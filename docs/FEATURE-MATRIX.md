# Editions
| Feature | Free Lite | Paid |
|---|---|---|
| Shared clock, pause, speed/day length, sleep/skip APIs | Yes | Yes |
| Editable day periods and final-state signals | Yes | Yes |
| Four fixed seasons / 112-day calendar | Yes | Yes |
| Plugin dock, guided profile setup, isolated preview, local Undo/Redo | Yes | Yes |
| Custom months/seasons and 365-day preset | No | Yes |
| Custom week names, event days, calendar-aware date formatting | No | Yes |
| Multiple registered clocks and age trackers with host save support | No | Yes |
| Scheduled events and skipped-occurrence delivery | No | Yes |
| Seasonal shop/NPC conditions and encounter weights | No | Yes |
| Bounded schedule diagnostic: exact rule explanation, sampled overlap and declared owner/group conflict reporting | No | Yes |
| Included standalone save/load and explicit v1 migration | No | Yes |
| Basic 2D tint / 3D sun and ambient / linked rigs | No | Yes |
| HUD, month calendar, dial, speed/progress controls, sleep button/2D zone, 2D/3D examples | No | Yes |
| Lite signal integration example | Yes | Yes |

No feature-count superiority claim. Choice depends on the buyer's needs. Exact Godot 4.7.2 Windows x64 tested; visual/manual release gates remain.

## 1.3 advanced authoring conveniences
Paid adds calendar-aware display components, multi-clock hosting, registered age/state persistence, explicit time pacing, a named signal bus, and bounded schedule diagnostics. The diagnostic samples only the requested interval; it reports every sampled overlap separately from a declared conflict, which requires matching nonempty owner IDs or exclusive groups. It refuses requests above 4,096 rows or 65,536 rule samples rather than allocating unbounded preview output. Lite receives clearer dock section navigation and styling; paid-only runtime/UI files remain excluded. No private third-party event-bus compatibility is implied.
