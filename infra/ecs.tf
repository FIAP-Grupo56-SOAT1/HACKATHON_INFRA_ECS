########## Creating an ECS Cluster ########
resource "aws_ecs_cluster" "ecs_timesheet" {
  name               = "cluster-${var.micro_servico}"
  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = {
    Name = "cluster-${var.micro_servico}"
  }
}

data "aws_ecr_repository" "repositorio" {
  name = var.nome_repositorio
}

resource "random_string" "lower" {
  length  = 16
  upper   = false
  lower   = true
  special = false
}

######### Configuring AWS ECS Task Definitions ########
resource "aws_ecs_task_definition" "timesheet" {
  family = "task-${var.micro_servico}" # Name your task
  container_definitions = jsonencode(
    [
      {
        name   = "task-${var.micro_servico}"
        image  = data.aws_ecr_repository.repositorio.repository_url
        cpu    = var.cpu_task
        memory = var.memory_task
        environment = [
          { "NAME" : "APP_PORT", "value" : tostring(var.portaAplicacao) },
          { "NAME" : "DB_PORT", "value" : var.containerDbPort },
          { "NAME" : "DB_USER", "value" : var.containerDbUser },
          { "NAME" : "DB_PASSWORD", "value" : var.containerDbPassword },
          { "NAME" : "DB_NAME", "value" : var.containerDbName },
          { "NAME" : "DB_SERVER", "value" : var.containerDbServer },
          { "NAME" : "AWS_ACCESS_KEY", "value" : var.access_key },
          { "NAME" : "AWS_SECRET_KEY", "value" : var.secret_key },
          { "NAME" : "AWS_SESSION_TOKEN", "value" : var.session_token },
          { "NAME" : "AWS_REGION", "value" : var.regiao },
          { "NAME" : "JWT_SECRET", "value" : var.jwt_secret },
          { "NAME" : "TIME_ZONE", "value" : var.time_zone },
          { "NAME" : "SENDER_MAIL", "value" : var.sender_mail },
          { "NAME" : "SENDER_MAIL_PASSWORD", "value" : var.sender_mail_password },
          { "NAME" : "MAIL_HOST", "value" : var.mail_host },
          { "NAME" : "MAIL_PORT", "value" : var.mail_port }
        ]
        essential = true
        portMappings = [
          {
            "containerPort" = var.portaAplicacao
            "hostPort"      = var.portaAplicacao
          }
        ],
        logConfiguration : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : aws_cloudwatch_log_group.timesheet.name,
            "awslogs-region" : var.regiao,
            "awslogs-stream-prefix" : "ecs-timesheet-api-${var.micro_servico}"
          }
        }
      }
    ])
  requires_compatibilities = ["FARGATE"]                              # use Fargate as the launch type
  network_mode             = "awsvpc"                                 # add the AWS VPN network mode as this is required for Fargate
  memory                   = var.memory_container                     # Specify the memory the container requires
  cpu                      = var.cpu_container                        # Specify the CPU the container requires
  execution_role_arn       = var.execution_role_ecs                   #aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name = "microservico-${var.micro_servico}"
    type = "terraform"
  }
}

##### Creating a VPC #####
# Provide a reference to your default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Provide references to your default subnets
resource "aws_default_subnet" "default_subnet_a" {
  # Use your own region here but reference to subnet 1a
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  # Use your own region here but reference to subnet 1b
  availability_zone = "us-east-1b"
}

#resource "aws_default_subnet" "default_subnet_c" {
#  # Use your own region here but reference to subnet 1b
#  availability_zone = "us-east-1c"
#}

resource "aws_lb_target_group" "lb_target_group_timesheet" {
  name        = "lb-target-group-${var.micro_servico}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # default VPC
  health_check {
    path                = "/actuator/health"
    port                = var.portaAplicacao
    healthy_threshold   = 5 # O número de verificações de integridade bem-sucedidas consecutivas necessárias antes de considerar um destino não íntegro como íntegro.
    unhealthy_threshold = 3 # O número de verificações de integridade consecutivas com falha exigido antes considerar um destino como não íntegro.
    timeout             = 5 # O tempo, em segundos, durante o qual a ausência de resposta significa uma falha na verificação de integridade.
    interval            = 60
    matcher             = "200" # has to be HTTP 200 or fails
  }
}


data "aws_alb" "application_load_balancer" {
  name   = "load-balancer-${var.micro_servico}"
}

resource "aws_lb_listener" "listener_timesheet" {

  load_balancer_arn = data.aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_timesheet.arn # target group
  }
}

##### ECS Service #####


resource "aws_ecs_service" "app_service_timesheet" {
  name            = "service-${var.micro_servico}"                        # Name the service
  cluster         = aws_ecs_cluster.ecs_timesheet.id      # Reference the created Cluster
  task_definition = aws_ecs_task_definition.timesheet.arn # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Set up the number of containers to 3
  force_new_deployment = true
  triggers = {
    redeployment = random_string.lower.result
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group_timesheet.arn # Reference the target group
    container_name   = aws_ecs_task_definition.timesheet.family
    container_port   = var.portaAplicacao # Specify the container port
  }

  network_configuration {
    subnets = [
      aws_default_subnet.default_subnet_a.id,
      aws_default_subnet.default_subnet_b.id,
      #aws_default_subnet.default_subnet_c.id
    ]
    assign_public_ip = true                                                  # Provide the containers with public IPs
    security_groups  = [
      data.aws_security_group.service_security_group_timesheet.id,
      data.aws_security_group.service_ecs_security_group_db_timesheet.id
    ] # Set up the security group
  }
}

data "aws_security_group" "service_security_group_timesheet" {
  name = "service-security-group-${var.micro_servico}"
}

data "aws_security_group" "service_ecs_security_group_db_timesheet" {
  name = "security-group-db-${var.micro_servico}"
}


resource "aws_cloudwatch_log_group" "timesheet" {
  name              = "timesheet-api-${var.micro_servico}"
  retention_in_days = 1
  tags = {
    Application = "micro-servico-${var.micro_servico}"
  }
}

# autoscaling

# auto_scaling.tf

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_timesheet.name}/${aws_ecs_service.app_service_timesheet.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.execution_role_ecs
  min_capacity       = 1
  max_capacity       = 4
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  name               = "${var.micro_servico}_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_timesheet.name}/${aws_ecs_service.app_service_timesheet.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  name               = "${var.micro_servico}_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_timesheet.name}/${aws_ecs_service.app_service_timesheet.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.micro_servico}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1" # minutes
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_timesheet.name
    ServiceName = aws_ecs_service.app_service_timesheet.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.micro_servico}_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"     # minutes
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_timesheet.name
    ServiceName = aws_ecs_service.app_service_timesheet.name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]
}

