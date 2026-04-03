"""Comprehensive real-world testing of the phishing detection model.

This script tests the model with various legitimate and phishing-like URLs
to evaluate if it's ready for production use.
"""

import os
import re
from typing import Dict, List

import requests
from colorama import Fore, Style, init

init(autoreset=True)

BASE_URL = os.getenv("TEST_BASE_URL", "http://127.0.0.1:5000")
REQUEST_TIMEOUT = float(os.getenv("TEST_TIMEOUT", "90"))

# Test cases: mix of legitimate websites and phishing patterns
TEST_CASES = {
    "Legitimate - Popular Sites": [
        "https://www.google.com",
        "https://github.com",
        "https://www.youtube.com",
        "https://www.wikipedia.org",
        "https://www.amazon.com",
        "https://www.microsoft.com",
        "https://stackoverflow.com",
        "https://www.reddit.com",
        "https://www.linkedin.com",
        "https://www.apple.com",
    ],
    "Legitimate - Banking & Finance": [
        "https://www.paypal.com",
        "https://www.chase.com",
        "https://www.bankofamerica.com",
        "https://www.wellsfargo.com",
    ],
    "Legitimate - Universities": [
        "https://www.harvard.edu",
        "https://www.stanford.edu",
        "https://www.mit.edu",
    ],
    "Suspicious - IP Address": [
        "http://192.168.1.1/login",
        "http://123.45.67.89/secure",
        "https://10.0.0.1/banking",
    ],
    "Suspicious - Homograph/Typosquatting": [
        "https://www.g00gle.com/signin",
        "https://www.paypa1.com/login",
        "https://www.micr0soft.com",
        "https://www.facebok.com",
    ],
    "Suspicious - Subdomain Tricks": [
        "https://paypal.com-secure.verify-account.com",
        "https://www.google.com.malicious-site.com/login",
        "https://account-amazon.com.phishing.net",
    ],
    "Suspicious - Long/Obfuscated URLs": [
        "https://bit.ly.secure-login.xyz/verify?id=12345",
        "http://urgentverification-paypal-account-suspended.com",
        "https://update-secure-banking.com/?redirect=verify&token=abc123xyz",
    ],
    "Suspicious - @ Symbol Tricks": [
        "https://paypal.com@malicious.com",
        "https://amazon.com@phishing.net/login",
    ],
    "Suspicious - Suspicious TLDs": [
        "https://secure-banking.tk",
        "https://paypal-verify.cf",
        "https://account-recovery.ml",
    ],
    "Suspicious - Encoded/Hex URLs": [
        "http://example.com/%2e%2e%2f%2e%2e",
        "https://site.com/login%40redirect",
    ],
}


def test_url(url: str) -> Dict:
    """Test a single URL against the model."""
    try:
        response = requests.post(
            f"{BASE_URL}/predict",
            data={"url": url},
            timeout=REQUEST_TIMEOUT,
        )

        html = response.text

        confidence_match = re.search(r"Confidence:\s*([^<]+)", html)
        confidence = confidence_match.group(1).strip() if confidence_match else "N/A"

        if 'badge badge-legit">LEGITIMATE<' in html:
            prediction = "LEGITIMATE"
        elif 'badge badge-phishing">PHISHING<' in html:
            prediction = "PHISHING"
        else:
            prediction = "ERROR"
            confidence = "N/A"

        return {
            "url": url,
            "prediction": prediction,
            "confidence": confidence,
            "status": "success",
        }
    except Exception as e:
        return {
            "url": url,
            "prediction": "ERROR",
            "confidence": "N/A",
            "status": f"error: {str(e)}",
        }


def print_results(category: str, results: List[Dict]):
    """Print test results for a category."""
    print(f"\n{'='*80}")
    print(f"{Fore.CYAN}{Style.BRIGHT}{category}")
    print(f"{'='*80}")
    
    for result in results:
        url = result["url"]
        prediction = result["prediction"]
        confidence = result["confidence"]
        
        # Color code based on prediction
        if prediction == "LEGITIMATE":
            color = Fore.GREEN
            symbol = "✓"
        elif prediction == "PHISHING":
            color = Fore.RED
            symbol = "⚠"
        else:
            color = Fore.YELLOW
            symbol = "?"
        
        print(f"{color}{symbol} {prediction:<12} ({confidence:>6}%) {Style.DIM}| {url}")


def calculate_statistics(all_results: Dict[str, List[Dict]]):
    """Calculate and display overall statistics."""
    total_tests = 0
    total_legitimate_predictions = 0
    total_phishing_predictions = 0
    total_errors = 0
    
    legitimate_categories = ["Legitimate - Popular Sites", "Legitimate - Banking & Finance", "Legitimate - Universities"]
    suspicious_categories = [cat for cat in all_results.keys() if "Suspicious" in cat]
    
    legitimate_correct = 0
    legitimate_total = 0
    phishing_correct = 0
    phishing_total = 0
    
    for category, results in all_results.items():
        for result in results:
            total_tests += 1
            
            if result["prediction"] == "LEGITIMATE":
                total_legitimate_predictions += 1
            elif result["prediction"] == "PHISHING":
                total_phishing_predictions += 1
            else:
                total_errors += 1
            
            # Track accuracy
            if category in legitimate_categories:
                legitimate_total += 1
                if result["prediction"] == "LEGITIMATE":
                    legitimate_correct += 1
            elif category in suspicious_categories:
                phishing_total += 1
                if result["prediction"] == "PHISHING":
                    phishing_correct += 1
    
    print(f"\n{'='*80}")
    print(f"{Fore.CYAN}{Style.BRIGHT}OVERALL STATISTICS")
    print(f"{'='*80}")
    print(f"Total Tests: {total_tests}")
    print(f"Legitimate Predictions: {total_legitimate_predictions}")
    print(f"Phishing Predictions: {total_phishing_predictions}")
    print(f"Errors: {total_errors}")
    
    if legitimate_total > 0:
        legitimate_accuracy = (legitimate_correct / legitimate_total) * 100
        false_positive_rate = ((legitimate_total - legitimate_correct) / legitimate_total) * 100
        print(f"\n{Fore.GREEN}Legitimate URL Detection:")
        print(f"  Accuracy: {legitimate_accuracy:.1f}% ({legitimate_correct}/{legitimate_total})")
        print(f"  False Positive Rate: {false_positive_rate:.1f}% (legitimate marked as phishing)")
    
    if phishing_total > 0:
        phishing_accuracy = (phishing_correct / phishing_total) * 100
        false_negative_rate = ((phishing_total - phishing_correct) / phishing_total) * 100
        print(f"\n{Fore.RED}Phishing URL Detection:")
        print(f"  Accuracy: {phishing_accuracy:.1f}% ({phishing_correct}/{phishing_total})")
        print(f"  False Negative Rate: {false_negative_rate:.1f}% (phishing marked as legitimate)")
    
    # Overall assessment
    print(f"\n{'='*80}")
    print(f"{Fore.YELLOW}{Style.BRIGHT}PRODUCTION READINESS ASSESSMENT")
    print(f"{'='*80}")
    
    overall_accuracy = ((legitimate_correct + phishing_correct) / total_tests) * 100 if total_tests > 0 else 0
    
    print(f"Overall Accuracy: {overall_accuracy:.1f}%")
    
    if overall_accuracy >= 95 and false_positive_rate <= 10 and false_negative_rate <= 5:
        print(f"{Fore.GREEN}{Style.BRIGHT}✓ EXCELLENT - Model is production-ready!")
        print("  • High accuracy across all test cases")
        print("  • Low false positive rate (won't block legitimate sites)")
        print("  • Low false negative rate (catches most phishing attempts)")
    elif overall_accuracy >= 85 and false_positive_rate <= 20:
        print(f"{Fore.YELLOW}{Style.BRIGHT}⚠ GOOD - Model is usable with monitoring")
        print("  • Consider adding more training data")
        print("  • Monitor false positives in production")
        print("  • Implement user feedback mechanism")
    else:
        print(f"{Fore.RED}{Style.BRIGHT}✗ NEEDS IMPROVEMENT")
        print("  • Accuracy is too low for production use")
        print("  • Requires more training data or feature engineering")
        print("  • Consider ensemble with other detection methods")


def main():
    print(f"{Fore.CYAN}{Style.BRIGHT}╔{'='*78}╗")
    print(f"║{' '*14}PHISHING DETECTION MODEL - REAL-WORLD TESTING{' '*20}║")
    print(f"╚{'='*78}╝")
    
    all_results = {}
    
    for category, urls in TEST_CASES.items():
        print(f"\n{Fore.YELLOW}Testing {category}... ({len(urls)} URLs)")
        results = []
        for url in urls:
            result = test_url(url)
            results.append(result)
        all_results[category] = results
        print_results(category, results)
    
    calculate_statistics(all_results)
    
    print(f"\n{Fore.CYAN}{'='*80}")
    print(f"Testing Complete!")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()
