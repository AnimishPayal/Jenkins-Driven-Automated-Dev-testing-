#!/bin/sh

__VERSION__='25.6.0.1.1'
__UPDATED__='2025.06.11'
__AUTHOR__='Ian Reid'
__MAINTAINER__='Ian Reid, Gustavo Cavallin'

  
main() {

echo HOME $HOME

if [ $HOME == '' ]; then
  HOME=/home/iareid
  echo WARNING Needed to fix Home
fi

export VERSION="${__VERSION__}.LOCAL"
if [ "$1" != "" ]; then
    #mkdir -p GIT2
    pwd
    #exit
    if [ "$2" != "" ]; then
       export VERSION="$2"
    fi
fi


# The following are paths in the users home
local_GIT=${HOME}/GIT/
local_MW_TOOLS=${HOME}/GIT/CMOS_TOOLS/
local_mw_container=${local_MW_TOOLS}mw_container/
local_input_files=${HOME}/adx/input_files/
local_MW_COMMON=${local_mw_container}MW_COMMON/ # ${local_GIT}SW_MW_EXECUTABLES/MW_COMMON/
local_TESTING=${local_mw_container}MW_COMMON/
local_SW_MW_XML=${local_GIT}SW_MW_DBUTIL_XML/
local_FV_JAVA=${local_GIT}SW_DBUTIL_JAVA/

echo ""
echo "#### Display ####"
echo "local_GIT: $local_GIT"
echo "local_MW_TOOLS: $local_MW_TOOLS"
echo "local_mw_container: $local_mw_container"
echo "local_input_files: $local_input_files"
echo "local_MW_COMMON: $local_MW_COMMON"
echo "local_TESTING: $local_TESTING"
echo "local_SW_MW_XML: $local_SW_MW_XML"
echo "local_FV_JAVA: $local_FV_JAVA"
echo ""


#::rem imageName=gcsdev-oci-docker-local.dockerhub-phx.oci.oraclecorp.com/dxf/base_images/dev/dx-perl-python-base
imageName="dx-perl-python-base"    # Same image we have in UAT and PROD. June 2025
#imageName="dx-java-python-base"   # <- in use Jan 2025
#imageName="dx-java-python-perl-base"  # Needed for RDA Extract. May 2025

# The following are path/env in the container
export SW_MW=/autodx/sw_tools/SW_MW/
#export DXF_BOUNDARY=/autodx/common_services/boundary_services/
export MW_TOOLS=${SW_MW}MW_TOOLS
export MW_COMMON=${SW_MW}MW_COMMON
#export MW_SERVICE=${SW_MW}MW_SERVICE
export DXF_CONTAINER=PODMAN
export DXF_IMAGE=${imageName}
export AD_MODE=DX_UAT
export JOB_ID=dx_1034828_1604428385686
export INPUT_FILE=${local_input_files}dx_1034828_1604428385686_input.xml
export TEST_FILE_PATH=/sr
ENV_FILE=${local_mw_container}env-DX_UAT.txt


echo "VERSION: $VERSION - Last update: $__UPDATED__"
export VERSION_DATE="$VERSION.$(date '+%d%H%M')"
echo "VERSION_DATE: $VERSION_DATE"

# the following is used to pass in default values is input json is missing or masking them. Used in UAT only.
export DXF_C_ID='3c71f85e543344bc91765739a0a498f9'
# new key Fen 2025 - 16351494-cc21-40d2-a791-40d9744ecc8c
# old export DXF_C_KEY='a91f5ece-97ce-4f83-b6f4-ed4f95742e61'
export DXF_C_KEY='16351494-cc21-40d2-a791-40d9744ecc8c'


containerName="mw_test"
devID="mw_dev"

echo ""
echo "#### Configuration ####"
echo ""

podman tag ${imageName} ${devID}
echo "NOTICE: ignore error on next command on first run."
imageID=$(podman inspect --format "{{.Id}}" ${imageName})
echo "imageName = ${imageName}  -  imageID = ${imageID}"


#command_mount
command_cp $*
#command_nothing

echo ""
echo "#### DONE ####"
echo ""

}


command_cp() {

#### SETUP and STARTUP STAGE ####

# start the container
#containerID=$(podman run --name ${containerName} -dt ${imageName})
containerID=$(podman --storage-opt ignore_chown_errors=true run --env-file ${ENV_FILE} -dt ${imageName} /bin/bash)
echo containerID = ${containerID}

# Create the paths for code
echo "podman: creating the paths inside the container"
# skipping ${MW_SERVICE} ${DXF_BOUNDARY}
podman exec -d -l mkdir -p ${SW_MW} ${HOME}/adx/ /autodx/logs/ ${TEST_FILE_PATH}

#### COPY STAGE ####
echo ""
echo "#### Copying ####"
echo ""

# Copy the entry script
if [ -d "${local_mw_container}entry/" ]; then
    podman cp ${local_mw_container}entry/ ${containerID}:${SW_MW}
    echo "podman cp ${local_mw_container}entry/"
else
    echo "ERROR: ${local_mw_container}entry/ missing"
fi


# Copy the test files (for OPatch Summary and other tools)
if [ -d "${HOME}/adx/test_files/" ]; then
    podman cp ${HOME}/adx/test_files/. ${containerID}:${TEST_FILE_PATH}
    echo "podman cp ${TEST_FILE_PATH}"
else
    echo "WARNING: ${HOME}/adx/test_files missing"
fi


# Copy the history to root
if [ -d "${local_mw_container}root/" ]; then
    podman cp ${local_mw_container}root/ ${containerID}:/
    echo "podman cp ${local_mw_container}root/"
else
    echo "ERROR: ${local_mw_container}root/ missing"
fi


# Copy the MW_TOOLS
if [ -d "${local_MW_TOOLS}" ]; then
    podman cp ${local_MW_TOOLS} ${containerID}:${MW_TOOLS}
    echo "podman cp ${local_MW_TOOLS}"
else
    echo "ERROR: ${local_MW_TOOLS} missing"
fi


# Copy the MW_COMMON code
if [ -d "${local_MW_COMMON}" ]; then
    podman cp ${local_MW_COMMON} ${containerID}:${SW_MW}
    echo "podman cp ${local_MW_COMMON}"
else
    echo "ERROR: ${local_MW_COMMON} missing"
fi

# Copy the users input files
if [ -d "${local_input_files}" ]; then
    podman cp ${local_input_files} ${containerID}:${HOME}/adx/
    echo "podman cp ${local_input_files}"
else
    echo "ERROR: ${local_input_files} missing"
fi

# Copy the container input files
if [ -d "${local_mw_container}tests/" ]; then
 #   podman cp ${local_mw_container}tests/ ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/input1-Oct2022.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/input2-Oct2022.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/sr_headers_sample_input.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1053459_1666721223184.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1014627_1675703512088.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/input3-Oct2022.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1020325_1678371646758.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1003265_1679939620845.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1002013_1682472381625.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1048409_1682651385125.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1020206_1690988187017.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1084604_1691001603861.json ${containerID}:${HOME}/adx/input_files/
 #   podman cp ${local_mw_container}tests/dx_1051654_1694541043119.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1067512_1701728232097.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1075588_1718206469836.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1096307_1718903233522.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1041625_1719962636930.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1099426_1723593703864.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1010809_1723752875631.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1000165_1727197853965.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1010146_1727199032339.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1033805_1727199095471.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1054957_1727210466365.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1021153_1730312790677.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1096313_1739638051483.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1019794_1744662273112.json ${containerID}:${HOME}/adx/input_files/
    podman cp ${local_mw_container}tests/dx_1097621_1747416575220.json ${containerID}:${HOME}/adx/input_files/
    echo "podman cp ${local_mw_container}tests/*.json"
else
    echo "ERROR: ${local_mw_container}tests/ missing"
fi

# Copy the pensar EDA code - Testing only as pensar will not move to CMOS
#if [ -d "${local_GIT}pensar_predictor/" ]; then
#    podman cp ${local_GIT}pensar_predictor/ ${containerID}:${MW_SERVICE}
#    echo "podman cp ${local_GIT}pensar_predictor/"
#else
#    echo "WARNING: ${local_GIT}pensar_predictor/ missing - OK to ignore"
#fi

# Copy the pensar CS code - Testing only as pensar will not move to CMOS
#if [ -d "${local_GIT}DX-DCS-Pensar/pensar_service/" ]; then
#    podman cp ${local_GIT}DX-DCS-Pensar/pensar_service/ ${containerID}:${DXF_BOUNDARY}
#    echo "podman cp ${local_GIT}DX-DCS-Pensar/pensar_service/"
#else
#    echo "WARNING: ${local_GIT}DX-DCS-Pensar/pensar_service/ missing - OK to ignore"
#fi

# Copy the FV XML Files
#if [ -d "${local_SW_MW_XML}" ]; then
#    podman cp ${local_SW_MW_XML} ${containerID}:${SW_MW}
#    echo "podman cp ${local_SW_MW_XML}"
#else
#    echo "ERROR: ${local_SW_MW_XML} missing"
#fi

# Copy the FV_JAVA -- Steps
#if [ -d "${local_FV_JAVA}" ]; then
#    podman cp ${local_FV_JAVA} ${containerID}:${SW_MW}
#    echo "podman cp ${local_FV_JAVA}"
#else
#    echo "ERROR: ${local_FV_JAVA} missing"
#fi

# Copy local testing files over the existing default, 
# started with the mw_container's MW_COMMON code -- updated for MOS2FS
if [ -d "${local_TESTING}" ]; then
    podman cp ${local_TESTING} ${containerID}:${SW_MW}
    echo "testing overiding: podman cp ${local_TESTING}"
else
    echo "ERROR: no testing overides set as 'local_TESTING' is missing"
fi

#### some clean up
podman exec ${containerID} bash -c "rm -rf /autodx/sw_tools/SW_MW/MW_TOOLS/mw_container /autodx/sw_tools/SW_MW/MW_TOOLS/*.tar.gz"


echo "#### Finishing setup ####"

#podman exec -d -l history -r

#echo NOTICE: ignore restart "WARN[0003] StopSignal" on next command.
podman restart -l -t 3

podman ps -a
echo ""

podman attach -l

podman ps -a

echo ""
echo "Copying {container}:/sr/output/* to output..."
podman cp "${containerID}:/sr/output" .
echo ""
echo "NOTE: Don't forget to remove the last container with command: podman rm -l"
echo "Tip: podman cp ${containerID}:MW_CMOS_DX.tar.gz ./../"

}

command_nothing() {

# just exit for now
echo exiting

}


main $*
