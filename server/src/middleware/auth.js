const jwt = require('jsonwebtoken');
const config = require('../config');

const blocklist = new Set();

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ message: 'Unauthorized' });
  if (blocklist.has(token)) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.user = payload;
    next();
  } catch (_) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
}

auth.blacklistAdd = (token) => {
  if (token) blocklist.add(token);
};

module.exports = auth;
