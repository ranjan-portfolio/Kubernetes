helm uninstall canary

kubectl delete -n argo-rollout -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

cd aks-terraform

terraform destroy --auto-approve