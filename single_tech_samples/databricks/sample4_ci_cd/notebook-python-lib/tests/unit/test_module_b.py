import pytest

from common.module_b import int_to_str

def test_int_to_str():
    int_value = 7
    assert int_to_str(int_value)=='<7>'