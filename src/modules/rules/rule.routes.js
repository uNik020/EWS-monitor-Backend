const express = require('express');
const router = express.Router();
const { createRules, getRules } = require('./rule.controller');
const auth = require('../../middleware/auth');

router.post('/', auth, createRules);
router.get('/', auth, getRules);

module.exports = router;
