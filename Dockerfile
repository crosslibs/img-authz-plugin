# Docker Image Authorization Plugin
# Build tools image
FROM centos:7

MAINTAINER Chaitanya Prakash N <cpdevws@gmail.com>

# Install make, golang and git
RUN yum install -y git make golang

