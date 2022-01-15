#----root/main.tf-----




module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidr
  access_ip        = var.access_ip
  security_groups  = local.security_groups
  private_sn_count = 3
  public_sn_count  = 2
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  max_subnets      = 20
  db_subnet_group  = true
}

# Module for RDS
#module "database" {
#  source                 = "./database"
# db_engine_version      = "5.7.22"
#  db_instance_class      = "db.t2.micro"
#  dbname                 = var.dbname
#  dbuser                 = var.dbuser
#  dbpassword             = var.dbpassword
#  db_identifier          = "hiba-db"
#  skip_db_snapshot       = true
#  db_subnet_group_name   = module.networking.db_subnet_group_name[0]
#  vpc_security_group_ids = [module.networking.db_security_group]
#}

#---------- loadbalancing----------------------
module "loadbalancing" {
  source                  = "./loadbalancing"
  public_sg               = module.networking.public_sg
  public_subnets          = module.networking.public_subnets
  tg_port                 = 80
  tg_protocol             = "HTTP"
  vpc_id                  = module.networking.vpc_id
  elb_healthy_threshold   = 2
  elb_unhealthy_threshold = 2
  elb_timeout             = 3
  elb_interval            = 30
  listener_port           = 80
  listener_protocol       = "HTTP"
}

module "compute" {
  source          = "./compute"
  public_sg       = module.networking.public_sg
  public_subnets  = module.networking.public_subnets
  instance_count  = 1
  instance_type   = "t3.micro"
  vol_size        = "20"
  #public_key_path = "/home/ubuntu/.ssh/sshkey.pub"
  #key_name        = "sshkey"
}

#1 -this will create a S3 bucket in AWS
resource "aws_s3_bucket" "terraform_state_s3" {
  #make sure you give unique bucket name
  bucket = "terraform-hiba-state-v.1"
  # Enable versioning to see full revision history of our state files
  versioning {
    enabled = true
  }

  lifecycle {

    # Any Terraform plan that includes a destroy of this resource will
    # result in an error message.
    #
    prevent_destroy = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# 2 - this Creates Dynamo Table
resource "aws_dynamodb_table" "terraform_locks" {
  # Give unique name for dynamo table name
  name         = "tf-hiba-state-locks-v.1"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  # configs...
  lifecycle {
    prevent_destroy = true
  }
}

