#!/usr/bin/env bash

# This script will replicate the given image into all Azure regions. It needs
# to be run in an environment where the azure-xplat-cli has been installed and
# configured with the production credentials and (optionally) SUBSCRIPTION_ID
# is defined, containing the subscription GUID.

DIR=$(dirname $0)
. $DIR/common.sh

set -e

GROUP="${1^}"
VERSION=$2

if [[ -z $GROUP || -z $VERSION ]]; then
	echo "Usage: $0 <group> <version>"
	exit 2
fi

image_name="CoreOS-${GROUP}-${VERSION}"

subscription_id=$SUBSCRIPTION_ID
if [ -z $subscription_id ]; then
	subscription_id=$(getSubscriptionId)
fi

url="$(getManagementEndpoint)/${subscription_id}/services/images/${image_name}/share?permission=public"

workdir=$(mktemp --directory)
trap "rm --force --recursive ${workdir}" SIGINT SIGTERM EXIT

azure account cert export \
	--file="${workdir}/cert" \
	--subscription="${subscription_id}" > /dev/null

result=$(curl \
	--silent \
	--request PUT \
	--header "x-ms-version: 2014-10-01" \
	--header "Content-Type: application/xml" \
	--header "Content-Length: 0" \
	--cert "${workdir}/cert" \
	--url "${url}" \
	--write-out "%{http_code}" \
	--output "${workdir}/out")

if [[ $result != 200 ]]; then
	echo "${result} - $(< ${workdir}/out)"
	exit 1
fi
