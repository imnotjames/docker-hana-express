#!/bin/bash
set -e

# Download the manifest file first

if [[ -z "$HANA_VERSION" || "latest" == "$HANA_VERSION" ]]; then
  HXE_IMAGEINFO_URL="${HANA_BASE_URL}HANA2latest/HXEImageInfo.xml"
else
  HXE_IMAGEINFO_URL="${HANA_BASE_URL}$(echo $HANA_VERSION | cut -c1-3)/${HANA_VERSION}/HXEImageInfo.xml"
fi

echo "Fetching Hana ${HANA_VERSION} Manifest from ${HXE_IMAGEINFO_URL}"

HXE_URL=$(
  curl -fs -H "Referer: https://go.sap.com/" "${HXE_IMAGEINFO_URL}" |
    xgrep -t -x '//image[@name="installer"][@platform="linuxx86_64"]/package[@name="server_only"]/source/@url' | \
    sed -rn '/url/ s/.*"(.+)"/\1/p'
)

echo "Downloading Installation Materials from ${HXE_URL}"

curl -fs -H "Referer: https://go.sap.com/" -o /tmp/hxe.tgz "${HXE_URL}"

# Extract the Hana Installation blobs
echo "Extracting Installation Materials..."
mkdir -p /tmp/hxe
tar xzf /tmp/hxe.tgz --no-same-owner --no-same-permissions -C /tmp/hxe/

rm /tmp/hxe.tgz
