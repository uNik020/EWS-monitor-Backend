const express = require("express");
const router = express.Router();
const auth = require("../../middleware/auth");
const { getNotifications, markRead } = require("./notification.controller");

router.get("/", auth, getNotifications);
router.patch("/:id/read", auth, markRead);

module.exports = router;
