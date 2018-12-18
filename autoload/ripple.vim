" Ripple - a read-eval-print-loop inside vim

" TODO:
"	* Allow newlines so you can write a class or function.
"	* Prevent error on empty line (just prompt).

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
	let result = s:ExecuteCode(lines)

	" Put the interpreter output into the buffer
	call append(a:lastline,'---Results---')
	call append(a:lastline+1, result)
	execute a:lastline + 1 + len(result)
endfunction

function! s:EvaluateCurrentLine()
	"get result of the command
	let result = s:DoCommand()
	call append(line('.'),result)
	exec '+'. len(result)
	call append(line('.'),'>>>  _')
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

function! s:HasTryCatch()
	return len(b:ripple_trycatch)
endf
function! s:ExecuteCode(code_lines)
	let g:ripple_exception = ''
	let code = a:code_lines
	let try_ = []
	let catch_ = []
	let has_try = s:HasTryCatch()
	if has_try
		let try_ = [b:ripple_trycatch[1]]
		let catch_ = b:ripple_trycatch[2:]
		" Indent is probably required for try-catch.
		let code = map(code, '"    ". v:val')
	endif
	let cmd = extend(try_, code)
	if has_try
		let cmd = extend(cmd, catch_)
	endif
	" We'll remove file before closing vim, so no fsync required.
	call writefile(cmd, b:ripple_tempfile, 'S')
	let use_file = b:ripple_language =~# 'file' || b:ripple_language == 'source'
	let result = ''
	redir =>> result
	if use_file
		silent! exec b:ripple_language .' '. b:ripple_tempfile
	else
		silent! exec b:ripple_language .' '. cmd
	endif
	redir END
	" result has lines separated by null bytes.
	let result = split(result, '\%x00')
	" TODO(ex): add callstack and fold it.
	if len(g:ripple_exception)
		let result = add(result, "Exception: ". g:ripple_exception)
	endif
	return result
endf

function! s:DoCommand()
	" this function redirects output to a variable, runs the command, and
	" returns result back to s:EvaluateCurrentLine()
	let command = matchstr(getline(line('.')),'>>>\zs.*')
	" tweak: initial p gets expanded to full 'print'
	let command = substitute(command,'^\s*[pP] ','print ','')
	let result = s:ExecuteCode([command])
	if len(result) == 0
		let result = ['('.command.' )']
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
	let b:ripple_tempfile = tempname()
	augroup Ripple
		au!
		au BufDelete <buffer> call delete(b:ripple_tempfile)
	augroup END
	let b:ripple_trycatch = g:ripple_filetype_trycatch[l:ripple_language]
	" First trycatch param is init code.
	if s:HasTryCatch() && len(b:ripple_trycatch[0])
		" Import vim with the nonfile command.
		let nonfile_cmd = substitute(b:ripple_language, 'file', '', '')
		execute nonfile_cmd .' '. b:ripple_trycatch[0]
	endif

	nnoremap <buffer> <CR> :call <SID>EvaluateFromNormalMode()<CR>
	" Should this be <C-CR> so you can write more than one line of code?
	inoremap <buffer> <CR> <c-r>=<SID>EvaluateFromInsertMode()<CR>
	" TODO: Why C-CR
	vnoremap <buffer> <C-CR> :call <SID>EvaluateRange()<CR>

	" TODO: will this work for all languages?
	" TODO(ex): Add Exception string here.
	syn region rippleError start='^Error detected while' end='^\s*\S\+Error:.*$'
	hi rippleError guibg=red

	normal! $
	if has('ex_extra')
		startinsert!
	endif
endfunction

" vim:noet:ts=4 sw=4:
