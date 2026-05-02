# FYP
Phishing URL Detection System using Ensemble Learning

## Step 0: Download and Prepare Raw Datasets

Script:

- `src/step0_download_data.py`

Purpose:

- Normalizes raw sources into the exact files used by Step 1:
- `data/phishtank.csv`
- `data/openphish.csv`
- `data/kaggle_legitimate.csv`

Notes:

- OpenPhish defaults to `https://openphish.com/feed.txt`.
- PhishTank and legitimate datasets are typically provided as local CSV files.
- Each source must contain one URL column (`url`, `URL`, `link`, or `Link`).

Run:

```bash
python src/step0_download_data.py \
	--phishtank-path data/raw/phishtank_input.csv \
	--legitimate-path data/raw/kaggle_legitimate_input.csv
```

You can also use URL sources with `--phishtank-url` and `--legitimate-url`.

## Step 1: Data Loading and Preprocessing

This repository now includes a starter preprocessing script:

- `src/step1_data_preprocessing.py`

### What it does

- Loads phishing dataset file(s) and one legitimate dataset file
- Combines them into one dataset
- Creates a binary label column `is_phishing`
- Removes missing rows and duplicate URLs
- Keeps only URLs starting with `http://` or `https://`

### Expected CSV format

Each CSV should include a URL column named one of:

- `url`
- `URL`
- `link`
- `Link`

### Run

Install dependencies first:

```bash
pip install -r requirements.txt
```

Then run:

```bash
python src/step1_data_preprocessing.py \
	--phishing data/PhiUSIIL_Phishing_URL_Dataset.csv \
	--legitimate data/new_data_urls.csv \
	--output data/processed_urls.csv
```

If you have multiple phishing CSV files, pass them all after `--phishing`.

Output file example: `data/processed_urls.csv`

## Step 2: Feature Extraction

Script:

- `src/step2_feature_extraction.py`

Extracted features (aligned with your report categories):

- Lexical features: `url_length`, `num_dots`, `has_at_symbol`, `has_hyphen`, `uses_ip_address`, `num_subdomains`, `path_length`, `query_length`, `num_digits`, `num_special_chars`, `suspicious_keyword_count`, `url_entropy`
- Domain-based features: `domain_age_days`, `whois_registrar_available`, `dns_resolves`, `domain_age_available`, `is_new_domain_30d`, `has_suspicious_tld`
- Heuristic features: `uses_https`, `redirection_count`

Notes for real-world performance:

- WHOIS is kept enabled for domain-age intelligence.
- WHOIS results are cached in `artifacts/whois_cache.csv` to avoid repeated network lookups.
- The model does not rely only on WHOIS; lexical and heuristic features remain active when WHOIS data is unavailable.

Run:

```bash
python src/step2_feature_extraction.py \
	--input data/processed_urls.csv \
	--output data/url_features.csv \
	--whois-cache artifacts/whois_cache.csv
```

If your environment blocks WHOIS/DNS sockets and Step 2 hangs, use stricter limits:

```bash
python src/step2_feature_extraction.py \
	--input data/processed_urls.csv \
	--output data/url_features.csv \
	--whois-cache artifacts/whois_cache.csv \
	--whois-timeout 1 \
	--whois-max-lookups 50 \
	--whois-max-errors 20 \
	--dns-timeout 0.5 \
	--dns-max-lookups 5000 \
	--dns-max-errors 200
```

## Step 3: Train Individual Models

Script:

- `src/step3_model_training.py`

Models trained:

- Random Forest
- Gradient Boosting
- XGBoost

Run:

```bash
python src/step3_model_training.py \
	--input data/url_features.csv \
	--output-dir artifacts/base_models
```

Outputs:

- Saved model files in `artifacts/base_models/`
- Baseline metrics CSV (Table 7 metrics): `artifacts/base_models/baseline_metrics.csv`
- Error analysis CSV (TN, FP, FN, TP, FPR, FNR): `artifacts/base_models/baseline_error_analysis.csv`

## Step 4: Soft Voting Ensemble

Script:

- `src/step4_ensemble_model.py`

Run:

```bash
python src/step4_ensemble_model.py \
	--input data/url_features.csv \
	--model-output artifacts/ensemble/soft_voting_ensemble.joblib
```

Outputs:

- Ensemble model: `artifacts/ensemble/soft_voting_ensemble.joblib`
- Ensemble metrics (Table 7 metrics): `artifacts/ensemble/ensemble_metrics.csv`
- Ensemble error analysis: `artifacts/ensemble/ensemble_error_analysis.csv`

## Model Upgrade Notes (Phishing Recall)

To improve detection of hard phishing URLs, the pipeline now includes:

- Additional path-based features (`path_depth`, `suspicious_path_keyword_count`, `has_wp_path`, `has_encoded_chars`)
- Threshold optimization in training (F-beta, default `beta=2.0`) with saved threshold files
- Hybrid safety rule in app inference for high-risk phishing-kit style URL structures

### Retrain Upgraded Models

```bash
python src/step2_feature_extraction.py \
	--input data/processed_urls.csv \
	--output data/url_features.csv \
	--whois-cache artifacts/whois_cache.csv \
	--whois-timeout 1 \
	--whois-max-lookups 50 \
	--whois-max-errors 20 \
	--dns-timeout 0.5 \
	--dns-max-lookups 5000 \
	--dns-max-errors 200
```

```bash
python src/step3_model_training.py \
	--input data/url_features.csv \
	--output-dir artifacts/base_models \
	--optimize-beta 2.0
```

When available, app inference auto-loads `artifacts/base_models/xgboost_threshold.txt`.

## Optional: Train with PhishingData.csv (Tabular Features)

If you have a dataset like `PhishingData.csv` (engineered columns such as `SSLfinal_State`, `Page_Rank`, `DNSRecord`, etc.), you can train with:

```bash
python src/step3_train_phishingdata.py \
	--input data/PhishingData.csv \
	--output-dir artifacts/phishingdata_models
```

Outputs:

- `artifacts/phishingdata_models/metrics.csv`
- model files and optimized threshold files
- `feature_columns.txt` schema

Important note:

- This tabular path is excellent for benchmarking and report comparison.
- It is not directly drop-in for the browser/mobile URL-only inference flow unless you can compute the same engineered features at runtime.

## Evaluation Metrics (Table 7 Alignment)

The training pipeline reports the exact metrics from your Table 7:

- `accuracy`
- `precision`
- `recall`
- `f1`

For stronger discussion in your report, it also saves confusion-matrix-based risk metrics:

- `tn`, `fp`, `fn`, `tp`
- `fpr` (false positive rate)
- `fnr` (false negative rate)

## Suggested File Organization for Copilot

To keep Copilot focused, keep prompts and code separated by phase:

- `src/step1_data_preprocessing.py`
- `src/step2_feature_extraction.py`
- `src/step3_model_training.py`
- `src/step4_ensemble_model.py`

## System Architecture Mapping

This section maps your architecture diagram modules to implemented files.

| Architecture Block | Implementation |
|---|---|
| URL Input Module | `templates/index.html` form input and validation (`required`) |
| Communication / API Layer | Flask routes in `app.py` (`/`, `/predict`) |
| Backend / ML Inference Engine | Model loading and inference logic in `app.py` |
| Preprocessing Module | `src/step1_data_preprocessing.py` |
| Feature Extraction Module | `src/step2_feature_extraction.py` |
| Ensemble Learning Model | `src/step3_model_training.py`, `src/step4_ensemble_model.py` |
| Output Handler Module | `src/output_handler.py` + rendered result sections in `templates/index.html` |

### Output Handler Module (Implemented)

The output handler now performs exactly the responsibilities in your architecture:

- Formats prediction output for UI presentation
- Assigns risk level (`Low`, `Medium-Low`, `Medium`, `High`, `Critical`)
- Generates actionable recommendations based on result and risk

Primary file:

- `src/output_handler.py`

## 24/7 Backend Deployment (Google Cloud Run)

If you want your backend online all the time for mobile users, deploy Flask to Cloud Run and set a permanent HTTPS API URL in Flutter.

### Why Cloud Run

- Managed deployment (no manual server maintenance)
- HTTPS URL by default
- Auto-restart and autoscaling
- Can be configured for near always-on by setting minimum instances

### Quick Steps

1. Install and login to Google Cloud CLI.
2. Create/select a project and enable billing.
3. Create a Cloud Storage bucket and upload your model file (`soft_voting_ensemble.joblib`) if you do not want it baked into image.
4. Deploy the backend container to Cloud Run.
5. Set Flutter API URL to your Cloud Run service URL.

### Example deploy command

```bash
gcloud run deploy phish-guard-backend \
	--source . \
	--region asia-southeast1 \
	--allow-unauthenticated \
	--port 8080 \
	--memory 2Gi \
	--cpu 1 \
	--timeout 120 \
	--min-instances 1 \
	--set-env-vars PORT=8080,FLASK_ENV=production,MODEL_DOWNLOAD_URL=https://storage.googleapis.com/YOUR_BUCKET/soft_voting_ensemble.joblib
```

Notes:

- `--min-instances 1` reduces cold starts and keeps service warm for mobile clients.
- Replace region with your nearest location.
- If your model is private, use signed URL or service-account-based access.

### Flutter connection

Use your Cloud Run URL in Flutter:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR_CLOUD_RUN_URL
```

For release builds:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_CLOUD_RUN_URL
```

### Health check

```bash
curl -s https://YOUR_CLOUD_RUN_URL/api/health
```

Expected response includes: `{"ok": true, "service": "phish-guard" ...}`

## Hybrid Ablation Benchmark (Model-Only vs Hybrid)

To generate report-ready evidence that compares model-only detection against
hybrid detection (model + threat intelligence fusion), run:

```bash
python scripts/benchmark_hybrid_ablation.py
```

Generated artifacts:

- `artifacts/results/hybrid_ablation_predictions.csv`
- `artifacts/results/hybrid_ablation_metrics.json`

The JSON summary includes:

- baseline metrics (`model_only`)
- upgraded metrics (`hybrid`)
- improvement deltas (`accuracy_delta`, `recall_delta`, `fpr_delta`, `fnr_delta`)
