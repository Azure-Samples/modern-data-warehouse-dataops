 #!/usr/bin/env pwsh

sudo npm install -g markdownlint-cli
sudo pip install yamllint
sudo pip install databricks-cli
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
az extension add --name datafactory
az extension add --name storage-preview
