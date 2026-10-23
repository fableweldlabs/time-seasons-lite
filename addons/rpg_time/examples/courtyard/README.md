# Lumen Vale — a tiny Time & Seasons showcase

One traversable, original 3D courtyard. Open main.tscn in Godot and press F6. Verified target: Godot 4.7.2 Windows x64. Viewport target: 1920×1080, Compatibility renderer with 4× MSAA. No engine or third-party asset pack is bundled.

Move with WASD or arrow keys. Press E near the market to visit, or near the bench to rest until morning. Escape opens help or closes the market. Buttons advance to morning, change seasons, and pause/play time. Market hours follow Morning + Day in the real Lite clock. Sleeping changes the clock; the garden and lanterns follow the resulting state.

All buildings, traveler parts, trees, garden props, water, materials and interactions are generated from original code. No downloaded art, prebuilt character, animation pack, music or sound is used. The character uses a simple original walking animation. Standard Godot UI/font facilities are used; no external font is bundled.

This is a showcase, not a complete RPG: no combat, inventory, quests, indoor levels or save-game system. The weather-like particles are cosmetic petals/snow, not a weather simulation. Lighting, scenery, shop behavior and the walking controller are separate example code, not built-in Lite features. The Lite clock/core API remains unchanged. Starter adds reusable authoring/integration workflows rather than a claim that this custom example code is automatic.

MIT license, as in ../../LICENSE. Copyright (c) 2026 Gordon Hinchen. Published under Fableweld Labs. Keep changes to your own project outside the vendor folder if you want painless add-on updates.

Watch a short tour uses the same walking physics and clock interactions, then returns control. It resets this disposable showcase to a Spring morning. Escape cancels the tour. A Windows demo build is also supplied separately; the editor add-on ZIP remains add-on-only.
