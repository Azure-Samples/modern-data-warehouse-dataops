import re
from typing import Any

from evaluators.types import EvalResult


class NumericEvaluator:
    """
    # noqa: W605
    Exact matches numeric values in a given response against the ground truth value.

    Args:
        truth_key: The key within the ground truth dictionary that is being evaluated.

    Methods:
        __call__(response, truth):
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

    def __init__(self, **kwargs: Any):
        pass

    def __call__(self, response: list, truth: str, **kwargs: Any) -> EvalResult:
        if not truth:
            if response:
                # we have responses, but truth says we should not have any
                return EvalResult(ratio=0.0)
            else:
                # If truth is none and no citations. The generator did well
                return EvalResult(ratio=1.0)
        elif not response:
            # we have truth but no citations
            return EvalResult(ratio=0.0)
        for r in response:
            excerpt = r.get("excerpt")
            numbers = re.findall(r"[\$]?\s*\d{1,3}(?:,\d{3})*(?:\.\d+)?", excerpt)
            chars_to_remove = ["$", ",", " "]
            numbers_processed = ["".join(char for char in num if char not in chars_to_remove) for num in numbers]
            truth_processed = "".join(char for char in truth if char not in chars_to_remove)
            if truth_processed in numbers_processed:
                return EvalResult(ratio=1.0)
        return EvalResult(ratio=0.0)
