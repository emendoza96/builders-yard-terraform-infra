variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_config_path" {
  type    = string
  default = "$HOME/.aws/config"
}

variable "aws_credentials_path" {
  type    = string
  default = "$HOME/.aws/credentials"
}

variable "key_name" {
  type    = string
  default = "testkey"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_ami" {
  type    = string
  default = "ami-080e1f13689e07408"
}