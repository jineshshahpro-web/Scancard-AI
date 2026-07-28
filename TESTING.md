# Testing

## Run everything

```bash
flutter test                 # unit + widget tests
flutter test --coverage      # + lcov.info for coverage tooling
```

CI (`.github/workflows/ci.yaml`) runs `dart format --set-exit-if-changed`,
`flutter analyze --fatal-infos`, and the full test suite on every push/PR.

## What's covered

| Area | File | Notes |
|---|---|---|
| Input validation | `test/core/utils/validators_test.dart` | email/password/phone/required rules |
| Exception→Failure mapping | `test/core/error/result_test.dart` | every exception type maps correctly |
| Offline regex parser | `test/features/ai_parsing/data/services/regex_fallback_parser_test.dart` | messy-OCR handling + **stress: 2,000 synthetic cards** |
| Search/filter usecase | `test/features/contacts/domain/usecases/search_contacts_test.dart` | name/company/title/email/phone/tag/favorite matching + **stress: 20,000 contacts, asserts <500ms** |
| Contact repository (offline-first) | `test/features/contacts/data/repositories/contact_repository_impl_test.dart` | online vs offline save/delete paths, remote-failure resilience, favorite toggle, and **stress: 500-contact sync backlog** |
| Auth controller | `test/features/auth/presentation/providers/auth_controller_test.dart` | sign-in/up/out success + failure states via `ProviderContainer` overrides |
| `PrimaryButton` | `test/widget/primary_button_test.dart` | loading state, disabled state, tap handling |
| `EmptyState` | `test/widget/empty_state_test.dart` | content + action button |
| `ContactListTile` | `test/widget/contact_list_tile_test.dart` | initials avatar, favorite star, offline indicator, tap |
| `LoginScreen` | `test/widget/login_screen_test.dart` | client-side validation, submit wiring to the repository, password visibility toggle |
| Order regex parser | `test/features/orders/data/services/regex_order_parser_test.dart` | qty×name×price line parsing, tax detection, **stress: 1,000 synthetic receipts** |
| `OrderEntity` totals | `test/features/orders/domain/entities/order_entity_test.dart` | subtotal/tax/discount/total/itemCount math |

`test/helpers/mocks.dart` centralizes every `mocktail` mock class and
fallback-value registration so individual test files stay focused on
behavior rather than mock setup.

## Why "stress" tests here mean something specific

These aren't load tests against a real backend (that needs a live
Firebase project + device farm, out of scope for a unit-test suite).
They're **synchronous, in-process volume tests** that catch the two
failure modes most likely to bite a growing contact book:

1. **Accidental O(n²) behavior** — e.g. a search or sync loop that
   re-scans the whole list per item. The assertions on elapsed
   milliseconds (not exact benchmarks, generous margins) fail loudly
   if someone introduces one.
2. **Off-by-one / partial-failure bugs at scale** — e.g. the
   sync-pending-changes loop silently dropping contacts after one
   throws. Small lists can hide this; a 500-item run doesn't.

## Not yet covered (good next additions)

- **Widget golden tests** (`golden_toolkit` is already a dev
  dependency) for `ContactDetailScreen`, dark mode, and tablet layouts
- **Integration tests** (`integration_test` package) driving the real
  scan → OCR → save flow on a device/emulator — camera and ML Kit
  can't be meaningfully unit-tested, only integration-tested
- **`AiParsingRepositoryImpl` tests** — currently untested directly
  because `GeminiDataSource`/`OpenAiDataSource` are concrete SDK
  wrappers rather than injected interfaces; extracting a thin
  `AiTextGenerator` interface first would make this mockable
- Firestore/Storage rules tests via the `@firebase/rules-unit-testing`
  emulator suite (the rules themselves are in `firestore.rules` /
  `storage.rules`, but nothing currently exercises them automatically)
