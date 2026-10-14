# Houndoc IAM

Houndoc IAM is the component of the Houndoc ecosystem that centralizes authentication, authorization, and user and role management.

This project is based on [Keycloak](https://www.keycloak.org/), an open source Identity and Access Management (IAM) solution. Within Houndoc, this component serves as the central point for managing user access and permissions for the applications and services that are part of the ecosystem.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) installed and running.
- Port `8080` available on your machine.

## Getting started: run Keycloak locally with Docker

The simplest way to start a local instance is to use the official Keycloak image in development mode. This is the flow recommended in the [official Keycloak README](https://github.com/keycloak/keycloak/blob/main/README.md).

### 1. Start the container

From the project root, run:

```bash
docker run --name houndoc-iam \
  -p 8080:8080 \
  -v "$(pwd)/themes:/opt/keycloak/themes:ro" \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.7.2 \
  start-dev \
  --spi-theme-cache-themes=false \
  --spi-theme-cache-templates=false
```

This command creates a container named `houndoc-iam`, exposes Keycloak at `http://localhost:8080`, creates the initial administrator credentials, and starts Keycloak with `start-dev`, which is appropriate for local development. It also mounts this repository's `themes/` directory in Keycloak, making the `nuvu-login` and `nuvu-admin-console` themes available. Theme caches are disabled so local theme edits are reflected after refreshing the browser.

Do not use these credentials in a shared or production environment.

### 2. Open the administration console

Once the container has started, visit:

```text
http://localhost:8080
```

Sign in with:

```text
Username: admin
Password: admin
```

From the console, you can manage the local Keycloak instance. The configuration of realms, clients, users, and roles depends on the needs of each application in the Houndoc ecosystem.

To apply a custom theme, open the target realm and go to **Realm settings** → **Themes**. Select `nuvu-login` for the login theme and/or `nuvu-admin-console` for the admin console theme, then save the changes.

### 3. Stop, start, and remove the container

```bash
# Stop
docker stop houndoc-iam

# Start again
docker start houndoc-iam

# View logs
docker logs -f houndoc-iam

# Remove the container
docker rm -f houndoc-iam
```

The instance created with this command uses the container's storage. If you remove the container, you should not assume that the local configuration can be recovered. To preserve data across recreations, configure a Docker volume and review the [official Keycloak container documentation](https://www.keycloak.org/server/containers).

## Custom project image

The [`Dockerfile`](./Dockerfile) defines a custom image based on Keycloak `26.7.2`. During the build, it includes the themes available in `themes/`, the providers available in `providers/`, the `keycloak.conf` configuration, and the truststores available in `truststores/`.

The Dockerfile also requires the `db_vendor` argument to build Keycloak:

```bash
docker build --build-arg db_vendor=<database-engine> -t houndoc-iam:local .
```

The Dockerfile configures optimized startup and parameters intended for deployment with HTTPS and a proxy. For this reason, the `start-dev` command from the previous section is recommended for a quick local test; use the custom image only when the configuration required for that environment has been defined.

### Database credentials from AWS Secrets Manager

The production `keycloak.conf` receives its database settings from `DB_URL` and
`DB_PASSWORD`:

```properties
db-url=${DB_URL}
db-password=${DB_PASSWORD}
```

Both environment variables accept a direct value. The container also detects an
ARN set directly in `db-url` or `db-password` in `keycloak.conf`. When either
source receives an AWS Secrets Manager ARN, its `SecretString` must be a JSON
object with `jdbc` and `password` fields:

```json
{
  "password": "database-password",
  "jdbc": "jdbc:postgresql://bnd-devs-iam-db.cink8syu0l45.us-east-1.rds.amazonaws.com:5432/postgres?user=iam_admin"
}
```

The same ARN can be assigned to both variables:

```text
DB_URL=arn:aws:secretsmanager:us-east-1:573578169450:secret:bnd-devs-iam-login-credentials-BVJt9T
DB_PASSWORD=arn:aws:secretsmanager:us-east-1:573578169450:secret:bnd-devs-iam-login-credentials-BVJt9T
```

For ARN values, the container uses `jdbc` for `DB_URL` and `password` for
`DB_PASSWORD`; a direct value is used unchanged. The container IAM role must
allow `secretsmanager:GetSecretValue` for the referenced secret. If the secret
uses a customer-managed KMS key, it must also allow `kms:Decrypt`. No AWS access
keys are stored in the image.

## Reference documentation

- [Official Keycloak README](https://github.com/keycloak/keycloak/blob/main/README.md)
- [Keycloak documentation](https://www.keycloak.org/documentation)
- [Keycloak containers](https://www.keycloak.org/server/containers)
