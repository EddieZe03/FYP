# Integrating New Dataset for Ensemble Model Improvement

This guide walks you through integrating the `Phishing_Legitimate_full.csv` dataset to improve your ensemble learning model.

## Dataset Overview

- **Size**: 10,000 samples (5,000 phishing + 5,000 legitimate)
- **Features**: 48 pre-extracted URL and HTML features
- **Source**: Mendeley Data - Phishing Dataset for Machine Learning
- **Time Period**: January-June 2015 & May-June 2017
- **Quality**: Extracted using Selenium WebDriver (more robust than regex parsing)

## Integration Steps

### Step 1: Prepare the External Dataset

Convert the external dataset to match your training pipeline format:

```bash
python src/step1_integrate_external_dataset.py \
    --input Phishing_Legitimate_full.csv \
    --output data/external_dataset_prepared.csv
```

This script:
- ✅ Loads the CSV file
- ✅ Removes the ID column (not needed for training)
- ✅ Renames `CLASS_LABEL` → `is_phishing`
- ✅ Validates the data (no missing values)
- ✅ Saves prepared dataset to `data/external_dataset_prepared.csv`

### Step 2: Choose Your Training Strategy

You have two options:

#### **Option A: Train Separate Models (Recommended First)**

Train models on the external dataset independently to see improvement:

```bash
# Train base models on external dataset
python src/step3_model_training.py \
    --input data/external_dataset_prepared.csv \
    --output-dir artifacts/external_models

# Train ensemble on external dataset
python src/step4_ensemble_model.py \
    --input data/external_dataset_prepared.csv \
    --model-output artifacts/ensemble/external_ensemble.joblib
```

Compare metrics to your existing models to see the improvement.

#### **Option B: Merge Datasets (If Compatible)**

Combine the external dataset with your existing data for more training data:

```bash
python src/merge_datasets.py
```

This creates `data/merged_training_data.csv`.

Then train:

```bash
# Train with combined dataset
python src/step3_model_training.py \
    --input data/merged_training_data.csv \
    --output-dir artifacts/merged_base_models

python src/step4_ensemble_model.py \
    --input data/merged_training_data.csv \
    --model-output artifacts/ensemble/merged_ensemble.joblib
```

## Training Command Summary

### Using Only External Dataset

```bash
# Step 1: Prepare
python src/step1_integrate_external_dataset.py

# Step 2: Train base models
python src/step3_model_training.py \
    --input data/external_dataset_prepared.csv \
    --output-dir artifacts/external_models

# Step 3: Train ensemble
python src/step4_ensemble_model.py \
    --input data/external_dataset_prepared.csv \
    --model-output artifacts/ensemble/external_ensemble.joblib
```

### Using Merged Dataset

```bash
# Step 1: Prepare external data
python src/step1_integrate_external_dataset.py

# Step 2: Merge with existing data
python src/merge_datasets.py

# Step 3: Train base models
python src/step3_model_training.py \
    --input data/merged_training_data.csv \
    --output-dir artifacts/merged_base_models

# Step 4: Train ensemble
python src/step4_ensemble_model.py \
    --input data/merged_training_data.csv \
    --model-output artifacts/ensemble/merged_ensemble.joblib
```

## Understanding the Dataset Features

The 48 features include:

### URL Structure Features
- `UrlLength`, `PathLevel`, `PathLength`, `QueryLength`
- `NumDots`, `NumDash`, `NumUnderscore`, `NumPercent`, `NumHash`
- `SubdomainLevel`, `HostnameLength`, `NumNumericChars`

### Domain Features  
- `DomainInSubdomains`, `DomainInPaths`, `IpAddress`
- `HttpsInHostname`, `NoHttps`, `AtSymbol`

### Page Content Features
- `NumSensitiveWords`, `EmbeddedBrandName`
- `PctExtHyperlinks`, `PctExtResourceUrls`, `ExtFavicon`
- `PopUpWindow`, `IframeOrFrame`, `MissingTitle`

### Behavior Features
- `RightClickDisabled`, `FakeLinkInStatusBar`
- `RandomString`, `TildeSymbol`, `DoubleSlashInPath`

### Form & Security Features
- `InsecureForms`, `RelativeFormAction`, `ExtFormAction`, `AbnormalFormAction`
- `SubmitInfoToEmail`, `ImagesOnlyInForm`

## Monitor Performance Improvements

After training, compare the metrics:

```bash
# View metrics for base models
cat artifacts/external_models/baseline_metrics.csv
cat artifacts/merged_base_models/baseline_metrics.csv

# View ensemble metrics
cat artifacts/ensemble/*.csv
```

Look for improvements in:
- ✅ **Accuracy**: Overall correctness
- ✅ **Precision**: Reduce false positives (legitimate marked as phishing)
- ✅ **Recall**: Reduce false negatives (missed phishing attacks)
- ✅ **F1-Score**: Balance between precision and recall

## Expected Benefits

- **Larger training set**: ~10k additional diverse samples
- **Different data collection period**: Captures phishing evolution (2015-2017 vs your data)
- **Robust features**: Selenium-extracted features vs regex parsing
- **Better generalization**: Model trained on diverse datasets typically performs better

## Troubleshooting

### If merge fails: "No common features found"
The external dataset has different feature names than your existing data. 
**Solution**: Use Option A (train separate models on external dataset)

### If training fails: "Missing columns"
Ensure you're using the correct input file (prepared dataset, not original)

### If ensemble performance decreases
This can happen if datasets have different distributions.
**Solution**: Keep training the ensemble on your original data and use external dataset for testing/validation

## Next Steps

1. Try Option A first (training on external dataset alone)
2. Compare metrics with your existing models
3. If improved, try merging datasets (Option B) for even better performance
4. Update `app.py` to use the best performing model
