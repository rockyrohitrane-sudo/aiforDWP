# Closure Note — Autopilot Enrolment Failure (Legacy MDM Conflict)
Device: DESKTOP-FB099 | User: FINBRIDGE\rthomas | Incident Date: 2024-03-15 | Closed: 2026-08-11

---

Resolved. Cause: Pre-existing legacy manual MDM enrolment (dated 2023-11-04) remained active on DESKTOP-FB099, conflicting with the 2024-03-15 Autopilot reprovisioning attempt and producing error 0x80180014 (device already enrolled in MDM), which blocked enrolment and caused downstream policy (0/4 profiles applied, 0x80070005) and compliance evaluation failures. Action: Retired and deleted the stale Intune managed device object, validated the single authoritative Autopilot device record, cleared device-side legacy MDM registration, and reprovisioned from clean OOBE — enrolment completed, all 4 profiles applied, compliance evaluated as compliant. Preventive: Mandatory pre-enrolment clean-state gate introduced requiring confirmation of no active legacy enrolment, no duplicate managed device objects, and a single authoritative Autopilot record before any Autopilot provisioning wave begins. User confirmed working.
