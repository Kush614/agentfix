#!/usr/bin/env bash
# fund-wallets.sh — Checks wallet balances via Node.js and provides funding instructions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env not found. Run generate-keys.sh and setup-wallets.sh first."
  exit 1
fi

node -e "
const fs = require('fs');
const https = require('https');

const envFile = process.argv[1];
const envRaw = fs.readFileSync(envFile, 'utf8');
const env = {};
envRaw.split('\n').forEach(line => {
  const m = line.match(/^([A-Z_]+)=(.*)$/);
  if (m) env[m[1]] = m[2];
});

const API_KEY = env.CROSSMINT_API_KEY;
const BASE_URL = env.CROSSMINT_BASE_URL || 'https://www.crossmint.com/api/2025-06-09';

function request(urlStr) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlStr);
    const opts = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname + url.search,
      method: 'GET',
      headers: { 'X-API-KEY': API_KEY },
    };
    const req = https.request(opts, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => {
        try { resolve(JSON.parse(body)); }
        catch { resolve(body); }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function main() {
  console.log('=== FinFix: Wallet Balances ===');
  console.log('');

  const checks = [
    { name: 'Treasury', email: 'treasury@finfix.demo' },
    { name: 'Fixer Agent', email: 'fixer@finfix.demo' },
    { name: 'Escrow', email: 'escrow@finfix.demo' },
    { name: 'Fee Collector', email: 'fees@finfix.demo' },
  ];

  for (const w of checks) {
    try {
      const data = await request(BASE_URL + '/wallets/email:' + w.email + '/balances?chains=solana&tokens=usdc');
      const bal = Array.isArray(data) && data[0] ? data[0].balance || '0' : '0';
      console.log('  ' + w.name.padEnd(20) + bal + ' USDC');
    } catch (e) {
      console.log('  ' + w.name.padEnd(20) + 'Error: ' + e.message);
    }
  }

  console.log('');
  console.log('=== How to Fund Wallets ===');
  console.log('');
  console.log('1. Circle Faucet: https://faucet.circle.com/');
  console.log('   Network: Solana');
  console.log('   Treasury address: ' + (env.TREASURY_WALLET_ADDRESS || '(run setup-wallets.sh first)'));
  console.log('');
  console.log('2. Crossmint Telegram: https://t.me/crossmintdevs');
  console.log('');
  console.log('Recommended: Fund treasury with 200 USDC, balance monitor auto-distributes.');
}

main().catch(e => { console.error(e); process.exit(1); });
" "$ENV_FILE"
