#!/usr/bin/env bash

# Expand parameters
readonly service_key=${!ORB_ENV_SERVICE_KEY}
readonly project_id=${!ORB_ENV_PROJECT_ID}
readonly compute_zone=${!ORB_ENV_COMPUTE_ZONE}
readonly compute_region=${!ORB_ENV_COMPUTE_REGION}

# Store service account
printf '%s\n' "$service_key" > "$HOME"/gcloud-service-key.json

# Initialize gcloud CLI
gcloud --quiet config set core/disable_usage_reporting true
gcloud --quiet config set component_manager/disable_update_check true
gcloud auth activate-service-account --key-file="$HOME"/gcloud-service-key.json
gcloud --quiet config set project "$project_id"

if [[ -n "$compute_zone" ]]; then
  gcloud --quiet config set compute/zone "$compute_zone"
fi

if [[ -n "$compute_region" ]]; then
  gcloud --quiet config set compute/region "$compute_region"
fi
