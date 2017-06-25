set nocompatible
filetype off

set undodir=~/.vim/undodir
set undofile
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

" allow the . to execute once for each line of a visual selection
vnoremap . :normal .<CR>

" Map control c to esc
vnoremap <C-c> <Esc>

" Specify a directory for plugins (for Neovim: ~/.local/share/nvim/plugged)
call plug#begin('~/.vim/plugged')

Plug 'bling/vim-airline'
let g:airline#extensions#tabline#enabled = 1

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" let g:deoplete#enable_at_startup = 1
let g:deoplete#file#enable_buffer_path = 1
if exists('g:plugs["tern_for_vim"]')
  let g:tern_show_argument_hints = 'on_hold'
  let g:tern_show_signature_in_pum = 1
  autocmd FileType javascript setlocal omnifunc=tern#Complete
endif
" deoplete tab-complete
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

Plug 'w0rp/ale'
nmap <silent> <C-S-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-S-j> <Plug>(ale_next_wrap)
if $ACPOWER == '1'
    " Write this in your vimrc file
    let g:ale_lint_on_text_changed = 'never'
    " " You can disable this option too
    " " if you don't want linters to run on opening a file
    let g:ale_lint_on_enter = 0
end

Plug 'vim-scripts/DeleteTrailingWhitespace'
Plug 'flazz/vim-colorschemes'
Plug 'wellsjo/wellsokai.vim'

Plug 'ervandew/supertab'
Plug 'mattn/emmet-vim'
Plug 'godlygeek/tabular'
Plug 'tpope/vim-surround'
Plug 'Chiel92/vim-autoformat'
Plug 'sbdchd/neoformat'
autocmd FileType javascript setlocal formatprg=prettier\ --stdin\ --parser\ flow\ --single-quote\ --trailing-comma\ es5
" Use formatprg when available
let g:neoformat_try_formatprg = 1
" auto format on save
augroup fmt
  autocmd!
  autocmd BufWritePre * Neoformat
augroup END

Plug 'scrooloose/nerdcommenter'
Plug 'terryma/vim-multiple-cursors'
Plug 'myusuf3/numbers.vim'
Plug 'chrisbra/NrrwRgn'

Plug 'junegunn/fzf', { 'dir': '~/.fz', 'do': 'yes \| ./install --all' }
nmap <Leader>t :FZF<CR>

Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
let g:go_fmt_command = "goimports"
let g:go_fmt_experimental = 1

Plug 'ternjs/tern_for_vim', {'do': 'npm install'}
nmap <Leader>jd :TernDef<CR>
nmap <Leader>jt :TernType<CR>
nmap <Leader>jr :TernRefs<CR>
nmap <Leader>jn :TernRename<CR>

Plug 'vim-scripts/closetag.vim', { 'for': ['xml', 'html', 'xhtml'] }
Plug 'fatih/vim-go', { 'for': ['go', 'golang'] }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': ['javascript'] }

Plug 'valloric/MatchTagAlways', { 'for': ['javascript', 'html', 'xml'] }
let g:mta_use_matchparen_group = 1

Plug 'elzr/vim-json', { 'for': ['json'] }

Plug 'ap/vim-css-color', { 'for': ['sass', 'css', 'less', 'scss'] }
call plug#end()

set laststatus=2
set background=dark

" Load AutoComplete only for certain files
au BufNewFile,BufRead *.partial,*.handlebars set filetype=html
au BufNewFile,BufRead *.jsx set filetype=javascript
au BufWrite * :DeleteTrailingWhitespace
autocmd FileType html,jinjahtml,eruby,mako let b:closetag_html_style=1
autocmd FileType htmldjango,java,coffee,javascript,scala,html,css,scss setlocal shiftwidth=2 tabstop=2 sts=2 " Two spaces for
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

let s:uname = system("uname -s")
if s:uname == "Darwin"
    let g:python3_host_prog = '/usr/local/bin/python3'
end
