const express = require('express');
const router = express.Router();
const auth = require('../../middleware/auth');
const {
  getAlerts,
  getAlertById,
  createAlert,
  patchAlert,
} = require('./alert.controller');

// list alerts (supports query params: q, severity, status, page, limit)
router.get('/', auth, getAlerts);

// create one or many alerts
router.post('/', auth, createAlert);

// get single alert
router.get('/:id', auth, getAlertById);

// patch alert (add history entry and update status)
router.patch('/:id', auth, patchAlert);

module.exports = router;
