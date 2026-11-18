const express = require("express");
const cors = require("cors");
require("dotenv").config();
const pool = require("./config/db");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/auth", require("./routes/auth"));
app.use("/api/orders", require("./routes/orders"));
app.use("/api/profile", require("./routes/profile"));

app.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT COUNT(*) FROM drivers");
    res.json({
      pesan: "API TowingKu berjalan",
      jumlah_driver: result.rows[0].count,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(process.env.PORT, () => {
  console.log(`Server berjalan di http://localhost:${process.env.PORT}`);
});
