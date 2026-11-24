const express = require("express");
const pool = require("../config/db");
const auth = require("../middleware/auth");

const router = express.Router();

// AMBIL PROFIL + STATISTIK
router.get("/", auth, async (req, res) => {
  try {
    const u = await pool.query(
      "SELECT id, nama, email, telepon, created_at FROM users WHERE id = $1",
      [req.userId],
    );
    if (u.rows.length === 0) {
      return res.status(404).json({ error: "User tidak ditemukan" });
    }

    const s = await pool.query(
      `SELECT
         COUNT(*)::int AS total,
         COUNT(*) FILTER (WHERE status = 'selesai')::int AS selesai,
         COUNT(*) FILTER (WHERE status = 'dibatalkan')::int AS dibatalkan,
         COALESCE(SUM(biaya) FILTER (WHERE status_bayar = 'lunas'), 0)::int AS total_bayar
       FROM orders WHERE user_id = $1`,
      [req.userId],
    );

    res.json({ user: u.rows[0], statistik: s.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UBAH PROFIL
router.put("/", auth, async (req, res) => {
  try {
    const { nama, telepon } = req.body;
    if (!nama || !nama.trim()) {
      return res.status(400).json({ error: "Nama wajib diisi" });
    }
    const hasil = await pool.query(
      `UPDATE users SET nama = $1, telepon = $2 WHERE id = $3
       RETURNING id, nama, email, telepon`,
      [nama.trim(), telepon || null, req.userId],
    );
    res.json({ pesan: "Profil diperbarui", user: hasil.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
