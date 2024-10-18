output "capacity_id" {
  value = var.create_fabric_capacity ? data.fabric_capacity.created_capacity_id[0].id : data.fabric_capacity.provided_capacity_id[0].id
  description = "Resource identifier of the instance of Microsoft Fabric capacity"
}

output "capacity_name" {
  value = var.create_fabric_capacity ? data.fabric_capacity.provided_capacity_id[0].display_name : data.fabric_capacity.provided_capacity_id[0].display_name
  description = "Microsoft Fabric capacity name"
}