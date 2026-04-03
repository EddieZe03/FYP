"""Automated retraining pipeline: Integrate all datasets and train models.

This script orchestrates the complete retraining workflow:
1. Combines all datasets (including new urldata.csv)
2. Extracts features from combined dataset
3. Trains individual base models
4. Trains ensemble model

Usage:
    python retrain_with_all_data.py
"""

import subprocess
import sys
from pathlib import Path
import argparse

def run_command(cmd: list[str], description: str) -> bool:
    """Run a command and handle errors."""
    print(f"\n{'='*70}")
    print(f"► {description}")
    print(f"{'='*70}")
    print(f"Command: {' '.join(cmd)}\n")
    
    try:
        result = subprocess.run(cmd, check=True)
        print(f"\n✓ {description} completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n✗ {description} failed with exit code {e.returncode}")
        return False
    except Exception as e:
        print(f"\n✗ {description} failed with error: {e}")
        return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Retrain phishing models with integrated datasets"
    )
    parser.add_argument(
        "--full-volume",
        action="store_true",
        help=(
            "Keep all URLs in Step 1 by disabling dedup and HTTP-only filtering. "
            "This can substantially increase runtime and dataset size."
        ),
    )
    return parser.parse_args()


def main():
    args = parse_args()
    workspace = Path("/workspaces/FYP")
    
    steps = [
        {
            "description": "Step 0: Integrate Phishing.Database active feeds",
            "cmd": [
                sys.executable, "src/step1_integrate_phishing_database.py",
                "--output", "data/phishing_database_prepared.csv",
            ]
        },
        {
            "description": "Step 1: Integrate all datasets (including new urldata.csv)",
            "cmd": [
                sys.executable, "src/step1_integrate_all_datasets.py",
                "--urldata", "urldata.csv",
                "--phishing", "PhiUSIIL_Phishing_URL_Dataset.csv",
                "--legitimate", "new_data_urls.csv",
                "--malicious-phish", "malicious_phish.csv",
                "--dataset-phishing", "dataset_phishing.csv",
                "--phishing-database", "data/phishing_database_prepared.csv",
                "--output", "data/processed_urls_with_all_datasets.csv",
            ]
        },
        {
            "description": "Step 2: Extract features from combined dataset",
            "cmd": [
                sys.executable, "src/step2_feature_extraction.py",
                "--input", "data/processed_urls_with_all_datasets.csv",
                "--output", "data/url_features_with_all_datasets.csv",
            ]
        },
        {
            "description": "Step 3: Train individual base models (Random Forest, Gradient Boosting, XGBoost)",
            "cmd": [
                sys.executable, "src/step3_model_training.py",
                "--input", "data/url_features_with_all_datasets.csv",
                "--output-dir", "artifacts/base_models_all_datasets",
            ]
        },
        {
            "description": "Step 4: Train ensemble model (Soft Voting)",
            "cmd": [
                sys.executable, "src/step4_ensemble_model.py",
                "--input", "data/url_features_with_all_datasets.csv",
                "--model-output", "artifacts/ensemble_all_datasets/soft_voting_ensemble.joblib",
                "--cv-folds", "2",
                "--max-rows", "100000",
            ]
        },
    ]
    
    print("\n" + "="*70)
    print("PHISHING URL DETECTION - FULL RETRAINING PIPELINE")
    print("="*70)
    print(f"Working directory: {workspace}")
    print(f"Total steps: {len(steps)}")

    if args.full_volume:
        steps[0]["cmd"].extend(["--disable-dedup", "--allow-non-http"])
        print("Mode: FULL VOLUME (no dedup + include non-http URLs)")
    
    successful = 0
    failed = 0
    
    for i, step in enumerate(steps, 1):
        print(f"\n[{i}/{len(steps)}]", end=" ")
        
        if run_command(step["cmd"], step["description"]):
            successful += 1
        else:
            failed += 1
            print(f"Stopping pipeline due to failure at step {i}")
            break
    
    # Summary
    print(f"\n\n" + "="*70)
    print("RETRAINING PIPELINE SUMMARY")
    print("="*70)
    print(f"✓ Successful steps: {successful}")
    print(f"✗ Failed steps: {failed}")
    
    if failed == 0:
        print("\n✅ All steps completed successfully!")
        print("\nNew models are ready at:")
        print("  - Base models: artifacts/base_models_all_datasets/")
        print("  - Ensemble: artifacts/ensemble_all_datasets/soft_voting_ensemble.joblib")
        print("\nTo use the new models, update app.py paths:")
        print("  ENSEMBLE_MODEL_PATH = Path('artifacts/ensemble_all_datasets/soft_voting_ensemble.joblib')")
        return 0
    else:
        print(f"\n❌ Pipeline failed at step {successful + 1}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
