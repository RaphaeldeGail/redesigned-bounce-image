packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "rsa_key" {
  type = string
}

variable "rsa_pub" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

source "googlecompute" "custom" {
  project_id                      = var.project
  source_image                    = "ubuntu-2004-focal-v20220118"
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "packer-bot"
  zone                            = "${var.region}-b"
  //skip_create_image               = true

  image_name        = "bounce-v{{timestamp}}-ubuntu-20"
  image_description = "Ubuntu 20.04 based VM with custom SSH settings for bounce."
  image_family      = "bounce-ubuntu-20"

  machine_type = "e2-micro"
  network      = "${var.name}-network"
  subnetwork   = "${var.name}-subnet"
  tags         = [var.name]

  disk_size = 10
  disk_type = "pd-standard"
}

build {
  sources = ["sources.googlecompute.custom"]

  provisioner "shell" {
    environment_vars = [
      "RSA_PUB=${var.rsa_pub}",
      "RSA_KEY=${var.rsa_key}"
    ]
    script = "./bounce-script.sh"
  }
}