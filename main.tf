################@
# SDLF-Principal

#################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "knowledge" {
  source       = "./modules/knowledge"
  common_tags  = var.common_tags
  environment  = var.environment
  region_name  = data.aws_region.current.name
}

