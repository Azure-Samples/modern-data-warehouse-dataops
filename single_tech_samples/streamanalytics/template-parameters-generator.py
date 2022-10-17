import json
import typer

singleindent = " " * 2
doubleindent = " " * 4

# To run this, make sure to pass the following parameters. In order to generate the job template path,
# you will need to run the command 'azure-streamanalytics-cicd build -project "asaproj.json"' fom within the project folder.
# This will generate the template file.
def main(
    subscription_id: str,
    subscription_name: str,
    job_name: str,
    job_location: str,
    job_template_path: str,
    resource_group_name: str,
    triggerbranch: str,
    key_vault_name: str = "",
):
    yamlfile = open("asa_cicd_pipeline_yaml", "w")
    yamlfile.write("trigger:\n")
    yamlfile.write(
        f"- {triggerbranch} \npool:\n{singleindent}name: Azure Pipelines\n{singleindent}demands: npm\nsteps:\n"
    )
    using_key_vault = key_vault_name != ""
    if using_key_vault:
        yamlfile.write(
            f"- task: AzureKeyVault@2\n{singleindent}inputs:\n{doubleindent}azureSubscription: '{subscription_name} ({subscription_id})'\n{doubleindent}KeyVaultName: '{key_vault_name}'\n{doubleindent}SecretsFilter: '*'\n{doubleindent}RunAsPreJob: false\n"
        )
    yamlfile.write(
        f"- task: Npm@1\n{singleindent}displayName: 'Install Azure stream analytics ci cd'\n{singleindent}inputs:\n{doubleindent}command: custom\n{doubleindent}verbose: false\n{doubleindent}customCommand: 'install -g azure-streamanalytics-cicd'"
    )
    yamlfile.close()
    create_all_asa_jobs(
        yamlfile,
        subscription_id,
        using_key_vault,
        subscription_name,
        job_location,
        job_name,
        resource_group_name,
        job_template_path,
    )


def create_all_asa_jobs(
    yamlfile,
    subscription_id,
    using_key_vault,
    subscription_name,
    job_location,
    job_name,
    resource_group_name,
    job_template_path,
):
    yamlfile = open("asa_cicd_pipeline_yaml", "a")
    template_params = open(job_template_path, "r")
    output = template_params.read()
    template_json = json.loads(output)["parameters"]
    new_json = create_asa_job_default_values(job_name)
    create_project_arr = create_asa_job(
        template_json,
        job_location,
        subscription_id,
        job_name,
        using_key_vault,
        resource_group_name,
        subscription_name,
    )
    yamlfile.write(new_json)
    yamlfile.writelines(create_project_arr)

    yamlfile.close()


def create_asa_job_default_values(project_name):
    new_json = "\n"

    new_json += f"\n- script: 'azure-streamanalytics-cicd build -project {project_name}/asaproj.json -outputpath {project_name}/Output/Deploy' \n"
    new_json += "  displayName: 'Build Stream Analytics proj'"

    new_json += "\n"
    new_json += f"- task: AzureResourceManagerTemplateDeployment@3\n{singleindent}inputs:\n{doubleindent}"
    return new_json


def create_asa_job(
    template_json,
    project_location,
    subscription_id,
    project_name,
    usingkeyvault,
    resourcegroup,
    subscription_name,
):
    overrideparams = f'-Location "{project_location}"'
    for key in template_json:
        if template_json[key]["value"] is None:
            if usingkeyvault:
                overrideparams += (
                    f"-{key} $([REQUIRED: Add Secret Name From Keyvault]) "
                )
            else:
                overrideparams += f'-{key} "[REQUIRED: Add Name] "'

    create_project_arr = [
        "deploymentScope: 'Resource Group'\n",
        f"{doubleindent}azureResourceManagerConnection: '{subscription_name} ({subscription_id})'\n",
        f"{doubleindent}subscriptionId: '{subscription_id}'\n",
        f"{doubleindent}action: 'Create Or Update Resource Group'\n",
        f"{doubleindent}resourceGroupName: '{resourcegroup}'\n",
        f"{doubleindent}location: '{project_location}'\n",
        f"{doubleindent}templateLocation: 'Linked artifact'\n",
        f"{doubleindent}csmFile: '{project_name}/Output/Deploy/{project_name}.JobTemplate.json'\n",
        f"{doubleindent}csmParametersFile: '{project_name}/Output/Deploy/{project_name}.JobTemplate.parameters.json'\n",
        f"{doubleindent}overrideParameters: '{overrideparams}'\n",
        f"{doubleindent}deploymentMode: 'Incremental'\n",
    ]
    return create_project_arr


if __name__ == "__main__":
    typer.run(main)
