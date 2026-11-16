# 02 App flow and screen index

Figma file: https://www.figma.com/design/0lWIv5IY18QemXtzP3YaTE
Open a frame with `?node-id=<id with - instead of :>`.

| ID | Screen | Route | App | Figma node | States (node) |
| --- | --- | --- | --- | --- | --- |
| A01 | Sign in | /sign-in | both | 26:3 | invalid code (26:38), phone (26:74) |
| P01 | Welcome + consent | /intake | patient | 6:2 | loading (23:33) |
| P02 | Intake chat | /intake/chat | patient | 6:40 | waiting (10:23), route refused (6:87), model error (23:71), tablet (23:108) |
| P03 | Urgent care | /intake/urgent | patient | 6:125 | |
| P04 | Done | /intake/done | patient | 6:143 | |
| D01 | Patient queue | /doctor | clinic | 7:2 | empty (11:362), loading (25:198) |
| D02 | Physician brief | /doctor/brief/:id | clinic | 7:139 | generating (25:281), approved (11:128), edited (25:401), rejected (25:497), no guideline (11:252), tablet (25:622) |
| D03 | Privacy & Trust panel | side sheet in D02 | clinic | in 7:139 | row states (7:261) |
| D04 | Audit log | /doctor/audit | clinic | 7:310 | |
| D05 | Demo scenarios | /doctor/demo | clinic | 7:428 | |
| D06 | Red-flag summary | /doctor/flag/:id | clinic | 25:722 | |
| S01 | Privacy & data settings | /doctor/settings | clinic | 27:3 | |

Flows (page "Flows", node 28:3):
- Patient: A01 → P01 → P02 → P04. P02 goes to P03 on red flag R1–R6, then to P04.
- Clinic: A01 → D01 → D02 → approved / edited / rejected. D01 → D06 for red-flag sessions. D05's negative test shows a refused row in D03.

Prototype links are wired on the Patient and Clinic pages, starting at P01 and D01.

Components → `packages/bloom_ui` widgets: Button, StatusChip, ChatBubble, QuickReply, Banner, CitationLink, TrustRow, DecisionBar.

New since the Gate 1 approval (2026-11-16): A01, D06, S01 and the extra states. They need srinivas's review.
