export enum PacketType {
  REQUEST  = 0x01,
  RESPONSE = 0x02,
  ACK      = 0x03,
  ERROR    = 0x04,
}

export interface SMSPacket {
  sid:     string;
  seq:     number;
  total:   number;
  type:    PacketType;
  payload: Buffer;
}

export interface ChunkBuffer {
  chunks:     (Buffer | null)[];
  total:      number;
  from:       string;
  receivedAt: number;
}

export interface SMSConfig {
  httpSmsApiKey:    string;
  httpSmsFromPhone: string;
  chunkSize:        number;
  timeoutMs:        number;
}

export interface SMSRequestEnvelope {
  action:  string;
  payload: unknown;
}

export interface SMSResponseEnvelope {
  ok:    boolean;
  data?: unknown;
  err?:  string;
}

export interface SMSHandlerResult {
  skipDefaultResponse?: boolean;
  data?: unknown;
}

export type SMSMessageHandler = (
  action:  string,
  payload: unknown,
  from:    string
) => Promise<unknown | SMSHandlerResult>;
