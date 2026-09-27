# Threat model

Music Studio must defend against both automated and human attackers.

## Threats

- Malicious project files.
- Compromised sync credentials.
- Account takeover.
- Network interception or downgrade attempts.
- Replay of old project revisions.
- Unauthorized device registration.
- Tampered release artifacts.
- Malicious or compromised plugins.
- Secrets leaked through logs, crash reports or repositories.
- Brute-force and abuse of sync/API endpoints.
- Supply-chain compromise of dependencies.

## Security architecture

### Device identity

Each registered device gets a unique cryptographic identity. The private key stays in the platform secure storage and is never uploaded.

### Transport

Network synchronization must use authenticated TLS. The protocol must reject invalid certificates, unsupported protocol versions and malformed messages.

### Authorization

Authentication alone is not sufficient. Every operation must be authorized against:

- account;
- device;
- project;
- revision;
- operation type.

### Replay protection

Sync operations carry monotonically increasing revisions plus a unique operation identifier. Previously accepted operations must not be accepted again.

### Project integrity

A project revision should carry an integrity/authentication record. Local corruption and unexpected modification must be detectable before applying the revision.

### Recovery

Security-sensitive state must support:

- session revocation;
- device removal;
- key rotation;
- project recovery from trusted revisions;
- audit events without recording musical secrets unnecessarily.

### Secrets

Never commit passwords, API keys, OAuth tokens, private keys, Android keystores or Apple signing certificates. CI secrets belong in the CI secret store.

## Security boundary

A compromised AI provider must not automatically compromise the device.

A compromised sync server must not automatically gain the ability to impersonate a registered device.

A malicious project must not automatically gain code execution.

A compromised plugin must be treated as a separate high-risk trust boundary.

## Implementation order

1. ProjectValidator and resource limits.
2. Signed revision envelope and replay protection.
3. Device identity and secure key storage.
4. Authenticated sync protocol.
5. Session/device revocation.
6. Plugin isolation and signing policy.
7. Release signing and supply-chain verification.
8. Security-focused automated tests.

Security controls should fail closed: invalid authentication, authorization, integrity, revision or protocol state must reject the operation rather than silently downgrade to an unsafe path.
