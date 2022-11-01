#!/usr/bin/env bash

# Expand parameters
readonly service_key=${!ORB_ENV_SERVICE_KEY}
readonly project_id=${!ORB_ENV_PROJECT_ID}
readonly compute_zone=${!ORB_ENV_COMPUTE_ZONE}
readonly compute_region=${!ORB_ENV_COMPUTE_REGION}

# Eval parameters
oidc_file_path=$(eval "echo $ORB_EVAL_OIDC_FILE")
cred_file_path=$(eval "echo $ORB_EVAL_CRED_FILE")

# Store service account
printf '%s\n' "$service_key" > "$HOME"/gcloud-service-key.json

# Initialize gcloud CLI
gcloud --quiet config set core/disable_usage_reporting true
gcloud --quiet config set component_manager/disable_update_check true

# Use oidc


# Determine credential source file by checking if an ENV exists as a file or a string.
# If it's a file, then use it, or if it's a string then base64 decode it.

if [ -n "$oidc_file_path" ]; then
  echo "$CIRCLE_OIDC_TOKEN" > "$oidc_file_path"
  # Store OIDC token in temp file
  gcloud iam workload-identity-pools create-cred-config \
      "projects/${!ORB_ENV_PROJECT_ID}/locations/global/workloadIdentityPools/${!ORB_ENV_POOL_ID}/providers/${!ORB_ENV_POOL_PROVIDER_ID}" \
      --output-file="$cred_file_path"  \
      --service-account="${!ORB_ENV_SERVICE_EMAIL}" \
      --credential-source-file="$oidc_file_path"

  # Configure gcloud to leverage the generated credential configuration
  gcloud auth login --brief --cred-file "$cred_file_path"
  # Configure ADC
  echo "export GOOGLE_APPLICATION_CREDENTIALS='$cred_file_path'" | tee -a "$BASH_ENV"
else
  gcloud auth activate-service-account --key-file="$HOME"/gcloud-service-key.json
fi

gcloud --quiet config set project "$project_id"

if [[ -n "$compute_zone" ]]; then
  gcloud --quiet config set compute/zone "$compute_zone"
fi

if [[ -n "$compute_region" ]]; then
  gcloud --quiet config set compute/region "$compute_region"
fi
