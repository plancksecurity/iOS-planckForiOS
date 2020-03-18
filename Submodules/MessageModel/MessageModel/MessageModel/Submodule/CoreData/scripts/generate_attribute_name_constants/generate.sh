#!/bin/bash -l

# Setup envirnoment and trigger generation of Core Data related boilerplate code

# YSL uses asci as default and fails if not set
export LANG="en_US.UTF-8"
export YML_PATH="${HOME}/yml2"

YML2PROC="${YML_PATH}/yml2proc"
SCRIPTS_PATH="${PROJECT_DIR}/MessageModel/Submodule/CoreData/scripts/generate_attribute_name_constants"
TMP_DIR="${SCRIPTS_PATH}/tmp"
MOM_BASE_PATH="${PROJECT_DIR}/MessageModel/MessageModel.xcdatamodeld"
CORE_DATA_SUBMODULE="${PROJECT_DIR}/MessageModel/Submodule/CoreData"
OUTPUT_DIR="${CORE_DATA_SUBMODULE}/gen"
OUTPUT_FILE="${OUTPUT_DIR}/CoreDataEntityAttributeNames.swift"

####################
# cleanup
rm -rf ${TMP_DIR}

####################
# Write header
echo "//\
// Generated file. DO NOT ALTER MANUALLY!\
//" \
> ${OUTPUT_FILE}

####################
# mk dirs
mkdir -p ${TMP_DIR}

####################
# get path to currently used  model
CUR_VERSION_DICT="${MOM_BASE_PATH}/.xccurrentversion"
CURRENT_MODEL_NAME="$(/usr/libexec/PlistBuddy -c "Print _XCCurrentVersionName" "${CUR_VERSION_DICT}")"
CURRENT_MODEL="${MOM_BASE_PATH}/${CURRENT_MODEL_NAME}"

####################
# copy model to not mess with original
MODEL_WORKING_COPY="${TMP_DIR}/contents"
`cp ${CURRENT_MODEL}/contents ${MODEL_WORKING_COPY}`

####################
# rm first line ("<?xml version="1.0" ...") as yml can not deal with it for some reason
`cat ${MODEL_WORKING_COPY} | sed 1d > ${MODEL_WORKING_COPY}_firstLineRemoved`
`cp ${MODEL_WORKING_COPY}_firstLineRemoved ${MODEL_WORKING_COPY}`
`rm ${MODEL_WORKING_COPY}_firstLineRemoved`

####################
## Generate code
####################
YSLT="${SCRIPTS_PATH}/gen_attribute_names.ysl2"
${YML2PROC} -y ${YSLT} -x ${MODEL_WORKING_COPY} >> ${OUTPUT_FILE}
yml_exit_code=$?

####################
# cleanup
rm -rf ${TMP_DIR}

####################
# Write trigger file to Derived Data.
# We are generating code only if not done already (setup as `outfile` in Xcode's "Build Phases").
# rm ${TRIGGER_FILE} (clean derived data) to force re-generation
TRIGGER_FILE="${DERIVED_FILE_DIR}/trigger_deleteThisFileToTriggerGenerationOfCoreDataBoilerplate.txt"
echo "To re-genererate Core Data boilerplate, rm this file." > ${TRIGGER_FILE}

exit $yml_exit_code
