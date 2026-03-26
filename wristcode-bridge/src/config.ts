import os from 'os';
import crypto from 'crypto';

export const config = {
  port: parseInt(process.env.PORT || '3847', 10),
  pairingCode: process.env.PAIRING_CODE || '123456',
  jwtSecret: process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex'),
  jwtExpiry: process.env.JWT_EXPIRY || '30d',
  hostname: os.hostname(),
  version: '1.0.0',
  enableSummarization: process.env.ENABLE_SUMMARIZATION !== 'false',
  sessionPollInterval: parseInt(process.env.SESSION_POLL_INTERVAL || '30000', 10),
  sseKeepAliveInterval: 15000,
  approvalTimeout: 5 * 60 * 1000, // 5 minutes
};
