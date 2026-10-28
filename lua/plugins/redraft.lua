-- redraft has no native Gemini provider. Its OpenAI provider is pointed at
-- Gemini's OpenAI-compatible endpoint (llm.base_url below, OPENAI_API_KEY set to
-- a Gemini key), which needs the TypeScript backend patched to forward baseURL
-- and to use the chat completions API. Lazy runs `build` after every install,
-- update and restore, so the patch is reapplied whenever the source is reset.
local patches = {
  { 'protected maxOutputTokens: number;', 'protected maxOutputTokens: number;\n  protected baseURL?: string;' },
  {
    'constructor(apiKey: string, model: string, maxOutputTokens?: number) {',
    'constructor(apiKey: string, model: string, maxOutputTokens?: number, baseURL?: string) {',
  },
  { 'this.maxOutputTokens = maxOutputTokens || 4096;', 'this.maxOutputTokens = maxOutputTokens || 4096;\n    this.baseURL = baseURL;' },
  { 'return createOpenAI({ apiKey: this.apiKey });', 'return createOpenAI({ apiKey: this.apiKey, baseURL: this.baseURL });' },
  { 'new OpenAIProvider(apiKey, model, maxOutputTokens)', 'new OpenAIProvider(apiKey, model, maxOutputTokens, baseURL)' },
  { 'model: provider(this.model),', "model: typeof provider.chat === 'function' ? provider.chat(this.model) : provider(this.model)," },
}

local function patch_llm_ts(dir)
  local path = dir .. '/ts/src/llm.ts'
  local src = assert(io.open(path, 'r'), 'nvim-redraft: cannot read ' .. path):read '*a'
  if src:find('baseURL: this.baseURL', 1, true) then
    return
  end
  for _, p in ipairs(patches) do
    assert(src:find(p[1], 1, true), 'nvim-redraft: patch target not found, upstream changed: ' .. p[1])
    src = table.concat(vim.split(src, p[1], { plain = true }), p[2])
  end
  local f = assert(io.open(path, 'w'))
  f:write(src)
  f:close()
end

local function run(cmd, cwd)
  local res = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if res.code ~= 0 then
    error(table.concat(cmd, ' ') .. ' failed:\n' .. (res.stderr or '') .. (res.stdout or ''))
  end
end

return {
  'jim-at-jibba/nvim-redraft',
  event = 'VeryLazy',
  build = function(plugin)
    patch_llm_ts(plugin.dir)
    run({ 'npm', 'install' }, plugin.dir .. '/ts')
    run({ 'npm', 'run', 'build' }, plugin.dir .. '/ts')
  end,
  keys = {
    {
      '<leader>ae',
      function()
        require('nvim-redraft').edit()
      end,
      mode = 'v',
      desc = 'AI Edit Selection',
    },
    {
      '<leader>am',
      function()
        require('nvim-redraft').select_model()
      end,
      desc = 'Select AI Model',
    },
  },
  opts = {
    -- AI edits appear as conflict markers for review
    diff_mode = true,
    debug = false,
    llm = {
      base_url = 'https://generativelanguage.googleapis.com/v1beta/openai/',
      models = {
        {
          provider = 'openai',
          model = 'gemini-3.1-pro-preview',
          label = 'Gemini 3.1 Pro',
        },
        {
          provider = 'copilot',
          model = 'gpt-5.2',
          label = 'GitHub Copilot (GPT 5.2)',
        },
      },
      default_model_index = 1,
    },
  },
}
