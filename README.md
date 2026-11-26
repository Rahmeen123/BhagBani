# Baghbani

Baghbani is a single-account Flutter app for agriculture, gardening, nurseries and community discovery.

## Run locally

1. Install Flutter and configure an Android, iOS, web or desktop target.
2. Run flutter pub get.
3. Run flutter run.

## Crop recommendations on Android

The Crop Recommendation entry in the dashboard opens a protected flow: after
sign-in, the user returns to the feature intro, selects a farm on Google Maps,
and receives the top three recommendations with weather details.

Enable the Google Maps SDK for Android for your Google Cloud project, then set
`MAPS_API_KEY` in the environment before launching the app. The key is injected
by Gradle and is not stored in the repository. Restrict the key to this app's
Android package and signing certificate.

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
