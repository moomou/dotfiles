import unittest

import simple_argparse as sa


class TestSimpleArgParse(unittest.TestCase):
    def test_parse(self):
        pos, named = sa.parse("--a --b --c".split(" "))
        self.assertEqual([], pos)
        self.assertEqual({"a": True, "b": True, "c": True}, named)

        pos, named = sa.parse("x y --a 1 --b 2 --c".split(" "))
        self.assertEqual(["x", "y"], pos)
        self.assertEqual({"a": "1", "b": "2", "c": True}, named)


if __name__ == "__main__":
    unittest.main()
