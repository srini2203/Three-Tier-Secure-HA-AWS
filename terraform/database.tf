#############################################
# Database — RDS MySQL, Multi-AZ, credentials in Secrets Manager
#############################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Master password is generated, never a plaintext Terraform variable.
resource "random_password" "db_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true # AWS-managed KMS key

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  multi_az = var.multi_az

  backup_retention_period = 7
  skip_final_snapshot     = true # portfolio project — no data worth preserving
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-db"
  }
}

#############################################
# Secrets Manager — the app reads DB credentials from here at
# startup (via the IAM role in compute.tf), never from user-data or
# a Terraform variable.
#############################################

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/${var.environment}/db-credentials"
  description = "RDS master credentials for ${var.project_name}"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_master.result
    host     = aws_db_instance.this.address
    port     = var.db_port
    dbname   = var.db_name
  })
}