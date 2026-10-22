# Repository development instructions

- The user approved `docs/requirements.md`, `docs/development-plan.md`, and `docs/development-rules.md`. Read them before application changes and follow the current phase. Report unverified capabilities honestly.
- Reuse this isolated checkout; do not create a Git worktree unless explicitly requested. Preserve existing changes. Do not push, publish, or upload signing credentials without authorization.
- Keep UI, application use cases, domain rules, and infrastructure separate. Domain code must not import Flutter widgets, SQLite implementations, or notification plugins.
- Use integer RMB cents and hundredths of an hour. Never calculate wages with binary floating point. Round each work category before summation.
- Preserve rate and adjustment snapshots. Historical correction requires an impact preview, explicit user confirmation in the app, and an atomic transaction.
- Use versioned database migrations and backup formats. Restore must validate first, back up current data, and replace atomically; never clear the database to solve an upgrade.
- The app is local-first with no account, analytics, advertisements, or automatic data uploads. Do not log private records or backup contents.
- Pin the SDK and application lockfile. Use `scripts/env.sh` to activate workspace tools. Keep downloaded tools, private configuration, signing files, and build artifacts out of Git.
- Run meaningful tests for changed behavior. Report static analysis, tests, Android builds, iOS builds, and device behavior separately. Never replace failed tests with skipped assertions.
- Update documentation and phase evidence with interface or behavior changes. Android success cannot stand in for iPhone verification.
