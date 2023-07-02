#! /bin/sh
# Creates a .kube/config with admin (aka sudo) and user contexts
# File is safer to redistribute than original admin.conf, so long as
# admin-user certificate is not redistributed.
#
#  Parameters
#    $1 name of existing config
#    $2 name of new config
#    $3 existing context
#    $4 kubernetes cluster name

CONFIG=$1
NEW=$2
ADMIN_CTX=$3
CLUSTER=$4

umask 077
cp $CONFIG $NEW
# Move admin cert and key to separate files so $NEW is safe to distribute
grep client-certificate-data: $CONFIG |awk '{print $2}'|base64 -d >/home/$USER/.kube/admin-user.crt
grep client-key-data: $CONFIG |awk '{print $2}'|base64 -d >/home/$USER/.kube/admin-user.key
SECRET=`kubectl get sa $ADMIN_CTX admin-user -n kube-system -o jsonpath={.secrets[0].name}`
kubectl config --kubeconfig=$NEW set-credentials kubernetes-admin --client-certificate=/home/$USER/.kube/admin-user.crt --client-key=/home/$USER/.kube/admin-user.key

# Add a synonym sudo
kubectl config --kubeconfig=$NEW set-context sudo --cluster=$CLUSTER --namespace=kube-system --user=kubernetes-admin

# TODO oidc configuration; this token-based auth is obsolete in 1.25

# Set credentials for user
SECRET=`kubectl get sa $ADMIN_CTX $K8S_NAMESPACE-user -n $K8S_NAMESPACE -o jsonpath={.secrets[0].name}`
kubectl get secret $SECRET -n $K8S_NAMESPACE -o jsonpath='{.data.ca\.crt}' | \
  base64 -d > /home/$USER/.kube/$K8S_NAMESPACE-user.crt
TOKEN=`kubectl get secret $SECRET -n $K8S_NAMESPACE -o jsonpath={.data.token}|base64 -d`
kubectl config --kubeconfig=$NEW set-credentials user --client-key=/home/$USER/.kube/$K8S_NAMESPACE-user.crt --token=$TOKEN
kubectl config --kubeconfig=$NEW set-context user@$CLUSTER --cluster=$CLUSTER --namespace=$K8S_NAMESPACE --user=user
kubectl config --kubeconfig=$NEW use-context user@$CLUSTER
ln -fns $NEW /home/$USER/.kube/config
