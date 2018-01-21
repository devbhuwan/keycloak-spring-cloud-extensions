#!/usr/bin/env bash

function buildWithDockerImage() {
    echo "Clean and Build Project"
    ./gradlew clean build copyDocker docker -x test
}

function publishToCloudfoundry() {
    echo "Publish To Cloudfoundry"
    cf push
}

function createPcfCloudServices() {
    echo "Creating PCF Spring Cloud Services"
    cf create-service \
        -c '{ "git": { "uri": "https://github.com/GorkhasLab/pcf-config", "label": "master"  } }' \
        p-config-server standard config-server

    cf create-service p-service-registry standard service-registry
}

function lunchDockerContainers() {
    echo "Launch Local Docker Running Containers"
    docker-compose up
}


function createCertificatesForAppsDomain() {
    for i in 'zuul-api-gateway-keycloak' 'uaa-keycloak' 'foo-service-keycloak'
	    do
		    echo "Generating Certificate For $i"
		    keytool -genkey -alias ${i} -storetype PKCS12 -keyalg RSA -keysize 2048 -keystore ${i}.jks -validity 3650
		    yes | cp -rf ${i}.jks ${i}/src/main/resources
		    rm ${i}.jks
	    done
}

# Bash Menu Script Example
ROOT_DIR=$PWD
echo "Building From ${ROOT_DIR}"
PS3='Please enter your choice: '
options=("buildWithDockerImage" "publishToCloudfoundry" "lunchDockerContainers" "createPcfCloudServices" "createCertificatesForAppsDomain" "Restart Apps in cf" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "buildWithDockerImage")
            echo "you chose 'buildWithDockerImage'"
            buildWithDockerImage;;
        "publishToCloudfoundry")
            echo "you chose 'publishToCloudfoundry'"
            publishToCloudfoundry;;
        "lunchDockerContainers")
            echo "you chose 'lunchDockerContainers'"
            lunchDockerContainers;;
        "createPcfCloudServices")
            echo "you chose 'createPcfCloudServices'"
            createPcfCloudServices;;
        "createCertificatesForAppsDomain")
            echo "you chose 'createCertificatesForAppsDomain'"
            createCertificatesForAppsDomain;;
        "Restart Apps in cf")
            echo "you chose 'Restart Apps in cf'"
            printf 'Apps [foo-service]: '
            read services
            cf restart ${services};;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done