#!/bin/bash -e

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
#createPcfCloudServices
buildWithDockerImage && publishToCloudfoundry