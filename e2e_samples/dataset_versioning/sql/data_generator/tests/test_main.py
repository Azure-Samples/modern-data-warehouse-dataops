from main import main
from keyvault_wrapper import KeyvaultWrapper
from process import Process
from sql_wrapper import SqlWrapper
import pytest


def test_missing_value(mocker):
    sql_mock = mocker.Mock(spec=SqlWrapper)
    keyvault_mock = mocker.Mock(spec=KeyvaultWrapper)
    process_mock = mocker.Mock(spec=Process)
    with pytest.raises(SystemExit):
        main(keyvault_mock, sql_mock, process_mock, ["-p", "test.csv"])
        assert not process_mock().called


@pytest.mark.parametrize(
    "test_input, expected",
    [(["-c", "-k", "keyvault"], [True, False, False]),
     (["-k", "keyvault", "-v", 0, "-p", "./test_sample.csv"], [False, True, True])])
def test_different_valid_arguments(mocker, test_input, expected):
    sql_mock = mocker.Mock(spec=SqlWrapper)
    keyvault_mock = mocker.Mock(spec=KeyvaultWrapper)
    process_mock = mocker.Mock(spec=Process)
    main(keyvault_mock, sql_mock, process_mock, test_input)
    actual_result = [sql_mock().clean_up.called, process_mock().filter_with_version.called, sql_mock().insert_to_sql.called]
    assert actual_result == expected
