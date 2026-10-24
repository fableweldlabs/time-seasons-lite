# Updating safely

Save and back up your own project in version control before updating. Keep profiles, generated clock scenes and game code outside addons/rpg_time. Do not customize vendor files directly; keep your changes in your own scripts/resources.

Disable Time & Seasons in Project Settings > Plugins. Replace only addons/rpg_time with the new release folder, then enable the plugin again. Do not remove your time_seasons folder or other user content. Keep the same vendor folder name; moving script paths can break existing Resources.

This UI refresh retains FWClock, FWTimeProfile, FWPeriods, public signals/methods, core script UIDs and schema_version=1. Existing profiles and generated clock scenes do not need regeneration. Your resource file names remain yours; display names do not rename files. Update your saved profile after applying changed settings. Clock scenes reference that profile.

Read the changelog before each upgrade. Major breaking changes require a migration guide and old-resource/save tests. Never replace a released tag or silently change a versioned package.

Uninstall: remove dependent clock nodes/scenes and references first, disable the plugin, then remove the add-on. Keep any user content you need. Only load Resources from trusted projects.

The editable Lumen Vale project and playable demo are separate optional downloads. They are not required to install or update the addon.
