#!/usr/bin/env python3
"""
Test runner for Texterify Language Processor
"""

import sys
import unittest
from pathlib import Path

# Add src to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root / "src"))
sys.path.insert(0, str(project_root))


def run_all_tests():
    """Run all tests with detailed output"""
    print("Running Texterify Language Processor Test Suite")
    print("=" * 60)

    # Discover all tests
    loader = unittest.TestLoader()
    start_dir = Path(__file__).parent
    suite = loader.discover(str(start_dir), pattern="test_*.py")

    # Run tests with detailed output
    runner = unittest.TextTestRunner(
        verbosity=2, stream=sys.stdout, descriptions=True, failfast=False
    )

    print(f"\nDiscovered {suite.countTestCases()} test cases")
    print("-" * 60)

    result = runner.run(suite)

    # Print summary
    print("\n" + "=" * 60)
    print("Test Summary:")
    print(f"  Tests run: {result.testsRun}")
    print(f"  Failures: {len(result.failures)}")
    print(f"  Errors: {len(result.errors)}")
    print(f"  Skipped: {len(result.skipped)}")

    if result.failures:
        print("\nFailures:")
        for test, traceback in result.failures:
            print(f"  - {test}: {traceback.split(chr(10))[-2]}")

    if result.errors:
        print("\nErrors:")
        for test, traceback in result.errors:
            print(f"  - {test}: {traceback.split(chr(10))[-2]}")

    success = result.wasSuccessful()

    if success:
        print("\nAll tests passed!")
    else:
        print("\nSome tests failed!")

    print("=" * 60)

    return success


def run_specific_test(test_name):
    """Run a specific test module"""
    print(f"Running specific test: {test_name}")
    print("=" * 60)

    try:
        module = __import__(test_name)
        suite = unittest.TestLoader().loadTestsFromModule(module)
        runner = unittest.TextTestRunner(verbosity=2)
        result = runner.run(suite)
        return result.wasSuccessful()
    except ImportError as e:
        print(f"Could not import test module '{test_name}': {e}")
        return False


def main():
    """Main test runner"""
    if len(sys.argv) > 1:
        # Run specific test
        test_name = sys.argv[1]
        success = run_specific_test(test_name)
    else:
        # Run all tests
        success = run_all_tests()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
