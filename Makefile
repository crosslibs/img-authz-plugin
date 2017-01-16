# Docker Image Authorization Plugin
# Builds, Installs and Uninstalls the image authorization plugin service
# Author: Chaitanya Prakash N <cpdevws@gmail.com>
DESCRIPTION="Docker Image Authorization Plugin"
SERVICE=img-authz-plugin
SERVICEINSTALLDIR=/usr/libexec
SERVICESOCKETFILE=${SERVICE}.socket
SERVICECONFIGFILE=${SERVICE}.service
SYSTEMINSTALLDIR=/usr/lib/systemd/system
SOURCEDIR=src/main/
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
REGISTRIES := ""
AUTH_REGISTRIES=$(shell echo $(REGISTRIES)  | sed 's/^\s*/--registry /g' | sed 's/\s*,\s*/ --registry /g' | sed 's/^\s*--registry\s*$$//g' )

VERSION := 1.0.0
BUILD := `date +%FT%T%z`

# LDFLAGS
LDFLAGS=-ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}"

# GO PACKAGE DEPENDENCIES
GOPKGDEPS = github.com/docker/go-plugins-helpers/authorization \
	    github.com/docker/docker/api \
	    github.com/docker/docker/client \
	    github.com/docker/docker/api/types/container

# Generate the service binary and executable
.DEFAULT_GOAL: $(SERVICE)
$(SERVICE): $(SOURCES)
	go get -d ${GOPKGDEPS}
	go build ${LDFLAGS} -o ${SERVICE} ${SOURCES}

# Generate the service config and socket files
.PHONY: config
config: $(SERVICESOCKETFILE) $(SERVICECONFIGFILE)

# Generate the socket file
.PHONY: $(SERVICESOCKETFILE)
$(SERVICESOCKETFILE): 
	@echo -n "" > ${SERVICESOCKETFILE}
	@echo "[Unit]" >> ${SERVICESOCKETFILE}
	@echo "Description=${DESCRIPTION} Socket" >> ${SERVICESOCKETFILE}
	@echo >> ${SERVICESOCKETFILE}
	@echo "[Socket]" >> ${SERVICESOCKETFILE}
	@echo "ListenStream=/run/docker/plugins/${SERVICE}.sock" >> ${SERVICESOCKETFILE}
	@echo >> ${SERVICESOCKETFILE}
	@echo "[Install]" >> ${SERVICESOCKETFILE}
	@echo "WantedBy=sockets.target" >> ${SERVICESOCKETFILE}

# Generate the service file
.PHONY: $(SERVICECONFIGFILE)
$(SERVICECONFIGFILE):
	@echo -n "" > ${SERVICECONFIGFILE}
	@echo "[Unit]" >> ${SERVICECONFIGFILE}
	@echo "Description=${DESCRIPTION}" >> ${SERVICECONFIGFILE}
	@echo "Before=docker.service" >> ${SERVICECONFIGFILE}
	@echo "After=network.target ${SERVICESOCKETFILE}" >> ${SERVICECONFIGFILE}
	@echo "Requires=${SERVICESOCKETFILE} docker.service" >> ${SERVICECONFIGFILE}
	@echo  >> ${SERVICECONFIGFILE}
	@echo "[Service]" >> ${SERVICECONFIGFILE}
	@echo "ExecStart=${SERVICEINSTALLDIR}/${SERVICE} ${AUTH_REGISTRIES}" >> ${SERVICECONFIGFILE}
	@echo  >> ${SERVICECONFIGFILE}
	@echo "[Install]" >> ${SERVICECONFIGFILE}
	@echo "WantedBy=multi-user.target" >> ${SERVICECONFIGFILE}

# Install the service binary and the service config files
.PHONY: install
install:
	@cp -f ${SERVICE} ${SERVICEINSTALLDIR}
	@cp -f ${SERVICESOCKETFILE} ${SYSTEMINSTALLDIR}
	@cp -f ${SERVICECONFIGFILE} ${SYSTEMINSTALLDIR}

# Uninstalls the service binary and the service config files
.PHONY: uninstall
uninstall:
	@rm -f ${SERVICEINSTALLDIR}/${SERVICE}
	@rm -f ${SYSTEMINSTALLDIR}/${SERVICESOCKETFILE}
	@rm -f ${SYSTEMINSTALLDIR}/${SERVICECONFIGFILE}

# Removes the generated service config and binary files
.PHONY: clean
clean:
	@rm -rf src/github.com src/golang.org
	@rm -rf pkg/ bin/
	@rm -f ${SERVICE}
	@rm -f ${SERVICESOCKETFILE}
	@rm -f ${SERVICECONFIGFILE}
