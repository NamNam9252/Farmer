import zlib
import base91

# ── smaz dictionary (exact tsmaz default, index = code byte) ──────────────────

_CODEBOOK = [
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
]

# ── trie for compress ─────────────────────────────────────────────────────────

def _build_trie(codebook):
    root = {}
    for code, word in enumerate(codebook):
        node = root
        for ch in word[:-1]:
            node = node.setdefault(ch, {})
        last = word[-1]
        node[last] = node.get(last, {})
        node[last]['__code__'] = code
    return root

_TRIE = _build_trie(_CODEBOOK)

# ── smaz compress ─────────────────────────────────────────────────────────────

def _smaz_compress(text: str) -> bytes:
    buf = bytearray()
    verbatim = bytearray()

    def flush_verbatim():
        if len(verbatim) == 1:
            buf.append(254)
            buf.append(verbatim[0])
        else:
            buf.append(255)
            buf.append(len(verbatim))
            buf.extend(verbatim)
        verbatim.clear()

    i = 0
    while i < len(text):
        code = -1
        index_after_match = -1
        node = _TRIE

        for j in range(i, len(text)):
            ch = text[j]
            if ch not in node:
                break
            node = node[ch]
            if '__code__' in node:
                code = node['__code__']
                index_after_match = j + 1

        if code == -1:
            verbatim.append(ord(text[i]) & 0xFF)   # mirrors JS Uint8Array truncation (charCodeAt & 0xFF)
            i += 1
            if len(verbatim) == 255:
                flush_verbatim()
        else:
            if verbatim:
                flush_verbatim()
            buf.append(code)
            i = index_after_match

    if verbatim:
        flush_verbatim()

    return bytes(buf)

# ── smaz decompress ───────────────────────────────────────────────────────────

def _smaz_decompress(data: bytes) -> str:
    out = []
    i = 0
    while i < len(data):
        b = data[i]
        if b == 254:
            out.append(chr(data[i + 1]))
            i += 2
        elif b == 255:
            length = data[i + 1]
            out.append(data[i + 2 : i + 2 + length].decode('latin-1'))
            i += 2 + length
        else:
            out.append(_CODEBOOK[b])
            i += 1
    return ''.join(out)

# ── flags (mirror TS constants exactly) ──────────────────────────────────────

SMAZ_FLAG = 0x01
ZLIB_FLAG  = 0x02
RAW_FLAG   = 0x00
THRESHOLD  = 100

# ── encode ────────────────────────────────────────────────────────────────────

def encode(text: str) -> str:
    raw = text.encode('utf-8')
    has_non_ascii = any(ord(ch) > 127 for ch in text)

    if len(raw) < THRESHOLD:
        if has_non_ascii:
            payload = bytes([RAW_FLAG]) + raw
        else:
            smazed = _smaz_compress(text)
            if len(smazed) < len(raw):
                payload = bytes([SMAZ_FLAG]) + smazed
            else:
                payload = bytes([RAW_FLAG]) + raw
    else:
        zlibbed = zlib.compress(raw, level=9, wbits=-15)
        payload = bytes([ZLIB_FLAG]) + zlibbed

    return base91.encode(payload)

# ── decode ────────────────────────────────────────────────────────────────────

def decode(sms_text: str) -> str:
    payload = bytes(base91.decode(sms_text))
    if not payload:
        return ''
    flag = payload[0]
    data = payload[1:]

    if flag == SMAZ_FLAG:
        return _smaz_decompress(data)
    if flag == ZLIB_FLAG:
        return zlib.decompress(data, wbits=-15).decode('utf-8')
    return data.decode('utf-8')

if __name__ == '__main__':
    msg = "Meeting rescheduled to tomorrow at 3pm, please confirm!"
    enc = encode(msg)
    print(f"Original : {len(msg)} chars")
    print(f"Encoded  : {len(enc)} chars")
    print(f"Decoded  : {decode('l_^!$m3iaFEAr%@@6E6gd~#A')}")
    print("||", encode("Tell me about wheat"), "||", sep='')
    assert decode(enc) == msg, "Round-trip failed!"
    print("Round-trip OK")
    print(decode("VowW$Al_x:a}p5}Er}!lIEy`L>A"))
    print(decode("@Q/2:WF|6U6t>aRn\"ieZS[SIFT+@R@&ktogZh>6e#F]4.,kLTG<h>iRd8yF2mBMmpo)=:Wxv2$8t7Pqm*U^IO>uC&$a.KF"))
    print(decode("<v^v$mutB"))
    print(decode("eZ=Z;$+E"))
    print(decode("GOJ>b,&Y$yIw^Q,R9ZU=f,!YbU#(|alL\"i01@[BB"))
    print(decode("Y0YAAQIfiwgAAAAAAAAKq1bKz1aySkvMKU7VUUotKlKyUsrMS84vKkpNLlHISE1MSS1SSM5ITc5WqgUA1o6flCsAAAA="))