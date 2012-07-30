" Ripple - a read-eval-print-loop inside vim

" TODO:
"	* Write a help file.
"	* Allow newlines so you can write a class or function.
"	* Prevent error on empty line (just prompt).

if !exists('loaded_ripple') || &cp || version < 700
	finish
endif

function! ripple#ValidateLanguage(ripple_language)
	let supported_languages = [ 'ruby', 'python', 'lua', 'perl' ]
	let is_good = index(supported_languages, a:ripple_language) >= 0
	if !is_good
		echoerr 'Language "'. a:ripple_language .'" is unsupported by vim-ripple.'
	elseif !has(a:ripple_language)
		echoerr 'Your vim does not have '. a:ripple_language .' support. See :help '. a:ripple_language
		let is_good = 0
	endif
	return is_good
endfunction

function! s:EvaluateFromInsertMode()
	" call EvaluateCurrentLine if user pressed <enter> on a line starting with
	" '>>>' (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call s:EvaluateCurrentLine()
	else
		normal! i
	endif
	return ''
endfunction

function! s:EvaluateFromNormalMode()
	" call EvaluateCurrentLine if user pressed <enter> on a line starting with
	" '>>>' (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call s:EvaluateCurrentLine()
	else
		normal! 
	endif
	return ''
endfunction

function! s:EvaluateRange() range 
	" runs visually highlighted multiline block of code with single call to
	" the interpreter
	let lines = getline(a:firstline, a:lastline)
	let result=''
	redir =>> result
	silent! execute b:ripple_language." ".join(lines,"\n")
	redir END

	" Put the interpreter output into the buffer
	call append(a:lastline,'---Results---')
	call append(a:lastline+1,result)
	execute a:lastline+2
	"normal V"ad
	"call append(line('.'),split(b:bad_char,"\n"))

	if getline(line('.')) =~ b:bad_char
		silent execute '.s/^'.b:bad_char.'//e'
		if b:ripple_language !~ 'ruby\|perl'
			silent execute '.s/'.b:bad_char.'//ge'
		else
			silent execute '.s/'.b:bad_char.b:bad_char.'//ge'
			silent execute '.s/'.b:bad_char.'//ge'
		endif
	endif
endfunction

function! s:EvaluateCurrentLine()
	"get result of the command
	let result = s:DoCommand()
	" and now append and format the result 
	" in the Vim buffer
	call append(line('.'),result)
	normal j
	call append(line('.'),'>>>  _')
	" result has troublesome '<ctrl-@>' characters that we will remove.
	" Quoting them or using literally doesn't work, so a single <ctrl-@> was
	" (hopefully) stored into b:bad_char in s:DoCommand()
	if getline(line('.')) =~ b:bad_char
		silent execute '.s/^'.b:bad_char.'//e'
		"if != 'ruby'
		silent execute '.s/'.b:bad_char.b:bad_char.'//ge'
		silent execute '.s/'.b:bad_char.'//ge'
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

function! s:DoCommand()
	" this function redirects output to a variable, runs the command, and
	" returns result back to s:EvaluateCurrentLine()
	let command = matchstr(getline(line('.')),'>>>\zs.*')
	let b:bad_char=''
	let result = ''
	" tweak: initial p gets expanded to full 'print'
	let command = substitute(command,'^\s*[pP] ','print ','')
	redir =>> result
	silent! exec b:ripple_language." ".command
	redir END
	let b:bad_char=result[0]
	if result == ''
		let result='('.command.' )'
	endif
	return result
endfunction

" Single optional argument: The language for the repl. If none is specified,
" uses default in g:ripple_default_language.
function! ripple#CreateRepl(...)
	if a:0
		let l:ripple_language = a:1
	else
		let l:ripple_language = g:ripple_default_language
	endif

	if !ripple#ValidateLanguage(l:ripple_language)
		return
	endif

	" Setup new buffer
	if exists(':Scratch') == 2
		exec 'silent Scratch '. l:ripple_language
	else
		silent vnew `= l:ripple_language`
		let &ft = l:ripple_language
	endif
	put! ='>>> '
	let b:ripple_language = l:ripple_language

	nnoremap <buffer> <CR> :call <SID>EvaluateFromNormalMode()<CR>
	inoremap <buffer> <CR> <c-r>=<SID>EvaluateFromInsertMode()<CR>
	vnoremap <buffer> <C-CR> :call <SID>EvaluateRange()<CR>

	" TODO: will this work for all languages?
	syn region rippleError start='^Error detected while' end='^\s*\S\+Error:.*$'
	hi rippleError guibg=red

	normal! $
	if has('ex_extra')
		startinsert!
	endif
endfunction

" vim:noet:ts=4 sw=4:
