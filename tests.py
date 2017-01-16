#!/bin/python

# Docker Image Authorization Plugin
# Test scripts for authorization plugin
# Author: Chaitanya Prakash N <cpdevws@gmail.com>

import docker
import unittest
from subprocess import call

class TestAuthorizationPlugin(unittest.TestCase):
	@classmethod
	def setUpClass(cls):
		call(["make"])
		call(["make", "config"])
		call(["make", "install"])
		call(["systemctl", "daemon-reload"])
		call(["systemctl", "restart", "img-authz-plugin"])
		call(["systemctl", "start", "docker"])

	def setup_with_registries(self, registries):
		if registries == None:
			registries = ""
		call(["make", "config", "REGISTRIES=%s"%registries])
		call(["make", "uninstall"])
		call(["make", "install"])
		call(["systemctl", "daemon-reload"])
		call(["systemctl", "restart", "img-authz-plugin"])

	def docker_pull(self, image):
		client = docker.from_env()
		try:
			client.images.pull(image)
		except docker.errors.APIError, exception:
			return False
		return True
			
	def docker_run(self, image):
		client = docker.from_env()
		try:
			client.containers.run(image, "echo 'from container'")
		except docker.errors.APIError, exception:
			return False
		return True
			
	def docker_pull_is_denied(self, image):
		self.assertEqual(self.docker_pull(image), False)
		
	def docker_pull_is_allowed(self, image):
		self.assertEqual(self.docker_pull(image), True)

	def docker_run_is_denied(self, image):
		self.assertEqual(self.docker_run(image), False)
		
	def docker_run_is_allowed(self, image):
		self.assertEqual(self.docker_run(image), True)

	def test_pull_is_not_allowed_when_no_registries_are_authorized(self):
		self.setup_with_registries(None)
		self.docker_pull_is_denied("alpine:latest")

	def test_run_is_not_allowed_when_no_registries_are_authorized(self):
		self.setup_with_registries(None)
		self.docker_run_is_denied("alpine:latest")

	def test_pull_is_not_allowed_when_registry_is_not_authorized(self):
		self.setup_with_registries("library")
		self.docker_pull_is_denied("my.docker.registry/alpine:latest")

	def test_run_is_not_allowed_when_registry_is_not_authorized(self):
		self.setup_with_registries("library")
		self.docker_run_is_denied("my.docker.registry/alpine:latest")

	def test_pull_is_allowed_when_registry_is_authorized(self):
		self.setup_with_registries("library")
		self.docker_pull_is_allowed("alpine:latest")

	def test_run_is_allowed_when_registry_is_authorized(self):
		self.setup_with_registries("library")
		self.docker_run_is_allowed("alpine:latest")

	def test_pull_is_allowed_when_multiple_registries_are_authorized(self):
		self.setup_with_registries("my.docker.registry,library")
		self.docker_pull_is_allowed("alpine:latest")

	def test_run_is_allowed_when_multiple_registries_are_authorized(self):
		self.setup_with_registries("my.docker.registry,library")
		self.docker_run_is_allowed("alpine:latest")


# Start the tests
suite = unittest.TestLoader().loadTestsFromTestCase(TestAuthorizationPlugin)
unittest.TextTestRunner(verbosity=2).run(suite)
