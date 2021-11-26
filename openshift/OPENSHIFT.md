# Augment openshift-router image with new haproxy build

The additional scripts in this directory facilitate building a new
version of `haproxy` and inserting that new `haproxy` binary into in
an existing openshift-router image.

## Setup local container to build haproxy from source

### Build base image

	$ ./toolbox-ubi.sh ubi8-$(id -un)

### Create haproxy-builder container for toolbox(1)

	$ toolbox create --container haproxy-builder-ubi8 --image localhost/ubi8-$(id -un)

### Add prerequisites for haproxy build to new container image

	$ toolbox run --container haproxy-builder-ubi8 sudo yum update -y
	$ toolbox run --container haproxy-builder-ubi8 sudo yum --disableplugin=subscription-manager install -y wget gcc make openssl-devel pcre-devel zlib-devel diffutils

## Building haproxy and updating an OCP image

Once the `haproxy-builder-ubi8` build container has been created you
can repeatedly rebuild `haproxy` and optionally push the augmented
image to a registry.

	$ ./build-image.sh --ocp-version 4.10 [ --push-image ] [ --dry-run ]

### Example session

	$ REGISTRY_USERNAME=amcdermo IMAGENAME=openshift-router-perscale ./build-image.sh --ocp-version 4.10 --push-image --dry-run
	rm -f haproxy
	toolbox run --container haproxy-builder-ubi8 /home/aim/src/github.com/frobware/haproxy-2.4/build-haproxy-with-openshift-settings.sh
	podman build -t amcdermo/openshift-router-perfscale:ocp-4.10-haproxy-v2.4.9 -f /home/aim/src/github.com/frobware/haproxy-2.4/Dockerfile.4.10 .
	podman tag amcdermo/openshift-router-perfscale:ocp-4.10-haproxy-v2.4.9 quay.io/amcdermo/openshift-router-perfscale:ocp-4.10-haproxy-v2.4.9
	podman push quay.io/amcdermo/openshift-router-perfscale:ocp-4.10-haproxy-v2.4.9

## Building haproxy within the toolbox

Alternatively, you can repeatedly build the `haproxy` binary without
injecting it into an image:

	$ toolbox run --container haproxy-builder-ubi8 ./build-haproxy-with-openshift-settings.sh
