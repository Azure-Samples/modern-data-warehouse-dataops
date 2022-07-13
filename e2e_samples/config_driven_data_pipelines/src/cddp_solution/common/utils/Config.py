import json
import logging
from pathlib import Path
from json import JSONDecodeError
from cddp_solution.common.utils.CddpException import CddpException
from cddp_solution.common.utils.Logger import Logger


class Config():
    REQUIRED_CONFIG_KEYS = ["customer_id",
                            "application_name",
                            "bad_data_storage_name",
                            "checkpoint_name",
                            "staging_data_storage_path",
                            "master_data_storage_path",
                            "serving_data_storage_path",
                            "event_data_storage_path",
                            "master_data_source",
                            "master_data_transform",
                            "event_data_source"
                            ]
    KEYS_WITH_JSONARRAY_VALUE = ["master_data_source",
                                 "master_data_transform",
                                 "event_data_source",
                                 "event_data_transform",
                                 "event_data_curation"
                                 ]
    __json_config_file_path = ""
    __source_system = ""
    __customer_id = ""
    __resources_base_path = ""
    __logger = None

    def __init__(self, source_system, customer_id, base_path=None):
        """
        Set default local json config file path with
           input source_system and customer_id

        Parameters
        ----------
        source_system : str
            source system

        customer_id : str
            customer id

        base_path : str
            base path, by default None

        """
        if not base_path:   # Set default base path if it's not set explicitly
            base_path = Path(__file__).parent.parent.parent.parent
        self.__resources_base_path = base_path

        if "." in source_system:
            modules = source_system.split(".")
            self.__source_system = modules[len(modules) - 1]
        else:
            self.__source_system = source_system

        self.__json_config_file_path = Path(base_path,
                                            f"{self.__source_system}_customers",
                                            f"{customer_id}/config.json")

        self.__customer_id = customer_id
        self.__logger = Logger(source_system, customer_id)

    def save_config_to_json_file(self):
        """
        Fetch metadata configs from DB by source_system and customer id,
           then save them to local json file

        """
        source_system = self.__source_system
        customer_id = self.__customer_id
        self.__logger.log(logging.INFO,
                          (f"Saved metadata configs for {source_system} and "
                           f"{customer_id} to local json file properly."))
        pass

    def load_config(self):
        """
        Loads configurations from local json file

        Returns
        ----------
        dict
            configuration

        Raises
        ----------
        CddpException
            when config json is not fount
        CddpException
            when config content not in correct json format
        """
        try:
            with open(self.__json_config_file_path, 'r') as f:
                config = json.load(f)

            self.__logger.log(logging.INFO, f"Customer config file loaded from {self.__json_config_file_path}")

            config["domain"] = self.__source_system
            config["resources_base_path"] = self.__resources_base_path

            # Define Schema Name here
            config["master_data_rz_database_name"] = f'{self.__customer_id}_rz_{config["application_name"]}'
            config["master_data_pz_database_name"] = f'{self.__customer_id}_pz_{config["application_name"]}'
            config["master_data_cz_database_name"] = f'{self.__customer_id}_cz_{config["application_name"]}'

            # Config validation check
            self.__validate_config(config)
        except FileNotFoundError:
            error_message = (f"Config json file for {self.__source_system} and "
                             f"{self.__customer_id} is not found.")
            self.__logger.log(logging.ERROR, error_message)
            raise CddpException(f"[CddpException|Config] {error_message}")
        except JSONDecodeError:
            error_message = (f"Config json file for {self.__source_system} and "
                             f"{self.__customer_id} is not in valid JSON format.")
            self.__logger.log(logging.ERROR, error_message)
            raise CddpException(f"[CddpException|Config] {error_message}")

        self.__logger.log(logging.INFO, (f"Load metadata configs for "
                                         f"{self.__source_system} and {self.__customer_id} "
                                         "properly."))
        return config

    def __validate_config(self, config):
        """
        Validates configuration

        Parameters
        ----------
        config : dict
            target config


        Raises
        ----------
        CddpException
            when required key is missing
        CddpException
            when certain key does not have array value
        CddpException
            when certain key has no value in the array
        """
        # Check required keys
        for required_key in self.REQUIRED_CONFIG_KEYS:
            if required_key not in config:
                error_message = (f"Required config key {required_key} for {self.__source_system} "
                                 f"and {self.__customer_id} is missing.")
                self.__logger.log(logging.ERROR, error_message)
                raise CddpException(f"[CddpException|Config] {error_message}")

        # Check value type
        for key_with_jsonarray_value in self.KEYS_WITH_JSONARRAY_VALUE:
            if key_with_jsonarray_value not in config:
                continue

            value = config[key_with_jsonarray_value]
            if not isinstance(value, list):
                error_message = (f"Config key {key_with_jsonarray_value} for {self.__source_system} "
                                 f"and {self.__customer_id} should have array value.")
                self.__logger.log(logging.ERROR, error_message)
                raise CddpException(f"[CddpException|Config] {error_message}")

            if len(value) == 0:
                error_message = (f"Config key {key_with_jsonarray_value} for {self.__source_system} "
                                 f"and {self.__customer_id} has no value in array.")
                self.__logger.log(logging.ERROR, error_message)
                raise CddpException(f"[CddpException|Config] {error_message}")
