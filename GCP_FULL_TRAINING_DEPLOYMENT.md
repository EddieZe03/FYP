# Full Google Cloud Training & Deployment Guide

Complete step-by-step guide to train your phishing detection model on 1.5M URLs using Google Cloud, then safely replace your running backend.

## Prerequisites

✅ Google Cloud account with billing enabled  
✅ `gcloud` CLI installed locally  
✅ Your repo cloned locally  
✅ Backend already running on Cloud Run

---

## Phase 1: Setup Google Cloud Project

### Step 1.1: Set Project Variables

Replace these with your actual values and run:

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-southeast1"  # or your preferred region
export BUCKET_NAME="phish-guard-models"  # must be globally unique
export VM_NAME="phish-train-1"
export ZONE="asia-southeast1-b"  # zone within your region
```

Verify:
```bash
echo "Project: $PROJECT_ID, Region: $REGION, Bucket: $BUCKET_NAME"
```

### Step 1.2: Login to Google Cloud

```bash
gcloud auth login
gcloud auth application-default login
```

### Step 1.3: Set Default Project

```bash
gcloud config set project "$PROJECT_ID"
```

### Step 1.4: Enable Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  storage-api.googleapis.com \
  storage-component.googleapis.com
```

---

## Phase 2: Create Cloud Storage Bucket

### Step 2.1: Create Bucket

```bash
gsutil mb -l "$REGION" "gs://$BUCKET_NAME" 2>/dev/null || echo "Bucket already exists"
```

### Step 2.2: Verify Bucket Created

```bash
gsutil ls -b "gs://$BUCKET_NAME"
```

---

## Phase 3: Create and Configure Training VM

### Step 3.1: Create Compute Engine VM

This creates an 8-CPU, 64GB RAM machine (safe for 1.5M rows):

```bash
gcloud compute instances create "$VM_NAME" \
  --zone "$ZONE" \
  --machine-type n2-highmem-8 \
  --image-family debian-12 \
  --image-project debian-cloud \
  --boot-disk-size 100GB \
  --scopes storage-rw,compute-rw \
  --metadata enable-oslogin=true
```

**If you want faster training (16 CPUs, 128 GB):**
```bash
# Replace n2-highmem-8 with n2-highmem-16 in the command above
```

### Step 3.2: Wait for VM to Start

```bash
echo "Waiting for VM to start..."
sleep 30
gcloud compute instances describe "$VM_NAME" --zone "$ZONE" | grep status
```

Expected output: `status: RUNNING`

---

## Phase 4: Upload Feature Data to Cloud Storage

### Step 4.1: Check if Feature CSV Exists Locally

```bash
ls -lh data/url_features_enhanced_all_datasets.csv
```

If file doesn't exist, run feature extraction first:
```bash
python3 src/step2_enhanced_feature_extraction.py \
  --input data/processed_urls_with_all_datasets.csv \
  --output data/url_features_enhanced_all_datasets.csv
```

### Step 4.2: Upload Feature CSV to Cloud Storage

```bash
echo "Uploading feature data to Cloud Storage..."
gsutil -m cp data/url_features_enhanced_all_datasets.csv \
  "gs://$BUCKET_NAME/data/url_features_enhanced_all_datasets.csv"

# Verify upload
gsutil ls -lh "gs://$BUCKET_NAME/data/"
```

---

## Phase 5: SSH into VM and Run Training

### Step 5.1: SSH into VM

```bash
gcloud compute ssh "$VM_NAME" --zone "$ZONE"
```

You should now be inside the VM. Run all following commands inside the VM.

### Step 5.2: Install System Dependencies

```bash
sudo apt update
sudo apt install -y python3-pip git curl wget
```

### Step 5.3: Clone Repository

```bash
git clone https://github.com/EddieZe03/FYP.git
cd FYP
```

### Step 5.4: Install Python Dependencies

```bash
pip3 install --upgrade pip
pip3 install -r requirements.txt
```

This installs: scikit-learn, pandas, numpy, xgboost, lightgbm, catboost, joblib, flask, etc.

### Step 5.5: Download Feature Data from Cloud Storage

```bash
mkdir -p data
gsutil cp "gs://$BUCKET_NAME/data/url_features_enhanced_all_datasets.csv" data/
```

Verify download:
```bash
ls -lh data/url_features_enhanced_all_datasets.csv
```

### Step 5.6: Run Full Training (No Sampling)

This trains on all 1.5M rows. Takes 2–4 hours depending on machine type.

```bash
mkdir -p artifacts/ensemble_ultra_all_datasets

python3 src/step4_ultra_ensemble.py \
  --input data/url_features_enhanced_all_datasets.csv \
  --output-dir artifacts/ensemble_ultra_all_datasets \
  --no-sampling
```

**What to expect:**
- Initial dataset load: ~30 sec
- Feature engineering: ~30 sec
- Train/val/test split: ~10 sec
- Training base learners: ~1.5–2 hours
- Calibration: ~20 min
- Threshold optimization: ~5 min
- Total: ~2–2.5 hours

**Progress indicators:**
```
Dataset: 1550000 samples, 96 features
Class distribution: {0: 1200000, 1: 350000}
Train: 1085000 | Val: 232500 | Test: 232500

🔧 Training ultra ensemble...
📊 Calibrating probabilities...
⚡ Optimizing threshold...
📈 Validation Metrics: ...
📈 Test Metrics: ...
✓ Saved model to artifacts/ensemble_ultra_all_datasets/ultra_ensemble_calibrated.joblib
✓ Saved threshold to artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt
🚀 Ultra ensemble training complete!
```

### Step 5.7: Verify Training Artifacts

```bash
ls -lh artifacts/ensemble_ultra_all_datasets/
cat artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt
```

Expected files:
- `ultra_ensemble.joblib` (~300-500 MB)
- `ultra_ensemble_calibrated.joblib` (~300-500 MB)
- `ultra_threshold.txt` (single float value)
- `ultra_metrics.csv` (performance metrics)

### Step 5.8: Read the Optimal Threshold

```bash
THRESHOLD=$(cat artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt)
echo "Optimal threshold: $THRESHOLD"
```

Save this value — you'll need it for backend deployment.

---

## Phase 6: Upload Trained Model to Cloud Storage

### Step 6.1: Upload Calibrated Model

Inside the VM:

```bash
gsutil cp artifacts/ensemble_ultra_all_datasets/ultra_ensemble_calibrated.joblib \
  "gs://$BUCKET_NAME/models/ultra_ensemble_v2.joblib"
```

### Step 6.2: Verify Upload

```bash
gsutil ls -lh "gs://$BUCKET_NAME/models/"
```

You should see `ultra_ensemble_v2.joblib` listed.

### Step 6.3: Save Threshold for Later

```bash
echo "Exit VM and save threshold value from previous output"
```

Inside the VM, print the threshold one more time:
```bash
cat artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt
```

Example output: `0.565432`

### Step 6.4: Exit VM

```bash
exit
```

You're now back on your local machine.

---

## Phase 7: Stop or Delete Training VM (Optional)

### Step 7.1: Stop VM to Save Costs

If you might train again later:

```bash
gcloud compute instances stop "$VM_NAME" --zone "$ZONE"
```

Restart later with:
```bash
gcloud compute instances start "$VM_NAME" --zone "$ZONE"
```

### Step 7.2: Delete VM (Permanent)

If you're done with training:

```bash
gcloud compute instances delete "$VM_NAME" --zone "$ZONE" --quiet
```

---

## Phase 8: Update Your Running Cloud Run Backend

### Step 8.1: Get Current Backend URL

```bash
gcloud run services describe phish-guard-backend --region "$REGION" --format='value(status.url)'
```

Save this URL — you'll need it for Flutter testing.

### Step 8.2: Set Threshold Variable

Use the threshold value you saved earlier (e.g., `0.565432`):

```bash
THRESHOLD="0.565432"  # Replace with your actual threshold
```

### Step 8.3: Update Backend to Use New Model

```bash
gcloud run services update phish-guard-backend \
  --region "$REGION" \
  --update-env-vars \
    MODEL_DOWNLOAD_URL="https://storage.googleapis.com/$BUCKET_NAME/models/ultra_ensemble_v2.joblib",\
PHISHING_THRESHOLD="$THRESHOLD"
```

**Expected output:**
```
Updating Cloud Run service [phish-guard-backend] in region [asia-southeast1]...done.
✓ Cloud Run service [phish-guard-backend] has been successfully updated.
```

### Step 8.4: Wait for Redeployment

The backend redeploys automatically. Wait ~30–60 seconds.

```bash
echo "Waiting for backend to redeploy..."
sleep 60
```

---

## Phase 9: Verify New Backend

### Step 9.1: Test Health Endpoint

```bash
BACKEND_URL=$(gcloud run services describe phish-guard-backend \
  --region "$REGION" \
  --format='value(status.url)')

curl -s "$BACKEND_URL/api/health" | python3 -m json.tool
```

Expected output:
```json
{
  "ok": true,
  "model_path": "...",
  "threshold": 0.565432,
  "time": "2026-05-03T12:34:56Z"
}
```

### Step 9.2: Test Prediction Endpoint

```bash
curl -s "$BACKEND_URL/api/predict" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com"}' | python3 -m json.tool
```

Expected output:
```json
{
  "url": "https://www.google.com",
  "is_phishing": false,
  "confidence": 0.95,
  "risk_level": "safe",
  "timestamp": "2026-05-03T12:34:56Z"
}
```

### Step 9.3: Test with a Phishing URL

```bash
curl -s "$BACKEND_URL/api/predict" \
  -H "Content-Type: application/json" \
  -d '{"url": "http://123.45.67.89/paypal-login"}' | python3 -m json.tool
```

Should detect as phishing.

---

## Phase 10: Update Flutter App (If Needed)

If your Flutter app uses a hardcoded backend URL, it should already work since Cloud Run service URL remains stable.

To verify your Flutter app is connected:

```bash
cd flutter_app

# Development test
flutter run \
  --dart-define=API_BASE_URL="$BACKEND_URL"

# Or rebuild release APK
flutter build apk --release \
  --dart-define=API_BASE_URL="$BACKEND_URL"
```

---

## Phase 11: Rollback Plan (If Something Goes Wrong)

If the new model performs poorly, rollback to the old model:

### Step 11.1: Get Old Model URL

```bash
# List all model versions in Cloud Storage
gsutil ls "gs://$BUCKET_NAME/models/"
```

### Step 11.2: Rollback Command

```bash
gcloud run services update phish-guard-backend \
  --region "$REGION" \
  --update-env-vars \
    MODEL_DOWNLOAD_URL="https://storage.googleapis.com/$BUCKET_NAME/models/ultra_ensemble_v1.joblib"
```

The backend redeploys with the old model in ~30 seconds.

---

## Complete Command Summary (Copy-Paste)

For quick reference, here are all commands in order:

```bash
# Set variables
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-southeast1"
export BUCKET_NAME="phish-guard-models"
export VM_NAME="phish-train-1"
export ZONE="asia-southeast1-b"

# Phase 1: Setup
gcloud auth login
gcloud config set project "$PROJECT_ID"
gcloud services enable compute.googleapis.com storage-api.googleapis.com storage-component.googleapis.com

# Phase 2: Create bucket
gsutil mb -l "$REGION" "gs://$BUCKET_NAME" 2>/dev/null || echo "Bucket exists"

# Phase 3: Create VM
gcloud compute instances create "$VM_NAME" \
  --zone "$ZONE" \
  --machine-type n2-highmem-8 \
  --image-family debian-12 \
  --image-project debian-cloud \
  --boot-disk-size 100GB \
  --scopes storage-rw,compute-rw

sleep 30

# Phase 4: Upload data
python3 src/step2_enhanced_feature_extraction.py \
  --input data/processed_urls_with_all_datasets.csv \
  --output data/url_features_enhanced_all_datasets.csv

gsutil -m cp data/url_features_enhanced_all_datasets.csv \
  "gs://$BUCKET_NAME/data/"

# Phase 5: SSH and train (RUN INSIDE VM)
# gcloud compute ssh "$VM_NAME" --zone "$ZONE"
# Then inside VM:
# sudo apt update && sudo apt install -y python3-pip git
# git clone https://github.com/EddieZe03/FYP.git && cd FYP
# pip3 install -r requirements.txt
# mkdir -p data && gsutil cp "gs://$BUCKET_NAME/data/url_features_enhanced_all_datasets.csv" data/
# python3 src/step4_ultra_ensemble.py --input data/url_features_enhanced_all_datasets.csv --output-dir artifacts/ensemble_ultra_all_datasets --no-sampling
# THRESHOLD=$(cat artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt)
# echo "THRESHOLD=$THRESHOLD"
# gsutil cp artifacts/ensemble_ultra_all_datasets/ultra_ensemble_calibrated.joblib "gs://$BUCKET_NAME/models/ultra_ensemble_v2.joblib"
# exit

# Phase 7: Stop VM (optional)
gcloud compute instances stop "$VM_NAME" --zone "$ZONE"

# Phase 8: Update backend (run on local machine)
THRESHOLD="0.565432"  # Use the threshold from training output
gcloud run services update phish-guard-backend \
  --region "$REGION" \
  --update-env-vars \
    MODEL_DOWNLOAD_URL="https://storage.googleapis.com/$BUCKET_NAME/models/ultra_ensemble_v2.joblib",\
PHISHING_THRESHOLD="$THRESHOLD"

sleep 60

# Phase 9: Verify
BACKEND_URL=$(gcloud run services describe phish-guard-backend \
  --region "$REGION" \
  --format='value(status.url)')

curl -s "$BACKEND_URL/api/health" | python3 -m json.tool
```

---

## Troubleshooting

### Training VM runs out of memory

**Solution:** Use `n2-highmem-16` instead (128 GB RAM)

```bash
gcloud compute instances delete "$VM_NAME" --zone "$ZONE" --quiet
# Then recreate with n2-highmem-16
```

### Model download fails on backend

**Solution:** Check model exists in Cloud Storage

```bash
gsutil ls "gs://$BUCKET_NAME/models/"
# If not there, re-upload: gsutil cp artifacts/.../ultra_ensemble_calibrated.joblib "gs://$BUCKET_NAME/models/ultra_ensemble_v2.joblib"
```

### Backend health check fails

**Solution:** Check backend logs

```bash
gcloud run services describe phish-guard-backend --region "$REGION"
# For recent logs:
gcloud logging read "resource.service.name=phish-guard-backend" --limit 50 --format json
```

### VM stuck in creation

**Solution:** Delete and recreate

```bash
gcloud compute instances delete "$VM_NAME" --zone "$ZONE" --quiet
sleep 10
# Then recreate using Phase 3 commands
```

---

## Costs Summary

| Component | Estimated Cost |
|-----------|-----------------|
| Compute Engine VM (n2-highmem-8, 3 hours) | ~$1.20 |
| Cloud Storage (small data upload/download) | <$0.01 |
| Cloud Run update (redeploy) | Free |
| **Total** | **~$1.20** |

Cloud Run inference continues at $0.40/million predictions (no extra cost).

---

## Done! 🎉

Your new stronger model is now serving 1.5M-trained predictions to your Flutter app 24/7. Next time you want to retrain, repeat Phases 3–9.
