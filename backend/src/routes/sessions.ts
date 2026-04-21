import type { FastifyInstance } from 'fastify';

import { Penalty, Prisma } from '@prisma/client';

import { prisma } from '../lib/prisma.js';

type SessionCreateBody = {
  id: string;
  name: string;
  cubeType: string;
  ownerUserId?: string | null;
  createdAt?: string;
};

type SessionUpdateBody = Partial<Pick<SessionCreateBody, 'name' | 'cubeType' | 'ownerUserId'>>;

function serializeSession(session: {
  id: string;
  ownerUserId: string | null;
  name: string;
  cubeType: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}) {
  return {
    id: session.id,
    ownerUserId: session.ownerUserId,
    name: session.name,
    cubeType: session.cubeType,
    createdAt: session.createdAt.toISOString(),
    updatedAt: session.updatedAt.toISOString(),
    deletedAt: session.deletedAt?.toISOString() ?? null,
  };
}

function serializeSolve(solve: {
  id: string;
  sessionId: string;
  ownerUserId: string | null;
  timeMs: number;
  penalty: Penalty;
  scramble: string;
  cubeType: string;
  lane: number;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}) {
  return {
    id: solve.id,
    sessionId: solve.sessionId,
    ownerUserId: solve.ownerUserId,
    timeMs: solve.timeMs,
    penalty: solve.penalty,
    scramble: solve.scramble,
    cubeType: solve.cubeType,
    lane: solve.lane,
    createdAt: solve.createdAt.toISOString(),
    updatedAt: solve.updatedAt.toISOString(),
    deletedAt: solve.deletedAt?.toISOString() ?? null,
  };
}

export async function sessionRoutes(app: FastifyInstance): Promise<void> {
  app.get('/sessions', async () => {
    const sessions = await prisma.session.findMany({
      where: {
        deletedAt: null,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      sessions: sessions.map(serializeSession),
    };
  });

  app.post<{ Body: SessionCreateBody }>('/sessions', async (request, reply) => {
    const { id, name, cubeType, ownerUserId, createdAt } = request.body;

    if (!id || !name?.trim() || !cubeType?.trim()) {
      return reply.code(400).send({
        message: 'id, name, and cubeType are required',
      });
    }

    try {
      const session = await prisma.session.create({
        data: {
          id,
          name: name.trim(),
          cubeType: cubeType.trim(),
          ownerUserId: ownerUserId ?? null,
          createdAt: createdAt ? new Date(createdAt) : new Date(),
          updatedAt: new Date(),
        },
      });

      return reply.code(201).send({
        session: serializeSession(session),
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return reply.code(409).send({
          message: 'Session id already exists',
        });
      }

      throw error;
    }
  });

  app.patch<{ Params: { id: string }; Body: SessionUpdateBody }>(
      '/sessions/:id',
      async (request, reply) => {
        const existingSession = await prisma.session.findFirst({
          where: {
            id: request.params.id,
            deletedAt: null,
          },
          select: {
            id: true,
          },
        });

        if (!existingSession) {
          return reply.code(404).send({ message: 'Session not found' });
        }

        const data: Record<string, string | null | Date> = {
          updatedAt: new Date(),
        };

        if (request.body.name !== undefined) {
          const trimmedName = request.body.name.trim();
          if (!trimmedName) {
            return reply.code(400).send({ message: 'name cannot be empty' });
          }
          data.name = trimmedName;
        }

        if (request.body.cubeType !== undefined) {
          const trimmedCubeType = request.body.cubeType.trim();
          if (!trimmedCubeType) {
            return reply.code(400).send({ message: 'cubeType cannot be empty' });
          }
          data.cubeType = trimmedCubeType;
        }

        if (request.body.ownerUserId !== undefined) {
          data.ownerUserId = request.body.ownerUserId;
        }

        const session = await prisma.session.update({
          where: { id: request.params.id },
          data,
        });

        return {
          session: serializeSession(session),
        };
      },
  );

  app.delete<{ Params: { id: string } }>('/sessions/:id', async (request, reply) => {
    const now = new Date();

    const [sessionResult] = await prisma.$transaction([
      prisma.session.updateMany({
        where: {
          id: request.params.id,
          deletedAt: null,
        },
        data: {
          deletedAt: now,
          updatedAt: now,
        },
      }),
      prisma.solve.updateMany({
        where: {
          sessionId: request.params.id,
          deletedAt: null,
        },
        data: {
          deletedAt: now,
          updatedAt: now,
        },
      }),
    ]);

    if (sessionResult.count === 0) {
      return reply.code(404).send({ message: 'Session not found' });
    }

    return reply.code(204).send();
  });

  app.get<{ Params: { id: string } }>(
      '/sessions/:id/solves',
      async (request, reply) => {
        const session = await prisma.session.findFirst({
          where: {
            id: request.params.id,
            deletedAt: null,
          },
          select: {
            id: true,
          },
        });

        if (!session) {
          return reply.code(404).send({ message: 'Session not found' });
        }

        const solves = await prisma.solve.findMany({
          where: {
            sessionId: request.params.id,
            deletedAt: null,
          },
          orderBy: {
            createdAt: 'desc',
          },
        });

        return {
          solves: solves.map(serializeSolve),
        };
      },
  );
}
