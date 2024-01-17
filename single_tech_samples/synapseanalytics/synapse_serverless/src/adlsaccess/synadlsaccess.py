import json
from collections import defaultdict
from datetime import datetime
from azure.storage.filedatalake import DataLakeServiceClient


## Read data from ADLS and update ACLS
class ADLSOps:
    def __init__(self, storage_acct, keyvault_ls_name, storage_key_name):
        self.storage_acct = storage_acct
        self.keyvault_ls_name = keyvault_ls_name
        self.storage_key_name = storage_key_name
        self.permissions_map = {
            0: "---",
            1: "--x",
            2: "-w-",
            3: "-wx",
            4: "r--",
            5: "r-x",
            6: "rw-",
            7: "rwx",
        }
        self.data_container = "datalake"
        self.config_container = "config"
        self.config_file_name = "datalake_config.json"
        self.config_file_path = "/"
        self.data_path_prefix = ""
        self.config_check_errors = []
        self.ad_set = set()

    def get_current_ts(self):
        return datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    # https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-directory-file-acl-python
    def initialize_storage_account(self, storage_account_key):

        global service_client

        try:
            service_client = DataLakeServiceClient(
                account_url=f"https://{self.storage_acct}.dfs.core.windows.net",
                credential=storage_account_key,
            )
        except Exception as e:
            print(
                f"Unable to connect to ADLS account {self.storage_acct}. Error is {e}"
            )
            raise

        # return service_client

    def _get_directory_client(self, file_sys, directory):

        file_system_client = service_client.get_file_system_client(file_system=file_sys)
        directory_client = file_system_client.get_directory_client(directory)

        return directory_client

    def read_config_from_adls(self):
        try:
            cfg_dir_client = self._get_directory_client(
                self.config_container, self.config_file_path
            )

            file_client = cfg_dir_client.get_file_client(self.config_file_name)

            download = file_client.download_file()

        except Exception as e:
            print(
                f"Unable to download {self.config_container}/{self.config_file_path}/{self.config_file_name}. Error is {e}"
            )
            raise
        else:
            configuration = json.loads(download.readall())
            return configuration

    # https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-acl-python
    def update_permission_recursively(
        self, directory_path, is_default_scope, user_type, user_id, permissions
    ):

        try:
            data_dir_client = self._get_directory_client(
                self.data_container, directory_path
            )

            acl = f"{user_type}:{user_id}:{permissions}"

            if is_default_scope:
                acl = f"default:{user_type}:{user_id}:{permissions}"

            data_dir_client.update_access_control_recursive(acl=acl)

            acl_props = data_dir_client.get_access_control()

            print(
                f"Permissions for {directory_path} - {user_type}:{user_id} are:\n{acl_props['acl']}"
            )

        except Exception as e:
            print(e)

    # Assumption: Config contains all the perms needed for a given location. Incremental changes are not allowed.
    # Evaluate effective permissions requested.
    def evaluate_ad_acl_perms(self, config, current_ts):
        ad_perms = defaultdict(int)
        for p_info in config["datalakeProperties"]:
            p_info["lastUpdatedDatalake"] = current_ts
            partition = f"{p_info['year']}/{p_info['month']}"
            partition_path = f"{self.data_path_prefix}{partition}/"

            for perm in p_info["aclPermissions"]:
                for grp in perm["groups"]:
                    self.ad_set.add(grp)
                    a_type = perm["type"]
                    if a_type == "read":
                        ad_perms[(partition_path, grp)] += 4
                    elif a_type == "write":
                        ad_perms[(partition_path, grp)] += 2
                    elif a_type == "execute":
                        ad_perms[(partition_path, grp)] += 1
                    else:
                        self.config_check_errors.append(
                            f"Invalid acl type value :'{a_type}' specified for partition '{partition}' . Acl Type must be one among ['read', 'write', 'execute']"
                        )
        return ad_perms

    # Assumption: ACL Grant statements are run after data copy step is complete.
    # Otherwise we will run into `The specified path does not exist` errors.
    # We are granting "r-x" on all folders (recursively from root) so that anyone can "read and list the *Folders*" .
    # We follow this statement with another recursive update this time including the "datafiles" path
    # which will overwrite any extra permissions granted in the previous step.
    # Otherwise, unless we create the parent folders separately and grant default permissions,
    # we will not have access to parent folders to avoid access denied errors.
    def update_parent_folder_acls(self, ad_perms, ad_map):
        parent_dirs = set()
        for path, ad in ad_perms:
            parent_dirs.add((path.lstrip("/").split("/", 1)[0], ad))

        for parentdir, ad in parent_dirs:
            if ad in ad_map:
                self.update_permission_recursively(
                    parentdir, 0, "group", ad_map[ad], "r-x"
                )
            else:
                self.config_check_errors.append(
                    f"{ad} is not a valid ActiveDirectory Group."
                )

    def update_ad_acls(self, ad_perms, ad_map):
        for k, v in ad_perms.items():
            (part_path, ad_name) = k
            if ad_name in ad_map:
               self.update_permission_recursively(
                    part_path,
                    0,
                    "group",
                    ad_map[ad_name],
                    self.permissions_map[ad_perms[k]],
                )
            else:
                self.config_check_errors.append(
                    f"{ad_name} is not a valid ActiveDirectory Group."
                )

    def update_datalake_config_with_retention(self, config, retention_year, current_month):
        configDeleteFinal={}
        configDeleteFinal["datalakeProperties"] = '{"datalakeProperties":[]}'
        configDelete=[]

        for p_info in config["datalakeProperties"]:
            if (int(retention_year) > int(p_info["year"])) and (int(current_month) < int(p_info["month"])):
                # if the conditions met, this items are out of the new array
                print("Skip entry")
            else:
                configDelete.append(p_info)
        configDeleteFinal["datalakeProperties"]=configDelete    
        return configDeleteFinal

    def check_config_errors(self):
        if len(self.config_check_errors) > 0:
            raise ValueError(
                f"Config file check failed. Errors are: {self.config_check_errors}"
            )
        print("ACL Statements generation and Active Directory Check Complete.")
