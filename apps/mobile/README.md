# VibeMingle Android (Flutter)
Flutter workspace target for VibeMingle.
## Dependencies
- Supabase Flutter Auth
- LiveKit Flutter SDK (`livekit_client`)
- dotenv for local development configuration
## Local setup
Run from `apps/mobile` with Flutter 3. latest stable and Dart 3.10+:
```sh
flutter pub get
flutter analyze
flutter test
```
The repository currently contains UI scaffolds and SDK dependency only. Generated Android/iOS platform projects, secure API token fetching, room connect, camera/mic tracks, participant rendering, and end-to-end call tests must still be implemented and verified. Do not place LiveKit API secrets in the mobile app.
