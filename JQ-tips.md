# Check readinessProbe configuration (first oc get dc) : 

    oc get dc $DCTOINSPEC -n $DEV_PROJECT_NAME -o json | jq ".spec.template.spec.containers[]?.readinessProbe"

# Check container environment variable (first oc get dc) : 

    oc get dc $DCTOINSPEC -n $DEV_PROJECT_NAME -o json | jq ".spec.template.spec.containers[]?.env"

# Check container volume mount (first oc get dc) : 

    oc get dc $DCTOINSPEC -n $DEV_PROJECT_NAME -o json | jq ".spec.template.spec.containers[]?.volumeMounts"

# Check all the containers volume mount paths in a project : 

    oc get dc -o json -n $DEV_PROJECT_NAME |  jq -e '(.items[]?.spec.template.spec.volumes[]?)'

    oc get dc -o json -n $DEV_PROJECT_NAME |  jq -e '(.items[]?.spec.template.spec.containers[]?.volumeMounts)'

# Check all the containers environment variables in a project (@todo improve with containers name) :

    oc get dc -o json -n $DEV_PROJECT_NAME |  jq -e '(.items[]?.spec.template.spec.containers[]?.env[]?)'

# Get Value for copy needed environment variables in a project (@todo improve with containers name) :

DATABASE_NAME=`oc get dc -o json -n $DEV_PROJECT_NAME |  jq -er '(.items[]?.spec.template.spec.containers[]?.env[]? | select(.name == "MYSQL_DATABASE")).value'`

MYSQL_PASSWORD=`oc get dc -o json -n $DEV_PROJECT_NAME |  jq -er '(.items[]?.spec.template.spec.containers[]?.env[]? | select(.name == "MYSQL_PASSWORD")).value'| head -1`

MYSQL_USER=`oc get dc -o json  -n $DEV_PROJECT_NAME |  jq -er '(.items[]?.spec.template.spec.containers[]?.env[]? | select(.name == "MYSQL_USER")).value'| head -1`

# Replace Value for secret htpasswd  in a project  :

    oc get secrets htpasswd-uat -o json | jq ".data.htpasswd=\"$NEW_VAL\"" | oc replace secrets htpasswd-uat -f -
    
    oc delete jobs -l app=supercron-jobs-openshift

    LST_PRJ=`oc get project -l role=webhop-production --no-headers | awk '{print $1}'` && for PJT in $LST_PRJ; do echo "$PJT"; oc get jobs -l app=supercron-jobs-openshift --no-headers -n $PJT ;done;

# This command allows to check that a projec that own a PV own a cron jobs

    LST_PRJ=`oc get project -l role=webhop-production --no-headers | awk '{print $1}'` && for PJT in $LST_PRJ; do echo "***** $PJT ******"; oc get jobs -l app=supercron-jobs-openshift --no-headers -n $PJT ; oc get pvc -l webhop-info/backup=true --no-headers -n $PJT ;done;
