module "lab" {
  source      = "./modules/lab"
  region      = var.region
  environment = var.environment
  proj    = var.proj
  my_ami_id = var.my_ami_id
}