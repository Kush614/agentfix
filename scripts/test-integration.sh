#!/usr/bin/env bash
# test-integration.sh — Sends 5 test purchase requests to FinFix webhook
# Requires: curl, jq

set -euo pipefail

WEBHOOK_URL="${N8N_WEBHOOK_BASE_URL:-http://localhost:5678}/webhook/finfix/purchase"

echo "=== FinFix Integration Test ==="
echo "Webhook: $WEBHOOK_URL"
echo ""

send_request() {
  local test_num="$1"
  local description="$2"
  local payload="$3"

  echo "--- Test $test_num: $description ---"
  echo "Sending: $(echo "$payload" | jq -c .)"
  echo ""

  local response
  local http_code

  response=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>&1) || true

  http_code=$(echo "$response" | tail -n1)
  local body
  body=$(echo "$response" | sed '$d')

  echo "HTTP $http_code"
  echo "$body" | jq . 2>/dev/null || echo "$body"
  echo ""
  echo ""
}

# Test 1: Clean Amazon URL (should succeed directly via Crossmint Checkout)
send_request 1 \
  "Direct Amazon purchase (should succeed via World Store)" \
  '{
    "product_url": "https://www.amazon.com/dp/B09V3KXJPB",
    "quantity": 1,
    "max_price": 30,
    "user_email": "test-buyer@example.com",
    "agent_id": "test-agent-1"
  }'

# Test 2: Broken merchant page (should trigger Data Fix)
send_request 2 \
  "Broken merchant page (should trigger DATA_FIX)" \
  '{
    "product_url": "https://example.com/products/wireless-headphones-pro-2024",
    "quantity": 1,
    "max_price": 150,
    "user_email": "test-buyer@example.com",
    "agent_id": "test-agent-2"
  }'

# Test 3: Shopify store with anti-bot (should reroute to World Store)
send_request 3 \
  "Shopify store checkout (should trigger CHECKOUT_FIX)" \
  '{
    "product_url": "https://some-shopify-store.myshopify.com/products/usb-c-cable-3pack",
    "quantity": 3,
    "max_price": 15,
    "user_email": "test-buyer@example.com",
    "agent_id": "test-agent-3"
  }'

# Test 4: Request that may need balance top-up
send_request 4 \
  "High-value purchase (may trigger auto-top-up)" \
  '{
    "product_url": "https://www.amazon.com/dp/B0BSHF7WHW",
    "quantity": 1,
    "max_price": 500,
    "user_email": "test-buyer@example.com",
    "agent_id": "test-agent-4"
  }'

# Test 5: Out-of-stock item
send_request 5 \
  "Out-of-stock item (should return graceful failure)" \
  '{
    "product_url": "https://example.com/products/limited-edition-sold-out-widget",
    "quantity": 1,
    "max_price": 25,
    "user_email": "test-buyer@example.com",
    "agent_id": "test-agent-5"
  }'

echo "=== Integration Tests Complete ==="
echo ""
echo "Check the FinFix dashboard for results: file://$(cd "$(dirname "$0")/../dashboard" && pwd)/index.html"
echo "Check Google Sheets audit trail for logged transactions."
