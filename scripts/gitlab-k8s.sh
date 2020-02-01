#!/bin/bash

export CI_PROJECT_ID=$1
export GL_API_TOKEN=$2

# adds gitlab service account
kubectl apply -f ../manifests/gitlab-service-account.yaml

# adds k8s cluster of current kubectl context to gitlab
kubectl get secret -o jsonpath="{.items[?(@.type==\"kubernetes.io/service-account-token\")].data['ca\.crt']}" | base64 --decode > cert.pem
K8NAME=$(kubectl config current-context)
K8SAPI=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
K8STOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')|grep "token:"|awk '{print $2}')
CACERT=$(cat cert.pem | sed ':a;N;$!ba;s/\n/\\r\\n/g')
postdata='{"name":"'${K8NAME}'", "platform_kubernetes_attributes":{"api_url":"'${K8SAPI}'","token":"'${K8STOKEN}'","namespace":"","ca_cert":"'${CACERT}'"}}'
echo ${postdata} > gitlab.json
curl --header "Private-Token: ${GL_API_TOKEN}" https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/clusters/user \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data @gitlab.json

# posts variable to project containing base64 encoded kubeconf for use elsewhere
kube_config_base64=$(cat ~/.kube/config | base64 -w 0)
postdatavariable='{"key": "kube_config","value": "'${kube_config_base64}'","protected": false,"variable_type": "file","masked": true,"environment_scope": "*"}'
echo ${postdatavariable} > kubeconfvariable.json
curl --header "Private-Token: ${GL_API_TOKEN}" https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/variables \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data @kubeconfvariable.json