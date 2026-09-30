import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

import syncRouter from './routes/sync.js';
import aiRouter from './routes/ai.js';
import apiRouter from './routes/api.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS for all clients (Web app, Flutter mobile app, LAN devices)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Client-Id']
}));

// Request body parsers
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    if (!req.path.startsWith('/static')) {
      console.log(`[${req.method}] ${req.path} -> ${res.statusCode} (${duration}ms)`);
    }
  });
  next();
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'Kabadiwala Connect Central Sync & AI Engine',
    version: '1.0.0',
    timestamp: Date.now(),
    fireworksConfigured: Boolean(process.env.FIREWORKS_API_KEY && process.env.FIREWORKS_API_KEY.trim() !== '')
  });
});

// API Routes
app.use('/api/sync', syncRouter);
app.use('/api/ai', aiRouter);
app.use('/api', apiRouter);

import fs from 'fs';

// Serve Flutter Web build (unified mobile-responsive Flutter app)
const webDistPath = path.resolve(__dirname, '../kabadiwala_connect/build/web');
console.log(`[Web] Serving Flutter Web frontend from: ${webDistPath}`);
app.use(express.static(webDistPath));

app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) {
    return next();
  }
  const indexPath = path.join(webDistPath, 'index.html');
  res.sendFile(indexPath, (err) => {
    if (err) {
      res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head><title>Kabadiwala Connect API</title></head>
        <body style="font-family: system-ui; padding: 40px; background: #0b0f17; color: #fff;">
          <h2>♻️ Kabadiwala Connect Backend API</h2>
          <p>Status: <span style="color: #10b981; font-weight: bold;">ONLINE</span> on port ${PORT}</p>
          <ul>
            <li><a style="color: #38bdf8;" href="/api/health">/api/health</a> - Health & Fireworks status</li>
            <li><a style="color: #38bdf8;" href="/api/prices">/api/prices</a> - Real-time E-Waste price board</li>
            <li><a style="color: #38bdf8;" href="/api/recyclers">/api/recyclers</a> - Verified CPCB recyclers</li>
            <li><a style="color: #38bdf8;" href="/api/stats">/api/stats</a> - Circularity impact metrics</li>
            <li><a style="color: #38bdf8;" href="/api/sync/pull">/api/sync/pull</a> - Mobile offline-sync pull endpoint</li>
          </ul>
        </body>
        </html>
      `);
    }
  });
});

if (!process.env.VERCEL) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n======================================================`);
    console.log(`🚀 Kabadiwala Connect Backend & Sync Engine Active!`);
    console.log(`📡 Local Port: http://localhost:${PORT}`);
    console.log(`🌐 LAN Address for Mobile App: http://192.168.1.73:${PORT}`);
    console.log(`⚡ Fireworks Vision Engine: ${process.env.FIREWORKS_VISION_MODEL || 'llama-v3p2-11b-vision-instruct'}`);
    console.log(`======================================================\n`);
  });
}

export default app;
