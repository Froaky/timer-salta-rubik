import Fastify, { type FastifyInstance } from 'fastify';

import { authRoutes } from './routes/auth.js';
import { healthRoutes } from './routes/health.js';
import { sessionRoutes } from './routes/sessions.js';
import { solveRoutes } from './routes/solves.js';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: true,
  });

  app.register(healthRoutes);
  app.register(authRoutes, { prefix: '/api/v1' });
  app.register(sessionRoutes, { prefix: '/api/v1' });
  app.register(solveRoutes, { prefix: '/api/v1' });

  return app;
}
