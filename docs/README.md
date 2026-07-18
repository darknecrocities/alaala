# Ala-ala documentation

This directory is the project’s source of truth. It describes the implemented MVP and the decisions that guide future work. When behaviour or scope changes, update the relevant document in the same change.

| Document | Scope |
| --- | --- |
| [Product brief](product.md) | Who Ala-ala serves, why it exists, and the MVP boundary |
| [Architecture](architecture.md) | Flutter structure, state ownership, and key data flows |
| [AI & retrieval](ai-and-retrieval.md) | Keyword retrieval, Local/Gemini/OpenAI behaviour, data flow, and safety limits |
| [Privacy & safety](privacy-and-safety.md) | Current data handling and requirements before real-world use |
| [Development guide](development.md) | Setup, verification, conventions, and known limitations |

## Documentation rules

- Describe current, observable behaviour; label plans as proposed or future work.
- Keep privacy claims conservative. The app is a demo until real data safeguards are implemented.
- Link decisions to source files where practical, so the documentation remains easy to verify.
- Update the root [README](../README.md) whenever a newcomer-facing workflow changes.

## Canonical language

Use **Ala-ala** for the product name and **MemoryLens** for the familiar-person recognition prototype. The interface is Filipino-first, with plain Tagalog used for primary prompts.
