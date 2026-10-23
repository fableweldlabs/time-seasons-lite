# Release decision

Status: **advanced local candidate**. The frozen 1.3.0 archives and separately validated 1.3.1 replacement candidates are not approved for commercial publication.

## Automated implementation evidence — passed on the verified target

The current package includes custom calendars, weeks and event days; multiple clocks and registered state; aging/growth; event reactions, bounded outcomes, and reusable signal routing; date-change publisher; displays, direct speed controls, and composable pacing layers; 2D/3D lighting and sleep; guide-driven editor setup; schedule explanation/conflict preview; clean Lite/Paid installation and actual upgrade coverage. The frozen 1.3.0 run recorded 573 named checks. The 1.3.1 replacement package run recorded 588 checks with zero failures on Godot 4.7.2 Windows x64, covering fresh installs, Lite-to-Paid upgrade, lifecycle and exported PCK runtime. Exact candidate hashes and verification scope are recorded outside the archives in evidence/candidate-package-validation.json. A separate 17-check workflow also verifies frozen Paid 1.3.0 authored content/save compatibility and dependency-aware uninstall. A documentation-only archive refresh verifies unchanged code/resource entries against those tested archives; its hash mapping is recorded in evidence/documentation-refresh.json.

## Engineering versus visual acceptance

Automated testing is engineering evidence. The separate visual/release task owns visual acceptance preparation, listing media, seller/legal/support/payment/tax decisions, private previews, and publication. It may return concrete UI findings for engineering to fix. Visual review does not block continuing source development.

Independent code review and timed unfamiliar-developer onboarding are optional future evidence activities. They are not release gates, are not required for continued implementation, and have not been performed.

## Owner/account requirements before publication

- Approve legal seller identity, Lite/Paid license terms, provenance/AI disclosure, support contact, refund wording and price.
- Configure itch.io seller, payment and tax settings; upload the chosen validated archives; inspect a private listing preview; explicitly authorize publication.

No account changes, uploads or publication are authorized by this repository work.
