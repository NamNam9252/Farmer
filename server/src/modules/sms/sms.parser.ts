import { SMSPacket, PacketType } from "./sms.types";

export const parsePacket = (raw: string): SMSPacket => {
  const bytes = Buffer.from(raw, "base64");
  if (bytes.length < 5) throw new Error(`Packet too short: ${bytes.length} bytes`);

  return {
    sid:     String.fromCharCode(bytes[0], bytes[1]),
    seq:     bytes[2],
    total:   bytes[3],
    type:    bytes[4] as PacketType,
    payload: bytes.slice(5),
  };
};

export const buildPacket = (
  sid:     string,
  seq:     number,
  total:   number,
  type:    PacketType,
  payload: Buffer
): string => {
  const header = Buffer.from([
    sid.charCodeAt(0),
    sid.charCodeAt(1),
    seq,
    total,
    type,
  ]);
  return Buffer.concat([header, payload]).toString("base64");
};

export const randomSID = (): string => {
  const c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  return (
    c[Math.floor(Math.random() * c.length)] +
    c[Math.floor(Math.random() * c.length)]
  );
};
