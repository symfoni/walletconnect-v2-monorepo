import fs from "fs";
import path from "path";
import Helmet from "fastify-helmet";
import pino, { Logger } from "pino";
import fastify, { FastifyInstance } from "fastify";
import { getLoggerOptions } from "@walletconnect/utils";

import { assertType } from "./utils";
import { RedisService } from "./redis";
import { WebSocketService } from "./ws";
import { NotificationService } from "./notification";
import { HttpServiceOptions, PostSubscribeRequest } from "./types";

export class HttpService {
  public app: FastifyInstance;
  public logger: Logger;
  public redis: RedisService;

  public ws: WebSocketService | undefined;
  public notification: NotificationService | undefined;

  public context = "server";

  constructor(opts: HttpServiceOptions) {
    const logger =
      typeof opts?.logger !== "undefined" && typeof opts?.logger !== "string"
        ? opts.logger
        : pino(getLoggerOptions(opts?.logger));
        /*
           
`privkey.pem`  : the private key for your certificate.
`fullchain.pem`: the certificate file used in most server software.
`chain.pem`    : used for OCSP stapling in Nginx >=1.3.7.
`cert.pem`     : will break many server configurations, and should not be used
                 without reading further documentation (see link below).

WARNING: DO NOT MOVE OR RENAME THESE FILES!
         Certbot expects these files to remain in this location in order
         to function properly!

We recommend not moving these files. For more information, see the Certbot
User Guide at https://certbot.eff.org/docs/using.html#where-are-my-certificates.
           */
    this.app = fastify({
      logger: logger,
      http2: true,
      https: {
        key: fs.readFileSync(path.join(__dirname, '..', 'https', 'fastify.key')),
        cert: fs.readFileSync(path.join('etc', 'letsencrypt', 'live', domain, 'fullchain.pem'))
      }
    });
    this.logger = logger.child({ context: "server" });
    this.redis = new RedisService(this.logger);
    this.initialize();
  }

  // ---------- Private ----------------------------------------------- //

  private initialize(): void {
    this.logger.trace(`Initialized`);

    this.app.register(Helmet);

    this.app.get("/health", (_, res) => {
      res.status(204).send();
    });

    this.app.get("/hello", (req, res) => {
      res.status(200).send(`Hello World, this is WalletConnect`);
    });

    this.app.post<PostSubscribeRequest>("/subscribe", async (req, res) => {
      try {
        assertType(req, "body", "object");

        assertType(req.body, "topic");
        assertType(req.body, "webhook");

        await this.redis.setNotification({
          topic: req.body.topic,
          webhook: req.body.webhook,
        });

        res.status(200).send({ success: true });
      } catch (e) {
        res.status(400).send({ message: `Error: ${e.message}` });
      }
    });

    this.app.ready(() => {
      this.notification = new NotificationService(this.logger, this.redis);
      this.ws = new WebSocketService(this.app.server, this.logger, this.redis, this.notification);
    });
  }
}
