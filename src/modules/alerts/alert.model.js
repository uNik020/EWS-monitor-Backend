const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
  {
    company: String,
    event_name: String,
    matched_rule: {},
    severity: String,
    tat_days: Number,
    status: String,
    history: Array,
  },
  { timestamps: true }
);

module.exports = mongoose.model('Alert', alertSchema);
