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
keytool -genkey -alias zuul-api-gateway-keycloak -storetype PKCS12 -keyalg RSA -keysize 2048 -keystore keystore.p12 -validity 3650
}

function createCertificatesForAppsDomainUsingLetsEncrypt() {
#sudo certbot certonly --standalone -d zuul-api-gateway-keycloak.cfapps.io -d uaa-keycloak.cfapps.io -d foo-service-keycloak.cfapps.io -d ui-keycloak.cfapps.io --email bhuwan.upadhyay49@gmail.com
sudo certbot certonly --standalone --preferred-challenges tls-sni -d zuul-api-gateway-keycloak.cfapps.io -d uaa-keycloak.cfapps.io -d foo-service-keycloak.cfapps.io -d ui-keycloak.cfapps.io --email bhuwan.upadhyay49@gmail.com
}
# Bash Menu Script Example
ROOT_DIR=$PWD
echo "Building From ${ROOT_DIR}"
PS3='Please enter your choice: '
options=("buildWithDockerImage" "publishToCloudfoundry" "lunchDockerContainers" "createPcfCloudServices" "createCertificatesForAppsDomain" "createCertificatesForAppsDomainUsingLetsEncrypt" "Restart Apps in cf" "Quit")
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
        "createCertificatesForAppsDomainUsingLetsEncrypt")
            echo "you chose 'createCertificatesForAppsDomainUsingLetsEncrypt'"
            createCertificatesForAppsDomainUsingLetsEncrypt;;
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