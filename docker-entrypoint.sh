#!/bin/sh

set -eu

fail() {
  echo "Unable to resolve the database configuration from AWS Secrets Manager." >&2
  exit 1
}

is_secretsmanager_arn() {
  secret_arn="$1"

  case "$secret_arn" in
    arn:aws:secretsmanager:*:secret:* | \
    arn:aws-us-gov:secretsmanager:*:secret:* | \
    arn:aws-cn:secretsmanager:*:secret:*)
      return 0
      ;;
    arn:*)
      fail
      ;;
    *)
      return 1
      ;;
  esac
}

get_secret_json() {
  secret_arn="$1"

  is_secretsmanager_arn "$secret_arn"

  secret_region=$(printf '%s' "$secret_arn" | cut -d ':' -f 4)
  [ -n "$secret_region" ] || fail

  secret_json=$(AWS_PAGER='' /usr/local/bin/aws secretsmanager get-secret-value \
    --secret-id "$secret_arn" \
    --region "$secret_region" \
    --query 'SecretString' \
    --output text 2>/dev/null) || fail

  case "$secret_json" in
    '' | None)
      fail
      ;;
  esac

  printf '%s' "$secret_json"
}

extract_secret_field() {
  secret_json="$1"
  secret_field="$2"

  secret_value=$(printf '%s' "$secret_json" | /usr/local/bin/jq -er \
    --arg field "$secret_field" \
    '.[$field] as $value | if (($value | type) == "string" and ($value | length) > 0) then $value else error("missing secret field") end' \
    2>/dev/null) || fail

  printf '%s' "$secret_value"
}

set_db_url_from_secret() {
  DB_URL=$(extract_secret_field "$1" jdbc)
  export DB_URL
  KCRAW_DB_URL="$DB_URL"
  export KCRAW_DB_URL
}

set_db_password_from_secret() {
  DB_PASSWORD=$(extract_secret_field "$1" password)
  export DB_PASSWORD
  KCRAW_DB_PASSWORD="$DB_PASSWORD"
  export KCRAW_DB_PASSWORD
}

resolve_database_configuration() {
  db_url_source="${DB_URL-}"
  db_password_source="${DB_PASSWORD-}"

  case "$db_url_source" in
    arn:*)
      if [ "$db_url_source" = "$db_password_source" ]; then
        secret_json=$(get_secret_json "$db_url_source")
        set_db_url_from_secret "$secret_json"
        set_db_password_from_secret "$secret_json"
        return
      fi

      secret_json=$(get_secret_json "$db_url_source")
      set_db_url_from_secret "$secret_json"
      ;;
  esac

  case "$db_password_source" in
    arn:*)
      secret_json=$(get_secret_json "$db_password_source")
      set_db_password_from_secret "$secret_json"
      ;;
  esac
}

resolve_database_configuration

exec /opt/keycloak/bin/kc.sh \
  --config-file=/opt/keycloak/conf/keycloak.conf \
  start \
  --optimized \
  "$@"
