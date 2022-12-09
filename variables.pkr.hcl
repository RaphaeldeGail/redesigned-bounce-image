variable "workspace" {
  type = object({
    name    = string
    project = string
    region  = string
  })
  description = "The workspace that will be used on GCP to build the image. Requires the **name** of the build (e.g \"bounce\"), the ID of a GCP **project** and the **region** of deployment on GCP. The **name** attributes must contain only lowercase letters. The **project** attribute can not be empty."

  validation {
    condition     = var.workspace.project != ""
    error_message = "The project can not be empty."
  }
  validation {
    condition     = can(regex("^[a-z]*$", var.workspace.name))
    error_message = "The name of the build should be a valid name with only lowercase letters allowed."
  }
}

variable "machine" {
  type = object({
    source_image_family = string
    rsa_keystore = object({
      private = string
      public  = string
    })
  })
  description = "The machine that will be used to create the packer image. Requires a **source_image_family** in GCP format and a **rsa_keystore** with both **private** and **public** keys base64 encoded. The **source_image_family** attribute can not be empty."
  sensitive   = true

  validation {
    condition     = var.machine.source_image_family != ""
    error_message = "The source_image_family can not be empty."
  }
}

variable "version" {
  type = object({
    number = string
    type   = string
    commit = string
  })
  description = "The version number and type, *develop* or *release*, for the image. The sha256 of the underlying commit complements the version."

  validation {
    condition     = var.version.type == "develop" || var.version.type == "release"
    error_message = "The version type can either be develop or release, got: ${var.version.type} ."
  }
}

variable "skip_create_image" {
  type        = bool
  default     = true
  description = "If true, packer does not create an image from the built disk."
}