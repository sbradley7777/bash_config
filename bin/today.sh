#!/bin/sh
#
# Description:
#   Output current date in ISO format with Unix timestamp.
#
# Usage:
#   today.sh
#
# Examples:
#   $ ./today.sh
#   2025-12-14_1734192345
#
# Exit Codes:
#   0    Success
#

date '+%F_%s'
exit 0
