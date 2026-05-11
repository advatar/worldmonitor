# Code Review: worldmonitor

Review date: 2026-05-11
Tracker: https://github.com/advatar/Tracker/issues/53
Scope: top-level app folder `worldmonitor` and nested project manifests under this folder, excluding generated dependency/build directories such as `.git`, `node_modules`, `target`, `.build`, `dist`, and virtual environments.

## Executive Summary

- Overall risk from this sweep: **High**
- Findings by severity: High 1, Medium 4, Low 0
- Source footprint: 1735 source files by extension scan (TypeScript 947, JavaScript 486, Protobuf 256, CSS 13, HTML 11, SQL 8, Swift 6, Shell 6)
- Test footprint: 279 test-like files detected
- CI footprint: 10 GitHub Actions workflow files detected
- Git posture: clean before review generation
- Pattern scan budget used: 1795 text/source files scanned

## Architecture Snapshot

Detected project and build surfaces:
- `Dockerfile`
- `apple-tv/Package.swift`
- `blog-site/package-lock.json`
- `blog-site/package.json`
- `consumer-prices-core/Dockerfile`
- `consumer-prices-core/package-lock.json`
- `consumer-prices-core/package.json`
- `docker-compose.yml`
- `docker/Dockerfile`
- `package-lock.json`
- `package.json`
- `pro-test/package-lock.json`
- `pro-test/package.json`
- `scripts/package-lock.json`
- `scripts/package.json`
- `scripts/shared/package.json`
- `src-tauri/Cargo.toml`
- `src-tauri/sidecar/package.json`

Nested manifest owners sampled:
- `.`
- `apple-tv`
- `blog-site`
- `consumer-prices-core`
- `docker`
- `pro-test`
- `scripts`
- `scripts/shared`
- `src-tauri`
- `src-tauri/sidecar`

Package scripts sampled:
- ``blog-site/package.json`: build`
- ``consumer-prices-core/package.json`: build, test, test:watch`
- ``package.json`: build, build:blog, build:commodity, build:desktop, build:finance, build:full, build:happy, build:pro, build:sidecar-sebuf, build:tech, desktop:build:finance, desktop:build:full`
- ``pro-test/package.json`: build, lint`

Local instruction/status files:
- `AGENTS.md`
- `STATUS.md`
- `apple-tv/STATUS.md`

## Findings

### 1. [High] Dynamic code or shell execution needs input-boundary review

These APIs are legitimate in tooling, but they become high-risk when command strings or evaluated input can be influenced by users, files, networks, or model output. Scanner count: 6.

Evidence:
- tests/oref-proxy.test.mjs:25 `return execSync(`
- tests/oref-proxy.test.mjs:44 `execSync('curl --version', { encoding: 'utf8', timeout: 5000 });`
- tests/oref-proxy.test.mjs:78 `const output = execSync(`
- tests/product-catalog-freshness.test.mjs:70 `execSync('npx tsx scripts/generate-product-config.mjs', { cwd: ROOT, stdio: 'pipe' });`
- tests/product-catalog-freshness.test.mjs:122 `execSync('npx tsx scripts/generate-product-config.mjs', { cwd: ROOT, stdio: 'pipe' });`
- tests/product-catalog-freshness.test.mjs:160 `const result = execSync(`
### 2. [Medium] Potential credential/config material needs a focused secret audit

Names commonly used for credentials or sensitive tokens appear in app-owned files. Some hits may be fixtures or placeholders, but every example should be verified, documented as fake, or moved to secret management. Values are redacted here. Scanner count: 3352.

Evidence:
- api/_api-key.js:34 `export function validateApiKey(req, options = {}) {`
- api/_oauth-token.js:6 `async function fetchOAuthToken(uuid) {`
- api/_oauth-token.js:10 `const resp = await fetch(`${creds.url}/get/${encodeURIComponent(`oauth:token:[REDACTED]}`)}`, {`
- api/_oauth-token.js:11 `headers: { Authorization: `Bearer ${creds.token}` },`
- api/_oauth-token.js:14 `// Throw on HTTP error so callers can distinguish Redis failure (→ 503) from missing token (→ 401).`
- api/_oauth-token.js:22 `// Legacy: 16-char fingerprint for client_credentials tokens (backward compat)`
- api/_oauth-token.js:23 `export async function resolveApiKeyFromFingerprint(fingerprint) {`
- api/_oauth-token.js:32 `// New: full SHA-256 (64 hex chars) for authorization_code / refresh_token issued tokens`
### 3. [Medium] Broad CORS/debug or insecure transport settings need environment gating

Wildcard CORS, debug flags, or disabled TLS verification should be mechanically limited to local/dev environments. Scanner count: 2.

Evidence:
- consumer-prices-core/src/db/client.ts:17 `ssl: databaseUrl.includes('localhost') ? false : { rejectUnauthorized: false },`
- src-tauri/sidecar/local-api-server.mjs:1121 `const parentOrigin = isAllowedParentOrigin ? rawParentOrigin : '*';`
### 4. [Medium] HTML injection surfaces need sanitization review

Direct HTML insertion needs one sanitizer policy and regression tests around every untrusted content path. Scanner count: 352.

Evidence:
- src/app/desktop-updater.ts:172 `toast.innerHTML = ``
- src/app/event-handlers.ts:795 `dropdown.innerHTML = ``
- src/app/event-handlers.ts:1521 `btn.innerHTML = isFullscreen ? shrinkSvg : expandSvg;`
- src/app/panel-layout.ts:308 `this.ctx.container.innerHTML = ``
- src/app/panel-layout.ts:606 `this.criticalBannerEl.innerHTML = ``
- src/bootstrap/sw-update.ts:116 `toast.innerHTML = ``
- src/components/AirlineIntelPanel.ts:362 `this.content.innerHTML = `<div class="panel-loading">${t('common.loading')}</div>`;`
- src/components/AirlineIntelPanel.ts:380 `this.content.innerHTML = `<div class="no-data">${t('components.airlineIntel.noOpsData')}</div>`;`
### 5. [Medium] Many nested project manifests increase ownership and verification complexity

This app folder contains many buildable surfaces. Document ownership and canonical verification commands so fixes do not verify the wrong package.

Evidence:
- Dockerfile
- apple-tv/Package.swift
- blog-site/package-lock.json
- blog-site/package.json
- consumer-prices-core/Dockerfile
- consumer-prices-core/package-lock.json
- consumer-prices-core/package.json
- docker-compose.yml

## Testing and Build Posture

Detected tests:
- `apple-tv/Tests/WorldMonitorTVClientTests/MockURLProtocol.swift`
- `apple-tv/Tests/WorldMonitorTVClientTests/WorldMonitorTVClientTests.swift`
- `consumer-prices-core/src/adapters/search.test.ts`
- `consumer-prices-core/src/adapters/validator.test.ts`
- `consumer-prices-core/tests/unit/matcher.test.ts`
- `consumer-prices-core/tests/unit/pinning.test.ts`
- `consumer-prices-core/tests/unit/search-extract-size.test.ts`
- `consumer-prices-core/tests/unit/size.test.ts`
- `consumer-prices-core/tests/unit/title.test.ts`
- `convex/__tests__/checkout.test.ts`
- `convex/__tests__/emailSuppressions.test.ts`
- `convex/__tests__/entitlements.test.ts`

Detected CI workflows:
- `.github/workflows/build-desktop.yml`
- `.github/workflows/contributor-trust.yml`
- `.github/workflows/deploy-gate.yml`
- `.github/workflows/docker-publish.yml`
- `.github/workflows/lint-code.yml`
- `.github/workflows/lint.yml`
- `.github/workflows/proto-check.yml`
- `.github/workflows/test-linux-app.yml`
- `.github/workflows/test.yml`
- `.github/workflows/typecheck.yml`

Inferred verification commands to standardize:
- JavaScript: run the owning package-manager install/build/test scripts from the relevant `package.json`.
- Rust: run `cargo test` or workspace-specific checks from each Cargo workspace root.
- Swift Package: run `swift test` from each package root.

## Review Limitations

- This was a broad static review across many local apps, not a full manual product walkthrough.
- Generated directories and dependency trees were pruned so findings focus on app-owned source.
- Secret-like values were not reproduced; examples are redacted or limited to path/line evidence.
- Pattern scanning is capped per app to keep the cross-repository sweep tractable; high-risk folders need focused follow-up review.

## Recommended Next Steps

1. Resolve every High finding first, especially secret material, tracked generated output, and dynamic execution paths.
2. Add or tighten the app's canonical CI workflow so build and tests run on every push.
3. Convert inferred build/test commands into documented commands in the app README or STATUS file.
4. Add smoke tests around app launch, persistence, API boundaries, and security-sensitive adapters.
5. Re-run this review after cleanup and replace this file with a human-reviewed release checklist.
