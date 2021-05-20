import pytest

import common.module_b

def test_int_to_str():
    int_value = 7
    assert int_to_str(int_value)=='<7>'