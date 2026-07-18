# Product brief

## Purpose

Ala-ala is a Filipino-first memory companion prototype for older adults and their families. It aims to make daily orientation, familiar relationships, and shared memories easier to revisit in a calm, dignified interface.

## People it serves

| Person | Need |
| --- | --- |
| Older adult | Gentle orientation, familiar context, and low-pressure prompts. |
| Family member | A respectful way to preserve moments, promises, and visit context. |
| Caregiver | A lightweight place to add relevant notes and support continuity of care. |

## Experience principles

- **Familiar before clever.** Use recognisable language, stable navigation, and personal context.
- **Calm by design.** Avoid urgency, dense screens, and complex interaction patterns.
- **Source-backed answers.** Show stored memories instead of presenting unsupported information as fact.
- **Consent is foundational.** Recognition and personal data require informed, ongoing permission.
- **Care supports autonomy.** The experience should assist the person, not speak over them.

## Current MVP

The app has four navigation destinations, defined in [`lib/main.dart`](../lib/main.dart):

1. **Tahanan** presents an orientation greeting, daily summary, and routine items.
2. **MemoryLens** simulates identifying known people and exposes relationship and timeline context.
3. **Aking Alaala** searches the saved demo memory list and displays matching source records.
4. **Pamilya** displays people and supports adding caregiver notes and memories.

The app currently starts with illustrative data for Maria and her family. The data is reset on restart.

## Non-goals of this MVP

- A production camera, facial-recognition, or biometric system
- Clinical advice, diagnosis, medication management, or emergency response
- Cloud storage, accounts, authentication, or multi-device sync
- Generative AI answers that are not grounded in stored memories

## Next product validation

Before increasing technical scope, test the flow with older adults, caregivers, and Filipino families. Observe comprehension of labels, tap-target comfort, reading load, emotional response to recognition prompts, and consent comprehension.
