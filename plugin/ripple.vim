" Ripple - a read-eval-print-loop inside vim

if exists('g:loaded_ripple') || &cp || version < 700
	finish
endif
let loaded_ripple = 1

if !exists('g:ripple_filetype_as_default')
	let g:ripple_filetype_as_default = 1
endif

if !exists('g:ripple_default_language')
	let g:ripple_default_language = 'python'
endif


let s:filetype_defaults = {
			\ 'lua':    'luafile',
			\ 'perl':   'perl',
			\ 'ruby':   'rubyfile',
			\ 'vim':    'source',
			\ }
if has('pythonx')
	let s:filetype_defaults['python'] = 'pyxfile'
elseif has('python3')
	let s:filetype_defaults['python'] = 'py3file'
elseif has('python')
	let s:filetype_defaults['python'] = 'pyfile'
endif

" Clobber defaults with user values if they exist.
let g:ripple_filetype_to_cmd = extend(s:filetype_defaults, get(g:, 'ripple_filetype_to_cmd', {}))
unlet s:filetype_defaults

" TODO(ex): Break into dictionary?
let s:trycatch_defaults = {
			\ 'lua':    [],
			\ 'perl':   [],
			\ 'python': ['import ripple', 'try:', 'except Exception as ex:', '     ripple.capture_exception(ex)'],
			\ 'ruby':   [],
			\ 'vim':    [],
			\ }
let g:ripple_filetype_trycatch = extend(s:trycatch_defaults, get(g:, 'ripple_filetype_trycatch', {}))
unlet s:trycatch_defaults

command! -nargs=? RippleCreate :call ripple#CreateRepl(<f-args>)

" vim:noet:ts=4 sw=4:
