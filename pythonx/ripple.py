#! /usr/bin/env python

import re
import vim


def capture_exception(ex):
    """Store exception for later handling.

    capture_exception(Exception) -> None
    """
    ex_name = type(ex).__name__
    ex_msg = str(ex)
    vim.vars['ripple_exception'] = "%s: %s" % (ex_name, ex_msg)

# execute 'pyx import ripple; ripple._test()' | echo g:ripple_exception
def _test():
    try:
        raise Exception('hello "friend"')
    except Exception as ex:
        capture_exception(ex)
