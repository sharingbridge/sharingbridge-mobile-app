# sharingbridge-mobile-app

> Flutter mobile app for meal initiators (MVP)

## Status

**Shipped:** Vendor preset setup, **Start initiation** (all three routes including **Eco kitchen · I pay**), **Help a seeker**, **Initiations**, **Google Sign-In**, FCM registration when Firebase is configured, **handover map picker** (Google tiles when `GOOGLE_MAPS_API_KEY` is in `android/local.properties`; pass `--dart-define=HANDOVER_MAP_ENABLED=true` for the map UI).

**Product model:** [Eco_Kitchen_Initiation_Flow.md](https://github.com/sharingbridge/sharingbridge/blob/main/design/Eco_Kitchen_Initiation_Flow.md)

**Location services:** [Location_Services_Vendor_Abstraction.md](https://github.com/sharingbridge/sharingbridge/blob/main/design/Location_Services_Vendor_Abstraction.md) · [Handover_Location_Map_Picker.md](https://github.com/sharingbridge/sharingbridge/blob/main/design/Handover_Location_Map_Picker.md) · [mobile-client.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/mobile-client.md)

**Doc map:** [STATUS.md](https://github.com/sharingbridge/sharingbridge/blob/main/development/STATUS.md) · [AGENT_SESSION.md](https://github.com/sharingbridge/sharingbridge/blob/main/development/AGENT_SESSION.md)

## Run locally

```bash
flutter pub get
flutter test
```

**Backends:** user-service (`8081`) + integration-service (`8080`). See [e2e-deployment-sequence.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/e2e-deployment-sequence.md).

### Google Sign-In (recommended)

```powershell
flutter run -d <device> `
  --dart-define=GOOGLE_CLIENT_ID=<WEB_OAuth_client_id> `
  --dart-define=USER_SERVICE_BASE_URL=http://localhost:8081 `
  --dart-define=INTG_SRVC_BASE_URL=http://localhost:8080
```

Device URLs: [mobile-client.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/mobile-client.md). Hosted sideload: `flutter build apk --release` with the same `--dart-define` flags — [mobile-client.md § Release APK](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/mobile-client.md#release-apk-flutter-build-apk---release).

## Key flows

| Flow | Route |
|------|--------|
| Help a seeker | **Direct order** |
| Start initiation → For pledging | **Eco kitchen · open for pledging** |
| Start initiation → Eco kitchen · I pay | **Eco kitchen · I pay** |
| Initiations | Merged history |

Details: [field-handoff.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/field-handoff.md).

## License

MIT — see [LICENSE](LICENSE).

Part of [SharingBridge](https://github.com/sharingbridge/sharingbridge).
