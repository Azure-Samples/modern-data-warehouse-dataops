variable "domain_id" {
  description = "Microsoft Fabric domain ID"
  type        = string
}

variable "workspace_ids" {
  description = "Microsoft Fabric workspace IDs (list)"
  type        = list(string)
}
