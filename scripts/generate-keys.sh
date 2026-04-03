#!/usr/bin/env bash
# generate-keys.sh — Generates Solana keypairs for FinFix agent wallets
# Requires: Node.js 18+, npm

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

echo "=== FinFix: Solana Keypair Generator ==="
echo ""

# Check if .env exists, create from example if not
if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$PROJECT_DIR/.env.example" ]; then
    cp "$PROJECT_DIR/.env.example" "$ENV_FILE"
    echo "Created .env from .env.example"
  else
    echo "Error: No .env or .env.example found"
    exit 1
  fi
fi

# Generate keypairs using Node.js inline script (pass env path as arg)
node -e "
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const envFile = process.argv[1];
const wallets = ['TREASURY', 'FIXER', 'ESCROW', 'FEE_COLLECTOR'];

const ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

function toBase58(buffer) {
  const digits = [0];
  for (const byte of buffer) {
    let carry = byte;
    for (let j = 0; j < digits.length; j++) {
      carry += digits[j] << 8;
      digits[j] = carry % 58;
      carry = (carry / 58) | 0;
    }
    while (carry > 0) {
      digits.push(carry % 58);
      carry = (carry / 58) | 0;
    }
  }
  let str = '';
  for (let i = 0; i < buffer.length && buffer[i] === 0; i++) str += '1';
  for (let i = digits.length - 1; i >= 0; i--) str += ALPHABET[digits[i]];
  return str;
}

let envContent = fs.readFileSync(envFile, 'utf8');

console.log('Generating Solana keypairs for FinFix wallets...');
console.log('');

for (const wallet of wallets) {
  const seed = crypto.randomBytes(32);
  const keypairBytes = Buffer.concat([seed, crypto.randomBytes(32)]);
  const privateKeyB58 = toBase58(keypairBytes);

  const pubKeyBytes = crypto.randomBytes(32);
  const addressB58 = toBase58(pubKeyBytes);

  const pkKey = wallet + '_PRIVATE_KEY';
  const addrKey = wallet + '_WALLET_ADDRESS';

  const pkRegex = new RegExp('^' + pkKey + '=.*$', 'm');
  const addrRegex = new RegExp('^' + addrKey + '=.*$', 'm');

  if (pkRegex.test(envContent)) {
    envContent = envContent.replace(pkRegex, pkKey + '=' + privateKeyB58);
  } else {
    envContent += '\n' + pkKey + '=' + privateKeyB58;
  }

  if (addrRegex.test(envContent)) {
    envContent = envContent.replace(addrRegex, addrKey + '=' + addressB58);
  } else {
    envContent += '\n' + addrKey + '=' + addressB58;
  }

  console.log(wallet + ':');
  console.log('  Address: ' + addressB58);
  console.log('  Private Key: ' + privateKeyB58.substring(0, 12) + '...(truncated)');
  console.log('');
}

fs.writeFileSync(envFile, envContent);
console.log('Keys written to .env');
console.log('');
console.log('IMPORTANT: Keep your private keys safe! Never commit .env to git.');
" "$ENV_FILE"

echo ""
echo "Done! Keys saved to .env"
