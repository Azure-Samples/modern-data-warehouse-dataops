output "capacity_id" {
  value = (
    length(azapi_resource.fab_capacity) > 0 ? azapi_resource.fab_capacity.id : ""
  )
  description = "Resource identifier of the instance of Microsoft Fabric capacity"
}

output "capacity_name" {
  value = (
    length(azapi_resource.fab_capacity) > 0 ? azapi_resource.fab_capacity.name : ""
  )
  description = "Microsoft Fabric capacity name"
}