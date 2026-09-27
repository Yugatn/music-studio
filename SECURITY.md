# Security model

Music Studio treats project files, AI providers, plugins and synchronization as separate trust boundaries.

## Current principles

- Never commit API keys, signing keys, keystores, provisioning profiles or private certificates.
- AI providers receive only the project context required for the requested operation.
- AI output is untrusted data: it produces recommendations/change plans, not executable code.
- AI recommendations never silently overwrite the user's composition.
- `.yms` files are treated as untrusted input and must be decoded defensively.
- Synchronization must authenticate peers and validate project/revision identifiers before applying changes.
- Plugin support must remain disabled until a signed/validated plugin policy is defined.
- Release artifacts should be signed and verified before distribution.

## macOS release security

For release builds, use Developer ID signing, Hardened Runtime and notarization. Keep runtime exceptions to the minimum required by actual plugin/audio functionality.

## Android release security

Release APK/AAB artifacts must be cryptographically signed. Signing keys must remain outside source control; Google Play App Signing should be used for Play distribution.

## Secrets

Use environment variables or the CI secret store for credentials. Never place secrets in Swift source, Kotlin source, JSON configuration committed to Git, or project files.

## Reporting

Do not publish exploitable vulnerability details in a normal issue. Report suspected security vulnerabilities privately to the project maintainer until a fix is available.