"""Retrain ensemble model with phishing_site_urls dataset integrated.

This script retrains the ensemble model using:
1. Original training datasets (if available)
2. phishing_site_urls dataset (507K URLs)

Usage:
    python retrain_with_phishing_site_urls.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import (
    GradientBoostingClassifier,
    RandomForestClassifier,
    VotingClassifier,
)
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
)

from src.step2_feature_extraction import extract_features_from_urls
from src.step3_model_training import calculate_f_beta_threshold


def load_and_prepare_data(
    phishing_urls_path: Path = Path("data/phishing_site_urls_prepared.csv"),
) -> tuple[pd.DataFrame, pd.Series]:
    """Load prepared data and extract features."""

    print("Loading phishing_site_urls prepared dataset...")
    df = pd.read_csv(phishing_urls_path)
    print(f"Dataset shape: {df.shape}")
    print(f"Label distribution:\n{df['Label'].value_counts()}")

    # Take a balanced sample if dataset is too large (to manage memory)
    # We'll use all 507K but limit to prevent memory issues
    if len(df) > 100000:
        print("\nSampling data to manage feature extraction (max 100K URLs for initial run)...")
        # Sample equally from phishing and legitimate to maintain balance
        phishing_df = df[df["Label"] == "Phishing"]
        legitimate_df = df[df["Label"] == "Legitimate"]
        
        max_per_class = 50000
        phishing_sample = phishing_df.sample(
            n=min(len(phishing_df), max_per_class), random_state=42
        )
        legitimate_sample = legitimate_df.sample(
            n=min(len(legitimate_df), max_per_class), random_state=42
        )
        
        df = pd.concat([phishing_sample, legitimate_sample], ignore_index=True)
        print(f"Sampled dataset shape: {df.shape}")
        print(f"Sampled label distribution:\n{df['Label'].value_counts()}")

    print("\nExtracting features from URLs...")
    features = extract_features_from_urls(
        df["URL"],
        whois_cache_path=Path("artifacts/whois_cache.csv"),
        whois_timeout=0.2,
        whois_max_lookups=10,  # Reduced for speed
        whois_max_errors=5,
        dns_timeout=0.2,
        dns_max_lookups=100,
        dns_max_errors=20,
    )

    # Map labels to binary (0=Legitimate, 1=Phishing)
    labels = (df["Label"] == "Phishing").astype(int)

    return features, labels


def retrain_ensemble(
    X: pd.DataFrame,
    y: pd.Series,
    test_size: float = 0.2,
    random_state: int = 42,
) -> tuple[VotingClassifier, float, dict]:
    """Retrain ensemble with improved parameters."""

    print("\nSplitting data into train/test sets...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )

    print(f"Train set size: {len(X_train)}")
    print(f"Test set size: {len(X_test)}")
    print(f"Train label distribution:\n{pd.Series(y_train).value_counts()}")

    print("\nTraining base models...")
    
    # Random Forest
    print("  - Training Random Forest...")
    rf = RandomForestClassifier(
        n_estimators=100,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1,
    )
    rf.fit(X_train, y_train)

    # Gradient Boosting
    print("  - Training Gradient Boosting...")
    gb = GradientBoostingClassifier(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=5,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
    )
    gb.fit(X_train, y_train)

    # XGBoost (if available)
    try:
        from xgboost import XGBClassifier

        print("  - Training XGBoost...")
        xgb = XGBClassifier(
            n_estimators=100,
            learning_rate=0.1,
            max_depth=5,
            min_child_weight=1,
            random_state=42,
            n_jobs=-1,
        )
        xgb.fit(X_train, y_train)
        base_models = [("rf", rf), ("gb", gb), ("xgb", xgb)]
    except ImportError:
        print("  - XGBoost not available, using RF + GB only")
        base_models = [("rf", rf), ("gb", gb)]

    # Ensemble
    print("\nCreating soft-voting ensemble...")
    ensemble = VotingClassifier(estimators=base_models, voting="soft", n_jobs=-1)
    ensemble.fit(X_train, y_train)

    # Evaluate
    print("\nEvaluating ensemble on test set...")
    y_pred = ensemble.predict(X_test)
    y_proba = ensemble.predict_proba(X_test)[:, 1]

    metrics = {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "f1": float(f1_score(y_test, y_pred, zero_division=0)),
        "auc_roc": float(roc_auc_score(y_test, y_proba)) if len(np.unique(y_test)) > 1 else 0.0,
    }

    print(f"\nMetrics:")
    for metric, value in metrics.items():
        print(f"  {metric}: {value:.4f}")

    # Calculate F-beta threshold
    print("\nCalculating F-beta (beta=2.0) optimized threshold...")
    threshold = calculate_f_beta_threshold(y_test, y_proba, beta=2.0)
    print(f"Optimal threshold: {threshold:.6f}")

    return ensemble, threshold, metrics


def main() -> None:
    # Load and prepare data
    features, labels = load_and_prepare_data()

    # Retrain ensemble
    ensemble, threshold, metrics = retrain_ensemble(features, labels)

    # Save artifacts
    print("\nSaving artifacts...")
    output_dir = Path("artifacts/final_submission_with_phishing_urls")
    output_dir.mkdir(parents=True, exist_ok=True)

    model_path = output_dir / "ensemble_retrained.joblib"
    joblib.dump(ensemble, model_path)
    print(f"  Model saved to {model_path}")

    threshold_path = output_dir / "ensemble_threshold_retrained.txt"
    with open(threshold_path, "w") as f:
        f.write(str(threshold))
    print(f"  Threshold saved to {threshold_path}")

    metrics_path = output_dir / "retrain_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"  Metrics saved to {metrics_path}")

    print(f"\nRetraining complete!")
    print(f"New model ready for evaluation at {output_dir}")


if __name__ == "__main__":
    main()
