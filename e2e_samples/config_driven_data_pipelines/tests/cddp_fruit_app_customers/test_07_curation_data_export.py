from cddp_solution.common.utils.module_helper import find_class
import pandas as pd
from ..utils.test_utils import assert_rows
import mock
import tempfile
import pytest

expected_rows = [
    (4, 'Green Apple', 12, 420.0),
    (7, 'Green Grape', 14, 246.4000000000001),
    (5, 'Fiji Apple', 15, 625.6),
    (1, 'Red Grape', 20, 485.0),
    (3, 'Orange', 8, 200.1),
    (6, 'Banana', 14, 195.6),
    (2, 'Peach', 16, 497.0)
]

serving_data_storage_path = f"{tempfile.gettempdir()}/__data_storage__/serving_data_storage/customer_data"
export_data_storage_csv_path = f"{tempfile.gettempdir()}/__data_storage__/export_data_storage/customer_2"


def prepare_test_data(transform, config):
    data = transform.spark.createDataFrame(
        expected_rows,
        ["ID", "Fruit", "sales_count", "sales_total"]
    )

    transform_list = config["event_data_curation"]
    for data_transform in transform_list:
        transform_target = data_transform["target"]
        partition_keys = data_transform["partition_keys"]
        target_table_path = serving_data_storage_path+"/"+transform_target
        if len(partition_keys) > 0:
            target_partition_keys = partition_keys.upper().split(",")
            data.write.format("delta").mode("append").partitionBy(target_partition_keys).save(target_table_path)
        else:
            data.write.format("delta").mode("append").save(target_table_path)


def test_postgreSQL_export_with_error(load_config, monkeypatch):
    config = load_config("tests.cddp_fruit_app", "customer_1")
    clz = find_class("tests.cddp_fruit_app.curation_data_export", "CurationDataExport")
    curation_export = clz(config)
    prepare_test_data(curation_export, config)
    curation_export.export_action.export_data_to_postgreSQL = mock.Mock()
    curation_export.export_action.export_data_to_postgreSQL.return_value = None

    curation_export.serving_data_storage_path = serving_data_storage_path
    with pytest.raises(Exception) as e:
        curation_export.export()

    assert str(e.value) == "Please check environment variables for SQL user name and password."


def test_postgreSQL_export(load_config, monkeypatch):
    # Mock environment variables
    monkeypatch.setenv("export_postgres_user", "mock_user")
    monkeypatch.setenv("export_postgres_password", "mock_pwd")

    config = load_config("tests.cddp_fruit_app", "customer_1")
    clz = find_class("tests.cddp_fruit_app.curation_data_export", "CurationDataExport")
    curation_export = clz(config)
    prepare_test_data(curation_export, config)
    curation_export.export_action.export_data_to_postgreSQL = mock.Mock()
    curation_export.export_action.export_data_to_postgreSQL.return_value = None

    curation_export.serving_data_storage_path = serving_data_storage_path
    curation_export.export()
    assert curation_export.export_action.export_data_to_postgreSQL.called


def test_csv_export(load_config, cleanup_datalake):
    config = load_config("tests.cddp_fruit_app", "customer_2")
    clz = find_class("tests.cddp_fruit_app.curation_data_export", "CurationDataExport")
    curation_export = clz(config)
    prepare_test_data(curation_export, config)
    curation_export.serving_data_storage_path = serving_data_storage_path
    curation_export.export_action.export_data_storage_csv_path = export_data_storage_csv_path
    curation_export.export()

    export_file_name = curation_export.export_action.config["export_file_name"]
    pddf = pd.read_csv(curation_export.export_action.export_data_storage_csv_path + "/" + export_file_name + ".csv")
    sparkdf = curation_export.spark.createDataFrame(pddf)
    assert sparkdf.count() == 7
    assert_rows(sparkdf, ('ID', 'Fruit', 'sales_count', 'sales_total'), expected_rows)
