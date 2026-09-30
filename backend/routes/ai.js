import express from 'express';
import multer from 'multer';
import { classifyEwasteWithFireworks, testFireworksKey } from '../services/fireworks.js';

const router = express.Router();
const upload = multer({ limits: { fileSize: 15 * 1024 * 1024 } }); // 15MB max

/**
 * POST /api/ai/classify
 * Accepts JSON with { imageBase64, weightKg, apiKey, model }
 * OR multipart form-data with file
 */
router.post('/classify', upload.single('image'), async (req, res) => {
  try {
    let imageBase64 = req.body.imageBase64;
    const weightKg = parseFloat(req.body.weightKg) || 10.0;
    const apiKey = req.body.apiKey;
    const model = req.body.model;

    if (!imageBase64 && req.file) {
      imageBase64 = req.file.buffer.toString('base64');
    }

    if (!imageBase64 && !req.body.imageUrl) {
      return res.status(400).json({
        success: false,
        error: 'No image provided. Please supply imageBase64, imageUrl, or an uploaded file.'
      });
    }

    const startTime = Date.now();
    const result = await classifyEwasteWithFireworks({
      imageBase64,
      imageUrl: req.body.imageUrl,
      apiKey,
      model,
      weightKg
    });
    const latencyMs = Date.now() - startTime;

    return res.json({
      success: true,
      data: {
        ...result,
        latencyMs
      }
    });
  } catch (error) {
    console.error('[AI Route] Error in classification:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * POST /api/ai/test-key
 * Allows testing Fireworks AI API key from the Web UI
 */
router.post('/test-key', async (req, res) => {
  try {
    const { apiKey } = req.body;
    const check = await testFireworksKey(apiKey);
    return res.json(check);
  } catch (error) {
    return res.status(500).json({ valid: false, error: error.message });
  }
});

export default router;
