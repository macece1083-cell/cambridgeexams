const fs = require("fs");
const { Client } = require("pg");

const sql = fs.readFileSync("C:/Users/User/Documents/bayetav/supabase/schema.sql", "utf8");

const client = new Client({
  host: process.env.PGHOST || "db.obdykcwnlkyoetnbxmqn.supabase.co",
  port: Number(process.env.PGPORT || 5432),
  database: "postgres",
  user: process.env.PGUSER || "postgres",
  password: process.env.PGPASSWORD,
  ssl: { rejectUnauthorized: false },
});

(async () => {
  await client.connect();
  await client.query(sql);
  const result = await client.query(
    "select table_name from information_schema.tables where table_schema='public' and table_name in ('students','exam_scores','score_audit_log') order by table_name"
  );
  console.log(JSON.stringify(result.rows, null, 2));
  await client.end();
})().catch(async (error) => {
  console.error(error.stack || error.message);
  try {
    await client.end();
  } catch (_) {
    // ignore cleanup errors
  }
  process.exit(1);
});
