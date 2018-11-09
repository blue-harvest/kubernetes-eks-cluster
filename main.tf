provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "blueharvest-terraform-state-storage-s3"
    region  = "eu-west-1"
    key     = "blueharvest/terraform/eks/dev"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20180306"]
  }
}

resource "aws_key_pair" "blueharvest-terraform-eks" {
  key_name   = "${var.cluster_name}"
  public_key = "${file("./ssh/blueharvest_terraform_bastion.pub")}"
}
