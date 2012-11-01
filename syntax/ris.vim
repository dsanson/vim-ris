" $Id: ris-synt.vim,v 1.2 2005/05/09 10:09:51 David_Nebauer Exp $

" Vim Syntax File:
" Language:	    RIS reference format
" Maintainer:   David Nebauer <david@nebauer.org>
" Last Change:  2005-07-08

" ===================================================================

" TODO

" Support line continuation

" ===================================================================

" REMOVE OLD SYNTAX:

if version < 600
	syn clear
elseif exists("b:current_syntax")
	finish
endif

" ===================================================================

" DEFINE FIELD VALUES:

syn case match
syn sync lines=50

" Type:
" Used In  TY:
syn match risValType "  - \zs\%(ABST\|ADVS\|ART\|BILL\|BOOK\|CASE\|CHAP\|COMP\|CONF\|CTLG\|DATA\|ELEC\|GEN\|HEAR\|ICOMM\|INPR\|JFULL\|JOUR\|MAP\|MGZN\|MPCT\|MUSIC\|NEWS\|PAMP\|PAT\|PCOMM\|RPRT\|SER\|SLIDE\|SOUND\|STAT\|THES\|UNBILL\|UNPB\|VIDEO\)$" contained

" Date:
" Used In  PY Y1 Y2:
syn match risValDate "  - \zs\%(\d\{4}\)\?\/\%(\%(0[1-9]\)\|\%(1[0-2]\)\)\{,1}\/\%(\%(0[1-9]\)\|\%([12][0-9]\)\|\%(3[0-1]\)\)\{,1}\/\%(\p\{,255}\S\)\{,1}$" contained

" Id:
" Used In  ID:
syn match risValId "  - \zs[[:alnum:]-]\{1,20}$" contained

" Reprint:
" Used In  RP:
syn match risValReprint "  - \zs\%(IN FILE\)\|\%(NOT IN FILE\)\|\%(ON REQUEST \%(\%(0[1-9]\)\|\%(1[0-2]\)\)\/\%(\%(0[1-9]\)\|\%([12][0-9]\)\|\%(3[0-1]\)\)\/\d\{4}\)$" contained

" Author:
" Used In  A1 AU A2 ED A3:
syn match risValAuthor "  - \zs\%(\<[[:alpha:] '-]\{1,}\>\)\%(,\%(\%(\%(\<[[:alpha:]'-]\{2,}\>\%( \<[[:alpha:]-]\{2,}\)\{}[ \.]\?\)\{1}\%([[:alpha:]]\.\)\{}\%(\%(,[[:alnum:]]\{1,}\.\)\|[[:alpha:]]\)\?\)\{1}\|\%([[:alpha:]]\.\)\{1,}\)\)\?$" contained

" String Length Unlimited:
" Used In  CT BT TI T1 T2 T3 N1 N2 AV AB AD SP EP VL IS CP:
" Used In  CY PB SN UR U1 U2 U3 U4 U5 M1 M2 M3 L1 L2 L3 L4:
syn match risValStrUnl "  \- \zs\p\{1,}$" contained

" String Length C255:
" Used In  KW JF JO JA J1 J2:
syn match risValStr255 "  \- \zs\p\{1,255}$" contained

" Journal Name Abbreviation:
" Used In  JO:
syn match risValJnlAbbr "  - \zs\%(\<[[:alnum:]]\{1,}\>\%( \|\.\)\?\)\{1,}$" contained

" ===================================================================

" DEFINE FIELD TAGS:

" Type Related:
" Tags  TY:
syn region risRgnType start="^TY  - " end="$" contains=risValType keepend

" Date Related:
" Tags  PY Y1 Y2:
syn region risRgnDate start="^\%(PY\|Y1\|Y2\)  - " end="$" contains=risValDate keepend

" Id Related:
" Tags  ID:
syn region risRgnId start="^ID  - " end="$" contains=risValId keepend

" Reprint Related:
" Tags  RP:
syn region risRgnReprint start="^RP  - " end="$" contains=risValReprint keepend

" Author Related:
" Tags  A1 AU A2 ED A3:
syn region risRgnAuthor start="^\%(A1\|AU\|A2\|ED\|A3\)  - " end="$" contains=risValAuthor keepend

" String Length Unlimited Related:
" Tags  CT BT TI T1 T2 T3 N1 N2 AV AB AD SP EP VL IS CP:
" Tags  CY PB SN UR U1 U2 U3 U4 U5 M1 M2 M3 L1 L2 L3 L4:
syn region risRgnStrUnl start="^\%(CT\|BT\|TI\|T1\|T2\|T3\|N1\|N2\|AV\|AB\|AD\|SP\|EP\|VL\|IS\|CP\|CY\|PB\|SN\|UR\|U1\|U2\|U3\|U4\|U5\|M1\|M2\|M3\|L1\|L2\|L3\|L4\)  \- " end="$" contains=risValStrUnl keepend

" String Length C255 Related:
" Used In  KW JF JO JA J1 J2:
syn region risRgnStr255 start="^\%(KW\|JF\|JO\|JA\|J1\|J2\)  \- " end="$" contains=risValStr255 keepend

" Journal Name Abbreviation Related:
" Tags  JO:
syn region risRgnJnlAbbr start="^JO  - " end="$" contains=risValJnlAbbr keepend

" End Record Related:
" Tags  ER:
syn match risEndRecord "^ER  - $"

" ===================================================================

" DEFINE ERRORS:

" Illegal Tag On NonBlank Line:
syn region risErrNoTag start="^[^\%($\|TY\|ID\|T1\|T2\|T3\|TI\|CT\|BT\|A1\|AU\|Y1\|PY\|N1\|AB\|KW\|RP\|SP\|EP\|JF\|JO\|JA\|J1\|J2\|VL\|BT\|A2\|ED\|IS\|CP\|CY\|PB\|U1\|U2\|U3\|U4\|U5\|A3\|N2\|SN\|AV\|Y2\|M1\|M2\|M3\|AD\|UR\|L1\|L2\|L3\|L4\|ER\)]" end="$" oneline

" Tag Not Followed By Separator:
syn region risErrTagNoSep start="^\%(TY\|ID\|T1\|TI\|T2\|T3\|CT\|BT\|A1\|AU\|Y1\|PY\|N1\|AB\|KW\|RP\|SP\|EP\|JF\|JO\|JA\|J1\|J2\|VL\|BT\|A2\|ED\|IS\|CP\|CY\|PB\|U1\|U2\|U3\|U4\|U5\|A3\|N2\|SN\|AV\|Y2\|M1\|M2\|M3\|AD\|UR\|L1\|L2\|L3\|L4\|ER\)\%(  - \)\@!" end="$" oneline

" Author Length Exceeded:
syn match risErrAuthLength "^\%(A1\|AU\|A2\|ED\|A3\)  - \p\{256,}$"

" Date Length Exceeded:
syn match risErrDateLength "^\%(PY\|Y1\|Y2\)  - \zs\%(\d\{4}\)\?\/\%(\%(0[1-9]\)\|\%(1[0-2]\)\)\{,1}\/\%(\%(0[1-9]\)\|\%([12][0-9]\)\|\%(3[0-1]\)\)\{,1}\/\%(\p\{256,}\)\{,1}$" contained

" No Record Separator:
" TY not preceded by empty line
syn match risErrRefNoSep  "\%(^$\n\)\@<!TY"

" Illegal Blank Line:
syn match risErrBlankLine "^$\n^\%(TY\)\@!\p\{}$"

" ===================================================================

" SET HIGHLIGHTING:

if version >= 508 || !exists("did_ris_syntax_inits")

	if version < 508
		let did_ris_syntax_inits = 1
		command -nargs=+ HiLink hi link <args>
	else
		command -nargs=+ HiLink hi def link <args>
	endif

	" Type Related:
	" Tags  TY:
	HiLink risValType          Comment
	HiLink risRgnType          PreProc
	" Date Related:
	" Tags  PY Y2:
	HiLink risValDate          Comment
	HiLink risRgnDate          Statement
	" Id Related:
	" Tags  ID:
	HiLink risValId            Comment
	HiLink risRgnId            Statement
	" Reprint Related:
	" Tags  RP:
	HiLink risValReprint       Comment
	HiLink risRgnReprint       Statement
	" Author Related:
	" Tags  A1 AU A2 ED A3:
	HiLink risValAuthor        Comment
	HiLink risRgnAuthor        Statement  
	" String Length Unlimited Related:
	" Tags  CT BT TI T1 T2 T3 N1 N2 AV AB AD SP EP VL IS CP:
	" Tags  CY PB SN UR U1 U2 U3 U4 U5 M1 M2 M3 L1 L2 L3 L4:
	HiLink risValStrUnl        Comment
	HiLink risRgnStrUnl        Statement
	" String Length C255 Related:
	" Tags  KW JF JO JA J1 J2:
	HiLink risValStr255        Comment
	HiLink risRgnStr255        Statement
	" Journal Name Abbreviation Related:
	" Tags  JO:
	HiLink risValJnlAbbr       Comment
	HiLink risRgnJnlAbbr       Statement
	" End Record Related:
	" Tags  ER:
	HiLink risEndRecord        PreProc
	" Errors:
	HiLink risErrNoTag         Error
	HiLink risErrTagNoSep      Error
	HiLink risErrRefNoSep      Error
	HiLink risErrBlankLine     Error
	HiLink risErrAuthLength    Error
	HiLink risErrDateLength    Error

	delcommand HiLink

endif

" ===================================================================

" SET SYNTAX VARIABLE:

let b:current_syntax = "ris"

" ===================================================================
