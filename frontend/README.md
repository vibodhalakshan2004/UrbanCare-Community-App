# UrbanCare Frontend (Flutter Mobile)

This folder contains the Flutter mobile frontend for the UrbanCare Community App.
It is designed to work with the existing backend running on:

http://127.0.0.1:8000

## Implemented Features

- Authentication: signup and login with JWT storage
- Complaint creation flow: issue type, title, description, current GPS location, image
- Firebase Storage image upload before complaint submission
- Nearby complaints map using Google Maps
- Geofence-based nearby notifications using geofence_service
- Complaint detail and verification action
- Clean architecture style with modular services, repositories, models, and reusable widgets

## Backend Endpoint Mapping

- POST /auth/signup
- POST /auth/login
- POST /complaints/
- GET /complaints/
- GET /complaints/{id}
- POST /complaints/{complaint_id}/verify?citizen_id=...&is_fixed=...
- GET /geofence/nearby?lat=...&lng=...

## Project Structure

The code follows the requested modular structure under lib:

- core/api
- core/config
- core/services
- core/utils
- models
- repositories
- screens/auth
- screens/home
- screens/complaint
- screens/map
- widgets
- theme

## Setup

1. Install Flutter SDK and verify with flutter doctor.
2. From this folder run:
	flutter pub get
3. Start backend server on http://127.0.0.1:8000.

## Firebase Setup (Required for Image Upload)

The app auto-calls Firebase.initializeApp(), but you must configure platform credentials:

1. Create or select a Firebase project.
2. Configure the app with flutterfire configure or manually add config files:
	- Android: android/app/google-services.json
	- iOS: ios/Runner/GoogleService-Info.plist
3. Re-run flutter pub get after configuration if needed.

## Google Maps Setup

Add platform API keys:

- Android key placeholder is in android/app/build.gradle.kts as MAPS_API_KEY
- iOS key placeholder is in ios/Runner/Info.plist as GMSApiKey

Replace placeholders with valid keys before running map features.

### Web Map Behavior

The app uses an OpenStreetMap fallback for Flutter web map rendering, so web runs do not require a Google Maps key by default.

### Optional: Google Maps Key for Web

For Flutter web (google_maps_flutter_web), you must:

1. Enable "Maps JavaScript API" in Google Cloud for your project.
2. Enable billing on the same Google Cloud project.
3. Create an API key with HTTP referrer restrictions for local/dev domains, for example:
	- http://localhost/*
	- http://127.0.0.1/*
	- https://your-domain.com/*
4. Replace YOUR_WEB_MAPS_API_KEY in web/index.html.

If this key is missing/invalid/restricted incorrectly, Google Maps web shows:
"Oops! Something went wrong. This page didn't load Google Maps correctly."

## Run

From this folder:

- flutter pub get
- flutter run

## Notes

- The app is built for mobile behavior. Desktop/web runs may have limited geofence support.
- Current backend complaint schema accepts primary_image_url; the app also sends image_urls for forward compatibility.
- If using Android emulator and backend runs on host machine, you may need to switch API base URL to http://10.0.2.2:8000 in lib/core/config/env.dart.
