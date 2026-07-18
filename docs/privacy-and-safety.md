# Privacy and safety

## Current state

The shipped source is a local, in-memory demo. It has no network client, account system, persistence layer, camera integration, or functional facial-recognition implementation. The people and memories in [`MemoryStore`](../lib/services/memory_store.dart) are illustrative seed data.

The repository includes [`.env.example`](../.env.example) only as a future configuration template. Provider credentials must not be committed or embedded in mobile builds.

## Sensitive information in the intended product

| Data type | Examples | Required posture |
| --- | --- | --- |
| Personal memories | Family moments, routines, notes, visits | Private by default; encrypted at rest; user-controlled sharing. |
| Health-adjacent notes | Medication reminders, appointments | Do not frame as clinical advice; apply heightened access and retention controls. |
| Biometric data | Face images, landmarks, embeddings | Explicit opt-in, local processing by default, revocation, and deletion. |
| Caregiver access | Who can view or add records | Role-based, auditable, and revocable. |

## Production requirements before real data

- Obtain clear, informed, revocable consent from each affected person or authorised representative.
- Provide a usable way to view, correct, export, and delete personal information.
- Encrypt local data and protect access with appropriate device authentication.
- Define retention, backup, recovery, and breach-response practices before launch.
- Process facial data on device by default; do not transmit biometric identifiers to third-party AI providers without an explicit, well-explained choice.
- Keep cloud-provider credentials on a server-side service, never in the client application.
- Test language, consent, and recognition interactions with the people the product intends to serve.

## Product safety boundaries

Ala-ala is not a medical device and must not diagnose, prescribe, or replace professional medical or emergency support. Medication and health prompts should be clearly labelled as family- or caregiver-provided reminders, with a path to verify the original source.
