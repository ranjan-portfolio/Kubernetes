TF_STATE_RG="TerraformStateRG"
TF_STATE_SA="uniquestatesaname12345" 
TF_STATE_CONTAINER="tfstate"
LOCATION="West US 2"

# Create a resource group for the state storage

az group create -n "$TF_STATE_RG" -l "$LOCATION"

# Create the storage account (must be globally unique)

az storage account create -n "$TF_STATE_SA" -g "$TF_STATE_RG" -l "$LOCATION" --sku Standard_LRS

# Create a storage container

az storage container create -n "$TF_STATE_CONTAINER" --account-name "$TF_STATE_SA"

echo "Terraform backend setup complete."
