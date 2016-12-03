set nocompatible
filetype off

set cc=100

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
nmap <c-h> :bn\|bd #<CR>

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

" Map control c to esc
vnoremap <C-c> <Esc>

" NeoBundles configs
set runtimepath^=~/.vim/bundle/neobundle.vim/
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'bling/vim-airline'
let g:airline#extensions#tabline#enabled = 1

NeoBundle 'Valloric/YouCompleteMe'
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_filetype_blacklist = { 'sql' : 1 }

NeoBundle 'neomake/neomake'
nnoremap <C-w>e :Neomake<CR>

NeoBundle 'wincent/Command-T'
let g:CommandTMaxCachedDirectories = 10
let g:CommandTInputDebounce = 50
let g:CommandTFileScanner = 'git'

"NeoBundle 'ctrlpvim/ctrlp.vim'
NeoBundle 'flazz/vim-colorschemes'
NeoBundle 'wellsjo/wellsokai.vim'

NeoBundle 'ervandew/supertab'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'godlygeek/tabular'
NeoBundle 'tpope/vim-surround'
NeoBundle 'Chiel92/vim-autoformat'
NeoBundle 'scrooloose/nerdcommenter'
NeoBundle 'terryma/vim-multiple-cursors'
NeoBundle 'myusuf3/numbers.vim'
NeoBundle 'fatih/vim-go'
" Go format
let g:go_fmt_command = "goimports"
let g:go_fmt_experimental = 1

NeoBundle 'ternjs/tern_for_vim', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['javascript']
            \ }
            \}
nmap <Leader>jd :TernDef<CR>
nmap <Leader>jt :TernType<CR>
nmap <Leader>jr :TernRefs<CR>
nmap <Leader>jn :TernRename<CR>

NeoBundle 'vim-scripts/closetag.vim', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['xml', 'html', 'xhtml']
            \ }
            \}

NeoBundle 'fatih/vim-go',{
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['go', 'golang']
            \ }
            \}

NeoBundle 'pangloss/vim-javascript', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['javascript']
            \ }
            \}

NeoBundle 'mxw/vim-jsx',{
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['javascript']
            \ }
            \}

NeoBundle 'valloric/MatchTagAlways', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['javascript', 'html', 'xml']
            \ }
            \}
" Match tag always
let g:mta_use_matchparen_group = 1


NeoBundle 'elzr/vim-json', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['json']
            \ }
            \}

NeoBundle 'ap/vim-css-color', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['sass', 'css', 'less', 'scss']
            \ }
            \}

NeoBundle 'derekwyatt/vim-scala', {
            \ 'lazy': 1,
            \ 'autoload': {
            \   'filetypes': ['scala']
            \ }
            \}

call neobundle#end() " end of bundle configs
filetype plugin indent on " required
NeoBundleCheck

set laststatus=2
set background=dark

" Load AutoComplete only for certain files
au BufNewFile,BufRead *.partial,*.handlebars set filetype=html
au BufNewFile,BufRead *.jsx set filetype=javascript
au BufWrite * :DeleteTrailingWhitespace
autocmd FileType html,htmldjango,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType html,partial,xhtml,xml,htmldjango,jinjahtml,eruby,mako source ~/.vim/bundle/closetag.vim/plugin/closetag.vim
autocmd FileType html,java,coffee,javascript,scala,html,css,scss setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for
autocmd FileType python set cc=80
autocmd FileType python inoremap # X<BS>#
autocmd FileType scala set cc=100

syntax enable
filetype off
filetype on

" ???
let g:pymode_rope_complete_on_dot = 0

" 'Global' buffer
vmap <leader>y :w! ~/.vitmp<CR>
nmap <leader>p :r! cat ~/.vitmp<CR>

" Disable middle click paste
nnoremap <MiddleMouse> <Nop>
nnoremap <2-MiddleMouse> <Nop>
nnoremap <3-MiddleMouse> <Nop>
nnoremap <4-MiddleMouse> <Nop>

inoremap <MiddleMouse> <Nop>
inoremap <2-MiddleMouse> <Nop>
inoremap <3-MiddleMouse> <Nop>
inoremap <4-MiddleMouse> <Nop>

" Custom Macro
let @t = 'dwiimport wwxifromwdwds($'

colorscheme wellsokai
com! FormatJSON %!python -m json.tool
