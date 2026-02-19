-- utils/packhealth.lua
-- Snapshot runtimepath at VimEnter so we can tell which opt/* were active at startup.

_G._PACKHEALTH = _G._PACKHEALTH or {}

-- One-time hook to capture rtp at startup (exact)
if not _G._PACKHEALTH._hooked then
  _G._PACKHEALTH._hooked = true
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      local function norm(p) return (p or ""):gsub("\\", "/"):gsub("/+$", "") end
      local snap = {}
      for _, p in ipairs(vim.opt.runtimepath:get()) do
        snap[#snap + 1] = norm(p)
      end
      _G._PACKHEALTH.rtp_at_startup = snap
      _G._PACKHEALTH.rtp_snapshot_is_approx = false
    end,
  })
end

-- User command
vim.api.nvim_create_user_command("PackHealth", function()
  -- =========================
  -- Utilities
  -- =========================
  local function push(t, v) t[#t + 1] = v end

  local function norm(p)
    return (p or ""):gsub("\\", "/"):gsub("/+$", "")
  end

  local function list_dirs(globpat)
    local out = {}
    local paths = vim.fn.glob(globpat, false, true) -- list=true returns table
    for _, p in ipairs(paths or {}) do
      if vim.fn.isdirectory(p) == 1 then
        out[#out + 1] = norm(p)
      end
    end
    return out
  end

  local function strip_after(p)
    p = norm(p)
    if p:sub(-6) == "/after" then return p:sub(1, -7) end
    return p
  end

  -- =========================
  -- 1) Discover plugins from all pack roots
  -- =========================
  local pack_roots, seen_root = {}, {}

  local function add_pack_roots_under(base)
    base = norm(base)
    if base == "" then return end
    local pack_dir = base .. "/pack"
    for _, r in ipairs(list_dirs(pack_dir .. "/*")) do
      if not seen_root[r] then
        seen_root[r] = true
        pack_roots[#pack_roots + 1] = r
      end
    end
  end

  -- a) From &packpath (strip trailing /after)
  for _, entry in ipairs(vim.opt.packpath:get()) do
    add_pack_roots_under(strip_after(entry))
  end
  -- b) Fallbacks (cover typical locations)
  add_pack_roots_under(vim.fn.stdpath("data") .. "/site")
  add_pack_roots_under(vim.fn.stdpath("config") .. "/site")

  -- Gather start and opt plugin directories
  local start_paths, opt_paths = {}, {}
  for _, root in ipairs(pack_roots) do
    for _, sp in ipairs(list_dirs(root .. "/start/*")) do start_paths[#start_paths + 1] = sp end
    for _, op in ipairs(list_dirs(root .. "/opt/*"))   do opt_paths[#opt_paths + 1]   = op end
  end

  -- Sorted plugin basenames
  local function base_names(paths)
    local names = {}
    for _, p in ipairs(paths) do
      names[#names + 1] = vim.fn.fnamemodify(p, ":t")
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
  end

  local start_plugins = base_names(start_paths)
  local opt_plugins   = base_names(opt_paths)

  -- Map: name -> full path
  local plugin_path = {}
  for _, p in ipairs(start_paths) do plugin_path[vim.fn.fnamemodify(p, ":t")] = p end
  for _, p in ipairs(opt_paths)   do plugin_path[vim.fn.fnamemodify(p, ":t")] = p end

  -- =========================
  -- 2) Runtimepath lookup (subfolder-aware)
  -- =========================
  local rtp_now = {}
  for _, p in ipairs(vim.opt.runtimepath:get()) do
    rtp_now[#rtp_now + 1] = norm(p)
  end

  -- Active NOW if any rtp entry equals or is inside plugin root
  local active_now = {}
  for name, p in pairs(plugin_path) do
    local root = norm(p)
    local prefix = root .. "/"
    for _, rtp in ipairs(rtp_now) do
      if rtp == root or rtp:sub(1, #prefix) == prefix then
        active_now[name] = true
        break
      end
    end
  end

  -- Startup snapshot
  if not _G._PACKHEALTH.rtp_at_startup then
    -- No exact snapshot (likely first run after sourcing this file).
    -- Capture approximate snapshot (warning will be shown).
    _G._PACKHEALTH.rtp_at_startup = rtp_now
    _G._PACKHEALTH.rtp_snapshot_is_approx = true
  end
  local rtp_start = _G._PACKHEALTH.rtp_at_startup or {}
  local startup_active = {}
  for name, p in pairs(plugin_path) do
    local root = norm(p)
    local prefix = root .. "/"
    for _, r in ipairs(rtp_start) do
      if r == root or r:sub(1, #prefix) == prefix then
        startup_active[name] = true
        break
      end
    end
  end

  -- =========================
  -- 3) Git version resolver
  -- =========================
  local function read_file(path)
    local fd = io.open(path, "r")
    if not fd then return nil end
    local s = fd:read("*a")
    fd:close()
    return s
  end

  local function short7(s) return (s and #s >= 7) and s:sub(1, 7) or s end

  local function resolve_sha(path)
    local g = path .. "/.git"
    if vim.fn.isdirectory(g) ~= 1 then return nil end
    local head = read_file(g .. "/HEAD")
    if not head then return nil end
    head = head:gsub("%s+$", "")

    if head:match("^ref:") then
      local ref = head:match("^ref:%s*(.+)$")
      if not ref then return nil end

      local loose = read_file(g .. "/" .. ref)
      if loose then
        local full = loose:match("^([0-9a-fA-F]+)")
        return { sha = full, branch = ref:match("refs/heads/(.+)$") }
      end

      local packed = read_file(g .. "/packed-refs")
      if packed then
        for line in packed:gmatch("[^\r\n]+") do
          local sha, r = line:match("^([0-9a-fA-F]+)%s+(.+)$")
          if r == ref then
            return { sha = sha, branch = ref:match("refs/heads/(.+)$") }
          end
        end
      end
      return nil
    end

    local full = head:match("^([0-9a-fA-F]+)")
    return { sha = full, branch = nil }
  end

  -- =========================
  -- 4) Fallback async tag detection
  -- =========================
  local function git_run_async(cwd, args, cb)
    vim.system(vim.list_extend({ "git" }, args), { text = true, cwd = cwd }, function(res)
      vim.schedule(function()
        if res.code == 0 then cb((res.stdout or ""):gsub("%s+$",""))
        else cb(nil) end
      end)
    end)
  end

  local function detect_tag_async(path, cb)
    git_run_async(path, { "describe", "--tags", "--exact-match" }, function(tag)
      cb(tag ~= "" and tag or nil)
    end)
  end

  -- =========================
  -- 5) Build UI (EAGER = start + startup-active opt/*)
  -- =========================
  local function fmt_version(ver)
    if not ver or ver == "" then return "" end
    return "  ·  " .. ver
  end

  -- Partition sets
  local eager_set = {}
  for _, name in ipairs(base_names(start_paths)) do eager_set[name] = true end
  for _, name in ipairs(base_names(opt_paths)) do
    if startup_active[name] then eager_set[name] = true end
  end

  -- Materialize lists
  local eager_list, lazy_list = {}, {}
  for name, _ in pairs(eager_set) do eager_list[#eager_list + 1] = name end
  table.sort(eager_list, function(a, b) return a:lower() < b:lower() end)

  for _, name in ipairs(opt_plugins) do
    if not eager_set[name] then
      local is_active = active_now[name] == true
      lazy_list[#lazy_list + 1] = { name = name, active = is_active }
    end
  end
  table.sort(lazy_list, function(a, b) return a.name:lower() < b.name:lower() end)

  -- Counts
  local eager_count = #eager_list
  local lazy_active_count, lazy_pending_count = 0, 0
  for _, item in ipairs(lazy_list) do
    if item.active then lazy_active_count = lazy_active_count + 1
    else lazy_pending_count = lazy_pending_count + 1 end
  end

  local lines = {
    "📦 Native PackHealth Report",
    "===========================",
    "",
    "🚀 EAGER PLUGINS (Loaded on Startup):",
    "-------------------------------------",
  }

  -- If the snapshot was approximated post-startup, warn once.
  if _G._PACKHEALTH.rtp_snapshot_is_approx then
    push(lines, "ℹ️  First run: startup snapshot was captured after VimEnter.")
    push(lines, "    Eager may include plugins activated later this session. Restart Neovim for exact classification.")
  end

  local idx_eager, idx_lazy = {}, {}

  for _, name in ipairs(eager_list) do
    local idx = #lines + 1
    lines[idx] = "  [✓] " .. name .. "  ·  (resolving…)"
    idx_eager[name] = idx
  end

  push(lines, "")
  push(lines, "💤 LAZY PLUGINS (lze / opt):")
  push(lines, "-------------------------------------")

  for _, item in ipairs(lazy_list) do
    local base = (item.active and "  [🟢] " or "  [💤] ") ..
                 item.name ..
                 (item.active and " (Active)" or " (Pending Trigger)")
    local idx = #lines + 1
    lines[idx] = base .. "  ·  (resolving…)"
    idx_lazy[item.name] = idx
  end

  push(lines, "")
  push(lines, "📊 SUMMARY:")
  push(lines, "  Eager:           " .. eager_count)
  push(lines, "  Lazy (Active):   " .. lazy_active_count)
  push(lines, "  Lazy (Pending):  " .. lazy_pending_count)
  push(lines, "  Total Installed: " .. (#start_plugins + #opt_plugins))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "packhealth"

  -- =========================
  -- 6) Async version resolving (no cache)
  -- =========================
  local function update_line(name, ver)
    local idx = idx_eager[name] or idx_lazy[name]
    if not idx then return end
    vim.bo[buf].modifiable = true
    local old = vim.api.nvim_buf_get_lines(buf, idx - 1, idx, false)[1]
    local new = old:gsub("  ·  .*$", "") .. fmt_version(ver)
    vim.api.nvim_buf_set_lines(buf, idx - 1, idx, false, { new })
    vim.bo[buf].modifiable = false
  end

  local function resolve_plugin(name)
    local path = plugin_path[name]
    if not path or vim.fn.isdirectory(path .. "/.git") ~= 1 then
      return update_line(name, "n/a")
    end
    local r = (function(p)
      local g = p .. "/.git"
      if vim.fn.isdirectory(g) ~= 1 then return nil end
      local head = read_file(g .. "/HEAD")
      if not head then return nil end
      head = head:gsub("%s+$", "")
      if head:match("^ref:") then
        local ref = head:match("^ref:%s*(.+)$"); if not ref then return nil end
        local loose = read_file(g .. "/" .. ref)
        if loose then
          local full = loose:match("^([0-9a-fA-F]+)")
          return { sha = full, branch = ref:match("refs/heads/(.+)$") }
        end
        local packed = read_file(g .. "/packed-refs")
        if packed then
          for line in packed:gmatch("[^\r\n]+") do
            local sha, rr = line:match("^([0-9a-fA-F]+)%s+(.+)$")
            if rr == ref then
              return { sha = sha, branch = ref:match("refs/heads/(.+)$") }
            end
          end
        end
        return nil
      end
      local full = head:match("^([0-9a-fA-F]+)")
      return { sha = full, branch = nil }
    end)(path)

    if not r or not r.sha then
      return update_line(name, "n/a")
    end
    local branch, sha = r.branch, short7(r.sha)
    detect_tag_async(path, function(tag)
      if tag then
        update_line(name, tag)
      elseif branch then
        update_line(name, branch .. "@" .. sha)
      else
        update_line(name, sha)
      end
    end)
  end

  for _, name in ipairs(eager_list) do resolve_plugin(name) end
  for _, item in ipairs(lazy_list)  do resolve_plugin(item.name) end

end, { desc = "Show PackHealth (async, no cache)" })
