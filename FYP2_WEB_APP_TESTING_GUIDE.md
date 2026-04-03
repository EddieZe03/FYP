# 🧪 FYP 2 WEB APP TESTING GUIDE

**Purpose:** Validate that your Flask website implementation correctly detects phishing URLs as designed in FYP 1.

---

## QUICK START: RUN THE APP

```bash
cd /workspaces/FYP
python app.py
```

Then open in browser: **http://localhost:5000**

---

## TEST CASES & EXPECTED RESULTS

### Category 1: Obviously Phishing URLs ⚠️

#### Test 1.1: PayPal Lookalike
```
URL: http://secure-paypa1.com/verify-account/
Expected Risk: PHISHING (High/Critical)
Why: 
  - Domain typo (paypa1 instead of paypal)
  - Not in trusted domains
  - Suspicious path (/verify-account/)
  - Uses http not https
```

#### Test 1.2: IP-Based Phishing
```
URL: http://192.168.1.105/secure/login/
Expected Risk: PHISHING (High/Critical)
Why:
  - Uses IP address instead of domain
  - Suspicious path keywords
  - Model should flag: uses_ip_address=1
```

#### Test 1.3: Suspicious TLD Phishing
```
URL: http://bankingsecurity-verify.tk
Expected Risk: PHISHING (High/Medium)
Why:
  - .tk is suspicious TLD (cheap, often abused)
  - "bankingsecurity" + "verify" are phishing keywords
  - No https
```

#### Test 1.4: New Domain with Phishing Keywords
```
URL: https://apple-security-verify-now.xyz
Expected Risk: PHISHING (Medium/High)
Why:
  - Domain age likely < 30 days (new)
  - Suspicious keywords (security, verify, apple-like)
  - Suspicious TLD (.xyz)
```

---

### Category 2: Legitimate URLs ✅

#### Test 2.1: GitHub
```
URL: https://github.com
Expected Risk: LEGITIMATE (Low)
Why:
  - In TRUSTED_DOMAINS whitelist
  - Should immediately show "Low" risk
  - Has https
```

#### Test 2.2: Google
```
URL: https://www.google.com
Expected Risk: LEGITIMATE (Low)
Why:
  - In TRUSTED_DOMAINS whitelist
  - Secure https
  - No suspicious keywords
```

#### Test 2.3: Stanford University
```
URL: https://www.stanford.edu
Expected Risk: LEGITIMATE (Low)
Why:
  - In TRUSTED_DOMAINS whitelist
  - Educational institution
  - Established domain
```

#### Test 2.4: Generic Tech Blog
```
URL: https://techblog-example.com/article-about-security
Expected Risk: LEGITIMATE (Low/Medium-Low)
Why:
  - Straightforward domain
  - Secure https
  - Normal path structure
```

---

### Category 3: Borderline/Edge Cases ⚠️ (Tests Model Confidence)

#### Test 3.1: URL with @ Symbol
```
URL: http://google.com@malicious.com/
Expected Risk: PHISHING (High)
Why:
  - @ symbol in URL is classic phishing indicator
  - Browsers will ignore google.com part
  - Feature: has_at_symbol=1
```

#### Test 3.2: URL with Many Subdomains
```
URL: https://login.verify.secure.account.malicious-domain.com
Expected Risk: PHISHING (Medium/High)
Why:
  - Excessive subdomains (5+) unusual
  - Likely trying to hide real domain
  - Feature: num_subdomains > 3
```

#### Test 3.3: URL with Suspicious Path
```
URL: https://example.com/admin/wp-admin/login.php
Expected Risk: PHISHING (Medium)
Why:
  - wp-admin/ is WordPress admin path
  - /login.php suggests harvesting attempt
  - Feature: has_wp_path=1, suspicious_path_keyword_count >= 1
```

#### Test 3.4: Shortened URL (Long Domain)
```
URL: https://example.com/redirect?url=http://malicious.com&user=123
Expected Risk: PHISHING (Medium)
Why:
  - Long query string with URL parameter
  - Trying to hide redirect destination
  - Feature: query_length > normal
```

---

### Category 4: Real-World Test Cases 🌍

#### Test 4.1: LinkedIn Clone
```
URL: http://linkedln.com/login
Expected Risk: PHISHING (High)
Why:
  - Domain looks like LinkedIn but "linkedln" not "linkedin"
  - Missing https
  - /login suggests credential harvesting
```

#### Test 4.2: Bank Notification (Phishing Email Style)
```
URL: https://update-banking-details-yourbank.info
Expected Risk: PHISHING (High)
Why:
  - Urgency keyword ("update")
  - Generic TLD (.info is cheap)
  - Impersonating bank
```

#### Test 4.3: Official Banks
```
URL: https://www.chase.com
Expected Risk: LEGITIMATE (Low)
Why:
  - chase.com in TRUSTED_DOMAINS
  - Real financial institution domain
```

---

## HOW TO INTERPRET RESULTS

### Risk Level Meanings

| Risk Level | Color | Confidence | What To Do |
|---|---|---|---|
| **Critical** | 🔴 Red | 90%+ phishing | DEFINITELY AVOID - block or report |
| **High** | 🔴 Red | 75-90% phishing | PROBABLY AVOID - verify before clicking |
| **Medium** | 🟡 Yellow | 50-75% suspicious | BE CAUTIOUS - check sender & domain |
| **Medium-Low** | 🟢 Green | <50% legitimate | LIKELY SAFE - but stay alert |
| **Low** | 🟢 Green | 90%+ legitimate | SAFE TO USE - trusted domain |

### Confidence Score Interpretation

```
60-70% (Medium Risk):
  Model is unsure but leans toward phishing
  Maybe domain is new or has mixed signals

75-85% (High Risk):
  Model is confident it's phishing
  Multiple phishing indicators present

90%+ (Critical):
  Model is very confident
  Clear phishing patterns detected
```

---

## VALIDATION CHECKLIST

After running each test case, verify:

- [ ] **URL Input Works:**
  - [ ] Can paste URL into text field
  - [ ] Field accepts valid URLs
  - [ ] Field rejects empty input

- [ ] **Prediction Runs:**
  - [ ] No error messages
  - [ ] Page doesn't crash
  - [ ] Prediction completes in < 2 seconds

- [ ] **Results Display Correctly:**
  - [ ] "PHISHING" or "LEGITIMATE" badge appears
  - [ ] Confidence percentage displayed (0-100%)
  - [ ] Risk level labeled (Critical/High/Medium/etc)
  - [ ] Explanation text readable
  - [ ] Recommendations list appears

- [ ] **Output Matches Expectations:**
  - [ ] Risk level matches FYP 1 design
  - [ ] Confidence makes logical sense
  - [ ] Explanation explains the decision
  - [ ] Recommendations are actionable

---

## DEBUGGING IF SOMETHING GOES WRONG

### Issue: "Please enter a URL" Error
```
Cause: Empty input submitted
Fix: Type or paste a URL first
```

### Issue: "Prediction failed" Error
```
Common causes:
1. Model not loaded (check console output when app started)
2. Invalid URL format
3. Feature extraction timeout (WHOIS lookup hanging)
4. Memory issue

Fix:
- Restart the app: python app.py
- Try a simple URL: https://google.com
- Check /tmp/whois_errors.log if it exists
```

### Issue: Confidence Score Seems Wrong
```
Possible reasons:
1. URL has mixed phishing signals
2. Domain is new (WHOIS returns -1)
3. Model wasn't trained on similar URLs
4. Threshold may need adjustment

Fix:
- Check explanation text for why
- Try other URLs to see pattern
- May need model retraining (FYP 2 later phase)
```

### Issue: Prediction Takes > 5 Seconds
```
Cause: WHOIS lookup timing out
Fix:
- App has timeout of 1 second per WHOIS query
- Consider disabling WHOIS for faster speed
- Use cached WHOIS data instead

In app.py line ~144, reduce whois_timeout:
  whois_timeout=0.5,  # or 0.2 for faster
```

---

## COMPARING TO FYP 1 SPECIFICATIONS

### FYP 1 Promised Feature: Risk Level Output
```
✅ Your app shows: Critical/High/Medium/Low
✅ Your app shows: % confidence
✅ Your app shows: Color coding (through CSS classes)
✅ Your app shows: Safety recommendations
✅ Your app shows: Explanation text
```

### FYP 1 Promised Feature: Ensemble Learning
```
✅ Models loaded: Random Forest, Gradient Boosting, XGBoost
✅ Voting method: Soft voting (probability averaging)
✅ Result: Single score representing ensemble decision
```

### FYP 1 Promised Feature: Feature Categories
```
✅ Lexical (URL structure analysis)
  - URL length, special chars, entropy, etc.
  
✅ Domain-based (WHOIS, DNS)
  - Domain age, registrar, DNS resolution
  
✅ Heuristic (Behavioral)
  - HTTPS usage, IP detection, redirects
```

---

## SAMPLE TEST SESSION

```
START TEST
-----------
1. Open browser: http://localhost:5000
   → Page loads with input field ✅

2. Paste: https://github.com
   → Click "Scan URL"
   → Result: LEGITIMATE, Low Risk, 95%+ confidence ✅

3. Paste: http://secure-paypa1.com/verify
   → Click "Scan URL"
   → Result: PHISHING, High/Critical Risk, 85%+ confidence ✅

4. Paste: http://192.168.1.1/bank/login.php
   → Click "Scan URL"
   → Result: PHISHING, High Risk, 90%+ confidence ✅

5. Paste: https://techblog.com
   → Click "Scan URL"
   → Result: LEGITIMATE, Low/Medium-Low, 75%+ confidence ✅

CONCLUSION: App works as designed! ✅
```

---

## PERFORMANCE BENCHMARKING

To measure system performance, add timing:

```python
# Add to app.py /predict route

import time
start = time.time()
label, prob, reason = predict_url_label(url)
elapsed = time.time() - start
print(f"Prediction took {elapsed:.2f} seconds")
```

**Target Metrics (from FYP 1):**
- Prediction latency: < 2 seconds (webpage shows result quickly)
- Without WHOIS: < 0.5 seconds (most of the time is WHOIS lookup)
- Model inference only: < 0.1 seconds (neural network is fast)

---

## LOGGING TEST RESULTS

Create a `TEST_RESULTS.txt` file:

```
TEST RESULTS - FYP 2 Web App Validation
========================================
Date: [Today]
Tester: [Your Name]

Test Case 1: https://github.com
  Expected: LEGITIMATE, Low Risk
  Actual: LEGITIMATE, Low Risk, 95%
  Status: ✅ PASS

Test Case 2: http://secure-paypa1.com/verify
  Expected: PHISHING, High Risk
  Actual: PHISHING, High Risk, 87%
  Status: ✅ PASS

Test Case 3: http://192.168.1.1/admin/
  Expected: PHISHING, High Risk
  Actual: PHISHING, Critical Risk, 92%
  Status: ✅ PASS

[Continue...]

OVERALL: Application works as specified in FYP 1 ✅
```

---

## NEXT STEP: REPORT YOUR FINDINGS

After testing 10-15 URLs, you should be able to:

1. ✅ Confirm the ensemble model works correctly
2. ✅ Verify risk levels are assigned appropriately
3. ✅ Validate confidence scores are meaningful
4. ✅ Document any issues or edge cases
5. ✅ Generate performance metrics for FYP 2 report

Then proceed to either:
- **Option A:** Add QR code scanning to web app (2-3 hours)
- **Option B:** Start Flutter mobile app (major effort, later phase)
- **Option C:** Optimize and refine current web app

---

**Happy Testing! 🧪**

Questions? Check the alignment assessment document: `FYP1_FYP2_ALIGNMENT_ASSESSMENT.md`
