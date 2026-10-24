variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "name" {
  description = "Name prefix for all resources (lowercase letters and numbers only for ACR compatibility)"
  type        = string
  default     = "devopsdemo"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Leave null to use the region default."
  type        = string
  default     = null
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 4
}

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}
