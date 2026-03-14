declare module "node-base91" {
  const api: {
    encode(data: string | Buffer, encoding?: BufferEncoding): string;
    decode(data: string, encoding?: BufferEncoding): Buffer | string;
  };

  export default api;
}
