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
const notificationRoutes = require('./modules/notifications/notification.routes');

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
app.use('/notifications', notificationRoutes);


app.use(errorHandler);

module.exports = app;
