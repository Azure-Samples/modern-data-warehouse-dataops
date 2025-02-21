# Citation Explanation Storage

Proposal

## Context

In order to debug the LLM's responses, citation explanations need to be stored for future retrieval and review. Therefore, storage alternatives need to be explored that can best suit the plain text format of these explanations.

While the original intention was to store these explanations in a database alongside their citation counterparts, the predefined schema of the Excitation Tool's database was something that would decidedly be left untouched until further customer signals indicated this was something worth modifying. Observability was another alternative considered and decided against, due to the potential risks of PII exposure.

## Decision

To circumvent the aforementioned issues, the decision was made to write explanations, alongside with all other citation data, to JSONL files within an output directory. This will allow evaluation to occur outside the context of the Excitation Tool.

## Consequences

In the future event that a business use case from a customer requires further leveraging of these explanations, either for debugging or for front-end display, it is possible that these explanations will need to be stored in the database, requiring updates to be made not just to this project but to the Excitation Tool's database schema and related code.

Until then, outputting to a local file ensures storage of LLM-generated explanations for the given citations. It likewise applies conceptual seperation between the Citation Generator and the Excitation Tool's intended purposes, the latter of which is agnostic to how citations are generated and intentionally does not include any functionality related to LLM-specific evaluation and storage.

A key tradeoff in this decision, of course, is that citation explanations cannot reside in a centralized datastore for LLM developers to collectively leverage.
