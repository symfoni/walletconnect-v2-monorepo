import { RequestGenericInterface } from "fastify";
import { Logger } from "pino";

export interface HttpServiceOptions {
  logger?: string | Logger;
  certsDir: string;
}

export interface PostSubscribeRequest extends RequestGenericInterface {
  Body: {
    topic: string;
    webhook: string;
  };
}
