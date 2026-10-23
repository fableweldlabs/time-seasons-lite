# Free Lite API — shared clock
All clocks simulate integer game minutes on the main thread. Treat total_minutes as read-only during gameplay. A negative date_at/period_at/season_at argument selects current time.

## Shared FWClock : Node
Exported: profile: FWTimeProfile (optional), periods: FWPeriods, minutes_per_second (0–3600), paused. Starts at absolute minute 480 unless profile overrides it.
profile applies in _ready. apply_profile() deliberately resets the clock to the authored start; do not call after loading a save.
tick(delta) -> bool: validated automatic progression; _process calls it only outside the editor. Fractions are normalized before observers see signals. Rejected ticks don't accumulate a retry backlog.
set_day_length(real_seconds) -> bool: finite >=0.4; speed = 1440/seconds.
advance(minutes) -> bool: 0–5,256,000 per call, absolute minute <=1,000,000,000. No backwards or reentrant advancement. Zero is no-op.
skip_days(days) -> bool: 0–3650 and advance limits. sleep_until(minute_of_day=360) -> bool: next strictly future occurrence, equal time means tomorrow. Explicit operations work while paused.
date_at(value=-1) -> Dictionary: year/month/day one-based; minute 0–1439; day_index zero-based.
period_at(value=-1), season_at(value=-1) -> String.
Signals: time_changed(previous,current), period_changed(final_period), season_changed(final_season), advance_rejected(reason) for rejected automatic ticks.
Period/season signals report the final state only. Lite does not emit a scheduled event for every crossed occurrence.

## FWPeriods / FWTimeProfile
Periods names/starts are matching arrays; first start 0, later starts strictly increasing through 1439. Names nonempty; repeated names allowed. Default Night 00:00, Morning 06:00, Day 12:00, Evening 18:00, Night 22:00.
Profile exports schema_version=1, initial_minute, speed, start_paused, periods, optional Paid calendar/lighting/events/conditions. problems(paid) lists human-readable issues; make_clock() creates an unparented runtime node; condition(id) returns authored condition or null.
Resources are shared. Use separate authored profiles for separate configurations. FWAuthoring.copy() isolates profile data for edit history.


## Forward skips
FWClock.skip_to(hour, minute=0) advances to the next strictly future occurrence. FWClock.advance_hours(hours) rounds to a game minute within the bounded skip limit. Neither operation runs time backwards.

## Edition boundary
Lite does not ship FWWorldClock, custom calendars, event scheduling, persistence, condition rules, lighting drivers or HUD classes. See FEATURE-MATRIX.md for edition scope and INSTALL-UPGRADE.md for replacement instructions.
