import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { PairRequest, JWTPayload } from '../types';

const router = Router();

router.post('/pair', (req: Request, res: Response) => {
  const { code } = req.body as PairRequest;

  if (!code) {
    res.status(400).json({
      error: 'MISSING_CODE',
      message: 'Pairing code is required',
      code: 400,
    });
    return;
  }

  if (code !== config.pairingCode) {
    res.status(403).json({
      error: 'INVALID_CODE',
      message: 'Incorrect pairing code',
      code: 403,
    });
    return;
  }

  const payload: JWTPayload = {
    device: 'watch',
    pairedAt: Date.now(),
  };

  const token = jwt.sign(payload, config.jwtSecret, {
    expiresIn: config.jwtExpiry,
  } as jwt.SignOptions);

  console.log('[Auth] Watch paired successfully');

  res.json({
    token,
    expiresIn: config.jwtExpiry,
    hostname: config.hostname,
  });
});

export default router;
