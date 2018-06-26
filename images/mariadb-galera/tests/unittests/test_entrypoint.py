import unittest

import entrypoint


class TestEntrypoint(unittest.TestCase):

    def test_setup_logging(self):
        ret = entrypoint.setup_logging()
        self.assertEqual(ret, "Not yet")
