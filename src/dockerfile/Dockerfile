# This image is intended for testing purposes, it has the same behavior as
# the origin-docker-builder image, but does so as a custom image so it can
# be used with Custom build strategies.  It expects a set of
# environment variables to parameterize the build:
#
#   OUTPUT_REGISTRY - the Docker registry URL to push this image to
#   OUTPUT_IMAGE - the name to tag the image with
#   IS_NAME - the name of the imageStream to be use
#   INPUT_REGISTRY - a URI to fetch the build context from
#    exemple : 
#     - name: INPUT_REGISTRY
#       value: '172.30.135.130:5000'
#   INPUT_IMAGE - a reference to pass to Git for which commit to use (optional)
#    exemple :  
#     - name: INPUT_IMAGE
#       value: >-
#        custombuild/cnp@sha256:09e2f87b64b431ed07722c0238848295c24d2806018c09e87ad418c0eb83395d
#
# This image expects to have the Docker socket bind-mounted into the container.
# If "/root/.dockercfg" is bind mounted in, it will use that as authorization
# to a Docker registry.
#
# The standard name for this image is openshift/origin-custom-docker-builder
#
FROM openshift/origin-base

RUN INSTALL_PKGS="gettext automake make docker" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

LABEL io.k8s.display-name="OpenShift Origin Custom Builder Example" \
      io.k8s.description="This is an example of a custom builder for use with OpenShift Origin."
      
ENV HOME=/root \
    OC_VERSION="v1.4.1" \
    OC_FILE="openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz" \
    OC_DIR="openshift-origin-client-tools-v1.4.1+3f9807a-linux-64bit" \
    OC_SHA256="c2ac117e85a968c4d16d5657a31dce0715dcbfa4ab4a7bc49e5c6fd7caffb7da"

RUN echo "install openshift client ..." && \
    curl -fsSL https://github.com/openshift/origin/releases/download/${OC_VERSION}/${OC_FILE} -o /tmp/oc.tar.gz && \
    echo "${OC_SHA256}  /tmp/oc.tar.gz" | sha256sum -c - && \
    tar -C /var/lib/origin -xzf /tmp/oc.tar.gz && \
    ln -sf /var/lib/origin/${OC_DIR}/oc /usr/bin/oc &&\
    rm -f /tmp/node.tar.gz     
    
    
COPY bash/build-tag-and-push.sh /build-tag-and-push.sh
RUN chmod a+x /build-tag-and-push.sh
CMD ["/bin/bash","-c","/build-tag-and-push.sh"]