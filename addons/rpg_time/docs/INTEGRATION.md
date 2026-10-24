# Connecting your world

Use the dock to create a clock, then instance it into your world. Keep one authoritative clock per world. The plugin never adds autoloads, input actions or changes to your current scene automatically.

Connect time_changed(previous, current), period_changed(period) and season_changed(season). Always synchronize your initial UI/behavior using period_at(), season_at() and date_at() before waiting for changes. Period and season signals report the final state after a skip; they do not replay every boundary crossed. Do not recursively advance time from the same clock's signal callbacks.

A shop can use period_at() in ["Morning", "Day"] to choose its initial open state and repeat that check when period_changed arrives. The world_clock scene in the separately downloaded optional example project implements this optional behavior and illustrates the changing season. It is a teaching scene, not a built-in shop, game HUD or world-lighting system.

Useful operations: advance(minutes), advance_hours(hours), skip_days(days), skip_to(hour, minute), sleep_until(minute_of_day), paused, minutes_per_second. Time only moves forward. A same-time sleep target advances to tomorrow. A day is 1,440 minutes. A year has 112 days. Four seasons each have 28 days.

Profiles use initial_minute, speed (game minutes per real second), start_paused and periods. The dock shows day length instead of that speed unit: speed = 1440 / real_seconds_per_day. Zero means stopped. Minimum running day length is 0.4 seconds. Use profile.make_clock() only when you intentionally manage your own instances.

Signals are useful for reactions, not persistent event delivery. Lite does not save/load game progress or provide a crossed-event scheduler. Add your own persistence outside the vendor folder if needed.
