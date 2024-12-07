module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"
  name    = "shared-vpc"

  cidr             = "10.0.0.0/16"
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
}

resource "aws_db_subnet_group" "shared" {
  name       = "shared-subnet-group"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "shared-subnet-group"
  }
}
