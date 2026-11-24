const express = require("express");
const pool = require("../config/db");
const auth = require("../middleware/auth");

const router = express.Router();

// BUAT PESANAN
router.post("/", auth, async (req, res) => {
  try {
    const {
      jemput_lat,
      jemput_lng,
      tujuan_lat,
      tujuan_lng,
      jarak_km,
      biaya,
      jenis_kendaraan,
    } = req.body;

    if (
      jemput_lat == null ||
      jemput_lng == null ||
      tujuan_lat == null ||
      tujuan_lng == null
    ) {
      return res
        .status(400)
        .json({ error: "Lokasi jemput dan tujuan wajib diisi" });
    }

    const driver = await pool.query(
      `SELECT id FROM drivers WHERE online = TRUE
       ORDER BY (lat - $1)^2 + (lng - $2)^2 LIMIT 1`,
      [jemput_lat, jemput_lng],
    );
    const driverId = driver.rows.length > 0 ? driver.rows[0].id : null;

    const hasil = await pool.query(
      `INSERT INTO orders
        (user_id, driver_id, jemput_lat, jemput_lng, tujuan_lat, tujuan_lng,
         jemput_alamat, tujuan_alamat, jarak_km, biaya, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'menunggu')
       RETURNING *`,
      [
        req.userId,
        driverId,
        jemput_lat,
        jemput_lng,
        tujuan_lat,
        tujuan_lng,
        "Kendaraan: " + (jenis_kendaraan || "-"),
        null,
        jarak_km,
        biaya,
      ],
    );

    res
      .status(201)
      .json({ pesan: "Pesanan berhasil dibuat", order: hasil.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// RIWAYAT PESANAN
router.get("/", auth, async (req, res) => {
  try {
    const hasil = await pool.query(
      "SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC",
      [req.userId],
    );
    res.json({ orders: hasil.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DETAIL + TRACKING (simulasi)
router.get("/:id", auth, async (req, res) => {
  try {
    const hasil = await pool.query(
      `SELECT o.*, d.nama AS driver_nama, d.telepon AS driver_telepon,
              d.plat_towing, d.lat AS driver_lat, d.lng AS driver_lng,
              EXTRACT(EPOCH FROM (NOW() - o.created_at)) AS detik
       FROM orders o
       LEFT JOIN drivers d ON d.id = o.driver_id
       WHERE o.id = $1 AND o.user_id = $2`,
      [req.params.id, req.userId],
    );

    if (hasil.rows.length === 0) {
      return res.status(404).json({ error: "Pesanan tidak ditemukan" });
    }

    const o = hasil.rows[0];
    const detik = Number(o.detik);

    const jLat = Number(o.jemput_lat),
      jLng = Number(o.jemput_lng);
    const tLat = Number(o.tujuan_lat),
      tLng = Number(o.tujuan_lng);
    const dLat = Number(o.driver_lat),
      dLng = Number(o.driver_lng);

    const antara = (a, b, p) => a + (b - a) * Math.min(Math.max(p, 0), 1);

    let status = "menunggu";
    let lat = dLat,
      lng = dLng;

    if (o.status === "dibatalkan") {
      status = "dibatalkan";
    } else if (detik < 10) {
      status = "menunggu";
    } else if (detik < 40) {
      status = "menuju_lokasi";
      const p = (detik - 10) / 30;
      lat = antara(dLat, jLat, p);
      lng = antara(dLng, jLng, p);
    } else if (detik < 70) {
      status = "dalam_perjalanan";
      const p = (detik - 40) / 30;
      lat = antara(jLat, tLat, p);
      lng = antara(jLng, tLng, p);
    } else {
      status = "selesai";
      lat = tLat;
      lng = tLng;
    }

    if (status !== o.status) {
      await pool.query("UPDATE orders SET status = $1 WHERE id = $2", [
        status,
        o.id,
      ]);
    }

    res.json({
      order: {
        id: o.id,
        status,
        biaya: o.biaya,
        jarak_km: o.jarak_km,
        metode_bayar: o.metode_bayar,
        status_bayar: o.status_bayar || "belum_bayar",
        jemput_lat: jLat,
        jemput_lng: jLng,
        tujuan_lat: tLat,
        tujuan_lng: tLng,
      },
      driver: {
        nama: o.driver_nama,
        telepon: o.driver_telepon,
        plat_towing: o.plat_towing,
        lat,
        lng,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// BATALKAN PESANAN
router.patch("/:id/cancel", auth, async (req, res) => {
  try {
    const hasil = await pool.query(
      `SELECT id, status,
              EXTRACT(EPOCH FROM (NOW() - created_at)) AS detik
       FROM orders WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.userId],
    );

    if (hasil.rows.length === 0) {
      return res.status(404).json({ error: "Pesanan tidak ditemukan" });
    }

    const o = hasil.rows[0];

    if (o.status === "dibatalkan") {
      return res.status(400).json({ error: "Pesanan sudah dibatalkan" });
    }
    if (o.status !== "menunggu" || Number(o.detik) >= 10) {
      return res.status(400).json({
        error: "Pesanan tidak bisa dibatalkan karena driver sudah berangkat",
      });
    }

    await pool.query("UPDATE orders SET status = 'dibatalkan' WHERE id = $1", [
      o.id,
    ]);
    res.json({ pesan: "Pesanan dibatalkan" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// BAYAR PESANAN (simulasi)
router.patch("/:id/pay", auth, async (req, res) => {
  try {
    const { metode } = req.body;
    const valid = ["tunai", "transfer", "ewallet"];
    if (!valid.includes(metode)) {
      return res.status(400).json({ error: "Metode pembayaran tidak valid" });
    }

    const hasil = await pool.query(
      `SELECT id, status, status_bayar,
              EXTRACT(EPOCH FROM (NOW() - created_at)) AS detik
       FROM orders WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.userId],
    );

    if (hasil.rows.length === 0) {
      return res.status(404).json({ error: "Pesanan tidak ditemukan" });
    }

    const o = hasil.rows[0];

    if (o.status === "dibatalkan") {
      return res.status(400).json({ error: "Pesanan sudah dibatalkan" });
    }
    if (o.status !== "selesai" && Number(o.detik) < 70) {
      return res.status(400).json({ error: "Pesanan belum selesai" });
    }
    if (o.status_bayar === "lunas") {
      return res.status(400).json({ error: "Pesanan sudah dibayar" });
    }

    await pool.query(
      "UPDATE orders SET metode_bayar = $1, status_bayar = 'lunas', status = 'selesai' WHERE id = $2",
      [metode, o.id],
    );
    res.json({ pesan: "Pembayaran berhasil" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
