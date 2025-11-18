const Notification = require("./notification.model");

const getNotifications = async (req, res, next) => {
  try {
    const user = req.user?.email;
    const notifs = await Notification.find({ user }).sort({ createdAt: -1 });
    res.json(notifs);
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const notif = await Notification.findByIdAndUpdate(
      id,
      { read: true },
      { new: true }
    );
    res.json(notif);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  markRead,
};
