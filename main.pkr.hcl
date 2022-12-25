packer {
  required_version = ">= 1.8.0"
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

locals {
  formatted_version = replace(var.version.number, ".", "-")
  unique_version    = join("-", [local.formatted_version, substr(var.version.commit, 0, 10)])
}

source "googlecompute" "custom" {
  project_id                      = var.workspace.project
  source_image_family             = var.machine.source_image_family
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "packer-bot"
  zone                            = "${var.workspace.region}-b"
  skip_create_image               = var.skip_create_image

  machine_type = "e2-micro"
  network      = "${var.workspace.name}-network"
  subnetwork   = "${var.workspace.name}-subnet"
  tags         = [var.workspace.name]

  disk_size = 10
  disk_type = "pd-standard"
}

build {
  name    = join("-", [var.workspace.name, "build", var.machine.source_image_family])

  source "googlecompute.custom" {
    image_name        = join("-", [var.workspace.name, local.unique_version, var.machine.source_image_family])
    image_description = "SSH customized image for bounce usage, based on ${var.machine.source_image_family}"
    image_family      = join("-", [var.workspace.name, var.machine.source_image_family])
    image_labels = {
      version      = local.formatted_version
      version_type = var.version.type
      commit       = var.version.commit
    }
  }

  provisioner "shell" {
    environment_vars = [
      "RSA_PUB=${var.machine.rsa_keystore.public}",
      "RSA_KEY=${var.machine.rsa_keystore.private}"
    ]
    # Will execute the script as root
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    valid_exit_codes = [0]
    script           = "./script.sh"
  }

  post-processors {
    post-processor "manifest" {
      output = "manifest.json"
      custom_data = {
        family  = join("-", [var.workspace.name, var.machine.source_image_family])
        version = local.formatted_version
        commit  = var.version.commit
      }
    }
  }
}
