import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  constructor(
    public error: string,
    message: string,
    public code: number = 500
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  if (err instanceof AppError) {
    res.status(err.code).json({
      error: err.error,
      message: err.message,
      code: err.code,
    });
    return;
  }

  console.error('[ERROR]', err.message);
  res.status(500).json({
    error: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred',
    code: 500,
  });
}
