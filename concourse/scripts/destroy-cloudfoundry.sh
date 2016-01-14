#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
FLY_TARGET=${FLY_TARGET:-$ATC_URL}

env=${DEPLOY_ENV-$1}
pipeline="destroy-cloudfoundry"
config="${SCRIPT_DIR}/../pipelines/destroy-cloudfoundry.yml"
bosh_password=$("$SCRIPT_DIR"/s3get.sh ${env}-state bosh-secrets.yml > /dev/null && awk '$1~/bosh_admin_password/ {print $2}' bosh-secrets.yml)
[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_name: ${pipeline}
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
aws_access_key_id: ${AWS_ACCESS_KEY_ID}
aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY}
bosh_password: ${bosh_password}
debug: ${DEBUG:-}
EOF
}
generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

fly -t "$FLY_TARGET" unpause-pipeline --pipeline "${pipeline}"


