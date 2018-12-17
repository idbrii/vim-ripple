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
			\ 'lua':    'lua',
			\ 'perl':   'perl',
			\ 'ruby':   'ruby',
			\ }
if has('pythonx')
	let s:filetype_defaults['python'] = 'pythonx'
elseif has('python3')
	let s:filetype_defaults['python'] = 'python3'
elseif has('python')
	let s:filetype_defaults['python'] = 'python'
endif

" Clobber defaults with user values if they exist.
let g:ripple_filetype_to_cmd = extend(s:filetype_defaults, get(g:, 'ripple_filetype_to_cmd', {}))
unlet s:filetype_defaults

command! -nargs=? RippleCreate :call ripple#CreateRepl(<f-args>)

" vim:noet:ts=4 sw=4:
