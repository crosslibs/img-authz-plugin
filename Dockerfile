# Docker Image Authorization Plugin
# Build tools image
FROM golang:1.7.4-alpine

MAINTAINER Chaitanya Prakash N <cpdevws@gmail.com>

# Install make and git
RUN apk add --no-cache curl-dev curl libcurl openssl make git

