#!/usr/bin/env bash

# Expand parameters
readonly service_key=${!ORB_ENV_SERVICE_KEY}
readonly project_id=${!ORB_ENV_PROJECT_ID}
readonly compute_zone=${!ORB_ENV_COMPUTE_ZONE}
readonly compute_region=${!ORB_ENV_COMPUTE_REGION}

# Eval parameters
cred_file_path=$(eval "echo $ORB_EVAL_CRED_FILE")

# Store service account
printf '%s\n' "$service_key" > "$HOME"/gcloud-service-key.json

# Initialize gcloud CLI
gcloud --quiet config set core/disable_usage_reporting true
gcloud --quiet config set component_manager/disable_update_check true

if [ -z "$CLOUDSDK_AUTH_ACCESS_TOKEN" ]; then # check issue/93
  # Use oidc
  if [ "$ORB_VAL_USE_OIDC" = 1 ]; then
    echo "Authorizing using OIDC token"

    if [ -z "$CIRCLE_OIDC_TOKEN" ]; then
      echo "Ensure this job has a context to populate OIDC token"
      echo "See more: https://circleci.com/docs/openid-connect-tokens/#openid-connect-id-token-availability"
      exit 1
    fi

    echo "$CIRCLE_OIDC_TOKEN" > "$HOME/oidc_token"
    # Store OIDC token in temp file
    gcloud iam workload-identity-pools create-cred-config \
        "projects/${!ORB_ENV_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${!ORB_ENV_POOL_ID}/providers/${!ORB_ENV_POOL_PROVIDER_ID}" \
        --service-account="${!ORB_ENV_SERVICE_EMAIL}" \
        --credential-source-type="text" \
        --credential-source-file="$HOME/oidc_token" \
        --output-file="$cred_file_path"

    # Configure gcloud to leverage the generated credential configuration
    gcloud auth login --brief --cred-file "$cred_file_path"
    # Configure ADC
    echo "export GOOGLE_APPLICATION_CREDENTIALS='$cred_file_path'" | tee -a "$BASH_ENV"
  else
    gcloud auth activate-service-account --key-file="$HOME"/gcloud-service-key.json
  fi
fi

gcloud --quiet config set project "$project_id"

if [[ -n "$compute_zone" ]]; then
  gcloud --quiet config set compute/zone "$compute_zone"
fi

if [[ -n "$compute_region" ]]; then
  gcloud --quiet config set compute/region "$compute_region"
fi
