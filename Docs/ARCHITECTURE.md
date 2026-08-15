# Architecture

QuotaBar separates provider-specific API semantics from the shared menu bar presentation.

## Data flow

1. `QuotaStore` schedules a refresh and asks all enabled providers for a snapshot.
2. Each provider performs an allowlisted HTTPS request and maps its response into `ProviderSnapshot`.
3. Successful snapshots replace cached in-memory values independently.
4. A provider failure leaves other provider results usable and is represented as an explicit error state.
5. The menu bar and popover render semantic metrics without pretending that currency balances and rate-limit percentages are interchangeable.

## Providers

- **Codex:** reads the active local Codex auth context and calls the read-only WHAM usage and reset-credit endpoints. It does not refresh or write Codex credentials.
- **OpenRouter:** calls the current-key endpoint with the regular API key. When a Management Key exists, it also requests account credit totals.
- **DeepSeek:** calls the official user balance endpoint.

## Security boundaries

- Secrets use macOS Keychain.
- Codex credentials are read for each request and are never copied into QuotaBar storage.
- Network destinations are exact HTTPS URLs owned by the configured provider.
- Redirects are rejected.
- Raw credentials, raw responses, and full account identifiers must not be logged.
- Provider actions are read-only.

## Appearance

The macOS 14 baseline uses system materials and semantic colors. A future macOS 26-specific layer can add Liquid Glass effects behind availability checks without changing provider or view-model code.
