
# Criando a VPC - dentro do VPN temos as regios e dentro das regios temos as zonas de disponibilidade (AZs)
# e depois temos as sub-redes (subnets), temos as subnets publicas e privadas 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-ecs"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}
