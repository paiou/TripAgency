VERSION := $(shell git describe --tags --always)-SNAPSHOT
APP_NAME := $(shell ./mvnw org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.name -q -DforceStdout)
DOCKER_IMAGE := $(shell echo "${DOCKER_PROJECT_REGISTRY}/${APP_NAME}-exposition:${VERSION}")
MODE := DOCKER

ci : setup_maven build build_docker_image sonarqube_scan generate_living_documentation_for_domain revert_maven_setup
.PHONY: ci
setup_maven :
	./CI_CD/setup_maven.sh "${VERSION}"
build :
	./CI_CD/build.sh -m "${VERSION}"
build_docker_image :
	./CI_CD/build_docker_image.sh "${DOCKER_IMAGE}"
sonarqube_scan :
	./CI_CD/sonarqube_scan.sh
generate_living_documentation_for_domain :
	./CI_CD/generate_living_documentation.sh domain "${VERSION}"
revert_maven_setup :
	./CI_CD/revert_maven_setup.sh

e2e : setup_maven start_exposition launch_e2e_tests generate_living_documentation_for_e2e stop_exposition revert_maven_setup
.PHONY: e2e
start_exposition :
	./CI_CD/start_exposition.sh "${DOCKER_IMAGE}" "${VERSION}" "${MODE}"
launch_e2e_tests :
	./CI_CD/launch_e2e_tests.sh
generate_living_documentation_for_e2e :
	./CI_CD/generate_living_documentation.sh e2e "${VERSION}"
stop_exposition :
	./CI_CD/stop_exposition.sh "${MODE}"

clean : revert_maven_setup clean
.PHONY: clean
clean :
	./CI_CD/clean.sh