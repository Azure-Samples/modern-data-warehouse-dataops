import re
from dataclasses import dataclass

from evaluators.citation_evaluator import CitationEvaluator


class ExactNumericMatchEvaluator:
    """
    # noqa: W605
    Exact matches numeric values in a given response against the ground truth value.

    Args:
        truth_key: The key within the ground truth dictionary that is being evaluated.

    Methods:
        __call__(ground_truth, repsonse):
            Evaluates the response against the ground truth numeric value.
            Returns: A dictionary containing a "ratio" key.
                - "ratio":
                    - 1.0 if any of the "excerpt" values in the response contain
                    the ground truth numeric value.
                    - 0.0 otherwise.
            **Regular Expression Explanation:**
            - `[\$]?`: Matches an optional dollar sign ($) character.
            - `\s*`: Matches zero or more whitespace characters(spaces, tabs, newlines).
            - `\d{1,3}`: Matches one to three digits (0-9).
            - `(?:,\d{3})*`: Matches zero or more groups of:
                - `,`: A comma.
                - `\d{3}`: Three digits.
            - `(?:\.\d+)?`: Matches an optional group of:
                - `\.`: A decimal point.
                - `\d+`: One or more digits.
            This regular expression extracts potential numeric values from the text,
            allowing for various formats:
            - `$123`
            - `$1,234`
            - `$1,234,567`
            - `$123.45`
            - `$1,234.56`
            - `123` (without dollar sign)
            - `1,234` (without dollar sign)
            - `1,234,567` (without dollar sign)
            - `123.45` (without dollar sign)
            - `1,234.56` (without dollar sign)
    """

    def __call__(self, ground_truth: str, response: str) -> float:
        numbers_regex = r"[\$]?\s*\d{1,3}(?:,\d{3})*(?:\.\d+)?"
        numbers = re.findall(numbers_regex, response)
        truth_numbers = re.findall(numbers_regex, ground_truth)

        chars_to_remove = ["$", ",", " "]

        numbers_processed = ["".join(char for char in num if char not in chars_to_remove) for num in numbers]
        truth_numbers_processed = [
            "".join(char for char in num if char not in chars_to_remove) for num in truth_numbers
        ]

        for t in truth_numbers_processed:
            if t not in numbers_processed:
                return 0.0
        return 1.0


@dataclass
class ExactNumericMatchCitationEvaluator(CitationEvaluator):

    match_threshold: float = 1.0
    evaluator = ExactNumericMatchEvaluator()

    def evaluate(self, ground_truth: str, response: str) -> float:
        return self.evaluator(ground_truth, response)
