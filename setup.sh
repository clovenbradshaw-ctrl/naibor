#!/bin/bash
# NaiBOR Local Webhook Setup
# n8n provides the webhook password, everything runs locally

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== NaiBOR Local Webhook Setup ===${NC}"
echo ""

# Generate a random webhook secret if not already set
if [ ! -f .env ]; then
    GENERATED_SECRET=$(openssl rand -hex 32)
    GENERATED_PASSWORD=$(openssl rand -base64 16 | tr -d '=/+' | head -c 20)

    cat > .env <<EOL
# n8n credentials (used to log into the n8n UI)
N8N_USER=admin
N8N_PASSWORD=${GENERATED_PASSWORD}

# Webhook secret — n8n sends this to authenticate deploy requests
# This is the password n8n uses when calling the webhook
WEBHOOK_SECRET=${GENERATED_SECRET}
EOL

    echo -e "${GREEN}Generated .env with credentials:${NC}"
    echo ""
    echo -e "  n8n UI:           ${YELLOW}http://localhost:5678${NC}"
    echo -e "  n8n User:         ${YELLOW}admin${NC}"
    echo -e "  n8n Password:     ${YELLOW}${GENERATED_PASSWORD}${NC}"
    echo ""
    echo -e "  Webhook Secret:   ${YELLOW}${GENERATED_SECRET}${NC}"
    echo ""
    echo -e "  Site:             ${YELLOW}http://localhost:8080${NC}"
    echo -e "  Webhook Server:   ${YELLOW}http://localhost:3000${NC}"
    echo ""
else
    echo -e "${YELLOW}.env already exists — skipping generation${NC}"
    echo ""
fi

echo -e "${GREEN}Starting services...${NC}"
docker compose up -d --build

echo ""
echo -e "${GREEN}=== All services running ===${NC}"
echo ""
echo "  Site:             http://localhost:8080"
echo "  n8n Dashboard:    http://localhost:5678"
echo "  Webhook Server:   http://localhost:3000/health"
echo ""
echo "=== n8n Workflow Setup ==="
echo ""
echo "1. Open n8n at http://localhost:5678"
echo "2. Create a new workflow"
echo "3. Add a 'Webhook' trigger node (or GitHub trigger)"
echo "4. Add an 'HTTP Request' node pointed at:"
echo "     POST http://naibor-webhook:3000/webhook/deploy"
echo "5. Set the header: x-webhook-secret = <your WEBHOOK_SECRET from .env>"
echo "6. Activate the workflow"
echo ""
echo "n8n handles the password — it sends the secret on every deploy call."
echo "The webhook server validates it before pulling new code."
