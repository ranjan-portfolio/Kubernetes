#!/bin/sh

set -x
echo "Logging into Azure..."
az login
echo "Azure login completed"

subscriptionId=$(az account show --query id -o tsv)
export ARM_SUBSCRIPTION_ID=$subscriptionId
echo "Subscription ID set: $ARM_SUBSCRIPTION_ID"

echo "Going to check terraform backend availability and create cluster..."
# Change directory first so subsequent paths work relative to aks-terraform
cd ../aks-terraform/

echo "Checking if terraform backend is available..."
# Run the check command and use an 'if' block immediately to capture success/failure
if az storage account show --name "uniquestatesaname12345" --resource-group "TerraformStateRG" --query location > /dev/null 2>&1; then
    echo "Backend storage account already exists."
else
    echo "Backend storage account not found. Creating now..."
    ./shell/configure-backend.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: configure-backend.sh failed. Exiting."
        exit 1
    fi
fi

# Initialize terraform (required to load backend config)
terraform init

# Use command substitution robustly for the plan filename
PLAN_FILE="./plan/plan_$(date +%Y-%m-%d_%H-%M-%S).tfplan"
mkdir -p ./plan
echo "Running terraform plan..."
terraform plan -out "$PLAN_FILE"

echo "Running terraform apply..."
terraform apply --auto-approve "$PLAN_FILE"

# Capture cluster details using the -raw flag for clean strings
cluster_name=$(terraform output -raw aks_cluster_name)
resource_group_name=$(terraform output -raw aks_resource_group_name)

if [ -z "$cluster_name" ]; then
    echo "❌ Terraform encountered issue while creating cluster or output is empty."
    exit 1
else
    echo "✅  Kubernetes cluster created: Name is $cluster_name"
fi

echo "Fetching cluster details and configuring kubectl"
# Use the variables captured above
az aks get-credentials --resource-group "$resource_group_name" --name "$cluster_name" --overwrite-existing --only-show-errors

# Assuming you are running this from a specific project root relative to the original start point
cd ../canary/voting-app

echo "Installing Argo rollout CRD..."
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
echo "✅  Argo rollout CRD installation completed"

cd chart
echo "Installing canary chart.. this will install vote-app,prometheus and grafana"
helm install canary .

echo "✅ Helm deployment completed"

echo "waiting for ingress loadbalancer to be ready"

INGRESS_SVC_NAME=canary-ingress-nginx-controller
INGRESS_NAMESPACE=default

EXTERNAL_IP=''

while [ -z "$EXTERNAL_IP" ]; do
 echo "External IP is pending.. waiting for 10 sec"
 sleep 10
 EXTERNAL_IP=$(kubectl get svc "$INGRESS_SVC_NAME" -n "$INGRESS_NAMESPACE" --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
done

echo "✅ Got External IP:: $EXTERNAL_IP"

curl -H "host:vote.example.com" http://"$EXTERNAL_IP" --silent --output /dev/null

if [ $? -eq 0 ]; then
  echo "✅ Curl command executed successfully at the network level."
else
  echo "❌ Curl command failed at the network level (e.g., connection refused, DNS error)."
fi


echo "Bootstrapping complete..."
