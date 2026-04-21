import type { FastifyInstance } from 'fastify';

import { prisma } from '../lib/prisma.js';

export async function healthRoutes(app: FastifyInstance): Promise<void> {
  app.get('/health', async () => {
    await prisma.$queryRaw`SELECT 1`;

    return {
      ok: true,
      service: 'salta-rubik-backend',
      database: 'reachable',
    };
  });
}
