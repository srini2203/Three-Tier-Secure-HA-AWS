
# AMI — latest Amazon Linux 2023


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# IAM — instance role
#
# No access keys anywhere: the EC2 instance assumes this role via
# its instance profile and gets temporary credentials only.
# SecretsManagerReadWrite is an AWS-managed policy, used here for
# readability at this project's scope — scoping it down to the one
# secret ARN is a documented "v2" tightening, see
# docs/design-decisions.md.


resource "aws_iam_role" "app" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-app-role"
  }
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM only, no SSH — enables Session Manager access with no open
# port 22 anywhere in the design. See docs/security.md.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app.name
}

# Launch Template


resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # IMDSv2 enforced — blocks the SSRF-to-credential-theft path IMDSv1
  # allows. See docs/security.md.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -eux

  dnf update -y
  dnf install -y docker jq awscli
  systemctl enable --now docker
  

  # Login to ECR
  aws ecr get-login-password --region ${var.aws_region} | \
    docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}

  # Pull application image
  docker pull ${aws_ecr_repository.app.repository_url}:v1

  # Retrieve database credentials from Secrets Manager
  SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id ${aws_secretsmanager_secret.db_credentials.arn} \
    --query SecretString \
    --output text \
    --region ${var.aws_region})

  DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')
  DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
  DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')
  DB_NAME=$(echo "$SECRET_JSON" | jq -r '.dbname')

  # Run application container
  docker run -d \
    --name task-tracker-api \
    --restart unless-stopped \
    -p 8080:8080 \
    -e DB_HOST="$DB_HOST" \
    -e DB_USER="$DB_USER" \
    -e DB_PASSWORD="$DB_PASSWORD" \
    -e DB_NAME="$DB_NAME" \
    ${aws_ecr_repository.app.repository_url}:v1
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_secretsmanager_secret_version.db_credentials
  ]
}

# Application Load Balancer


resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# HTTP only in this repo — no ACM cert / Route 53 zone is provisioned
# here (out of scope for this project, see README Future Improvements
# for the HTTPS/WAF path).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Auto Scaling Group


resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = aws_subnet.private_app[*].id

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}