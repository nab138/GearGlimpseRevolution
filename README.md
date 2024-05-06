# GearGlimpse Revolution

iOS AR Frc tools!

Powered by [theos](https://theos.dev)

# Building & Installation

1. Follow the installation guide from [theos](https://theos.dev)
2. Install the [swift toolchain](https://github.com/kabiroberai/swift-toolchain-linux/) (note that theos's default swift toolchain will not work for this project.
3. Clone the repo, `git clone https://github.com/nab138/GearGlimpseRevolution && cd GearGlimpseRevolution`
4. Run `make package` to build an ipa

If you add the [sideloader cli](https://github.com/Dadoum/Sideloader) to $THEOS/bin, you can run deploy.sh to automatically build and install to your ios device.
