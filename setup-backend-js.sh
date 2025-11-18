#!/bin/bash
set -e

echo ">>> Starting backend setup (CommonJS Node.js) ..."

# Ensure we run from project root
ROOT="$(pwd)"
echo "Project root: $ROOT"

# Back up existing index.js if present
if [ -f "index.js" ]; then
  echo "Found existing index.js — making a backup to index.js.bak"
  cp index.js index.js.bak || true
fi

# Ensure package.json exists
if [ ! -f "package.json" ]; then
  echo "No package.json found — initializing npm"
  npm init -y
else
  echo "package.json exists — keeping it and will add scripts"
fi

# Install runtime deps
echo "Installing runtime dependencies..."
npm install express mongoose dotenv jsonwebtoken bcryptjs cors morgan

# Install dev deps
echo "Installing dev dependencies..."
npm install -D nodemon

# Create src folder, back up if exists
if [ -d "src" ]; then
  echo "Existing src/ found — backing up to src-backup-$(date +%s)"
  mv src "src-backup-$(date +%s)"
fi

mkdir -p src
mkdir -p src/config
mkdir -p src/middleware
mkdir -p src/modules/auth
mkdir -p src/modules/rules
mkdir -p src/modules/events
mkdir -p src/modules/alerts
mkdir -p src/utils

echo "Creating files..."

# app.js
cat > src/app.js <<'JS'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { connectDB } = require('./config/db');
const authRoutes = require('./modules/auth/auth.routes');
const ruleRoutes = require('./modules/rules/rule.routes');
const eventRoutes = require('./modules/events/event.routes');
const alertRoutes = require('./modules/alerts/alert.routes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

connectDB();

app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(morgan('dev'));

app.get('/', (_, res) => res.json({ message: 'EWS API Running' }));

app.use('/auth', authRoutes);
app.use('/rules', ruleRoutes);
app.use('/events', eventRoutes);
app.use('/alerts', alertRoutes);

app.use(errorHandler);

module.exports = app;
JS

# server.js
cat > src/server.js <<'JS'
const app = require('./app');
const port = process.env.PORT || 5000;

app.listen(port, () => console.log(`🚀 Server running on port ${port}`));
JS

# db.js
cat > src/config/db.js <<'JS'
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/ews_demo';
    await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });
    console.log('✅ MongoDB connected');
  } catch (err) {
    console.error('❌ MongoDB connection failed', err);
    process.exit(1);
  }
};

module.exports = { connectDB };
JS

# middleware auth.js
cat > src/middleware/auth.js <<'JS'
const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ message: 'Unauthorized - no token' });
  const token = header.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Unauthorized - bad header' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'devsecret');
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};
JS

# middleware errorHandler.js
cat > src/middleware/errorHandler.js <<'JS'
module.exports = function (err, req, res, next) {
  console.error(err);
  res.status(err.status || 500).json({ message: err.message || 'Server Error' });
};
JS

# utils/jwt.js
cat > src/utils/jwt.js <<'JS'
const jwt = require('jsonwebtoken');

const signToken = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET || 'devsecret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

module.exports = { signToken };
JS

# Auth module (service/controller/routes)
cat > src/modules/auth/auth.service.js <<'JS'
const bcrypt = require('bcryptjs');
const { signToken } = require('../../utils/jwt');

// Pre-hashed demo password for "demo123"
const DEMO_USER = {
  email: 'demo@bank.com',
  password: '$2a$10$C3UJy/PEF9o8V1jVze2ewaY2iNDPM1KbhOfyuuG7vRfgPkZoRb2Ka',
};

const login = async (email, password) => {
  if (email !== DEMO_USER.email) throw new Error('Invalid credentials');
  const match = await bcrypt.compare(password, DEMO_USER.password);
  if (!match) throw new Error('Invalid credentials');
  return signToken({ email });
};

module.exports = { login };
JS

cat > src/modules/auth/auth.controller.js <<'JS'
const { login } = require('./auth.service');

const loginHandler = async (req, res) => {
  const { email, password } = req.body;
  try {
    const token = await login(email, password);
    res.json({ token });
  } catch (err) {
    res.status(401).json({ message: err.message });
  }
};

module.exports = { loginHandler };
JS

cat > src/modules/auth/auth.routes.js <<'JS'
const express = require('express');
const router = express.Router();
const { loginHandler } = require('./auth.controller');

router.post('/login', loginHandler);

module.exports = router;
JS

# Rules module
cat > src/modules/rules/rule.model.js <<'JS'
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
JS

cat > src/modules/rules/rule.controller.js <<'JS'
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
JS

cat > src/modules/rules/rule.routes.js <<'JS'
const express = require('express');
const router = express.Router();
const { createRules, getRules } = require('./rule.controller');
const auth = require('../../middleware/auth');

router.post('/', auth, createRules);
router.get('/', auth, getRules);

module.exports = router;
JS

# Events module
cat > src/modules/events/event.model.js <<'JS'
const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    company: String,
    event_name: String,
    event_raw: {},
  },
  { timestamps: true }
);

module.exports = mongoose.model('Event', eventSchema);
JS

cat > src/modules/events/event.controller.js <<'JS'
const Event = require('./event.model');

const createEvent = async (req, res, next) => {
  try {
    const event = await Event.create(req.body);
    res.json(event);
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
JS

cat > src/modules/events/event.routes.js <<'JS'
const express = require('express');
const router = express.Router();
const { createEvent, getEvents } = require('./event.controller');
const auth = require('../../middleware/auth');

router.post('/', auth, createEvent);
router.get('/', auth, getEvents);

module.exports = router;
JS

# Alerts module
cat > src/modules/alerts/alert.model.js <<'JS'
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
JS

cat > src/modules/alerts/alert.controller.js <<'JS'
const Alert = require('./alert.model');

const createAlert = async (req, res, next) => {
  try {
    const alert = await Alert.create(req.body);
    res.json(alert);
  } catch (err) {
    next(err);
  }
};

const getAlerts = async (req, res, next) => {
  try {
    const alerts = await Alert.find().sort({ createdAt: -1 });
    res.json(alerts);
  } catch (err) {
    next(err);
  }
};

module.exports = { createAlert, getAlerts };
JS

cat > src/modules/alerts/alert.routes.js <<'JS'
const express = require('express');
const router = express.Router();
const { createAlert, getAlerts } = require('./alert.controller');
const auth = require('../../middleware/auth');

router.post('/', auth, createAlert);
router.get('/', auth, getAlerts);

module.exports = router;
JS

# .env
cat > .env <<'ENDENV'
PORT=5000
MONGO_URI=mongodb://127.0.0.1:27017/ews_demo
JWT_SECRET=supersecret123
JWT_EXPIRES_IN=7d
ENDENV

# Update package.json scripts (careful not to clobber)
echo "Updating package.json scripts..."
node - <<'NODE'
const fs = require('fs');
const p = JSON.parse(fs.readFileSync('package.json','utf8'));
p.scripts = p.scripts || {};
p.scripts.start = p.scripts.start || 'node src/server.js';
p.scripts.dev = 'nodemon src/server.js';
fs.writeFileSync('package.json', JSON.stringify(p, null, 2));
console.log('Updated package.json with start/dev scripts.');
NODE

echo "✅ Setup complete."
echo "Run the server with:"
echo "  npm run dev"
echo ""
echo "Quick test (after server is running):"
echo "  curl -X POST http://localhost:5000/auth/login -H \"Content-Type: application/json\" -d '{\"email\":\"demo@bank.com\",\"password\":\"demo123\"}'"
