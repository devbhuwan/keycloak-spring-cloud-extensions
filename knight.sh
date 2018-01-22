#!/usr/bin/env bash

function buildWithDockerImage() {
    echo "Clean and Build Project"
    ./gradlew clean build copyDocker docker -x test
    cd foo-web-client && npm run build && cd ../
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
		    keytool   -genkey \
                      -alias ${i} \
                      -storetype PKCS12 \
                      -keyalg RSA \
                      -keysize 2048 \
                      -keystore ${i}.p12 \
                      -dname "CN=${i}, OU=DEV, O=GorkhasLab, L=Dhangadhi, ST=Kailali, C=NP" \
                      -validity 3650 \
                      -keypass password \
                      -storepass password \
                      && yes | cp -rf ${i}.p12 ${i}/src/main/resources \
		              && rm ${i}.p12
            # openssl pkcs12 -info -in keystore.p12
	    done
}

function cleanCfApps() {
for i in 'zuul-api-gateway-keycloak' 'uaa-keycloak' 'foo-service-keycloak' 'foo-web-client'
	    do
		    echo "Clean App: $i"
		    yes | cf delete ${i}
	    done
}

function createCertificatesForWebClientDomain() {
	t='foo-web-client'
	echo "Generating Certificate For $t"
	openssl dhparam -out ${t}.pem 2048
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${t}.key -out ${t}.crt
	yes | cp -rf ${t}.key ${t}.crt ${t}.pem ${t}/
	rm ${t}.key ${t}.crt ${t}.pem
}

# Bash Menu Script Example
ROOT_DIR=$PWD
echo "Building From ${ROOT_DIR}"
PS3='Please enter your choice: '
options=("buildWithDockerImage" "publishToCloudfoundry" "lunchDockerContainers" "createPcfCloudServices" "createCertificatesForAppsDomain" "createCertificatesForWebClientDomain" "cleanCfApps" "Restart Apps in cf" "Quit")
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
        "createCertificatesForWebClientDomain")
            echo "you chose 'createCertificatesForWebClientDomain'"
            createCertificatesForWebClientDomain;;
        "cleanCfApps")
            echo "you chose 'cleanCfApps'"
            cleanCfApps;;
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