#!/bin/sh
set -e

run_occ() {
  if [ "$$(id -u)" = "0" ]; then
    su -p www-data -s /bin/sh -c "php /var/www/html/occ $$*"
  else
    php /var/www/html/occ "$$@"
  fi
}

if [ -z "$$NEXTCLOUD_OIDC_CLIENT_ID" ] || [ -z "$$NEXTCLOUD_OIDC_CLIENT_SECRET" ]; then
  echo "oidc credentials unavailable, skipping user_oidc setup"
  exit 0
fi

ready=no
attempt=0
while [ "$$attempt" -lt 12 ]; do
  attempt=$$((attempt + 1))
  status=$$(run_occ status 2>&1 || true)
  case "$$status" in
    *"installed: true"*)
      ready=yes
      break
      ;;
  esac
  echo "occ status not ready (attempt $$attempt): $$(echo "$$status" | head -2 | tr '\n' ' ')"
  sleep 5
done

if [ "$$ready" != "yes" ]; then
  echo "nextcloud never reported installed, skipping user_oidc setup"
  exit 0
fi

if ! run_occ app:list 2>/dev/null | grep -q user_oidc; then
  run_occ app:install user_oidc
fi
run_occ app:enable user_oidc

run_occ user_oidc:provider Authentik \
  --clientid="$$NEXTCLOUD_OIDC_CLIENT_ID" \
  --clientsecret="$$NEXTCLOUD_OIDC_CLIENT_SECRET" \
  --discoveryuri="https://authentik.${TAILNET_DOMAIN}/application/o/nextcloud-oidc/.well-known/openid-configuration" \
  --scope="openid email profile" \
  --mapping-uid=sub \
  --unique-uid=0

echo "user_oidc provider Authentik configured"
