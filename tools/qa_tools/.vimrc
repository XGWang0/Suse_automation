" enable syntax highlighting
syntax on

" allow backspacing over everything in insert mode 
set backspace=indent,eol,start

" Only do this part when compiled with support for autocommands. 
if has("autocmd") 
  autocmd BufNewFile,BufRead *.pl set et sw=4 ts=4 ai si
endif " has("autocmd")

