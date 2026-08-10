# Security Policy

## Supported versions

Only the latest published release is supported with security fixes.

## Reporting a vulnerability

Please do not disclose a suspected vulnerability in a public issue. Use the repository's GitHub Security Advisories feature to submit a private vulnerability report to the maintainers.

Do not include passwords, access tokens, private URLs, customer data, or other sensitive information in public issues, pull requests, sample files, or test data.

## Project security properties

- The program does not access the network.
- The program does not read or modify file contents.
- Registry changes are limited to the current Windows user under `HKEY_CURRENT_USER`.
- Rename operations refuse to overwrite an existing destination.
- Rename history is stored locally to support undo.
