terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version = "5.14.0"
    }
  }
}

provider "aws" {
  alias                    = "service_provider_main"
  region                   = "eu-west-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
  default_tags {
    tags = {
      use_case = "tutorial"
    }
  }
}

provider "aws" {
  alias                    = "service_provider_region"
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
  default_tags {
    tags = {
      use_case = "tutorial"
    }
  }
}