# Known Error Record - AVD Session Disconnect After Logon (POOL-FIN-01)

- Knowledge base reference: KE-AVD-001
- Incident date: 2024-03-15
- Platform: Azure Virtual Desktop
- Status: Resolved

---

**Symptom**
Users connecting to `POOL-FIN-01` can authenticate successfully but are disconnected within seconds of desktop initialisation and then immediately reconnect, repeating in a loop. Desktop access is effectively unavailable despite valid credentials being accepted.

**Cause**
A graphics driver regression introduced by the overnight host image update caused `dwm.exe` (Desktop Window Manager) to crash in `igdumd64.dll` (Intel graphics component) on session host `SHFIN-01-A` during AVD session initialisation. The crash terminates the compositor before the desktop can be presented to the user, triggering an automatic disconnect.

**Scope**
All users assigned to session host `SHFIN-01-A` in `POOL-FIN-01` are affected. Confirmed affected users: `FINBRIDGE\mlopez` and `FINBRIDGE\akapoor`. Session hosts running the pre-update image (e.g. `SHFIN-02-A` in `POOL-FIN-02`) are unaffected.

**Workaround**
Place `SHFIN-01-A` in drain mode to prevent new sessions landing on it, then move affected users to a healthy session host or known-good pool. Users can work normally once redirected to an unaffected host.

**Permanent Fix**
Roll back `SHFIN-01-A` to the last known-good host image, or redeploy the host from that image if it is non-persistent. Remove or replace the regressed Intel graphics driver in the gold image, validate the corrected image in a pre-production host subset before wider deployment, and confirm clean sign-ins with no Application Error Event 1000 entries before returning the host to service.

**How to Spot It**
Look for Application Error **Event ID 1000** in the Application log with faulting application `dwm.exe` and faulting module `igdumd64.dll`, exception code `0xc0000005`, followed within seconds by TerminalServices-LocalSessionManager **Event ID 40** (session disconnected) and Desktop Window Manager **Event ID 9009** (DWM exited with code `0x40010004`). The sequence repeats on every reconnect attempt and will be absent on healthy session hosts in the same pool.
