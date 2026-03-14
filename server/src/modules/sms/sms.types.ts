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
