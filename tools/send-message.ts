import { RabbitMQClient } from "@linagora/rabbitmq-client";
import { createInterface } from "node:readline";

interface SettingsPayload {
  matrix_id: string;
  display_name?: string;
  avatar?: string;
  language?: string;
}

type CommonSettingsMessage = {
  source: string;
  nickname: string;
  request_id: string;
  timestamp: number;
  version: number;
  payload: SettingsPayload;
};

function buildAmqpUrl(): string {
  const protocol = process.env.RABBITMQ_TLS === "true" ? "amqps" : "amqp";
  const hostname = process.env.RABBITMQ_HOST ?? "localhost";
  const port = process.env.RABBITMQ_PORT ?? "5672";
  const username = process.env.RABBITMQ_USERNAME ?? "guest";
  const password = process.env.RABBITMQ_PASSWORD ?? "guest";
  const vhost = process.env.RABBITMQ_VHOST ?? "/";
  return `${protocol}://${encodeURIComponent(username)}:${encodeURIComponent(password)}@${hostname}:${port}/${encodeURIComponent(vhost)}`;
}

const exchange = process.env.EXCHANGE_NAME ?? "settings.exchange";
const routingKey = process.env.ROUTING_KEY ?? "user.settings.updated";

async function sendMessage(payload: SettingsPayload, nickname: string, version: number): Promise<void> {
  const client = new RabbitMQClient({ url: buildAmqpUrl(), logger: console });
  try {
    await client.init();

    const message: CommonSettingsMessage = {
      source: "test-helper",
      nickname,
      request_id: crypto.randomUUID(),
      timestamp: Date.now(),
      version,
      payload,
    };

    await client.publish(exchange, routingKey, message);

    console.log("Message sent to exchange '%s' with routing key '%s':", exchange, routingKey);
    console.log(JSON.stringify(message, null, 2));
  } finally {
    await client.close();
    console.log("Connection closed.");
  }
}

function main(): void {
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const ask = (question: string): Promise<string> =>
    new Promise((resolve) => rl.question(question, resolve));

  (async () => {
    console.log("Starting interactive message sender. Press Ctrl+C to exit.");
    console.log("Leave matrix_id empty to exit.");

    let version = 1;
    let language = "en";

    while (true) {
      const matrix_id = await ask("Enter matrix_id (e.g., @user:matrix.org): ");
      if (!matrix_id) {
        break;
      }

      const nickname = matrix_id.startsWith("@") ? matrix_id.split(":")[0]?.substring(1) ?? matrix_id : matrix_id;

      const nversion = await ask(`Enter a version number: (${version}) `);
      if (nversion) {
        const parsed = Number.parseInt(nversion, 10);
        if (!Number.isFinite(parsed) || parsed <= 0) {
          console.error("Invalid version number; keeping previous value.");
        } else {
          version = parsed;
        }
      }

      const display_name = await ask("Enter new display_name (optional): ");
      const avatar = await ask("Enter new avatar URL (optional): ");
      const languageInput = await ask(`Enter new language (optional): (${language}) `);
      if (languageInput) {
        language = languageInput;
      }

      const payload: SettingsPayload = { matrix_id };

      if (display_name) {
        payload.display_name = display_name;
      }

      if (avatar) {
        payload.avatar = avatar;
      }

      if (language) {
        payload.language = language;
      }

      try {
        await sendMessage(payload, nickname, version);
        version += 1;
      } catch (error) {
        console.error("Failed to send message:", error);
      }
    }

    rl.close();
    console.log("Exiting.");
  })();
}

main();
