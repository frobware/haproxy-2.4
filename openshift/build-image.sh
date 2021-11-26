#!/usr/bin/env bash

set -u
set -o pipefail
set -o errexit

thisdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

: "${REGISTRY:=quay.io}"
: "${REGISTRY_USERNAME:=amcdermo}"
: "${IMAGENAME:=openshift-router}"

dockerfile=
push_image=0
dry_run=""
ocpver=

PARAMS=""
while (( "$#" )); do
    case "$1" in
	-o|--ocp-version)
	    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
		ocpver=$2
		shift 2
	    else
		echo "error: Argument for $1 is missing" >&2
		exit 1
	    fi
	    ;;
	-p|--push-image)
	    push_image=1
	    shift
	    ;;
	-n|--dry-run)
	    dry_run="echo"
	    shift
	    ;;
	-.|--.=)
	echo "error: Unsupported flag $1" >&2
	exit 1
	;;
	*) # preserve positional arguments
	    PARAMS="$PARAMS $1"
	    shift
	    ;;
    esac
done

if [[ -z "${ocpver}" ]]; then
    echo "no OCP version specified (e.g., --ocp-version 4.8)."
    exit 1
fi

dockerfile="$thisdir/Dockerfile.$ocpver"

: "${TAGNAME:=ocp-${ocpver}-haproxy-$(git describe --tags --abbrev=0)}"

# reset positional arguments
eval set -- "$PARAMS"

$dry_run rm -f haproxy
$dry_run toolbox run --container haproxy-builder-ubi8 "${thisdir}/build-haproxy-with-openshift-settings.sh"

if [ ! -x ./haproxy ]; then
    echo "error: no haproxy binary."
    $dry_run exit 1
fi

$dry_run podman build -t "${REGISTRY_USERNAME}/${IMAGENAME}:${TAGNAME}" -f "$dockerfile" .

if [[ $push_image -eq 1 ]]; then
    $dry_run podman tag "${REGISTRY_USERNAME}/${IMAGENAME}:${TAGNAME}" "${REGISTRY}/${REGISTRY_USERNAME}/${IMAGENAME}:${TAGNAME}"
    $dry_run podman push "${REGISTRY}/${REGISTRY_USERNAME}/${IMAGENAME}:${TAGNAME}"
fi
