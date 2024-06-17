#!/bin/bash

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
else
  echo ".env file not found"
  exit 1
fi

mv packages/*.ipa packages_archive/
make package
package_name=$(ls packages/*.ipa | awk -F'/' '{print $2}')
$THEOS/bin/sideloader-cli-linux-x86_64 install packages/$package_name -i

pymobiledevice3 syslog live | grep -P '.*GearGlimpse.*Foundation.*NOTICE.*'