

module "random" {
  source = "./modules/random"
  length = 2
}

module "resource_group" {
  source = "./modules/rg"
  name   = module.random.random_id
}

module "eks" {
  source    = "./modules/eks"
  location  = module.resource_group.location
  name      = module.resource_group.resource_group_name
  random_id = module.random.random_id
}

