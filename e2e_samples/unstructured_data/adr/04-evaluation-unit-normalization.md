# Unit normalization of LLM response for evaluation

Proposal

## Context
The purpose of this document is to outline the architecture for evaluating LLM-generated citations against ground-truth data, specifically for questions involving financial values. Given that the citations may vary in format, units and numerical representation, a robust evaluation mechanism is required to ensure accurate comparison.

## Decision

Ground-truth financial values may be expressed in different formats and units compared to LLM-generated citations. Eg.,
- Ground-truth: 1,500 million USD.
- LLM-generated citation: 1.5B in revenue.

The evaluator should normalize and compare these values despite variations in representation.

Following are the proposed steps:

1. **Preprocessing**: Tokenize and extract financial values from the LLM-generated citations and ground-truth data. The preprocessing step should handle different representations such as "1,500 million USD" vs "$1.5B".
Additionally, the preprocessing step may need to include context matching to isolate the financial category (eg., revenue, assets, profit) to which the extracted numbers belong. E.g., The LLM-generated citation may contain multiple numbers like "1.5B revenue, 500M profit".
Both heuristic (E.g., regex) and LLM based approaches (prompting the LLM to extract revenue number and unit from text) can be considered for this step.

2. **Normalization**: Convert all numbers to a common unit (eg., millions or billions). This step needs to account for different formats of expressing numbers (eg., commans, decimals, currency symbols).
Example conversions:
   - 1,500 million -> 1.5B
   - 1,500 million USD -> 1.5B
   - 1.5 billion -> 1.5B

3. **Evaluation**: Compare the normalized values using the following metrics:
   - Numeric match: Check if the normalized values match exactly.
   - Percentage match: Calculate the percentage difference between the normalized values.
   - [Optional] Unit match: If we prefer the LLM to generate the citations in a specific unit, check if the unit matches with the ground-truth unit.

## Consequences

This change will enable a robust evaluation mechanism for comparing LLM-generated citations against ground-truth data despite variations in numeric representation and units in financial values.
