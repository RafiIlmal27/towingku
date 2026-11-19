const jwt = require("jsonwebtoken");

module.exports = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token tidak ada" });
  }
  try {
    const data = jwt.verify(header.split(" ")[1], process.env.JWT_SECRET);
    req.userId = data.id;
    next();
  } catch (err) {
    res.status(401).json({ error: "Token tidak valid atau kedaluwarsa" });
  }
};
