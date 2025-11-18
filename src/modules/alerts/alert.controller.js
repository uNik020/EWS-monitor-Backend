const Alert = require('./alert.model');
const mongoose = require('mongoose');

/**
 * Get all alerts (with optional query params for filtering/search/pagination)
 */
const getAlerts = async (req, res, next) => {
  try {
    const { q, severity, status, page = 1, limit = 100 } = req.query;

    const filter = {};
    if (severity) filter.severity = severity;
    if (status) filter.status = status;
    if (q) {
      // text-ish search on company or event_name
      filter.$or = [
        { company: { $regex: q, $options: 'i' } },
        { event_name: { $regex: q, $options: 'i' } },
      ];
    }

    const skip = (Math.max(Number(page), 1) - 1) * Number(limit);

    const alerts = await Alert.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit));

    const total = await Alert.countDocuments(filter);

    res.json({ data: alerts, meta: { total, page: Number(page), limit: Number(limit) } });
  } catch (err) {
    next(err);
  }
};

/**
 * Get single alert by id
 */
const getAlertById = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid id' });

    const alert = await Alert.findById(id);
    if (!alert) return res.status(404).json({ message: 'Alert not found' });

    res.json(alert);
  } catch (err) {
    next(err);
  }
};

/**
 * Create alert(s)
 * Accepts single alert object or array of alerts
 */
const createAlert = async (req, res, next) => {
  try {
    const payload = req.body;
    if (Array.isArray(payload)) {
      const created = await Alert.insertMany(payload);
      return res.status(201).json(created);
    } else {
      const created = await Alert.create(payload);
      return res.status(201).json(created);
    }
  } catch (err) {
    next(err);
  }
};

/**
 * Patch alert: record an action in history and update status
 * Body: { action: "approve"|"stop"|"request_info"|"close", comment?: string, actor?: string }
 */
const patchAlert = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { action, comment, actor } = req.body;
    if (!action) return res.status(400).json({ message: 'Action required' });

    if (!mongoose.Types.ObjectId.isValid(id)) return res.status(400).json({ message: 'Invalid id' });

    const alert = await Alert.findById(id);
    if (!alert) return res.status(404).json({ message: 'Alert not found' });

    // map action -> new status
    const statusMap = {
      approve: 'Approved',
      stop: 'Stopped',
      request_info: 'Info Requested',
      close: 'Closed',
    };
    const newStatus = statusMap[action] || alert.status;

    const entry = {
      id: new mongoose.Types.ObjectId().toHexString(),
      action,
      comment: comment || null,
      actor: actor || req.user?.email || 'system',
      timestamp: new Date().toISOString(),
    };

    alert.status = newStatus;
    alert.history = Array.isArray(alert.history) ? alert.history : [];
    alert.history.push(entry);

    await alert.save();

    // Auto-create notification
    const Notification = require("../notifications/notification.model");
    await Notification.create({
      user: actor || req.user?.email,
      title: `Alert ${newStatus}`,
      message: `Alert for ${alert.company} (${alert.event_name}) was ${action}.`,
      alertId: alert._id,
    });

    res.json(alert);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAlerts,
  getAlertById,
  createAlert,
  patchAlert,
};
