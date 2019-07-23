" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
"
set encoding=utf-8
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Multiple Plug commands can be written in a single line using | separators
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-master branch
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug 'fatih/vim-go', { 'tag': '*' }

" Plugin options
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
Plug '~/my-prototype-plugin'

" Lean & mean status/tabline for vim that's light as air
Plug 'vim-airline/vim-airline'

" A collection of themes for vim-airline
Plug 'vim-airline/vim-airline-themes'

" one colorsheme pack to rule them all
Plug 'flazz/vim-colorschemes'

" Fuzzy file, buffer, mru, tag, etc finder.
Plug 'kien/ctrlp.vim'

" Vim plugin, provides insert mode auto-completion for quotes, parens,
" brackets, etc
Plug 'raimondi/delimitmate'

" emmet for vim: http://emmit.io
Plug 'bubujka/emmet-vim'

" A vim plugin to display the indention levels with him thin vertical lines
Plug 'yggdroot/indentline'

" Next generation completion framework after neocomplache
Plug 'shougo/neocomplete.vim'

" A Vim plugin for visually displaying indent levels in code
Plug 'valloric/vim-indent-guides'

" Instant Markdown previews from Vim
Plug 'terryma/vim-instant-markdown'

" NERDTree and tabs together in Vim, painlessly
Plug 'jistr/vim-nerdtree-tabs'

" Syntax checking hacks for vim
Plug 'scrooloose/syntastic'

" Configure tabs within Terminal Vim
Plug 'mkitt/tabline.vim'

" A Vim plugin for TypeScript
Plug 'quramy/tsuquyomi'

" Typescript syntax files for vim
Plug 'leafgarland/typescript-vim'

" UltiSnips - The ultimate snippet solution for Vim.
" Plug 'sirver/ultisnips'

" Simple color selector/picker plugin for Vim.
Plug 'kabbamine/vcoolor.vim'

" Provide easy code formatting in Vim by integrating existing code formatters.
Plug 'chiel92/vim-autoformat'

" Better whitespace highlighting for Vim
Plug 'ntpeters/vim-better-whitespace'

" Commentary.vim: Comment stuff out
Plug 'joom/vim-commentary'

" fugitive.vim: A Git wrapper so awesome, it should be illegal
Plug 'tpope/vim-fugitive'

" A Vim pulgin which show a git diff in the gutter 
Plug 'airblade/vim-gitgutter'

" True Sublime Tex Style multiple selections for Vim
Plug 'terryma/vim-multiple-cursors'

" mustache and handelbars mode for vim
Plug 'mustache/vim-mustache-handlebars'

" Toggles between hybird and absolute line numbers automatically
Plug 'jeffkreeftmeijer/vim-numbertoggle'

" vim-snipmate default snippets (Previously snipmate-snippets)
Plug 'honza/vim-snippets'

" surroun.vim: quoting/parenthesizing made simple
Plug 'tpope/vim-surround'

" Seamless navigation between tmux panes and vim splits
Plug 'christoomey/vim-tmux-navigator'

" Highlights trailing whitespace in red and provides: FiexWhitespace to fix
" it.
Plug 'bronson/vim-trailing-whitespace'

" A code-completion engine for vim
Plug 'valloric/youcompleteme'

" Bash IDE -- insert code snippets, run, check
Plug 'vim-scripts/bash-support.vim'

" Add additional support for Ansible in VIM
Plug 'chase/vim-ansible-yaml'

" Intellgently reopen files at your last edit postion in vim
Plug 'farmergreg/vim-lastplace'

" i3config syntax plugin
Plug 'mboughaba/i3config.vim'

" Initialize plugin system
call plug#end()

" Vim-commentary
autocmd FileType apache setlocal commentstring=#\ %s

" Tabulacion
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Pathogen

" execute pathogen#infect()
" syntax enable

" Colors
syntax enable
set t_Co=256
set background=dark
let g:solarized_termcolors=256
" colorscheme gruvbox
" colorscheme PaperColor
colorscheme professional
hi Normal guibg=NONE ctermbg=NONE


" Indent Guides
let g:indent_guides_start_level = 1
let g:indent_guides_guide_size = 1
let g:indent_guides_auto_colors = 0
" set ts=4 sw=4 et
let g:indent_guides_enable_on_vim_startup=1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red        ctermbg=243
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=lightred   ctermbg=179

" Airline
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif

" let g:airline_theme = 'base16_grayscale'
" let g:airline_left_sep = '»'
" let g:airline_left_sep = '▶'
" let g:airline_right_sep = '«'
" let g:airline_right_sep = '◀'
" let g:airline_symbols.crypt = '🔒 '
" let g:airline_symbols.linenr = '␊'
" let g:airline_symbols.linenr = '␤'
" let g:airline_symbols.linenr = '¶'
" let g:airline_symbols.maxlinenr = '☰'
" let g:airline_symbols.maxlinenr = ''
" let g:airline_symbols.branch = '⎇'
" let g:airline_symbols.paste = 'ρ'
" let g:airline_symbols.paste = 'Þ'
" let g:airline_symbols.paste = '∥'
" let g:airline_symbols.spell = 'Ꞩ'
" let g:airline_symbols.notexists = '∄'
" let g:airline_symbols.whitespace = 'Ξ'

let g:airline_theme = 'base16_grayscale'
let g:airline_left_sep = ''
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_right_sep = ''
let g:airline_symbols.crypt = ''
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.maxlinenr = '☰'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.copy = ''
let g:airline_symbols.spell = 'Ꞩ'
let g:airline_symbols.notexists = '∄'
let g:airline_symbols.whitespace = 'Ξ'

set nu
set laststatus=2

" Syntastic

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"

let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

" Vim-Jedi
let g:jedi#auto_initialization = 1
let g:powerline_pycmd="py3"

autocmd FileType yaml setlocal ai ts=2 sw=2 et


