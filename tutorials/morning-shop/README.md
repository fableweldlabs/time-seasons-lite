# Open a shop with Free Lite's morning signal

This optional tutorial uses Time & Seasons Free Lite 1.3.3. The shop controller, buttons and display are example code, not built-in Lite features. The original 1.3.3 release ZIP contains the simpler text signal example; this tutorial is a separate addition to the GitHub main branch.

Verified target: Godot 4.7.2 on Windows x64. MIT license, Copyright (c) 2026 Gordon Hinchen, under this repository's LICENSE. No Paid addon is required.

![Morning opens the tutorial shop; Evening closes it](https://img.itch.zone/aW1hZ2UvNTIxNDc3My8zMTI2Nzk4OS5naWY=/original/oWSSSr.gif)

24-second recording of real Godot viewport output. The timeline uses deterministic clock API calls for capture; the scene runs automatically when played normally.

## Run the example

1. Download the repository's current **main** branch ZIP, extract it and import its root `project.godot`. For the original packaged addon, use [itch.io](https://fableweld-labs.itch.io/time-seasons-free-lite).
2. Open `tutorials/morning-shop/morning_shop.tscn` and press **F6** to run this scene. F5 still runs the original text example.
3. The clock starts at Spring day 28, 05:50. At its configured speed, one game hour passes per real second. Watch the sign change to OPEN at 06:00.
4. Use **Pause / resume**, **Next morning**, **Next evening** and **Skip 1 day** to try different clock states. Default periods keep the shop open from 06:00 until 18:00. Skipping a day from Spring 28 reaches Summer 1.

The clock starts paused only in automated tests, not in this interactive scene. Skips are strictly forward: choosing Next morning at 06:00 goes to tomorrow's 06:00.

## Connect it to your own project

Copy `addons/rpg_time` from Free Lite into your project and enable the plugin. Keep your existing `project.godot`. Copy `shop_controller.gd` into your own example folder; change preload paths if you move files.

Create and parent the clock before binding the shop. A clock with a profile applies that profile in `_ready()`, so reading its state too early can show the wrong starting time.

```gdscript
const ShopController = preload("res://tutorials/morning-shop/shop_controller.gd")
var clock: FWClock
var shop: Node

func _ready() -> void:
    var profile := FWTimeProfile.new()
    profile.initial_minute = 350 # 05:50 on Spring day 1.
    profile.speed = 1.0
    clock = profile.make_clock()
    assert(clock != null)
    add_child(clock)

    shop = ShopController.new()
    add_child(shop)
    shop.shop_state_changed.connect(_on_shop_state_changed)
    shop.bind_clock(clock)
    _on_shop_state_changed(shop.is_open) # Initialize your own UI too.

func _on_shop_state_changed(is_open: bool) -> void:
    print("Shop open: ", is_open)
    # Update your interaction area, sign or dialogue here.
```

`shop_controller.gd` connects to the real `clock.period_changed` signal and calls its handler once when binding:

```gdscript
func _on_period_changed(period: String) -> void:
    _set_open(period in ["Morning", "Day"])
```

That initial synchronization matters when loading a scene at noon, after Morning's signal has already happened. The controller disconnects its old clock when rebound and emits `shop_state_changed` only when the open/closed state actually changes.

## Periods and time skips

Default periods are Night at 00:00, Morning at 06:00, Day at 12:00, Evening at 18:00 and Night at 22:00. If you rename or redefine periods, update the shop's allowed names as well. This is a period-based rule, not a hard-coded hours scheduler.

Lite's period and season signals report the **final state**, not every boundary crossed. A jump from one Night to another Night does not replay the intervening Morning. The shop remains correctly closed at the destination, but this tutorial does not process missed business transactions or scheduled events. A full-day skip that ends in the same open period leaves the shop open without an extra state-change signal.

Do not call `advance()` or other skips from inside the clock's signal callbacks: advancement is non-reentrant. Queue a deferred operation if your own game needs a subsequent skip.

This example does not implement save/load, inventories, buying/selling, NPC schedules, lighting or a complete game HUD. Those behaviors belong to your game or a separate system.

## Verify the controller

From the repository root, with Godot available:

```text
godot --headless --path . --script tutorials/morning-shop/tests.gd
```

The focused checks cover startup state, Morning/Day/Evening transitions, day skips, immediate synchronization after rebinding, old-clock disconnection and unbinding. They do not establish support for other Godot versions or platforms.

[Free download](https://fableweld-labs.itch.io/time-seasons-free-lite) | [Lite API](../../docs/API.md) | [Bug reports](https://github.com/fableweldlabs/time-seasons-lite/issues)

