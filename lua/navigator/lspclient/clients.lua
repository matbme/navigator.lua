-- todo allow config passed in
local lspconfig = nil
local log = require "navigator.util".log
local verbose = require "navigator.util".verbose

if packer_plugins ~= nil then
  if not packer_plugins["neovim/nvim-lspconfig"] or not packer_plugins["neovim/nvim-lspconfig"].loaded then
    vim.cmd [[packadd nvim-lspconfig]]
  end
  if not packer_plugins["ray-x/guihua.lua"] or not packer_plugins["guihua.lua"].loaded then
    vim.cmd [[packadd guihua.lua]]
  -- if lazyloading
  end
end
if package.loaded["lspconfig"] then
  lspconfig = require "lspconfig"
end

local highlight = require "navigator.lspclient.highlight"
if lspconfig == nil then
  error("loading lsp config")
end
local util = lspconfig.util
local config = require "navigator".config_values()

local cap = vim.lsp.protocol.make_client_capabilities()
local on_attach = require("navigator.lspclient.attach").on_attach
-- local gopls = {}
-- gopls["ui.completion.usePlaceholders"] = true

local golang_setup = {
  on_attach = on_attach,
  capabilities = cap,
  filetypes = {"go", "gomod"},
  -- init_options = {
  --   useplaceholders = true,
  --   completeunimported = true
  -- },
  message_level = vim.lsp.protocol.MessageType.Error,
  cmd = {
    "gopls"

    -- share the gopls instance if there is one already
    -- "-remote=auto",

    --[[ debug options ]]
    --
    -- "-logfile=auto",
    -- "-debug=:0",
    -- "-remote.debug=:0",
    -- "-rpc.trace",
  },
  settings = {
    gopls = {
      analyses = {unusedparams = true, unreachable = false},
      codelenses = {
        generate = true, -- show the `go generate` lens.
        gc_details = true --  // Show a code lens toggling the display of gc's choices.
      },
      usePlaceholders = true,
      completeUnimported = true,
      staticcheck = true,
      matcher = "fuzzy",
      symbolMatcher = "fuzzy",
      gofumpt = true,
      buildFlags = {"-tags", "integration"}
      -- buildFlags = {"-tags", "functional"}
    }
  },
  root_dir = function(fname)
    local util = require("lspconfig").util
    return util.root_pattern("go.mod", ".git")(fname) or util.path.dirname(fname)
  end
}
local clang_cfg = {
  cmd = {
    "clangd",
    "--background-index",
    "--suggest-missing-includes",
    "--clang-tidy",
    "--header-insertion=iwyu"
  },
  filetypes = {"c", "cpp", "objc", "objcpp"},
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = true
    on_attach(client)
  end
}
local rust_cfg = {
  filetypes = {"rust"},
  root_dir = util.root_pattern("Cargo.toml", "rust-project.json", ".git"),
  message_level = vim.lsp.protocol.MessageType.error,
  on_attach = on_attach,
  settings = {
    root_dir = util.root_pattern("Cargo.toml", "rust-project.json", ".git"),
    ["rust-analyzer"] = {
      assist = {importMergeBehavior = "last", importPrefix = "by_self"},
      cargo = {loadOutDirsFromCheck = true},
      procMacro = {enable = true}
    }
  }
}

local sqls_cfg = {
  filetypes = {"sql"},
  on_attach = function(client, bufnr)
    client.resolved_capabilities.execute_command = true
    highlight.diagnositc_config_sign()
    require "sqls".setup {picker = "telescope"} -- or default
  end,
  settings = {
    cmd = {"sqls", "-config", "$HOME/.config/sqls/config.yml"}
    -- alterantively:
    -- connections = {
    --   {
    --     driver = 'postgresql',
    --     datasourcename = 'host=127.0.0.1 port=5432 user=postgres password=password dbname=user_db sslmode=disable',
    --   },
    -- },
  }
}
-- lua setup
local sumneko_root_path = config.sumneko_root_path
local sumneko_binary = config.sumneko_binary

local lua_cfg = {
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
  filetypes = {"lua"},
  on_attach = on_attach,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
        -- Setup your lua path
        path = vim.split(package.path, ";")
      },
      diagnostics = {
        enable = true,
        -- Get the language server to recognize the `vim` global
        globals = {
          "vim",
          "describe",
          "it",
          "before_each",
          "after_each",
          "teardown",
          "pending"
        }
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
          -- [vim.fn.expand("~/repos/nvim/lua")] = true
        }
      }
    }
  }
}

local pyright_cfg = {
  cmd = {"pyright-langserver", "--stdio"},
  filetypes = {"python"},
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true
      }
    }
  }
}

local servers = {
  "gopls",
  "tsserver",
  "flow",
  "bashls",
  "dockerls",
  "pyls",
  "pyright",
  "jedi_language_server",
  "jdtls",
  "sumneko_lua",
  "vimls",
  "html",
  "jsonls",
  "cssls",
  "yamlls",
  "clangd",
  "sqls",
  "denols",
  "dartls",
  "dotls",
  "kotlin_language_server",
  "nimls",
  "intelephense",
  "phpactor",
  "r_language_server",
  "rust_analyzer",
  "terraformls"
}
local default_cfg = {on_attach = on_attach}

local function load_cfg(client, cfg)
  local ft = vim.bo.filetype

  if lspconfig[client] == nil then
    log("not supported", client)
    return
  end
  local lspft = lspconfig[client].document_config.default_config.filetypes

  local should_load = false
  if lspft ~= nil and #lspft > 0 then
    for _, value in ipairs(lspft) do
      if ft == value then
        should_load = true
      end
    end
    if should_load then
      log(client, "loaded for", ft)
      lspconfig[client].setup(cfg)
    end
  end
end

local function setup(user_opts)
  verbose(debug.traceback())

  if lspconfig == nil then
    error("lsp-config need installed and enabled")
    return
  end

  highlight.diagnositc_config_sign()
  highlight.add_highlight()
  for _, lspclient in ipairs(servers) do
    load_cfg(lspclient, default_cfg)
  end
  load_cfg("gopls", golang_setup)
  load_cfg("sqls", sqls_cfg)
  load_cfg("sumneko_lua", lua_cfg)
  load_cfg("clangd", clang_cfg)
  load_cfg("rust_analyzer", rust_cfg)
  load_cfg("pyright", pyright_cfg)

  log("setup all clients finished")
end
return {setup = setup, cap = cap}
