local M = {}
_NgConfigValues = {
  debug = false, -- log output not implemented
  width = 0.6, -- valeu of cols TODO allow float e.g. 0.6
  preview_height = 0.35,
  height = nil,
  default_mapping = true,
  on_attach = nil,
  -- function(client, bufnr)
  --   -- your on_attach will be called at end of navigator on_attach
  -- end,
  code_action_prompt = {enable = true, sign = true, sign_priority = 40, virtual_text = true},
  treesitter_analysis = true, -- treesitter variable context
  lsp = {
    format_on_save = true, -- set to false to disasble lsp code format on save (if you are using prettier/efm/formater etc)
    tsserver = {
      filetypes = {'typescript'} -- disable javascript etc,
      -- set to {} to disable the lspclient for all filetype
    },
    sumneko_lua = {
      -- sumneko_root_path = sumneko_root_path,
      -- sumneko_binary = sumneko_binary,
      -- cmd = {'lua-language-server'}
    }
  },
  icons = {
    -- Code action
    code_action_icon = " ",
    -- Diagnostics
    diagnostic_head = '🐛',
    diagnostic_head_severity_1 = "🈲",
    diagnostic_head_severity_2 = "☣️",
    diagnostic_head_severity_3 = "👎",
    diagnostic_head_description = "📛",
    diagnostic_virtual_text = "🦊",
    diagnostic_file = "🚑",
    -- Values
    value_changed = "📝",
    value_definition = "🦕",
    -- Treesitter
    match_kinds = {
      var = " ", -- "👹", -- Vampaire
      method = "ƒ ", --  "🍔", -- mac
      ["function"] = " ", -- "🤣", -- Fun
      parameter = "  ", -- Pi
      associated = "🤝",
      namespace = "🚀",
      type = " ",
      field = "🏈",
    },
    treesitter_defult = "🌲",
  }
}

vim.cmd("command! -nargs=0 LspLog call v:lua.open_lsp_log()")
vim.cmd("command! -nargs=0 LspRestart call v:lua.reload_lsp()")

local extend_config = function(opts)
  opts = opts or {}
  if next(opts) == nil then
    return
  end
  for key, value in pairs(opts) do
    -- if _NgConfigValues[key] == nil then
    --   error(string.format("[] Key %s not valid", key))
    --   return
    -- end
    if type(_NgConfigValues[key]) == "table" then
      for k, v in pairs(value) do
        _NgConfigValues[key][k] = v
      end
    else
      _NgConfigValues[key] = value
    end
  end
  if _NgConfigValues.sumneko_root_path or _NgConfigValues.sumneko_binary then
    vim.notify("Please put sumneko setup in lsp['sumneko_lua']", vim.log.levels.WARN)
  end
end

M.config_values = function()
  return _NgConfigValues
end

M.setup = function(cfg)
  extend_config(cfg)
  -- local log = require"navigator.util".log
  -- log(debug.traceback())
  -- log(cfg, _NgConfigValues)
  -- print("loading navigator")
  require('navigator.lspclient.clients').setup(_NgConfigValues)
  require("navigator.lspclient.mapping").setup(_NgConfigValues)
  require("navigator.reference")
  require("navigator.definition")
  require("navigator.hierarchy")
  require("navigator.implementation")
  -- log("navigator loader")
  if _NgConfigValues.code_action_prompt.enable then
    vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'navigator.codeAction'.code_action_prompt()]]
  end
  -- vim.cmd("autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4")
  if not _NgConfigValues.loaded then
    vim.cmd([[autocmd FileType * lua require'navigator.lspclient.clients'.setup()]]) -- BufWinEnter BufNewFile,BufRead ?
    _NgConfigValues.loaded = true
  end
end

return M
