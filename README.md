# HelloChat Live

Clone de **Parallel Live** — simulation d'application de live streaming social (inspiré de BIGO Live / TikTok Live).

## Fonctionnalités

- Diffusion via la caméra frontale en temps réel
- Chat en overlay avec défilement automatique
- Messages simulés de viewers (en français)
- Compteur de viewers dynamique
- Badge LIVE, avatar streamer
- Envoi de ses propres messages

## Stack

- Flutter
- Plugin `camera` pour l'accès à la caméra

## Lancer le projet

```bash
flutter pub get
flutter run
```

> L'app demandera la permission d'accès à la caméra au premier lancement.

## Permissions requises

**iOS** — `NSCameraUsageDescription` déclarée dans `Info.plist`

**Android** — `android.permission.CAMERA` déclarée dans `AndroidManifest.xml`
