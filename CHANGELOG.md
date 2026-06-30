# Changelog

All notable changes to this project will be documented in this file.

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
