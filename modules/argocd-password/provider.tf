terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = ">= 0.1.2"
    }
  }
  required_version = ">= 1.0"
}
