#!/bin/sh

echo "Uninstalling all components created..."

az login

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

helm uninstall canary

echo "✅ Uninstalled application deployment ..."

echo "Removing CRDs...."

kubectl delete -n argo-rollout -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

echo "✅ CRDs removed .."

echo "Destroying kubernetes cluster"

cd ../aks-terraform

terraform destroy --auto-approve

echo "✅ Cluster destroyed..."

echo "Cleaning backend data..."

az group delete --name "TerraformStateRG" --yes --no-wait

echo "✅  Uninstall completed ...."