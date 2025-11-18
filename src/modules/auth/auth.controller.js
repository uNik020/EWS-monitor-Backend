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
