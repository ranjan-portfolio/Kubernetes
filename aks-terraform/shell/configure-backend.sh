TF_STATE_RG="TerraformStateRG"
TF_STATE_SA="uniquestatesaname12345" 
TF_STATE_CONTAINER="tfstate"
LOCATION="West US 2" # Location has a space

# Create a resource group for the state storage
# Added quotes around $TF_STATE_RG and $LOCATION
az group create -n "$TF_STATE_RG" -l "$LOCATION"

# Create the storage account (must be globally unique)
# Added quotes around all variables
az storage account create -n "$TF_STATE_SA" -g "$TF_STATE_RG" -l "$LOCATION" --sku Standard_LRS

# Create a storage container
# Added quotes around all variables
az storage container create -n "$TF_STATE_CONTAINER" --account-name "$TF_STATE_SA"

echo "Terraform backend setup complete."
