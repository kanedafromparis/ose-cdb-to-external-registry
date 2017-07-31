# Push to external registry

This code is inspiread from : 
 - https://github.com/openshift/origin/blob/master/images/builder/docker/custom-docker-builder/Dockerfile
 - https://github.com/YannMoisan/openshift-tagger-custom-builder
 - https://blog.openshift.com/getting-any-docker-image-running-in-your-own-openshift-cluster/
 - https://coderleaf.wordpress.com/2017/02/10/run-docker-as-user-on-centos7/

The purpose of this code is to allows from an openshift server to push a docker images for internal registry to an external registry. It will use custombuild strategy to push existing image from internal registry to an external registry.

# How to use it

## in order to build the docker image used for the custom build named "external-pusher"

oc new-app -f src/ose-files/build-to-external-builder.yaml 

It will create the buildconfig for the image ans the imagestream.

## in order to the custom build

1 - import the "external-pusher" image into your project 

    oc tag <source_project>/<image_stream>:<tag> <new_image_stream>:<new_tag>

    for instance 
    
    oc tag custom-pusher/build-to-external-registry:latest build-to-external-registry:1.0
    
cf . https://docs.openshift.com/container-platform/3.4/dev_guide/managing_images.html#importing-tag-and-image-metadata

2 - create the custom builder

2.a - without using ImageStream tag :

    oc new-app -f src/ose-files/build-to-external-pusher.yaml \
     -p IMAGESTREAM_NAME=<IMAGESTREAM_NAME> \
     -p IMAGESTREAM_TAG=<IMAGESTREAM_TAG> \
     -p OUTPUT_REGISTRY=<OUTPUT_REGISTRY> \
     -p OUTPUT_IMAGE=<OUTPUT_IMAGE> \
     -p INPUT_REGISTRY=<INPUT_REGISTRY> \
     -p INPUT_IMAGE=<INPUT_IMAGE>

     for instance

    oc new-app -f src/ose-files/build-to-external-pusher.yaml \
     -p IMAGESTREAM_NAME=ose-cdb-to-external-registry \
     -p IMAGESTREAM_TAG='1.0' \
     -p OUTPUT_REGISTRY=repo.example-01.com \
     -p OUTPUT_IMAGE=project/tt0:prod \
     -p INPUT_REGISTRY=172.30.135.155:5000 \
     -p INPUT_IMAGE=current-ns/tt00@sha256:da13798eee695eca94d26f1c7b0b9cb97ff6b425a3b45278d5cca344c67675bc

2.b - using ImageStream tag :

Beware that in order to allow your cutom build to access and update ImageStream, you need to use a serviceaccount with editing right on you ImageStream. You also need tag to exist on your IS to be tag with INPUT_IS_TAG (default is uat)

    oc new-app -f src/ose-files/build-to-external-pusher-with-is-tag.yaml \
     -p NAMESPACE=$(oc project | cut -d'"' -f2) \
     -p PULL_SECRET_NAME=<PULL_SECRET_NAME> \
     -p IMAGESTREAM_NAME=<IMAGESTREAM_NAME> \
     -p IMAGESTREAM_TAG=<IMAGESTREAM_TAG> \
     -p OUTPUT_REGISTRY=<OUTPUT_REGISTRY> \
     -p OUTPUT_IMAGE=<OUTPUT_IMAGE> \
     -p INPUT_REGISTRY=<INPUT_REGISTRY> \
     -p IS_NAME=<IS_NAME>

     for instance

    oc new-app -f src/ose-files/build-to-external-pusher-with-is-tag.yaml \
     -p NAMESPACE=custom-push-project \
     -p PULL_SECRET_NAME=docker-pullsecrete-cfg \
     -p IMAGESTREAM_NAME=ose-cdb-to-external-registry \
     -p IMAGESTREAM_TAG=latest \
     -p OUTPUT_REGISTRY=repo.example-01.com \
     -p OUTPUT_IMAGE=test/php-project:prod \
     -p INPUT_REGISTRY=172.30.1.1:5000 \
     -p IS_NAME=php-cake     

3 - in order to use this external image into another project 

you can use the template :

    oc new-app -f src/ose-files/build-to-external-pusher-with-is-tag.yaml \
     -p DEV_PROJECT_NAME=$(oc project | cut -d'"' -f2) \
     -p IMAGESTREAM_NAME=<IMAGESTREAM_NAME> \
     -p IMAGESTREAM_TAG='IMAGESTREAM_TAG' \
     -p OUTPUT_REGISTRY=<OUTPUT_REGISTRY> \
     -p OUTPUT_IMAGE=<OUTPUT_IMAGE> 

     example :
     
   oc new-app -f src/ose-files/build-to-external-pusher-with-is-tag.yaml \
     -p DEV_PROJECT_NAME=My-producion-project \
     -p IMAGESTREAM_NAME=my-new-is \
     -p IMAGESTREAM_TAG='prod' \
     -p OUTPUT_REGISTRY=repo.example-01.com \
     -p OUTPUT_IMAGE=project/tt0:prod 


- name: IMAGESTREAM_NAME
  description: The ImageStream used for the BuildConfig
- name: DEV_PROJECT_NAME
  description: The name on the project using this ImageStream
- name: IMAGESTREAM_TAG
  description: The ImageStream tag used
  value: prod
- name: OUTPUT_REGISTRY
  description: the Docker registry URL to retreive the image from
  value: "172.30.135.130:5000"
- name: OUTPUT_IMAGE
  description: the name of the tagged the image
  value: "custombuild/cnp-custom:custom"

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
for working on roles issue :
DEV_PROJECT_NAME=custom-pusher
oc new-project $DEV_PROJECT_NAME
oc export secret docker-extreg-cfg -n custombuild | oc create -f -
oc export bc/cnp -n custombuild | oc create -f -
oc export bc/vfttsjrq -n custombuild | oc create -f -
oc export is/cnp -o yaml -n custombuild | oc create -f -
oc export is/ose-cdb-to-external-registry -o yaml -n custombuild | oc create -f -

oc policy add-role-to-user system:image-puller system:serviceaccount:custombuild:default --namespace=$DEV_PROJECT_NAME


--
oc secrets link --for=pull builder docker-extreg-cfg


--
### tips :

#### docker-machine env ose14-cb

eval $(docker-machine env ose14-cb)

docker run --rm -it --entrypoint /bin/bash ose-cdb-to-external-registry

##### default docker build

docker build -t ose-cdb-to-external-registry -f ./src/dockerfile/Dockerfile ./src/dockerfile/;

##### enforced yum update docker build

docker build --build-arg YUM_UPDATE=1 -t ose-cdb-to-external-registry -f ./src/dockerfile/Dockerfile ./src/dockerfile/;

_ --no-cache could be used ;-) _

oc create -f ./src/ose-files/jobs-util.yaml

#### Cleaning

RM_LST=`docker ps -a | grep Exited | awk '{print $1}'` && docker rm $RM_LST

RMI_LST=`docker images | grep none | awk '{print $3}'` && docker rmi $RMI_LST
