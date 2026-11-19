const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");

const router = express.Router();

// REGISTER
router.post("/register", async (req, res) => {
  try {
    const { nama, email, password, telepon } = req.body;

    if (!nama || !email || !password) {
      return res
        .status(400)
        .json({ error: "Nama, email, dan password wajib diisi" });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: "Password minimal 6 karakter" });
    }

    const cek = await pool.query("SELECT id FROM users WHERE email = $1", [
      email,
    ]);
    if (cek.rows.length > 0) {
      return res.status(400).json({ error: "Email sudah terdaftar" });
    }

    const hash = await bcrypt.hash(password, 10);
    const hasil = await pool.query(
      "INSERT INTO users (nama, email, password, telepon) VALUES ($1, $2, $3, $4) RETURNING id, nama, email, telepon",
      [nama, email, hash, telepon || null],
    );

    res.status(201).json({ pesan: "Registrasi berhasil", user: hasil.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email dan password wajib diisi" });
    }

    const hasil = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (hasil.rows.length === 0) {
      return res.status(401).json({ error: "Email atau password salah" });
    }

    const user = hasil.rows[0];
    const cocok = await bcrypt.compare(password, user.password);
    if (!cocok) {
      return res.status(401).json({ error: "Email atau password salah" });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    res.json({
      pesan: "Login berhasil",
      token,
      user: {
        id: user.id,
        nama: user.nama,
        email: user.email,
        telepon: user.telepon,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
