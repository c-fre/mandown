# @mandown - Mandown

Arma 3 addon focused on downed-player utility and simple BFT/map improvements.

## Includes

- BFT/map markers for players, groups, and vehicles
- optional downed-player display on BFT
- medical markers for downed players
- multiline or comma-delimited vehicle name labels
- map access while unconscious
- optional speaking while unconscious
- nearby 2D down alerts using the downed player's selected sound

## Dependencies

- `CBA_A3`
- `ACE3`

## Settings

Mandown uses CBA Settings. Shared settings can be overridden by the server or mission when Mandown is loaded as a regular server `-mod`.

### Shared

`Mandown > BFT Ext.`

- `Enable BFT`
- `BFT update interval (seconds)`
- `BFT display mode`
- `Vehicle name format`
- `Show downed players on BFT`
- `Show all downed players in leader-only mode`

`Mandown > Utilities`

- `Allow downed players to speak`
- `Allow map access while unconscious`
- `Down alert range (km)`

### Client

`Mandown > Utilities`

- `Down sound`
- `Receive down alerts`
- `Down alert volume`

## Notes

- In `All players` mode, players in the same vehicle share one marker.
- Downed on-foot players use a medical marker, turn red, and blink.
- Vehicle markers with downed occupants stay as vehicle markers and turn red.
- If `Show downed players on BFT` is disabled, unconscious players are shown like healthy players.
- Down alerts are local 2D playback and do not use TFAR radio transmission.
