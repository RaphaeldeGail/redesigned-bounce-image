packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "rsa_key" {
  type      = string
  sensitive = true
}

variable "rsa_pub" {
  type      = string
  sensitive = true
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

variable "skip_create_image" {
  type    = bool
  default = true
}

source "googlecompute" "custom" {
  project_id                      = var.project
  source_image_family             = "debian-11"
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "packer-bot"
  zone                            = "${var.region}-b"
  skip_create_image               = var.skip_create_image

  image_name        = "bounce-v{{timestamp}}-debian-11"
  image_description = "Debian 11 based VM with custom SSH settings for bounce."
  image_family      = "bounce-debian-11"

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