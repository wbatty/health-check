# Health Check

An iOS app for a weekly weight check-in: set a goal, read 7-day averages from Apple Health,
lock each week at a scheduled check-in and adjust targets from the trend.

Designs: the "Weekly Check-In" canvas (onboarding steps 1–4 and the weekly loop).

## Setup

Requires Xcode 15.3+ (iOS 17 SDK) and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open HealthCheck.xcodeproj
```

Pick your development team under Signing & Capabilities, then run on a device or simulator.
HealthKit data in the simulator can be added through the Health app.

## Layout

| Path | What's there |
| --- | --- |
| `project.yml` | XcodeGen spec: target, HealthKit entitlement, Info.plist keys |
| `HealthCheck/App` | App entry, `AppModel` (saved plan) |
| `HealthCheck/Onboarding` | The 4-step onboarding flow and its `OnboardingModel` |
| `HealthCheck/Services` | HealthKit reads, check-in notifications |
| `HealthCheck/Design` | Colors, type and shared controls from the design |
| `HealthCheck/Home` | Placeholder "This week" screen |
| `Packages/HealthCheckCore` | Platform-free logic: goal pace, check-in schedule, target math, `Plan` |

## Tests

The core logic runs anywhere Swift does:

```sh
swift test --package-path Packages/HealthCheckCore
```

In Xcode, open `Packages/HealthCheckCore/Package.swift` and press ⌘U.
