import pathlib
import unittest


class UpdateCompatibilityTests(unittest.TestCase):
    def test_legacy_update_requirements_file_is_retained(self):
        m_root = pathlib.Path(__file__).resolve().parents[1]
        requirements = m_root / "pip-requirements.txt"

        self.assertTrue(requirements.is_file())
        self.assertIn("coloredlogs", requirements.read_text().splitlines())


if __name__ == "__main__":
    unittest.main()
