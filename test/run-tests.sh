#!/usr/bin/env bash

# unofficial bash strict mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Do not "cd" to any existing "test" dir from CDPATH!
unset CDPATH

cd "$( dirname "${BASH_SOURCE[0]}" )"

export VADER_OUTPUT_FILE=vader.log
set -x
nvim -N -u vimrc.vim -c 'Vader! **/*.vader'
cat ${VADER_OUTPUT_FILE}
set +x
