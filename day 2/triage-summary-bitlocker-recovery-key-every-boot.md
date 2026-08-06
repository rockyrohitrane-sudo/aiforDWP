# Triage Summary - T-1001

## Summary (one line)
New Windows 11 laptop repeatedly prompts for BitLocker recovery key on every boot, indicating persistent startup trust validation failure (to-verify).

## Impact (who/how many/business urgency)
- Who: Single end user on a newly issued laptop (to-verify).
- How many: Currently reported as 1 device/user; risk of wider impact unknown (to-verify).
- Business urgency: High for affected user due to repeated boot interruption and productivity loss; priority rises if multiple new devices are affected (to-verify).

## Known Facts
- Ticket ID: T-1001.
- Device type: New Windows 11 laptop.
- Symptom: BitLocker asks for recovery key every boot.
- Timing/context: Problem present from early device use on a new build (to-verify).

## Missing Information to Gather
- Scope confirmation: Is this isolated or seen on other recently provisioned devices?
- User/account context: Department, role criticality, and immediate business deadline impact.
- Build/provisioning details: Imaging method, provisioning process, and whether any pre-boot/security settings were changed after handover.
- Recent hardware/firmware changes: Docking, motherboard/TPM-related updates, BIOS/UEFI updates, or boot order changes (all to-verify).
- Recovery key behavior: Whether the same key works each time and whether prompt appears after every reboot, shutdown, or specific trigger.
- Security tooling context: Any endpoint/security policy actions around encryption at first sign-in (to-verify).

## Likely Category
Encryption / BitLocker startup validation issue on endpoint build or platform trust chain (to-verify).

## First Diagnostic Step
Confirm scope and capture a minimal timeline with the user, then verify whether any firmware/UEFI/TPM or boot configuration changes occurred between first successful sign-in and the first repeated recovery prompt (all details to-verify).