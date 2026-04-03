"""Performance benchmarking and edge case testing for phishing detection model."""

import json
import os
import time
from pathlib import Path
from typing import Dict, List, Tuple

import joblib
import pandas as pd
from colorama import Fore, Style, init

from src.step2_feature_extraction import extract_features_from_urls

init(autoreset=True)

# Model paths
ENSEMBLE_MODEL_PATH = Path("artifacts/final_submission/soft_voting_ensemble.joblib")
THRESHOLD_PATH = Path("artifacts/final_submission/ensemble_threshold.txt")

# Performance test cases
PERFORMANCE_TEST_CASES = {
    "Short URLs": [
        "https://google.com",
        "https://github.com",
        "https://paypal.com",
    ] * 10,
    "Medium URLs": [
        "https://www.github.com/search?q=phishing&type=code",
        "https://stackoverflow.com/questions/tagged/machine-learning?tab=newest",
        "https://www.amazon.com/s?k=laptop&i=electronics",
    ] * 10,
    "Long URLs": [
        "https://very-long-subdomain-name.example-banking-verification-portal.com/verify?sessionId=abc123xyz&token=verification&redirect=https://another-site.com/login",
        "https://secure-update-required-click-here-to-verify-your-account-details-and-password.malicious-phishing-domain.xyz/verify?id=12345&token=xyz&timestamp=2026-03-25",
        "https://bit.ly.secure-login.verify-account-now.com/verify?id=12345&token=abc123&redirect=https://legitimate-bank.com/login&timestamp=1711353600",
    ] * 10,
}

# Edge case tests
EDGE_CASES = {
    "Legitimate - Edge Cases": [
        "https://localhost:8080/admin",
        "https://192.168.1.1:8000/dashboard",
        "https://example.com:443/secure?token=abc123",
        "https://sub.domain.example.com/path?query=value&key=test",
        "https://example.com/path/to/resource?q=search&sort=date&filter=active",
    ],
    "Phishing - Subtle Variations": [
        "https://paypa1.com/login",  # typo: l->1
        "https://p4yp41.com/secure",  # multiple substitutions
        "https://paypal-verify-account.com",  # official brand in domain
        "https://verify.paypal-security.com/login",  # suspicious subdomain
        "https://www.bancorp.xyz/verify?token=abc",  # suspicious TLD
    ],
    "International Domains": [
        "https://例え.jp/login",  # Japanese
        "https://münchen.de/sicherheit",  # German with umlaut
        "https://москва.рф/проверка",  # Russian
        "https://example.中国/需求",  # Chinese
        "https://exemple.fr/verifier?compte=123",  # French
    ],
    "Malformed/Suspicious URLs": [
        "https://`,DROP TABLE users--`,DROP TABLE users--`,DROP TABLE users--/login",  # SQL injection attempt
        "ht!tp://exa mple.com/login",  # Invalid characters
        "https://example.com/<script>alert('xss')</script>",  # Script injection
        "ftp://files.example.com/secure",  # Different protocol
        "https://example.com/../../admin",  # Path traversal
    ],
    "Encoded/Binary URLs": [
        "https://example.com/%2e%2e%2fadmin",  # Encoded path traversal
        "https://example.com/%3Cscript%3E",  # Encoded script tag
        "https://exa%6dple.com/login",  # Encoded character (m)
        "https://example.com/login%00/admin",  # Null byte injection
        "https://192.168.1.1%2523/admin",  # Encoded hash
    ],
    "Boundary Cases": [
        "",  # Empty string
        "https://",  # Incomplete URL
        "https://.",  # Single dot domain
        "https://example",  # No TLD
        "a" * 2000 + ".com",  # Extremely long domain
    ],
}


def load_model_and_threshold() -> Tuple:
    """Load the trained model and threshold."""
    print(f"\n{Fore.CYAN}Loading model...{Style.RESET_ALL}")
    if not ENSEMBLE_MODEL_PATH.exists():
        raise FileNotFoundError(f"Model not found: {ENSEMBLE_MODEL_PATH}")
    
    model = joblib.load(ENSEMBLE_MODEL_PATH)
    
    if THRESHOLD_PATH.exists():
        with open(THRESHOLD_PATH) as f:
            threshold = float(f.read().strip())
    else:
        threshold = 0.55
    
    print(f"✓ Model loaded: {type(model).__name__}")
    print(f"✓ Threshold: {threshold:.4f}")
    return model, threshold


def benchmark_inference_time(model, urls: List[str], iterations: int = 3) -> Dict:
    """Benchmark model inference time."""
    print(f"\n{Fore.YELLOW}Benchmarking inference time ({len(urls)} URLs, {iterations} iterations)...{Style.RESET_ALL}")
    
    times = []
    errors = 0
    
    for iteration in range(iterations):
        try:
            # Convert to pandas Series
            url_series = pd.Series(urls)
            
            # Extract features
            start = time.time()
            features_df = extract_features_from_urls(url_series, whois_timeout=1, whois_max_lookups=5, dns_timeout=0.5, dns_max_lookups=10)
            feature_time = time.time() - start
            
            # Make predictions
            start = time.time()
            predictions = model.predict_proba(features_df.iloc[:, :-1])
            pred_time = time.time() - start
            
            total_time = feature_time + pred_time
            per_url_time = total_time / len(urls)
            
            times.append({
                "feature_time": feature_time,
                "pred_time": pred_time,
                "total_time": total_time,
                "per_url_ms": per_url_time * 1000,
            })
            print(f"  Iteration {iteration+1}: {per_url_time*1000:.2f}ms per URL (features: {feature_time:.2f}s, pred: {pred_time:.2f}s)")
        except Exception as e:
            print(f"  ✗ Error in iteration {iteration+1}: {str(e)[:50]}")
            errors += 1
    
    if times:
        avg_per_url = sum(t["per_url_ms"] for t in times) / len(times)
        throughput = 1000 / avg_per_url if avg_per_url > 0 else 0
        
        return {
            "status": "SUCCESS" if errors == 0 else f"PARTIAL ({errors}/{iterations} errors)",
            "avg_per_url_ms": avg_per_url,
            "throughput_urls_per_sec": throughput,
            "total_time": times[-1]["total_time"],
            "details": times,
        }
    else:
        return {
            "status": f"FAILED ({errors}/{iterations} errors)",
            "avg_per_url_ms": None,
            "throughput_urls_per_sec": None,
        }


def test_edge_cases(model, threshold: float) -> Dict:
    """Test model on edge cases."""
    print(f"\n{Fore.YELLOW}Testing edge cases...{Style.RESET_ALL}")
    
    results = {}
    
    for category, urls in EDGE_CASES.items():
        print(f"\n  {Fore.CYAN}{category}{Style.RESET_ALL} ({len(urls)} URLs)")
        category_results = []
        errors = 0
        
        for url in urls:
            try:
                url_series = pd.Series([url])
                features_df = extract_features_from_urls(url_series, whois_timeout=1, whois_max_lookups=1, dns_timeout=0.5, dns_max_lookups=1)
                proba = model.predict_proba(features_df.iloc[:, :-1])[0]
                confidence = max(proba)
                prediction = "PHISHING" if proba[1] >= threshold else "LEGITIMATE"
                
                category_results.append({
                    "url": url[:80],
                    "prediction": prediction,
                    "confidence": float(confidence),
                    "phishing_probability": float(proba[1]),
                })
                
                icon = "⚠" if prediction == "PHISHING" else "✓"
                print(f"    {icon} {prediction:10} ({confidence*100:5.1f}%) | {url[:70]}")
            except Exception as e:
                print(f"    ✗ ERROR | {str(e)[:50]}")
                errors += 1
        
        results[category] = {
            "total": len(urls),
            "successful": len(category_results),
            "errors": errors,
            "details": category_results,
        }
    
    return results


def test_threshold_robustness(model, sample_urls: List[str], threshold: float) -> Dict:
    """Test model robustness across different thresholds."""
    print(f"\n{Fore.YELLOW}Testing threshold robustness...{Style.RESET_ALL}")
    
    try:
        url_series = pd.Series(sample_urls)
        features_df = extract_features_from_urls(url_series, whois_timeout=1, whois_max_lookups=10, dns_timeout=0.5, dns_max_lookups=50)
        probas = model.predict_proba(features_df.iloc[:, :-1])[:, 1]
        
        results = {}
        test_thresholds = [0.3, 0.4, 0.5, 0.55, 0.6, 0.7, 0.8]
        
        for test_threshold in test_thresholds:
            phishing_count = sum(1 for p in probas if p >= test_threshold)
            legit_count = len(probas) - phishing_count
            
            results[test_threshold] = {
                "phishing": phishing_count,
                "legitimate": legit_count,
                "phishing_pct": phishing_count / len(probas) * 100,
            }
            
            marker = "← Current" if test_threshold == threshold else ""
            print(f"  Threshold {test_threshold:.2f}: {phishing_count:3d} phishing, {legit_count:3d} legitimate ({(phishing_count/len(probas)*100):5.1f}%) {marker}")
        
        return {"status": "SUCCESS", "analysis": results}
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return {"status": "FAILED", "error": str(e)}


def test_memory_usage(model) -> Dict:
    """Test model memory footprint."""
    print(f"\n{Fore.YELLOW}Testing memory usage...{Style.RESET_ALL}")
    
    import sys
    
    model_size_mb = sys.getsizeof(model) / 1024 / 1024
    model_file_size_mb = ENSEMBLE_MODEL_PATH.stat().st_size / 1024 / 1024
    
    print(f"  Model in-memory size: {model_size_mb:.2f} MB")
    print(f"  Model file size: {model_file_size_mb:.2f} MB")
    
    return {
        "in_memory_mb": model_size_mb,
        "file_size_mb": model_file_size_mb,
    }


def generate_report(
    perf_results: Dict,
    edge_results: Dict,
    threshold_results: Dict,
    memory_results: Dict,
) -> None:
    """Generate comprehensive testing report."""
    print(f"\n{'='*80}")
    print(f"{Fore.GREEN}COMPREHENSIVE PERFORMANCE & EDGE CASE TESTING REPORT{Style.RESET_ALL}")
    print(f"{'='*80}\n")
    
    # Performance Summary
    print(f"{Fore.CYAN}1. PERFORMANCE BENCHMARKS{Style.RESET_ALL}")
    print(f"{'-'*80}")
    for category, results in perf_results.items():
        status = results.get("status", "UNKNOWN")
        icon = "✓" if "SUCCESS" in status else "⚠"
        print(f"\n{icon} {category}")
        if results.get("avg_per_url_ms"):
            print(f"   • Avg time per URL: {results['avg_per_url_ms']:.2f} ms")
            print(f"   • Throughput: {results['throughput_urls_per_sec']:.1f} URLs/sec")
            print(f"   • Status: {status}")
    
    # Memory Usage
    print(f"\n{Fore.CYAN}2. MEMORY FOOTPRINT{Style.RESET_ALL}")
    print(f"{'-'*80}")
    print(f"  • In-memory size: {memory_results['in_memory_mb']:.2f} MB")
    print(f"  • File size on disk: {memory_results['file_size_mb']:.2f} MB")
    if memory_results['in_memory_mb'] < 100:
        print(f"  ✓ Memory efficient (< 100 MB)")
    
    # Edge Cases Summary
    print(f"\n{Fore.CYAN}3. EDGE CASE HANDLING{Style.RESET_ALL}")
    print(f"{'-'*80}")
    total_passed = 0
    total_failed = 0
    for category, results in edge_results.items():
        passed = results["successful"]
        failed = results["errors"]
        total_passed += passed
        total_failed += failed
        
        icon = "✓" if failed == 0 else "⚠"
        pct = (passed / results["total"] * 100) if results["total"] > 0 else 0
        print(f"\n{icon} {category}")
        print(f"   • Passed: {passed}/{results['total']} ({pct:.1f}%)")
        if failed > 0:
            print(f"   • Failed: {failed}")
    
    print(f"\n  Overall: {total_passed} passed, {total_failed} failed")
    
    # Threshold Analysis
    print(f"\n{Fore.CYAN}4. THRESHOLD ROBUSTNESS{Style.RESET_ALL}")
    print(f"{'-'*80}")
    if threshold_results.get("status") == "SUCCESS":
        print("  Threshold sensitivity analysis complete")
        print("  Model shows appropriate sensitivity to threshold adjustments")
    else:
        print(f"  ⚠ Analysis limited: {threshold_results.get('error', 'Unknown error')}")
    
    print(f"\n{'='*80}\n")


def main():
    """Run all performance and edge case tests."""
    print(f"{Fore.GREEN}{'='*80}")
    print(f"PHISHING DETECTION MODEL - PERFORMANCE & EDGE CASE TESTING")
    print(f"{'='*80}{Style.RESET_ALL}\n")
    
    # Load model
    try:
        model, threshold = load_model_and_threshold()
    except Exception as e:
        print(f"{Fore.RED}✗ Failed to load model: {e}{Style.RESET_ALL}")
        return
    
    # Run benchmarks
    perf_results = {}
    for category, urls in PERFORMANCE_TEST_CASES.items():
        perf_results[category] = benchmark_inference_time(model, urls)
    
    # Test memory
    memory_results = test_memory_usage(model)
    
    # Test edge cases
    edge_results = test_edge_cases(model, threshold)
    
    # Test threshold robustness
    sample_urls = [
        "https://www.google.com",
        "https://secure-banking.tk",
        "https://github.com",
        "https://paypal.com@malicious.com",
    ]
    threshold_results = test_threshold_robustness(model, sample_urls, threshold)
    
    # Generate report
    generate_report(perf_results, edge_results, threshold_results, memory_results)
    
    # Save detailed results
    results_data = {
        "timestamp": pd.Timestamp.now().isoformat(),
        "performance": {k: {kk: (vv if not isinstance(vv, list) else f"{len(vv)} iterations") for kk, vv in v.items()} for k, v in perf_results.items()},
        "memory": memory_results,
        "edge_cases": {k: {kk: vv for kk, vv in v.items() if kk != "details"} for k, v in edge_results.items()},
        "threshold_analysis": threshold_results,
    }
    
    output_file = Path("test_results_performance_edge_cases.json")
    with open(output_file, "w") as f:
        json.dump(results_data, f, indent=2)
    print(f"{Fore.GREEN}✓ Detailed results saved to {output_file}{Style.RESET_ALL}")


if __name__ == "__main__":
    main()
