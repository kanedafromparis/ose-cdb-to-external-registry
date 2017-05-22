# This image is intended for testing purposes, it has the same behavior as
# the origin-docker-builder image, but does so as a custom image so it can
# be used with Custom build strategies.  It expects a set of
# environment variables to parameterize the build:
#
#   OUTPUT_REGISTRY - the Docker registry URL to push this image to
#   OUTPUT_IMAGE - the name to tag the image with
#   SOURCE_URI - a URI to fetch the build context from
#   SOURCE_REF - a reference to pass to Git for which commit to use (optional)
#
# This image expects to have the Docker socket bind-mounted into the container.
# If "/root/.dockercfg" is bind mounted in, it will use that as authorization
# to a Docker registry.
#
# The standard name for this image is openshift/origin-custom-docker-builder
#

FROM centos:centos7

LABEL io.k8s.display-name="OpenShift Origin Custom Builder Centos 7 Base" \
      io.k8s.description="This is a custom base image to pull image from imagestreamTag to external registry." \
      maintainer="kanedafromparis@gmail.com" \
      version="0.2.0" 

#Notice the "+" difference between DIR and FILE....
#@TODO check this issue to a simplier version
ENV OC_VERSION="v1.4.1" \
    OC_FILE="openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz" \
    OC_DIR="openshift-origin-client-tools-v1.4.1+3f9807a-linux-64bit" \
    OC_SHA256="c2ac117e85a968c4d16d5657a31dce0715dcbfa4ab4a7bc49e5c6fd7caffb7da" \
    HOME=/home/docker-publisher 

RUN echo "Install initial package ..."  && \
    yum install -y epel-release && \
    INSTALL_PKGS="jq which git tar wget mailx ssmtp hostname sysvinit-tools util-linux bsdtar \
      socat ethtool device-mapper iptables tree findutils nmap-ncat e2fsprogs xfsprogs lsof \
      device-mapper-persistent-data ceph-common gettext automake make docker" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/origin
    

# This sepration is for layer optimisation reuse (will seen if that's a good idea)    
    
RUN echo "install openshift client ..." && \
    curl -fsSL https://github.com/openshift/origin/releases/download/${OC_VERSION}/${OC_FILE} -o /tmp/oc.tar.gz && \
    echo "${OC_SHA256}  /tmp/oc.tar.gz" | sha256sum -c - && \
    tar -C /var/lib/origin -xzf /tmp/oc.tar.gz && \
    ln -sf /var/lib/origin/${OC_DIR}/oc /usr/bin/oc &&\
    rm -f /tmp/node.tar.gz 

COPY bash/push-to-external-registry.sh /root/push-to-external-registry.sh
COPY bash/daemon.json /etc/docker/daemon.json

RUN chmod ug+x /root/push-to-external-registry.sh && mkdir -p /root/secret-pull

#USER 1001

WORKDIR ${HOME}

ENTRYPOINT ["/bin/bash"]

CMD ["/root/docker-publisher/push-to-external-registry.sh"]
