variable "workspace" {
  type = object({
    name    = string
    project = string
    region  = string
  })
  description = "The workspace that will be used on GCP to build the image. Requires the **name** of the build (e.g \"bounce\"), the ID of a GCP **project** and the **region** of deployment on GCP. The **name** attributes must contain only lowercase letters."

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
  description = "The machine that will be used to create the packer image. Requires a **source_image_family** in GCP format and a **rsa_keystore** with both **private** and **public** keys base64 encoded."
  sensitive   = true
}

variable "skip_create_image" {
  type        = bool
  default     = true
  description = "If true, packer does not create an image from the built disk."
}