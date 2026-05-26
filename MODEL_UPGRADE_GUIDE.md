# Enhanced Model Upgrade Guide

## Overview
This guide explains the ultra-powerful ensemble improvements made to your phishing detection model.

## What's Been Improved

### 1. **Advanced Feature Engineering** 
   - **File**: `src/step2_enhanced_feature_extraction.py`
   - **New Features Added** (15+):
     - **Punycode Detection**: Identifies IDN homograph attack attempts (e.g., `xn--` domains)
     - **Brand Impersonation Score**: Counts phishing target brands in URL (Amazon, PayPal, Google, etc.)
     - **Entropy Variants**: Separate entropy calculations for domain, path, and query
     - **Rare Character Detection**: Identifies obfuscation attempts
     - **Domain Structure Analysis**: 
       - Longest label in domain (unusually long = suspicious)
       - Domain label count
       - Multiple hyphens in domain (common in phishing)
     - **Port Analysis**: Non-standard ports detection (8080, 8888, etc.)
     - **URL Structure**:
       - Fragment URL detection (hiding real URL in anchor)
       - Fragment length analysis
       - URL length categorization
     - **Character Distribution**: Consonant-vowel ratio, numeric-to-letter ratio

### 2. **Ultra-Powerful Ensemble Architecture**
   - **File**: `src/step4_ultra_ensemble.py`
   - **Base Learners** (5-6):
     1. **Random Forest**: 200 estimators, depth 22, captures complex patterns
     2. **Gradient Boosting**: 300 estimators, optimized for sequential learning
     3. **XGBoost**: 450 estimators, industry-standard gradient boosting
     4. **Extra Trees**: 220 estimators, additional diversity
     5. **LightGBM** (if available): 400 estimators, fast + memory-efficient
     6. **CatBoost** (if available): 350 iterations, handles categorical data well

   - **Meta-Learner**: Logistic Regression with class weighting
   - **Stacking Approach**: 3-fold cross-validation for robust out-of-fold predictions
   - **Passthrough Features**: Base learner outputs + original features fed to meta-learner

### 3. **Probability Calibration**
   - **Method**: Isotonic regression (more flexible than Platt scaling)
   - **Benefit**: Calibrated probabilities → more reliable confidence scores
   - **Impact**: Risk levels ("Low", "Medium", "High", "Critical") better reflect actual risk

### 4. **Advanced Threshold Optimization**
   - **Methods Used**:
     - F-beta search: Balances precision and recall (beta=2.0 favors recall/phishing detection)
     - Youden's J statistic: Maximizes sensitivity + specificity
     - Precision floor constraint: Ensures minimum precision (70%) to avoid false alarms
   
   - **Result**: Dynamic optimal threshold instead of fixed 0.5

### 5. **Comprehensive Evaluation**
   - **Metrics Tracked**:
     - Accuracy, Precision, Recall, F1, F2-score
     - ROC-AUC, PR-AUC (more important for imbalanced phishing data)
     - Sensitivity, Specificity, FPR, FNR
     - Confusion matrix (TP, TN, FP, FN)

## How to Use

### Option A: Full Pipeline (Recommended for First Run)
```bash
bash scripts/train_ultra_ensemble.sh
```

This will:
1. Extract enhanced features from your dataset
2. Train the ultra ensemble with calibration
3. Compare with your old model
4. Show deployment instructions

### Option B: Step-by-Step

**Step 1: Extract Enhanced Features**
```bash
python3 src/step2_enhanced_feature_extraction.py \
    --input data/processed_urls_with_all_datasets.csv \
    --output data/url_features_enhanced_all_datasets.csv \
    --whois-cache artifacts/whois_cache.csv
```

**Step 2: Train Ultra Ensemble**
```bash
python3 src/step4_ultra_ensemble.py \
    --input data/url_features_enhanced_all_datasets.csv \
    --output-dir artifacts/ensemble_ultra_all_datasets \
    --optimize-beta 2.0 \
    --min-precision 0.70 \
    --calibration-method isotonic
```

### Option C: Production Deployment

After training completes, deploy with:
```bash
export FINAL_MODEL_PATH="artifacts/ensemble_ultra_all_datasets/ultra_ensemble_calibrated.joblib"
export PHISHING_THRESHOLD=$(cat artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt)
python3 app.py
```

Or in your Flutter app:
```bash
cd flutter_app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend-url
```

## Installation of Optional Packages

For maximum performance, install:
```bash
pip install lightgbm catboost
```

If not installed, the ultra ensemble will still work with RF, GB, XGB, and ET.

## Performance Expectations

Based on ensemble learning theory:
- **Accuracy**: Typically +1-3% improvement from feature enhancement alone
- **Recall (Phishing Detection)**: +3-8% improvement (catching more phishing)
- **Precision**: +2-5% improvement (fewer false alarms)
- **ROC-AUC**: +0.02-0.05 improvement in probability ranking
- **Calibration**: Confidence scores now align with actual correctness

Your improvements depend on:
- Dataset quality and size
- Original feature quality
- Class balance (how many phishing vs. legitimate URLs)

## Troubleshooting

### LightGBM/CatBoost not installed
- The script will still work with 4 base learners instead of 6
- To install: `pip install lightgbm catboost`
- Both are optional but recommended for +1-2% boost

### Memory issues during training
- Reduce batch size in training data
- Use `--no-sampling` flag (train on full dataset)
- Disable LightGBM: comment out lines in `build_ultra_ensemble()`

### Threshold seems too high/low
- Adjust `--min-precision` flag (lower = more aggressive phishing detection)
- Adjust `--optimize-beta` flag (higher = prefer recall over precision)

## Advanced Tuning

Edit `step4_ultra_ensemble.py` to adjust:
- Number of estimators (lines 160-190)
- Learning rates (0.05 is conservative; raise to 0.1+ for faster training)
- Max depths (increase for more complex patterns)
- Class weights (increase second value to favor phishing detection)

## Integration with Threat Intelligence

Your backend already has threat-intel fusion. With the ultra ensemble:
1. Model outputs probability → risk level
2. Threat-intel (URLhaus) provides live verdict
3. Hybrid fusion: Conservative escalation if either signals high-risk

This gives you defense-in-depth:
- **Model**: Catches zero-day phishing via learned patterns
- **Threat-intel**: Catches known-bad URLs instantly

## Next Steps

1. **Monitor Performance**: Log predictions on new URLs; track false positives/negatives
2. **Retrain Monthly**: New phishing evolves; retrain with recent data
3. **A/B Testing**: Deploy ultra ensemble to 10% of users first; compare with old model
4. **Feature Feedback**: If certain phishing bypasses your model, add new features
5. **Calibration Check**: Verify probability confidence aligns with outcomes

## Questions?

- Check `artifacts/ensemble_ultra_all_datasets/ultra_metrics.csv` for detailed metrics
- Review logs during training for any warnings
- Compare threshold values: check `artifacts/ensemble_ultra_all_datasets/ultra_threshold.txt`
