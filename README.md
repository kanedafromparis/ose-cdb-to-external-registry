# Push to external registry

This code is inspiread from : 
 - https://github.com/openshift/origin/blob/master/images/builder/docker/custom-docker-builder/Dockerfile
 - https://github.com/YannMoisan/openshift-tagger-custom-builder
 - https://blog.openshift.com/getting-any-docker-image-running-in-your-own-openshift-cluster/
 - https://coderleaf.wordpress.com/2017/02/10/run-docker-as-user-on-centos7/

The purpose of this code is to allows from an openshift server to push a docker images for internal registry to an external registry

## In progress Work

The following are command used on my development
--
if using oc cluser up on docker-machine : 

# set up the environement : 

$ oc cluster up --metrics=false --use-existing-config=false --version="v1.4.1" --create-machine=false --docker-machine='ose14-cb'

$ oc login -u system:admin && oc adm policy add-cluster-role-to-user cluster-admin developer
--
# create the project to push to external registry :
$ oc login -u developer

$ oc new-project external

$ oc new-app https://github.com/kanedafromparis/cncparis-node.git

$ oc logs -f bc/cncparis-node

$ oc env dc cncparis-node -e OPENSHIFT_NODEJS_IP={valueFrom:fieldRef:{apiVersion:v1,fieldPath:status.podIP}}

$ oc edit dc cncparis-node

$ oc tag cncparis-node:latest cncparis-node:pre-production

--
# create the needed secrets :

$ oc secrets new-dockercfg docker-extreg-cfg     \
    --docker-server=$OUTPUT_REGISTRY \
    --docker-username=$USERNAME     \
    --docker-password=$PASSWORD      \ 
    --docker-email=$EMAIL

$ oc new-app -f src/ose-files/build-to-external.yaml -p GIT_REF=develop -p APPLICATION_NAME=cnp ...
    
--
### tips :

#### docker-machine env ose14-cb

eval $(docker-machine env ose14-cb)

docker run --rm -it --entrypoint /bin/bash ose-cdb-to-external-registry

#### Cleaning

RM_LST=`docker ps -a | grep Exited | awk '{print $1}'` && docker rm $RM_LST

RMI_LST=`docker images | grep none | awk '{print $3}'` && docker rmi $RMI_LST
