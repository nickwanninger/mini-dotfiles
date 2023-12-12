vim.cmd([[
filetype off
set nocompatible
set noshowmode
set laststatus=0
set winminheight=0
set splitbelow
set splitright
set noeol
set tabstop=2
set shiftwidth=2
set expandtab
set nofoldenable
set foldmethod=indent
set foldnestmax=10
set foldlevel=1
let g:indentLine_enabled = 1
set visualbell t_vb=
set ttyfast
set lazyredraw
set backspace=indent,eol,start
set clipboard=unnamedplus
set mouse=a
set pastetoggle=<F2>
set sidescroll=10
set matchpairs+=<:>
set incsearch
set ignorecase
set smartcase
set showmatch
set smartindent
set noswapfile
set nobackup
set nowritebackup
set undofile
set undodir=~/.tmp//,/tmp//
set hidden
set shell=/bin/sh
set encoding=utf-8
set termguicolors
filetype plugin indent on

let g:indentLine_fileTypeExclude=['help']
let g:indentLine_bufNameExclude=['NERD_tree.*']

command WQ wq
command Wq wq
command W w
command Q q
nnoremap ; :

set nu

let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <M-Left> :TmuxNavigateLeft<cr>
nnoremap <silent> <M-Down> :TmuxNavigateDown<cr>
nnoremap <silent> <M-Up> :TmuxNavigateUp<cr>
nnoremap <silent> <M-Right> :TmuxNavigateRight<cr>
nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :TmuxNavigateRight<cr>

noremap <leader>f :ClangFormat<CR>

autocmd filetype crontab setlocal nobackup nowritebackup
]])


-- This function ensures that our package manager, packer, has been installed.
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then

		print("Bootstrapping packer")
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]

		vim.cmd "redraw"
    return true
  end
  return false
end


local packer_bootstrap = ensure_packer()
local packer = require('packer')


packer.startup(function(use)
	-- packer manages itself
	use 'wbthomason/packer.nvim'

	-- some stuff that some people want
	use 'nvim-lua/plenary.nvim'
	use 'MunifTanjim/nui.nvim'
	use 'nvim-telescope/telescope.nvim'
	use 'sindrets/diffview.nvim'

	-- A fantastic reimplementation of magit from emacs
	use 'NeogitOrg/neogit'

	-- Merge Tmux stuff
	use 'christoomey/vim-tmux-navigator'

	-- A bunch of base16 themes
	use 'RRethy/nvim-base16'

	-- Fuzzy finder
	use {'junegunn/fzf', run='fzf#install()'}
	use 'junegunn/fzf.vim'

	-- `gcc` key combo
	use 'numToStr/Comment.nvim'

	-- Show git info next to the numbers
	use 'lewis6991/gitsigns.nvim'

	-- A nice tree on the left
	use 'kyazdani42/nvim-tree.lua'

	-- Pretty notifications
	use 'rcarriga/nvim-notify'

	-- Autocompletion & Autocomplete
	use 'ms-jpq/coq_nvim'
	use 'ms-jpq/coq.artifacts'
	use 'neovim/nvim-lspconfig'
	use 'ray-x/lsp_signature.nvim'
	use 'rhysd/vim-clang-format'
	use 'ErichDonGubler/lsp_lines.nvim'
	use 'nvim-treesitter/nvim-treesitter' -- very important

	use 'weilbith/nvim-code-action-menu'
	use 'folke/which-key.nvim'

	-- Automatically set up the configuration after cloning packer.nvim
	if packer_bootstrap then
		packer.sync()
	end
end)


local lsp = require('lspconfig')
local coq = require('coq')
local wk = require('which-key')

wk.setup {}

-- (wk.register {";" [":" "vim-ex"]})

function map(binding, name, func, opt)
  opt = opt or {}
  wk.register({
    [binding] = {func, name}
  }, opt)
end

vim.notify = require'notify'
vim.notify.setup()


require('nvim-treesitter.configs').setup {
  ensure_installed = 'all'
}



-- now setup the nvim-tree on the left
require'nvim-tree'.setup {}
require'gitsigns'.setup {
  signcolumn = false,
  numhl = true,
}

local neogit = require'neogit'
neogit.setup {
  disable_signs = false,
  disable_hint = true,
  disable_context_highlighting = false,
  disable_builtin_notifications = true,
}

map("<leader>g", "Open Neogit", neogit.open)


function on_attach(client, bufnr)
  local opts = {noremap = true, silent = true}
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.lsp.buf.format()<CR>", opts)
end


local servers = {'clangd', 'rust_analyzer'}
for _, lang in pairs(servers) do
  local pkg = lsp[lang]
  pkg.setup(coq.lsp_ensure_capabilities {
    on_attach = on_attach,
    keymap = { recommended = true, jump_to_mark = "<c-Tab>" },
    flags = { debounce_text_changed = 150 }
  })
end

coq.Now("-s")


map("<C-n>", "Focus on the tree view", ":NvimTreeToggle<CR>", {mode = "n"})

