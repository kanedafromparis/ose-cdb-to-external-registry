#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${INPUT_IMAGE}" ]; then
  IN_TAG="${INPUT_REGISTRY}/${INPUT_IMAGE}"
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
  OUT_TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
fi

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then

  #docker login ${INPUT_REGISTRY}
  docker pull "${IN_TAG}"
  docker tag "${IN_TAG}" "${OUT_TAG}"
  docker login -u "${OUTPUT_REGISTRY_USERNAME}" -p "${OUTPUT_REGISTRY_PASSWORD}" "${OUTPUT_REGISTRY}"
  docker push "${OUT_TAG}"

fi