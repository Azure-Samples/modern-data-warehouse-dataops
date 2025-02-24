import re
from typing import Any

from evaluators.citation_evaluator import CitationEvaluator


class NumericEvaluator:
    """
    # noqa: W605
    Exact matches numeric values in a given response against the ground truth value.

    Methods:
        __call__(response, ground_truth):
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

    def __call__(self, response: str, ground_truth: str) -> float:
        numbers = re.findall(r"[\$]?\s*\d{1,3}(?:,\d{3})*(?:\.\d+)?", response)
        chars_to_remove = ["$", ",", " "]
        numbers_processed = ["".join(char for char in num if char not in chars_to_remove) for num in numbers]
        truth_processed = "".join(char for char in ground_truth if char not in chars_to_remove)
        if truth_processed in numbers_processed:
            return 1.0
        return 0.0


class NumericCitationEvaluator(CitationEvaluator):
    """
    NumericCitationEvaluator is a class that evaluates numeric citations by extending the CitationEvaluator class.

    Attributes:
        evaluator (NumericEvaluator): An instance of NumericEvaluator used for evaluation.
        match_threshold (float): The threshold for matching numeric citations, set to 1.0 by default.

    Methods:
        __init__(**kwargs): Initializes the NumericCitationEvaluator with the given keyword arguments.
    """

    def __init__(self, **kwargs: Any):
        # threshold is 1.0 because we want only exact matches to pass
        super().__init__(evaluator=NumericEvaluator(), match_threshold=1.0, **kwargs)
