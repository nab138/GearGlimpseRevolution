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

1. Follow the installation guide from [theos](https://theos.dev)
2. Install the [swift toolchain](https://github.com/kabiroberai/swift-toolchain-linux/) (note that theos's default swift toolchain will not work for this project).
3. **IMPORTANT**: Follow the instructions here or theos will not build the app correctly. `https://github.com/theos/theos/issues/752#issuecomment-1694531205`
4. Clone the repo, `git clone https://github.com/nab138/GearGlimpseRevolution && cd GearGlimpseRevolution`
5. Run `make package` to build an ipa

If you add the [sideloader cli](https://github.com/Dadoum/Sideloader) to $THEOS/bin, you can run deploy.sh to automatically build and install to your ios device.

# Roadmap

- [x] Basic field placement
- [x] Networktables support
- [x] Robot switching
- [x] Custom robot import
- [x] Transparent/Invisible Field
- [ ] Trajectory Rendering
- [ ] Field Switcher
- [ ] Field Element Placement
- [ ] Mechanism Rendering (maybe)
- [ ] Alignment with real field via AprilTags (in progress)
