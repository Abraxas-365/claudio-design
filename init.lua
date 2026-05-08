-- claudio-design: Transforms Claudio into a professional design creation tool.
--
-- This plugin replaces Claudio's bundled design skills with enhanced versions
-- derived from the huashu-design methodology, and registers export tools for
-- video (MP4), PowerPoint (PPTX), and PDF output.

local plugin_dir = PLUGIN_DIR

------------------------------------------------------------------------
-- 1. Disable bundled design skills — plugin provides enhanced versions
------------------------------------------------------------------------
claudio.design.configure({
  disabled_skills = {
    "mockup",
    "hifi",
    "wireframe",
    "prototype",
    "design-system",
    "design-direction-advisor",
    "handoff",
    "design-system-extractor",
    "design-flow",
  }
})

------------------------------------------------------------------------
-- 2. Load enhanced skills from plugin directory
------------------------------------------------------------------------
claudio.skills.load_dir(plugin_dir .. "/skills")

------------------------------------------------------------------------
-- 3. Helper: parse JSON input string
------------------------------------------------------------------------
local function parse_json(input_str)
  -- Minimal JSON parser using Lua patterns for flat objects
  local obj = {}
  if not input_str or input_str == "" then
    return obj
  end
  -- Try to use cjson if available, otherwise pattern-match
  local ok, cjson = pcall(require, "cjson")
  if ok then
    local success, result = pcall(cjson.decode, input_str)
    if success then return result end
  end
  -- Fallback: extract string and number values from flat JSON
  for k, v in input_str:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
    obj[k] = v
  end
  for k, v in input_str:gmatch('"([^"]+)"%s*:%s*(%d+%.?%d*)') do
    obj[k] = tonumber(v)
  end
  return obj
end

------------------------------------------------------------------------
-- 4. Helper: run a command and capture stdout
------------------------------------------------------------------------
local function run_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to execute command"
  end
  local output = handle:read("*a")
  local ok = handle:close()
  return output, ok and nil or "Command failed"
end

------------------------------------------------------------------------
-- 5. Helper: shell-escape a string
------------------------------------------------------------------------
local function shell_escape(s)
  if not s then return "''" end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

------------------------------------------------------------------------
-- 6. Export Tools
------------------------------------------------------------------------

-- ExportVideo: HTML animation → MP4 via Playwright + ffmpeg
claudio.tools.register({
  name = "ExportVideo",
  description = "Export an HTML design/animation as an MP4 video (25fps with optional BGM). " ..
    "Input: html_file (required), output_path (optional), fps (default 25), " ..
    "duration (default 3 seconds), bgm (mood name: tech|tutorial|educational|ad, or omit for no music). " ..
    "Requires Node.js >= 18 and Playwright installed (`npx playwright install chromium`). " ..
    "Requires ffmpeg on PATH.",
  capabilities = { "design" },
  agents = { "design" },
  execute = function(input_json)
    local input = parse_json(input_json)
    local html_file = input.html_file
    if not html_file then
      return '{"success": false, "error": "html_file is required"}'
    end

    local duration = input.duration or 3
    local output_path = input.output_path
    local bgm = input.bgm

    -- Build render-video command
    local script = plugin_dir .. "/scripts/render-video.js"
    local cmd = "node " .. shell_escape(script) ..
      " " .. shell_escape(html_file) ..
      " --duration=" .. tostring(duration) ..
      " --json"

    if output_path then
      cmd = cmd .. " --output=" .. shell_escape(output_path)
    end

    local render_output, err = run_command(cmd)
    if err then
      return '{"success": false, "error": "render-video.js failed: ' ..
        (render_output or "unknown error"):gsub('"', '\\"'):gsub("\n", " "):sub(1, 200) .. '"}'
    end

    -- Extract JSON line from output (last line with JSON)
    local json_line
    for line in render_output:gmatch("[^\n]+") do
      if line:match("^{") then
        json_line = line
      end
    end

    if not json_line then
      return '{"success": false, "error": "No JSON output from render-video.js"}'
    end

    -- If BGM requested and render succeeded, add music
    if bgm and json_line:match('"success"%s*:%s*true') then
      local rendered_path = json_line:match('"output_path"%s*:%s*"([^"]*)"')
      if rendered_path then
        local music_script = plugin_dir .. "/scripts/add-music.sh"
        local music_cmd = "bash " .. shell_escape(music_script) ..
          " " .. shell_escape(rendered_path) ..
          " --mood=" .. shell_escape(bgm) ..
          " --json"

        local music_output = run_command(music_cmd)
        if music_output then
          local music_json
          for line in music_output:gmatch("[^\n]+") do
            if line:match("^{") then
              music_json = line
            end
          end
          if music_json then
            return music_json
          end
        end
      end
    end

    return json_line
  end,
})

-- ExportPPTX: HTML slides → PowerPoint
claudio.tools.register({
  name = "ExportPPTX",
  description = "Export an HTML slide file as an editable PowerPoint (.pptx). " ..
    "Input: html_file (required), output_path (required). " ..
    "The HTML must follow the 4 hard constraints for editable PPTX " ..
    "(see references/editable-pptx.md). " ..
    "Requires Node.js >= 18, Playwright, pptxgenjs, and sharp.",
  capabilities = { "design" },
  agents = { "design" },
  execute = function(input_json)
    local input = parse_json(input_json)
    local html_file = input.html_file
    local output_path = input.output_path

    if not html_file then
      return '{"success": false, "error": "html_file is required"}'
    end
    if not output_path then
      return '{"success": false, "error": "output_path is required"}'
    end

    local cmd = "node " .. shell_escape(plugin_dir .. "/scripts/pptx-export.js") ..
      " " .. shell_escape(html_file) ..
      " " .. shell_escape(output_path) .. " 2>&1"

    local output, err = run_command(cmd)
    if err or not output then
      return '{"success": false, "error": "html2pptx conversion failed"}'
    end

    local json_line
    for line in output:gmatch("[^\n]+") do
      if line:match("^{") then
        json_line = line
      end
    end

    return json_line or '{"success": false, "error": "No JSON output from PPTX conversion"}'
  end,
})

-- ExportPDF: HTML slides → PDF
claudio.tools.register({
  name = "ExportPDF",
  description = "Export HTML slide files as a single vector PDF. " ..
    "Input: html_file (required — path to a directory containing .html slide files, " ..
    "or a single HTML file), output_path (required). " ..
    "Text is preserved as vectors (copyable, searchable). " ..
    "Requires Node.js >= 18, Playwright, and pdf-lib.",
  capabilities = { "design" },
  agents = { "design" },
  execute = function(input_json)
    local input = parse_json(input_json)
    local html_file = input.html_file
    local output_path = input.output_path

    if not html_file then
      return '{"success": false, "error": "html_file is required"}'
    end
    if not output_path then
      return '{"success": false, "error": "output_path is required"}'
    end

    local script = plugin_dir .. "/scripts/export-pdf.mjs"

    -- Determine if html_file is a directory or single file
    local slides_dir = html_file
    if claudio.fs.exists(html_file) then
      local stat = claudio.fs.stat(html_file)
      if stat and stat.type == "file" then
        -- Single file: use its parent directory
        slides_dir = html_file:match("(.*/)")
        if not slides_dir then
          slides_dir = "."
        end
      end
    end

    local cmd = "node " .. shell_escape(script) ..
      " --slides " .. shell_escape(slides_dir) ..
      " --out " .. shell_escape(output_path) ..
      " --json"

    local output, err = run_command(cmd)
    if err or not output then
      return '{"success": false, "error": "PDF export failed"}'
    end

    local json_line
    for line in output:gmatch("[^\n]+") do
      if line:match("^{") then
        json_line = line
      end
    end

    return json_line or '{"success": false, "error": "No JSON output from PDF export"}'
  end,
})

------------------------------------------------------------------------
-- 7. Hook: Copy components to design session directory
------------------------------------------------------------------------
claudio.hooks.on("PostToolUse", "CreateDesignSession", function(ctx)
  local session_dir = ctx and ctx.output and ctx.output:match('"session_dir"%s*:%s*"([^"]*)"')
  if not session_dir then return end

  local components_dir = plugin_dir .. "/components"
  local target_dir = session_dir .. "/components"

  -- Create target directory and copy component files
  local files = {
    "ios-frame.jsx",
    "android-frame.jsx",
    "macos-window.jsx",
    "browser-window.jsx",
    "design-canvas.jsx",
    "deck-stage.js",
    "animations.jsx",
    "ui-kit.jsx",
  }

  io.popen("mkdir -p " .. shell_escape(target_dir)):close()

  for _, file in ipairs(files) do
    local src = components_dir .. "/" .. file
    if claudio.fs.exists(src) then
      -- io.open is sandboxed; use cp via io.popen instead
      io.popen("cp " .. shell_escape(src) .. " " .. shell_escape(target_dir .. "/" .. file)):close()
    end
  end
end)
