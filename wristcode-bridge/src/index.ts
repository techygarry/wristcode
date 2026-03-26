import express from 'express';
import cors from 'cors';
import path from 'path';
import { config } from './config';
import { authMiddleware } from './middleware/auth';
import { errorHandler } from './middleware/errorHandler';
import { startAdvertising, stopAdvertising } from './services/bonjourAdvertiser';
import { sseManager } from './services/sseManager';
import healthRouter from './routes/health';
import authRouter from './routes/auth';
import sessionsRouter from './routes/sessions';

const app = express();

// Body parsing & CORS
app.use(express.json());
app.use(cors());

// Preview endpoint — serves files from session's cwd (NO auth, before middleware)
app.get('/preview/:sessionId', (req, res) => {
  const { sessionManager } = require('./services/sessionManager');
  const session = sessionManager.getSession(req.params.sessionId);
  const info = sessionManager.getSessionInfo(req.params.sessionId);
  const cwd = session?.cwd || info?.cwd;
  if (!cwd) return res.status(404).send('Session not found');
  const filePath = path.join(cwd, 'index.html');
  res.sendFile(filePath, (err: any) => {
    if (err) res.status(404).send('No index.html found');
  });
});

app.get('/preview/:sessionId/:file', (req, res) => {
  const { sessionManager } = require('./services/sessionManager');
  const session = sessionManager.getSession(req.params.sessionId);
  const info = sessionManager.getSessionInfo(req.params.sessionId);
  const cwd = session?.cwd || info?.cwd;
  if (!cwd) return res.status(404).send('Session not found');
  const filePath = path.join(cwd, req.params.file);
  res.sendFile(filePath, (err: any) => {
    if (err) res.status(404).send('File not found');
  });
});

// Screenshot endpoint — renders HTML to PNG image
app.get('/preview/:sessionId/screenshot', (req, res) => {
  const { sessionManager } = require('./services/sessionManager');
  const { execSync } = require('child_process');
  const fs = require('fs');
  const session = sessionManager.getSession(req.params.sessionId);
  const info = sessionManager.getSessionInfo(req.params.sessionId);
  const cwd = session?.cwd || info?.cwd;
  if (!cwd) return res.status(404).send('Session not found');

  const htmlPath = path.join(cwd, 'index.html');
  if (!fs.existsSync(htmlPath)) return res.status(404).send('No index.html');

  const pngPath = path.join(cwd, '.preview.png');
  try {
    const screenshotBin = path.join(__dirname, '..', 'screenshot');
    execSync(`"${screenshotBin}" "${htmlPath}" "${pngPath}"`, { timeout: 15000, stdio: 'pipe' });
    if (fs.existsSync(pngPath)) {
      res.sendFile(pngPath);
    } else {
      res.status(500).send('Screenshot not generated');
    }
  } catch (e: any) {
    console.error('[Screenshot] Error:', e.message?.substring(0, 100));
    // Fallback: serve the HTML directly
    res.sendFile(htmlPath);
  }
});

// Auth middleware (skips /api/health and /api/pair)
app.use(authMiddleware);

// Mount routes
app.use('/api', healthRouter);
app.use('/api', authRouter);
app.use('/api', sessionsRouter);



// Error handler (must be last)
app.use(errorHandler);

// Start server
const server = app.listen(config.port, () => {
  console.log(BANNER);
  console.log(`  Port:     ${config.port}`);
  console.log(`  Hostname: ${config.hostname}`);
  console.log(`  Version:  ${config.version}`);
  console.log(`  Pairing:  ${config.pairingCode}`);
  console.log('');

  // Start mDNS advertising after server is listening
  startAdvertising();
});

// Graceful shutdown
function shutdown(signal: string): void {
  console.log(`\n[Server] Received ${signal}, shutting down gracefully...`);

  stopAdvertising();
  sseManager.disconnectAll();

  server.close(() => {
    console.log('[Server] HTTP server closed');
    process.exit(0);
  });

  // Force exit after 5 seconds if graceful shutdown hangs
  setTimeout(() => {
    console.error('[Server] Forced shutdown after timeout');
    process.exit(1);
  }, 5000);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

const BANNER = `
╔══════════════════════════════════════════════╗
║                                              ║
║   ╦ ╦╦═╗╦╔═╗╔╦╗╔═╗╔═╗╔╦╗╔═╗                ║
║   ║║║╠╦╝║╚═╗ ║ ║  ║ ║ ║║║╣                  ║
║   ╚╩╝╩╚═╩╚═╝ ╩ ╚═╝╚═╝═╩╝╚═╝                ║
║                                              ║
║   ╔╗ ╦═╗╦╔╦╗╔═╗╔═╗                           ║
║   ╠╩╗╠╦╝║ ║║║ ╦║╣                             ║
║   ╚═╝╩╚═╩═╩╝╚═╝╚═╝                           ║
║                                              ║
║   Apple Watch <-> Claude Code Bridge          ║
║                                              ║
╚══════════════════════════════════════════════╝
`;
