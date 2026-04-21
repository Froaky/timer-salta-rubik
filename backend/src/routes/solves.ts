import type { FastifyInstance } from 'fastify';

import { Penalty, Prisma } from '@prisma/client';

import { prisma } from '../lib/prisma.js';

type SolveCreateBody = {
  id: string;
  sessionId: string;
  timeMs: number;
  penalty: 'none' | 'plus2' | 'dnf';
  scramble: string;
  cubeType: string;
  lane?: number;
  ownerUserId?: string | null;
  createdAt?: string;
};

type SolveUpdateBody = Partial<Omit<SolveCreateBody, 'id' | 'sessionId'>>;

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

function isPenalty(value: string): value is Penalty {
  return value === 'none' || value === 'plus2' || value === 'dnf';
}

export async function solveRoutes(app: FastifyInstance): Promise<void> {
  app.get<{ Querystring: { sessionId?: string } }>('/solves', async (request) => {
    const solves = await prisma.solve.findMany({
      where: {
        sessionId: request.query.sessionId,
        deletedAt: null,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return {
      solves: solves.map(serializeSolve),
    };
  });

  app.post<{ Body: SolveCreateBody }>('/solves', async (request, reply) => {
    const {
      id,
      sessionId,
      timeMs,
      penalty,
      scramble,
      cubeType,
      lane,
      ownerUserId,
      createdAt,
    } = request.body;

    if (
      !id ||
      !sessionId ||
      !Number.isInteger(timeMs) ||
      timeMs < 0 ||
      !scramble?.trim() ||
      !cubeType?.trim() ||
      !isPenalty(penalty)
    ) {
      return reply.code(400).send({
        message:
            'id, sessionId, timeMs, penalty, scramble, and cubeType are required',
      });
    }

    const session = await prisma.session.findFirst({
      where: {
        id: sessionId,
        deletedAt: null,
      },
      select: {
        id: true,
      },
    });

    if (!session) {
      return reply.code(404).send({ message: 'Session not found' });
    }

    try {
      const solve = await prisma.solve.create({
        data: {
          id,
          sessionId,
          ownerUserId: ownerUserId ?? null,
          timeMs,
          penalty,
          scramble: scramble.trim(),
          cubeType: cubeType.trim(),
          lane: lane ?? 0,
          createdAt: createdAt ? new Date(createdAt) : new Date(),
          updatedAt: new Date(),
        },
      });

      return reply.code(201).send({
        solve: serializeSolve(solve),
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        return reply.code(409).send({
          message: 'Solve id already exists',
        });
      }

      throw error;
    }
  });

  app.patch<{ Params: { id: string }; Body: SolveUpdateBody }>(
      '/solves/:id',
      async (request, reply) => {
        const existingSolve = await prisma.solve.findFirst({
          where: {
            id: request.params.id,
            deletedAt: null,
          },
          select: {
            id: true,
          },
        });

        if (!existingSolve) {
          return reply.code(404).send({ message: 'Solve not found' });
        }

        const data: Record<string, string | number | null | Date> = {
          updatedAt: new Date(),
        };

        if (request.body.timeMs !== undefined) {
          if (!Number.isInteger(request.body.timeMs) || request.body.timeMs < 0) {
            return reply.code(400).send({ message: 'timeMs must be a positive integer' });
          }
          data.timeMs = request.body.timeMs;
        }

        if (request.body.penalty !== undefined) {
          if (!isPenalty(request.body.penalty)) {
            return reply.code(400).send({ message: 'Invalid penalty value' });
          }
          data.penalty = request.body.penalty;
        }

        if (request.body.scramble !== undefined) {
          const trimmedScramble = request.body.scramble.trim();
          if (!trimmedScramble) {
            return reply.code(400).send({ message: 'scramble cannot be empty' });
          }
          data.scramble = trimmedScramble;
        }

        if (request.body.cubeType !== undefined) {
          const trimmedCubeType = request.body.cubeType.trim();
          if (!trimmedCubeType) {
            return reply.code(400).send({ message: 'cubeType cannot be empty' });
          }
          data.cubeType = trimmedCubeType;
        }

        if (request.body.lane !== undefined) {
          if (!Number.isInteger(request.body.lane) || request.body.lane < 0) {
            return reply.code(400).send({ message: 'lane must be a non-negative integer' });
          }
          data.lane = request.body.lane;
        }

        if (request.body.ownerUserId !== undefined) {
          data.ownerUserId = request.body.ownerUserId;
        }

        const solve = await prisma.solve.update({
          where: { id: request.params.id },
          data,
        });

        return {
          solve: serializeSolve(solve),
        };
      },
  );

  app.delete<{ Params: { id: string } }>('/solves/:id', async (request, reply) => {
    const result = await prisma.solve.updateMany({
      where: {
        id: request.params.id,
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
        updatedAt: new Date(),
      },
    });

    if (result.count === 0) {
      return reply.code(404).send({ message: 'Solve not found' });
    }

    return reply.code(204).send();
  });
}
