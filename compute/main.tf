# --------- compute / main.tf -------

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "random_id" "hiba_node_id" {
  byte_length = 2
  count       = var.instance_count
   keepers = {
    key_name = var.key_name
  }
}

# ssh key pair

resource "aws_key_pair" "key_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


resource "aws_instance" "hiba_node" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "hiba_node-${random_id.hiba_node_id[count.index].dec}"
  }

  key_name               = aws_key_pair.key_auth.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  user_data              = templatefile(var.user_data_path,
    {
      nodename    = "${random_id.hiba_node_id[count.index].dec}"
      db_endpoint = var.db_endpoint
      dbuser      = var.dbuser
      dbpass      = var.dbpassword
      dbname      = var.dbname
    }
  )

  root_block_device {
    volume_size = var.vol_size
  }
}

aws ec2 run-instances ^
    --image-id ami-02e136e904f3da870 ^
    --instance-type t2.micro ^
    --subnet-id subnet-003a5fcf377fc9087 ^
    --security-group-ids sg-03a437741e53c16ea ^
    --key-name mykeypair ^
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=my-ec2-created-through-CLI}]"