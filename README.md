# Habesha Hub

Community app for the Ethiopian & Eritrean diaspora — businesses, anonymous service providers
(photographers, decoration, guesthouses, transport, clothing, hawala, flight & visa), Hab Tok videos,
marketplace and an AI assistant. Languages: English (default), Tigrinya, Amharic.

- **App:** Flutter (Android `no.habesha.hub`, iOS via Codemagic)
- **Backend:** Firebase project `habesha-hub-7bd1d` (Firestore + Functions in `europe-west1`)
- **Media:** Bunny.net — Storage zone `habesha-photos` (photos), Stream (videos)
- **Website:** https://habesha-hub.no (`public/`)

## Project structure

```
lib/
  main.dart                     app start, notifications, language
  config/secrets.dart           (git-ignored, not used by the app any more)
  models/business.dart
  services/                     notifications, business queries
  theme/app_theme.dart          colors, fonts (NotoSerif + Manrope)
  utils/
    translations.dart           ALL texts — English → Tigrinya / Amharic (_textTr)
    language_notifier.dart      selected language
  widgets/business_card.dart
  screens/
    home_screen.dart            bottom tabs: Home · Explore · Services · Hab Tok · Profile
    placeholder_screens.dart    Explore, Profile, Privacy, Contact
    services_screen.dart        Services → country → category → provider → booking
    provider_extras.dart        reviews, favorites, share link, admin statistics
    payment.dart                payment methods per country, My bookings, receipt
    habesha_tok_screen.dart     vertical video feed
    marketplace_screen.dart     buy & sell, seller profiles
    ai_chat_screen.dart         AI assistant (talks to Cloud Function aiChat)
    admin_screen.dart           admin panel (tabs)
    add_service_screen.dart     admin: providers, orders, payment settings
    …                           auth, business detail/edit/register, bookings
functions/index.js              Cloud Functions (see below)
public/                         website: index, download, privacy, /p/<provider> share pages
tools/                          admin scripts (run from the project root)
firestore.rules, storage.rules  security rules
```

## Cloud Functions (`functions/index.js`)

| Function | What it does |
|---|---|
| `notifyBooking` | push to admin on a new service booking |
| `notifyCustomer` | push to the customer when a booking is confirmed / paid / cancelled |
| `aiChat` | AI assistant (Gemini key stored as secret `GEMINI_KEY`) |
| `updateProviderRating` | keeps ★ average on providers |
| `providerPage` | public share page `habesha-hub.no/p/<name>` |
| `notifyNewProvider` / `notifyNewVideo` | push to everyone (topics `news_en/ti/am`) |

## Everyday tasks

```powershell
# run the app
flutter run

# new photos/videos for a provider (Bunny folder "cameraman-1", Stream collection "Cameraman 1")
node tools/sync_bunny.js "Cameraman 1"

# deploy backend
$env:FUNCTIONS_DISCOVERY_TIMEOUT = "60"
firebase deploy --only "functions,firestore:rules,storage,hosting"

# release
flutter build appbundle --release     # → build/app/outputs/bundle/release/app-release.aab
```

## Tools (`tools/`)

| Script | Use |
|---|---|
| `sync_bunny.js "Name"` | mirror a provider's Bunny photos + videos into Firestore |
| `translate_services.js` | English names/descriptions + Tigrinya/Amharic for providers |
| `fix_countries.js` | fix Norwegian country/category names on businesses |
| `set_gemini_key.ps1` | store the Gemini key as a Cloud Functions secret |
| `fix_secrets.ps1` | stop tracking key files in git |
| `cleanup.ps1` | one-time cleanup of old files |

Never commit: `serviceAccountKey.json`, `*firebase-adminsdk*.json`, `*.jks`, `key.properties`,
`.bunny-keys.json`, `lib/config/secrets.dart` (all in `.gitignore`).
