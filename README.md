# ScanCard AI

Scan business cards, extract contact details with on-device OCR (Google ML
Kit) refined by AI parsing (Gemini/OpenAI), and manage them in a fast,
offline-capable, cross-platform address book — built with Flutter, Firebase,
and Riverpod, using Clean Architecture (MVVM).

> **Status:** Step 1 of the guided build — project scaffold only.
> Screens are placeholders; features are added incrementally, one at a
> time, in the steps that follow.

## Architecture

Clean Architecture, three layers per feature, unidirectional dependency
flow (`presentation → domain → data`, never the reverse):

```
lib/
├── main.dart                  # Entry point: Firebase bootstrap, error zone
├── app.dart                   # Root MaterialApp.router (theme + routing)
│
├── core/                      # Shared, feature-agnostic code
│   ├── config/                 # Env vars, Firebase options
│   ├── constants/               # App-wide constants
│   ├── di/                     # Root Riverpod providers
│   ├── error/                   # Exceptions ↔ Failures ↔ Result<T>
│   ├── network/                 # Connectivity abstraction (offline support)
│   ├── routing/                 # go_router configuration
│   ├── theme/                   # Material 3 light/dark theme
│   ├── utils/                   # Logger, validators, extensions
│   └── widgets/                 # Shared reusable widgets & animations
│
├── features/
│   ├── auth/                   # Firebase Authentication (email + Google)
│   ├── contacts/                # CRUD, search, Firestore + local cache
│   ├── scan_card/                # Camera capture + ML Kit OCR
│   ├── ai_parsing/               # Gemini/OpenAI structured parsing
│   ├── export/                   # CSV / PDF / VCF export, save-to-phone
│   └── settings/                 # Theme toggle, account, AI provider
│
└── l10n/                       # Localization (future)

test/                          # Mirrors lib/ structure
```

Each feature folder follows the same three sub-layers:

| Layer          | Responsibility                                              | Depends on |
|----------------|---------------------------------------------------------------|------------|
| `domain`       | Entities, repository *interfaces*, use cases. Pure Dart, no Flutter/Firebase imports. | nothing |
| `data`         | Models (`fromJson`/`toJson`), remote/local data sources, repository *implementations*. | `domain` |
| `presentation` | Riverpod providers (view models), screens, widgets.           | `domain` |

Errors flow as `Exception`s in `data` → mapped to `Failure`s in `domain`
(`Either<Failure, T>` via `dartz`) → surfaced as friendly UI state in
`presentation`. See `core/error/`.

## Tech stack

| Concern              | Package(s) |
|-----------------------|------------|
| State management      | `flutter_riverpod`, `riverpod_generator` |
| Backend                | `firebase_auth`, `cloud_firestore`, `firebase_storage` |
| OCR                     | `google_mlkit_text_recognition`, `camera` |
| AI parsing               | `google_generative_ai` (Gemini) / `dio` → OpenAI REST |
| Offline cache             | `drift` (SQLite) + `connectivity_plus` |
| Routing                    | `go_router` |
| Export                      | `csv`, `pdf` + `printing`, `flutter_contacts` (VCF/save-to-phone) |
| Animation                    | `flutter_animate`, `lottie`, `shimmer` |
| Codegen                       | `freezed`, `json_serializable`, `drift_dev`, `riverpod_generator` |

## Getting started

```bash
flutter pub get

# Configure Firebase for this project (generates
# lib/core/config/firebase_options.dart — see the placeholder inside
# for details):
dart pub global activate flutterfire_cli
flutterfire configure

# Generate freezed/json_serializable/drift/riverpod code:
dart run build_runner build --delete-conflicting-outputs

# Run with AI provider keys injected at build time (never hard-coded):
flutter run \
  --dart-define=GEMINI_API_KEY=your_key_here \
  --dart-define=DEFAULT_AI_PROVIDER=gemini
```

## Build roadmap

- [x] 1. Project structure
- [x] 2. Firebase Authentication (email/password + Google, splash redirect)
- [x] 3. Home screen (responsive nav shell, contacts list host)
- [x] 4. Camera scanner with live preview + animated scan-frame overlay
- [x] 5. Image cropping (image_cropper) + enhancement (contrast/sharpen/grayscale)
- [x] 6. Google ML Kit OCR integration
- [x] 7. AI parsing of OCR text (Gemini/OpenAI, with offline regex fallback)
- [x] 8. Save contacts to Firestore + offline Drift cache + device contacts
- [x] 9. Search, favorites filter, contact detail screen
- [x] 10. Export — CSV, PDF, VCF + share sheet
- [x] 11. Premium AI features — contact summaries, follow-up email drafts
- [x] 12. Polish — animations, empty/error states, ProviderObserver logging,
      release prep (`PERMISSIONS.md`, `RELEASE_CHECKLIST.md`)
- [x] 13. **Order scanning** — snap a receipt/invoice, OCR + AI extracts
      line items (name/qty/price) + tax/discount, shown as an editable
      itemized form and then a professional receipt-style summary card.
      Same offline-first Drift + Firestore pattern as contacts, its own
      "Orders" tab, and a scan-mode picker sheet (card vs. order) behind
      the single Scan FAB.

See `PERMISSIONS.md` for required native permission entries and
`RELEASE_CHECKLIST.md` before shipping to the Play Store / App Store.

## Security & quality

- `firestore.rules` / `storage.rules` — every contact and card image
  is scoped to `request.auth.uid == ownerId`; deploy with
  `firebase deploy --only firestore:rules,storage`
- `.github/workflows/ci.yaml` — format check, `flutter analyze
  --fatal-infos`, and the full test suite on every push/PR
- Release builds swap Flutter's default red error screen for a
  friendly one (`ErrorWidget.builder` in `main.dart`) and log every
  provider failure centrally (`AppProviderObserver`)
- See `TESTING.md` for what's covered — including two "stress" tests
  (20k-contact search, 500-contact offline sync backlog) that catch
  accidental O(n²) regressions as the app scales
