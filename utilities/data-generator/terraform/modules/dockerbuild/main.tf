# Create docker image
resource "null_resource" "docker_image" {
  triggers = {
    image_name              = var.image
    image_tag               = var.image_tag
    registry_uri            = data.azurerm_container_registry.acr.login_server
    dockerfile_path         = "${path.cwd}/../../application/Dockerfile"
    dockerfile_context      = "${path.cwd}/../../application"
    registry_admin_username = data.azurerm_container_registry.acr.admin_username
    registry_admin_password = data.azurerm_container_registry.acr.admin_password
    dir_sha1                = sha1(join("", [for f in fileset(path.cwd, "../../application/*") : filesha1(f)]))
  }
  provisioner "local-exec" {
    command     = "../modules/dockerbuild/scripts/docker_build_and_push_to_acr.sh ${self.triggers.image_name} ${self.triggers.image_tag} ${self.triggers.registry_uri} ${self.triggers.dockerfile_path} ${self.triggers.dockerfile_context} ${self.triggers.registry_admin_username} ${self.triggers.registry_admin_password}"
    interpreter = ["bash", "-c"]
  }
}
