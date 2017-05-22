#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

if [ -n "${DEBUG_LEVEL}" ]; then
  echo "DEBUG INFO"
  oc whoami
  echo "  -- "
  echo ""
  ls -la /var/run/docker.sock
  echo "  -- "
  echo "pull info"
  ls -laR /var/run/secrets/openshift.io/pull
  echo "  -- cat /var/run/secrets/openshift.io/pull/.dockercfg "
  cat /var/run/secrets/openshift.io/pull/.dockercfg
  echo "  -- "
  echo "push info"
  ls -laR /var/run/secrets/openshift.io/push
  echo "  -- cat /var/run/secrets/openshift.io/push/.dockercfg "
  cat /var/run/secrets/openshift.io/push/.dockercfg
  echo "  -- "
  echo "push ~/secret-pull"
  ls -laR ~/secret-pull
  echo "  -- cat ~/secret-pull "
  cat ~/secret-pull/.dockercfg
  echo "  -- "
fi

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi


#TODO get thoses data form the build info
if [ ! -n "${OUTPUT_REGISTRY}" ]; then
  echo "OUTPUT_REGISTRY is missing"
  exit 1
fi

if [ ! -n "${OUTPUT_IMAGE}" ]; then
  echo "OUTPUT_IMAGE is missing"
  exit 1
fi

if [ ! -n "${INPUT_REGISTRY}" ]; then
  echo "INPUT_REGISTRY is missing"
  exit 1
fi

if [ ! -n "${INPUT_IMAGE}" ]; then
  echo "INPUT_IMAGE is missing"
  exit 1
fi

TAG_TO="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
TAG_FROM="${INPUT_REGISTRY}/${INPUT_IMAGE}"

docker --config ~/secret-pull pull ${TAG_FROM}
docker --config ~/secret-pull tag ${TAG_FROM} ${TAG_TO}
docker push ${TAG_TO}