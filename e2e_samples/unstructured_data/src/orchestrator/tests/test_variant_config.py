import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from orchestrator.evaluation_config import EvaluationConfig, EvaluatorLoadConfig, EvaluatorLoadConfigMap
from orchestrator.variant_config import VariantConfig, load_variant, merge_variant_configs


class TestVariantConfig(unittest.TestCase):

    def test_merge_evaluation(self) -> None:
        vc1 = VariantConfig(
            evaluation=EvaluationConfig(
                evaluators={
                    "eval1": EvaluatorLoadConfig(
                        module="module1", class_name="class_name1", init_args={"arg1": "value1"}
                    )
                }
            ),
        )
        vc2 = VariantConfig(
            evaluation=EvaluationConfig(
                evaluators={
                    "eval1": EvaluatorLoadConfig(init_args={"arg2": "value2"}),
                    "eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2"),
                }
            ),
        )

        merged = merge_variant_configs(vc1, vc2)

        eval1 = merged.evaluation.evaluators.get("eval1")
        self.assertIsNotNone(eval1, "eval1 should not be None")
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1", "eval1 module is incorrect")
            self.assertEqual(eval1.class_name, "class_name1", "eval1 class_name is incorrect")
            self.assertDictEqual(eval1.init_args, {"arg1": "value1", "arg2": "value2"}, "eval1 init_args are incorrect")

        eval2 = merged.evaluation.evaluators.get("eval2")
        self.assertIsNotNone(eval2, "eval2 should not be None")
        if eval2 is not None:
            self.assertEqual(eval2.module, "module2", "eval2 module is incorrect")
            self.assertEqual(eval2.class_name, "class_name2", "eval2 class_name is incorrect")
        self.assertEqual(merged.output_container, vc2.output_container, "output_container is incorrect")

    def test_merge_evaluation_none(self) -> None:
        vc1 = VariantConfig(
            evaluation=EvaluationConfig(
                evaluators={"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}
            ),
        )
        vc2 = VariantConfig()

        merged = merge_variant_configs(vc1, vc2)

        eval1 = merged.evaluation.evaluators.get("eval1")
        self.assertIsNotNone(eval1, "eval1 should not be None")
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1", "module is incorrect")
            self.assertEqual(eval1.class_name, "class_name1", "class_name is incorrect")

    def test_merge_output_container(self) -> None:
        vc1 = VariantConfig(output_container="container1")
        vc2 = VariantConfig(output_container="container2")

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.output_container, "container2", "output_container is incorrect")

    def test_merge_output_container_none(self) -> None:
        vc1 = VariantConfig(output_container="container1")
        vc2 = VariantConfig(output_container=None)

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.output_container, "container1", "output_container is incorrect")

    def test_merge_init_args(self) -> None:
        vc1 = VariantConfig(init_args={"arg1": "value1", "list_arg": ["value1"]})
        vc2 = VariantConfig(init_args={"arg2": "value2", "list_arg": ["value2"]})

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(
            merged.init_args, {"arg1": "value1", "arg2": "value2", "list_arg": ["value2"]}, "init_args are incorrect"
        )

    def test_merge_init_args_empty(self) -> None:
        vc1 = VariantConfig(init_args={"arg1": "value1", "list_arg": ["value1"]})
        vc2 = VariantConfig()

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.init_args, {"arg1": "value1", "list_arg": ["value1"]}, "init_args are incorrect")

    def test_merge_call_args(self) -> None:
        vc1 = VariantConfig(call_args={"arg1": "value1", "list_arg": ["value1"]})
        vc2 = VariantConfig(call_args={"arg2": "value2", "list_arg": ["value2"]})

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(
            merged.call_args, {"arg1": "value1", "arg2": "value2", "list_arg": ["value2"]}, "call_args are incorrect"
        )

    def test_merge_call_args_empty(self) -> None:
        vc1 = VariantConfig(call_args={"arg1": "value1", "list_arg": ["value1"]})
        vc2 = VariantConfig()

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.call_args, {"arg1": "value1", "list_arg": ["value1"]}, "call_args are incorrect")

    @patch("orchestrator.variant_config.load_file")
    def test_load_variant_with_no_parents(self, mock_load_file: MagicMock) -> None:
        mock_load_file.return_value = {
            "name": "variant1",
            "init_args": {"arg1": "value1"},
            "call_args": {"call_arg1": "value1"},
            "evaluation": {"evaluators": {"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}},
            "output_container": "container1",
        }
        variant_path = Path("variant.yaml")
        variant = load_variant(variant_path)

        self.assertEqual(variant.name, "variant1", "variant name is incorrect")
        self.assertEqual(variant.init_args, {"arg1": "value1"}, "init_args are incorrect")
        self.assertEqual(variant.call_args, {"call_arg1": "value1"}, "call_args are incorrect")
        eval1 = variant.evaluation.evaluators.get("eval1")
        self.assertIsNotNone(eval1, "eval1 should not be None")
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1", "module is incorrect")
            self.assertEqual(eval1.class_name, "class_name1", "class_name is incorrect")
        self.assertEqual(variant.output_container, "container1", "output_container is incorrect")

    @patch("orchestrator.variant_config.load_file")
    def test_load_variant_with_parents(self, mock_load_file: MagicMock) -> None:
        def side_effect(path: Path) -> dict:
            if path.name == "parent.yaml":
                return {
                    "name": "parent",
                    "init_args": {"arg1": "value1"},
                    "call_args": {"call_arg1": "value1"},
                    "evaluation": {
                        "evaluators": {"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}
                    },
                    "output_container": "container1",
                }
            return {
                "name": "variant1",
                "parent_variants": ["parent.yaml"],
                "init_args": {"arg2": "value2"},
                "call_args": {"call_arg2": "value2"},
                "evaluation": {
                    "evaluators": {"eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2")}
                },
                "output_container": "container2",
            }

        mock_load_file.side_effect = side_effect
        variant_path = Path("variant.yaml")
        variant = load_variant(variant_path)

        self.assertEqual(variant.name, "variant1", "variant1 name is incorrect")
        self.assertEqual(variant.init_args, {"arg1": "value1", "arg2": "value2"}, "variant1 init_args are incorrect")
        self.assertEqual(
            variant.call_args, {"call_arg1": "value1", "call_arg2": "value2"}, "variant1 call_args are incorrect"
        )

        eval1 = variant.evaluation.evaluators.get("eval1")
        self.assertIsNotNone(eval1, "eval1 should not be None")
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1", "eval1 module is incorrect")
            self.assertEqual(eval1.class_name, "class_name1", "eval1 class_name is incorrect")
        eval2 = variant.evaluation.evaluators.get("eval2")
        self.assertIsNotNone(eval2, "eval2 should not be None")
        if eval2 is not None:
            self.assertEqual(eval2.module, "module2", "eval2 module is incorrect")
            self.assertEqual(eval2.class_name, "class_name2", "eval2 class_name is incorrect")

        self.assertEqual(variant.output_container, "container2", "variant1 output_container is incorrect")

    @patch("orchestrator.variant_config.load_file")
    def test_load_variant_with_exp_evaluators(self, mock_load_file: MagicMock) -> None:
        mock_load_file.return_value = {
            "name": "variant1",
            "init_args": {"arg1": "value1"},
            "call_args": {"call_arg1": "value1"},
            "evaluation": {
                "evaluators": {
                    "eval1": None,
                    "eval3": {"module": "module3", "class_name": "class_name3"},
                }
            },
            "output_container": "container1",
        }
        exp_evaluators: EvaluatorLoadConfigMap = {
            "eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1"),
            "eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2"),
        }
        variant_path = Path("variant.yaml")
        variant = load_variant(variant_path, exp_evaluators)

        self.assertEqual(variant.name, "variant1", "variant name is incorrect")
        self.assertEqual(variant.init_args, {"arg1": "value1"}, "init_args are incorrect")
        self.assertEqual(variant.call_args, {"call_arg1": "value1"}, "call_args are incorrect")
        self.assertEqual(len(variant.evaluation.evaluators.keys()), 2, "evaluators count is incorrect")
        eval1 = variant.evaluation.evaluators.get("eval1")
        self.assertIsNotNone(eval1, "eval1 should not be None")
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1", "eval1 module is incorrect")
            self.assertEqual(eval1.class_name, "class_name1", "eval1 class_name is incorrect")
        eval3 = variant.evaluation.evaluators["eval3"]
        self.assertIsNotNone(eval3, "eval3 should not be None")
        if eval3 is not None:
            self.assertEqual(eval3.module, "module3", "eval3 module is incorrect")
            self.assertEqual(eval3.class_name, "class_name3", "eval3 class_name is incorrect")

        self.assertEqual(variant.output_container, "container1", "output_container is incorrect")
        mock_load_file.assert_called_once_with(variant_path)
