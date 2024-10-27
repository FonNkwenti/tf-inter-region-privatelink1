terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        # version = "5.14.0"
    }
  }
}

provider "aws" {
  alias                    = "service_consumer_main"
  region                   = "eu-west-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "aai-admin"
  default_tags {
    tags = {
      use_case = "tutorial"
    }
  }
}

provider "aws" {
  alias                    = "service_consumer_transit"
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "aai-admin"
  default_tags {
    tags = {
      use_case = "tutorial"
    }
  }
}