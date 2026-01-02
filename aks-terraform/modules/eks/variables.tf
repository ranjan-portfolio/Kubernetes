
variable "location"{
    description="location where AKS cluster is created"
    type= string
    default="West US 2"
}

variable "name"{
    description="Name of the AKS cluster"
    type=string
    default="test"

}

variable "random_id"{
    description="Random id generated for AKS"
    type= string
}