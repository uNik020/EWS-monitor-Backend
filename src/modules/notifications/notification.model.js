const mongoose = require("mongoose");

const NotificationSchema = new mongoose.Schema(
  {
    user: { type: String, required: true }, // email or userId
    title: { type: String, required: true },
    message: { type: String },
    alertId: { type: mongoose.Schema.Types.ObjectId, ref: "Alert" },
    read: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Notification", NotificationSchema);
