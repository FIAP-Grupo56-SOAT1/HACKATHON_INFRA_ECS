terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.37.0"
    }
  }
  ####### Configuring the S3 to Remote State #######
  backend "s3" {
    bucket = "bucket-fiap56-to-remote-state"
    key    = "aws-ecs-hackathon-timesheet/terraform.tfstate"
    region = "us-east-1"
  }
}

######## Configuring the AWS Provider ########
provider "aws" {
  region = "us-east-1" #The region where the environment
}

# Criando um modulo que utiliza os dados do infra para criação do ambiente
module "prod" {
  source                                          = "../../infra"
  containerDbName                                 = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["dbname"]
  containerDbUser                                 = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["username"]
  containerDbPassword                             = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["password"]
  containerDbRootPassword                         = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["password"]
  containerDbServer                               = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["host"]
  containerDbPort                                 = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["port"]
  portaAplicacao                                  = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["app_port"]
  access_key                                      = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["access_key"]
  secret_key                                      = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["secret_key"]
  session_token                                   = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["session_token"]

}


#obteando dados do secret manager
data "aws_secretsmanager_secret" "secrets_microservico" {
  name = "prod/soat1grupo56/Timesheet"
}

data "aws_secretsmanager_secret_version" "credentials" {
  secret_id = data.aws_secretsmanager_secret.secrets_microservico.id
}


output "IP_alb" {
  value = module.prod.app_url
}
