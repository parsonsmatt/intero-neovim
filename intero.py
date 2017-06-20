# Functions consumed from Vimscript. This file is loaded as a module, to avoid
# polluting the global namespace.

import os.path
import re
import vim


# Regexes used to remove control characters
regexes = [
    # Filter out ANSI codes - they are needed for interactive use, but we don't care about them.
    # Regex from: https://stackoverflow.com/questions/14693701/how-can-i-remove-the-ansi-escape-sequences-from-a-string-in-python
    # Note that we replace [0-?] with [0-Z] to filter out the arrow keys as well (xterm codes)
    re.compile(r"(\x9B|\x1B\[)[0-Z]*[ -\/]*[@-~]"),
    # Filter out DECPAM/DECPNM, since they're emitted as well
    # Source: https://www.xfree86.org/4.8.0/ctlseqs.html
    re.compile(r"\x1B[>=]")
]


def stack_dirname():
    '''Determines the path to the root directory.'''

    return os.path.dirname(vim.eval('g:intero_stack_yaml'))


def strip_control_chars():
    '''Removes control characters from the line buffer.'''

    current_line = vim.eval('s:current_line')

    for r in regexes:
        current_line = r.sub("", current_line)

    return current_line

