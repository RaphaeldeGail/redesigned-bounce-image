packer {
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "rsa_keystore" {
  type = object({
    private = string
    public  = string
  })
  description = "The RSA keystore is composed of **private** for the private key and **public** for the public key."
  sensitive   = true
}

variable "project" {
  type        = string
  description = "The ID of the GCP **project** to use for the packer build."
}

variable "region" {
  type        = string
  description = "The name of the **region** for the network hosting the packer instance."
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