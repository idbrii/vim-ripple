" Ripple - a read-eval-print-loop inside vim

if exists('loaded_ripple') || &cp || version < 700
	finish
endif
let loaded_ripple = 1

if !exists("g:ripple_language")
	let g:ripple_language = 'python'
endif

command! -nargs=? RippleCreate :call ripple#CreateRepl(<f-args>)

" vim:noet:ts=4 sw=4:
