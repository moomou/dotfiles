set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

syn on
set t_Co=256
set smartindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set nu
set wildchar=<Tab> wildmenu wildmode=full
set foldmethod=indent
set nofoldenable
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

noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>
noremap <F3> <Esc>:%!xmllint --format --encode UTF-8
inoremap <F3> <C-o>:%!xmllint --format --encode UTF-8

filetype plugin indent on

set runtimepath^=~/.vim/bundle/ctrlp.vim

" Load AutoComplete only for certain files
au BufNewFile,BufRead *.partial,*.handlebars set filetype=html
autocmd FileType html,htmldjango,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType html,partial,xhtml,xml,htmldjango,jinjahtml,eruby,mako source ~/.vim/bundle/closetag.vim/plugin/closetag.vim
autocmd FileType scala,html,css,scss setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for HTML files "

" Bundles"
Bundle 'closetag.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'wincent/Command-T'
Bundle 'bling/vim-airline'
Bundle 'flazz/vim-colorschemes'
Bundle 'ervandew/supertab'
Bundle 'kchmck/vim-coffee-script'
Bundle 'derekwyatt/vim-scala'
Bundle 'jnwhiteh/vim-golang'
Bundle 'tpope/vim-fugitive'
Bundle 'Valloric/YouCompleteMe'
Bundle 'mattn/emmet-vim'
Bundle 'godlygeek/tabular'
Bundle 'tpope/vim-surround'

let coffee_compiler = '/usr/local/bin/iced'
au BufWritePost *.coffee silent make!

highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

set laststatus=2
colorscheme dante

syntax enable
filetype off
filetype on
