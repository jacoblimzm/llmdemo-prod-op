#!/bin/bash

# Deploy script for llm-prod-app-jacob-vm* backend VMs
# Usage: ./deploy-to-jacob-vms.sh

set -e

# Configuration
GCP_PROJECT="mcse-sandbox"
ZONE="us-central1-a"
PROJECT_DIR="llmdemo-prod-op"
COMPOSE_FILE="docker-compose-backend.yml"
GIT_BRANCH="main"
GIT_REMOTE="origin"
HEALTH_URL="https://my.dd-demo-sg-llm.com/menu"
IAP_FLAG="--tunnel-through-iap"

VMS=(
  "llm-prod-app-jacob-vm1"
  "llm-prod-app-jacob-vm2"
  "llm-prod-app-jacob-vm3"
  "llm-prod-app-jacob-vm4"
  "llm-prod-app-jacob-vm5"
  "llm-prod-app-jacob-vm6"
  "llm-prod-app-jacob-vm7"
  "llm-prod-app-jacob-vm8"
  "llm-prod-app-jacob-vm9"
  "llm-prod-app-jacob-vm10"
)

echo "🚀 Starting deployment to ${#VMS[@]} VMs..."
echo "   Project: $GCP_PROJECT | Dir: ~/$PROJECT_DIR | Branch: $GIT_BRANCH"
echo "=================================================="

run_on_vm() {
  local vm_name=$1
  local command=$2
  echo "📡 Running on $vm_name: $command"
  gcloud compute ssh "$vm_name" \
    --project="$GCP_PROJECT" \
    --zone="$ZONE" \
    $IAP_FLAG \
    --command="$command" \
    --quiet
}

deploy_to_vm() {
  local vm_name=$1
  echo ""
  echo "🔄 Deploying to $vm_name..."
  echo "----------------------------------------"

  run_on_vm "$vm_name" "test -d ~/$PROJECT_DIR || { echo 'Missing ~/$PROJECT_DIR — run Step 3 deploy first'; exit 1; }"
  run_on_vm "$vm_name" "cd ~/$PROJECT_DIR && git fetch $GIT_REMOTE && git checkout $GIT_BRANCH && git pull $GIT_REMOTE $GIT_BRANCH"
  run_on_vm "$vm_name" "cd ~/$PROJECT_DIR && docker compose -f $COMPOSE_FILE down"
  run_on_vm "$vm_name" "cd ~/$PROJECT_DIR && docker compose -f $COMPOSE_FILE up -d --build"

  sleep 5

  echo "✅ Checking containers on $vm_name..."
  run_on_vm "$vm_name" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
  run_on_vm "$vm_name" "curl -sf http://localhost:5000/menu > /dev/null && echo '/menu OK' || echo '/menu FAILED'"

  echo "✅ $vm_name deployment complete!"
}

deploy_parallel() {
  echo "🚀 Starting parallel deployment..."
  for vm in "${VMS[@]}"; do
    deploy_to_vm "$vm" &
  done
  wait
  echo ""
  echo "🎉 All VMs deployed successfully!"
}

deploy_sequential() {
  echo "🚀 Starting sequential deployment..."

  for vm in "${VMS[@]}"; do
    echo ""
    echo "📋 Next VM: $vm"
    read -p "Deploy to $vm? (y/n/q to quit): " confirm

    case $confirm in
      [Yy]* ) deploy_to_vm "$vm" ;;
      [Nn]* ) echo "⏭️  Skipping $vm" ;;
      [Qq]* ) echo "🛑 Deployment stopped by user"; return ;;
      * ) echo "Please answer y, n, or q" ;;
    esac
  done
  echo ""
  echo "🎉 Sequential deployment complete!"
}

health_check() {
  echo ""
  echo "🏥 Running health checks (via IAP SSH)..."
  echo "================================"

  for vm in "${VMS[@]}"; do
    echo "Checking $vm..."
    if run_on_vm "$vm" "curl -sf http://localhost:5000/menu > /dev/null"; then
      echo "✅ $vm - Healthy"
    else
      echo "❌ $vm - Not responding"
    fi
  done

  if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Load balancer: $HEALTH_URL"
  else
    echo "⚠️  Load balancer not reachable yet: $HEALTH_URL"
  fi
}

echo "Choose deployment method:"
echo "1) Sequential (safer, easier to debug)"
echo "2) Parallel (faster)"
echo "3) Health check only"
read -p "Enter choice (1-3): " choice

case $choice in
  1) deploy_sequential; health_check ;;
  2) deploy_parallel; health_check ;;
  3) health_check ;;
  *) echo "Invalid choice. Using sequential deployment."; deploy_sequential; health_check ;;
esac

echo ""
echo "🎯 Deployment complete!"
echo "🌐 Test at: $HEALTH_URL"
