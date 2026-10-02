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

def get_token():
    cmd = ['xcrun', 'altool', '--generate-jwt', '--apiKey', API_KEY, '--apiIssuer', API_ISSUER]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    lines = [l.strip() for l in (proc.stdout + proc.stderr).splitlines() if l.strip().startswith('ey')]
    if not lines:
        raise RuntimeError("No se pudo generar JWT para App Store Connect")
    return lines[0]

def check_app():
    token = get_token()
    url = f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={BUNDLE_ID}"
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            apps = data.get('data', [])
            if apps:
                app = apps[0]
                return app.get('id'), app.get('attributes', {}).get('name')
    except Exception as e:
        print(f"Error consultando API: {e}")
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
        while not app_id:
            time.sleep(10)
            app_id, app_name = check_app()
            if app_id:
                print(f"🎉 ¡App detectada! ID: {app_id} | Nombre: {app_name}")
                break
            print(".", end="", flush=True)

    if app_id:
        print(f"✅ App confirmada en App Store Connect:")
        print(f"   ID: {app_id}")
        print(f"   Nombre: {app_name}")
        print("🚀 Iniciando carga a TestFlight...")
        script_path = os.path.join(os.path.dirname(__file__), "upload_to_testflight.sh")
        subprocess.run(["bash", script_path], check=True)
    else:
        print("❌ La app aún no ha sido creada en App Store Connect.")
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
