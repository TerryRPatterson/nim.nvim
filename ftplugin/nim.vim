" Vim filetype plugin file
" Language: Nim
" Author:   Leorize

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

setlocal comments=:##,:#,s1:#[,e:]#,fb:-
setlocal commentstring=#%s
setlocal foldignore=
setlocal include=^\\s*\\(from\\|import\\|include\\)
setlocal suffixesadd=.nim
setlocal keywordprg=:NimDocOf
setlocal iskeyword=a-z,A-Z,48-57,_

" required by the compiler
setlocal expandtab

if exists('loaded_matchit') && !exists('b:match_words')
  let b:match_ignorecase = 0
  let b:match_words = '\<\%(case\|if\|when\)\>:\<of\>:\<elif\>:\<else\>,' .
      \               '\<try\>:\<except\>:\<finally\>,'
  let b:match_skip = "synIDattr(synID(line('.'), col('.'), v:false), 'name') =~ '\\(Comment\\|String\\|nimCharacter\\)$'"
endif

compiler nim

" section movement

" type:
"   1. any line that starts with a non-whitespace char following a blank line,
"      or the first line
"   2. top-level block-like statements
function! s:nimNextSection(type, backwards, visual)
  let count = v:count1

  if a:backwards
    let backward = 'b'
  else
    let backward = ''
  endif

  if a:type == 1
    let pattern = '\v(\n\n^\S|%^)'
    let flag = 'e'
  elseif a:type == 2
    let pattern = '\v^((const|let|var|type)\s*|((func|iterator|method|proc).*\=\s*)|\S.*:\s*)$'
    let flag = ''
  endif

  if a:visual
    normal! gv
  endif

  let i = 0
  while i < count
    call search(pattern, backward . flag . 'W')
    let i += 1
  endwhile
endfunction

function! s:nimStar(word, backwards)
  let regex = nim#StarSearchRegex()
  let searchOp = a:backwards ? 'b' : 'n'
  if len(regex) > 0
    let @/ = (a:word ? '\<' : '') . regex . (a:word ? '\>' : '')
    return 'normal ' . searchOp
  else
    return ''
  endif
endfunction

" commands
" find references to symbol on cursor
command! -buffer NimReferences call nim#suggest#use#ShowReferences()
" display the type of symbol on cursor
command! -buffer NimTypeOf call nim#suggest#def#ShowType()
" display the documentation of symbol on cursor, arguments are ignored, only
" used for keywordprg support
command! -nargs=* -buffer NimDocOf call nim#suggest#def#ShowDoc()

" scripted mappings
noremap <script> <buffer> <silent> <Plug>NimGoToDefBuf :call nim#suggest#def#GoTo('b')<lf>
noremap <script> <buffer> <silent> <Plug>NimGoToDefSplit :call nim#suggest#def#GoTo('s')<lf>
noremap <script> <buffer> <silent> <Plug>NimGoToDefVSplit :call nim#suggest#def#GoTo('v')<lf>
noremap <script> <buffer> <silent> <Plug>NimOutline :call nim#suggest#outline#OpenLocList()<lf>
" these have to be implemented like this due to function-search-undo
noremap <script> <buffer> <silent> <Plug>NimStar :execute <SID>nimStar(v:true, v:true)<lf>
noremap <script> <buffer> <silent> <Plug>NimGStar :execute <SID>nimStar(v:false, v:true)<lf>
noremap <script> <buffer> <silent> <Plug>NimPound :execute <SID>nimStar(v:true, v:false)<lf>
noremap <script> <buffer> <silent> <Plug>NimGPound :execute <SID>nimStar(v:false, v:false)<lf>

function s:updateSemanticHighlight() abort
  if (!exists('SessionLoad') || !SessionLoad) &&
    \ !empty(nim#suggest#ProjectFindOrStart())
    if get(b:, 'nim_last_changed', -1) != b:changedtick
      call nim#suggest#highlight#HighlightBuffer()
      let b:nim_last_changed = b:changedtick
    endif
  endif
endfunction

augroup NimSemanticHighlight
  autocmd!
  autocmd BufNewFile,BufWinEnter,BufWritePost *.nim
  \ call s:updateSemanticHighlight()

  if get(g:, 'nim_highlight_wait', v:false)
    autocmd CursorHold,CursorHoldI,InsertEnter,InsertLeave *.nim
    \ call s:updateSemanticHighlight()
  else
    autocmd TextChanged,TextChangedI,TextChangedP *.nim
    \ call s:updateSemanticHighlight()
  endif
augroup END
