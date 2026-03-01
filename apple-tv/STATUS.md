# Apple TV implementation status

## Completed
- [x] Bootstrap SwiftPM package for Apple TV client and app shell.
- [x] Added tvOS SwiftUI dashboard shell with profile switching, module cards, and module detail view.
- [x] Added HTTP client for `manifest`, `bootstrap`, and `dashboard` endpoints.

## In progress
- [x] Add and run package-level Swift unit tests for client networking behavior.
- [ ] Capture follow-up notes from successful Apple TV simulator/device smoke test.

## Planned
- [ ] Add endpoint-specific payload renderers in module detail view.
- [ ] Add app shell metadata for production signing/signing workflow in `XCODE_SHELL`.
