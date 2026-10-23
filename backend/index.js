require("dotenv").config();
const express = require("express");
const { Pool } = require("pg");

const app = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get("/salud", async (req, res) => {
  try {
    const r = await pool.query("SELECT COUNT(*) AS tablas FROM information_schema.tables WHERE table_schema = 'public'");
    res.json({ estado: "ok", tablas: Number(r.rows[0].tablas) });
  } catch (err) {
    res.status(500).json({ estado: "error", detalle: err.message });
  }
});

app.listen(process.env.PORT, () => {
  console.log(`Servidor en http://localhost:${process.env.PORT}`);
});