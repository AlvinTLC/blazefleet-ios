#!/usr/bin/env python3
import urllib.request
import json
import subprocess
import time
import sys
import os

API_KEY = "97QZQ4YBNL"
API_ISSUER = "cdbb2898-c770-4f9b-8e7e-051f8f0266c5"
BUNDLE_ID = "do.blaze.fleet"

_cached_token = None
_cached_token_time = 0

def get_token():
    global _cached_token, _cached_token_time
    now = time.time()
    # Reuse token for up to 15 minutes (valid for 20 mins)
    if _cached_token and (now - _cached_token_time < 900):
        return _cached_token

    cmd = ['xcrun', 'altool', '--generate-jwt', '--apiKey', API_KEY, '--apiIssuer', API_ISSUER]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        lines = [l.strip() for l in (proc.stdout + proc.stderr).splitlines() if l.strip().startswith('ey')]
        if lines:
            _cached_token = lines[0]
            _cached_token_time = now
            return _cached_token
    except Exception as e:
        print(f"\n[Warning] altool JWT generation exception: {e}")

    return _cached_token

def check_app():
    token = get_token()
    if not token:
        return None, None
        
    url = f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={BUNDLE_ID}"
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            apps = data.get('data', [])
            if apps:
                app = apps[0]
                return app.get('id'), app.get('attributes', {}).get('name')
    except Exception as e:
        # Ignore intermittent network errors
        pass
    return None, None

def main():
    watch = "--watch" in sys.argv
    print(f"🔎 Verificando existencia de '{BUNDLE_ID}' en App Store Connect...")
    app_id, app_name = check_app()
    
    if not app_id and watch:
        print("⏳ App aún no registrada en App Store Connect. Esperando a que sea creada...")
        print("👉 Crea la app en https://appstoreconnect.apple.com/apps")
        print("   - Nombre: BlazeFleet")
        print(f"   - Bundle ID: {BUNDLE_ID}")
        print("   - SKU: BLAZEFLEET-IOS-01")
        consecutive_errors = 0
        while not app_id:
            try:
                time.sleep(10)
                app_id, app_name = check_app()
                if app_id:
                    print(f"\n🎉 ¡App detectada! ID: {app_id} | Nombre: {app_name}")
                    break
                print(".", end="", flush=True)
                consecutive_errors = 0
            except Exception as e:
                consecutive_errors += 1
                if consecutive_errors > 10:
                    time.sleep(30)

    if app_id:
        print(f"\n✅ App confirmada en App Store Connect:")
        print(f"   ID: {app_id}")
        print(f"   Nombre: {app_name}")
        print("🚀 Iniciando carga a TestFlight...")
        script_path = os.path.join(os.path.dirname(__file__), "upload_to_testflight.sh")
        subprocess.run(["bash", script_path], check=True)
    else:
        print("\n❌ La app aún no ha sido creada en App Store Connect.")
        print("Por políticas de Apple, el registro inicial del App Record debe hacerse vía web:")
        print("1. Abre https://appstoreconnect.apple.com/apps")
        print("2. Pulsa '+' -> 'Nueva app'")
        print("3. Plataforma: iOS")
        print("4. Nombre: BlazeFleet (o 'BlazeFleet GPS')")
        print("5. Idioma principal: Español")
        print(f"6. ID de paquete (Bundle ID): {BUNDLE_ID}")
        print("7. SKU: BLAZEFLEET-IOS-01")
        print("8. Acceso de usuario: Acceso completo -> Crear")
        print("\nLuego ejecuta este script con: python3 scripts/watch_and_upload.py --watch")

if __name__ == "__main__":
    main()
