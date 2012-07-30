" Ripple - a read-eval-print-loop inside vim

if exists('loaded_ripple') || &cp || version < 700
    finish
endif
let loaded_ripple = 1

function! ValidateLanguage()
    let supported_languages = [ 'ruby', 'python', 'lua', 'perl' ]
    let is_good = index(supported_languages, g:ripple_language) >= 0
    if !is_good
        echoerr 'Language "'. g:ripple_language .'" is unsupported by vim-ripple.'
    elseif !has(g:ripple_language)
        echoerr 'Your vim does not have '. g:ripple_language .' support. See :help '. g:ripple_language
        let is_good = 0
    endif
    return is_good
endfunction

if !exists("g:ripple_language")
    let g:ripple_language = 'python'
endif

if !ValidateLanguage()
    finish
endif

function! EvaluateFromInsertMode()
	" call EvaluateCurrentLine if user pressed <enter>
	" on a line starting with '>>>' 
	" (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call EvaluateCurrentLine()
	else
		normal! i
	endif
	return ''
endfunction
function! EvaluateFromNormalMode()
	" call EvaluateCurrentLine if user pressed <enter>
	" on a line starting with '>>>' 
	" (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call EvaluateCurrentLine()
	else
		normal! 
	endif
	return ''
endfunction
function! EvaluateRange() range 
	" runs visually highlighted multiline block
	" of code with single call to the interpreter
	let g:first=a:firstline
	let g:last= a:lastline
	let g:myvar = getline(g:first,g:last)
	let myvar=''
	redir =>> myvar
	:silent! execute g:ripple_language." ".join(g:myvar,"\n")
	redir END
	call append(g:last,'---Results---')
	call append(g:last+1,myvar)
	execute g:last+2
	"normal V"ad
	"call append(line('.'),split(@a,"\n"))

	if getline(line('.')) =~ @a
		silent execute '.s/^'.@a.'//e'
		if g:ripple_language !~ 'ruby\|perl'
			silent execute '.s/'.@a.'//ge'
		else
			silent execute '.s/'.@a.@a.'//ge'
			silent execute '.s/'.@a.'//ge'
		endif
	endif
endfunction
function! EvaluateCurrentLine()
	"get result of the command
	let result = DoCommand()
	" and now append and format the result 
	" in the Vim buffer
	call append(line('.'),result)
	normal j
	call append(line('.'),'>>>  _')
	" result has troublesome '<ctrl-@>' characters
	" that we will remove.  Quoting them or using 
	" literally doesn't work, so a single <ctrl-@>
	" was (hopefully) stored into @a in DoCommand()
	if getline(line('.')) =~ @a
		silent execute '.s/^'.@a.'//e'
		"if != 'ruby'
		silent execute '.s/'.@a.@a.'//ge'
		silent execute '.s/'.@a.'//ge'
		"endif
	endif
	" try to do nice formatting when result has
	" a lot of text
	if len(getline(line('.'))) > 80
		let myline = getline(line('.'))
		let splitlines = split(myline,'\%'.string(winwidth(0)-20).'c\S*\zs ')
		call setline(line('.'),splitlines[0])
		call append(line('.'),splitlines[1:])
	endif
	call search('>>>  _')	
	normal $x
endfunction

function! DoCommand()
	" this function redirects output to a variable,
	" runs the command, and returns result back to EvaluateCurrentLine()
	let command = matchstr(getline(line('.')),'>>>\zs.*')
	let @a=''
	let g:result = ''
	" tweak: initial p gets expanded to full 'print'
	let command = substitute(command,'^\s*[pP] ','print ','')
	redir =>> g:result
	silent! exec g:ripple_language." ".command
	redir END
	let @a=g:result[0]
	if g:result == ''
		let g:result='('.command.' )'
	endif
	return g:result
endfunction

nmap <CR> :call EvaluateFromNormalMode()<cr>
imap <CR> <c-r>=EvaluateFromInsertMode()<cr>
vmap <c-cr> :call EvaluateRange()<cr>
" TODO: will this work for all languages?
syn region rippleError start='^Error detected while' end='^\S\+Error:.*$'
hi rippleError guibg=red
