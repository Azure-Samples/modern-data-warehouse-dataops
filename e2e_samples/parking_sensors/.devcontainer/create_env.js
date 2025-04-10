const fs = require("fs");

if (!fs.existsSync(".devcontainer/.env")) {
  fs.copyFileSync(".devcontainer/.envtemplate", ".devcontainer/.env");
}
