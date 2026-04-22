import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';

import { authRoutes } from './routes/auth.js';
import { healthRoutes } from './routes/health.js';
import { sessionRoutes } from './routes/sessions.js';
import { solveRoutes } from './routes/solves.js';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: true,
  });

  const allowedOrigins =
      process.env.CORS_ALLOWED_ORIGINS
          ?.split(',')
          .map((value) => value.trim())
          .filter(Boolean) ?? [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://localhost:8080',
        'http://localhost:8081',
        'https://timer-salta-rubik-production.up.railway.app',
      ];

  app.register(cors, {
    origin: (
        origin: string | undefined,
        callback: (error: Error | null, allow: boolean) => void,
    ) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin not allowed by CORS'), false);
    },
    credentials: false,
    allowedHeaders: ['Authorization', 'Content-Type'],
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  });

  app.register(healthRoutes);
  app.register(authRoutes, { prefix: '/api/v1' });
  app.register(sessionRoutes, { prefix: '/api/v1' });
  app.register(solveRoutes, { prefix: '/api/v1' });

  return app;
}
