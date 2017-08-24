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

command! -nargs=? RippleCreate :call ripple#CreateRepl(<f-args>)

" vim:noet:ts=4 sw=4:
