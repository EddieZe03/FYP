from __future__ import annotations

import os
import html
from pathlib import Path
import traceback
from typing import Any
from urllib.parse import urlparse

import joblib
import pandas as pd
import tldextract
from flask import Flask, jsonify, render_template, request

from src.output_handler import format_output
from src.step2_feature_extraction import extract_features_from_urls

app = Flask(__name__)

FINAL_MODEL_PATH = Path("artifacts/ensemble_all_datasets_retry/soft_voting_ensemble.joblib")
FINAL_THRESHOLD = 0.565
WHOIS_CACHE_PATH = Path("artifacts/whois_cache.csv")
MODEL_DISPLAY_NAME = "Soft Voting Ensemble (Retry Balanced Sample)"
EXPECTED_FEATURE_COLUMNS = [
    "url_length",
    "num_dots",
    "has_at_symbol",
    "has_hyphen",
    "uses_ip_address",
    "domain_age_days",
    "whois_registrar_available",
    "dns_resolves",
    "domain_age_available",
    "is_new_domain_30d",
    "num_subdomains",
    "path_length",
    "path_depth",
    "query_length",
    "num_digits",
    "num_special_chars",
    "has_encoded_chars",
    "has_suspicious_tld",
    "suspicious_keyword_count",
    "suspicious_path_keyword_count",
    "has_wp_path",
    "url_entropy",
    "uses_https",
    "redirection_count",
]

_MODEL: Any | None = None
_MODEL_PATH: Path | None = None
PHISHING_THRESHOLD = float(os.getenv("PHISHING_THRESHOLD", str(FINAL_THRESHOLD)))

TRUSTED_DOMAINS = {
    "youtube.com",
    "google.com",
    "wikipedia.org",
    "github.com",
    "stackoverflow.com",
    "reddit.com",
    "openai.com",
    "chatgpt.com",
    "microsoft.com",
    "apple.com",
    "amazon.com",
    "paypal.com",
    "chase.com",
    "bankofamerica.com",
    "wellsfargo.com",
    "harvard.edu",
    "stanford.edu",
    "mit.edu",
    "facebook.com",
    "instagram.com",
    "linkedin.com",
}

HIGH_RISK_BRAND_TOKENS = {
    "aol",
    "remax",
    "paypal",
    "microsoft",
    "office365",
    "outlook",
    "appleid",
    "icloud",
    "chase",
    "wellsfargo",
    "bankofamerica",
    "amazon",
    "facebook",
    "instagram",
    "linkedin",
    "hsbc",
    "abn",
    "amro",
    "barclays",
    "citibank",
    "discover",
}

BANKING_ENDPOINT_KEYWORDS = {
    "identification",
    "verify",
    "confirm",
    "authenticate",
    "authorization",
    "activation",
}

HIGH_RISK_MAIL_STACK_TOKENS = {"zimbra", "owa", "exch", "webmail"}
HIGH_RISK_PATH_TOKENS = {
    "plugins",
    "tmp",
    "components",
    "com_newsfeeds",
    "cadastro",
    "verify",
    "update",
    "secure",
    "billing",
}


def _resolve_model_path() -> Path:
    """Load only the final submission model."""
    if FINAL_MODEL_PATH.exists():
        return FINAL_MODEL_PATH
    raise FileNotFoundError(f"Final ensemble model not found: {FINAL_MODEL_PATH}")


def _get_model() -> Any:
    """Lazy-load model so server startup stays lightweight."""
    global _MODEL, _MODEL_PATH, PHISHING_THRESHOLD

    if _MODEL is not None:
        return _MODEL

    _MODEL_PATH = _resolve_model_path()
    _MODEL = joblib.load(_MODEL_PATH)
    PHISHING_THRESHOLD = FINAL_THRESHOLD
    return _MODEL


def _registered_domain(url: str) -> str:
    extracted = tldextract.extract(url)
    if extracted.domain and extracted.suffix:
        return f"{extracted.domain}.{extracted.suffix}"
    host = urlparse(url).hostname
    return host or ""


def _normalize_input_url(raw_url: str) -> str:
    """Accept URLs with or without scheme and normalize for model inference."""
    # Decode common copied HTML entities (e.g. &amp;) before parsing features.
    url = html.unescape(raw_url.strip())
    if not url:
        return ""
    if "://" in url:
        return url
    return f"http://{url}"


def _path_and_query_text(url: str) -> str:
    parsed = urlparse(url)
    path = (parsed.path or "").lower()
    query = (parsed.query or "").lower()
    return f"{path}?{query}"


def _host(url: str) -> str:
    return (urlparse(url).hostname or "").lower()


def _should_override_brand_mismatch(
    url: str,
    domain: str,
    suspicious_keyword_count: int,
    suspicious_path_count: int,
    path_depth: int,
    num_subdomains: int,
    has_encoded_chars: int,
) -> bool:
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    brand_hits = [token for token in HIGH_RISK_BRAND_TOKENS if token in text]
    if not brand_hits:
        return False

    # Brand appears in path/query but not in host/domain: common impersonation signal.
    mismatch_hits = [token for token in brand_hits if token not in domain]
    if not mismatch_hits:
        return False

    structural_signal = (
        suspicious_keyword_count >= 1
        or suspicious_path_count >= 1
        or path_depth >= 2
        or num_subdomains >= 2
        or has_encoded_chars == 1
    )
    return structural_signal


def _should_override_mail_stack(url: str, domain: str, path_depth: int) -> bool:
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    stack_hits = sum(1 for token in HIGH_RISK_MAIL_STACK_TOKENS if token in text)
    return stack_hits >= 2 and path_depth >= 2


def _should_override_php_trap(
    url: str,
    domain: str,
    suspicious_keyword_count: int,
    suspicious_path_count: int,
    path_depth: int,
) -> bool:
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    has_php_endpoint = ".php" in text
    risky_tokens = sum(1 for token in HIGH_RISK_PATH_TOKENS if token in text)

    return has_php_endpoint and path_depth >= 2 and (
        risky_tokens >= 2 or suspicious_keyword_count >= 1 or suspicious_path_count >= 1
    )


def _should_override_hosted_form(url: str, domain: str) -> bool:
    host = _host(url)
    text = _path_and_query_text(url)

    # Common hosted phishing pattern using Google-hosted form endpoints.
    if domain == "google.com" and host.startswith("docs.google.com"):
        if ("/viewform" in text or "formkey=" in text) and "/a/" in text:
            return True

    return False


def _should_override_wp_login(url: str, domain: str, path_depth: int) -> bool:
    """Detect WordPress admin + login pattern even on old domains."""
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    has_wp_path = "wp-admin" in text or "wp-includes" in text or "wp-content" in text
    has_login_pattern = "login" in text or "signin" in text or "password.php" in text
    
    return has_wp_path and has_login_pattern


def _should_override_banking_brand_endpoint(
    url: str,
    domain: str,
    path_depth: int,
) -> bool:
    """Detect banking brand tokens with sensitive endpoints in deep paths."""
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    full_url_text = url.lower()
    
    # Check for banking brand tokens
    brand_hits = [token for token in {"hsbc", "abn", "barclays", "citibank"} if token in text]
    if not brand_hits:
        return False
    
    # Check for sensitive banking endpoints
    endpoint_hits = [token for token in BANKING_ENDPOINT_KEYWORDS if token in text]
    if not endpoint_hits:
        return False
    
    # Require reasonable path depth
    return path_depth >= 2


def _should_override_short_php_endpoint(
    url: str,
    domain: str,
    domain_age_days: int,
) -> bool:
    """Detect suspicious short PHP filenames on new/unknown domains."""
    if domain in TRUSTED_DOMAINS:
        return False

    text = _path_and_query_text(url)
    
    # Check for short PHP endpoints (< 8 chars including extension)
    if ".php" not in text:
        return False
    
    # Extract just the PHP filename
    parts = text.split("/")
    php_files = [p for p in parts if ".php" in p]
    
    if not php_files:
        return False
    
    # Check if any PHP file is suspiciously short (like M5.php)
    short_php_files = [f for f in php_files if len(f) <= 8]
    
    if not short_php_files:
        return False
    
    # This is suspicious on new/unknown domains
    return domain_age_days < 0 or domain_age_days > 5475  # New or very old domain


def _should_override_embedded_domain_pattern(url: str, domain: str, path_depth: int) -> bool:
    """Detect embedded domain patterns in path (e.g., shopgreenmall.net/tomatodesign.net/...)."""
    if domain in TRUSTED_DOMAINS:
        return False

    path_text = urlparse(url).path.lower()
    
    # Count dots in the path part (embedded domain indicators)
    path_dots = path_text.count(".")
    
    # If path has multiple dots and is deep, suggests embedded domain
    if path_dots >= 2 and path_depth >= 4:
        # Check for suspicious patterns like brand names in path
        for brand in {"hsbc", "mybanklogin", "paypal", "amazon", "apple", "microsoft"}:
            if brand in path_text:
                return True
    
    return False


def _align_features_to_model(features: pd.DataFrame) -> pd.DataFrame:
    """Align runtime features to the locked schema used for the final submission model."""
    aligned = features.copy()

    for col in EXPECTED_FEATURE_COLUMNS:
        if col not in aligned.columns:
            aligned[col] = 0

    return aligned[EXPECTED_FEATURE_COLUMNS]


def _safe_int_feature(features: pd.DataFrame, column: str, default: int = 0) -> int:
    """Safely read an integer feature from extraction output with a fallback."""
    try:
        if column not in features.columns:
            return default
        value = features[column].iloc[0]
        if pd.isna(value):
            return default
        return int(value)
    except Exception:
        return default


def predict_url_label(url: str) -> tuple[str, float, str]:
    model = _get_model()

    features = extract_features_from_urls(
        pd.Series([url]),
        whois_cache_path=WHOIS_CACHE_PATH,
        whois_timeout=0.2,
        whois_max_lookups=1,
        whois_max_errors=1,
        dns_timeout=0.2,
        dns_max_lookups=100,
        dns_max_errors=20,
    )

    aligned_features = _align_features_to_model(features)
    probabilities = model.predict_proba(aligned_features)[0]
    phishing_probability = float(probabilities[1])
    domain = _registered_domain(url).lower()

    suspicious_path_count = _safe_int_feature(features, "suspicious_path_keyword_count", 0)
    suspicious_keyword_count = _safe_int_feature(features, "suspicious_keyword_count", 0)
    has_wp_path = _safe_int_feature(features, "has_wp_path", 0)
    domain_age_days = _safe_int_feature(features, "domain_age_days", -1)
    dns_resolves = _safe_int_feature(features, "dns_resolves", 0)
    uses_ip_address = _safe_int_feature(features, "uses_ip_address", 0)
    has_suspicious_tld = _safe_int_feature(features, "has_suspicious_tld", 0)
    path_depth = _safe_int_feature(features, "path_depth", 0)
    num_subdomains = _safe_int_feature(features, "num_subdomains", 0)
    has_encoded_chars = _safe_int_feature(features, "has_encoded_chars", 0)

    if (suspicious_path_count >= 1 or has_wp_path == 1) and domain_age_days < 0 and dns_resolves == 0:
        return (
            "Phishing",
            max(phishing_probability, 0.90),
            "High-risk structural override applied: suspicious path pattern with unresolved and unknown domain metadata.",
        )

    if uses_ip_address == 1 and (suspicious_path_count >= 1 or suspicious_keyword_count >= 1):
        return (
            "Phishing",
            max(phishing_probability, 0.85),
            "IP-host + suspicious keyword override applied.",
        )

    if has_suspicious_tld == 1 and suspicious_keyword_count >= 1:
        return (
            "Phishing",
            max(phishing_probability, 0.80),
            "Suspicious-TLD + phishing keyword override applied.",
        )

    if _should_override_brand_mismatch(
        url=url,
        domain=domain,
        suspicious_keyword_count=suspicious_keyword_count,
        suspicious_path_count=suspicious_path_count,
        path_depth=path_depth,
        num_subdomains=num_subdomains,
        has_encoded_chars=has_encoded_chars,
    ):
        return (
            "Phishing",
            max(phishing_probability, 0.88),
            "Brand-impersonation path override applied (brand token mismatch with host/domain).",
        )

    if _should_override_mail_stack(url=url, domain=domain, path_depth=path_depth):
        return (
            "Phishing",
            max(phishing_probability, 0.84),
            "Mail-stack path override applied (zimbra/owa/exch-style phishing pattern).",
        )

    if _should_override_php_trap(
        url=url,
        domain=domain,
        suspicious_keyword_count=suspicious_keyword_count,
        suspicious_path_count=suspicious_path_count,
        path_depth=path_depth,
    ):
        return (
            "Phishing",
            max(phishing_probability, 0.82),
            "PHP trap-path override applied (high-risk endpoint structure).",
        )

    if _should_override_hosted_form(url=url, domain=domain):
        return (
            "Phishing",
            max(phishing_probability, 0.78),
            "Hosted-form phishing override applied (google-docs form impersonation pattern).",
        )

    if _should_override_wp_login(url=url, domain=domain, path_depth=path_depth):
        return (
            "Phishing",
            max(phishing_probability, 0.86),
            "WordPress admin/login override applied (WP-admin + login endpoint pattern detected).",
        )

    if _should_override_banking_brand_endpoint(
        url=url,
        domain=domain,
        path_depth=path_depth,
    ):
        return (
            "Phishing",
            max(phishing_probability, 0.87),
            "Banking-brand endpoint override applied (brand token + sensitive endpoint match).",
        )

    if _should_override_short_php_endpoint(
        url=url,
        domain=domain,
        domain_age_days=domain_age_days,
    ):
        return (
            "Phishing",
            max(phishing_probability, 0.85),
            "Short PHP endpoint override applied (suspicious minimal script on suspicious domain).",
        )

    if _should_override_embedded_domain_pattern(url=url, domain=domain, path_depth=path_depth):
        return (
            "Phishing",
            max(phishing_probability, 0.84),
            "Embedded-domain pattern override applied (domain structure mismatch detected).",
        )

    trusted_override_safe = (
        suspicious_keyword_count == 0
        and suspicious_path_count == 0
        and has_wp_path == 0
        and has_encoded_chars == 0
        and path_depth <= 1
        and num_subdomains <= 1
    )

    if domain in TRUSTED_DOMAINS and trusted_override_safe:
        return (
            "Legitimate",
            phishing_probability,
            f"Trusted-domain override applied for {domain}. Model phishing score was {phishing_probability:.4f}.",
        )

    label = "Phishing" if phishing_probability >= FINAL_THRESHOLD else "Legitimate"
    reason = f"Threshold decision at {FINAL_THRESHOLD:.6f}."
    return label, phishing_probability, reason


@app.route("/", methods=["GET"])
def home() -> str:
    model_info = MODEL_DISPLAY_NAME if _MODEL_PATH else f"{MODEL_DISPLAY_NAME} (loading...)"
    return render_template("home.html", model_info=model_info)


@app.route("/analyze", methods=["GET"])
def analyze() -> str:
    model_info = MODEL_DISPLAY_NAME if _MODEL_PATH else f"{MODEL_DISPLAY_NAME} (loading...)"
    return render_template("index.html", model_info=model_info)


@app.route("/scan-qr", methods=["GET"])
def scan_qr() -> str:
    model_info = MODEL_DISPLAY_NAME if _MODEL_PATH else f"{MODEL_DISPLAY_NAME} (loading...)"
    return render_template("qr_scan.html", model_info=model_info)


def _predict_and_render(raw_url: str, template_name: str) -> str:
    url = _normalize_input_url(raw_url)

    if not url:
        return render_template(
            template_name,
            error_text="Please enter a URL.",
            input_url=raw_url,
            model_info=MODEL_DISPLAY_NAME,
        )

    try:
        label, phishing_probability, reason = predict_url_label(url)
        output = format_output(label, phishing_probability, reason)
        return render_template(
            template_name,
            result_badge=output["result_badge"],
            result_label=output["result_label"],
            result_confidence=output["result_confidence"],
            risk_level=output["risk_level"],
            explanation_text=output["explanation_text"],
            rule_trigger=output["rule_trigger"],
            recommendations=output["recommendations"],
            input_url=raw_url,
            model_info=MODEL_DISPLAY_NAME,
        )
    except Exception as exc:
        return render_template(
            template_name,
            error_text=f"Prediction failed: {exc}",
            input_url=raw_url,
            model_info=MODEL_DISPLAY_NAME,
        )


def _predict_to_payload(raw_url: str) -> tuple[dict[str, Any], int]:
    """Return structured JSON payload for mobile/API clients."""
    url = _normalize_input_url(raw_url)
    if not url:
        return {"ok": False, "error": "Please provide a URL."}, 400

    try:
        label, phishing_probability, reason = predict_url_label(url)
        output = format_output(label, phishing_probability, reason)
        return (
            {
                "ok": True,
                "input_url": raw_url,
                "normalized_url": url,
                "result": {
                    "badge": output["result_badge"],
                    "label": output["result_label"],
                    "confidence": output["result_confidence"],
                    "risk_level": output["risk_level"],
                    "explanation": output["explanation_text"],
                    "rule_trigger": output["rule_trigger"],
                    "recommendations": output["recommendations"],
                },
                "model": MODEL_DISPLAY_NAME,
            },
            200,
        )
    except Exception as exc:
        app.logger.error("Prediction failed for URL '%s': %s", url, exc)
        app.logger.debug(traceback.format_exc())
        return {"ok": False, "error": f"Prediction failed: {exc}"}, 500


@app.route("/predict", methods=["POST"])
def predict() -> str:
    raw_url = request.form.get("url", "").strip()
    return _predict_and_render(raw_url, "index.html")


@app.route("/predict-qr", methods=["POST"])
def predict_qr() -> str:
    raw_url = request.form.get("url", "").strip()
    return _predict_and_render(raw_url, "qr_scan.html")


@app.route("/api/health", methods=["GET"])
def api_health() -> Any:
    return jsonify({"ok": True, "service": "phish-guard", "model": MODEL_DISPLAY_NAME}), 200


@app.route("/api/predict", methods=["POST"])
def api_predict() -> Any:
    payload = request.get_json(silent=True) or {}
    raw_url = str(payload.get("url", "")).strip()
    response, status_code = _predict_to_payload(raw_url)
    return jsonify(response), status_code


if __name__ == "__main__":
    app.run(debug=False, use_reloader=False, host="0.0.0.0", port=5000)
