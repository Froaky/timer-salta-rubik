import { buildApp } from './app.js';

const requiredEnvVars = ['DATABASE_URL'] as const;

for (const variableName of requiredEnvVars) {
  if (!process.env[variableName]) {
    throw new Error(`Missing required environment variable: ${variableName}`);
  }
}

const port = Number(process.env.PORT ?? '8081');
const host = process.env.HOST ?? '0.0.0.0';

const app = buildApp();

app
    .listen({ port, host })
    .then(() => {
      app.log.info({ port, host }, 'Salta Rubik backend listening');
    })
    .catch((error) => {
      app.log.error(error, 'Failed to start server');
      process.exit(1);
    });
