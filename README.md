# sharingbridge-mobile-app

> Flutter mobile app for meal initiators (MVP)

## Status

**Shipped:** Vendor preset setup, **Start initiation** (Direct order + For pledging), **Help a seeker** (direct order path), **Initiations** (merged list), **Google Sign-In**.

**Product model:** [Eco_Kitchen_Initiation_Flow.md](https://github.com/sharingbridge/sharingbridge/blob/main/design/Eco_Kitchen_Initiation_Flow.md) — three routes; **Eco kitchen · I pay** coming soon.

**Doc map:** [AGENT_HANDOFF.md](https://github.com/sharingbridge/sharingbridge/blob/main/development/AGENT_HANDOFF.md).

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
  --dart-define=API_BASE_URL=http://localhost:8080
```

Device URLs: [mobile-client.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/mobile-client.md).

## Key flows

| Flow | Route |
|------|--------|
| Help a seeker | **Direct order** |
| Start initiation → For pledging | **Eco kitchen · open for pledging** (partial) |
| Initiations | Merged history |

Details: [field-handoff.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/field-handoff.md).

## License

MIT — see [LICENSE](LICENSE).

Part of [SharingBridge](https://github.com/sharingbridge/sharingbridge).
