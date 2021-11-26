#!/usr/bin/env bash

# Copied from: https://blog.mosibi.nl/all/2020/10/04/ubi-toolbox.html

NAME=$1
VERSION=${2:-'latest'}

if [ -z "${NAME}" ]; then
    echo "Usage: $0 <container-name>"
    echo " "
    echo "Example: $0 ubi:8.2-mosibi"
    exit 0
fi

CONTAINER=$(buildah from  registry.access.redhat.com/ubi8/ubi:${VERSION})
buildah run "${CONTAINER}" dnf -y install sudo less vim python3
buildah config --label com.github.{CONTAINER}s.toolbox="true" "${CONTAINER}"
buildah config --label com.github.debarshiray.toolbox="true" "${CONTAINER}"

TEMPFILE=$(mktemp)
echo 'alias __vte_prompt_command=/bin/true' > "${TEMPFILE}"
buildah copy "${CONTAINER}" "${TEMPFILE}" '/etc/profile.d/vte.sh'
buildah run "${CONTAINER}" chmod 755 /etc/profile.d/vte.sh
rm "${TEMPFILE}"

buildah commit "${CONTAINER}" "${NAME}"

echo "Container ${NAME} is created"
echo "With the following you can make changes to container ${NAME}"
echo "buildah run ${CONTAINER} <command>"
echo "buildah commit ${CONTAINER} ${NAME}"
