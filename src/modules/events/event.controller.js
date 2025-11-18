const Event = require('./event.model');

const createEvent = async (req, res, next) => {
  try {
    const payload = req.body;

    if (Array.isArray(payload)) {
      const created = await Event.insertMany(payload);
      return res.status(201).json(created);
    } else {
      const created = await Event.create(payload);
      return res.status(201).json(created);
    }

  } catch (err) {
    next(err);
  }
};


const getEvents = async (req, res, next) => {
  try {
    const events = await Event.find().sort({ createdAt: -1 });
    res.json(events);
  } catch (err) {
    next(err);
  }
};

module.exports = { createEvent, getEvents };
