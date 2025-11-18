const Rule = require('./rule.model');

const createRules = async (req, res, next) => {
  try {
    const rules = req.body;
    const saved = await Rule.insertMany(rules);
    res.json(saved);
  } catch (err) {
    next(err);
  }
};

const getRules = async (req, res, next) => {
  try {
    const rules = await Rule.find().sort({ createdAt: -1 });
    res.json(rules);
  } catch (err) {
    next(err);
  }
};

module.exports = { createRules, getRules };
