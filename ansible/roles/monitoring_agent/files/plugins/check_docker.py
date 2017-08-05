#!/usr/bin/env python3

import nagiosplugin
import docker
import argparse

'''
	Class for the plugin to do its work. Passing in URL or local connection.

	Defines all metrics from docker_info that are numbers with context names that equal
	their names out of the API.

	This plugin should be rather immune to changes in the underlying Docker API. If
	things are added to info(), the plugin doesn't have to be updated immediately to pull 
	in new identifiers but can be controlled via commandline arguments. 

'''
class Docker(nagiosplugin.Resource):
	def __init__(self, url):
		self.url = url

	def probe(self):
		
		try:
			conn = docker.Client(base_url=self.url, timeout=20)
			docker_info = conn.info()
			self.running = 0
		except:
			self.running = 1

		yield nagiosplugin.Metric('service', self.running)
		if self.running == 0:
			for k,v in docker_info.items():
				# Only pick numbers that we can generate metrics from
				# Nagios is not a config management system.
				if isinstance(v, (int, float, complex)):
					yield nagiosplugin.Metric(k, v)
	
# Extend nagiosplugin.Summary so we get verbosity
class DockerSummary(nagiosplugin.Summary):
	def verbose(self, results):
		super(DockerSummary, self).verbose(results)

@nagiosplugin.guarded
def main():

	args = argparse.ArgumentParser()
	args.add_argument('-u', '--url', metavar='URL', default='unix://var/run/docker.sock', help='URL for Docker service. (ex. unix://var/run/docker.sock or http://localhost:4243/)')
	args.add_argument('-t', '--timeout', default=10, help='abort execution after Timeout')
	args.add_argument('-v', '--verbose', action='count', default=0, help='increase output verbosity (use up to 3 times)')
	args.add_argument('-m', '--metric', nargs=3, action='append', help='<metric name> <warning> <critical>')

	# Defaults for metrics we know about. Can be overridden with -m/--metric option
	# Add any new metrics, or change default thresholds here. 
	metrics = [ 
		['Containers',0,0],
		['Debug',0,0],
		['IPv4Forwarding',0,0],
		['Images',0,0],
		['MemoryLimit',0,0],
		['NEventsListener',0,0],
		['NFd',0,0],
		['NGoroutines',0,0],
		['SwapLimit',0,0]
	]

	args = args.parse_args()

	# Add or update options based on -m
	# Any options that are spurious will just not be matched by the check.
	if args.metric:
		for i in args.metric:
			try:
				i = next(subl for subl in args.metric if 'i[0]' in subl)
			except:
				metrics.append(i)

	check = nagiosplugin.Check(
		Docker(args.url),
		DockerSummary(),
		nagiosplugin.ScalarContext('service', '0', '0',fmt_metric=''))

	# Add our metric checks (totally positional in the list, need to add identifiers)
	for i in metrics:
		check.add(nagiosplugin.ScalarContext(i[0],i[1],i[2],fmt_metric=''))

	check.main(args.verbose, args.timeout)

if __name__ == '__main__':
	main()

