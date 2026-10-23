# Your first useful clock in Free Lite

## Run the included example
1. Extract this ZIP into its own folder.
2. In Godot Project Manager, choose Import and select project.godot at the extracted folder root, beside README.md. The examples folder is not a separate project.
3. Open the project, wait for import to finish, then press F5. This runs the signal example.

## Add Lite to your game
1. Close your game in Godot. Copy only addons/rpg_time into your game's addons folder. Keep your own project.godot.
2. Reopen your game and wait for import. Enable RPG Time & Seasons under Project > Project Settings > Plugins.
3. Open the Time & Seasons dock and its Setup tab. Set the starting day, hour and minute, and real seconds per game day. Click Apply starting time & speed.
4. Save the profile as res://time_seasons/world.tres. Keep authored files outside addons.
5. Set the clock scene path to res://time_seasons/world_clock.tscn and click Create clock scene.
6. Drag that saved scene from FileSystem onto your world root in the Scene tree. Save your world. Creating the file alone does not add it to your running game.

The clock has no visible artwork or HUD in Lite. Use the included examples/lite.gd as a signal-connection reference for your own display or gameplay. You do not need an autoload. Avoid adding duplicate clocks unless you intentionally want independent time sources.

## Choose a useful pace
1200 real seconds gives a 20-minute game day. 24 gives a fast 24-second demonstration. Zero stops automatic progression; explicit skips and the sleep API still work when stopped or paused.
Starting day is absolute and one-based. The fixed calendar has four 28-day seasons and a 112-day year. Day 113 starts Year 2.

## Edit and preview
Periods lets you name time-of-day sections and set their starts. Apply each edit before saving. Save refuses unapplied fields; Revert fields abandons those fields. Undo/Redo affects this profile's edits. Save before closing the editor.
Preview is an isolated sandbox: Play/Pause, skips and Sleep to 06:00 do not modify your running world or save files. Reset restores the authored starting time. Fix validation messages before saving or previewing.

## Troubleshooting
- Empty Import dialog: go up to the extracted root and select project.godot.
- Empty editor scene: F5 runs the included example; the currently open editor tab need not show it.
- Missing dock: wait for import, enable the plugin, then check Output for errors.
- No visible clock in your game: Lite supplies the time source and signals, not a HUD. See the signal example and docs/API.md.
- Time not moving: check Start paused and the day duration, and ensure the generated clock is inside the running world.

## Upgrade or remove
See docs/INSTALL-UPGRADE.md before replacing or removing the addon. Lite and Paid use the same folder and class names; do not install them side by side. Keep your authored profiles and scenes outside the vendor folder.
Paid adds optional HUD, lighting rigs, persistence and custom calendar/schedule features. Those controls are not part of Lite.

Verified target: Godot 4.7.2 on Windows x64. Other versions/platforms are unverified. MIT licensed; see LICENSE.txt. Copyright (c) 2026 Gordon Hinchen.
