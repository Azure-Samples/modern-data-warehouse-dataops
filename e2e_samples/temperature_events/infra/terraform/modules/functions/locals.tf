locals {
  function_app_name    = "func-${var.function_name}-${var.name}-${var.environment}"
  storage_account_name = lower("st${substr("${var.function_name}${var.name}", 0, 22 - length(var.environment))}${var.environment}")
}
