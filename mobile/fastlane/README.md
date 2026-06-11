fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Locally build the iOS app and upload to Apple TestFlight

### ios check_testflight_builds

```sh
[bundle exec] fastlane ios check_testflight_builds
```

Check TestFlight builds

----


## Android

### android beta

```sh
[bundle exec] fastlane android beta
```

Locally build the Android app and upload to Google Play Beta Track

### android list_apps

```sh
[bundle exec] fastlane android list_apps
```

List all registered App IDs and bundle identifiers on Apple

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
