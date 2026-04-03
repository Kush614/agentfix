#!/usr/bin/env bash
# setup-wallets.sh — Creates 4 AgentFix wallets on Crossmint via Node.js
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env not found. Run generate-keys.sh first."
  exit 1
fi

node -e "
const fs = require('fs');
const https = require('https');
const path = require('path');

const envFile = process.argv[1];
const envRaw = fs.readFileSync(envFile, 'utf8');
const env = {};
envRaw.split('\n').forEach(line => {
  const m = line.match(/^([A-Z_]+)=(.*)$/);
  if (m) env[m[1]] = m[2];
});

const API_KEY = env.CROSSMINT_API_KEY;
const BASE_URL = env.CROSSMINT_BASE_URL || 'https://www.crossmint.com/api/2025-06-09';

if (!API_KEY || API_KEY.includes('XXXX')) {
  console.error('Error: Set a valid CROSSMINT_API_KEY in .env');
  process.exit(1);
}

const wallets = [
  { name: 'TREASURY', email: 'treasury@agentfix.demo', signer: env.TREASURY_WALLET_ADDRESS },
  { name: 'FIXER', email: 'fixer@agentfix.demo', signer: env.FIXER_WALLET_ADDRESS },
  { name: 'ESCROW', email: 'escrow@agentfix.demo', signer: env.ESCROW_WALLET_ADDRESS },
  { name: 'FEE_COLLECTOR', email: 'fees@agentfix.demo', signer: env.FEE_COLLECTOR_WALLET_ADDRESS },
];

function request(method, urlPath, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlPath, BASE_URL);
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname,
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': API_KEY,
      },
    };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);

    const req = https.request(opts, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(body) }); }
        catch { resolve({ status: res.statusCode, data: body }); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function main() {
  console.log('=== AgentFix: Wallet Setup ===');
  console.log('API: ' + BASE_URL);
  console.log('');

  let envContent = fs.readFileSync(envFile, 'utf8');

  for (const w of wallets) {
    console.log('Creating wallet: ' + w.name + ' (' + w.email + ')...');

    const res = await request('POST', BASE_URL + '/wallets', {
      chainType: 'solana',
      type: 'smart',
      config: {
        adminSigner: {
          type: 'external-wallet',
          address: w.signer,
        },
      },
      owner: 'email:' + w.email,
    });

    if (res.status >= 200 && res.status < 300) {
      const addr = res.data.address || res.data.walletAddress || 'unknown';
      console.log('  Success! Address: ' + addr);

      if (addr !== 'unknown' && addr !== w.signer) {
        const key = w.name + '_WALLET_ADDRESS';
        const regex = new RegExp('^' + key + '=.*$', 'm');
        envContent = envContent.replace(regex, key + '=' + addr);
        console.log('  Updated ' + key + ' in .env');
      }
    } else {
      console.log('  HTTP ' + res.status);
      console.log('  ' + JSON.stringify(res.data));
    }
    console.log('');
  }

  fs.writeFileSync(envFile, envContent);
  console.log('=== Wallet setup complete ===');
}

main().catch(e => { console.error(e); process.exit(1); });
" "$ENV_FILE"
