# Triage Summary - T-1008

## Summary (one line)
VPN connection succeeds but internal resources are unreachable after Windows 11 upgrade, pointing to post-connect routing, DNS resolution, or policy path issue (to-verify).

## Impact (who/how many/business urgency)
- Who: At least one remote user relying on VPN for internal systems.
- How many: Reported as 1 case so far; broader post-upgrade VPN impact unknown (to-verify).
- Business urgency: High for remote productivity because core internal access is blocked despite successful VPN sign-in.

## Known Facts
- Ticket ID: T-1008.
- Platform change: Windows 11 upgrade occurred before issue.
- Symptom: VPN reports connected.
- Symptom: Internal resources remain unreachable.

## Missing Information to Gather
- Which internal resources fail (file shares, intranet, line-of-business apps, name-based vs IP-based targets) (to-verify).
- Whether any internal destination is reachable at all during VPN session.
- Whether issue is reproducible across different networks/home broadband (to-verify).
- Whether peer users on same VPN profile are unaffected.
- Whether split-tunnel/full-tunnel expectation for this user profile is known (to-verify).
- Whether local firewall/network profile changed during/after upgrade (to-verify).

## Likely Category
Remote access connectivity issue after OS upgrade affecting internal path resolution/reachability (to-verify).

## First Diagnostic Step
Validate scope by testing one known internal destination via both hostname and direct address during an active VPN session to quickly identify whether failure is name resolution, routing, or broader policy enforcement (to-verify).