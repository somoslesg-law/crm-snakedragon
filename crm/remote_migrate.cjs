const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const config = {
  connectionString: 'postgres://admin:a32b9e0439bc4904b8d5@187.124.77.182:5432/crm_dragon',
  ssl: false
};

async function migrate() {
  const client = new Client(config);
  try {
    await client.connect();
    console.log('Connected to remote database.');

    const files = [
      '../snake_dragon_crm_v1.sql',
      '../snake_dragon_crm_v2.sql',
      '../snake_dragon_crm_v3.sql'
    ];

    for (const file of files) {
      console.log(`Executing ${file}...`);
      const sql = fs.readFileSync(path.join(__dirname, file), 'utf8');
      
      // Split by semicolon and filter out empty strings to avoid some common pg issues with large blocks
      // Actually, pg.query can handle multiple statements if they are valid.
      // But for very large files, it might be better to send them as one big string if the driver supports it.
      // The pg driver's client.query(sql) handles multiple statements separated by semicolons.
      
      await client.query(sql);
      console.log(`Finished ${file}.`);
    }

    console.log('All migrations completed successfully!');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await client.end();
  }
}

migrate();
