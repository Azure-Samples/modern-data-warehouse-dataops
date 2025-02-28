import unittest

from orchestrator.evaluation_config import EvaluatorLoadConfig, merge_eval_config_maps


class TestMergeEvalConfigMaps(unittest.TestCase):

    def setUp(self) -> None:
        self.exp_evaluators = {
            "evaluator1": EvaluatorLoadConfig(
                module="module1",
                class_name="EvaluatorClass1",
                evaluator_config={"column_mapping": {"input1": "column1"}},
                init_args={"arg1": "value1"},
            ),
            "evaluator2": EvaluatorLoadConfig(
                module="module2",
                class_name="EvaluatorClass2",
                evaluator_config={"column_mapping": {"input2": "column2"}},
                init_args={"arg2": "value2"},
            ),
        }

        self.variant_evaluators = {
            "evaluator1": None,
            "evaluator3": EvaluatorLoadConfig(
                module="module3",
                class_name="EvaluatorClass3",
                evaluator_config={"column_mapping": {"input3": "column3"}},
                init_args={"arg3": "value3"},
            ),
        }

    def test_merge_eval_config_maps(self) -> None:
        merged = merge_eval_config_maps(self.exp_evaluators, self.variant_evaluators)

        self.assertIn("evaluator1", merged)
        self.assertNotIn("evaluator2", merged)
        self.assertIn("evaluator3", merged)

        eval1 = merged["evaluator1"]
        self.assertIsNotNone(eval1)
        if eval1 is not None:
            self.assertEqual(eval1.init_args["arg1"], "value1")
            self.assertEqual(eval1.evaluator_config["column_mapping"]["input1"], "column1")

        eval3 = merged["evaluator3"]
        self.assertIsNotNone(eval3)
        if eval3 is not None:
            self.assertEqual(eval3.init_args["arg3"], "value3")
            self.assertEqual(eval3.evaluator_config["column_mapping"]["input3"], "column3")
