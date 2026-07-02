#!/usr/bin/env bash
# Spark — Gate 4/5 App Store readiness static scan.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

pass() {
  echo "OK: $1"
}

echo "==> Gate 4: Privacy permissions"
for key in NSPhotoLibraryUsageDescription NSLocationWhenInUseUsageDescription NSCalendarsUsageDescription NSCalendarsFullAccessUsageDescription; do
  if rg -q "$key" Config/SparkURLScheme.plist 2>/dev/null; then
    pass "$key declared"
  else
    fail "Missing $key"
  fi
done

if rg -q 'NSCameraUsageDescription' Config/SparkURLScheme.plist 2>/dev/null; then
  pass "NSCameraUsageDescription declared"
else
  fail "Missing NSCameraUsageDescription"
fi

for key in NSMicrophoneUsageDescription NSContactsUsageDescription; do
  if rg -q "$key" Config Spark --glob '*.plist' 2>/dev/null; then
    fail "Unused permission key present: $key"
  fi
done
pass "no unused mic/contacts permission keys"

echo "==> Gate 4: PrivacyInfo collected data types"
if rg -q 'NSPrivacyCollectedDataTypeEmailAddress' Spark/PrivacyInfo.xcprivacy 2>/dev/null \
  && rg -q 'NSPrivacyCollectedDataTypePhoneNumber' Spark/PrivacyInfo.xcprivacy 2>/dev/null \
  && rg -q 'NSPrivacyCollectedDataTypeOtherUserContent' Spark/PrivacyInfo.xcprivacy 2>/dev/null; then
  pass "PrivacyInfo declares collected data types"
else
  fail "PrivacyInfo missing collected data type declarations"
fi

echo "==> Gate 4: Sign in with Apple"
if rg -q 'signInWithAppleTapped|SignInWithAppleButton' Packages/SparkAuth/Sources/SparkAuth/Presentation/LoginView.swift 2>/dev/null; then
  pass "LoginView wires Apple sign-in"
else
  fail "LoginView missing Apple sign-in"
fi

echo "==> Gate 4: Token storage"
if rg -q 'UserDefaults.*token|UserDefaults.*password' Packages Spark --glob '**/*.swift' -i 2>/dev/null; then
  fail "Possible token/password in UserDefaults"
else
  pass "no obvious token/password in UserDefaults"
fi

echo "==> Gate 4: Account deletion"
if rg -q 'deleteAccount' Packages/SparkAuth/Sources --glob '**/*.swift' 2>/dev/null \
  && rg -q 'onDeleteAccount' Packages/SparkProfile/Sources --glob '**/*.swift' 2>/dev/null; then
  pass "account deletion flow present"
else
  fail "account deletion flow missing"
fi

echo "==> Gate 4: Legal links in Profile"
if rg -q 'SparkLegalLinks' Packages/SparkProfile/Sources --glob '**/*.swift' 2>/dev/null; then
  pass "privacy/terms links in Profile"
else
  fail "legal links missing from Profile"
fi

echo "==> Gate 4: Community UGC report"
if rg -q 'CommunityReportSheet|reportPost' Packages/SparkCommunity/Sources --glob '**/*.swift' 2>/dev/null; then
  pass "community report entry present"
else
  fail "community report entry missing"
fi

echo "==> Gate 4: Release API configuration"
if [[ -f Config/SparkRelease.xcconfig ]] && rg -q 'https://api.spark.app' Config/SparkRelease.xcconfig 2>/dev/null; then
  pass "Release xcconfig points to production API host"
else
  fail "Release xcconfig missing production API URL"
fi

echo "==> Gate 4: Production push entitlements"
if [[ -f Config/SparkRelease.entitlements ]] && rg -q '<string>production</string>' Config/SparkRelease.entitlements 2>/dev/null; then
  pass "Release entitlements use production APNs"
else
  fail "Release entitlements missing production APNs"
fi

echo "==> Gate 5: Demo login copy hidden in Release"
if rg -q 'auth.login.hint' Packages/SparkAuth/Sources/SparkAuth/Presentation/LoginView.swift 2>/dev/null; then
  if rg -q '#if DEBUG' Packages/SparkAuth/Sources/SparkAuth/Presentation/LoginView.swift 2>/dev/null; then
    pass "login demo hint guarded for DEBUG"
  else
    fail "login demo hint not DEBUG-guarded"
  fi
else
  pass "login demo hint removed"
fi

echo "==> Gate 5: StoreKit restore purchases"
if rg -q 'restorePurchases' Packages/SparkPayments/Sources --glob '**/*.swift' 2>/dev/null; then
  pass "restore purchases implemented"
else
  fail "restore purchases missing"
fi

echo "==> Gate 5: App Icon assets"
ICON_DIR="Spark/Assets.xcassets/AppIcon.appiconset"
if [[ -f "$ICON_DIR/icon-1024.png" ]] || [[ -f "$ICON_DIR/AppIcon-1024.png" ]]; then
  pass "App Icon 1024 PNG present"
elif rg -q '"idiom"\s*:\s*"universal"' "$ICON_DIR/Contents.json" 2>/dev/null; then
  pass "App Icon universal slot declared in Contents.json"
else
  fail "App Icon 1024 PNG missing"
fi

echo "==> Gate 5: iPhone-only target"
if rg -q 'TARGETED_DEVICE_FAMILY = 1;' Spark.xcodeproj/project.pbxproj 2>/dev/null; then
  pass "TARGETED_DEVICE_FAMILY set to iPhone"
else
  fail "App still targets iPad (needs screenshots) or family not updated"
fi

echo
echo "Gate 4/5 static scan complete. Failures: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
