variable "micro_servico" {
  description = "Nome do microserviço"
  type    = string
  default = "timesheet"
}

##### variaveis de ambiente repositorio de imagens docker#######
variable "nome_repositorio" {
  description = "Nome do repositório de imagens Docker"
  type    = string
  default = "microservico-timesheet"
}

variable "repositorio_url" {
  description = "URL do repositório de imagens Docker do microserviço"
  type = string
  default = "730335661438.dkr.ecr.us-east-1.amazonaws.com/microservico-timesheet"
}

variable "imagemDocker" {
  type    = string
  default = "730335661438.dkr.ecr.us-east-1.amazonaws.com/microservico-timesheet:latest"
}

##### fim variaveis de ambiente repositorio de imagens docker#######

variable "regiao" {
  type    = string
  default = "us-east-1"
}


variable "portaAplicacao" {
  type    = number
  default = 8080
}

variable "containerDbPort" {
  description = "Porta do banco de dados do microserviço"
  type    = string
  default = "3306"
}

variable "containerDbServer" {
  description = "Endereço do banco de dados do microserviço"
  type    = string
}

variable "containerDbName" {
  description = "Nome do banco de dados do microserviço"
  type    = string
}

variable "containerDbUser" {
  description = "Usuário do banco de dados do microserviço"
  type    = string
}

variable "containerDbPassword" {
  description = "Senha do banco de dados do microserviço"
  type    = string
}

variable "containerDbRootPassword" {
  description = "Senha do user root do banco de dados do microserviço"
  type    = string
}

######### OBS: a execution role acima foi trocada por LabRole devido a restricoes de permissao na conta da AWS Academy ########
variable "execution_role_ecs" {
  type    = string
  default = "arn:aws:iam::730335661438:role/LabRole" #aws_iam_role.ecsTaskExecutionRole.arn
}


########## variaveis de ambiente CPU/MEM para cluster ECS ##########
variable "cpu_task" {
  type    = number
  default = 256
}

variable "memory_task" {
  type    = number
  default = 512
}

variable "cpu_container" {
  type    = number
  default = 256
}

variable "memory_container" {
  type    = number
  default = 512
}
########## fim variaveis de ambiente para o cluster ECS ##########


variable "container_insights" {
  type        = bool
  default     = false
  description = "Set to true to enable container insights on the cluster"
}

variable "access_key" {
  type    = string
}

variable "secret_key" {
  type    = string
}
variable "session_token" {
  type    = string
}
variable "jwt_secret" {
  type    = string
}
variable "time_zone" {
  type    = string
  default = "America/Sao_Paulo"
}

variable "sender_mail" {
  type    = string
}


variable "sender_mail_password" {
  type    = string
}


variable "mail_host" {
  type    = string
}


variable "mail_port" {
  type = string
}



