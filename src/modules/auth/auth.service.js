const bcrypt = require('bcryptjs');
const { signToken } = require('../../utils/jwt');

// Pre-hashed demo password for "demo123"
const DEMO_USER = {
  email: 'demo@bank.com',
  password: "$2b$10$WKgztEdoHeWZbBZXAiL/7u7cnsVDOkBE0Oi2wPAhFsl24X1Y7mtly"
};

const login = async (email, password) => {
  //if (email !== DEMO_USER.email) throw new Error('Invalid credentials');
  if (email !== DEMO_USER.email) {
    console.log("❌ Email mismatch:", email);
    throw new Error("Invalid credentials");
  }

  const match = await bcrypt.compare(password, DEMO_USER.password);
  //if (!match) throw new Error('Invalid credentials');
  if (!match) {
    console.log("❌ Password wrong");
    console.log("Password entered:", password);
    console.log("Hash stored:", DEMO_USER.password);
    throw new Error("Invalid credentials pass");
  }

  return signToken({ email });
};

module.exports = { login };
