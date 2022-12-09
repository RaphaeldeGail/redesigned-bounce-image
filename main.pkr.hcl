packer {
  required_version = ">= 1.8.0"
  required_plugins {
    googlecompute = {
      version = "~> 1.0.10"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

local "unique_version" {
  expression = var.version.type == "release" ? replace(var.version.number, ".", "-") : "${replace(var.version.number, ".", "-")}-{{ timestamp }}"
}

source "googlecompute" "custom" {
  project_id                      = var.workspace.project
  source_image_family             = var.machine.source_image_family
  disable_default_service_account = true
  communicator                    = "ssh"
  ssh_username                    = "packer-bot"
  zone                            = "${var.workspace.region}-b"
  skip_create_image               = var.skip_create_image

  image_name        = join("-", [var.workspace.name, local.unique_version, var.machine.source_image_family])
  image_description = "SSH customized image for bounce usage, based on ${var.machine.source_image_family}"
  image_family      = join("-", [var.workspace.name, var.machine.source_image_family])
  image_labels = {
    version      = replace(var.version.number, ".", "-")
    version_type = var.version.type
    commit       = var.version.commit
  }


  machine_type = "e2-micro"
  network      = "${var.workspace.name}-network"
  subnetwork   = "${var.workspace.name}-subnet"
  tags         = [var.workspace.name]

  disk_size = 10
  disk_type = "pd-standard"
}

build {
  name    = join("-", [var.workspace.name, "build", var.machine.source_image_family])
  sources = ["sources.googlecompute.custom"]

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
    }
  }
}
