#!/bin/sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

echo "${BLUE} Logging into Azure..."

az login
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
echo -e "${GREEN} Azure login completed"

echo -e "${BLUE} Going to check terraform backend availability and create cluster..."
# Change directory first so subsequent paths work relative to aks-terraform
cd ../aks-terraform/

echo -e "${BLUE} Checking if terraform backend is available..."
# Run the check command and use an 'if' block immediately to capture success/failure
if az storage account show --name "uniquestatesaname12345" --resource-group "TerraformStateRG" --query location > /dev/null 2>&1; then
    echo -e "${BLUE} Backend storage account already exists."
else
    echo -e "${RED} Backend storage account not found. Creating now..."
    ./shell/configure-backend.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED} ERROR: configure-backend.sh failed. Exiting."
        exit 1
    fi
fi

# Initialize terraform (required to load backend config)
terraform init

# Use command substitution robustly for the plan filename
PLAN_FILE="./plan/plan_$(date +%Y-%m-%d_%H-%M-%S).tfplan"
mkdir -p ./plan
echo -e "${BLUE} Running terraform plan..."
terraform plan -out "$PLAN_FILE"

echo -e "${BLUE} Running terraform apply..."
terraform apply --auto-approve "$PLAN_FILE"

# Capture cluster details using the -raw flag for clean strings
cluster_name=$(terraform output -raw aks_cluster_name)
resource_group_name=$(terraform output -raw aks_resource_group_name)

if [ -z "$cluster_name" ]; then
    echo -e "${RED}❌ Terraform encountered issue while creating cluster or output is empty."
    exit 1
else
    echo -e "${GREEN} ✅  Kubernetes cluster created: Name is $cluster_name"
fi

echo -e "${BLUE} Fetching cluster details and configuring kubectl"
# Use the variables captured above
az aks get-credentials --resource-group "$resource_group_name" --name "$cluster_name" --overwrite-existing --only-show-errors

# Assuming you are running this from a specific project root relative to the original start point
cd ../canary/voting-app

echo -e "${BLUE} Installing Argo rollout CRD..."
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
echo -e "${GREEN} ✅  Argo rollout CRD installation completed"

cd chart
echo -e "${BLUE} Installing canary chart.. this will install vote-app,prometheus and grafana"
helm install canary .

echo -e "${GREEN} ✅ Helm deployment completed"

echo -e "${BLUE} waiting for ingress loadbalancer to be ready"

INGRESS_SVC_NAME=canary-ingress-nginx-controller
INGRESS_NAMESPACE=default

EXTERNAL_IP=''

while [ -z "$EXTERNAL_IP" ]; do
 echo -e "${RED} External IP is pending.. waiting for 10 sec"
 sleep 10
 EXTERNAL_IP=$(kubectl get svc "$INGRESS_SVC_NAME" -n "$INGRESS_NAMESPACE" --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
done

echo -e "${GREEN} ✅ Got External IP:: $EXTERNAL_IP"

curl -H "host:vote.example.com" http://"$EXTERNAL_IP" --silent --output /dev/null

if [ $? -eq 0 ]; then
  echo -e "${GREEN} ✅ Curl command executed successfully at the network level."
else
  echo -e "${RED} ❌ Curl command failed at the network level (e.g., connection refused, DNS error)."
fi

echo -e "${BLUE} Rolling out argo dahsboard..."

kubectl argo rollouts dashboard --namespace default &

sudo sed -i".bak" "/vote.example.com/s/.*/"$EXTERNAL_IP"\tvote.example.com/" "/etc/hosts"

echo -e "${GREEN} Argo rollout dashboard URL: http://localhost:3100/rollouts"

echo -e "${GREEN} Application URL: http://vote.example.com"


echo -e "${GREEN} Bootstrapping complete..."
