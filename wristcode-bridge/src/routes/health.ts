import { Router, Request, Response } from 'express';
import { config } from '../config';
import { sessionManager } from '../services/sessionManager';

const router = Router();

router.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    version: config.version,
    hostname: config.hostname,
    uptime: process.uptime(),
    sessions: sessionManager.getActiveCount(),
  });
});

export default router;
