# Combination of https://github.com/code-ready/snc/blob/4.2.8/snc.sh and
# https://blog.openshift.com/revamped-openshift-all-in-one-aio-for-labs-and-fun/

OC=${OC:-.local/bin/oc}

${OC} scale --replicas=0 deployment --all -n openshift-cluster-version

# Get the pod name associated with cluster-monitoring-operator deployment
cmo_pod=$(${OC} get pod -l app=cluster-monitoring-operator -o jsonpath="{.items[0].metadata.name}" -n openshift-monitoring)
# Disable the deployment/replicaset/statefulset config for openshift-monitoring namespace
${OC} scale --replicas=0 deployment --all -n openshift-monitoring
# Wait till the cluster-monitoring-operator pod is deleted
${OC} wait --for=delete pod/$cmo_pod --timeout=60s -n openshift-monitoring
# Disable the statefulset for openshift-monitoring namespace
${OC} scale --replicas=0 statefulset --all -n openshift-monitoring

# Delete the pods which are there in Complete state
${OC} delete pods -l 'app in (installer, pruner)' -n openshift-kube-apiserver
${OC} delete pods -l 'app in (installer, pruner)' -n openshift-kube-scheduler
${OC} delete pods -l 'app in (installer, pruner)' -n openshift-kube-controller-manager

# Disable the deployment/replicaset for openshift-machine-api and openshift-machine-config-operator
${OC} scale --replicas=0 deployment --all -n openshift-machine-api
${OC} scale --replicas=0 deployment --all -n openshift-machine-config-operator

# Set replica to 0 for openshift-insights
${OC} scale --replicas=0 deployment --all -n openshift-insights

# Scale route deployment from 2 to 1
${OC} patch --patch='{"spec": {"replicas": 1}}' --type=merge ingresscontroller/default -n openshift-ingress-operator

# Scale console deployment from 2 to 1
${OC} scale --replicas=1 deployment.apps/console -n openshift-console

# Scale console download deployment from 2 to 0
${OC} scale --replicas=0 deployment.apps/downloads -n openshift-console

# Set default route for registry CRD from false to true.
${OC} patch config.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

# Set replica for cloud-credential-operator from 1 to 0
${OC} scale --replicas=0 deployment --all -n openshift-cloud-credential-operator

# Use ephemeral storage for internal registry
${OC} patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
${OC} patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'

# Delete the v1beta1.metrics.k8s.io apiservice since we are already scale down cluster wide monitioring.
# Since this CRD block namespace deletion forever.
${OC} delete apiservice v1beta1.metrics.k8s.io
