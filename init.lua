-- claudio-design: Transforms Claudio into a professional design creation tool.
--
-- This plugin replaces Claudio's bundled design skills with enhanced versions
-- derived from the huashu-design methodology, and registers the full suite of
-- design tools (ListDesigns, CreateDesignSession, RenderMockup, VerifyMockup,
-- BundleMockup, ExportHandoff, ReviewDesignFidelity) plus export tools for
-- video (MP4), PowerPoint (PPTX), and PDF output.
--
-- Config pattern — call setup() from your config callback:
--   claudio.plugin.use({
--     source = "Abraxas-365/claudio-design",
--     config = function()
--       require("claudio-design").setup({
--         critic_model   = "claude-opus-4-6",  -- optional, default: haiku
--         fidelity_model = "claude-opus-4-6",  -- optional, default: haiku
--       })
--     end,
--   })

local plugin_dir = PLUGIN_DIR

------------------------------------------------------------------------
-- 1. Helper: parse JSON input string
------------------------------------------------------------------------
local function parse_json(input_str)
  if not input_str or input_str == "" then return {} end
  local ok, cjson = pcall(require, "cjson")
  if ok then
    local success, result = pcall(cjson.decode, input_str)
    if success then return result end
  end
  -- Fallback: extract string and number values from flat JSON
  local obj = {}
  for k, v in input_str:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do obj[k] = v end
  for k, v in input_str:gmatch('"([^"]+)"%s*:%s*(%d+%.?%d*)') do obj[k] = tonumber(v) end
  return obj
end

------------------------------------------------------------------------
-- 2. Helper: run a command and capture stdout+stderr
------------------------------------------------------------------------
local function run_command(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then return nil, "Failed to execute command" end
  local output = handle:read("*a")
  local ok = handle:close()
  return output, ok and nil or "Command failed"
end

------------------------------------------------------------------------
-- 3. Helper: shell-escape a string (POSIX single-quote)
------------------------------------------------------------------------
local function shell_escape(s)
  if not s then return "''" end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

------------------------------------------------------------------------
-- 4. Helper: write content to a file via io.popen write mode
------------------------------------------------------------------------
local function write_file(path, content)
  local h = io.popen("cat > " .. shell_escape(path), "w")
  if not h then return false end
  h:write(content)
  h:close()
  return true
end

------------------------------------------------------------------------
-- 5. Helper: pure-Lua JSON encoder
------------------------------------------------------------------------
local function json_encode(val)
  local t = type(val)
  if t == "nil" then
    return "null"
  elseif t == "boolean" then
    return val and "true" or "false"
  elseif t == "number" then
    if val ~= val or val == math.huge or val == -math.huge then return "null" end
    return tostring(val)
  elseif t == "string" then
    return '"' .. val
        :gsub('\\', '\\\\')
        :gsub('"',  '\\"')
        :gsub('\n', '\\n')
        :gsub('\r', '\\r')
        :gsub('\t', '\\t')
        :gsub('%c', function(c) return string.format('\\u%04x', c:byte()) end)
      .. '"'
  elseif t == "table" then
    local n = #val
    local count = 0
    for _ in pairs(val) do count = count + 1 end
    if count == n and n > 0 then
      -- Array
      local parts = {}
      for i = 1, n do parts[i] = json_encode(val[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      -- Object
      local parts = {}
      for k, v in pairs(val) do
        parts[#parts + 1] = '"' .. tostring(k) .. '":' .. json_encode(v)
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  return "null"
end

------------------------------------------------------------------------
-- 6. Helper: pure-Lua base64 encoder (RFC 4648)
------------------------------------------------------------------------
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64_encode(data)
  if not data or data == "" then return "" end
  local result = {}
  local i = 1
  local len = #data

  while i <= len - 2 do
    local b0, b1, b2 = data:byte(i, i + 2)
    local n = b0 * 65536 + b1 * 256 + b2
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 262144) + 1,     math.floor(n / 262144) + 1)
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1,  math.floor(n / 4096) % 64 + 1)
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 64)   % 64 + 1,  math.floor(n / 64)   % 64 + 1)
    result[#result + 1] = B64_CHARS:sub(n % 64 + 1, n % 64 + 1)
    i = i + 3
  end

  local rem = len - i + 1
  if rem == 1 then
    local b0 = data:byte(i)
    local n = b0 * 65536
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 262144) + 1,    math.floor(n / 262144) + 1)
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
    result[#result + 1] = "=="
  elseif rem == 2 then
    local b0, b1 = data:byte(i, i + 1)
    local n = b0 * 65536 + b1 * 256
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 262144) + 1,    math.floor(n / 262144) + 1)
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
    result[#result + 1] = B64_CHARS:sub(math.floor(n / 64)   % 64 + 1, math.floor(n / 64)   % 64 + 1)
    result[#result + 1] = "="
  end

  return table.concat(result)
end

------------------------------------------------------------------------
-- 7. Helper: extract outermost JSON object from LLM response text
------------------------------------------------------------------------
local function extract_json(text)
  local s = text:find("{")
  if not s then return nil end
  local depth = 0
  local in_string = false
  local escape_next = false
  for i = s, #text do
    local c = text:sub(i, i)
    if escape_next then
      escape_next = false
    elseif c == "\\" and in_string then
      escape_next = true
    elseif c == '"' then
      in_string = not in_string
    elseif not in_string then
      if     c == "{" then depth = depth + 1
      elseif c == "}" then
        depth = depth - 1
        if depth == 0 then return text:sub(s, i) end
      end
    end
  end
  return nil
end

------------------------------------------------------------------------
-- 8. Helper: slugify a file-system path to a safe identifier
------------------------------------------------------------------------
local function make_slug(path)
  if not path or path == "" then
    local cwd, _ = run_command("pwd")
    path = (cwd or "/unknown"):gsub("%s+$", "")
  end
  local name = path:match("[^/]+$") or path
  return name:gsub("[^%w%-]", "-"):lower()
end

------------------------------------------------------------------------
-- 9. Module-local config — overridable via setup()
------------------------------------------------------------------------
local _config = {
  critic_model   = os.getenv("CLAUDIO_DESIGN_CRITIC_MODEL") or "claude-haiku-4-5-20251001",
  fidelity_model = os.getenv("CLAUDIO_DESIGN_FIDELITY_MODEL") or "claude-haiku-4-5-20251001",
}

local function critic_model()
  return _config.critic_model
end

local function fidelity_model()
  return _config.fidelity_model
end

------------------------------------------------------------------------
-- 10. Registration
------------------------------------------------------------------------

------------------------------------------------------------------------
-- 11. Load enhanced skills from plugin directory
------------------------------------------------------------------------
claudio.skills.load_dir(plugin_dir .. "/skills")

------------------------------------------------------------------------
-- 11a. Register the design agent
------------------------------------------------------------------------
claudio.agents.register({
  name        = "design",
  description = "Senior UI/UX designer and frontend engineer. Produces pixel-accurate interactive mockups as self-contained React JSX rendered in the browser. Handles the full design pipeline: brief → direction → tokens → mockup → verify → bundle → handoff → export.",
  model       = "claude-sonnet-4-6",
  tools       = {
    "ListDesigns", "CreateDesignSession", "RenderMockup", "VerifyMockup",
    "BundleMockup", "ExportHandoff", "ReviewDesignFidelity",
    "ExportVideo", "ExportPPTX", "ExportPDF",
    "Read", "Write", "Edit", "Glob", "Bash",
    "WebSearch", "WebFetch", "Agent", "SpawnTeammate",
  },
  system      = [[You are a senior UI/UX designer and frontend engineer. Your specialty is producing pixel-accurate, interactive mockups as self-contained React JSX rendered directly in the browser using React 18 + Babel Standalone. No build tools, no node_modules, no bundler — everything runs from CDN in plain HTML.

# ROLE

You produce high-fidelity, interactive UI mockups. Each mockup is a set of four files:

- tokens.jsx     — design tokens (colors, typography, spacing, radii, shadows)
- primitives.jsx — base components (Button, Input, Card, Badge, Avatar, Icon, etc.)
- screens.jsx    — full screen compositions
- index.html     — wires everything together via Babel Standalone

Your mockups are not wireframes. They are visually complete, polished, and immediately usable as a design reference. Every decision — color, type scale, spacing, shadow, border radius — must be intentional and coherent.

# WORKFLOW (mandatory steps)

**Step 1 — Understand the brief.**
If the platform, screens, brand, or target audience are unclear, ask 2–3 focused clarifying questions. Do not guess when the answer materially changes the design.

**Session handling:**
1. Call ListDesigns first. If a session exists, use its session_dir for all subsequent calls.
2. If no session: call RenderMockup with session_dir omitted — it creates the session automatically. Capture session_dir from the output.
3. Always pass session_dir explicitly to BundleMockup and ExportHandoff.

**Step 2 — Pick ONE bold aesthetic direction.**
State it in a single sentence before writing any code. "Clean and modern" is NOT a direction.

Good examples:
- "Dark industrial with amber highlights — heavy type, sharp corners, high contrast"
- "Soft pastel clay — rounded shapes, warm neutrals, playful scale"
- "Brutalist high-contrast editorial — tight grid, raw typography, deliberate asymmetry"
- "Frosted glass sci-fi dark — blur surfaces, neon accents, subtle grain"

**Step 3 — Define design tokens in tokens.jsx.**
Always use hex (#RRGGBB) for all colors. Never oklch, never hsl, never rgb().

**Step 4 — Build primitive components in primitives.jsx.**
Generic, reusable: Button, Input, Card, Badge, Avatar, Icon, Divider, Stack. Consume tokens only.

**Step 5 — Compose screens in screens.jsx.**
Each screen wrapped in a data-artboard div. Export via Object.assign(window, ...).

**Step 6 — Call RenderMockup.** Fix any console_errors before proceeding.

**Step 7 — Call VerifyMockup.** Score must be >= 75 to pass. Max 3 render+verify cycles.

**Step 8 — Call BundleMockup.** Show the user the bundle URL from the tool output.

# OUTPUT RULES

- React 18 functional components only. No class components.
- All styles inline via style={{}}. No CSS files, no Tailwind.
- All icons as inline SVG. No external icon libraries.
- Every color must use a token: C.tokenName. Zero raw values in components.
- Export via Object.assign(window, {...}).
- No fetch() or network calls. All data is hardcoded or prop-driven.

# TOKEN FORMAT

```js
const C = { brand: '#4A5FD8', surface: '#1A1B1F', onSurface: '#F2F2F4' }
const TYPE = { h1: { fontSize: 40, fontWeight: 800 }, body: { fontSize: 16 } }
const S = { xs: 4, sm: 8, md: 16, lg: 24, xl: 40 }
const R = { sm: 4, md: 8, lg: 16, full: 9999 }
```

# ARTBOARD CONVENTION

Wrap each screen in: <div data-artboard="Screen Name" style={{width:390, minHeight:844}}>

# ANTI-SLOP RULES

- No gradient rainbow buttons
- No glassmorphism unless it fits the direction
- No "hero section with big text and CTA" as the only idea
- No stock photo placeholders — use geometric shapes or initials
- Every screen must have a clear visual hierarchy
- Typography must be intentional — not just system font at default size]],
})

------------------------------------------------------------------------
-- 12. Tool: ListDesigns
--     Scan ~/.claudio/projects/{slug}/designs/ and return session list
------------------------------------------------------------------------
claudio.tools.register({
  name        = "ListDesigns",
  description = "List all design sessions for the current project. " ..
    "Input: project_path (optional — defaults to current directory). " ..
    "Returns JSON array of sessions with name, path, created_at, has_bundle, has_handoff, screens.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input       = parse_json(input_json)
    local slug        = make_slug(input.project_path)
    local designs_dir = os.getenv("HOME") .. "/.claudio/projects/" .. slug .. "/designs"

    local find_out = run_command(
      "find " .. shell_escape(designs_dir) ..
      " -maxdepth 1 -mindepth 1 -type d 2>/dev/null"
    ) or ""

    local sessions = {}
    for dir in find_out:gmatch("[^\n]+") do
      if dir ~= "" then
        local name = dir:match("[^/]+$") or dir

        local bundle_test = run_command(
          "test -f " .. shell_escape(dir .. "/bundle/mockup.html") .. " && echo yes || echo no"
        ) or "no"
        local handoff_test = run_command(
          "test -f " .. shell_escape(dir .. "/handoff/spec.md") .. " && echo yes || echo no"
        ) or "no"
        local screens_out = run_command(
          "ls " .. shell_escape(dir .. "/screenshots/") ..
          " 2>/dev/null | grep -c '\\.png$' 2>/dev/null || echo 0"
        ) or "0"

        sessions[#sessions + 1] = {
          name        = name,
          path        = dir,
          created_at  = name:match("^(%d+)") or "",
          has_bundle  = bundle_test:match("yes") ~= nil,
          has_handoff = handoff_test:match("yes") ~= nil,
          screens     = tonumber(screens_out:match("%d+")) or 0,
        }
      end
    end

    return json_encode(sessions)
  end,
})

------------------------------------------------------------------------
-- 12. Tool: CreateDesignSession
--     Create a new session directory with scaffold
------------------------------------------------------------------------
claudio.tools.register({
  name        = "CreateDesignSession",
  description = "Create a new design session directory with scaffold. " ..
    "Input: session_name (required), project_path (optional). " ..
    "Creates ~/.claudio/projects/{slug}/designs/{timestamp}-{name}/ with " ..
    "subdirectories: screenshots/, bundle/, handoff/, exports/, components/. " ..
    "Writes manifest.json and copies plugin component library.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input        = parse_json(input_json)
    local session_name = input.session_name
    if not session_name or session_name == "" then
      return '{"success":false,"error":"session_name is required"}'
    end

    local slug         = make_slug(input.project_path)
    local timestamp    = tostring(os.time())
    local safe_name    = session_name:gsub("[^%w%-]", "-"):lower()
    local dir_name     = timestamp .. "-" .. safe_name
    local base_dir     = os.getenv("HOME") .. "/.claudio/projects/" .. slug .. "/designs"
    local session_dir  = base_dir .. "/" .. dir_name

    -- Create session subdirectories
    for _, sub in ipairs({ "", "screenshots", "bundle", "handoff", "exports", "components" }) do
      run_command("mkdir -p " .. shell_escape(session_dir .. (sub ~= "" and ("/" .. sub) or "")))
    end

    -- Write initial manifest.json
    local now          = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local manifest_path = session_dir .. "/manifest.json"
    write_file(manifest_path, json_encode({
      session_name = session_name,
      created_at   = now,
      slug         = slug,
      screens      = {},
    }))

    -- Copy plugin component library into session components/
    local components_src = plugin_dir .. "/components"
    local components_dst = session_dir .. "/components"
    run_command(
      "cp -r " .. shell_escape(components_src) .. "/. " ..
      shell_escape(components_dst) .. "/ 2>/dev/null || true"
    )

    -- Copy starters if the directory exists, else write minimal starter
    local starters_dir  = plugin_dir .. "/starters"
    local starters_test = run_command(
      "test -d " .. shell_escape(starters_dir) .. " && echo yes || echo no"
    ) or "no"

    if starters_test:match("yes") then
      run_command(
        "cp -r " .. shell_escape(starters_dir) .. "/. " ..
        shell_escape(session_dir) .. "/ 2>/dev/null || true"
      )
    else
      -- Write minimal index.html starter inline
      write_file(session_dir .. "/index.html", [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Design Session</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --color-primary: oklch(0.55 0.15 250);
      --color-surface: oklch(0.97 0.01 80);
      --color-ink:     oklch(0.25 0.02 250);
      --color-accent:  oklch(0.65 0.20 30);
    }
    body { background: #1a1a1a; display: flex; gap: 24px; padding: 24px; }
    [data-artboard] {
      background: var(--color-surface);
      flex-shrink: 0;
      position: relative;
      overflow: hidden;
    }
  </style>
</head>
<body>
  <div data-artboard="screen-1" style="width:1440px;height:900px;">
    <!-- Your design goes here -->
  </div>
</body>
</html>]])
    end

    return json_encode({
      success       = true,
      session_dir   = session_dir,
      session_name  = session_name,
      manifest_path = manifest_path,
    })
  end,
})

------------------------------------------------------------------------
-- 13. Tool: RenderMockup
--     Screenshot all [data-artboard] elements via embedded Playwright JS
------------------------------------------------------------------------

-- Playwright render script — embedded as a Lua long string
local RENDER_MOCKUP_JS = [=[
'use strict';
const { chromium } = require('playwright');
const path         = require('path');
const fs           = require('fs');

(async () => {
  const htmlFile      = process.argv[2];
  const sessionDir    = process.argv[3];
  const vpWidth       = parseInt(process.argv[4])  || 1440;
  const vpHeight      = parseInt(process.argv[5])  || 900;

  if (!htmlFile || !sessionDir) {
    console.log(JSON.stringify({ success: false, screens: [], errors: [{ error: 'Missing arguments: htmlFile sessionDir' }] }));
    process.exit(1);
  }

  const screenshotsDir = path.join(sessionDir, 'screenshots');
  if (!fs.existsSync(screenshotsDir)) fs.mkdirSync(screenshotsDir, { recursive: true });

  const browser = await chromium.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const page    = await browser.newPage();
  await page.setViewportSize({ width: vpWidth, height: vpHeight });

  const fileUrl = htmlFile.startsWith('file://') ? htmlFile : 'file://' + path.resolve(htmlFile);
  await page.goto(fileUrl, { waitUntil: 'networkidle', timeout: 30000 });

  // Honour optional __ready signal (used by animation-based designs)
  try {
    await page.waitForFunction(() => window.__ready === true, { timeout: 3000 });
  } catch (_) { /* no ready signal — proceed */ }

  const artboards = await page.$$('[data-artboard]');
  const screens   = [];
  const errors    = [];

  if (artboards.length === 0) {
    // No artboards — screenshot the full viewport
    const outPath = path.join(screenshotsDir, 'screen-1.png');
    try {
      await page.screenshot({ path: outPath, fullPage: false });
      screens.push({ name: 'screen-1', path: outPath, width: vpWidth, height: vpHeight });
    } catch (e) {
      errors.push({ name: 'screen-1', error: e.message });
    }
  } else {
    for (let i = 0; i < artboards.length; i++) {
      const ab   = artboards[i];
      const name = await ab.getAttribute('data-artboard') || ('screen-' + (i + 1));
      const out  = path.join(screenshotsDir, name + '.png');
      try {
        await ab.screenshot({ path: out });
        const box = await ab.boundingBox();
        screens.push({
          name,
          path:   out,
          width:  box ? Math.round(box.width)  : vpWidth,
          height: box ? Math.round(box.height) : vpHeight,
        });
      } catch (e) {
        errors.push({ name, error: e.message });
      }
    }
  }

  await browser.close();
  console.log(JSON.stringify({ success: true, screens, errors }));

})().catch(err => {
  process.stderr.write(err.stack + '\n');
  console.log(JSON.stringify({ success: false, screens: [], errors: [{ error: err.message }] }));
  process.exit(1);
});
]=]

claudio.tools.register({
  name        = "RenderMockup",
  description = "Render an HTML mockup file into screenshots using Playwright. " ..
    "Input: html_file (required), session_dir (required), " ..
    "viewport_width (default 1440), viewport_height (default 900). " ..
    "Finds all [data-artboard] elements and screenshots each one. " ..
    "Requires Node.js >= 18 and Playwright (`npx playwright install chromium`).",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input    = parse_json(input_json)
    local html_file = input.html_file
    local session_dir = input.session_dir

    if not html_file then
      return '{"success":false,"error":"html_file is required"}'
    end
    if not session_dir then
      return '{"success":false,"error":"session_dir is required"}'
    end

    local vw = tonumber(input.viewport_width)  or 1440
    local vh = tonumber(input.viewport_height) or 900

    -- Write the Playwright script to a unique temp file
    local script_path = "/tmp/claudio-render-" .. os.time() .. ".js"
    write_file(script_path, RENDER_MOCKUP_JS)

    -- Ensure screenshots dir exists
    run_command("mkdir -p " .. shell_escape(session_dir .. "/screenshots"))

    local cmd = "node " .. shell_escape(script_path) ..
      " " .. shell_escape(html_file) ..
      " " .. shell_escape(session_dir) ..
      " " .. tostring(vw) ..
      " " .. tostring(vh) ..
      " 2>&1"

    local output = run_command(cmd) or ""

    -- Clean up temp script
    run_command("rm -f " .. shell_escape(script_path))

    -- Extract JSON line from output
    local json_line
    for line in output:gmatch("[^\n]+") do
      if line:match("^{") then json_line = line end
    end

    if not json_line then
      return json_encode({
        success = false,
        error   = "No JSON output from render script: " .. output:sub(1, 300),
      })
    end

    -- Update manifest.json with rendered screen list
    local screens_json = json_line:match('"screens"%s*:%s*(%[.-%])')
    if screens_json then
      local manifest_path = session_dir .. "/manifest.json"
      local manifest_raw  = claudio.fs.read(manifest_path)
      if manifest_raw then
        -- Inject / replace "screens" key
        local updated = manifest_raw:gsub('"screens"%s*:%s*%[.-%]', '"screens":' .. screens_json)
        if not updated:find('"screens"') then
          updated = manifest_raw:gsub('}%s*$', ',"screens":' .. screens_json .. '}')
        end
        write_file(manifest_path, updated)
      end
    end

    return json_line
  end,
})

------------------------------------------------------------------------
-- 14. Tool: VerifyMockup
--     Score a screenshot with a vision LLM (5-dimension, 0-50)
------------------------------------------------------------------------
local VERIFY_PROMPT = [[You are a senior UI/UX design critic. Score this screenshot across 5 dimensions.

Return ONLY valid JSON — no markdown, no explanation outside the JSON:

{
  "score": <integer 0-50, sum of dimensions>,
  "dimensions": {
    "composition": <0-10>,
    "typography":  <0-10>,
    "color":       <0-10>,
    "spacing":     <0-10>,
    "polish":      <0-10>
  },
  "feedback":     "<one concise actionable sentence>",
  "strengths":    ["<strength>", "<strength>"],
  "improvements": ["<improvement>", "<improvement>"]
}

Dimension criteria:
  composition  — visual hierarchy, layout balance, information architecture
  typography   — font choices, size hierarchy, readability
  color        — harmony, contrast, brand coherence; oklch palettes score higher
  spacing      — consistent padding / margins, breathing room
  polish       — shadows, borders, micro-details, overall finish

40-50: exceptional  |  30-39: solid professional  |  20-29: acceptable  |  <20: needs work]]

claudio.tools.register({
  name        = "VerifyMockup",
  description = "Score a design screenshot using a vision LLM (5 dimensions, total 0-50). " ..
    "Input: screenshot_path (required), session_dir (optional — to update manifest). " ..
    "Reads design:critic_model from storage (fallback: claude-haiku-4-5-20251001). " ..
    "Returns JSON with score, per-dimension breakdown, and actionable feedback.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input           = parse_json(input_json)
    local screenshot_path = input.screenshot_path
    if not screenshot_path then
      return '{"success":false,"error":"screenshot_path is required"}'
    end

    -- Step 1: Get base64 image data via crop-image.js (handles large images)
    local img_data, crop_warning
    local crop_script = plugin_dir .. "/scripts/crop-image.js"
    local crop_output = run_command(
      "node " .. shell_escape(crop_script) .. " " .. shell_escape(screenshot_path)
    ) or ""

    local crop_json_str
    for line in crop_output:gmatch("[^\n]+") do
      if line:match("^{") then crop_json_str = line end
    end

    if crop_json_str and crop_json_str:match('"success"%s*:%s*true') then
      img_data     = crop_json_str:match('"data"%s*:%s*"([^"]*)"')
      crop_warning = crop_json_str:match('"crop_warning"%s*:%s*"([^"]*)"')
    else
      -- Fallback: read the file and encode with pure-Lua base64
      local raw = claudio.fs.read(screenshot_path)
      if not raw then
        return json_encode({ success = false, error = "Cannot read screenshot: " .. screenshot_path })
      end
      img_data = base64_encode(raw)
    end

    if not img_data or img_data == "" then
      return '{"success":false,"error":"Failed to obtain image data"}'
    end

    -- Step 2: Call the vision LLM
    local model = critic_model()
    local ok, result = pcall(claudio.llm.complete, {
      model      = model,
      max_tokens = 1024,
      messages   = {
        { role = "user", content = {
          { type = "text",  text = VERIFY_PROMPT },
          { type = "image", source = "base64", media_type = "image/png", data = img_data },
        }},
      },
    })

    if not ok or not result then
      local err_msg = type(result) == "string" and result or "LLM call failed"
      return json_encode({ success = false, error = err_msg })
    end

    -- Step 3: Extract JSON from LLM response
    local response_text  = (result and result.text) or ""
    local analysis_json  = extract_json(response_text)

    local out = { success = true, verified = true, model_used = model }
    if crop_warning then out.crop_warning = crop_warning end

    if analysis_json then
      out.analysis = analysis_json  -- raw JSON string for the caller to parse
      local score = analysis_json:match('"score"%s*:%s*(%d+)')
      if score then out.score = tonumber(score) end
    else
      out.raw_response = response_text:sub(1, 500)
    end

    -- Step 4: Mark manifest as verified
    local session_dir = input.session_dir
    if session_dir then
      local manifest_path = session_dir .. "/manifest.json"
      local manifest_raw  = claudio.fs.read(manifest_path)
      if manifest_raw then
        local upd = manifest_raw:gsub('"verified"%s*:%s*%a+', '"verified":true')
        if not upd:find('"verified"') then
          upd = manifest_raw:gsub('}%s*$', ',"verified":true}')
        end
        write_file(manifest_path, upd)
      end
    end

    return json_encode(out)
  end,
})

------------------------------------------------------------------------
-- 15. Tool: BundleMockup
--     Inline all CDN scripts/stylesheets into a self-contained HTML file
------------------------------------------------------------------------
claudio.tools.register({
  name        = "BundleMockup",
  description = "Bundle an HTML mockup into a self-contained file by inlining " ..
    "all CDN scripts and stylesheets. " ..
    "Input: session_dir (required). " ..
    "Reads session_dir/index.html, inlines CDN resources via curl, " ..
    "writes to session_dir/bundle/mockup.html. " ..
    "Returns {success, bundle_path, size_bytes, resources_inlined}.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input       = parse_json(input_json)
    local session_dir = input.session_dir
    if not session_dir then
      return '{"success":false,"error":"session_dir is required"}'
    end

    local html_path = session_dir .. "/index.html"
    local html      = claudio.fs.read(html_path)
    if not html then
      return json_encode({ success = false, error = "Cannot read " .. html_path })
    end

    local resources_inlined = 0

    -- Inline CDN <script src="https://..."></script>
    html = html:gsub(
      '<script([^>]-)%ssrc="(https?://[^"]+)"([^>]-)>%s*</script>',
      function(pre, url, post)
        -- Only inline scripts that lack type="module" etc — keep data-* attrs
        local content = run_command("curl -sL --max-time 20 " .. shell_escape(url)) or ""
        if #content > 50 then
          resources_inlined = resources_inlined + 1
          return '<script>' .. content .. '</script>'
        end
        return '<script' .. pre .. ' src="' .. url .. '"' .. post .. '></script>'
      end
    )

    -- Also catch self-closing variant: <script src="..."/>
    html = html:gsub(
      '<script([^>]-)%ssrc="(https?://[^"]+)"([^>]-)/?>',
      function(pre, url, post)
        local content = run_command("curl -sL --max-time 20 " .. shell_escape(url)) or ""
        if #content > 50 then
          resources_inlined = resources_inlined + 1
          return '<script>' .. content .. '</script>'
        end
        return '<script' .. pre .. ' src="' .. url .. '"' .. post .. '></script>'
      end
    )

    -- Inline CDN <link rel="stylesheet" href="https://...">
    html = html:gsub(
      '<link([^>]-)href="(https?://[^"]+)"([^>]-)/?>',
      function(pre, url, post)
        local full_tag = pre .. url .. post
        if full_tag:match('rel%s*=%s*"stylesheet"') or full_tag:match("rel%s*=%s*'stylesheet'") then
          local content = run_command("curl -sL --max-time 20 " .. shell_escape(url)) or ""
          if #content > 50 then
            resources_inlined = resources_inlined + 1
            return '<style>' .. content .. '</style>'
          end
        end
        return '<link' .. pre .. 'href="' .. url .. '"' .. post .. '>'
      end
    )

    -- Write bundle
    run_command("mkdir -p " .. shell_escape(session_dir .. "/bundle"))
    local bundle_path = session_dir .. "/bundle/mockup.html"
    write_file(bundle_path, html)

    -- Get file size
    local size_out = run_command("wc -c < " .. shell_escape(bundle_path)) or "0"
    local size_bytes = tonumber(size_out:match("%d+")) or #html

    return json_encode({
      success           = true,
      bundle_path       = bundle_path,
      size_bytes        = size_bytes,
      resources_inlined = resources_inlined,
    })
  end,
})

------------------------------------------------------------------------
-- 16. Tool: ExportHandoff
--     Extract design tokens and spec from HTML; generate developer handoff
------------------------------------------------------------------------
claudio.tools.register({
  name        = "ExportHandoff",
  description = "Generate a developer handoff package from an HTML mockup. " ..
    "Input: session_dir (required), framework (optional: tailwind|bootstrap|vanilla). " ..
    "Applies 12 extraction patterns to index.html, then writes: " ..
    "handoff/spec.md, handoff/tokens.css, handoff/tailwind.config.js (Tailwind only), " ..
    "handoff/tokens-used.json. " ..
    "Returns {success, handoff_dir, files_generated, framework_detected}.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input       = parse_json(input_json)
    local session_dir = input.session_dir
    if not session_dir then
      return '{"success":false,"error":"session_dir is required"}'
    end

    local html_path = session_dir .. "/index.html"
    local html      = claudio.fs.read(html_path)
    if not html then
      return json_encode({ success = false, error = "Cannot read " .. html_path })
    end

    -- Auto-detect framework
    local framework = input.framework
    if not framework or framework == "" then
      if html:lower():find("tailwind") or html:find("cdn%.tailwindcss%.com") then
        framework = "tailwind"
      elseif html:lower():find("bootstrap") then
        framework = "bootstrap"
      else
        framework = "vanilla"
      end
    end

    -- ----------------------------------------------------------------
    -- 12 Extraction Patterns
    -- ----------------------------------------------------------------

    -- Pattern 1: Artboard names
    local artboards = {}
    for name in html:gmatch('data%-artboard="([^"]*)"') do
      artboards[#artboards + 1] = name
    end

    -- Pattern 2: CSS class inventory (unique classes, frequency sorted)
    local class_freq = {}
    for cls_attr in html:gmatch('class="([^"]*)"') do
      for c in cls_attr:gmatch("%S+") do
        class_freq[c] = (class_freq[c] or 0) + 1
      end
    end

    -- Pattern 3: Image sources
    local images = {}
    for src in html:gmatch('<img[^>]+src="([^"]*)"') do
      images[#images + 1] = src
    end

    -- Pattern 4: Link interactions
    local links = {}
    for href in html:gmatch('<a[^>]+href="([^"]*)"') do
      links[#links + 1] = href
    end

    -- Pattern 5: Font imports (@import url() and <link> with fonts)
    local fonts = {}
    local font_seen = {}
    for url in html:gmatch('@import%s+url%([\'"]?([^\'"%)]+)[\'"]?%)') do
      if not font_seen[url] then fonts[#fonts + 1] = url; font_seen[url] = true end
    end
    for href in html:gmatch('<link[^>]+href="([^"]*fonts[^"]*)"') do
      if not font_seen[href] then fonts[#fonts + 1] = href; font_seen[href] = true end
    end

    -- Pattern 6: Icon library references
    local icons = {}
    local icon_seen = {}
    for cls_attr in html:gmatch('class="([^"]*)"') do
      for ic in cls_attr:gmatch("lucide%-[%w%-]+") do
        if not icon_seen[ic] then icons[#icons + 1] = ic; icon_seen[ic] = true end
      end
      for ic in cls_attr:gmatch("ph%-[%w%-]+") do
        if not icon_seen[ic] then icons[#icons + 1] = ic; icon_seen[ic] = true end
      end
      for ic in cls_attr:gmatch("feather%-[%w%-]+") do
        if not icon_seen[ic] then icons[#icons + 1] = ic; icon_seen[ic] = true end
      end
    end
    -- Also check SVG <use> and icon data attributes
    for ic in html:gmatch('data%-icon="([^"]*)"') do
      if not icon_seen[ic] then icons[#icons + 1] = ic; icon_seen[ic] = true end
    end

    -- Pattern 7: Component markers
    local components = {}
    local comp_seen = {}
    for name in html:gmatch('data%-component="([^"]*)"') do
      if not comp_seen[name] then components[#components + 1] = name; comp_seen[name] = true end
    end
    for name in html:gmatch('data%-component%-name="([^"]*)"') do
      if not comp_seen[name] then components[#components + 1] = name; comp_seen[name] = true end
    end

    -- Pattern 8: CSS animations and transitions
    local animations = {}
    local anim_seen = {}
    for anim in html:gmatch('animation%s*:%s*([^;}{]+)') do
      local a = anim:match("^%s*(.-)%s*$")
      if a ~= "" and not anim_seen[a] then animations[#animations + 1] = a; anim_seen[a] = true end
    end
    for trans in html:gmatch('transition%s*:%s*([^;}{]+)') do
      local t = "transition: " .. trans:match("^%s*(.-)%s*$")
      if not anim_seen[t] then animations[#animations + 1] = t; anim_seen[t] = true end
    end

    -- Pattern 9: CSS custom properties (design tokens from :root and inline)
    local tokens = {}
    for name, value in html:gmatch('%-%-([%a][%w%-]*)%s*:%s*([^;}{]+)') do
      tokens[name] = value:match("^%s*(.-)%s*$")
    end

    -- Pattern 10: Color values
    local colors = {}
    local color_seen = {}
    local function add_color(c)
      c = c:match("^%s*(.-)%s*$")
      if c ~= "" and not color_seen[c] then colors[#colors + 1] = c; color_seen[c] = true end
    end
    for c in html:gmatch('color%s*:%s*([^;}{]+)') do              add_color(c) end
    for c in html:gmatch('background%-color%s*:%s*([^;}{]+)') do  add_color(c) end
    for c in html:gmatch('background%s*:%s*([^;}{]+)') do
      if c:find("oklch") or c:find("#%x%x%x") or c:find("rgb") or c:find("hsl") then
        add_color(c)
      end
    end
    for c in html:gmatch('stroke%s*:%s*([^;}{]+)') do
      if c:find("oklch") or c:find("#%x%x%x") or c:find("rgb") then add_color(c) end
    end
    for c in html:gmatch('fill%s*:%s*([^;}{]+)') do
      if c:find("oklch") or c:find("#%x%x%x") or c:find("rgb") then add_color(c) end
    end

    -- Pattern 11: Typography declarations
    local typography = {}
    local typo_seen = {}
    for ff in html:gmatch('font%-family%s*:%s*([^;}{]+)') do
      local v = ff:match("^%s*(.-)%s*$")
      if not typo_seen["family:" .. v] then
        typography[#typography + 1] = { property = "font-family", value = v }
        typo_seen["family:" .. v] = true
      end
    end
    for fs in html:gmatch('font%-size%s*:%s*([^;}{]+)') do
      local v = fs:match("^%s*(.-)%s*$")
      if not typo_seen["size:" .. v] then
        typography[#typography + 1] = { property = "font-size", value = v }
        typo_seen["size:" .. v] = true
      end
    end
    for fw in html:gmatch('font%-weight%s*:%s*([^;}{]+)') do
      local v = fw:match("^%s*(.-)%s*$")
      if not typo_seen["weight:" .. v] then
        typography[#typography + 1] = { property = "font-weight", value = v }
        typo_seen["weight:" .. v] = true
      end
    end

    -- Pattern 12: Framework-specific utility classes
    local framework_classes = {}
    if framework == "tailwind" then
      local tw_prefixes = {
        "^text%-", "^bg%-", "^border%-", "^ring%-",
        "^p%-", "^px%-", "^py%-", "^pt%-", "^pb%-", "^pl%-", "^pr%-",
        "^m%-",  "^mx%-", "^my%-", "^mt%-", "^mb%-", "^ml%-", "^mr%-",
        "^gap%-", "^space%-", "^rounded", "^shadow", "^opacity%-",
        "^flex",  "^grid", "^col%-", "^row%-",
        "^w%-", "^h%-", "^max%-w%-", "^min%-h%-",
        "^font%-", "^leading%-", "^tracking%-",
      }
      local tw_seen = {}
      for cls_attr in html:gmatch('class="([^"]*)"') do
        for c in cls_attr:gmatch("%S+") do
          if not tw_seen[c] then
            for _, prefix in ipairs(tw_prefixes) do
              if c:match(prefix) then
                framework_classes[#framework_classes + 1] = c
                tw_seen[c] = true
                break
              end
            end
          end
        end
      end
    elseif framework == "bootstrap" then
      local bs_seen = {}
      for cls_attr in html:gmatch('class="([^"]*)"') do
        for c in cls_attr:gmatch("%S+") do
          if not bs_seen[c] and (
            c:match("^btn") or c:match("^card") or c:match("^nav") or
            c:match("^col%-") or c:match("^row") or c:match("^container") or
            c:match("^d%-") or c:match("^text%-") or c:match("^bg%-") or
            c:match("^mb%-") or c:match("^mt%-") or c:match("^px%-") or c:match("^py%-")
          ) then
            framework_classes[#framework_classes + 1] = c
            bs_seen[c] = true
          end
        end
      end
    end

    -- ----------------------------------------------------------------
    -- Generate handoff files
    -- ----------------------------------------------------------------
    local handoff_dir   = session_dir .. "/handoff"
    local files_generated = {}
    run_command("mkdir -p " .. shell_escape(handoff_dir))

    -- spec.md
    local spec_lines = {
      "# Design Handoff Specification",
      "",
      "Generated by claudio-design ExportHandoff",
      "",
      "## Screens / Artboards",
      "",
    }
    if #artboards > 0 then
      for _, ab in ipairs(artboards) do
        spec_lines[#spec_lines + 1] = "- `" .. ab .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No artboards detected — full-page layout_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Components"
    spec_lines[#spec_lines + 1] = ""
    if #components > 0 then
      for _, c in ipairs(components) do
        spec_lines[#spec_lines + 1] = "- `" .. c .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No data-component markers found_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Typography"
    spec_lines[#spec_lines + 1] = ""
    if #typography > 0 then
      for _, t in ipairs(typography) do
        spec_lines[#spec_lines + 1] = "- **" .. t.property .. "**: `" .. t.value .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No font declarations extracted_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Fonts Loaded"
    spec_lines[#spec_lines + 1] = ""
    if #fonts > 0 then
      for _, f in ipairs(fonts) do
        spec_lines[#spec_lines + 1] = "- " .. f
      end
    else
      spec_lines[#spec_lines + 1] = "_No external font imports_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Icons"
    spec_lines[#spec_lines + 1] = ""
    if #icons > 0 then
      for _, ic in ipairs(icons) do
        spec_lines[#spec_lines + 1] = "- `" .. ic .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No icon library classes detected_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Interactions & Animations"
    spec_lines[#spec_lines + 1] = ""
    if #animations > 0 then
      for _, a in ipairs(animations) do
        spec_lines[#spec_lines + 1] = "- `" .. a .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No animations or transitions detected_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Image Assets"
    spec_lines[#spec_lines + 1] = ""
    if #images > 0 then
      for _, img in ipairs(images) do
        spec_lines[#spec_lines + 1] = "- `" .. img .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No img elements detected_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Navigation / Links"
    spec_lines[#spec_lines + 1] = ""
    if #links > 0 then
      for _, l in ipairs(links) do
        spec_lines[#spec_lines + 1] = "- `" .. l .. "`"
      end
    else
      spec_lines[#spec_lines + 1] = "_No anchor links detected_"
    end

    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "## Framework"
    spec_lines[#spec_lines + 1] = ""
    spec_lines[#spec_lines + 1] = "Detected: **" .. framework .. "**"

    if #framework_classes > 0 then
      spec_lines[#spec_lines + 1] = ""
      spec_lines[#spec_lines + 1] = "### " .. (framework:sub(1,1):upper() .. framework:sub(2)) .. " Utility Classes Used"
      spec_lines[#spec_lines + 1] = ""
      spec_lines[#spec_lines + 1] = "```"
      -- Show up to 60 most-used classes
      local fc_table = {}
      for k, v in pairs(class_freq) do fc_table[#fc_table + 1] = { k, v } end
      table.sort(fc_table, function(a, b) return a[2] > b[2] end)
      local shown = 0
      for _, pair in ipairs(fc_table) do
        if shown >= 60 then break end
        spec_lines[#spec_lines + 1] = pair[1] .. " (" .. pair[2] .. "x)"
        shown = shown + 1
      end
      spec_lines[#spec_lines + 1] = "```"
    end

    local spec_path = handoff_dir .. "/spec.md"
    write_file(spec_path, table.concat(spec_lines, "\n"))
    files_generated[#files_generated + 1] = spec_path

    -- tokens.css
    local css_lines = {
      "/* Design Tokens — generated by claudio-design ExportHandoff */",
      "/* Framework: " .. framework .. " */",
      "",
      ":root {",
    }

    local token_count = 0
    for name, value in pairs(tokens) do
      css_lines[#css_lines + 1] = "  --" .. name .. ": " .. value .. ";"
      token_count = token_count + 1
    end

    if token_count == 0 then
      css_lines[#css_lines + 1] = "  /* No CSS custom properties detected */"
    end

    css_lines[#css_lines + 1] = "}"
    css_lines[#css_lines + 1] = ""
    css_lines[#css_lines + 1] = "/* Extracted color values */"
    for _, c in ipairs(colors) do
      css_lines[#css_lines + 1] = "/* " .. c .. " */"
    end

    local tokens_path = handoff_dir .. "/tokens.css"
    write_file(tokens_path, table.concat(css_lines, "\n"))
    files_generated[#files_generated + 1] = tokens_path

    -- tailwind.config.js (only for Tailwind)
    if framework == "tailwind" then
      local theme_colors = {}
      for name, value in pairs(tokens) do
        if name:match("^color%-") or name:match("^colour%-") then
          local color_name = name:gsub("^color%-", ""):gsub("^colour%-", "")
          theme_colors[color_name] = "var(--" .. name .. ")"
        end
      end

      local tw_lines = {
        "/** @type {import('tailwindcss').Config} */",
        "/** Generated by claudio-design ExportHandoff */",
        "module.exports = {",
        "  content: ['./**/*.html', './**/*.jsx', './**/*.tsx'],",
        "  theme: {",
        "    extend: {",
        "      colors: {",
      }
      for color_name, value in pairs(theme_colors) do
        tw_lines[#tw_lines + 1] = "        '" .. color_name .. "': '" .. value .. "',"
      end
      if not next(theme_colors) then
        tw_lines[#tw_lines + 1] = "        /* No --color-* tokens detected — add manually */"
      end
      tw_lines[#tw_lines + 1] = "      },"
      tw_lines[#tw_lines + 1] = "    },"
      tw_lines[#tw_lines + 1] = "  },"
      tw_lines[#tw_lines + 1] = "  plugins: [],"
      tw_lines[#tw_lines + 1] = "};"

      local tw_path = handoff_dir .. "/tailwind.config.js"
      write_file(tw_path, table.concat(tw_lines, "\n"))
      files_generated[#files_generated + 1] = tw_path
    end

    -- tokens-used.json
    local tokens_used = {
      artboards        = artboards,
      components       = components,
      fonts            = fonts,
      icons            = icons,
      colors           = colors,
      animations       = animations,
      framework        = framework,
      framework_classes = framework_classes,
      token_count      = token_count,
      tokens           = tokens,
    }
    local tokens_json_path = handoff_dir .. "/tokens-used.json"
    write_file(tokens_json_path, json_encode(tokens_used))
    files_generated[#files_generated + 1] = tokens_json_path

    return json_encode({
      success             = true,
      handoff_dir         = handoff_dir,
      files_generated     = files_generated,
      framework_detected  = framework,
      token_count         = token_count,
      artboard_count      = #artboards,
      component_count     = #components,
    })
  end,
})

------------------------------------------------------------------------
-- 17. Tool: ReviewDesignFidelity
--     Screenshot live URLs and compare with design screenshots via LLM
------------------------------------------------------------------------
local FIDELITY_PROMPT = [[You are a design fidelity reviewer. Compare:
- Image 1: The original design mockup
- Image 2: The live implementation / screenshot

Score fidelity on a 0-100 scale and return ONLY valid JSON:

{
  "score": <integer 0-100>,
  "issues": ["<specific visual deviation>", "..."],
  "matches": ["<what was implemented faithfully>", "..."],
  "feedback": "<one-sentence overall summary>"
}

100 = pixel-perfect  |  80-99 = minor deviations  |  60-79 = noticeable differences
40-59 = significant differences  |  0-39 = major misalignment]]

-- Screenshot-URL script — embedded as a Lua long string
local SCREENSHOT_URL_JS = [=[
'use strict';
const { chromium } = require('playwright');

const url         = process.argv[2];
const viewportArg = process.argv[3];

if (!url) {
  console.log(JSON.stringify({ success: false, error: 'No URL provided' }));
  process.exit(1);
}

(async () => {
  let width = 1440, height = 900;
  if (viewportArg) {
    const m = viewportArg.match(/^(\d+)[xX×](\d+)$/);
    if (m) { width = parseInt(m[1]); height = parseInt(m[2]); }
  }
  try {
    const browser    = await chromium.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const page       = await browser.newPage();
    await page.setViewportSize({ width, height });
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
    const screenshot = await page.screenshot({ fullPage: false });
    await browser.close();
    console.log(JSON.stringify({
      success: true,
      data:    screenshot.toString('base64'),
      width,
      height,
    }));
  } catch (e) {
    console.log(JSON.stringify({ success: false, error: e.message }));
  }
})();
]=]

claudio.tools.register({
  name        = "ReviewDesignFidelity",
  description = "Compare a live implementation against its design mockup screenshots. " ..
    "Input: screens (array of {name, url?, template_path?}), " ..
    "session_name (optional — to locate design screenshots). " ..
    "For each screen, screenshots the live URL with Playwright and compares against " ..
    "the design screenshot using a vision LLM. " ..
    "Reads design:fidelity_model from storage. " ..
    "Returns {overall_score, screens: [{name, score, issues}]}.",
  capabilities = { "design" },
  agents       = { "design" },
  execute = function(input_json)
    local input = parse_json(input_json)

    -- Screens can be passed as a JSON array string in input.screens
    local screens_raw = input.screens
    if not screens_raw or type(screens_raw) ~= "table" then
      return '{"success":false,"error":"screens array is required"}'
    end

    -- Write screenshot-url.js to temp location
    local shot_script = "/tmp/claudio-shot-url-" .. os.time() .. ".js"
    write_file(shot_script, SCREENSHOT_URL_JS)

    local model   = fidelity_model()
    local results = {}
    local total   = 0

    for _, screen in ipairs(screens_raw) do
      local screen_name     = screen.name or ("screen-" .. #results + 1)
      local live_url        = screen.url
      local template_path   = screen.template_path

      -- 1. Get live screenshot base64
      local live_b64
      if live_url then
        local shot_output = run_command(
          "node " .. shell_escape(shot_script) ..
          " " .. shell_escape(live_url) ..
          " 1440x900"
        ) or ""
        local shot_json
        for line in shot_output:gmatch("[^\n]+") do
          if line:match("^{") then shot_json = line end
        end
        if shot_json and shot_json:match('"success"%s*:%s*true') then
          live_b64 = shot_json:match('"data"%s*:%s*"([^"]*)"')
        end
      end

      -- 2. Get design screenshot base64 (from session dir or template_path)
      local design_b64
      local design_source = template_path
      if not design_source and input.session_name then
        -- Try to find in ~/.claudio/projects/*/designs/*-session_name/screenshots/
        local find_out = run_command(
          "find " .. shell_escape(os.getenv("HOME") .. "/.claudio/projects") ..
          " -path '*/" .. input.session_name .. "/screenshots/" .. screen_name .. ".png'" ..
          " -type f 2>/dev/null | head -1"
        ) or ""
        design_source = find_out:match("([^\n]+)")
      end

      if design_source and design_source ~= "" then
        local crop_out = run_command(
          "node " .. shell_escape(plugin_dir .. "/scripts/crop-image.js") ..
          " " .. shell_escape(design_source)
        ) or ""
        local crop_json
        for line in crop_out:gmatch("[^\n]+") do
          if line:match("^{") then crop_json = line end
        end
        if crop_json and crop_json:match('"success"%s*:%s*true') then
          design_b64 = crop_json:match('"data"%s*:%s*"([^"]*)"')
        else
          -- Fallback to pure-Lua read + encode
          local raw = claudio.fs.read(design_source)
          if raw then design_b64 = base64_encode(raw) end
        end
      end

      -- 3. Compare via LLM (need both images)
      if not live_b64 or not design_b64 then
        results[#results + 1] = {
          name   = screen_name,
          score  = 0,
          issues = { "Could not obtain one or both images for comparison" },
          skipped = true,
        }
      else
        local ok, result = pcall(claudio.llm.complete, {
          model      = model,
          max_tokens = 1024,
          messages   = {
            { role = "user", content = {
              { type = "text",  text = FIDELITY_PROMPT },
              { type = "image", source = "base64", media_type = "image/png", data = design_b64 },
              { type = "image", source = "base64", media_type = "image/png", data = live_b64  },
            }},
          },
        })

        local screen_result = { name = screen_name }
        if ok and result then
          local response_text = (result.text) or ""
          local analysis = extract_json(response_text)
          if analysis then
            screen_result.analysis = analysis
            local score = analysis:match('"score"%s*:%s*(%d+)')
            screen_result.score = tonumber(score) or 0
          else
            screen_result.score = 0
            screen_result.raw_response = response_text:sub(1, 300)
          end
        else
          screen_result.score = 0
          screen_result.error = type(result) == "string" and result or "LLM comparison failed"
        end
        total = total + (screen_result.score or 0)
        results[#results + 1] = screen_result
      end
    end

    -- Clean up temp script
    run_command("rm -f " .. shell_escape(shot_script))

    local overall = (#results > 0) and math.floor(total / #results) or 0
    return json_encode({
      success       = true,
      overall_score = overall,
      model_used    = model,
      screens       = results,
    })
  end,
})

------------------------------------------------------------------------
-- 18. Export Tools (preserved from original plugin)
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

    local json_line
    for line in render_output:gmatch("[^\n]+") do
      if line:match("^{") then json_line = line end
    end

    if not json_line then
      return '{"success": false, "error": "No JSON output from render-video.js"}'
    end

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
            if line:match("^{") then music_json = line end
          end
          if music_json then return music_json end
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
      if line:match("^{") then json_line = line end
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

    local slides_dir = html_file
    if claudio.fs.exists(html_file) then
      local stat = claudio.fs.stat(html_file)
      if stat and stat.type == "file" then
        slides_dir = html_file:match("(.*/)")
        if not slides_dir then slides_dir = "." end
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
      if line:match("^{") then json_line = line end
    end

    return json_line or '{"success": false, "error": "No JSON output from PDF export"}'
  end,
})

------------------------------------------------------------------------
-- 19. Hook: Copy plugin components into new design sessions
------------------------------------------------------------------------
claudio.hooks.register("PostToolUse", "CreateDesignSession", function(ctx)
  local session_dir = ctx and ctx.output and ctx.output:match('"session_dir"%s*:%s*"([^"]*)"')
  if not session_dir then return end

  local components_dir = plugin_dir .. "/components"
  local target_dir     = session_dir .. "/components"

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
      io.popen("cp " .. shell_escape(src) .. " " .. shell_escape(target_dir .. "/" .. file)):close()
    end
  end
end)

------------------------------------------------------------------------
-- Module table — returned when loaded via require("claudio-design")
------------------------------------------------------------------------
local M = {}

--- Configure the claudio-design plugin.
--- Call this from your config callback inside claudio.plugin.use().
---
--- @param opts table|nil  Optional configuration keys:
---   critic_model   string  Vision model for VerifyMockup scoring.
---                          Default: claude-haiku-4-5-20251001
---   fidelity_model string  Vision model for ReviewDesignFidelity.
---                          Default: claude-haiku-4-5-20251001
function M.setup(opts)
  for k, v in pairs(opts or {}) do
    _config[k] = v
  end
end

return M
