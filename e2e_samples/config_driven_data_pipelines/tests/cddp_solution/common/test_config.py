import os
import pytest
from pathlib import Path
from cddp_solution.common.utils.Config import Config
from cddp_solution.common.utils.CddpException import CddpException


@pytest.fixture(scope='session', autouse=True)
def initialize_test_config():
    source_system = "test_source_system"
    customer_id = "test_customer"
    base_path = Path(Path(__file__).parent, "resources")
    test_config_path = Path(base_path,
                            f"{source_system}_customers/{customer_id}/config.json")
    metadata_config = Config(source_system,
                             customer_id,
                             base_path)

    config_contents = """
    {   "customer_id": "",
        "application_name": "test_app",
        "bad_data_storage_name": "bad_data",
        "checkpoint_name": "checkpoint",
        "staging_data_storage_path": "Staging",
        "event_data_storage_path": "Standard",
        "serving_data_storage_path": "serving_data_storage",
        "event_data_curation_sql": [
            "SELECT m.ID, m.Fruit, count(m.ID) AS sales_count, SUM(m.Price*m.amount) AS sales_total \
            FROM fruits_events m GROUP BY m.ID, m.Fruit"
        ],
        "event_data_source": [{
            "name":"event-hub",
            "type": "local",
            "format": "json",
            "table_name":"events",
            "location":"customer_3/mock_events/",
            "secret": "eventhubs.connectionString"
        }],
        "event_data_transform":[{
            "sql": "\\n select m.ID, m.Fruit, m.Price, e.amount, e.ts, e.rz_create_ts \
                from events e\\n left outer join fruits m\\n ON e.id=m.ID \\n and m.row_active_start_ts<=e.ts\\n \
                and m.row_active_end_ts>e.ts\\n ",
            "target": "fruits_events",
            "storage_path": "event_data_storage",
            "partition_keys": "ID"
        }],
        "event_data_transform_sql": [
            "SELECT m.ID, m.Fruit, m.Price, e.amount, e.ts  FROM events e \
            LEFT OUTER JOIN fruits m ON e.id=m.ID AND m.row_active_start_ts<=e.ts \
            AND m.row_active_end_ts>e.ts"
        ],
        "master_data_source": [
            "ID,shuiguo,yanse,jiage\\n1,Red Grape,Red, 2.5\\n2,Peach,Yellow,3.5\\n3,Orange,Orange, 2.3\\n \
            4,Green Apple,Green, 3.5\\n5,Fiji Apple,Red, 3.4 \\n6,Banana,Yellow, 1.2\\n7,Green Grape, Green,2.2"
        ],
        {master_data_transform_config}
        "master_data_storage_path": "master_data_storage"
    }
    """

    yield (test_config_path, metadata_config, config_contents)

    # Teardown: removing test config file after all tests
    os.remove(test_config_path)


def test_load_config_with_not_found_error(initialize_test_config):
    test_config_path, metadata_config, __ = initialize_test_config

    with pytest.raises(CddpException) as e:
        metadata_config.load_config()
    assert str(e.value) == ("[CddpException|Config] Config json file for test_source_system "
                            "and test_customer is not found.")

    # Create blank config file for next test
    os.makedirs(Path(test_config_path).parent, exist_ok=True)
    with open(test_config_path, "w"):
        pass


def test_load_config_with_invalid_json_error(initialize_test_config):
    __, metadata_config, __ = initialize_test_config

    with pytest.raises(CddpException) as e:
        metadata_config.load_config()
    assert str(e.value) == ("[CddpException|Config] Config json file for test_source_system "
                            "and test_customer is not in valid JSON format.")


def test_load_config_with_missing_key_error(initialize_test_config):
    test_config_path, metadata_config, config_contents = initialize_test_config

    config_contents = config_contents.replace("{master_data_transform_config}", "")
    with open(test_config_path, "w") as configs:
        configs.write(config_contents)

    with pytest.raises(CddpException) as e:
        metadata_config.load_config()
    assert str(e.value) == ("[CddpException|Config] Required config key master_data_transform "
                            "for test_source_system and test_customer is missing.")


def test_load_config_with_value_type_error(initialize_test_config):
    test_config_path, metadata_config, config_contents = initialize_test_config

    master_data_transform_config = """
    "master_data_transform": {"function": "test.function", "target": "fruits"},
    """
    config_contents = config_contents.replace("{master_data_transform_config}", master_data_transform_config)
    with open(test_config_path, "w") as configs:
        configs.write(config_contents)

    with pytest.raises(CddpException) as e:
        metadata_config.load_config()
    assert str(e.value) == ("[CddpException|Config] Config key master_data_transform for test_source_system "
                            "and test_customer should have array value.")


def test_load_config_with_value_error(initialize_test_config):
    test_config_path, metadata_config, config_contents = initialize_test_config

    config_contents = config_contents.replace("{master_data_transform_config}", "\"master_data_transform\": [],")
    with open(test_config_path, "w") as configs:
        configs.write(config_contents)

    with pytest.raises(CddpException) as e:
        metadata_config.load_config()
    assert str(e.value) == ("[CddpException|Config] Config key master_data_transform for test_source_system "
                            "and test_customer has no value in array.")


def test_load_config_properly(initialize_test_config):
    test_config_path, metadata_config, config_contents = initialize_test_config
    master_data_transform_config = """
    "master_data_transform": [{"function": "test.function", "target": "fruits"}],
    """
    config_contents = config_contents.replace("{master_data_transform_config}", master_data_transform_config)

    with open(test_config_path, "w") as configs:
        configs.write(config_contents)

    meta_config = metadata_config.load_config()

    assert meta_config["master_data_storage_path"] == "master_data_storage"
    assert meta_config["serving_data_storage_path"] == "serving_data_storage"
    assert meta_config["event_data_source"] == [{
        "name": "event-hub",
        "type": "local",
        "format": "json",
        "table_name": "events",
        "location": "customer_3/mock_events/",
        "secret": "eventhubs.connectionString"
    }]
    assert meta_config["event_data_transform"] == [{
        "sql": "\n select m.ID, m.Fruit, m.Price, e.amount, e.ts, e.rz_create_ts \
                from events e\n left outer join fruits m\n ON e.id=m.ID \n and m.row_active_start_ts<=e.ts\n \
                and m.row_active_end_ts>e.ts\n ",
        "target": "fruits_events",
        "storage_path": "event_data_storage",
        "partition_keys": "ID"
    }]
    assert meta_config["master_data_transform"] == [{"function": "test.function", "target": "fruits"}]
