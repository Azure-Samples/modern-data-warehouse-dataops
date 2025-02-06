import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from orchestrator.evaluation_config import EvaluationConfig, EvaluatorLoadConfig
from orchestrator.experiment_config import VariantConfig, load_variant, merge_variant_configs


class TestExperimentConfig(unittest.TestCase):

    def test_merge_with_empty_vc2(self) -> None:
        vc1 = VariantConfig(
            name="variant1",
            parent_variants=["parent1"],
            init_args={"arg1": "value1"},
            call_args={"call_arg1": "value1"},
            evaluation=EvaluationConfig(
                evaluators={"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}
            ),
            output_container="container1",
        )
        vc2 = VariantConfig()

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.name, vc1.name)
        self.assertEqual(merged.parent_variants, vc1.parent_variants)
        self.assertEqual(merged.init_args, vc1.init_args)
        self.assertEqual(merged.call_args, vc1.call_args)
        eval1 = merged.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        # typechecking
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        self.assertEqual(merged.output_container, vc1.output_container)

    def test_merge_with_non_empty_vc2(self) -> None:
        vc1 = VariantConfig(
            name="variant1",
            parent_variants=["parent1"],
            init_args={"arg1": "value1"},
            call_args={"call_arg1": "value1"},
            evaluation=EvaluationConfig(
                evaluators={"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}
            ),
            output_container="container1",
        )
        vc2 = VariantConfig(
            name="variant2",
            parent_variants=["parent2"],
            init_args={"arg2": "value2"},
            call_args={"call_arg2": "value2"},
            evaluation=EvaluationConfig(
                evaluators={"eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2")}
            ),
            output_container="container2",
        )

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.name, vc2.name)
        self.assertEqual(merged.parent_variants, vc2.parent_variants)
        self.assertEqual(merged.init_args, {"arg1": "value1", "arg2": "value2"})
        self.assertEqual(merged.call_args, {"call_arg1": "value1", "call_arg2": "value2"})

        eval1 = merged.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        eval2 = merged.evaluation.evaluators["eval2"]
        self.assertIsNotNone(eval2)
        if eval2 is not None:
            self.assertEqual(eval2.module, "module2")
            self.assertEqual(eval2.class_name, "class_name2")
        self.assertEqual(merged.output_container, vc2.output_container)

    def test_merge_with_none_output_container_in_vc2(self) -> None:
        vc1 = VariantConfig(
            name="variant1",
            parent_variants=["parent1"],
            init_args={"arg1": "value1"},
            call_args={"call_arg1": "value1"},
            evaluation=EvaluationConfig(
                evaluators={"eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1")}
            ),
            output_container="container1",
        )
        vc2 = VariantConfig(
            name="variant2",
            parent_variants=["parent2"],
            init_args={"arg2": "value2"},
            call_args={"call_arg2": "value2"},
            evaluation=EvaluationConfig(
                evaluators={"eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2")}
            ),
            output_container=None,
        )

        merged = merge_variant_configs(vc1, vc2)

        self.assertEqual(merged.name, vc2.name)
        self.assertEqual(merged.parent_variants, vc2.parent_variants)
        self.assertEqual(merged.init_args, {"arg1": "value1", "arg2": "value2"})
        self.assertEqual(merged.call_args, {"call_arg1": "value1", "call_arg2": "value2"})
        eval1 = merged.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        eval2 = merged.evaluation.evaluators["eval2"]
        self.assertIsNotNone(eval2)
        if eval2 is not None:
            self.assertEqual(eval2.module, "module2")
            self.assertEqual(eval2.class_name, "class_name2")
        self.assertEqual(merged.output_container, vc1.output_container)

    @patch("orchestrator.experiment_config.load_file")
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

        self.assertEqual(variant.name, "variant1")
        self.assertEqual(variant.init_args, {"arg1": "value1"})
        self.assertEqual(variant.call_args, {"call_arg1": "value1"})
        eval1 = variant.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        self.assertEqual(variant.output_container, "container1")

    @patch("orchestrator.experiment_config.load_file")
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

        self.assertEqual(variant.name, "variant1")
        self.assertEqual(variant.init_args, {"arg1": "value1", "arg2": "value2"})
        self.assertEqual(variant.call_args, {"call_arg1": "value1", "call_arg2": "value2"})
        eval1 = variant.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        eval2 = variant.evaluation.evaluators["eval2"]
        self.assertIsNotNone(eval2)
        if eval2 is not None:
            self.assertEqual(eval2.module, "module2")
            self.assertEqual(eval2.class_name, "class_name2")
        self.assertEqual(variant.output_container, "container2")

    @patch("orchestrator.experiment_config.load_file")
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
        exp_evaluators = {
            "eval1": EvaluatorLoadConfig(module="module1", class_name="class_name1"),
            "eval2": EvaluatorLoadConfig(module="module2", class_name="class_name2"),
        }
        variant_path = Path("variant.yaml")
        variant = load_variant(variant_path, exp_evaluators)

        self.assertEqual(variant.name, "variant1")
        self.assertEqual(variant.init_args, {"arg1": "value1"})
        self.assertEqual(variant.call_args, {"call_arg1": "value1"})
        self.assertEqual(len(variant.evaluation.evaluators.keys()), 2)
        eval1 = variant.evaluation.evaluators["eval1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.module, "module1")
            self.assertEqual(eval1.class_name, "class_name1")
        eval3 = variant.evaluation.evaluators["eval3"]
        self.assertIsNotNone(eval3)
        if eval3 is not None:
            self.assertEqual(eval3.module, "module3")
            self.assertEqual(eval3.class_name, "class_name3")
        self.assertEqual(variant.output_container, "container1")

    @patch("orchestrator.experiment_config.load_file")
    def test_load_variant_without_name(self, mock_load_file: MagicMock) -> None:
        mock_load_file.return_value = {
            "init_args": {"arg1": "value1"},
            "evaluation": {"evaluators": {"eval1": None}},
            "output_container": "container1",
        }
        variant_path = Path("variant.yaml")
        with self.assertRaises(ValueError):
            load_variant(variant_path)
