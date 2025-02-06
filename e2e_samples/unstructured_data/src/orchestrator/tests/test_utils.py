import unittest

from orchestrator.utils import flatten_dict, merge_dicts


class TestUtils(unittest.TestCase):

    def test_merge_dicts(self) -> None:
        d1 = {
            "a": {"a1": "d1-value", "a2": "d1-value"},
            "b": [{"b1": "d1-value"}, {"b2": "d1-value"}],
        }
        d2 = {
            "a": {"a1": "d2-value"},
            "b": [{"b1": "d2-value"}],
            "c": "d2-value",
        }

        merged = merge_dicts(d1, d2)

        expected_output = {
            # dicts are merged. d2 takes precedence
            "a": {"a1": "d2-value", "a2": "d1-value"},
            # d2 has precence for lists
            "b": [{"b1": "d2-value"}],
            # d2 has precence for other values
            "c": "d2-value",
        }

        self.assertDictEqual(merged, expected_output)
        # ensure original dicts are unchanged
        self.assertDictEqual(d1["a"], {"a1": "d1-value", "a2": "d1-value"})
        self.assertDictEqual(d2["a"], {"a1": "d2-value"})

    def test_flatten_dict(self) -> None:
        d = {"a": {"b": {"c": "value1"}}, "d": {"e": "value2"}, "f": "value3"}

        flattened = flatten_dict(d)

        expected_output = {"a.b.c": "value1", "d.e": "value2", "f": "value3"}

        self.assertDictEqual(flattened, expected_output)

    def test_flatten_dict_with_custom_separator(self) -> None:
        d = {"a": {"b": {"c": "value1"}}, "d": {"e": "value2"}, "f": "value3"}

        flattened = flatten_dict(d, sep="_")

        expected_output = {"a_b_c": "value1", "d_e": "value2", "f": "value3"}

        self.assertDictEqual(flattened, expected_output)

    def test_flatten_dict_with_empty_dict(self) -> None:
        d: dict = {}

        flattened = flatten_dict(d)

        expected_output: dict = {}

        self.assertDictEqual(flattened, expected_output)
