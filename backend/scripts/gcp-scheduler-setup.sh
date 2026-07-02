#!/bin/bash
# gcp-scheduler-setup.sh

PROJECT_ID=$(gcloud config get-value project)
BACKEND_URL="https://kivo-backend-uv7z7y-uc.a.run.app"
SECRET="your-scheduler-secret-here"

# 1. Safety Net Repayment (Daily at midnight)
gcloud scheduler jobs create http kivo-safety-net-repay \
  --schedule="0 0 * * *" \
  --uri="$BACKEND_URL/internal/safety-net-repay" \
  --http-method=POST \
  --headers="X-Scheduler-Secret=$SECRET" \
  --time-zone="America/Jamaica"

# 2. Credit Due Check (Daily at 00:01)
gcloud scheduler jobs create http kivo-credit-due \
  --schedule="1 0 * * *" \
  --uri="$BACKEND_URL/internal/credit-due" \
  --http-method=POST \
  --headers="X-Scheduler-Secret=$SECRET" \
  --time-zone="America/Jamaica"

# 3. Poll Lynk (Every 15 minutes)
gcloud scheduler jobs create http kivo-poll-lynk \
  --schedule="*/15 * * * *" \
  --uri="$BACKEND_URL/internal/poll-lynk" \
  --http-method=POST \
  --headers="X-Scheduler-Secret=$SECRET" \
  --time-zone="America/Jamaica"
