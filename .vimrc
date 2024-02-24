"""""""""""""""""""
" Preprocessing
"""""""""""""""""""
" いろいろ便利な設定がされていて便利なので、デフォルトの設定を読み込む
unlet! skip_defaults_vim
if filereadable($VIMRUNTIME.'/defaults.vim')
    source $VIMRUNTIME/defaults.vim
endif

"""""""""""""""""""
" Setting
"""""""""""""""""""
"文字コードを自動判別
"  とりあえず
set fileencodings=euc-jp,utf-8,iso-2022-jp,sjis
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd
" マウス操作の有効化 & ホイール操作の有効化
set mouse=a
" viとの互換性を無効にする(INSERT中にカーソルキーが有効になる)
set nocompatible

"""""""""""""""""""
" Visual
"""""""""""""""""""
" 行番号を表示
set number
" 現在の行を強調表示
set cursorline
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" シンタックスハイライトの有効化
syntax enable
" デフォルトだと端末の背景色が黒の時にコメントが見づらくなるので、配色を変更する
colorscheme evening
" タイトルを表示
set title
" インサートモード中の BS、CTRL-W、CTRL-U による文字削除を柔軟にする
set backspace=indent,eol,start
" カーソルの外観を変更させない(端末の設定のまま)
set guicursor=

"""""""""""""""""""
" Statusline
"  大体VS CodeのStatus Barの表示に合わせる
"""""""""""""""""""
" ファイル名表示
set statusline=%F
" 変更チェック表示(",+"が変更あり、",-"は変更不可)
set statusline+=%M
" 読み込み専用かどうか表示
set statusline+=%R
" ヘルプページなら",HLP"と表示
set statusline+=%H
" プレビューウインドウなら",PRV"と表示
set statusline+=%W

" これ以降は右寄せ表示
set statusline+=%=

" カーソル位置表示
set statusline+=Ln\ %l(%p%%),Col\ %c
set statusline+=\|
" file encoding
set statusline+=%{&fileencoding}
set statusline+=\|
" ファイルフォーマット表示
set statusline+=%{&fileformat}
set statusline+=\|
" ファイルタイプ表示
set statusline+=%Y

"""""""""""""""""""
" Tab
"""""""""""""""""""
" 不可視文字を可視化(タブが「?-」と表示される)
set list listchars=tab:\?\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=4
" Tabキーを入力した時の表示幅
"   set expandtabを設定しているので、Tab入力はsofttabstopのスペースが入力されて表示幅はtabstopになる
set softtabstop=4
" 行頭でのTab文字の表示幅
set shiftwidth=4

"""""""""""""""""""
" Search
"""""""""""""""""""
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <Esc><Esc> :nohlsearch<CR><Esc>

"""""""""""""""""""
" Plugin
"""""""""""""""""""
" Automatic install of vim-plug
" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation

" ~/.vim でプラグインを管理すると、共有環境でプラグインを使いたいときに他の人に影響を及ぼすので、
" DOTFILES_DIRECTORY の中でプラグインを管理するようにする
if exists('$DOTFILES_DIRECTORY')
    " DOTFILESが設定されている場合の処理
    if empty(glob('$DOTFILES_DIRECTORY/.vim/autoload/plug.vim'))
        silent !curl -fLo /home/yuto/project/dotfiles/.vim/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    endif

    set runtimepath+=$DOTFILES_DIRECTORY/.vim

    " Run PlugInstall if there are missing plugins
    autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
        \| PlugInstall --sync | source $MYVIMRC
    \| endif

    call plug#begin('$DOTFILES_DIRECTORY/.vim/plugged')
        Plug 'tpope/vim-fugitive'
        Plug 'airblade/vim-gitgutter'
        Plug 'prabirshrestha/vim-lsp'
        Plug 'prabirshrestha/asyncomplete.vim'
        Plug 'prabirshrestha/asyncomplete-lsp.vim'
        Plug 'mattn/vim-lsp-settings'
        Plug 'vim-airline/vim-airline'
        Plug 'preservim/nerdtree'
        Plug 'tyru/caw.vim'
    call plug#end()

    let g:lsp_settings_servers_dir = $DOTFILES_DIRECTORY . '/.vim/vim-lsp-settings/servers'
    let g:airline#extensions#tabline#enabled = 1
    let g:airline_powerline_fonts = 1

    " VS CodeのようにCtrl+BでNERDTreeを開閉する
    nnoremap <C-b> :NERDTreeToggle<CR>

    " Ctrl+Nで次のタブに移動
    nmap <C-n> <Plug>AirlineSelectNextTab

    " Ctrl+/でコメント切り替え
    nmap <C-_> <Plug>(caw:i:toggle)
    vmap <C-_> <Plug>(caw:i:toggle)
endif
