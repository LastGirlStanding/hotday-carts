# creates account for gitlab
export CI_PROJECT_ID=$1
export GL_API_TOKEN=$2

kubectl apply -f ../manifests/gitlab-service-account.yaml

#kubectl get secret $(kubectl get secrets|grep default|awk '{print $1}') -o jsonpath="{['data']['ca\.crt']}" | base64 --decode
kubectl get secret -o jsonpath="{.items[?(@.type==\"kubernetes.io/service-account-token\")].data['ca\.crt']}" | base64 --decode > cert.pem
K8NAME=$(kubectl config current-context)


K8STOKEN=$(kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')|grep "token:"|awk '{print $2}')
#echo $K8STOKEN

K8SAPI=$(cat aws.kubeconfig|grep "server:"|awk '{print $2}')
echo $K8SAPI
curl --header "Private-Token: ${GL_API_TOKEN}" https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/clusters/user \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data '{"name":"${K8NAME}", "platform_kubernetes_attributes":{"api_url":"${K8SAPI}","token":"${K8STOKEN}","namespace":"","ca_cert":"$(sed :a;N;$!ba;s/\n/\\r\\n/g cert.pem)"}}'
