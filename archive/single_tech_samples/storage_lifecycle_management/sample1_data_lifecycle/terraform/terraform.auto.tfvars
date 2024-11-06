resource_group_name       = "rg-storage-datalifecycle"
location                  = "CentralIndia"
is_hns_enabled            = true
last_access_time_enabled  = true
blob_storage_cors_origins = ["https://*.contoso.com"]
bypass                    = ["AzureServices"]
env                       = "dev"
storage_account_container_config = {
  "storage1"  = {
    "container11"   = { }
    "container11"   = { "delete" : "10" }
  }
  "storage2"  = {
    "container21"   = { "cool" : "7", "archive" : "9", "delete" : "15" }
    "container22"   = { "delete" : "7", "archive" : "9", }
  }
  "storage3"  = {
    "container31"   = { "cool" : "30" }
    "container32"   = { }
  }
}

