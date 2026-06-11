# sharingbridge-mobile-app

> Flutter mobile app for meal initiators (MVP)

## Status

**Shipped:** Vendor preset setup, **Help a seeker** (guidance → instruction pack → register order intent), **Order initiation history**, **Google Sign-In** (JWT role `donor` today). Push notifications are not in this MVP.

**Product language:** [README § Documentation verbiage](https://github.com/sharingbridge/sharingbridge/blob/main/README.md#documentation-guide).

**Doc map and live status:** [AGENT_HANDOFF.md](https://github.com/sharingbridge/sharingbridge/blob/main/development/AGENT_HANDOFF.md) § Documentation map.

## Run locally

```bash
flutter pub get
flutter test
```

**Backends:** user-service (`8081`) + integration-service (`8080`) running. See [configuration/e2e-deployment-sequence.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/e2e-deployment-sequence.md).

### Google Sign-In (recommended)

```powershell
flutter run -d <device> `
  --dart-define=GOOGLE_CLIENT_ID=<WEB_OAuth_client_id> `
  --dart-define=USER_SERVICE_BASE_URL=http://localhost:8081 `
  --dart-define=API_BASE_URL=http://localhost:8080
```

**API URLs depend on the device:** emulator → `10.0.2.2`; physical phone → PC LAN IP (`ipconfig`, same Wi‑Fi); hosted → `https://…onrender.com`. Do not use `localhost` on Android devices. See [mobile-client.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/mobile-client.md) § Local networking and [MANUAL_TESTING_GUIDE §3-host](https://github.com/sharingbridge/sharingbridge/blob/main/testing/MANUAL_TESTING_GUIDE.md).

**Windows desktop:** Google Sign-In is not supported by `google_sign_in`; use Android emulator or dev token below.

### Dev token (local only)

Mint a JWT with the same `AUTH_TOKEN_SECRET` as user-service:

```powershell
cd ..\sharingbridge-user-service
$token = node scripts/mint-dev-jwt.mjs demo-user donor
cd ..\sharingbridge-mobile-app
flutter run --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=AUTH_TOKEN=$token
```

## Key APIs (via integration-service)

| Flow | Endpoint |
|------|----------|
| Vendor preset setup | `POST /v1/initiator-setup/suggest-vendors`, preferences CRUD |
| Help a seeker | `POST /v1/instruction-pack` |
| Order intent | `POST` / `GET /v1/order-intents` |

Details: [configuration/field-handoff.md](https://github.com/sharingbridge/sharingbridge/blob/main/configuration/field-handoff.md).

## License

MIT — see [LICENSE](LICENSE).

Part of [SharingBridge](https://github.com/sharingbridge/sharingbridge).
