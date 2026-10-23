# Install, upgrade, disable and uninstall
Back up your own source and saves with your normal version-control/backup system before an upgrade.
Existing project: copy only addons/rpg_time. Do not overwrite your project.godot, input map, main scene or other add-ons with the demonstration project.
Both editions use the same plugin directory and class names. Never install them side by side.

## Lite → Paid
Save the Lite profile outside addons. Disable plugin and close the editor. Replace addons/rpg_time with Paid's folder. Reopen, let classes import, enable plugin.
Load the Lite .tres profile in the dock. Equivalent default calendar/lighting are added, retaining periods, starting minute, speed and pause. Save the upgraded profile. Regenerate the linked clock/rig at its owned path. Lite's generated FWClock scene otherwise stays Lite.
Paid → Lite automatic downgrade is not supported. Paid Resources reference scripts absent in Lite.

## 1.0 → 1.1
The original 1.0 candidate had no plugin.cfg; replace the vendor add-on folder, reopen and enable the new plugin.
Existing direct clock scripts still work. Default period boundaries remain equivalent.
Save schema is now v2. Old schema-1 saves require an explicit call:
migrated = clock.migrate_v1(old_dictionary); then check clock.restore(migrated).
Only default periods and matching calendar are accepted by this helper. You must confirm the original event definitions: schema 1 did not record them. Unknown versions are rejected. Never simply relabel arbitrary saves as v2.

## Paid 1.3.0 to 1.3.1
Close Godot before replacing only addons/rpg_time with the 1.3.1 folder. Keep your authored profiles, generated scenes and save files outside addons. Reopen and allow import to finish. This patch keeps the existing profile/save schemas; regeneration is not required solely for the patch. Check every restore return value. The time host now attempts recovery after a rejected member commit and reports any participant that refuses rollback through last_error; see LIMITATIONS.md for the custom-participant contract.
## Disable/uninstall
Save dock changes first. Disable RPG Time & Seasons in Plugins. Runtime scenes continue working with the add-on installed; the dock is editor-only.
Before removing addons/rpg_time, remove or replace dependent clock/lighting/HUD/sleep nodes and authored FW Resources from your own scenes, scripts and autoloads. Save your own data separately. Deleting the vendor folder while references remain breaks those references.
The plugin does not add autoloads, change existing scene nodes, modify input actions or delete authored profiles. Generated files are outside addons and are yours to retain.