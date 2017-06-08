#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock
PUSH_SECRET=/root/.push-secret

#env
#oc whoami
ls -al ${PUSH_SECRET}
#ls -al /var/run/secrets/openshift.io/push
#ls -al /var/run/secrets/openshift.io/pull

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi


if [ ! -e "${PUSH_SECRET}" ]; then
  echo "push secret file is missing at ${PUSH_SECRET}"
  exit 1
else
  OUTPUT_REGISTRY=`cat ${PUSH_SECRET}/.dockercfg | jq -r 'keys'[0]`;
  OUTPUT_REGISTRY_USERNAME=`cat ${PUSH_SECRET}/.dockercfg  | jq -r ".\"$OUTPUT_REGISTRY\".username"`;
  OUTPUT_REGISTRY_PASSWORD=`cat ${PUSH_SECRET}/.dockercfg  | jq -r ".\"$OUTPUT_REGISTRY\".password"`;
fi


if [ -z "${OUTPUT_REGISTRY}" ]; then
  echo "OUTPUT_REGISTRY is missing"
  exit 1
fi



#TODO improve with git describe --exact-match <commit-id>
if [ -n "${INPUT_IMAGE}" ]; then
  if [ -z "${INPUT_REGISTRY}" ]; then
    echo "INPUT_REGISTRY is missing"
    exit 1
  fi
  IN_TAG="${INPUT_REGISTRY}/${INPUT_IMAGE}"
else
  if [ -n "${IS_NAME}" ]; then
    IS_VALUE=`oc get is ${IS_NAME} -o json`
    if [ -z "${IS_VALUE}" ]; then
      echo "no imageStream ${IS_NAME} in this project";
      exit 1
    fi
    TAG_UAT=`echo ${IS_VALUE} | jq -r ".status.tags[]|select(.tag == \"uat\")|.items|max_by(.created)|.dockerImageReference"`
    if [ -z "${TAG_UAT}" ]; then
      echo "no tag \"uat\" in imageStream ${IS_NAME} in this project";
      exit 1
    fi
     oc tag ${IS_NAME}:uat ${IS_NAME}:production
     IN_TAG=`echo ${IS_VALUE} | jq -r ".status.tags[]|select(.tag == \"production\")|.items|max_by(.created)|.dockerImageReference"`
  else
      echo "INPUT_IMAGE or IS_NAME need to be set"
      exit 1
  fi
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
  OUT_TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}";
else
  echo "OUTPUT_IMAGE is missing"
  exit 1
fi

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then

  #docker login ${INPUT_REGISTRY}
  docker pull "${IN_TAG}"
  docker tag "${IN_TAG}" "${OUT_TAG}"
  docker login -u ${OUTPUT_REGISTRY_USERNAME} -p ${OUTPUT_REGISTRY_PASSWORD} ${OUTPUT_REGISTRY}
  docker push "${OUT_TAG}"

fi