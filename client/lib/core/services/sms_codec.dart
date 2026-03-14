// Dart port of server/src/modules/sms/sms.codec.ts
// Encodes/decodes messages for SMS transport using:
//   base91 + (smaz | zlib | raw) strategy — exactly matching the server codec.


import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// ─── Flags ────────────────────────────────────────────────────────────────────
const int _smazFlag = 0x01;
const int _zlibFlag = 0x02;
const int _rawFlag  = 0x00;
const int _threshold = 100;

// ─── SMAZ Codebook (exact tsmaz default — matches TypeScript & Python) ─────────
const List<String> _codebook = [
  ' ', 'the', 'e', 't', 'a', 'of', 'o', 'and', 'i', 'n', 's', 'e ',
  'r', ' th', ' t', 'in', 'he', 'th', 'h', 'he ', 'to', '\r\n', 'l',
  's ', 'd', ' a', 'an', 'er', 'c', ' o', 'd ', 'on', ' of', 're',
  'of ', 't ', ', ', 'is', 'u', 'at', '   ', 'n ', 'or', 'which', 'f',
  'm', 'as', 'it', 'that', '\n', 'was', 'en', '  ', ' w', 'es', ' an',
  ' i', 'f ', 'g', 'p', 'nd', ' s', 'nd ', 'ed ', 'w', 'ed', 'http://',
  'https://', 'for', 'te', 'ing', 'y ', 'The', ' c', 'ti', 'r ', 'his',
  'st', ' in', 'ar', 'nt', ',', ' to', 'y', 'ng', ' h', 'with', 'le',
  'al', 'to ', 'b', 'ou', 'be', 'were', ' b', 'se', 'o ', 'ent', 'ha',
  'ng ', 'their', '"', 'hi', 'from', ' f', 'in ', 'de', 'ion', 'me', 'v',
  '.', 've', 'all', 're ', 'ri', 'ro', 'is ', 'co', 'f t', 'are', 'ea',
  '. ', 'her', ' m', 'er ', ' p', 'es ', 'by', 'they', 'di', 'ra', 'ic',
  'not', 's, ', 'd t', 'at ', 'ce', 'la', 'h ', 'ne', 'as ', 'tio',
  'on ', 'n t', 'io', 'we', ' a ', 'om', ', a', 's o', 'ur', 'li', 'll',
  'ch', 'had', 'this', 'e t', 'g ', ' wh', 'ere', ' co', 'e o', 'a ',
  'us', ' d', 'ss', ' be', ' e', 's a', 'ma', 'one', 't t', 'or ', 'but',
  'el', 'so', 'l ', 'e s', 's,', 'no', 'ter', ' wa', 'iv', 'ho', 'e a',
  ' r', 'hat', 's t', 'ns', 'ch ', 'wh', 'tr', 'ut', '/', 'have', 'ly ',
  'ta', ' ha', ' on', 'tha', '-', ' l', 'ati', 'en ', 'pe', ' re',
  'there', 'ass', 'si', ' fo', 'wa', 'ec', 'our', 'who', 'its', 'z',
  'fo', 'rs', 'ot', 'un', 'im', 'th ', 'nc', 'ate', 'ver', 'ad', ' we',
  'ly', 'ee', ' n', 'id', ' cl', 'ac', 'il', 'rt', ' wi', 'e, ', ' it',
  'whi', ' ma', 'ge', 'x', 'e c', 'men', '.com',
];

// ─── SMAZ Trie ────────────────────────────────────────────────────────────────
// Build a prefix-trie for fast longest-match compression
class _TrieNode {
  final Map<int, _TrieNode> children = {};
  int code = -1; // -1 means no code at this node
}

_TrieNode _buildTrie() {
  final root = _TrieNode();
  for (int i = 0; i < _codebook.length; i++) {
    final word = _codebook[i];
    var node = root;
    for (int ci = 0; ci < word.length; ci++) {
      final charCode = word.codeUnitAt(ci);
      node.children.putIfAbsent(charCode, () => _TrieNode());
      node = node.children[charCode]!;
    }
    node.code = i;
  }
  return root;
}

final _TrieNode _trie = _buildTrie();

// ─── SMAZ compress ────────────────────────────────────────────────────────────
Uint8List _smazCompress(String text) {
  final buf = BytesBuilder();
  final verbatim = BytesBuilder();

  void flushVerbatim() {
    final v = verbatim.takeBytes();
    if (v.length == 1) {
      buf.addByte(254);
      buf.addByte(v[0]);
    } else {
      buf.addByte(255);
      buf.addByte(v.length);
      buf.add(v);
    }
  }

  int i = 0;
  while (i < text.length) {
    int bestCode = -1;
    int bestEnd = -1;
    var node = _trie;

    for (int j = i; j < text.length; j++) {
      final ch = text.codeUnitAt(j);
      if (!node.children.containsKey(ch)) break;
      node = node.children[ch]!;
      if (node.code != -1) {
        bestCode = node.code;
        bestEnd = j + 1;
      }
    }

    if (bestCode == -1) {
      // Mirror JS: charCodeAt & 0xFF (truncate to byte)
      verbatim.addByte(text.codeUnitAt(i) & 0xFF);
      i++;
      if (verbatim.length == 255) flushVerbatim();
    } else {
      if (verbatim.length > 0) flushVerbatim();
      buf.addByte(bestCode);
      i = bestEnd;
    }
  }

  if (verbatim.length > 0) flushVerbatim();
  return buf.takeBytes();
}

// ─── SMAZ decompress ─────────────────────────────────────────────────────────
String _smazDecompress(Uint8List data) {
  final sb = StringBuffer();
  int i = 0;
  while (i < data.length) {
    final b = data[i];
    if (b == 254) {
      sb.writeCharCode(data[i + 1]);
      i += 2;
    } else if (b == 255) {
      final length = data[i + 1];
      // latin-1 decode: each byte is a codepoint
      for (int k = i + 2; k < i + 2 + length; k++) {
        sb.writeCharCode(data[k]);
      }
      i += 2 + length;
    } else {
      sb.write(_codebook[b]);
      i++;
    }
  }
  return sb.toString();
}

// ─── Base91 ───────────────────────────────────────────────────────────────────
// Table matching node-base91
const String _b91Table =
    r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    r'!#$%&()*+,./:;<=>?@[]^_`{|}~"';

final List<int> _b91Dec = () {
  final t = List<int>.filled(256, -1);
  for (int i = 0; i < _b91Table.length; i++) {
    t[_b91Table.codeUnitAt(i)] = i;
  }
  return t;
}();

// ─── Public API ───────────────────────────────────────────────────────────────
class SmsCodec {
  SmsCodec._();

  /// Encodes [text] to raw bytes (flag + compressed data) without Base91.
  /// Matches smscodec.standard.py encode() logic.
  static Uint8List encodeToBytes(String text) {
    final rawBytes = utf8.encode(text);
    final raw = Uint8List.fromList(rawBytes);

    final hasNonAscii = text.runes.any((r) => r > 127);
    Uint8List payload;

    if (raw.length < _threshold) {
      if (hasNonAscii) {
        payload = _prepend(_rawFlag, raw);
      } else {
        final smazed = _smazCompress(text);
        if (smazed.length < raw.length) {
          payload = _prepend(_smazFlag, smazed);
        } else {
          payload = _prepend(_rawFlag, raw);
        }
      }
    } else {
      // Raw deflate (no header) matching python wbits=-15
      final compressed = Uint8List.fromList(
        ZLibCodec(raw: true, level: 9).encoder.convert(raw),
      );
      payload = _prepend(_zlibFlag, compressed);
    }
    return payload;
  }

  /// Decodes [payload] (flag + compressed data) to plain text.
  /// Matches smscodec.standard.py decode() logic.
  static String decodeFromBytes(Uint8List payload) {
    if (payload.isEmpty) return '';
    final flag = payload[0];
    final data = payload.sublist(1);

    if (flag == _smazFlag) return _smazDecompress(data);
    if (flag == _zlibFlag) {
      // Raw inflate matching python wbits=-15
      return utf8.decode(
        Uint8List.fromList(ZLibCodec(raw: true).decoder.convert(data)),
      );
    }
    // RAW
    return utf8.decode(data);
  }

  /// Standard encode: flag + compression + Base91
  static String encode(String text) => b91Encode(encodeToBytes(text));

  /// Standard decode: Base91 + flag + decompression
  static String decode(String smsText) => decodeFromBytes(b91Decode(smsText));

  /// Base91 encode matching node-base91 / python base91
  static String b91Encode(Uint8List data) {
    final sb = StringBuffer();
    int b = 0;
    int n = 0;
    for (final byte in data) {
      b |= byte << n;
      n += 8;
      if (n > 13) {
        int v = b & 8191;
        if (v > 88) {
          b >>= 13;
          n -= 13;
        } else {
          v = b & 16383;
          b >>= 14;
          n -= 14;
        }
        sb.writeCharCode(_b91Table.codeUnitAt(v % 91));
        sb.writeCharCode(_b91Table.codeUnitAt(v ~/ 91));
      }
    }
    if (n > 0) {
      sb.writeCharCode(_b91Table.codeUnitAt(b % 91));
      if (n > 7 || b > 90) {
        sb.writeCharCode(_b91Table.codeUnitAt(b ~/ 91));
      }
    }
    return sb.toString();
  }

  /// Base91 decode matching node-base91 / python base91
  static Uint8List b91Decode(String input) {
    final buf = BytesBuilder();
    int v = -1;
    int b = 0;
    int n = 0;
    for (int i = 0; i < input.length; i++) {
      final cIdx = input.codeUnitAt(i);
      final c = cIdx < 256 ? _b91Dec[cIdx] : -1;
      if (c == -1) continue; // skip unknown chars
      if (v < 0) {
        v = c;
      } else {
        v += c * 91;
        b |= v << n;
        n += (v & 8191) > 88 ? 13 : 14;
        v = -1;
        do {
          buf.addByte(b & 255);
          b >>= 8;
          n -= 8;
        } while (n > 7);
      }
    }
    if (v > -1) buf.addByte((b | v << n) & 255);
    return buf.takeBytes();
  }

  static Uint8List _prepend(int flag, Uint8List data) {
    final out = Uint8List(data.length + 1);
    out[0] = flag;
    out.setRange(1, out.length, data);
    return out;
  }
}
