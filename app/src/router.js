const express = require('express');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Feature routes (Sections 1/2 — /tip, /fact) register below this line.

module.exports = router;
