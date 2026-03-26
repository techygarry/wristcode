# WristCode — Session 1: Bridge Server Foundation

## Context
WristCode is an Apple Watch app that controls Claude Code sessions on your Mac. This session builds the Node.js bridge server — the middleware between the watch and Claude Code.

## Tech Stack
Node.js 20+, TypeScript, Express.js, bonjour-service, jsonwebtoken, PM2

## Task
Create the complete bridge server foundation:

```
wristcode-bridge/
  package.json
  tsconfig.json
  ecosystem.config.js
  src/
    index.ts                   # Express server on port 3847
    config.ts                  # Env-based config
    routes/health.ts           # GET /api/health -> { status, version, hostname, uptime }
    routes/auth.ts             # POST /api/pair -> validates 6-digit code, returns JWT
    middleware/auth.ts         # JWT verification, skip for health+pair routes
    middleware/errorHandler.ts # Consistent { error, message, code } format
    services/bonjourAdvertiser.ts  # mDNS _wristcode._tcp advertisement
    types/index.ts             # All TypeScript interfaces
```

## Config (config.ts)
- PORT: 3847, PAIRING_CODE: "123456", JWT_SECRET: auto-generated via crypto.randomBytes if not set
- JWT_EXPIRY: "30d", HOSTNAME: os.hostname()

## Auth Flow
1. Watch sends POST /api/pair with { code: "123456" }
2. Server validates against PAIRING_CODE, returns JWT { token, expiresIn, hostname }
3. Watch stores JWT, sends as Authorization: Bearer <token> on all subsequent requests
4. JWT payload: { device: "watch", pairedAt: timestamp }

## Bonjour
- Service type: _wristcode._tcp on configured port
- TXT record: { version: "1.0.0", hostname: os.hostname() }
- Start on boot, stop on SIGINT/SIGTERM graceful shutdown

## Error Format (all endpoints)
```json
{ "error": "ERROR_CODE", "message": "Human readable", "code": 400 }
```

## Verify
1. npm run build compiles clean
2. npm start boots + prints Bonjour advertisement
3. curl localhost:3847/api/health returns status
4. POST /api/pair with correct code returns JWT
5. Requests with Bearer token pass auth middleware
