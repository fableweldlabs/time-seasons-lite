# Time & Seasons Lite
A free, MIT-licensed Godot world clock by Fableweld Labs. Copyright (c) 2026 Gordon Hinchen.

## Choose your download

**Only Time & Seasons Lite — Addon Only is needed to use the tool.** Lumen Vale — Editable Example Project and Lumen Vale — Playable Windows Demo are optional separate downloads. You can skip both. The addon contains no example-game assets and works independently.

## Install
Copy addons/rpg_time into an existing Godot project. Enable Time & Seasons in Project > Project Settings > Plugins. Use the Time & Seasons dock on the right.

1. Set up your world: choose a starting day/time and the real seconds in each game day. Apply settings.
2. Save world settings with the file picker. Keep them outside addons.
3. Create your clock with the file picker, then drag that scene from FileSystem into your world.
4. Shape the day to rename periods or change their start times. Apply and save again.
5. Try your clock in the safe preview; it never changes the saved world.

The calendar has four fixed 28-day seasons: Spring, Summer, Autumn and Winter. Periods and seasons expose signals for your game code. No ready-made game HUD, world lighting, scheduler, weather system or save-game integration is included. The illustrated village/shop is an optional learning example, not an automatic integration.

To explore Lumen Vale, download the optional Editable Example Project, extract it to a separate folder, import its project.godot into Godot and press F5. Its included addon is for that standalone project; do not copy the example into your game. The optional project also contains the smaller world_clock.tscn learning scene. For integration details see docs/INTEGRATION.md. For updates see docs/UPDATING.md. LICENSE contains the MIT terms.

Tested target: Godot 4.7.2, Windows x64. Other targets are not claimed as verified.

Website: https://fableweld-labs.itch.io/time-seasons-free-lite
Docs, source and bug reports: https://github.com/fableweldlabs/time-seasons-lite

## Languages / Idiomas / 语言 / 言語 / Langues / Sprachen

Choose Language in the addon dock: English, Español, Português (Brasil), 简体中文, 日本語, Français, Deutsch, Polski, 한국어, 繁體中文, Türkçe or Українська. Only this addon’s interface changes. Customer period names, API identifiers and saved resources remain unchanged. Native Godot dialogs follow the editor’s language. Unknown text falls back to English.

[Español](docs/QUICKSTART.es.md) · [Português (Brasil)](docs/QUICKSTART.pt_BR.md) · [简体中文](docs/QUICKSTART.zh_CN.md) · [日本語](docs/QUICKSTART.ja.md) · [Français](docs/QUICKSTART.fr.md) · [Deutsch](docs/QUICKSTART.de.md) · [Polski](docs/QUICKSTART.pl.md) · [한국어](docs/QUICKSTART.ko.md) · [繁體中文](docs/QUICKSTART.zh_TW.md) · [Türkçe](docs/QUICKSTART.tr.md) · [Українська](docs/QUICKSTART.uk.md)

Translations are AI-assisted and have not had independent native-speaker review. Please report wording issues on GitHub. The optional Lumen Vale game also supports these languages, including dialogue, prompts and signs, with localized place names. Choose a language in its top-left selector. The English MIT license is authoritative; API reference remains in English.

## Version 2.2.0

Adds Polish, Korean, Traditional Chinese, Turkish and Ukrainian across the interface, quick starts and optional example. Formatted status-message patterns are now compiled once per language change rather than once per message. Core clock behavior and existing profile formats are unchanged.
