# SmartBus Guardian

SmartBus Guardian is a Flutter application with an optional Flask/SQLite
backend. It helps passengers monitor a journey, receive destination alerts,
protect against missed stops, and share an emergency location.

## Run the Flutter app

From this directory:

```powershell
flutter pub get
flutter run
```

The app requests device location permission for live tracking. Destination
search, road routing, and nearby bus-stop lookup use online OpenStreetMap
services and require network access.

## Run the backend

From the repository root, enter the tracked backend directory:

```powershell
Set-Location smartbusguardian_backend
python -m pip install -r requirements.txt
python init_db.py
python app.py
```

`init_db.py` creates `smartbus.db` from `schema.sql` if it does not already
exist. Keep that database file backed up; do not replace it when deploying over
an existing installation. The Flask server listens on port `5000`. For a
physical device, set the non-web API address in
`lib/services/api_service.dart` to the reachable IP address of the backend
machine. The Flask development server is for development only.

The SOS backend uses Twilio when `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and
`TWILIO_FROM_NUMBER` are configured. Without those credentials, remote SMS
delivery is unavailable; the app must not be treated as an emergency-service
replacement.

## Module status and known limitations

| Synopsis module | Current implementation |
| --- | --- |
| User Management | Registration, login/logout, local profile editing, and password change are implemented. Backend-backed accounts use the Flask API. Password recovery is deliberately unavailable until an email/SMS verification channel is configured; the app will not reset a password based only on an email address or phone number. |
| GPS Tracking and Route Monitoring | Live GPS tracking, online road routing, route deviation detection, and route recalculation are implemented. |
| Smart Destination Alert | Destination proximity alerts use live GPS distance and the configured alert services. |
| Sleep Protection | Journey sleep mode and scheduled alert behavior are implemented; device notification and audio permissions/settings apply. |
| Missed-Stop Detection | Detection requires a fired destination alert, at least 200 m of movement beyond the destination, and three successive increasing-distance fixes. Alternative routing still requires network access. |
| Offline Tracking | Journey data is stored locally and GPS tracking can continue on-device, but there is no explicit map-region download or offline geocoding/routing. Treat this module as partial; routes and map tiles not previously available on-device cannot be guaranteed offline. |
| Journey History and Analytics | History is account-scoped, stored locally, and synchronized with the backend for backend-linked accounts. |
| Emergency SOS | Contacts and local SOS history are account-scoped; current GPS coordinates are required for an SOS. Remote SMS delivery requires configured Twilio credentials. Backend SOS history additionally requires an active journey because the confirmed schema requires every SOS row to reference one. |

The SQLite database design in `../smartbusguardian_backend/schema.sql` is the
authoritative table definition. It contains the eight user, destination,
journey, alert, missed-stop, emergency-contact, SOS, and journey-history
tables. Application tests use temporary databases and do not modify an
existing `smartbus.db`.

## Checks

From the Flutter project directory:

```powershell
flutter analyze lib test
flutter test test --concurrency=1
```

From the repository root, enter `smartbusguardian_backend`:

```powershell
Set-Location smartbusguardian_backend
python -m py_compile app.py test_app.py
python -m unittest -v test_app
```
