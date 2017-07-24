# This image is intended to be used to push internal images to external repository.
# It expects a set of environment variables to parameterize the build:
#
#   OUTPUT_REGISTRY - the Docker registry URL to push this image to
#   OUTPUT_IMAGE - the name to tag the image with
#   IS_NAME - the name of the imageStream to use
#   INPUT_REGISTRY - the Docker registry URL to fetch image from (internal registry)
#    example : 
#     - name: INPUT_REGISTRY
#       value: '172.30.135.130:5000'
#  
#   INPUT_IMAGE - This is an overriding mechanism to push a specific image without tags (optional)
#    example :  
#     - name: INPUT_IMAGE
#       value: >-
#        custombuild/cnp@sha256:09e2f87b64b431ed07722c0238848295c24d2806018c09e87ad418c0eb83395d
#
#   INPUT_IS_TAG - the reference tag used for the image to push
#
#   OUTPUT_IS_TAG - the tag used for the image before to pushing it
#
#   PUSH_SECRET needs to be set to /root/.push-secret
#
# This image expects to have the Docker socket bind-mounted into the container.
# Push secret need to be mounted to "/root/.push-secret" it will use that as authorization
# to a Docker registry.
#
# exemple of BuildConfig :
#
# apiVersion: v1
# kind: BuildConfig
# metadata:
# ...
# spec:
#   triggers:
#     - type: ConfigChange
#   runPolicy: Serial
#   source:
#     type: None
#   strategy:
#     type: Custom
#     customStrategy:
#       from:
#         kind: ImageStreamTag
#         namespace: custombuild
#         name: 'ose-cdb-to-external-registry:latest'
#       env:
#         - name: IS_NAME
#           value: cnp
#         - name: OUTPUT_IMAGE
#           value: 'cncparis-node/seb-node:production'
#       exposeDockerSocket: true
#       secrets:
#         - secretSource:
#             name: docker-extreg-cfg
#           mountPath: /root/.push-secret
#   output:
#     to:
#       kind: ImageStreamTag
#       name: 'ose-cdb-to-external-registry:custom'
#   resources: {}
#   postCommit: {}
#   nodeSelector: null
# 
#
############## 
# After in order to import your image from your external repository to your project 
# oc secrets new-dockercfg <secretSourceName> \
#     --docker-server=<OUTPUT_REGISTRY> \
#     --docker-username=<user> \
#     --docker-password=<password> \
#     --docker-email=<email>
# 
# oc tag OUTPUT_REGISTRY/IS_NAME:IS_TAG <current-is>:<current-tag> --scheduled
#
# NB : OUTPUT_REGISTRY (is the external registry dns)
#
FROM openshift/origin-base

ARG  YUM_UPDATE=0

RUN INSTALL_PKGS="gettext automake make docker" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

LABEL io.k8s.display-name="OpenShift Custom Builder to external repository" \
      io.k8s.description="This a custom builder for use with OpenShift in order to tag a specific taged image before pushing it to an extrenal repository."
      
ENV HOME=/root \
    OC_VERSION="v1.4.1" \
    OC_FILE="openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz" \
    OC_DIR="openshift-origin-client-tools-v1.4.1+3f9807a-linux-64bit" \
    OC_SHA256="c2ac117e85a968c4d16d5657a31dce0715dcbfa4ab4a7bc49e5c6fd7caffb7da"

RUN if [ $YUM_UPDATE -eq 1 ]; then \
      echo " yum update " && yum upgrade -y ; \
      else \    
      echo " no yum update "; \
    fi;
    
RUN echo "install openshift client ..." && \
    curl -fsSL https://github.com/openshift/origin/releases/download/${OC_VERSION}/${OC_FILE} -o /tmp/oc.tar.gz && \
    echo "${OC_SHA256}  /tmp/oc.tar.gz" | sha256sum -c - && \
    tar -C /var/lib/origin -xzf /tmp/oc.tar.gz && \
    ln -sf /var/lib/origin/${OC_DIR}/oc /usr/bin/oc 

RUN echo "install jq cli..." && \
    yum install -y epel-release &&\
    INSTALL_PKGS="jq" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all 
    
COPY bash/build-tag-and-push.sh /build-tag-and-push.sh
RUN chmod a+x /build-tag-and-push.sh
CMD ["/bin/bash","-c","/build-tag-and-push.sh"]