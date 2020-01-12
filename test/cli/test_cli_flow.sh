#!/bin/bash

export PS4='\e[36m+ ${FUNCNAME:-main}\e[0m@\e[32m${BASH_SOURCE}:\e[35m${LINENO} \e[0m'

#In first stage, the script assume that the noobaa cli is installed.
#Also assuming aws cli is installed

NAMESPACE='test'
#the timeout is that big because it sometimes take a while to get pvc
DEFAULT_TIMEOUT=1800

directory=$(dirname ${0})
. ${directory}/test_cli_functions.sh
unset directory

#FLOW TODO:
# # AWS-S3 ❌
# nb backingstore create aws-s3 aws1 --target-bucket znoobaa --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY ❌
# nb backingstore create aws-s3 aws2 --target-bucket noobaa-qa --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY ❌
# nb backingstore status aws1 ❌
# nb backingstore status aws2 ❌
# nb backingstore list ❌
# nb status ❌
# kubectl get backingstore ❌
# kubectl describe backingstore ❌

# # Google - TODO ❌
# nb backingstore create azure-blob blob1 --target-blob-container jacky-container --account-name $AZURE_ACCOUNT_NAME --account-key $AZURE_ACCOUNT_KEY

# # Azure - TODO ❌
# nb backingstore create google-cloud-storage google1 --target-bucket jacky-bucket --private-key-json-file ~/Downloads/noobaa-test-1-d462775d1e1a.json

# # BucketClass ❌
# nb bucketclass create class1 --backingstores nb1 ✅
# nb bucketclass create class2 --placement Mirror --backingstores nb1,aws1 ❌
# nb bucketclass create class3 --placement Spread --backingstores aws1,aws2 ❌
# nb bucketclass create class4 --backingstores nb1,nb2 ✅
# nb bucketclass status class1 ✅
# nb bucketclass status class2 ✅
# nb bucketclass list ✅
# nb status ✅
# kubectl get bucketclass ✅
# kubectl describe bucketclass ✅

# # OBC ❌
# nb obc create buck1 --bucketclass class1 ✅
# nb obc create buck2 --bucketclass class2 ❌
# nb obc create buck3 --bucketclass class3 --app-namespace default ❌
# nb obc create buck4 --bucketclass class4 ✅
# nb obc list ✅
# # nb obc status buck1 ✅
# # nb obc status buck2 ✅
# # nb obc status buck3 ✅
# kubectl get obc ✅
# kubectl describe obc ✅
# kubectl get obc,ob,secret,cm -l noobaa-obc ✅

# AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=YYY aws s3 --endpoint-url XXX ls BUCKETNAME ❌

function clean {
    PID=$1
    kill -9 ${PID}
    exit 0
}

function main {
    noobaa_install
    aws_credentials
    check_S3_compatible
    bucketclass_cycle
    obc_cycle
    check_deletes
    test_noobaa uninstall
}

function usage {
    set +x
    echo -e "\nUsage: ${0} [options]"
    echo "--timeout         -   Set Timeout in sec (default: ${DEFAULT_TIMEOUT})"
    echo "--namespace       -   Change the namespace"
    echo "--mongo-image     -   Change the mongo image"
    echo "--noobaa-image    -   Change the noobaa image"
    echo "--operator-image  -   Change the operator image"
    echo -e "--help         -   print this help\n"
    exit 1
}

while true
do
    if [ -z ${1} ]; then
        break
    fi

    case ${1} in
        --mongo-image)      MONGO_IMAGE=${2}
                            shift 2;;
        --noobaa-image)     NOOBAA_IMAGE=${2}
                            shift 2;;
        --operator-image)   OPERATOR_IMAGE=${2}
                            shift 2;;
        -n|--namespace)     NAMESPACE=${2}
                            shift 2;;
        --timeout)          TIMEOUT=${2}
                            shift 2
                            number='^[0-9]+$'
                            if ! [[ ${TIMEOUT} =~ ${number} ]]
                            then
                                echo "❌  timeout must be a number, Exiting"
                                exit 1
                            fi;;
        -h|--help)          usage;;
        *)                  usage;;
    esac
done

#Setting noobaa command with namespace
#The reason that we are doing it in a variable and not alias is
#That alias is not expended in non interactive shell
#Currently will work only on noobaa-operator-local - need to change it
noobaa="build/_output/bin/noobaa-operator-local -n ${NAMESPACE}"
kubectl="kubectl -n ${NAMESPACE}"

#Setting the noobaa command with non standard options if needed.
if [ ! -z ${MONGO_IMAGE} ]
then
    noobaa+=" --mongo-image ${MONGO_IMAGE}"
fi

if [ ! -z ${NOOBAA_IMAGE} ]
then
    noobaa+=" --noobaa-image ${NOOBAA_IMAGE}"
fi

if [ ! -z ${OPERATOR_IMAGE} ]
then
    noobaa+=" --operator-image ${OPERATOR_IMAGE}"
fi

if [ -z ${TIMEOUT} ]
then
    TIMEOUT=${DEFAULT_TIMEOUT}
fi

main
