" Ripple - a read-eval-print-loop inside vim

" TODO:
"	* Write a help file.
"	* Allow newlines so you can write a class or function.
"	* Prevent error on empty line (just prompt).

if !exists('g:loaded_ripple') || &cp || version < 700
	finish
endif

function! ripple#ValidateLanguage(ripple_language, verbose)
	try
		let cmd = g:ripple_filetype_to_cmd[a:ripple_language]
		let is_good = exists(':'. cmd) == 2
		if !is_good
			if a:verbose
				echoerr 'Your vim does not have a :'. cmd .' command. See :help '. a:ripple_language
			endif
		endif
	catch /^Vim\%((\a\+)\)\=:E716/	" Error: Key not present in Dictionary
		let is_good = 0
		if a:verbose
			echoerr 'Language "'. a:ripple_language .'" is unsupported by vim-ripple.'
		endif
	endtry 
	return is_good
endfunction

function! s:EvaluateFromInsertMode()
	" call EvaluateCurrentLine if user pressed <enter> on a line starting with
	" '>>>' (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call s:EvaluateCurrentLine()
	else
		" Use :execute so we can use printable characters instead of raw ^M.
		exec "normal! i\<CR>"
	endif
	return ''
endfunction

function! s:EvaluateFromNormalMode()
	" call EvaluateCurrentLine if user pressed <enter> on a line starting with
	" '>>>' (the single-line "prompt")
	if getline(line('.')) =~ '^>>>'
		call s:EvaluateCurrentLine()
	else
		exec "normal! \<CR>"
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
			silent execute '.s/'.b:bad_char.'/\r/ge'
		else
			silent execute '.s/'.b:bad_char.b:bad_char.'/\r/ge'
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
		silent execute '.s/'.b:bad_char.b:bad_char.'/\r/ge'
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
" tries to use current filetype or g:ripple_default_language.
function! ripple#CreateRepl(...)
	if a:0
		let l:ripple_language = a:1
	elseif g:ripple_filetype_as_default && ripple#ValidateLanguage(&filetype, 0)
		let l:ripple_language = &filetype
	else
		let l:ripple_language = g:ripple_default_language
	endif

	if !ripple#ValidateLanguage(l:ripple_language, 1)
		return
	endif

	" Setup new buffer
	if exists('g:itchy_loaded') && exists(':Scratch') == 2
		" itchy has nice opening behavior and will make it a scratch buffer
		exec 'silent Scratch '. l:ripple_language
	else
		" fall back on simpler behavior
		silent vnew `= l:ripple_language`
		let &ft = l:ripple_language
	endif
	put! ='>>> '
	let b:ripple_language = g:ripple_filetype_to_cmd[l:ripple_language]

	nnoremap <buffer> <CR> :call <SID>EvaluateFromNormalMode()<CR>
	" Should this be <C-CR> so you can write more than one line of code?
	inoremap <buffer> <CR> <c-r>=<SID>EvaluateFromInsertMode()<CR>
	" TODO: Why C-CR
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
