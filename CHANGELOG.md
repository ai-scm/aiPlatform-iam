# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 15-09-2026

### Changed

- Renamed environment variables in `keycloak.conf` for clarity:
  - `hostname-url` → `hostname`
  - `hostname-admin-url` → `hostname-admin`

## [1.0.1] - 01-09-2026

### Fixed

- Adjusted the container configuration to operate behind a proxy using `X-Forwarded` headers, enable HTTP on port `8180`, and keep the dynamic backchannel disabled.

### Documentation

- Updated the local setup instructions to use Keycloak `26.7.2`, mount the repository themes, and disable their cache during development.
- Documented how to select the `nuvu-login` and `nuvu-admin-console` themes from the administration console.

## [1.0.0] - 28-08-2026

### Changed

- Updated the Keycloak base image from `25.0` to `26.7.2`.
- Parameterized the Keycloak version through the `KEYCLOAK_VERSION` build argument, used in both Docker image stages.
- Adapted the proxy and backchannel configuration to the current Keycloak 26 options.

### Security

- Updated to Keycloak `26.7.2`, which includes security fixes published by the project, including CVE-2026-18963: a potential unauthenticated account takeover through a reset-credentials flow bypass.

## [0.1.3] - 05-06-2026

### Added

- Truststores directory and Dockerfile support to copy truststores into the Keycloak image.
- CI/CD pipeline steps to conditionally update DynamoDB, upload the CHANGELOG, and invalidate CloudFront based on development or stable versions.
- IAM product version update in the `houndoc_product_master` DynamoDB table during the build process.

### Fixed

- Correct product key from `AIPlatform` to `IAM` in the DynamoDB update.

## [0.1.2] - 28-10-2025

### Changed

- Custom layer is supported in the customize view on aiplatform component (images and colors).


## [0.1.1] - 28-12-2023

### Fixed

- Bug with special characters on spanish lang.

## [0.1.0] - 13-12-2023

### Added

- Creation for the component and add custom layer.
