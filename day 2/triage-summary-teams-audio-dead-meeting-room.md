# Triage Summary - T-1005

## Summary (one line)
Teams audio is non-functional on three machines in the same meeting room, suggesting a shared room-level audio path or configuration issue (to-verify).

## Impact (who/how many/business urgency)
- Who: Users of one meeting room and their meeting participants.
- How many: At least 3 devices in the same room are affected.
- Business urgency: High for collaboration continuity, especially for scheduled meetings.

## Known Facts
- Ticket ID: T-1005.
- Application: Teams.
- Symptom: Audio dead (input/output to-verify).
- Scope clue: Three machines in one meeting room.

## Missing Information to Gather
- Whether issue is microphone, speaker, or both on each machine.
- Whether same behavior occurs in non-Teams audio tests on those devices (to-verify).
- Shared hardware details: room dock, USB audio device, display hub, or conferencing peripheral model (to-verify).
- Whether issue started after any recent room hardware change/update (to-verify).
- Whether unaffected rooms/devices can run Teams audio normally.
- Whether users are selecting the same incorrect/default device profile (to-verify).

## Likely Category
Meeting room endpoint/peripheral audio configuration fault affecting Teams across multiple local devices (to-verify).

## First Diagnostic Step
Test one affected machine with and without the shared room peripheral chain, then compare Teams device selection and basic audio playback/recording behavior to isolate room hardware path versus endpoint profile issue (to-verify).