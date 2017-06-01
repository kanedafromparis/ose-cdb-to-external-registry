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
FROM openshift/origin:v1.3.3

RUN INSTALL_PKGS="gettext automake make docker jq" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

LABEL io.k8s.display-name="OpenShift Origin Custom Builder Example" \
      io.k8s.description="This is an example of a custom builder for use with OpenShift Origin."
ENV HOME=/root
COPY bash/build-tag-and-push.sh /build-tag-and-push.sh
RUN chmod a+x /build-tag-and-push.sh
CMD ["/bin/bash","-c","/build-tag-and-push.sh"]