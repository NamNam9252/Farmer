declare module 'node-base91' {
  export function encode(input: Uint8Array | Buffer | string): string;
  export function decode(input: string): Uint8Array;
}
