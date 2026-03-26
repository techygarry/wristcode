import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { JWTPayload } from '../types';

const PUBLIC_PATHS = ['/api/health', '/api/pair'];

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  if (PUBLIC_PATHS.includes(req.path)) {
    return next();
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Missing or invalid Authorization header',
      code: 401,
    });
    return;
  }

  const token = authHeader.substring(7);
  try {
    const payload = jwt.verify(token, config.jwtSecret) as JWTPayload;
    (req as any).devicePayload = payload;
    next();
  } catch (err) {
    res.status(401).json({
      error: 'TOKEN_INVALID',
      message: 'Invalid or expired token',
      code: 401,
    });
  }
}
