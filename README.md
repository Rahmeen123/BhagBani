# Baghbani

Baghbani is a single-account Flutter app for agriculture, gardening, nurseries and community discovery.

## Run locally

1. Install Flutter and configure an Android, iOS, web or desktop target.
2. In a terminal, change to `backend` and start the API (see
   [`backend/README.md`](backend/README.md) for environment setup):

   ```powershell
   Set-Location backend
   python -m pip install -r requirements.txt
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

   The first startup downloads the plant-health model and may take a while.
   Wait for the server to finish startup, then confirm
   `http://localhost:8000/docs` opens.
3. In a second terminal, run `flutter pub get` and `flutter run`.

Flutter Web uses `http://localhost:8000` for plant health by default. The
Android emulator uses `http://10.0.2.2:8000`. For a physical Android device,
set both API URLs to the computer's LAN address, for example:

```powershell
flutter run `
  --dart-define=CROP_RECOMMENDATION_API_BASE_URL=http://192.168.1.10:8000 `
  --dart-define=PLANT_HEALTH_API_BASE_URL=http://192.168.1.10:8000
```

Replace `192.168.1.10` with the development machine's LAN IP.

## Crop recommendations on Android

The Crop Recommendation entry in the dashboard opens a protected flow: after
sign-in, the user returns to the feature intro, selects a farm on Google Maps,
and receives the top three recommendations with weather details.

Enable the Google Maps SDK for Android and billing for your Google Cloud
project. Put your key in the ignored `android/local.properties` file:

```properties
MAPS_API_KEY=your-restricted-android-maps-key
```

Gradle also accepts the `MAPS_API_KEY` environment variable or project
Gradle property. The key is injected by Gradle and should not be committed.
Restrict it to this app's Android package (`com.baghbani.baghbani`) and
the signing certificate used by your build.

The default API URL (`http://10.0.2.2:8000`) is for the Android emulator. For a
physical Android device, use the development machine's LAN address and keep
both devices on the same network:

```powershell
$env:MAPS_API_KEY = "your-restricted-android-maps-key"
flutter run --dart-define=CROP_RECOMMENDATION_API_BASE_URL=http://192.168.1.10:8000
```

Replace `192.168.1.10` with the machine's LAN IP. The development Android build
allows cleartext HTTP for local testing; production deployments should use
HTTPS. The backend API contract and OpenAPI docs are available in
`backend/README.md` and at `/docs`.

## Current scope

The current build includes onboarding, welcome, sign in, sign up, local password
update, profile editing, Help & Guide, notifications, a single dashboard, crop
recommendations, and tree recommendations.

Account data is stored on the current device with shared_preferences; passwords are hashed before local storage. This is a development-only local authentication flow. Connect a production identity service before using real accounts or password recovery. Password recovery currently updates the matching local account directly.

The supplied Figma file could not be read in this session because the Figma connector and browser access were unavailable. The current palette and components are an agriculture-inspired implementation and still need a visual pass against the Figma reference.
