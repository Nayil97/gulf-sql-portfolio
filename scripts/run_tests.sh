#!/usr/bin/env bash
#
# Run pgTAP tests against the current database
#
# This script executes all pgTAP test files in the `tests/pgtap/` directory.
# Ensure that the `pgtap` extension is installed in the database and that
# the warehouse has been built before running.

set -euo pipefail

for test_file in tests/pgtap/*.sql; do
    echo "Running $test_file..."
    psql -v ON_ERROR_STOP=1 -f "$test_file"
done

echo "All tests completed."