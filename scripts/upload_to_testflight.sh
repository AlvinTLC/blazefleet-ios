#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

API_KEY="97QZQ4YBNL"
API_ISSUER="cdbb2898-c770-4f9b-8e7e-051f8f0266c5"
API_KEY_PATH="/Users/alvinnunez/.appstoreconnect/private_keys/AuthKey_${API_KEY}.p8"
IPA_PATH="$PROJECT_ROOT/build/export/BlazeFleet.ipa"
ARCHIVE_PATH="$PROJECT_ROOT/build/BlazeFleet.xcarchive"

echo "======================================================"
echo "🚀 BlazeFleet iOS — TestFlight Upload & Verification"
echo "======================================================"

if [ ! -f "$IPA_PATH" ]; then
    echo "📦 IPA no encontrado. Generando archivo y exportando..."
    xcodebuild archive \
      -project BlazeFleet.xcodeproj \
      -scheme BlazeFleet \
      -destination 'generic/platform=iOS' \
      -archivePath "$ARCHIVE_PATH" \
      -allowProvisioningUpdates \
      -authenticationKeyPath "$API_KEY_PATH" \
      -authenticationKeyID "$API_KEY" \
      -authenticationKeyIssuerID "$API_ISSUER"

    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$PROJECT_ROOT/build/export" \
      -exportOptionsPlist "$PROJECT_ROOT/Config/ExportOptions-export.plist" \
      -allowProvisioningUpdates \
      -authenticationKeyPath "$API_KEY_PATH" \
      -authenticationKeyID "$API_KEY" \
      -authenticationKeyIssuerID "$API_ISSUER"
fi

echo "🔍 Validando IPA contra App Store Connect..."
xcrun altool --validate-app -f "$IPA_PATH" -t ios \
  --apiKey "$API_KEY" \
  --apiIssuer "$API_ISSUER"

echo "⬆️ Subiendo BlazeFleet a TestFlight..."
xcrun altool --upload-app -f "$IPA_PATH" -t ios \
  --apiKey "$API_KEY" \
  --apiIssuer "$API_ISSUER"

echo "✅ ¡Subida a TestFlight completada con éxito!"
