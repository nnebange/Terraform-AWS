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
}

# ssh key pair




resource "aws_instance" "hiba_node" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "hiba_node-${random_id.hiba_node_id[count.index].dec}"
  }

  #key_name               = aws_key_pair.ssh_key.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  # user_data              = ""

  root_block_device {
    volume_size = var.vol_size
  }
}
