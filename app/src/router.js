const express = require('express');
const { lookup } = require('./lookup');
const tips = require('../data/tips');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Feature routes (Sections 1/2 — /tip, /fact) register below this line.

router.get('/tip', (req, res) => {
  try {
    const tip = lookup(tips, req.query.category);
    res.type('text/plain').send(tip.text);
  } catch (err) {
    res.status(err.status || 500).send(err.message);
  }
});

module.exports = router;
