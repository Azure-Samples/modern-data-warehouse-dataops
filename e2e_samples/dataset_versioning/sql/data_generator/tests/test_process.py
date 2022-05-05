from process import Process
import pandas as pd
import numpy as np
import pytest
from datetime import datetime
from pandas._testing import assert_frame_equal


def test_process_non_datetime_water_mark():
    data = np.array([['id', 'col1', 'date'], ['1', 1, 2], ['2', 3, 4]])
    df = pd.DataFrame(data=data[1:, ], columns=data[0, 0:])
    process = Process(df, version_date='date')
    with pytest.raises(AttributeError):
        process.filter_with_version(0)


def test_process_normal_case():
    data = np.array([['id', 'col1', 'date'], ['1', 1, datetime(2020, 1, 1)], ['2', 3, datetime(2020, 2, 1)]])
    df = pd.DataFrame(data=data[1:, ], columns=data[0, 0:])
    process = Process(df, version_date='date')
    actual_v0 = process.filter_with_version(0)
    expected_v0 = pd.DataFrame(data=data[1:2, ], columns=data[0, 0:])
    actual_v1 = process.filter_with_version(1)
    expected_v1 = pd.DataFrame(data=data[2:3, ], columns=data[0, 0:])
    assert_frame_equal(expected_v0.reset_index(drop=True), actual_v0.reset_index(drop=True))
    assert_frame_equal(expected_v1.reset_index(drop=True), actual_v1.reset_index(drop=True))
