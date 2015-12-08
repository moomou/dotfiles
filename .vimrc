set nocompatible
filetype off

set cc=100

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
set encoding=utf-8  " The encoding displayed.
set fileencoding=utf-8  " The encoding written to file.

" General Settings
syn on
set nu
set smartindent
set expandtab
set nofoldenable
set hidden       " Hide buffer
set autowrite    " autosave buffer changes
set autowriteall " autosave buffer changes

" set term=xterm-256color
set t_Co=256

set tabstop=4
set softtabstop=4
set shiftwidth=4
set wildchar=<Tab> wildmenu wildmode=full
set foldmethod=indent
set pastetoggle=<F2>

" Search Options
set incsearch
set ignorecase
set smartcase
set hlsearch

" Make mouse interactive
set mouse=a

" Performance tricks
set nocursorcolumn
set nocursorline
set norelativenumber
set synmaxcol=200
set lazyredraw " to avoid scrolling problems
syntax sync minlines=256

" Key mapping
imap jk <Esc>
imap <C-c> <Esc>

nmap \q :nohlsearch<CR>
nmap j gj
nmap k gk
nmap <c-l> :redraw!<CR>

nmap <c-m> <c-y>,
let g:tagbar_usearrows = 1

" mv between splits
nmap <c-k> <C-W>l
nmap <c-j> <C-W>h
nmap <S-m> :bp<CR>
nmap mm :bn<CR>

" http://stackoverflow.com/questions/2600783/how-does-the-vim-write-with-sudo-trick-work
cmap w!! w !sudo tee > /dev/null %

noremap <F1> <Esc>:syntax sync fromstart<CR>
inoremap <F1> <C-o>:syntax sync fromstart<CR>

noremap <F3> <Esc>:'<,'>Tab/=/l1<CR>
inoremap <F3> <C-o>:'<,'>Tab/=/l1<CR>

noremap <F4> <Esc>:'<,'>Tab/:/l1<CR>
inoremap <F4> <C-o>:'<,'>Tab/:/l1<CR>

noremap <F5> <Esc>:silent %!xmllint --encode UTF-8 --format -
inoremap <F5> <C-o>:silent %!xmllint --encode UTF-8 --format -

noremap <F6> <Esc>:set ft=html<CR>
inoremap <F6> <C-o>:set ft=html<CR>

noremap <F7> <Esc>:set ft=javascript<CR>
inoremap <F7> <C-o>:set ft=javascript<CR>

noremap <F8> :Autoformat<CR><CR>
inoremap <F8> :Autoformat<CR><CR>

noremap <c-c> <Esc>
inoremap <c-c> <Esc>

filetype plugin indent on

set runtimepath^=~/.vim/bundle/ctrlp.vim

" Load AutoComplete only for certain files
au BufNewFile,BufRead *.partial,*.handlebars set filetype=html
au BufNewFile,BufRead *.jsx set filetype=javascript
au BufWrite * :DeleteTrailingWhitespace
autocmd FileType html,htmldjango,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType html,partial,xhtml,xml,htmldjango,jinjahtml,eruby,mako source ~/.vim/bundle/closetag.vim/plugin/closetag.vim
autocmd FileType coffee,javascript,scala,html,css,scss setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for
autocmd FileType html setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for
autocmd FileType python set cc=80
autocmd FileType python inoremap # X<BS>#
autocmd FileType scala set cc=100

" Bundles"
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'bling/vim-airline'
Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-scripts/closetag.vim'
Plugin 'scrooloose/syntastic'
let g:syntastic_javascript_checkers = ['eslint']

Plugin 'wincent/Command-T'
set wildignore+=node_modules
set wildignore+=build

Plugin 'fatih/vim-go'
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'flazz/vim-colorschemes'
Plugin 'wellsjo/wellsokai.vim'
Plugin 'ctrlpvim/ctrlp.vim'

Plugin 'ervandew/supertab'
Plugin 'mattn/emmet-vim'
Plugin 'godlygeek/tabular'
Plugin 'tpope/vim-surround'
Plugin 'valloric/MatchTagAlways'
Plugin 'elzr/vim-json'
Plugin 'ap/vim-css-color'
Plugin 'mileszs/ack.vim'
Plugin 'derekwyatt/vim-scala'
Plugin 'kchmck/vim-coffee-script'
Plugin 'Chiel92/vim-autoformat'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'scrooloose/nerdcommenter'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'myusuf3/numbers.vim'

call vundle#end()            " required
filetype plugin indent on    " required

set laststatus=2
set background=dark

syntax enable
filetype off
filetype on

" ???
let g:pymode_rope_complete_on_dot = 0

" Match tag always
let g:mta_use_matchparen_group = 1

" Airline
let g:airline#extensions#tabline#enabled = 1

" Go format
let g:go_fmt_command = "goimports"

" Unite
nnoremap <space>/ :Unite grep:.<cr>
nnoremap <space>s :Unite -quick-match buffer<cr>

" EasyMotion
let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Bi-directional find motion
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
nmap s <Plug>(easymotion-s)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-s2)

" Turn on case sensitive feature
let g:EasyMotion_smartcase = 1

" JK motions: Line motions
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)

" Custom Macro
let @t = 'dwiimport wwxifromwdwds($'

colorscheme wellsokai
