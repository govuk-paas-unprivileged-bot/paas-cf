#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream
WORKDIR=${WORKDIR:-.}


opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/change-vm-types-dev.yml "
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/scale-down-dev.yml "
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/speed-up-deployment-dev.yml "
fi

alerts_opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/alerts.d/*.yml; do
  alerts_opsfile_args+="-o $i "
done

if [ "${ENABLE_ALERT_NOTIFICATIONS:-}" == "false" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/disable-alert-notifications.yml"
fi

variables_file="$(mktemp)"
trap 'rm -f "${variables_file}"' EXIT

cat <<EOF > "${variables_file}"
---
metrics_environment: $DEPLOY_ENV
bosh_url: $BOSH_URL
uaa_bosh_exporter_client_secret: $BOSH_EXPORTER_PASSWORD
system_domain: $SYSTEM_DNS_ZONE_NAME
app_domain: $APPS_DNS_ZONE_NAME
metron_deployment_name: $DEPLOY_ENV
skip_ssl_verify: false
traffic_controller_external_port: 443
loggregator_ca_name: /$DEPLOY_ENV/$DEPLOY_ENV/loggregator_ca
uaa_clients_cf_exporter_secret: $UAA_CLIENTS_CF_EXPORTER_SECRET
uaa_clients_firehose_exporter_secret: $UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET
aws_account: $AWS_ACCOUNT
aws_region: $AWS_REGION
grafana_auth_google_client_id: $GRAFANA_AUTH_GOOGLE_CLIENT_ID
grafana_auth_google_client_secret: $GRAFANA_AUTH_GOOGLE_CLIENT_SECRET
bosh_ca_cert: "$BOSH_CA_CERT"
vcap_password: $VCAP_PASSWORD
EOF

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${variables_file}" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/cf-manifest/env-specific/${ENV_SPECIFIC_BOSH_VARS_FILE}" \
  --vars-file="${PAAS_CF_DIR}/manifests/prometheus/env-specific/${ENV_SPECIFIC_BOSH_VARS_FILE}" \
  ${opsfile_args} \
  ${alerts_opsfile_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
