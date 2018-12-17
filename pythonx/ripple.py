#! /usr/bin/env python

import re
import vim

noquote_re = re.compile('(["\'])')

def capture_exception(ex):
    """Store exception for later handling.

    capture_exception(Exception) -> None
    """
    ex_name = type(ex).__name__
    ex_msg = noquote_re.sub(r'\\\1', str(ex))
    cmd = 'let g:ripple_exception = \"%s: %s\"' % (ex_name, ex_msg)
    vim.command(cmd)

if __name__ == '__main__':
    try:
        raise Exception('hello "friend"')
    except Exception as ex:
        capture_exception(ex)
