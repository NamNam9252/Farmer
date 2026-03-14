import base91 from "node-base91";
import { compress as smazCompress, decompress as smazDecompress } from "tsmaz";
import { deflateSync, inflateSync, strFromU8, strToU8 } from "fflate";

const SMAZ_FLAG = 0x01;
const ZLIB_FLAG = 0x02;
const RAW_FLAG = 0x00;
const THRESHOLD = 100;

const concatBytes = (a: Uint8Array, b: Uint8Array): Uint8Array => {
  const out = new Uint8Array(a.length + b.length);
  out.set(a);
  out.set(b, a.length);
  return out;
};

export const encode = (text: string): string => {
  const raw = strToU8(text);
  const hasNonAscii = [...text].some((ch) => ch.charCodeAt(0) > 127);
  let payload: Uint8Array;

  if (raw.length < THRESHOLD) {
    if (hasNonAscii) {
      payload = concatBytes(new Uint8Array([RAW_FLAG]), raw);
    } else {
      const smazed = new Uint8Array(smazCompress(text));
      if (smazed.length < raw.length) payload = concatBytes(new Uint8Array([SMAZ_FLAG]), smazed);
      else payload = concatBytes(new Uint8Array([RAW_FLAG]), raw);
    }
  } else {
    const zlibbed = deflateSync(raw, { level: 9 });
    payload = concatBytes(new Uint8Array([ZLIB_FLAG]), zlibbed);
  }

  return base91.encode(Buffer.from(payload));
};

export const decode = (smsText: string): string => {
  const decoded = base91.decode(smsText);
  const payload = Buffer.isBuffer(decoded)
    ? new Uint8Array(decoded)
    : new Uint8Array(Buffer.from(decoded, "latin1")); // ← fix: latin1, not utf-8

  if (!payload.length) return "";

  const flag = payload[0];
  const data = payload.slice(1);

  if (flag === SMAZ_FLAG) return smazDecompress(data);
  if (flag === ZLIB_FLAG) return strFromU8(inflateSync(data));
  return strFromU8(data);
};