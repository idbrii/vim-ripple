Vim-Ripple
----------
vim-ripple is a REPL (read-evalulate-print-loop) plugin for vim. It allows you
to write code in a vim buffer and execute it from that buffer. The results
will be appended to the buffer. You can write both single lines of code and
blocks. vim-ripple can support any language with native vim bindings.


Screencast
----------
Watch the `screencast demo`_ of vim-ripple.

.. _screencast demo: http://vimeo.com/16871727


Recommendations
---------------
You can get tab completion of your Python commands by using any of the 
available methods of completion in Vim.  I've tried the pydiction 
tab-completion plugin and recommend that anyone using vim-ripple install pydiction_

.. _pydiction: http://www.vim.org/scripts/script.php?script_id=850  


You should get itchy.vim_ to have improved splitting behavior when opening a
new REPL.

.. _itchy.vim: https://github.com/pydave/itchy.vim


Compatibility
-------------
vim-ripple works with Ruby, Perl, and Lua.



Details
-------
The vim-ripple plugin consists of a single vimscript file that a Vim user can
install by placing it in their 'plugin' directory.

vim-ripple requires a Vim executable compiled with support for the 
scripting language(s) that will be used. It has been
tested with Python26, Ruby1.8, Perl 5.12, and Lua 5.1,
but version should not matter.

Over last few years several different plugins have been designed to send
commands in a Vim buffer out to a shell for processing (typically scripting
the Gnu Screen utility), where the output can be viewed.  This works well, but
for languages where Vim has built-in support some people might prefer
executing the commands and getting output right in the Vim buffer.  All this
takes is redirecting the output from a supported language's command to the
user's buffer instead of to a message buffer.  This technique is possible only
for the languages where Vim offers compile-in support, which include Python,
Perl, Ruby, Lua, MZScheme (anything else?)  This plugin is specific to Python
but it should be relatively easy to extend to other supported languages.

In general, this plugin makes Vim into an alternative to Python's IDLE.  It
has advantages and disadvantages compared to IDLE, but it's possible that some
people may prefer it to a tool like IDLE, at least for some uses.


Using Ripple
------------

When the vim-ripple plugin is loaded you can process language commands and get
output in your Vim buffer in several different ways:

(1)  Prepend a '>>>' user prompt as first characters in a line, then press
<enter>.  The command will be evaluated and results will be shown beginning in
the next line.  Commands that provide no output have the command itself
mirrored as output as confirmation that they have been processed.  You will
typically want to issue Python print commands, and these can be abbreviated
with 'p' instead of 'print'.  Some examples:

>>> print 8 + 16
24
>>> p 8 + 16
24
>>> import sys
( import sys )
>>> for i in range(5): print i
1
2
3
4
5
>>> etc. etc.

(2)  You can execute a block of lines at one time by visually selecting them
and pressing <ctrl_enter>.  The block should be a clean block of code with no
user prompt chars (i.e, '>>>') at left margin.  Output will be returned below
the block of lines.  Note that this method uses <ctrl-enter> rather than the
simple <enter> of the single-line-prompt method.

(3)  It's not part of the plugin, but an entire file of Python can be executed
with the Vim command:   pyfile <filename>.  The plugin does not capture any
output from this command, however functions defined in the file can may then
be accessed in the Vim buffer using single-line-prompt Python commands or the
block-select Python processing.

The plugin has a couple of lines defining a syntax region for error messages
and a highlight command that displays them in red.  This may be overwritten by
a syntax file that clears all syntax settings so if you want to use these you
may want to move the syntax and the highlight command to a syntax and color
file, respectively.

This is just a Sunday afternoon hack and there are lots of little tweaks and
improvements that could be added.   I'd be happy to hear comments or
suggestions. . . 


 vim:tw=78:et:norl:
