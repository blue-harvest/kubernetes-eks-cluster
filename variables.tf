variable "region" {
  default = "eu-west-1"
}

variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "environment" {
  default = "dev"
}

variable "cluster_name" {
  default = "develop"
}

variable "instance_type" {
  default = "t2.large"
}

variable "asg_min_size" {
  default = "5"
}

variable "asg_max_size" {
  default = "24"
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type        = "list"

  default = [
    {
      user_arn = "arn:aws:iam::121854299932:user/armando-ramirez"
      username = "armando-ramirez"
      group    = "system:masters"
    },
    {
      user_arn = "arn:aws:iam::121854299932:user/sherief-shahin"
      username = "sherief-shahin"
      group    = "system:masters"
    },
    {
      user_arn = "arn:aws:iam::121854299932:user/stefan.ghiata"
      username = "stefan.ghiata"
      group    = "system:masters"
    },
  ]
}

variable "map_users_count" {
  description = "The count of roles in the map_users list."
  type        = "string"
  default     = 3
}
