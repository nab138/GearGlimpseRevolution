# GearGlimpse Revolution

[![Build GearGlimpseRevolution](https://github.com/nab138/GearGlimpseRevolution/actions/workflows/ci.yml/badge.svg)](https://github.com/nab138/GearGlimpseRevolution/actions/workflows/ci.yml)

iOS AR Frc tools!

Powered by [theos](https://theos.dev)

# Installation

To install on an iDevice, download the ipa from the latest [release](https://github.com/nab138/GearGlimpseRevolution/releases/latest) or [actions run](https://github.com/nab138/GearGlimpseRevolution/actions) for the bleeding edge.

You can use sideloaders such as [sidestore](https://sidestore.io), [sideloader](https://github.com/Dadoum/Sideloader), [altstore](https://altstore.io), etc to install the ipa.

# Usage

Tap on a plane to place the field, pinch and twist to scale and rotate. You may have to move the phone around a bit before the field will be placeable.

To connect the app to networktables, press and hold to open the configuration menu.

To import a custom robot, convert it to a .usdz file, then you can import it from the configuration menu.

# Development

1. Follow the installation guide from [theos](https://theos.dev) (doesn't matter what toolchain you pick, you will be replacing it anyways)
2. Download the correct [swift toolchain](https://github.com/kabiroberai/swift-toolchain-linux/releases/latest) (note that theos's default swift toolchain will not work for this project). Yes, that is the correct link on windows as well. Extract it to $THEOS/toolchain (make sure $THEOS/toolchain is empty before extracting, delete any files in there if necessary)
3. Follow [these instructions](https://github.com/theos/theos/issues/752#issuecomment-1694531205) or theos will not build the app correctly.
4. Download the [required frameworks](https://visp-doc.inria.fr/download/snapshot/ios/visp3.framework-2022-04-07.zip) and extract them into $THEOS/lib
5. Clone the repo, `git clone https://github.com/nab138/GearGlimpseRevolution && cd GearGlimpseRevolution`
6. Download the [required assets](https://github.com/nab138/GearGlimpseRevolution/releases/tag/assets-v2) and place them in the "Resources" folder
7. Run `make package` to build an ipa

If you add the [sideloader cli](https://github.com/Dadoum/Sideloader) to $THEOS/bin, you can run deploy.sh to automatically build and install to your ios device.

## Current Features

- [x] Basic field placement
- [x] Field Scaling & Rotation
- [x] Transparent/Invisible Field
- [x] Networktables support for robot position (Sim or real robot)
- [x] Robot switching
- [x] Custom robot import
- [x] Built-in configuration options (long press to access)
- [x] AprilTag Detector (unstable, and doesn't do anything right now
- [x] Command Scheduler Display
- [x] FMS state info display (enabled, mode, alliance, etc)
- [x] Trajectory Rendering

## In progress features

Features that are being worked on. Features with a checkmark are in a working state, but aren't included in the latest release yet and may not be stable.

- [ ] Alignment with real field via AprilTags

## Planned Features (in no particular order)

- [ ] Field Switcher
- [ ] Field Element Placement
- [ ] Mechanism Rendering (maybe)

## Credits

- [2024 Field Model](https://cad.onshape.com/documents/dcbe49ce579f6342435bc298/w/b93673f5b2ec9c9bdcfec487)
- [2024 KitBot Model](https://firstfrc.blob.core.windows.net/frc2024/KitBot/KitBot%20CAD%20and%20Drawings.zip)
- [ViSP (for apriltags)](https://visp.inria.fr/)
- [ViSP example project (for apriltag overlays)](https://github.com/lagadic/visp/tree/master/tutorial/ios/AprilTagLiveCamera)

Theos does not currently support installing spm packages/pods, so the following libraries are part of the source tree but were NOT written by me:

- [Starscream (websockets)](https://github.com/daltoniam/Starscream)
- [SwiftMsgPack](https://github.com/malcommac/SwiftMsgPack)
- [SceneKit-SCNLine](https://github.com/maxxfrazer/SceneKit-SCNLine)
