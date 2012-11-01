" Function:    Vim filetype plugin for RIS files
"              (as used by RefDB <refdb.sourceforge.net>)
" Last Change: 2005-05-04
" Maintainer:  David Nebauer <david@nebauer.org>
" License:     Public domain

" ========================================================================

" TODO:

" ========================================================================

" 1. REQUIREMENTS                                                    {{{1

" Shell Select:
" For selecting an item from a large menu, this script relies on the
" following shell builtin command construct:
" 		select VAR in OPT1 OPT2 [...] ; do break ; done
" This is available in bash(-like) shells.

" ========================================================================

" 2. CONTROL STATEMENTS                                              {{{1

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Use default cpoptions to avoid unpleasantness from customised
" 'compatible' settings
let s:save_cpo = &cpo
set cpo&vim

" ========================================================================

" 3. FUNCTIONS                                                       {{{1

" ------------------------------------------------------------------------
" Function:   Ris_PickAndInsert                                        {{{2
" Purpose:    Pick and insert pubtypes and ris tags
" Parameters: type  - menu options
"             mode  - mode called from ('i'|other)
" Returns:    NONE
" Credit:     Technique for associating mappings with menu options stolen
"             shamelessly from VimSpell plugin (author: Mathieu Clabaut)
if !exists( "*s:Ris_PickAndInsert" )
function s:Ris_PickAndInsert( type, mode )
	" variables
	let l:msg_no_if = "No matching if block in PickAndInsert."
	if     a:type == 'pubtype'
		let l:title = 'PUBLICATION TYPES'
		let l:prompt = 'Type letter for Pubtype or <Esc> to abort:'
		let l:opts = s:pub_types_short
		let l:fn = "Ris__InsertPubType"
	elseif a:type == 'ristag'
		let l:title = 'RIS TAGS'
		let l:prompt = 'Type letter for RIS tag or <Esc> to abort:'
		let l:opts = s:ris_tags_short
		let l:fn = "Ris__InsertRisTag"
	else | call s:Ris__ShowMsg( l:msg_no_if, "Error" ) | return 0
	endif
	" build command
	let l:mnu_opt = s:Ris__ExtractListElement( l:opts, '@', 'element' )
	let l:mnu_all = s:Ris__ExtractListElement( l:opts, '@', 'list' )
	let l:cmd = '' | let l:mnu_label = '' | let l:output = ''
	while l:mnu_opt != ''
		let l:tag = strpart( l:mnu_opt, 0, match( l:mnu_opt, ':' ) )
		let l:mnu_label = s:Ris__NextMenuLabel( l:mnu_label )  " a-zA-Z0-9
		let l:mnu_opt = l:mnu_label . ') ' . l:mnu_opt  " a menu option
		let l:output = s:Ris__PadEnd( l:output . l:mnu_opt )  " right pad
		if strlen( l:output) > 32  " print output (32 allows for unicode)
			let l:cmd = s:Ris__AddToCmd( l:cmd, "echo \"" . l:output . "\"" )
			let l:output = ''
		endif
		let l:new_cmd = "noremap <silent> <buffer> " . l:mnu_label
					\ . " :let r=<SID>" . l:fn . "( '" . l:tag
					\ . "', \"" . a:mode . "\" )<CR>"
		let l:cmd = s:Ris__AddToCmd( l:cmd, l:new_cmd )  " the magic command
		let l:mnu_opt = s:Ris__ExtractListElement( l:mnu_all, '@', 'element' )
		let l:mnu_all = s:Ris__ExtractListElement( l:mnu_all, '@', 'list' )
	endwhile
	if strlen( l:output) > 0  " print any final output
		let l:cmd = s:Ris__AddToCmd( l:cmd, "echo \"" . l:output . "\"" )
	endif
	" execute
	echo l:title
	echo l:prompt
	execute l:cmd  | " prints menu and creates mappings for each option
	if a:mode == 'i'  " <Esc> is mapped to allow for aborting
		map <silent> <buffer> <Esc> <CR>
					\:let r=<SID>Ris__RemoveMappings()<CR>
					\:let r=<SID>Ris__StartInsert( 1 )<CR>
	else
		map <silent> <buffer> <Esc> <CR>:let r=<SID>Ris__RemoveMappings()<CR>
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris_InsertReprintStatus                                {{{2
" Purpose:    Insert reprint status
" Parameters: (optional) mode function called from ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris_InsertReprintStatus" )
function s:Ris_InsertReprintStatus( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" set prompt and options
	let l:msg  = "Select reprint status: "
	let l:opts = "&IN FILE\n&NOT IN FILE\n&ON REQUEST MM/DD/YYYY"
	" make choice
	let l:status = ""
	let l:choice = confirm( l:msg, l:opts, 2 )
	if     l:choice == 1 | let l:status = "IN FILE"
	elseif l:choice == 2 | let l:status = "NOT IN FILE"
	elseif l:choice == 3
		let l:date = s:Ris__GetReprintDate()
		let l:status = l:date
		if l:status != "" | let l:status = "ON REQUEST " . l:status | endif
	else                 | let l:status = ""
	endif
	" insert type
	if l:status != "" | call s:Ris__InsertString( l:status, 1 ) | endif
	" finish in insert mode if called from there
	if a:0 > 0 && a:1 == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris_DuplicateTag                                       {{{2
" Purpose:    Insert duplicate tag
" Parameters: (optional) mode function called from ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris_DuplicateTag" )
function s:Ris_DuplicateTag( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" if current line has tag, duplicate it on next line
	let l:line = getline( "." )
	if l:line =~ '^[A-Z][A-Z0-5]  - '
		let l:ristag = strpart( l:line, 0, 6 )
		call append( ".", l:ristag )
		call cursor( line( "." ) + 1, col( "$" ) )
	else  " check previous line
		let l:line = getline( line( "." ) - 1 )
		if l:line =~ '^[A-Z][A-Z0-5]  - '
			let l:ristag = strpart( l:line, 0, 6 )
			call s:Ris__InsertString( l:ristag, 1 )
		else  " neither line had tag
			call confirm( 
						\ 	"Sorry, no tag on current or previous line.",
						\ 	"&Ok",
						\ 	1,
						\ 	"Error"
						\ )
		endif
	endif
	" finish in insert mode if called from there
	if a:0 > 0 && a:1 == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris_AddTemplate                                        {{{2
" Purpose:    Insert publication template (blank tags)
" Parameters: (optional) mode function called from ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris_AddTemplate" )
function s:Ris_AddTemplate( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" ensure blank line
	if getline( "." ) != ""
		call append( ".", "" )
		call cursor( line( "." ) + 1, col( "$" ) )
	endif
	" remember where we started
	let l:cur_row = line( "." ) + 1
	" decide type of reference
	let l:choices = "&Journal\n&Book\n&Other (all tags)"
	let l:msg = "Select type of reference: "
	let l:choice = confirm( l:msg, l:choices )
	if     l:choice == 1 | let l:use_list = s:tags_jrnl
	elseif l:choice == 2 | let l:use_list = s:tags_book
	else                 | let l:use_list = s:tags_all
	endif
	" cycle through tags and add those required
	let l:items = s:tags_all
	while l:items != ""
		" extract next tag
        let l:ris_tag = strpart( l:items, 0, match( l:items, "@" ) )
		let l:items = strpart( l:items, match( l:items, "@" ) + 1 )
		" add tag if on request list
		if match( l:use_list, l:ris_tag . "@" ) != -1
			let l:ris_tag = l:ris_tag . "  - "
			call append( ".", l:ris_tag )
			call cursor( line( "." ) + 1, col( "$" ) )
		endif
	endwhile
	" back to starting location
	call cursor( l:cur_row, 1 )
	" finish in insert mode if called from there
	if a:0 > 0 && a:1 == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris_ShowHelp                                           {{{2
" Purpose:    Show help
" Parameters: (optional) mode function called from ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris_ShowHelp" )
function s:Ris_ShowHelp( ... )
	" clean up status line
	if !has( "gui_running" ) | echo | echo | endif
	" build help
	let l:msg = "Available RIS-related commands:\n\n"
				\ . "<Leader>p  - Select publication type and insert\n"
				\ . "<Leader>r  - Select reprint status and insert\n"
				\ . "<Leader>d  - Duplicate tag\n"
				\ . "<Leader>a  - Select RIS tag and insert\n"
				\ . "<Leader>t  - Insert reference template\n\n"
				\ . "Note: Default <Leader> is '\\' so commands are:\n"
				\ . "      '\\p', '\\d' , '\\a' and '\\t'"
	" display help
	call confirm( l:msg )
	" finish in insert mode if called from there
	if a:0 > 0 && a:1 == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__GetInput                                          {{{2
" Purpose:    Handles user input for gui and console modes
" Parameters: prompt  - user prompt
"             default - default value
" Returns:    string - user input
if !exists( "*s:Ris__GetInput" )
function s:Ris__GetInput( prompt, default )
	if has( "gui_running" )
		let l:input = inputdialog( a:prompt, a:default )
	else
		let l:input = input( a:prompt, a:default )
	endif
	return l:input
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__ShowMsg                                           {{{2
" Purpose:    Display message to user
" Parameters: msg             - user prompt
"             type (optional) - 'generic'|'warning'|'info'|'question'|'error'
" Returns:    NONE
if !exists( "*s:Ris__ShowMsg" )
function s:Ris__ShowMsg( msg, ... )
	let l:msg = a:msg
	let l:type = ''
	" sanity check
	let l:error = 0
	if l:msg == ''
		let l:msg = "NO MESSAGE SUPPLIED TO 'Ris__DisplayMessage'."
		let l:error = 1
		let l:type = "Error"
	endif
	" set dialog type (if valid type supplied and not overridden by error)
	if ! l:error
		if a:0 > 0 && tolower( a:1 ) =~ 'warning\|info\|question\|error'
			let l:type = tolower( a:1 )
		endif
	endif
	" for non-gui environment add message type to output
	if !has ( "gui_running" ) && l:type != ""
		let l:msg = toupper( strpart( l:type, 0, 1 ) ) 
					\ . tolower( strpart( l:type, 1 ) )
					\ . ": " 
					\ . l:msg
	endif
	" display message
	call confirm( l:msg, "&OK", 1, l:type )
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__InsertString                                      {{{2
" Purpose:    Insert string at current cursor location
" Parameters: inserted_text - string for insertion
"             restrictive   - boolean (1|0) indicating whether 'paste'
"                             setting used
" Returns:    NONE
if !exists( "*s:Ris__InsertString" )
function s:Ris__InsertString( inserted_text, restrictive )
	if a:restrictive | let l:paste_setting = &paste | set paste | endif
	silent execute "normal a" . a:inserted_text
	if a:restrictive && ! l:paste_setting | set nopaste | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__StartInsert                                       {{{2
" Purpose:    Switch to insert mode
" Parameters: column adjustment before entering insert mode
" Returns:    NONE
if !exists( "*s:Ris__StartInsert" )
function s:Ris__StartInsert( adjust )
	" override adjustment if cursor at eol to prevent error beep
	if col( "." ) >= col( "$" ) | let l:adjust = 0
	else                        | let l:adjust = a:adjust
	endif
	" adjust cursor position
	call cursor( ".", col( "." ) + l:adjust )
	" handle case where cursor at end of line
	if col( "." ) >= strlen( getline( "." ) ) | startinsert!  " ~ 'A'
	else                                      | startinsert   " ~ 'i'
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__GetReprintDate                                    {{{2
" Purpose:    Assembles reprint date from user input
" Parameters: NONE
" Returns:    Date formatted as MM/DD/YYYY
if !exists( "*s:Ris__GetReprintDate" )
function s:Ris__GetReprintDate()
	" first need year
	let l:year = s:Ris__GetInput( "Enter year: ", strftime( "%Y" ) )
	if l:year !~ '^\d\{4}$'
		call s:Ris__ShowMsg( "Invalid year", "Error" )
		return ""
	endif
	" now get month
	let l:month = s:Ris__GetDateComponent( "month", 12 )
	if l:month == "" | return "" | endif
	" determine maximum legal day
	if l:month =~ '^\%(09\|04\|06\|11\)$' | let l:maxday = 30 | endif
	if l:month =~ '^\%(01\|03\|05\|07\|08\|10\|12\)$'
		let l:maxday = 31
	endif
	if l:month == "02"
		let l:maxday = s:Ris__IsLeapYear( l:year ) ? 29 : 28
	endif
	" get day
	let l:day = s:Ris__GetDateComponent( "day", l:maxday )
	if l:day == "" | return "" | endif
	" return date value
	let l:retval = l:month . "/" . l:day . "/" . l:year
	return l:retval
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__GetDateComponent                                  {{{2
" Purpose:    Get month or day value
" Parameters: component name - 'month'|'day'
"             maximum        - maximum value allowed
" Returns:    formatted number (two chars)
if !exists( "*s:Ris__GetDateComponent" )
function s:Ris__GetDateComponent( component, maximum )
	" get component value
	let l:msg = "Enter " . a:component . " [1-" . a:maximum . "]: "
	let l:val = s:Ris__GetInput( l:msg, "" )
	" strip leading zeros
	while strpart( l:val, 0, 1 ) == "0"
		let l:val = strpart( l:val, 1 )
	endwhile
	" check is valid integer
	" test 1 - consists solely of digits
	" test 2 - is non-zero
	" test 3 - does not exceed maximum value
	if l:val =~ '^\d\{1,}$'
				\ && strpart( l:val, 0, 1 ) != "0" 
				\ && l:val <= a:maximum
		" is valid -- now format to two chars
		if l:val =~ '^\%(1\|2\|3\|4\|5\|6\|7\|8\|9\)$'
			let l:val = "0" . l:val
		endif
		" return result
		return l:val
	else  " not valid integer
		call s:Ris__ShowMsg( "Invalid " . a:component, "Error" )
		return ""
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__IsLeapYear                                        {{{2
" Purpose:    Determine if year is leap year
" Parameters: Year
" Returns:    Boolean ('1' = true | '0' = false)
" Note:       Assumes Gregorian calendar
if !exists( "*s:Ris__IsLeapYear" )
function s:Ris__IsLeapYear( year )
	let true = 1
	let false = 0
	if a:year < 0 | return ( ( a:year + 1 ) % 4 == 0 ) ? true : false | endif
	if a:year < 1582 | return ( a:year % 4 == 0 ) ? true : false | endif
	if a:year % 4 != 0 | return false | endif
	if a:year % 100 != 0 | return true | endif
	if a:year % 400 != 0 | return false | endif
	return true
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__NextMenuLabel                                     {{{2
" Purpose:    Returns next menu label in sequence a-z, A-Z, 0-9
" Parameters: label - (optional) current label
" Returns:    char  - next menu label ('' when labels exhausted)
if !exists( "*s:Ris__NextMenuLabel" )
function s:Ris__NextMenuLabel( ... )
	" if no label, issue first
	if a:0 == 0 || ( a:0 > 0 && a:1 == '' ) | return 'a' | endif
	" process label
	let l:nr = char2nr( a:1 )
	if     l:nr == 122  " is 'z', jump to 'A'
		return 'A'
	elseif l:nr == 90   " is 'Z', jump to '0'
		return '0'
	elseif l:nr == 57   " is '9', have exhausted labels
		return ''
	else                " increment
		return nr2char( l:nr + 1 )
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__RemoveMappings                                    {{{2
" Purpose:    Removes mappings created by Ris_PickAndInsert
" Parameters: NONE
" Returns:    NONE
if !exists( "*s:Ris__RemoveMappings" )
function s:Ris__RemoveMappings()
	" start with first mapping and proceed
	let l:mapping = 'a'
	while l:mapping != ''
		if maparg( l:mapping ) != ''
			execute "map <silent> <buffer> " . l:mapping . " x"
			execute "unmap <silent> <buffer> " . l:mapping
		else | break
		endif
		let l:mapping = s:Ris__NextMenuLabel( l:mapping )
	endwhile
	map <silent> <buffer> <Esc> p
	unmap <silent> <buffer> <Esc>
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__ExtractListElement                                {{{2
" Purpose:    Extracts first element from list
" Parameters: list        - delimited list
"             delimiter   - character delimiting list elements
"             return_type - what to return ('list'|'element')
" Returns:    string - either first element or shrunken list
if !exists( "*s:Ris__ExtractListElement" )
function s:Ris__ExtractListElement( list, delimiter, return_type )
	" variables
	let l:msg_no_if = "No matching if block in ExtractListElement."
	" catch end of list condition
	if a:list == '' || a:list == '@' | return '' | endif
	" extract element
	let l:delim = match( a:list, a:delimiter )  " first delimiter
	if l:delim == -1  " assume only last element remaining in list
		let l:element = a:list
		let l:list = ''
	else  " multiple elements remaining
		let l:element = strpart( a:list, 0, l:delim )
		let l:list = strpart( a:list, l:delim + 1 )
	endif
	" return requested value
	if     a:return_type == 'element' | return l:element
	elseif a:return_type == 'list'    | return l:list
	else | call s:Ris__ShowMsg( l:msg_no_if, "Error" ) | return 0
	endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__AddToCmd                                          {{{2
" Purpose:    Adds command to command string
" Parameters: current - current command string
"             new     - new command string
" Returns:    string - new command string
if !exists( "*s:Ris__AddToCmd" )
function s:Ris__AddToCmd( current, new )
	return a:current == '' ? a:new : a:current . "| " . a:new
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__PadEnd                                            {{{2
" Purpose:    Right justify string to 30 or greater chars
" Parameters: string - string to right justify
" Returns:    string - justified string
if !exists( "*s:Ris__PadEnd" )
function s:Ris__PadEnd( string )
	let l:string = a:string
	let l:length = strlen( l:string )
	" determine target length
	if     l:length < 29 | let l:target = 30
	else                 | let l:target = l:length
	endif
	" compensate for unicode (which count as two chars but occupy only one)
	let l:count = 0
	while l:count < l:length
		if char2nr( l:string[l:count] ) > 122
			let l:target = l:target + 1
			let l:count = l:count + 1
		endif
		let l:count = l:count + 1
	endwhile
	" pad string
	while strlen( l:string ) < l:target
		let l:string = l:string . ' '
	endwhile
	" done
	return l:string
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__InsertPubType                                      {{{2
" Purpose:    Insert tag
" Parameters: tag  - tag to insert
"             mode - mode to return to ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris__InsertPubType" )
function s:Ris__InsertPubType( tag, mode )
	call s:Ris__RemoveMappings()
	call s:Ris__InsertString( a:tag, 1 )
	if a:mode == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__InsertRisTag                                       {{{2
" Purpose:    Insert ris tag
" Parameters: tag  - tag to insert
"             mode - mode to return to ('i'|other)
" Returns:    NONE
if !exists( "*s:Ris__InsertRisTag" )
function s:Ris__InsertRisTag( tag, mode )
	" prevent recursion
	call s:Ris__RemoveMappings()
	" insert tag
	let l:line = getline( "." )
	if getline( "." ) == ""
		call s:Ris__InsertString( a:tag . "  - ", 1 )
	else
		call append( ".", a:tag . "  - " )
		call cursor( line( "." ) + 1, col( "$" ) )
	endif
	" finish in insert mode if called from there
	if a:mode == "i" | call s:Ris__StartInsert( 1 ) | endif
endfunction
endif  " function wrapper
" ------------------------------------------------------------------------
" Function:   Ris__InstallDocumentation                              {{{2
" Purpose:    Install help documentation
" Parameters: full_name  - filepath of this vim plugin script
" Returns:    boolean    - indicating whether help doc installed (1|0)
" Credits:    Document installation mechanism copied from 'xml.vim'
"             xml.vim maintainer: Devin Weaver
"             author of 'self-install' code: Guo-Peng Wen
if !exists( "*s:Ris__InstallDocumentation" )
function s:Ris__InstallDocumentation( full_name )
    " name of the document path based on the system we use
    if (has("unix"))
		" on *nix systems use '/'
		let l:slash_char = '/'
		let l:mkdir_cmd  = ':silent !mkdir -p '
    else
		" on MS systems (w2k and later) use '\'; also different mkdir syntax
		let l:slash_char = '\'
		let l:mkdir_cmd  = ':silent !mkdir '
    endif
    let l:doc_path = l:slash_char . 'doc'
    let l:doc_home = l:slash_char . '.vim' . l:slash_char . 'doc'
    " figure out document path based on full name of this script
    let l:vim_plugin_path = fnamemodify(a:full_name, ':h')
    let l:vim_doc_path	  = fnamemodify(a:full_name, ':h:h') . l:doc_path
    if ( !( filewritable( l:vim_doc_path ) == 2 ) )
		echomsg "Doc path: " . l:vim_doc_path
		execute l:mkdir_cmd . l:vim_doc_path
		if ( !( filewritable( l:vim_doc_path ) == 2 ) )
			" try a default configuration in user home
			let l:vim_doc_path = expand( "~" ) . l:doc_home
			if ( !( filewritable( l:vim_doc_path ) == 2 ) )
				execute l:mkdir_cmd . l:vim_doc_path
				if ( !( filewritable( l:vim_doc_path ) == 2 ) )
					" give a warning
					echomsg "Unable to open documentation directory"
					echomsg " type :help add-local-help for more informations."
					return 0
				endif
			endif
		endif
    endif
    " exit if we have problem accessing the document directory:
    if ( !isdirectory( l:vim_plugin_path )
				\ || !isdirectory( l:vim_doc_path )
				\ || filewritable( l:vim_doc_path ) != 2 )
		return 0
    endif
    " full name of script and documentation file
    let l:script_name = 'ris.vim'
    let l:doc_name    = 'ris-plugin.txt'
    let l:plugin_file = l:vim_plugin_path . l:slash_char . l:script_name
    let l:doc_file    = l:vim_doc_path	  . l:slash_char . l:doc_name
    " bail out if document file is still up to date
    if ( filereadable( l:doc_file )  &&
				\ getftime( l:plugin_file ) < getftime( l:doc_file ) )
		return 0
    endif
    " prepare window position restoring command
    if ( strlen( @% ) )
		let l:go_back = 'b ' . bufnr( "%" )
    else
		let l:go_back = 'enew!'
    endif
    " create a new buffer & read in the plugin file (me)
    setl nomodeline
    exe 'enew!'
    exe 'r ' . l:plugin_file
    setl modeline
    let l:buf = bufnr("%")
    setl noswapfile modifiable
    norm zR
    norm gg
    " delete from first line to a line starts with '=== START_DOC'
    1,/^=\{3,}\s\+START_DOC\C/ d
    " delete from a line starts with '=== END_DOC' to the end of doc
    /^=\{3,}\s\+END_DOC\C/,$ d
    " remove fold marks
    % s/{\{3}[1-9]/    /
    " add modeline for help doc (mangled intentionally)
    call append(line('$'), '')
    call append(line('$'), '')
    call append(line('$'), ' v' . 'im:tw=78:ts=8:ft=help:norl:')
    " save the help document
    exe 'w! ' . l:doc_file
    exe l:go_back
    exe 'bw ' . l:buf
    " build help tags
    exe 'helptags ' . l:vim_doc_path
	" installed doc successfully
    return 1
endfunction
endif  " function wrapper

" ========================================================================

" 4. SCRIPT VARIABLES                                                {{{1

" Publication types
let s:pub_types = "\"ABST: abstract reference\" "
			\ . "\"ADVS: audiovisual material\" "
			\ . "\"ART: art work\" "
			\ . "\"BILL: bill/resolution\" "
			\ . "\"BOOK: whole book reference\" "
			\ . "\"CASE: case\" "
			\ . "\"CHAP: book chapter reference\" "
			\ . "\"COMP: computer program\" "
			\ . "\"CONF: conference proceeding\" "
			\ . "\"CTLG: catalog\" "
			\ . "\"DATA: data file\" "
			\ . "\"ELEC: electronic citation\" "
			\ . "\"GEN: generic\" "
			\ . "\"HEAR: hearing\" "
			\ . "\"ICOMM: internet communication\" "
			\ . "\"INPR: in press reference\" "
			\ . "\"JFULL: journal/periodical - full\" "
			\ . "\"JOUR: journal/periodical reference\" "
			\ . "\"MAP: map\" "
			\ . "\"MGZN: magazine article\" "
			\ . "\"MPCT: motion picture\" "
			\ . "\"MUSIC: music score\" "
			\ . "\"NEWS: newspaper\" "
			\ . "\"PAMP: pamphlet\" "
			\ . "\"PAT: patent\" "
			\ . "\"PCOMM: personal communication\" "
			\ . "\"RPRT: report\" "
			\ . "\"SER: serial - book, monograph\" "
			\ . "\"SLIDE: slide\" "
			\ . "\"SOUND: sound recording\" "
			\ . "\"STAT: statute\" "
			\ . "\"THES: thesis/dissertation\" "
			\ . "\"UNBILL: unenacted bill/resolution\" "
			\ . "\"UNPB: unpublished work reference\" "
			\ . "\"VIDEO: video recording\" "
let s:pub_types_short = "ABST: abstract@"
			\ . "ADVS: audiovisual@"
			\ . "ART: art work@"
			\ . "BILL: bill/resolution@"
			\ . "BOOK: whole book@"
			\ . "CASE: case@"
			\ . "CHAP: book chapter@"
			\ . "COMP: computer program@"
			\ . "CONF: conference@"
			\ . "CTLG: catalog@"
			\ . "DATA: data file@"
			\ . "ELEC: electronic@"
			\ . "GEN: generic@"
			\ . "HEAR: hearing@"
			\ . "ICOMM: internet comm.@"
			\ . "INPR: in press@"
			\ . "JFULL: journal-full@"
			\ . "JOUR: journal@"
			\ . "MAP: map@"
			\ . "MGZN: magazine article@"
			\ . "MPCT: motion picture@"
			\ . "MUSIC: music score@"
			\ . "NEWS: newspaper@"
			\ . "PAMP: pamphlet@"
			\ . "PAT: patent@"
			\ . "PCOMM: personal comm.@"
			\ . "RPRT: report@"
			\ . "SER: serial@"
			\ . "SLIDE: slide@"
			\ . "SOUND: sound recording@"
			\ . "STAT: statute@"
			\ . "THES: thesis@"
			\ . "UNBILL: unenacted bill@"
			\ . "UNPB: unpublished@"
			\ . "VIDEO: video recording@"

" Tags
let s:ris_tags = "\"TY: Publication type\" "
			\ . "\"TI: Publication title\" "
			\ . "\"T2: Secondary title\" "
			\ . "\"T3: Tertiary title\" "
			\ . "\"AU: Author (=A1)\" "
			\ . "\"A2: Editor (=ED)\" "
			\ . "\"A3: Series editor\" "
			\ . "\"PY: Publication date (=Y1)\" "
			\ . "\"Y2: Secondary publication date\" "
			\ . "\"N1: Notes\" "
			\ . "\"N2: Abstract (=AB)\" "
			\ . "\"KW: Keyword\" "
			\ . "\"RP: Reprint status\" "
			\ . "\"AV: Availability information\" "
			\ . "\"SP: Start page\" "
			\ . "\"EP: End page\" "
			\ . "\"JO: Journal name (abbreviated)\" "
			\ . "\"JF: Journal name (full)\" "
			\ . "\"J1: Journal name (user abbr.)\" "
			\ . "\"J2: Journal name (user abbr.)\" "
			\ . "\"VL: Volume\" "
			\ . "\"IS: Issue\" "
			\ . "\"CY: City of publication\" "
			\ . "\"PB: Publisher\" "
			\ . "\"SN: ISBN or ISSN number\" "
			\ . "\"AD: Contact address\" "
			\ . "\"UR: URL of online version\" "
			\ . "\"U1: User defined field\" "
			\ . "\"U2: User defined field\" "
			\ . "\"U3: User defined field\" "
			\ . "\"U4: User defined field\" "
			\ . "\"U5: User defined field\" "
			\ . "\"M1: Miscellaneous field\" "
			\ . "\"M2: Miscellaneous field\" "
			\ . "\"M3: Miscellaneous field\" "
			\ . "\"ER: End of reference\" "
let s:ris_tags_short = "TY: Publication type@"
			\ . "TI: Publication title@"
			\ . "T2: 2° title@"
			\ . "T3: 3° title@"
			\ . "AU: Author (=A1)@"
			\ . "A2: Editor (=ED)@"
			\ . "A3: Series editor@"
			\ . "PY: Publn. date (=Y1)@"
			\ . "Y2: 2° publn. date@"
			\ . "N1: Notes@"
			\ . "N2: Abstract (=AB)@"
			\ . "KW: Keyword@"
			\ . "RP: Reprint status@"
			\ . "AV: Availability@"
			\ . "SP: Start page@"
			\ . "EP: End page@"
			\ . "JO: Jnl name (abbr.)@"
			\ . "JF: Jnl name (full)@"
			\ . "J1: Jnl (user abbr.)@"
			\ . "J2: Jnl (user abbr.)@"
			\ . "VL: Volume@"
			\ . "IS: Issue@"
			\ . "CY: City of publn.@"
			\ . "PB: Publisher@"
			\ . "SN: ISBN/ISSN number@"
			\ . "AD: Contact address@"
			\ . "UR: online URL@"
			\ . "U1: User defined@"
			\ . "U2: User defined@"
			\ . "U3: User defined@"
			\ . "U4: User defined@"
			\ . "U5: User defined@"
			\ . "M1: Miscellaneous@"
			\ . "M2: Miscellaneous@"
			\ . "M3: Miscellaneous@"
			\ . "ER: End of reference@"

" Tags needed by different reference types
let s:tags_book = "TY@BT@AU@PY@KW@RP@CY@PB@ER@"
let s:tags_jrnl = "TY@TI@AU@PY@N1@KW@RP@SP@EP@VL@IS@CY@PB@ER@"
let s:tags_all  = "TY@ID@T1@T2@T3@TI@CT@BT@A1@AU@Y1@PY@N1@AB@KW@RP@SP@EP@JF@JO@JA@J1@J2@VL@BT@A2@ED@IS@CP@CY@PB@U1@U2@U3@U4@U5@A3@N2@SN@AV@Y2@M1@M2@M3@AD@UR@L1@L2@L3@L4@ER@"

" ========================================================================

" 5. CONTROL STATEMENTS                                              {{{1

" restore user's cpoptions
let &cpo = s:save_cpo

" install documentation
let s:installed = s:Ris__InstallDocumentation( expand( "<sfile>:p" ) )
if ( s:installed == 1 )
    let msg = expand( "<sfile>:t:r" )
  			  \ . "-plugin: Help-documentation installed."
    echom msg
endif

" ========================================================================

" 6. MAPPINGS AND MENUS                                              {{{1

" User can prevent mappings by setting these variables
if !exists("no_plugin_maps") && !exists("no_ris_maps")

" Insert Publication Type:                                           {{{2
if !hasmapto( '<Plug>iPubType' )
	imap <buffer> <unique> <LocalLeader>p <Plug>iPubType
endif
inoremap <script> <unique> <Plug>iPubType <Esc>:call
			\ <SID>Ris_PickAndInsert( 'pubtype', 'i' )<CR>
inoremenu <silent> 500.10 
			\ &Ris.Insert\ &Pubtype<Tab><Leader>p 
			\ <Esc>:call <SID>Ris_PickAndInsert( 'pubtype', 'i' )<CR>
if !hasmapto( '<Plug>nPubType' )
	nmap <buffer> <unique> <LocalLeader>p <Plug>nPubType
endif
nnoremap <script> <unique> <Plug>nPubType :call
			\ <SID>Ris_PickAndInsert( 'pubtype', 'n' )<CR>
nnoremenu 500.10 
			\ &Ris.Insert\ &Pubtype<Tab><Leader>p 
			\ :call <SID>Ris_PickAndInsert( 'pubtype', 'n' )<CR>

" Insert Reprint Status:                                             {{{2
if !hasmapto( '<Plug>iReprint' )
	imap <buffer> <unique> <LocalLeader>r <Plug>iReprint
endif
inoremap <script> <unique> <Plug>iReprint <Esc>:call
			\ <SID>Ris_InsertReprintStatus( "i" )<CR>
inoremenu <silent> 500.20 
			\ &Ris.Insert\ &Reprint\ Status<Tab><Leader>r 
			\ :call <SID>Ris_InsertReprintStatus( "i" )<CR>
if !hasmapto( '<Plug>nReprint' )
	nmap <buffer> <unique> <LocalLeader>r <Plug>nReprint
endif
nnoremap <script> <unique> <Plug>nReprint <Esc>:call
			\ <SID>Ris_InsertReprintStatus( "n" )<CR>
nnoremenu 500.20 
			\ &Ris.Insert\ &Reprint\ Status<Tab><Leader>r 
			\ :call <SID>Ris_InsertReprintStatus( "n" )<CR>

" Duplicate Tag:                                                     {{{2
if !hasmapto( '<Plug>iTagDupl' )
	imap <buffer> <unique> <LocalLeader>d <Plug>iTagDupl
endif
inoremap <script> <unique> <Plug>iTagDupl <Esc>:call
			\ <SID>Ris_DuplicateTag( "i" )<CR>
inoremenu <silent> 500.30 
			\ &Ris.&Duplicate\ Tag<Tab><Leader>d 
			\ <Esc>:call <SID>Ris_DuplicateTag( "i" )<CR>
if !hasmapto( '<Plug>nTagDupl' )
	nmap <buffer> <unique> <LocalLeader>d <Plug>nTagDupl
endif
nnoremap <script> <unique> <Plug>nTagDupl <Esc>:call
			\ <SID>Ris_DuplicateTag( "n" )<CR>
nnoremenu 500.30 
			\ &Ris.&Duplicate\ Tag<Tab><Leader>d 
			\ :call <SID>Ris_DuplicateTag( "n" )<CR>

" Add Tag:                                                           {{{2
if !hasmapto( '<Plug>iTagAdd' )
	imap <buffer> <unique> <LocalLeader>a <Plug>iTagAdd
endif
inoremap <script> <unique> <Plug>iTagAdd <Esc>:call
			\ <SID>Ris_PickAndInsert( 'ristag', 'i' )<CR>
inoremenu <silent> 500.40 
			\ &Ris.&Add\ Tag<Tab><Leader>a 
			\ <Esc>:call <SID>Ris_PickAndInsert( 'ristag', 'i' )<CR>
if !hasmapto( '<Plug>nTagAdd' )
	nmap <buffer> <unique> <LocalLeader>a <Plug>nTagAdd
endif
nnoremap <script> <unique> <Plug>nTagAdd :call
			\ <SID>Ris_PickAndInsert( 'ristag', 'n' )<CR>
nnoremenu 500.40 
			\ &Ris.&Add\ Tag<Tab><Leader>a :call
			\ <SID>Ris_PickAndInsert( 'ristag', 'n' )<CR>

" Add Template:                                                      {{{2
if !hasmapto( '<Plug>iTemplateAdd' )
	imap <buffer> <unique> <LocalLeader>t <Plug>iTemplateAdd
endif
inoremap <script> <unique> <Plug>iTemplateAdd <Esc>:call
			\ <SID>Ris_AddTemplate( "i" )<CR>
inoremenu <silent> 500.50 
			\ &Ris.Add\ &Template<Tab><Leader>t 
			\ <Esc>:call <SID>Ris_AddTemplate( "i" )<CR>
if !hasmapto( '<Plug>nTemplateAdd' )
	nmap <buffer> <unique> <LocalLeader>t <Plug>nTemplateAdd
endif
nnoremap <script> <unique> <Plug>nTemplateAdd :call
			\ <SID>Ris_AddTemplate( "n" )<CR>
nnoremenu 500.50 
			\ &Ris.Add\ &Template<Tab><Leader>t 
			\ :call <SID>Ris_AddTemplate( "n" )<CR>

" Show Help:                                                         {{{2
if !hasmapto( '<Plug>iShowHelp' )
	imap <buffer> <unique> <LocalLeader>h <Plug>iShowHelp
endif
inoremap <script> <unique> <Plug>iShowHelp <Esc>:call
			\ <SID>Ris_ShowHelp( "i" )<CR>
inoremenu <silent> 500.60 
			\ &Ris.&Help<Tab><Leader>h 
			\ <Esc>:call <SID>Ris_ShowHelp( "i" )<CR>
if !hasmapto( '<Plug>nShowHelp' )
	nmap <buffer> <unique> <LocalLeader>h <Plug>nShowHelp
endif
nnoremap <script> <unique> <Plug>nShowHelp :call
			\ <SID>Ris_ShowHelp( "n" )<CR>
nnoremenu 500.60 
			\ &Ris.&Help<Tab><Leader>h 
			\ :call <SID>Ris_ShowHelp( "n" )<CR>

endif  " mappings

" ========================================================================
" }}}1
finish
" 7. DOCUMENTATION                                                 {{{1

=== START_DOC
RIS Plugin and Syntax {{{2                                      *vim-ris*
=========================================================================
1. Contents {{{2

	1. Contents ......................... |ris-contents|
	2. Overview ......................... |ris-overview|
	3. Plugin ........................... |ris-mappings|
	4. Syntax ........................... |ris-dependencies|

=========================================================================
2. RIS Overview {{{2                                       *ris-overview*


A filetype plugin and syntax file to help edit RIS files.

RIS is a tagged file format used to define bibliographic references.  It was created for use in the 'Reference Manager' product <www.refman.com> and is used by other applications.  The canonical specification is that found at the aforementioned URL.  Unfortunately, it is incomplete and has some apparent internal contradictions.  The RefDB application <refdb.sourceforge.net> contains its own RIS specification (see the RefDB manual for details).  The syntax file was created using both specifications.

=========================================================================
3. RIS Plugin {{{2                                           *ris-plugin*


A complete list of mappings and a short description of the associated functionality is available by using the <Leader>h mapping.

The plugin file supplies five convenience commands mapped to keyboard shortcuts:
	<Leader>a = insert RIS tag (select from menu)
	<Leader>p = insert publication type (select from menu)
	<Leader>r = insert reprint status
	<Leader>d = duplicate current/previous tag
	<Leader>t = add reference template (group of blank tags; choose from three templates: journal|book|other)

All mappings are available via the 'Ris' menu (see |console-menus| for how to access menus from a console vim).

The plugin has the following limitations: it relies on the shell's in-built select command to handle menu selection for RIS field tags publication types. All bash-like shells have this feature.  Vim versions compiled with a GUI (e.g., some versions of GVim) may not handle menu selection properly.


=========================================================================
4. RIS Syntax {{{2                                           *ris-syntax*


The syntax file enables Vim to highlight legal tags and mark illegal tags as errors.

It also highlights correct field values, thus helping users to avoid invalid field values.  It checks the syntax of author names, dates and journal abbreviation fields.  It checks the values in reprint and pubtype fields.  It also checks the length of length-limited fields and does some other rudimentary error checking.

What the syntax file does not currently do is handle line continuations ('/$') -- it assumes all fields are a single line

=========================================================================
5. RIS Limitations {{{2                                 *ris-limitations*


See |ris-plugin| and |ris-syntax| for limitations specific to each.

This plugin and syntax were developed and tested on a Debian Sarge/testing system. They may not work correctly on other operating systems. Windows users, in particular, are likely to experience unpredictable behaviour.

If you encounter any problems, please email me a bug report. Even better would be a patch fixing the problem!
=== END_DOC
 
" ========================================================================
" vim: set foldmethod=marker :
