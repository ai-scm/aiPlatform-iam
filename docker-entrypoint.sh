#!/bin/sh

set -eu

fail() {
  echo "Unable to resolve the database configuration from AWS Secrets Manager." >&2
  exit 1
}

resolve_secret_arn() {
  secret_arn="$1"

  case "$secret_arn" in
    arn:aws:secretsmanager:*:secret:* | \
    arn:aws-us-gov:secretsmanager:*:secret:* | \
    arn:aws-cn:secretsmanager:*:secret:*)
      ;;
    arn:*)
      fail
      ;;
    *)
      return 1
      ;;
  esac

  secret_region=$(printf '%s' "$secret_arn" | cut -d ':' -f 4)
  [ -n "$secret_region" ] || fail

  secret_value=$(AWS_PAGER='' /usr/local/bin/aws secretsmanager get-secret-value \
    --secret-id "$secret_arn" \
    --region "$secret_region" \
    --query 'SecretString' \
    --output text 2>/dev/null) || fail

  case "$secret_value" in
    '' | None)
      fail
      ;;
  esac

  printf '%s' "$secret_value"
}

resolve_db_url() {
  case "${DB_URL-}" in
    arn:*)
      DB_URL=$(resolve_secret_arn "$DB_URL")
      export DB_URL
      KCRAW_DB_URL="$DB_URL"
      export KCRAW_DB_URL
      ;;
  esac
}

resolve_db_password() {
  case "${DB_PASSWORD-}" in
    arn:*)
      DB_PASSWORD=$(resolve_secret_arn "$DB_PASSWORD")
      export DB_PASSWORD
      KCRAW_DB_PASSWORD="$DB_PASSWORD"
      export KCRAW_DB_PASSWORD
      ;;
  esac
}

resolve_db_url
resolve_db_password

exec /opt/keycloak/bin/kc.sh \
  --config-file=/opt/keycloak/conf/keycloak.conf \
  start \
  --optimized \
  "$@"
