set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" General Settings
syn on
set nu
set smartindent
set expandtab
set nofoldenable
set hidden       " Hide buffer
set autowrite    " autosave buffer changes
set autowriteall " autosave buffer changes

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

" Key mapping
imap jk <Esc>

nmap \q :nohlsearch<CR>
nmap j gj
nmap k gk
nmap <c-l> :redraw!<CR>
" nmap ; :CtrlPBuffer<CR>

nmap <c-m> <c-y>,
let g:tagbar_usearrows = 1
nnoremap ; :TagbarToggle<CR>

" mv between splits
nmap <c-k> <C-W>l
nmap <c-j> <C-W>h
nmap <S-m> :bp<CR>
nmap m :bn<CR>

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

noremap <c-c> <Esc>
inoremap <c-c> <Esc>

filetype plugin indent on

set runtimepath^=~/.vim/bundle/ctrlp.vim

" Load AutoComplete only for certain files
au BufNewFile,BufRead *.partial,*.handlebars set filetype=html
autocmd FileType html,htmldjango,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType html,partial,xhtml,xml,htmldjango,jinjahtml,eruby,mako source ~/.vim/bundle/closetag.vim/plugin/closetag.vim
autocmd FileType scala,html,css,scss setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for HTML files "

let coffee_compiler = '/usr/local/bin/iced'
au BufWritePost *.coffee silent make!

" Bundles"
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-scripts/closetag.vim'
Plugin 'scrooloose/syntastic'
Plugin 'wincent/Command-T'
Plugin 'bling/vim-airline'
Plugin 'flazz/vim-colorschemes'
Plugin 'ervandew/supertab'
Plugin 'mattn/emmet-vim'
Plugin 'godlygeek/tabular'
Plugin 'tpope/vim-surround'
Plugin 'valloric/MatchTagAlways'
Plugin 'elzr/vim-json'
Plugin 'ap/vim-css-color'
Plugin 'kchmck/vim-coffee-script'
Plugin 'derekwyatt/vim-scala'
Plugin 'jnwhiteh/vim-golang'
Plugin 'tpope/vim-fugitive'

call vundle#end()            " required
filetype plugin indent on    " required

set cc=100

set laststatus=2
colorscheme dante

syntax enable
filetype off
filetype on

let g:pymode_rope_complete_on_dot = 0

" Match tag always
let g:mta_use_matchparen_group = 1

" Airline
let g:airline#extensions#tabline#enabled = 1

" Unite
nnoremap <space>/ :Unite grep:.<cr>
nnoremap <space>s :Unite -quick-match buffer<cr>
