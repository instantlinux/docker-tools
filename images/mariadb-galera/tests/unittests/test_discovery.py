import unittest

import entrypoint


class TestDiscovery(unittest.TestCase):

    def test_init(self):
        client = entrypoint.DiscoveryService([('127.0.0.1', 2379)], 'test')
        assert client is not None, 'failed to init'
        assert client.cluster == 'test', 'cluster value not set'
