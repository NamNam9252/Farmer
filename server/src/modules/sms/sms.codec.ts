// Simplified SMS Codec - Plain Text only
// (Removed Base91, Smaz, and ZLib to use simple text for SMS transport)

export const encodeBinary = (text: string): Uint8Array => {
  return new TextEncoder().encode(text);
};

export const decodeBinary = (payload: Uint8Array): string => {
  return new TextDecoder().decode(payload);
};

export const encode = (text: string): string => {
  return text;
};

export const decode = (smsText: string): string => {
  return smsText;
};