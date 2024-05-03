#!/bin/bash

mv packages/*.ipa packages_archive/
make clean package
package_name=$(ls packages/*.ipa | awk -F'/' '{print $2}')
$THEOS/bin/sideloader-cli-linux-x86_64 install packages/$package_name -i