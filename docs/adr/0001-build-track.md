# ADR 0001: Build track and product

- **Status:** Accepted (chosen by srinivas in chat, 2026-11-16)
- **Date:** 2026-11-16

## Context
Bloom, the Private AI Gynecology Copilot, is built for Boat Hackathon SF. The final submission deadline is Fri 2026-11-20, 5:00 PM PT, and the plan is to submit on Wed 2026-11-18. Bloom has a patient pre-visit intake and a gynecologist dashboard.

## Decision
- **Track:** Web. Flutter Web with responsive phone, tablet and desktop layouts. No Android/iOS store builds this week.
- **Product:** Both. Patient intake (screens P01–P04) and clinic dashboard (screens D01–D05) share one backend.
- **Clinic app:** web with tablet layouts. **Patient app:** web with phone and tablet layouts. This deviates from the playbook default of a mobile patient app; see Consequences.

## Consequences
- One codebase (`apps/bloom_web`), with the patient and doctor areas separated by route and role.
- There are no store builds, so mobile parity is deferred. A native patient app would get its own ADR after Demo Day.
- The playbook's mobile platform doc (10-platform-mobile.md) is out of scope this week.
