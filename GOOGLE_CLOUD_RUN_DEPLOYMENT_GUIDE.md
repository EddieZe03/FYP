# Google Cloud Run Deployment Guide (24/7 Backend)

This guide deploys your Flask phishing detection backend so your mobile app can call it anytime.

## 1) What you get

- Public HTTPS backend URL for Flutter
- Auto-restart and managed scaling
- Reduced timeout issues by keeping 1 warm instance

## 2) Prerequisites

- Google account with billing enabled
- Google Cloud CLI installed
- Docker not required for source deploy

## 3) Set project variables

Run these commands and replace values:

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export REGION="asia-southeast1"
export SERVICE_NAME="phish-guard-backend"
export BUCKET_NAME="YOUR_UNIQUE_MODEL_BUCKET"
```

## 4) Login and configure project

```bash
gcloud auth login
gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com storage.googleapis.com
```

## 5) Upload model to Cloud Storage

Your app already supports runtime model download via MODEL_DOWNLOAD_URL.

```bash
gsutil mb -l "$REGION" "gs://$BUCKET_NAME" || true
gsutil cp artifacts/ensemble_all_datasets_retry/soft_voting_ensemble.joblib "gs://$BUCKET_NAME/soft_voting_ensemble.joblib"
```

If bucket objects are private, create a signed URL and use that URL for MODEL_DOWNLOAD_URL.

## 6) Deploy to Cloud Run

From repository root:

```bash
gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --cpu 1 \
  --memory 2Gi \
  --timeout 120 \
  --min-instances 1 \
  --max-instances 5 \
  --set-env-vars PORT=8080,FLASK_ENV=production,MODEL_DOWNLOAD_URL=https://storage.googleapis.com/$BUCKET_NAME/soft_voting_ensemble.joblib
```

After deploy, Cloud Run prints your service URL:

```text
https://phish-guard-backend-xxxxx-xx.a.run.app
```

## 7) Verify backend health

```bash
curl -s "https://YOUR_SERVICE_URL/api/health"
```

Expected: JSON with ok true.

## 8) Connect Flutter app to cloud backend

Development run:

```bash
cd flutter_app
flutter run --dart-define=API_BASE_URL=https://YOUR_SERVICE_URL
```

Release build:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_SERVICE_URL
```

## 9) Cost and reliability notes

- Keeping min instances at 1 improves user experience but costs more.
- If budget is tight, set min instances to 0 and accept occasional cold starts.
- Monitor logs in Cloud Run to detect inference failures.

## 10) Optional hardening

- Add MODEL_DOWNLOAD_SHA256 environment variable for integrity check.
- Restrict CORS and only allow your app domains if needed.
- Use Cloud Monitoring alerts on high error rates.
