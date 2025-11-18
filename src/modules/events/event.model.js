const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  event_type: String, // new / old
  company: String,
  company_pan: String,
  event_name: String,
  description: String,
  flag: String,
  rbi_trigger: String,
  event_date: Date,
  identification_date: Date,
  event_raw: {},
}, { timestamps: true });

module.exports = mongoose.model('Event', eventSchema);
