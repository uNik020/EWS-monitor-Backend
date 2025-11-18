const mongoose = require('mongoose');

const ruleSchema = new mongoose.Schema(
  {
    rule_code: String,
    change_reported: String,
    condition: String,
    severity: String,
    primary_action: String,
    secondary_action: String,
    tat_days: Number,
    assigned_team: String,
    tags: [String],
    metadata: {},
  },
  { timestamps: true }
);

module.exports = mongoose.model('Rule', ruleSchema);
