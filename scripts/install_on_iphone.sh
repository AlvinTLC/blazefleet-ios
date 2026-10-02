#!/usr/bin/env bash
set -e

DEVICE_ID="8E2F8979-7E80-54DA-9C0E-0C758992C382"
BUNDLE_ID="do.blaze.fleet"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔨 Compilando BlazeFleet para Alvin iPhone..."
xcodebuild build \
  -project "$PROJECT_ROOT/BlazeFleet.xcodeproj" \
  -scheme BlazeFleet \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -authenticationKeyPath "/Users/alvinnunez/.appstoreconnect/private_keys/AuthKey_97QZQ4YBNL.p8" \
  -authenticationKeyID "97QZQ4YBNL" \
  -authenticationKeyIssuerID "cdbb2898-c770-4f9b-8e7e-051f8f0266c5"

APP_PATH="/Users/alvinnunez/Library/Developer/Xcode/DerivedData/BlazeFleet-dygrbbnxpxqmsshbflhzorxyxiiu/Build/Products/Debug-iphoneos/BlazeFleet.app"

echo "📲 Instalando BlazeFleet en iPhone..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "🚀 Iniciando BlazeFleet..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" || echo "ℹ️ Dispositivo con pantalla bloqueada. Desbloquea tu iPhone para abrir BlazeFleet."

echo "✅ ¡BlazeFleet instalado con éxito en tu iPhone!"
