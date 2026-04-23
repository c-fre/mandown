# @mandown

Coop-focused Arma 3 addon for adding lightweight BFT tracking for all players and features to make going unconscious more bearable.

## Includes

- BFT/Map Markers for Players, Groups, and Vehicles
- Optional Downed-Player Display on BFT
- Medical Markers for Downed Players
- Multiline or Comma-Delimited Vehicle Name Labels
- Map Access While Unconscious
- Downed Hover Camera via the User's Toggle View Key, with Bound Zoom In/Out Controls
- Optional Speaking While Unconscious
- Nearby 2D Down Alerts Using the Downed Player's Selected Sound

## Dependencies

- `CBA_A3`
- `ACE3`

## Settings

Mandown uses CBA Settings. Shared settings can be overridden by the server or mission when Mandown is loaded as a regular server `-mod`.

### BFT

- `Enable BFT`
- `BFT update interval (seconds)`
- `BFT display mode`
- `Vehicle name format`
- `Show downed players on BFT`
- `Show all downed players in leader-only mode`

### Utilities

- `Allow downed players to speak`
- `Allow map access while unconscious`
- `Allow downed hover camera`
- `Down alert range (km)`
- `Down sound`
- `Receive down alerts`
- `Down alert audience`
- `Down alert volume`

## Notes

- In `All players` mode, players in the same vehicle share one marker.
- Downed on-foot players use a medical marker, turn red, and blink.
- Vehicle markers with downed occupants stay as vehicle markers and turn red.
- If `Show downed players on BFT` is disabled, unconscious players are shown like healthy players.
- Downed map access uses the player's bound map key.
- The downed hover camera uses the player's bound Toggle View key, stays fixed above the body, and supports the player's bound Zoom In/Out controls.
- Down alerts are local 2D playback and do not use TFAR radio transmission.
- Each client can choose whether down alerts are heard from their group/squad only or all players on the same side.

### NOTE

This is my first attempt at a A3 addon & is mostly vibe-coded. Improvements and feedback appreciated!
