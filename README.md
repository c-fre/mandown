# @mandown - Mandown

Arma 3 all rounder mod for out private server that allows down alerting and lighter BFT settings for more fun, less tac-sim.

When a player is downed, the mod:

- Can show them through the Mandown BFT marker system with ACE-style marker text sizing
- Allows local voice & map to be used when downed
- Plays a configurable radio alert sound over TFAR when supported

Gameplay settings can be shared by the server or mission through CBA Settings when Mandown is loaded as a regular server `-mod`. The down-sound choice remains a per-player preference via `ESC -> Options -> Addon Options -> Mandown`.

## BFT settings

Mandown now uses one unified local marker pipeline for both normal BFT tracking and downed-player markers. Marker labels are standard `createMarkerLocal` / `setMarkerTextLocal` labels so they inherit the same map text sizing style as ACE BFT.

Shared CBA settings under `Mandown > BFT Ext.`:

- `Enable BFT`
- `BFT update interval (seconds)`
- `BFT display mode`
  - `All players`
  - `Leaders only`
- `Vehicle name format`
  - `New line per player`
  - `Comma delimited`
- `Show all downed players in leader-only mode`

Behavior notes:

- When BFT is disabled, Mandown does not show normal or downed BFT markers.
- In `All players` mode, players in the same vehicle share one marker and downed occupants are labeled as `NAME - DOWNED`.
- Vehicle markers with downed occupants turn red but do not flash.
- Individual on-foot downed markers flash on a short interval.
- In `Leaders only` mode, healthy groups use the leader/group marker, and you can optionally expose all downed non-leaders with individual markers.

**Dependencies:** CBA_A3, ACE3  
**Optional:** TFAR (Task Force Arrowhead Radio) - Mandown only plays down sounds when a supported TFAR radio path is available

### NOTE

This is my first attempt at a A3 addon & is mostly vibe-coded. Improvements and feedback appreciated!
