import unittest2

import entrypoint


class TestEntrypoint(unittest2.TestCase):

    def test_setup_logging(self):
        ret = entrypoint.setup_logging()
        self.assertEqual(ret, "Not yet")
