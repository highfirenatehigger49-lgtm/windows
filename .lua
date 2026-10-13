--!native

-- ============================================================================
--  FILE MAP (in execution order; search the section banner to jump to it)
-- ============================================================================
--  [01] STARTUP ............. Library, loading screen, services, shared helpers
--  [02] UI FOUNDATION ....... Window, tabs, theme, and config save manager
--  [03] HOME TAB ............ Profile, community, information, and session
--  [04] MAIN & COMBAT ....... Head hit, auto jump, hitbox, and accuracy helpers
--  [05] ESP ................. Zombie/player ESP and billboard update loops
--  [06] PERFORMANCE ......... Performance controls and FPS helpers
--  [07] KILL AURA ........... Targeting, attacks, effects, and range visualizer
--  [08] LOCAL PLAYER ........ Movement controls (fly, noclip, and related tools)
--  [09] CLASSES ............. Musician, Medic, and Sapper features
--  [10] SHOVE AURA .......... Shared configuration, coordination, and hitbox logic
--  [11] CHAPLAIN ............ Blessing features
--  [12] MISC & GUN FEATURES . Keybinds, target visuals, silent aim, gun modifiers
--
--  MAINTENANCE NOTES
--  * This file is evaluated from top to bottom. Keep definitions before use.
--  * Tab creation order and feature setup are intentionally left unchanged.
--  * Shared state includes Tabs, Options, Toggles, and _G aliases. Do not rename
--    identifiers without checking every reader/writer and external integration.
--  * This cleanup is documentation-only; runtime statements are not refactored.
-- ============================================================================

-- ===== LOAD OBSIDIAN LIBRARY =====
local repo = "https://raw.githubusercontent.com/highfirenatehigger49-lgtm/Assets/refs/heads/main/"
-- W repo layout: Library.lua + tees (ThemeManager) + savemanager (SaveManager).
local function loadWSrc(path)
    local src = game:HttpGet(repo .. path)
    -- NOTE: no GroupTransparency stripping here. The CanvasGroup conversion
    -- below makes upstream's intended slide+fade valid; stripping the fade
    -- is what left the old tab lingering opaquely over the new one.
    if path == "Library.lua" then
        local function patchOnce(plainFrom, toText)
            local pat = string.gsub(plainFrom, "(%W)", "%%%1")
            local out, n = string.gsub(src, pat, toText)
            if n == 1 then src = out end
            return n
        end
        -- Upstream animates tab GroupTransparency but creates the container
        -- as Frame (no such member). Make it a CanvasGroup so the intended
        -- slide+fade works instead of stripping the fade (which caused the
        -- old tab to linger opaquely over the new one).
        patchOnce(
            '            TabContainer = New("Frame", {\n'
                .. '                BackgroundTransparency = 1,',
            '            TabContainer = New("CanvasGroup", {\n'
                .. '                BackgroundTransparency = 1,'
        )
        -- Softer tab exit: upstream outro accelerates inward (Quint In),
        -- which reads as a janky drop. Ease it out like the entrance.
        patchOnce(
            "Enum.EasingStyle.Quint, Enum.EasingDirection.In",
            "Enum.EasingStyle.Cubic, Enum.EasingDirection.Out"
        )
        -- Header layout: logo docked left, title truly centered.
        patchOnce(
            '            Size = UDim2.new(0, InitialLeftWidth, 1, 0),\n'
                .. '            Parent = TopBar,\n'
                .. '        })\n'
                .. '        New("UIListLayout", {\n'
                .. '            FillDirection = Enum.FillDirection.Horizontal,\n'
                .. '            HorizontalAlignment = Enum.HorizontalAlignment.Center,\n'
                .. '            VerticalAlignment = Enum.VerticalAlignment.Center,\n'
                .. '            Padding = UDim.new(0, 6),\n'
                .. '            Parent = TitleHolder,\n'
                .. '        })',
            '            Size = UDim2.new(0, InitialLeftWidth, 1, 0),\n'
                .. '            Parent = TopBar,\n'
                .. '        })'
        )
        patchOnce(
            '            WindowIcon = New("ImageLabel", {\n'
                .. '                Size = WindowInfo.IconSize,\n'
                .. '                Parent = TitleHolder,\n'
                .. '            })',
            '            WindowIcon = New("ImageLabel", {\n'
                .. '                AnchorPoint = Vector2.new(0, 0.5),\n'
                .. '                Position = UDim2.new(0, 6, 0.5, 0),\n'
                .. '                Size = WindowInfo.IconSize,\n'
                .. '                Parent = TitleHolder,\n'
                .. '            })'
        )
        patchOnce(
            '        WindowTitle = New("TextLabel", {\n'
                .. '            BackgroundTransparency = 1,\n'
                .. '            Size = UDim2.new(0, X, 1, 0),\n'
                .. '            Text = WindowInfo.Title,\n'
                .. '            TextSize = 20,\n'
                .. '            Parent = TitleHolder,\n'
                .. '        })',
            '        WindowTitle = New("TextLabel", {\n'
                .. '            BackgroundTransparency = 1,\n'
                .. '            Size = UDim2.new(1, 0, 1, 0),\n'
                .. '            Text = WindowInfo.Title,\n'
                .. '            TextSize = 20,\n'
                .. '            TextXAlignment = Enum.TextXAlignment.Center,\n'
                .. '            Parent = TitleHolder,\n'
                .. '        })'
        )
        local boxFrom = '        local Checkbox = New("Frame", {\n'
            .. '            BackgroundColor3 = "MainColor",\n'
            .. '            Size = UDim2.fromScale(1, 1),\n'
            .. '            SizeConstraint = Enum.SizeConstraint.RelativeYY,\n'
            .. '            Parent = Button,\n'
            .. '        })'
        local boxTo = '        local Checkbox = New("Frame", {\n'
            .. '            AnchorPoint = Vector2.new(0, 0.5),\n'
            .. '            BackgroundColor3 = "MainColor",\n'
            .. '            Position = UDim2.fromScale(0, 0.5),\n'
            .. '            Size = UDim2.fromOffset(18, 18),\n'
            .. '            Parent = Button,\n'
            .. '        })'
        local boxPat = string.gsub(boxFrom, "(%W)", "%%%1")
        local patched, boxCount = string.gsub(src, boxPat, boxTo)
        if boxCount == 1 then
            src = patched
        end
        -- else: pattern drifted upstream: don't half-apply, keep remote
        -- as-is. (Checkbox will render large; update the pattern.)

        -- Arrey checkbox look: accent-filled box + white check that pops in
        -- with a scale punch, glowing accent stroke, brighter title/desc.
        -- (patchOnce defined above; kept atomic with the Display patch below.)
        -- Atomic: the Display patch references CheckScale, so only apply it
        -- when the UIScale creation patch landed too. Otherwise a half-patch
        -- breaks every toggle (nil CheckScale).
        local nScale = patchOnce(
            '        if CheckIcon then\n'
                .. '            Library:ApplyLucideIcon(CheckImage, CheckIcon)\n'
                .. '        end\n'
                .. '\n'
                .. '        local ToggleDescLabel = nil',
            '        if CheckIcon then\n'
                .. '            Library:ApplyLucideIcon(CheckImage, CheckIcon)\n'
                .. '        end\n'
                .. '\n'
                .. '        local CheckScale = New("UIScale", {\n'
                .. '            Scale = 1,\n'
                .. '            Parent = CheckImage,\n'
                .. '        })\n'
                .. '\n'
                .. '        local ToggleDescLabel = nil'
        )
        if nScale == 1 then
        patchOnce(
            '            TweenService:Create(CheckImage, Library.TweenInfo, {\n'
                .. '                ImageTransparency = Toggle.Value and 0 or 1,\n'
                .. '            }):Play()\n'
                .. '\n'
                .. '            Checkbox.BackgroundColor3 = Library.Scheme.MainColor\n'
                .. '            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"\n'
                .. '\n'
                .. '            if ToggleDescLabel then\n'
                .. '                ToggleDescLabel.TextTransparency = 0.6\n'
                .. '            end',
            '            if Toggle.Value then\n'
                .. '                Library.Registry[Checkbox].BackgroundColor3 = "AccentColor"\n'
                .. '                TweenService:Create(Checkbox, Library.TweenInfo, {\n'
                .. '                    BackgroundColor3 = Library.Scheme.AccentColor,\n'
                .. '                }):Play()\n'
                .. '                Checkbox.BackgroundColor3 = Library.Scheme.AccentColor\n'
                .. '                TweenService:Create(CheckboxStroke, Library.TweenInfo, {\n'
                .. '                    Color = Library.Scheme.AccentColor,\n'
                .. '                }):Play()\n'
                .. '                CheckboxStroke.Color = Library.Scheme.AccentColor\n'
                .. '                CheckImage.ImageColor3 = Color3.fromRGB(255, 255, 255)\n'
                .. '                CheckImage.Rotation = -14\n'
                .. '                CheckScale.Scale = 1.6\n'
                .. '                TweenService:Create(CheckImage, Library.TweenInfo, {\n'
                .. '                    ImageTransparency = 0,\n'
                .. '                    Rotation = 0,\n'
                .. '                }):Play()\n'
                .. '                TweenService:Create(CheckScale, Library.TweenInfo, {\n'
                .. '                    Scale = 1,\n'
                .. '                }):Play()\n'
                .. '            else\n'
                .. '                Library.Registry[Checkbox].BackgroundColor3 = "MainColor"\n'
                .. '                TweenService:Create(Checkbox, Library.TweenInfo, {\n'
                .. '                    BackgroundColor3 = Library.Scheme.MainColor,\n'
                .. '                }):Play()\n'
                .. '                Checkbox.BackgroundColor3 = Library.Scheme.MainColor\n'
                .. '                TweenService:Create(CheckboxStroke, Library.TweenInfo, {\n'
                .. '                    Color = Library.Scheme.OutlineColor,\n'
                .. '                }):Play()\n'
                .. '                CheckboxStroke.Color = Library.Scheme.OutlineColor\n'
                .. '                CheckImage.ImageColor3 = Library.Scheme.FontColor\n'
                .. '                CheckImage.Rotation = 0\n'
                .. '                CheckScale.Scale = 1\n'
                .. '                TweenService:Create(CheckImage, Library.TweenInfo, {\n'
                .. '                    ImageTransparency = 1,\n'
                .. '                }):Play()\n'
                .. '            end\n'
                .. '\n'
                .. '            if ToggleDescLabel then\n'
                .. '                TweenService:Create(ToggleDescLabel, Library.TweenInfo, {\n'
                .. '                    TextTransparency = Toggle.Value and 0.35 or 0.6,\n'
                .. '                }):Play()\n'
                .. '            end'
        )
        end
    end
    return src
end
local Library = loadstring(loadWSrc("Library.lua"))()
Library.ForceCheckbox = true -- Arrey style: toggles render as checkboxes
local ThemeManager = loadstring(game:HttpGet(repo .. "tees"))()

local SaveManager
pcall(function()
    SaveManager = loadstring(game:HttpGet(repo .. "savemanager"))()
end)
if not SaveManager then
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/addons/SaveManager.lua"))()
end

local Options = Library.Options
local Toggles = Library.Toggles

-- ===== LOADING SCREEN (Obsidian built-in, shown while the hub builds) =====
local ArreyLoading = nil
pcall(function()
    ArreyLoading = Library:CreateLoading({
        Title = "Arrey Hub",
        TotalSteps = 4,
    })
    ArreyLoading:SetMessage("Loading interface...")
    ArreyLoading:SetDescription("Guts & BlackPowder")
    ArreyLoading:SetCurrentStep(1)
end)
task.wait(0.05)

local function ArreyLoadStep(step, message)
    pcall(function()
        if ArreyLoading then
            ArreyLoading:SetMessage(message)
            ArreyLoading:SetCurrentStep(step)
        end
    end)
    task.wait(0.05)
end

-- ===== SERVICES =====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local _tableUnpack = table.unpack or unpack

local tick_ = os.clock -- monotonic client clock for intervals/cooldowns (WepHitID still uses tick())
local mathFloor = math.floor
local mathCeil = math.ceil
local mathAbs = math.abs
local mathMin = math.min
local mathMax = math.max
local mathHuge = math.huge
local mathSqrt = math.sqrt
local mathRad = math.rad
local mathClamp = math.clamp
local v3new = Vector3.new
local v2new = Vector2.new
local c3rgb = Color3.fromRGB
local cfNew = CFrame.new
local strFormat = string.format

-- Emptiness check via generalized iteration (no pairs/ipairs/next)
local function tableHasEntries(t)
    for _ in t do return true end
    return false
end

-- ================= SHARED REFACTOR HELPERS =================
-- Unified gun check (merges KillAura_isGun Ammo/ShotsLoaded logic + isGun Animations/Aim logic).
local function isGunTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool:FindFirstChild("Ammo") or tool:FindFirstChild("ShotsLoaded") then return true end
    if tool:FindFirstChild("GunSettings") then return true end
    local cfg = tool:FindFirstChild("Configuration")
    if cfg and (cfg:FindFirstChild("Ammo") or cfg:FindFirstChild("ShotsLoaded")) then return true end
    local animFolder = tool:FindFirstChild("Animations")
    if animFolder and (animFolder:FindFirstChild("Aim") or animFolder:FindFirstChild("Aiming")) then
        return true
    end
    return false
end

-- Unified tool remote lookup with weak cache. Canonical order:
-- Tool.RemoteEvent -> Workspace.Players/<name>/<tool>/RemoteEvent.
local _toolRemoteCache = setmetatable({}, { __mode = "k" })
local function getToolRemote(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local cached = _toolRemoteCache[tool]
    if cached and cached.Parent then return cached end
    local remote = tool:FindFirstChild("RemoteEvent")
    if remote and remote:IsA("RemoteEvent") then
        _toolRemoteCache[tool] = remote
        return remote
    end
    local wsPlayers = Workspace:FindFirstChild("Players")
    local folder = wsPlayers and LocalPlayer and wsPlayers:FindFirstChild(LocalPlayer.Name)
    local toolFolder = folder and folder:FindFirstChild(tool.Name)
    local fallback = toolFolder and toolFolder:FindFirstChild("RemoteEvent")
    if fallback and fallback:IsA("RemoteEvent") then
        _toolRemoteCache[tool] = fallback
        return fallback
    end
    return nil
end

-- Unified zombie query over the central cache. Filter receives (model) -> true/false.
-- Returns closest-first up to maxN (default all) within range of pos.
local function queryZombies(pos, range, filter, maxN)
    local cache = _G.CentralZombieCache
    local count = _G.CentralZombieCount or #cache
    local out, outN = {}, 0
    if not pos or not range then return out, 0 end
    local rangeSq = range * range
    for i = 1, count do
        local model = cache[i]
        if model and model.Parent and model:IsA("Model") then
            if not filter or filter(model) then
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
                if root and root:IsA("BasePart") then
                    local p = root.Position
                    local dx, dy, dz = p.X - pos.X, p.Y - pos.Y, p.Z - pos.Z
                    local d2 = dx * dx + dy * dy + dz * dz
                    if d2 <= rangeSq then
                        outN = outN + 1
                        out[outN] = { model = model, root = root, d2 = d2 }
                        if maxN and outN >= maxN then break end
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.d2 < b.d2 end)
    return out, outN
end

-- Shared ESP factories (single stealth-name + transparency defaults).
local function makeHighlight(adornee, color, fillTrans, outlineTrans)
    local h = Instance.new("Highlight")
    h.Name = (_G.getRandomStealthName and _G.getRandomStealthName()) or ("HL_" .. math.random(10000, 99999))
    h.Adornee = adornee
    h.FillColor = color or c3rgb(255, 0, 0)
    h.OutlineColor = color or c3rgb(255, 0, 0)
    h.FillTransparency = fillTrans or 0.5
    h.OutlineTransparency = outlineTrans or 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return h
end

local function makeBillboard(adornee, text, textColor, studsOffset)
    local bb = Instance.new("BillboardGui")
    bb.Name = (_G.getRandomStealthName and _G.getRandomStealthName()) or ("BB_" .. math.random(10000, 99999))
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset = studsOffset or v3new(0, 3, 0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.Text = text or ""
    lbl.TextColor3 = textColor or c3rgb(255, 255, 255)
    lbl.Parent = bb
    return bb, lbl
end

-- Single FOV circle manager (replaces 3x ensure/update FOV clones).
local FovCircles = {}
local function getFovCircle(key, color)
    local entry = FovCircles[key]
    if entry and entry.gui and entry.gui.Parent then return entry end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    if _G.protectGUI then _G.protectGUI(gui) else gui.Parent = playerGui end
    local frame = Instance.new("Frame")
    frame.AnchorPoint = v2new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = gui
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or c3rgb(255, 0, 0)
    stroke.Thickness = 1.5
    stroke.Parent = frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    entry = { gui = gui, frame = frame }
    FovCircles[key] = entry
    return entry
end

local function getFovScreenCenterShared(mobileFlag)
    local cam = Workspace.CurrentCamera
    if not cam then return v2new(0, 0) end
    local viewportSize = cam.ViewportSize
    if mobileFlag or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return v2new(viewportSize.X / 2, viewportSize.Y / 2)
    end
    local mousePos = UserInputService:GetMouseLocation()
    local ok, inset = pcall(function() return game:GetService("GuiService"):GetGuiInset() end)
    if not ok or not inset then return mousePos end
    return mousePos - v2new(inset.X, inset.Y)
end

-- ================= CENTRAL ZOMBIE SCANNER =================
_G.CentralZombieCache = {}
_G.CentralZombieCount = 0

local function initCentralZombieCache()
    local cache = _G.CentralZombieCache
    local count = 0
    local cacheIndex = {}
    table.clear(cache)

    local function addToCache(z)
        if not z:IsA("Model") then return end
        count = count + 1
        cache[count] = z
        cacheIndex[z] = count
        _G.CentralZombieCount = count

        task.defer(function()
            if not z or not z.Parent then return end
            pcall(function() _G.GetZombieTypeFromModel(z) end)
            pcall(function() _G.getCachedZombieParts(z) end)
        end)
    end

    local function removeFromCache(z)
        local i = cacheIndex[z]
        if not i then return end
        local last = cache[count]
        cache[i] = last
        if last then cacheIndex[last] = i end
        cache[count] = nil
        cacheIndex[z] = nil
        count = count - 1
        _G.CentralZombieCount = count

        if _G.ZombieTypeCache then _G.ZombieTypeCache[z] = nil end
        if _G.ZombiePartCache then _G.ZombiePartCache[z] = nil end
        if _G.ESPPendingRemoval then _G.ESPPendingRemoval[z] = nil end
        if _G.IdentifiedIgniters then _G.IdentifiedIgniters[z] = nil end
        if _G._limiterHiddenSet then _G._limiterHiddenSet[z] = nil end
        if _G.PartVelocityCache then _G.PartVelocityCache[z] = nil end
    end

    local folderConns = {}
    local function watchFolder(folder)
        if not folder then return end
        for _, z in folder:GetChildren() do addToCache(z) end
        table.insert(folderConns, folder.ChildAdded:Connect(addToCache))
        table.insert(folderConns, folder.ChildRemoved:Connect(removeFromCache))
    end

    local function setupWatchers()
        for _, c in folderConns do c:Disconnect() end
        table.clear(folderConns)
        count = 0
        table.clear(cache)
        _G.CentralZombieCount = 0

        local zFolder = Workspace:FindFirstChild("Zombies")
        if zFolder then
            watchFolder(zFolder:FindFirstChild("Agent"))
            watchFolder(zFolder:FindFirstChild("Slim"))

            table.insert(folderConns, zFolder.ChildAdded:Connect(function(child)
                if child.Name == "Agent" or child.Name == "Slim" then
                    task.defer(watchFolder, child)
                end
            end))
        end
        watchFolder(Workspace:FindFirstChild("Camera"))
    end

    Workspace.ChildAdded:Connect(function(child)
        -- FIX: also re-arm when the Camera (visual zombies) folder appears.
        if child.Name == "Zombies" or child.Name == "Camera" then
            task.defer(setupWatchers)
        end
    end)
    setupWatchers()
end
initCentralZombieCache()
-- ===== WINDOW CREATION =====
local Arrey_LOGO_URLS = {
    "https://github.com/highfirenatehigger49-lgtm/Assets/blob/main/71oY4SnbixL.webp?raw=true",
}

local Arrey_LOGO_VERSION = 2
local function resolveArreyLogo()
    local localAsset = (getcustomasset or getsynasset)
    if writefile and localAsset then
        local logoPath = "ArreyHub/logo_v" .. tostring(Arrey_LOGO_VERSION) .. ".png"
        local logoSrcPath = "ArreyHub/logo_v" .. tostring(Arrey_LOGO_VERSION) .. ".src"
        if makefolder and (not isfolder or not isfolder("ArreyHub")) then
            pcall(function() makefolder("ArreyHub") end)
        end
        -- Bust stale caches: if the saved source URL differs from the
        -- current one, the cached logo is from an older build. Delete it.
        -- Versioned filename also defeats asset caching on rewrites.
        local wantedSrc = Arrey_LOGO_URLS[1]
        local savedSrc = nil
        if isfile and isfile(logoSrcPath) and type(readfile) == "function" then
            pcall(function() savedSrc = readfile(logoSrcPath) end)
        end
        if savedSrc ~= wantedSrc then
            pcall(function()
                if isfile and isfile(logoPath) and type(delfile) == "function" then
                    delfile(logoPath)
                elseif isfile and isfile(logoPath) then
                    writefile(logoPath, "")
                end
            end)
        end
        -- Clean legacy unversioned cache from older builds.
        pcall(function()
            if isfile and isfile("ArreyHub/logo.png") and type(delfile) == "function" then
                delfile("ArreyHub/logo.png")
            end
            if isfile and isfile("ArreyHub/logo.src") and type(delfile) == "function" then
                delfile("ArreyHub/logo.src")
            end
        end)
        if isfile and isfile(logoPath) then
            local ok, asset = pcall(localAsset, logoPath)
            if ok and asset then return asset end
        end

        for _, url in Arrey_LOGO_URLS do
            local ok, body = pcall(function() return game:HttpGet(url) end)
            if ok and body and #body > 0 then
                pcall(function() writefile(logoPath, body) end)
                pcall(function() writefile(logoSrcPath, url) end)
                local assetOk, asset = pcall(localAsset, logoPath)
                if assetOk and asset then return asset end
            end
        end
    end

    return Arrey_LOGO_URLS[1]
end

local Arrey_LOGO_URL = resolveArreyLogo()

-- Streamer Mode
streamerModeEnabled = _G.StreamerMode == true

-- Single-instance guard: re-executing the script destroys the old
-- window first instead of stacking duplicate UIs.
pcall(function()
    local function killHubGuis(root)
        if not root then return end
        for _, g in ipairs(root:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name == "Obsidian" then
                local isHub = false
                pcall(function()
                    for _, d in ipairs(g:GetDescendants()) do
                        if (d:IsA("TextLabel") or d:IsA("TextButton")) and string.find(d.Text or "", "Arrey Hub", 1, true) then
                            isHub = true
                            break
                        end
                    end
                end)
                if isHub then pcall(function() g:Destroy() end) end
            end
        end
    end
    killHubGuis(game:GetService("CoreGui"):FindFirstChild("RobloxGui"))
    if typeof(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then killHubGuis(h) end
    end
    local lp = game.Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if pg then killHubGuis(pg) end
end)

-- Previous-execution teardown: every toggle object from the last run is a
-- handle into that run's loops (they gate on the toggle state), so switch
-- them all off. Otherwise old features keep running headless behind the
-- new UI. Notifications are muted during the sweep.
pcall(function()
    if type(_G.ArreyAutoSaveStop) == "function" then _G.ArreyAutoSaveStop() end
end)
pcall(function()
    local el = _G.ArreyToggleElements
    if type(el) ~= "table" then return end    local origNotify
    if Library and type(Library.Notify) == "function" then
        origNotify = Library.Notify
        Library.Notify = function() end
    end
    pcall(function()
        for _, widget in pairs(el) do
            pcall(function()
                if type(widget) == "table" and type(widget.SetValue) == "function" then
                    widget:SetValue(false)
                end
            end)
        end
    end)
    if Library and type(origNotify) == "function" then
        Library.Notify = origNotify
    end
end)

local Window = Library:CreateWindow({
    Title = "Arrey Hub",
    Footer = "by Arrey | Guts & BlackPowder",
    Icon = Arrey_LOGO_URL,
    IconSize = UDim2.fromOffset(44, 44),
    Size = UDim2.fromOffset(920, 640),
    NotifySide = "Right",
    ShowCustomCursor = true,
    CornerRadius = 6,
    ToggleKeybind = Enum.KeyCode.RightShift,
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },
    TabTransitionTime = 0.3,
    TabSwipeOffset = 16,
    TabSwipeFrom = "Auto",
    TabButtonsStyle = {
        Gap = 6,
        Padding = 6,
        CornerRadius = 6,
        Indicator = true,
        IndicatorWidth = 2,
        IndicatorHeight = 20,
    },
})

-- ===== TABS =====
local Tabs = {
    Home         = Window:AddTab("Home", "house"),
    Main         = Window:AddTab("Main & Combat", "sword"),
    ESP          = Window:AddTab("Other & ESP", "eye"),
    Events       = Window:AddTab("Events", "sparkles"),
    Protection   = Window:AddTab("Protection", "shield"),
    Anims        = Window:AddTab("Animation Pack", "film"),
    Automation   = Window:AddTab("Automation", "zap"),
    PVP          = Window:AddTab("PVP", "swords"),
    Classes      = Window:AddTab("Class Features", "users"),
    LocalPlayer  = Window:AddTab("Local Player", "user"),
    Misc         = Window:AddTab("Misc", "layout-grid"),
    Settings     = Window:AddTab("Settings", "settings"),
}

-- ===== TABBOXES (sub-tabs above groupboxes) =====
-- NOTE: stored as Tabs.* fields (not locals) — the main chunk is near the
-- 200-register limit, so no new top-level locals may be added here.
Tabs._AuraBox = Tabs.Main:AddRightTabbox()
Tabs.AuraTarget = Tabs._AuraBox:AddTab("Target")
Tabs.AuraAttack = Tabs._AuraBox:AddTab("Attack")
Tabs.AuraEffects = Tabs._AuraBox:AddTab("Effects")

Tabs._ESPBox = Tabs.ESP:AddRightTabbox()
Tabs.ZombieESP = Tabs._ESPBox:AddTab("Zombie ESP")
Tabs.PlayerESP = Tabs._ESPBox:AddTab("Player ESP")

-- Events tab groupboxes (alternating sides). Stored on Tabs (register limit).
Tabs.EventsDracula = Tabs.Events:AddGroupbox({ Side = "Left", Name = "Dracula", Description = "Dracula boss features", IconName = "ghost", PopOut = false })
Tabs.EventsHeadless = Tabs.Events:AddGroupbox({ Side = "Right", Name = "Headless Horseman", Description = "Headless Horseman features", IconName = "skull", PopOut = false })

ArreyLoadStep(2, "Building tabs...")

-- Theme Manager setup
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("ArreyHub/GutsBlackPowder")

-- Default UI: built-in Monokai + Gotham font (must run before ApplyToTab).
ThemeManager:SetDefaultTheme({
    FontFace = "Gotham",
    FontColor = "f8f8f2",
    MainColor = "272822",
    AccentColor = "f92672",
    BackgroundColor = "1e1f1c",
    OutlineColor = "49483e",
})

local ThemeTab = Tabs.Settings
ThemeManager:ApplyToTab(ThemeTab)

-- Persist Monokai as the default theme and sync the font dropdown.
-- Only migrates users still on Arrey / built-in "Default" (or with no saved
-- default); custom picks are respected. No theme download involved.
pcall(function()
    local cur = ThemeManager:GetDefaultTheme()
    if cur == nil or cur == "none" or cur == "Default" or cur == "Arrey" then
        ThemeManager:SaveDefault("Monokai")
    end
end)
pcall(function()
    local fontFaceOption = ThemeManager.Library.Options.FontFace
    if fontFaceOption and fontFaceOption.SetValue then
        fontFaceOption:SetValue("Gotham")
    end
end)
ThemeManager:LoadDefault()

-- Save Manager setup
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("ArreyHub/GutsBlackPowder")
SaveManager:BuildConfigSection(ThemeTab)
-- Suppress notification spam while loading configs (restored elements fire many toggles)
do
    local origSM_LoadJSON = SaveManager.LoadJSON
    SaveManager.LoadJSON = function(self, content)
        _G.ArreySilentConfigLoad = true
        local results = { origSM_LoadJSON(self, content) }
        task.defer(function()
            task.wait(0.75)
            _G.ArreySilentConfigLoad = false

            pcall(function()
                local EspSelectToggle = Toggles and Toggles.EspSelect
                if EspSelectToggle and EspSelectToggle.Value == true then
                    EspSelectToggle:RunChanged()
                end
            end)

            pcall(function()
                if not _G.ArreySuppressConfigNotify then
                    Library:Notify({
                        Title = "Configuration",
                        Description = results[1] == true and "Config loaded" or (results[2] or "Failed to load config"),
                        Time = 2,
                        Icon = results[1] == true and "check" or "alert-circle",
                    })
                end
            end)
        end)
        return table.unpack(results)
    end
end

-- ===== AUTO SAVE CONFIGS (toggle) =====
-- Silently saves the config whenever a setting changes. Saving stays
-- blocked until the hub is fully built and the autoload config applied
-- (else a restored-ON toggle would snapshot half-built state).
_G.ArreyAutoSaveArmed = false -- saving blocked until hub is built + config applied
_G.ArreyGunUIReady = false    -- set true by the deferred gun UI when finished

local autoSaveConfigsEnabled = false
local autoSaveConfigsThread = nil
local AUTO_SAVE_POLL = 1.5
local AUTO_SAVE_MIN_GAP = 2

local function autoSaveConfigsNow()
    if not SaveManager then return false, "no SaveManager" end
    local targetUsed, saved, errText
    local ok = pcall(function()
        targetUsed = SaveManager:GetAutoloadConfig()
        if type(targetUsed) ~= "string" or targetUsed == "none" or targetUsed == "" then
            targetUsed = "autosave"
        end
        saved, errText = SaveManager:Save(targetUsed)
        if saved then
            pcall(function() SaveManager:SaveAutoloadConfig(targetUsed) end)
        end
    end)
    if not ok then return false, "exception" end
    return saved == true, errText
end

local AutoSaveStatusLabel = nil
local function autoSaveStatus(text)
    pcall(function()
        if AutoSaveStatusLabel and AutoSaveStatusLabel.SetText then
            AutoSaveStatusLabel:SetText(text)
        end
    end)
end

local function autoSaveConfigsSignature()
    local parts = {}
    pcall(function()
        for idx, t in pairs(Library.Toggles) do
            local v = t.Value
            if type(v) == "table" then
                local ks = {}
                for k in pairs(v) do ks[#ks + 1] = tostring(k) end
                table.sort(ks)
                v = "{" .. table.concat(ks, ",") .. "}"
            end
            parts[#parts + 1] = tostring(idx) .. "=" .. tostring(v)
        end
        for idx, o in pairs(Library.Options) do
            local v = o.Value
            if type(v) == "table" then
                local ks = {}
                for k in pairs(v) do ks[#ks + 1] = tostring(k) end
                table.sort(ks)
                v = "{" .. table.concat(ks, ",") .. "}"
            end
            parts[#parts + 1] = tostring(idx) .. "=" .. tostring(v)
        end
    end)
    table.sort(parts)
    return table.concat(parts, ";")
end

local AutoSaveSection = ThemeTab:AddGroupbox({ Side = "Left", Name = "Auto Save", Description = "Automatic config saving", IconName = "save", PopOut = false })
AutoSaveStatusLabel = AutoSaveSection:AddLabel("Auto save: idle", true)
local AutoSaveConfigsToggle = AutoSaveSection:AddToggle('AutoSaveConfigs', {
    Text = "Auto Save Configs",
    Flag = "AutoSaveConfigs",
    Description = "Silently saves your config whenever you change a setting.",
    Default = false,
    Callback = function(state)
        autoSaveConfigsEnabled = state
        if autoSaveConfigsThread then
            pcall(function() task.cancel(autoSaveConfigsThread) end)
            autoSaveConfigsThread = nil
        end
        if not state then return end

        -- Only save + notify immediately when the user flips it by hand.
        if _G.ArreyAutoSaveArmed and not _G.ArreySilentConfigLoad then
            local okSave, errSave = autoSaveConfigsNow()
            autoSaveStatus((okSave and "Last saved: " or "Save FAILED: ") .. (okSave and os.date("%H:%M:%S") or tostring(errSave)))
            Library:Notify({
                Title = "Auto Save",
                Description = "Enabled - config saves on every change.",
                Time = 3,
                Icon = "save"
            })
        end

        autoSaveConfigsThread = task.spawn(function()
            local lastSig = autoSaveConfigsSignature()
            local lastSave = os.clock()
            while autoSaveConfigsEnabled do
                task.wait(AUTO_SAVE_POLL)
                if not autoSaveConfigsEnabled then break end
                if _G.ArreySilentConfigLoad or not _G.ArreyAutoSaveArmed then
                    -- still building / loading: only re-baseline, never save
                    lastSig = autoSaveConfigsSignature()
                    lastSave = os.clock()
                else
                    local sig = autoSaveConfigsSignature()
                    if sig ~= lastSig and os.clock() - lastSave >= AUTO_SAVE_MIN_GAP then
                        lastSig = sig
                        lastSave = os.clock()
                        local okSave, errSave = autoSaveConfigsNow()
                        autoSaveStatus((okSave and "Last saved: " or "Save FAILED: ") .. (okSave and os.date("%H:%M:%S") or tostring(errSave)))
                    end
                end
            end
        end)
    end
})
_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.AutoSaveConfigs = AutoSaveConfigsToggle
_G.ArreyAutoSaveStop = function()
    autoSaveConfigsEnabled = false
    if autoSaveConfigsThread then
        pcall(function() task.cancel(autoSaveConfigsThread) end)
        autoSaveConfigsThread = nil
    end
end

-- early autoload, popup muted
do
    local _n = Library.Notify
    Library.Notify = function() end
    pcall(function() SaveManager:LoadAutoloadConfig() end)
    Library.Notify = _n
end

Library:Notify({
    Title = "Please Wait While Arrey Hub Loads",
    Description = "Usually takes 10-15 seconds",
    Time = 5,
    Icon = "zap",
})

do -- // Home Tab (scoped: main chunk is near the 200-register limit)
-- ===== HOME TAB (Profile + Community + Information + Session) =====
local DashboardTab = Tabs.Home

-- Key-system runtime vars (prompt.txt API). Set by the backend after key
-- validation; nil when keyless or running outside the key system.
local function jdVar(name)
    local v = rawget(_G, name)
    if v ~= nil then return v end
    local ok, gv = pcall(function() return getgenv()[name] end)
    if ok and gv ~= nil then return gv end
    local ok2, sv = pcall(function() return shared[name] end)
    if ok2 and sv ~= nil then return sv end
    return nil
end

local function fmtDur(sec)
    if sec == nil then return "--" end
    sec = math.max(tonumber(sec) or 0, 0)
    local h = mathFloor(sec / 3600)
    local m = mathFloor((sec % 3600) / 60)
    local s = mathFloor(sec % 60)
    if h > 0 then return strFormat("%dh %dm", h, m) end
    if m > 0 then return strFormat("%dm %ds", m, s) end
    return strFormat("%ds", s)
end

local function fmtDate(ts)
    ts = tonumber(ts)
    if not ts then return "--" end
    local ok, d = pcall(function() return os.date("%Y-%m-%d", ts) end)
    return (ok and d) or "--"
end

local function expiryText()
    local exp = tonumber(jdVar("JD_EXPIRES_AT"))
    if exp == nil then
        return (jdVar("JD_REASON") == "KEYLESS") and "Keyless session" or "Lifetime"
    end
    local left = exp - os.time()
    if left <= 0 then return "Expired" end
    return fmtDur(left) .. " left (" .. fmtDate(exp) .. ")"
end

-- Profile box: avatar image with username below, then key + discord lines.
local ProfileSection = DashboardTab:AddGroupbox({ Side = "Left", Name = "Profile", Description = "Your key profile", IconName = "user" })

local thumbUrl = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=180&h=180"
local AvatarImg = ProfileSection:AddImage("ArreyAvatar", { Image = thumbUrl, Height = 140 })

-- Prefer the linked Discord avatar when the key system provides one.
-- Retried on every refresh tick: the backend may set vars after hub load.
local discordAvatarLoaded = false
local function tryDiscordAvatar()
    if discordAvatarLoaded then return end
    local url = jdVar("JD_DISCORD_PFP")
    if type(url) ~= "string" or url == "" then return end
    local asset = nil
    pcall(function()
        local getAsset = (getcustomasset or getsynasset)
        if type(writefile) == "function" and getAsset then
            if makefolder and (not isfolder or not isfolder("ArreyHub")) then
                pcall(function() makefolder("ArreyHub") end)
            end
            local path = "ArreyHub/discord_pfp.png"
            writefile(path, game:HttpGet(url))
            asset = getAsset(path)
        end
    end)
    if asset and pcall(function() AvatarImg:SetImage(asset) end) then
        discordAvatarLoaded = true
    end
end
task.spawn(tryDiscordAvatar)

local displayName, userName = "--", "--"
pcall(function()
    displayName = tostring(LocalPlayer.DisplayName)
    userName = "@" .. tostring(LocalPlayer.Name)
end)
ProfileSection:AddLabel({ Text = displayName .. "\n" .. userName, DoesWrap = true, Size = 15 })

local function keyStatusText()
    local premium = jdVar("JD_IS_PREMIUM")
    local tier = (premium == true) and "Premium" or ((premium == false) and "Standard" or "--")
    return "Key: " .. tier
        .. "\nAuth: " .. tostring(jdVar("JD_REASON") or "--")
        .. "\nExpires: " .. expiryText()
        .. "\nCreated: " .. fmtDate(jdVar("JD_CREATED_AT"))
end
local KeyCard = ProfileSection:AddLabel({ Text = keyStatusText(), DoesWrap = true, Size = 14 })

local function discordText()
    local un = jdVar("JD_DISCORD_USERNAME")
    if un == nil then return "Discord: not linked" end
    return "Discord: " .. tostring(jdVar("JD_DISCORD_DISPLAY_NAME") or un)
        .. "\n@" .. tostring(un)
        .. "\nID: " .. tostring(jdVar("JD_DISCORD_ID") or "--")
end
local DiscordCard2 = ProfileSection:AddLabel({ Text = discordText(), DoesWrap = true, Size = 14 })

local DiscordSection = DashboardTab:AddGroupbox({ Side = "Right", Name = "Community", Description = "Community links", IconName = "users" })
local InfoSection = DashboardTab:AddGroupbox({ Side = "Right", Name = "Information", Description = "Hub information", IconName = "info" })

InfoSection:AddLabel({
    Text = "Arrey Hub V8.67\nGuts & BlackPowder Script Hub\nMade by Yuki\nExecutor: " .. tostring(identifyexecutor and identifyexecutor() or "Unknown"),
    DoesWrap = true,
    Size = 14,
})

InfoSection:AddLabel({
    Text = "Changelogs\n- Added HeadHit probability\n- Added swing speed modifier for kill aura (faster swingspeed stronger aura)\n- Added Swing Speed modifier (no ka), added brightness slider (adjust brightness and ambient.",
    DoesWrap = true,
    Size = 14,
})

-- Session box: key + script counters (macros refresh ~every 60s).
local StatsSection = DashboardTab:AddGroupbox({ Side = "Right", Name = "Session", Description = "Key and script stats", IconName = "activity" })

local function statsText()
    return "Your executions: " .. tostring(jdVar("JD_EXECUTIONS") or "--")
        .. "\nYour runtime: " .. fmtDur(jdVar("JD_USAGE"))
        .. "\nKey sessions: " .. tostring(jdVar("JD_KEY_SESSION_COUNT") or "--")
        .. "\nScript executions: " .. tostring(jdVar("JD_SCRIPT_EXECUTIONS") or "--")
        .. "\nScript runtime: " .. fmtDur(jdVar("JD_SCRIPT_USAGE"))
        .. "\nActive sessions: " .. tostring(jdVar("JD_SESSION_COUNT") or "--")
        .. "\nScript ID: " .. tostring(jdVar("JD_SCRIPT_ID") or "--")
end
local StatsCard = StatsSection:AddLabel({ Text = statsText(), DoesWrap = true, Size = 14 })

local homeStatsRunning = true
_G.ArreyHomeCleanup = function() homeStatsRunning = false end
task.spawn(function()
    while homeStatsRunning do
        task.wait(60)
        if not homeStatsRunning then break end
        pcall(function()
            StatsCard:SetText(statsText())
            KeyCard:SetText(keyStatusText())
            DiscordCard2:SetText(discordText())
            tryDiscordAvatar()
        end)
    end
end)

-- Discord constants
local discordInvite = "https://discord.gg/gbqyys5eF5"
local widgetUrl = "https://discord.com/api/guilds/1433658537027833969/widget.json"
local TOTAL_MEMBERS = 20

local DiscordCard = DiscordSection:AddLabel({
    Text = "Arrey Hub | Balls 🔥\n🟢 Loading online...\n👥 " .. TOTAL_MEMBERS .. " Members\nEst. Oct 2025",
    DoesWrap = true,
    Size = 14,
})

DiscordSection:AddButton({
    Text = "Copy Invite",
    Func = function()
        setclipboard(discordInvite)
        Library:Notify({
            Title = "Copied!",
            Description = "Discord invite link has been copied to your clipboard.",
            Time = 3,
            Icon = "copy",
        })
    end
})

-- Live online count updater
local function updateDiscordCard()
    local okRun, errRun = pcall(function()
        local online = 0

        local ok, body = pcall(function()
            return game:HttpGet(widgetUrl)
        end)

        if ok and body then
            local okDecode, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)

            if okDecode and type(data) == "table" then
                online = tonumber(data.presence_count) or 0
            end
        end

        local line1 = strFormat("🟢 %d Online    👥 %d Members", online, TOTAL_MEMBERS)
        local line2 = "Est. Oct 2025"

        DiscordCard:SetText(line1 .. "\n" .. line2)
    end)
    if not okRun then
        error(errRun, 0)
    end
end

local discordUpdateRunning = true
local discordUpdateInFlight = false
local function stopDiscordUpdates()
    discordUpdateRunning = false
end
_G.ArreyDiscordCleanup = stopDiscordUpdates

task.defer(function()
    task.wait(15)
    while discordUpdateRunning do
        if not discordUpdateInFlight then
            discordUpdateInFlight = true
            task.spawn(function()
                pcall(updateDiscordCard)
                discordUpdateInFlight = false
            end)
        end
        task.wait(900)
    end
end)

end -- // Home Tab

-- Global toggle registry for keybinds
_G.ArreyToggles = _G.ArreyToggles or {}
_G.ArreyToggleElements = _G.ArreyToggleElements or {}

do -- // Main Tab
-- ===== MAIN TAB =====

local MainTab = Tabs.Main

-- Modules (Bayonet / Melee override, safe non-blocking require)
local Modules = ReplicatedStorage:FindFirstChild("Modules") or nil

-- ===== Head Hit (Force Headshots) =====
local headshotEnabled = false
local removeBloodEnabled = false
local hookInstalled = false
local originalBayonetHitCheck = nil
local originalMeleeHitCheck = nil
local lastZombieHitTime = {}
local ZOMBIE_HIT_COOLDOWN = 0.1

local function getZombieModel(part)
    if not part then return nil end
    local model = part.Parent
    for i = 1, 5 do
        if not model then break end
        if model:IsA("Model") and (model.Name == "m_Zombie" or model:FindFirstChild("Orig")) then
            return model
        end
        model = model.Parent
    end
    return nil
end

local function getZombieHead(zombieModel)
    if not zombieModel then return nil end
    for _, part in zombieModel:GetChildren() do
        if part.Name == "Head" and (part:IsA("Part") or part:IsA("MeshPart")) then
            return part
        end
    end
    return nil
end

local function resolveHeadHit(origin, direction, raycastParams)
    local rp = (type(raycastParams) == "table" and raycastParams.ray) or raycastParams
    local rayResult = workspace:Raycast(origin, direction, rp)
    if not rayResult then return nil end
    local zombieModel = getZombieModel(rayResult.Instance)
    if not zombieModel then return nil end
    local now = tick_()
    if lastZombieHitTime[zombieModel] and now - lastZombieHitTime[zombieModel] < ZOMBIE_HIT_COOLDOWN then
        return 0
    end
    local head = getZombieHead(zombieModel)
    if not head then return nil end
    local orig = zombieModel:FindFirstChild("Orig")
    if not orig then return nil end
    local hitPos = head.Position
    if removeBloodEnabled then
        local rootPart = zombieModel:FindFirstChild("HumanoidRootPart") or zombieModel:FindFirstChild("Torso")
        if rootPart then
            hitPos = rootPart.Position + v3new(0, -9999, 0)
        end
    end
    return zombieModel, orig.Value, hitPos, rayResult, now
end

local function unifiedBayonetHitCheck(self, origin, direction, raycastParams, hitEntities)
    local zombieModel, zombieRef, hitPos, rayResult, now = resolveHeadHit(origin, direction, raycastParams)
    if zombieModel == 0 or zombieRef == 0 then return 0 end
    if zombieModel then
        -- Probability roll: only force head HitChance% of the time, otherwise
        -- fall through to the game's original (legit body) hit check.
        local chance = tonumber(HeadHitChance) or 100
        if chance < 100 and math.random(1, 100) > chance then
            if originalBayonetHitCheck then
                return originalBayonetHitCheck(self, origin, direction, raycastParams, hitEntities)
            end
            return 0
        end
        local partName = "Head"
        self.remoteEvent:FireServer("Bayonet_HitZombie", zombieRef, hitPos, true, partName, self.swingType)
        -- Replicate the game's hit-validation attributes the server checks (Flintlock:1241-1244).
        -- NOTE: game uses tick() epoch clock here; do NOT switch to os.clock().
        zombieRef:SetAttribute("WepHitID", tick())
        zombieRef:SetAttribute("WepHitDirection", direction * 10)
        zombieRef:SetAttribute("WepHitPos", hitPos)
        lastZombieHitTime[zombieModel] = now
        return 1
    end
    if originalBayonetHitCheck then
        return originalBayonetHitCheck(self, origin, direction, raycastParams, hitEntities)
    end
    return 0
end

local function unifiedMeleeHitCheck(self, origin, direction, raycastParams, hitEntities, isCharge)
    local zombieModel, zombieRef, hitPos, rayResult, now = resolveHeadHit(origin, direction, raycastParams)
    if zombieModel == 0 or zombieRef == 0 then return 0 end
    if zombieModel then
        -- Probability roll: only force head HitChance% of the time, otherwise
        -- fall through to the game's original (legit body) hit check.
        local chance = tonumber(HeadHitChance) or 100
        if chance < 100 and math.random(1, 100) > chance then
            if originalMeleeHitCheck then
                return originalMeleeHitCheck(self, origin, direction, raycastParams, hitEntities, isCharge)
            end
            return 0
        end
        local partName = "Head"
        local char = LocalPlayer.Character
        local headPart = char and char:FindFirstChild("Head")
        local Direction = headPart and (hitPos - headPart.Position).Unit or v3new(0, 1, 0)
        if isCharge then
            self.remoteEvent:FireServer("ThrustCharge", zombieRef, hitPos, rayResult.Normal)
        else
            self.remoteEvent:FireServer("HitZombieM", zombieRef, hitPos, true, hitPos, partName, Direction)
        end
        lastZombieHitTime[zombieModel] = now
        return 1
    end
    if originalMeleeHitCheck then
        return originalMeleeHitCheck(self, origin, direction, raycastParams, hitEntities, isCharge)
    end
    return 0
end

local function swapHitCheck(modTable, key, newFn, stored)
    if not modTable then return stored end
    if type(hookfunction) == "function" then
        if not stored then
            return hookfunction(modTable[key], newFn)
        end
        hookfunction(modTable[key], newFn)
        return stored
    end
    if not stored then
        stored = modTable[key]
    end
    modTable[key] = newFn
    return stored
end

local function restoreHitCheck(modTable, key, origFn)
    if not modTable or not origFn then return end
    if type(hookfunction) == "function" then
        hookfunction(modTable[key], origFn)
    else
        modTable[key] = origFn
    end
end

local function updateHitHooks()
    local shouldHook = headshotEnabled
    local rs = ReplicatedStorage
    local weapons = rs:FindFirstChild("Modules") and rs.Modules:FindFirstChild("Weapons")
    if shouldHook and not hookInstalled then
        if weapons then
            local success, FlintLock = pcall(require, weapons:FindFirstChild("Flintlock"))
            if success and FlintLock then
                originalBayonetHitCheck = swapHitCheck(FlintLock, "BayonetHitCheck", unifiedBayonetHitCheck, originalBayonetHitCheck)
            end
            local success2, MeleeBase = pcall(require, weapons:FindFirstChild("MeleeBase"))
            if success2 and MeleeBase then
                originalMeleeHitCheck = swapHitCheck(MeleeBase, "MeleeHitCheck", unifiedMeleeHitCheck, originalMeleeHitCheck)
            end
        end
        hookInstalled = true
    elseif not shouldHook and hookInstalled then
        if weapons then
            if originalBayonetHitCheck then
                local success, FlintLock = pcall(require, weapons:FindFirstChild("Flintlock"))
                if success and FlintLock then
                    restoreHitCheck(FlintLock, "BayonetHitCheck", originalBayonetHitCheck)
                end
            end
            if originalMeleeHitCheck then
                local success, MeleeBase = pcall(require, weapons:FindFirstChild("MeleeBase"))
                if success and MeleeBase then
                    restoreHitCheck(MeleeBase, "MeleeHitCheck", originalMeleeHitCheck)
                end
            end
        end
        hookInstalled = false
    end
end

-- Re-hook after respawn (the game re-requires/replaces weapon modules each round)
_G.ArreyConns = _G.ArreyConns or {}
if _G.ArreyConns.headshotRespawn then pcall(function() _G.ArreyConns.headshotRespawn:Disconnect() end) end
_G.ArreyConns.headshotRespawn = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if headshotEnabled then
        pcall(updateHitHooks)
    end
end)

-- ---------- Aiming Section ----------
-- Aiming moved into Aura Effects tabbox

HeadHitEnabled = false -- Global for keybind access
HeadHitChance = 100 -- Global headshot probability (1-100). 1 = legit/misses a lot, 50 = coin flip, 100 = always head.

local function notifyAndLock(title, desc, widgets)
    pcall(function()
        if Library then
            Library:Notify({ Title = title, Description = desc, Time = 4, Icon = "alert-circle" })
        end
    end)
    pcall(function()
        for _, w in widgets or {} do
            if w and type(w.SetValue) == "function" then
                w:SetValue(false)
            end
        end
    end)
end

local function notifyErrorAndLock(toggle)
    notifyAndLock("Aiming — Error", "Head Hit had an error and will be locked.", toggle and { toggle } or {})
end

-- ===== AURA EFFECTS — Accuracy (force headshots) =====
local HeadHitToggle
HeadHitToggle = Tabs.AuraEffects:AddToggle('HeadHit', {
    Text = "Head Hit",
    Default = false,
    Tooltip = "Forces Attacks To Redirect to the zombies Head.",
    Callback = function(value)
        HeadHitEnabled = value
        headshotEnabled = value

        local ok, err = pcall(updateHitHooks)

        if not ok then
            HeadHitEnabled = false
            headshotEnabled = false
            pcall(updateHitHooks)
            notifyErrorAndLock(HeadHitToggle)
            return
        end

        pcall(function()
            if Library then
                Library:Notify({
                    Title = "Aiming",
                    Description = value and "Head Hit enabled" or "Head Hit disabled",
                    Time = 2,
                    Icon = value and "crosshair" or "crosshair-off",
                })
            end
        end)
    end
})

-- Store toggle reference globally for keybind access
_G.ArreyToggleElements.HeadHit = Toggles.HeadHit

Tabs.AuraEffects:AddSlider('HeadHitChance', {
    Text = "Head Hit Chance",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Tooltip = "Headshot probability",
    Callback = function(value)
        HeadHitChance = math.clamp(math.floor(tonumber(value) or 100), 1, 100)
    end
})

_G.ArreyToggles.HeadHit = {
    element = HeadHitToggle,
    getState = function() return HeadHitEnabled end,
    setState = function(v) HeadHitEnabled = v; if Toggles.HeadHit then Toggles.HeadHit:SetValue(v) end end
}

-- ---------- Legit / Auto Jump Section ----------
local LegitGroup = Tabs.LocalPlayer:AddGroupbox({ Side = "Right", Name = "Legit Thingys", Description = "Natural movement", IconName = "shield-check" })

local TARGET_ANIM_IDS = {
    "rbxassetid://17406577733",
    "rbxassetid://15669224658",
    "rbxassetid://12591948314",
    "rbxassetid://12333491302",
}

AutoJumpHeight = 7.2
AutoJumpCooldown = 0
local lastJumpTime = 0

local TARGETS = {}
for _, v in TARGET_ANIM_IDS do
    local id = tostring(v)
    if id:match("^%d+$") then
        id = "rbxassetid://" .. id
    end
    TARGETS[id] = true
end

local humanoid, animator
local playedTracks = {}

local function normalizeAnimId(id)
    if not id then return nil end
    local s = tostring(id)
    if s:match("^%d+$") then
        return "rbxassetid://" .. s
    end
    return s
end

local function trackIsTarget(track)
    if not track or not track.IsPlaying then return false end
    local anim = track.Animation
    if not anim or not anim.AnimationId then return false end
    local aId = normalizeAnimId(anim.AnimationId)
    return aId and TARGETS[aId]
end

local function doJump()
    if not humanoid or not humanoid.Parent then return end

    local now = time()
    if AutoJumpCooldown > 0 and (now - lastJumpTime) < AutoJumpCooldown then
        return
    end
    lastJumpTime = now

    task.spawn(function()
        pcall(function()
            local timeout = 1
            local startTime = time()

            while time() - startTime < timeout do
                local state = humanoid:GetState()
                if state == Enum.HumanoidStateType.Running
                    or state == Enum.HumanoidStateType.Landed
                    or state == Enum.HumanoidStateType.RunningNoPhysics
                    or state == Enum.HumanoidStateType.Climbing then
                    break
                end
                task.wait(0.05)
            end

            local gravity = workspace.Gravity
            local jumpHeight = AutoJumpHeight or 3.5
            local jumpVelocity = mathSqrt(2 * gravity * jumpHeight)

            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                local currentVel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = v3new(currentVel.X, jumpVelocity, currentVel.Z)
            end
        end)
    end)
end

local monitoringConn = nil

local function startMonitoring()
    if monitoringConn then return end
    if not animator then return end
    monitoringConn = animator.AnimationPlayed:Connect(function(track)
        if trackIsTarget(track) and not playedTracks[track] then
            playedTracks[track] = true
            pcall(doJump)
            local stoppedConn = nil
            stoppedConn = track.Stopped:Connect(function()
                playedTracks[track] = nil
                if stoppedConn then
                    pcall(function() stoppedConn:Disconnect() end)
                    stoppedConn = nil
                end
            end)
        end
    end)
end

local function stopMonitoring()
    if monitoringConn then
        pcall(function() monitoringConn:Disconnect() end)
        monitoringConn = nil
    end
    playedTracks = {}
end

local function refreshCharacter(char)
    lastJumpTime = 0
    playedTracks = {}

    humanoid = char and char:FindFirstChildOfClass("Humanoid") or nil
    animator = nil
    if humanoid then
        animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Name = "AutoAnimator"
            animator.Parent = humanoid
        end
    end
end

refreshCharacter(LocalPlayer.Character)

local function restoreAutoJump()
    local persisted = false
    pcall(function()
        persisted = LocalPlayer:GetAttribute("AutoJumpEnabled")
    end)
    if persisted then
        task.delay(0.3, startMonitoring)
    end
end
restoreAutoJump()

local autoJumpCharConnection = nil
local function setupAutoJumpCharConnection()
    if autoJumpCharConnection then
        pcall(function() autoJumpCharConnection:Disconnect() end)
    end
    autoJumpCharConnection = LocalPlayer.CharacterAdded:Connect(function(ch)
        ch:WaitForChild("Humanoid", 5)
        ch:WaitForChild("HumanoidRootPart", 5)
        refreshCharacter(ch)
        restoreAutoJump()
    end)
end
setupAutoJumpCharConnection()

_G.AutoJumpCharConnectionCleanup = function()
    if autoJumpCharConnection then
        pcall(function() autoJumpCharConnection:Disconnect() end)
        autoJumpCharConnection = nil
    end
end

local AutoJumpToggle = LegitGroup:AddToggle('AutoJump', {
    Text = "Auto Jump",
    Default = false,
    Tooltip = "Makes you jump When Thrusting Your Weapon",
    Callback = function(value)
        pcall(function() LocalPlayer:SetAttribute("AutoJumpEnabled", value) end)
        if value then
            startMonitoring()
            Library:Notify({
                Title = "Jump On Swing",
                Description = "Auto Jump Enabled",
                Time = 2,
                Icon = "activity",
            })
        else
            stopMonitoring()
            Library:Notify({
                Title = "Jump On Swing",
                Description = "Auto Jump Disabled",
                Time = 2,
                Icon = "activity-off",
            })
        end
    end
})
_G.ArreyToggleElements.AutoJump = AutoJumpToggle

LegitGroup:AddSlider('JumpHeight', {
    Text = "Jump Height",
    Default = 3.5,
    Min = 1,
    Max = 10,
    Suffix = " studs",
    Callback = function(value)
        AutoJumpHeight = value
    end
})

LegitGroup:AddSlider('JumpCooldown', {
    Text = "Jump Cooldown",
    Default = 0,
    Min = 0,
    Max = 2,
    Rounding = 1,
    Suffix = "s",
    Callback = function(value)
        AutoJumpCooldown = value
    end
})

-- ---------- Hitbox Section ----------
-- Hitbox moved into Aura Effects tabbox

hitboxEnabled = false
hitboxSize = 10

local zombieFolder = Workspace:FindFirstChild("Zombies")
if not zombieFolder then
    warn("Bruh")
end

local function getZombieRoot()
    return Workspace:FindFirstChild("Zombies")
end

local function notifyHitboxErrorAndLock(widgets)
    notifyAndLock("Hitbox — Error", "Hitbox had an error and will be locked.", widgets)
end

local function safeCreateHitbox(parent, name, size, attachPart)
    local ok, err = pcall(function()
        if not parent or not parent.Parent then return end
        local part = Instance.new("Part")
        part.Name = name
        part.Size = v3new(size, size, size)
        part.Transparency = 1
        part.Anchored = false
        part.CanCollide = false
        part.Massless = true
        part.CanTouch = true
        part.CFrame = attachPart.CFrame
        part.Parent = parent

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = attachPart
        weld.Part1 = part
        weld.Parent = part
    end)
    return ok, err
end

local function addOuterHitbox(zombie)
    if not zombie or not zombie.Parent then return end
    local hrp = zombie:FindFirstChild("HumanoidRootPart")
    if hrp and not zombie:FindFirstChild("OuterHitbox") then
        local ok, err = safeCreateHitbox(zombie, "OuterHitbox", hitboxSize, hrp)
        if not ok then
            warn("Failed to create OuterHitbox:", err)
            return false, err
        end
    end
    return true
end

local function addHeadHitbox(zombie)
    if not zombie or not zombie.Parent then return end
    local head = zombie:FindFirstChild("Head")
    if head and not zombie:FindFirstChild("HeadHitbox") then
        local ok, err = safeCreateHitbox(zombie, "HeadHitbox", hitboxSize/2, head)
        if not ok then
            warn("Failed to create HeadHitbox:", err)
            return false, err
        end
    end
    return true
end

local function removeHitboxes(zombie)
    if not zombie then return end
    pcall(function()
        local outer = zombie:FindFirstChild("OuterHitbox")
        local head = zombie:FindFirstChild("HeadHitbox")
        if outer then outer:Destroy() end
        if head then head:Destroy() end
    end)
end

local function updateHitboxes(zombie)
    if not zombie then return true end
    if hitboxEnabled then
        removeHitboxes(zombie)
        task.wait(0.05)
        addOuterHitbox(zombie)
        addHeadHitbox(zombie)
    else
        removeHitboxes(zombie)
    end
    return true
end

local _hitboxUpdateQueue = {}
local _hitboxUpdateProcessing = false
local _hitboxUpdatesPerFrame = 3
local _lastHitboxUpdateTime = 0
local _hitboxUpdateThrottle = 0.1

local function _processHitboxQueue()
    if _hitboxUpdateProcessing or #_hitboxUpdateQueue == 0 then return end
    _hitboxUpdateProcessing = true

    local now = time()
    if now - _lastHitboxUpdateTime < _hitboxUpdateThrottle then
        _hitboxUpdateProcessing = false
        return
    end
    _lastHitboxUpdateTime = now

    task.spawn(function()
        local processed = 0
        while #_hitboxUpdateQueue > 0 and processed < _hitboxUpdatesPerFrame do
            local zombie = table.remove(_hitboxUpdateQueue, 1)
            if zombie and zombie.Parent then
                pcall(function() updateHitboxes(zombie) end)
                processed = processed + 1
            end
        end
        _hitboxUpdateProcessing = false

        if #_hitboxUpdateQueue > 0 then
            task.defer(_processHitboxQueue)
        end
    end)
end

local function _queueHitboxUpdate(zombie)
    if not zombie or not zombie.Parent then return end
    for _, z in _hitboxUpdateQueue do
        if z == zombie then return end
    end
    table.insert(_hitboxUpdateQueue, zombie)
    _processHitboxQueue()
end

local function _forEachZombieModel(container, callback)
    if not container or not callback then return end

    for _, child in container:GetChildren() do
        if child:IsA("Model") then
            callback(child)
        elseif child:IsA("Folder") then
            _forEachZombieModel(child, callback)
        end
    end
end

local function _applyHitboxToAll()
    local currentZombieFolder = getZombieRoot()
    if currentZombieFolder then
        _forEachZombieModel(currentZombieFolder, _queueHitboxUpdate)
    end
    local cam = Workspace:FindFirstChild("Camera")
    if cam then
        for _, zombie in cam:GetChildren() do
            if zombie.Name == "m_Zombie" then
                _queueHitboxUpdate(zombie)
            end
        end
    end
end

local function setHitboxSize(newSize, widgetsToLock)
    hitboxSize = newSize
    if hitboxEnabled then
        local ok, err = pcall(_applyHitboxToAll)
        if not ok then
            warn("setHitboxSize encountered an error:", err)
            notifyHitboxErrorAndLock(widgetsToLock)
        end
    end
end

local function toggleHitboxExpander(enabled, widgetsToLock)
    hitboxEnabled = enabled
    local ok, err = pcall(_applyHitboxToAll)
    if not ok then
        warn("toggleHitboxExpander encountered an error:", err)
        hitboxEnabled = false
        pcall(function()
            local currentZombieFolder = getZombieRoot()
            if currentZombieFolder then
                _forEachZombieModel(currentZombieFolder, removeHitboxes)
            end
            local cam = Workspace:FindFirstChild("Camera")
            if cam then
                for _, z in cam:GetChildren() do
                    if z.Name == "m_Zombie" then
                        removeHitboxes(z)
                    end
                end
            end
        end)
        notifyHitboxErrorAndLock(widgetsToLock)
    end
end

local _hitboxConns = {}
local function setupHitboxWatchers()
    for _, c in _hitboxConns do pcall(function() c:Disconnect() end) end
    table.clear(_hitboxConns)

    local zf = Workspace:FindFirstChild("Zombies")
    if zf then
        for _, name in {"Agent", "Slim"} do
            local folder = zf:FindFirstChild(name)
            if folder then
                table.insert(_hitboxConns, folder.ChildAdded:Connect(function(child)
                    if child:IsA("Model") and hitboxEnabled then
                        _queueHitboxUpdate(child)
                    end
                end))
            end
        end
    end

    local cam = Workspace:FindFirstChild("Camera")
    if cam then
        table.insert(_hitboxConns, cam.ChildAdded:Connect(function(child)
            if child.Name == "m_Zombie" and hitboxEnabled then
                _queueHitboxUpdate(child)
            end
        end))
    end
end
setupHitboxWatchers()

_G.HitboxConnectionCleanup = function()
    for _, c in _hitboxConns do pcall(function() c:Disconnect() end) end
    table.clear(_hitboxConns)
end

local toggleWidgetRef
local sliderSizeWidgetRef
local sliderRangeWidgetRef

Tabs.AuraEffects:AddDivider()

-- ===== AURA EFFECTS — Hitbox (easier hits) =====
toggleWidgetRef = Tabs.AuraEffects:AddToggle('HitboxExpander', {
    Text = "Hitbox Expander",
    Default = false,
    Tooltip = "Expands zombie hitboxes for easier hits.",
    Callback = function(value)
        toggleHitboxExpander(value, { toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
        pcall(function()
            if Library then
                Library:Notify({
                    Title = "Hitbox",
                    Description = value and "Hitbox Expander enabled" or "Hitbox Expander disabled",
                    Time = 2,
                    Icon = value and "scan" or "scan-line",
                })
            end
        end)
    end
})
_G.ArreyToggleElements.HitboxExpander = toggleWidgetRef

sliderSizeWidgetRef = Tabs.AuraEffects:AddSlider('HitboxSize', {
    Text = "Hitbox Zombie Size",
    Default = hitboxSize or 10,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        setHitboxSize(value, { toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
    end
})

sliderRangeWidgetRef = Tabs.AuraEffects:AddSlider('HitboxRange', {
    Text = "Hitbox Zombie Range",
    Default = _G.MaxRange or 30,
    Min = 0,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        local ok, err = pcall(function()
            _G.MaxRange = value
        end)
        if not ok then
            warn("Setting MaxRange failed:", err)
            notifyHitboxErrorAndLock({ toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
        end
    end
})

local cameraExists = Workspace:FindFirstChild("Camera") ~= nil
if (not zombieFolder) and (not cameraExists) then
    warn("Hitbox Locked Due to an error.")
    notifyHitboxErrorAndLock({ toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
end

-- ---------- Shove Hitbox & Auto Parry Sapper ----------
task.wait(0.1)
local ShoveHitboxGroup = Tabs.Classes:AddGroupbox({ Side = "Right", Name = "Shove Hitbox Expander", Description = "Shove reach", IconName = "zap" })

ShoveHitboxExpanderEnabled = false
ShoveHitboxExpanderRange = 20
ShoveHitboxExpanderTargets = 10
ShoveHitboxExpanderDelay = 0.03
ShoveHitboxAnimConnection = nil

local ShoveHitboxToggle = ShoveHitboxGroup:AddToggle('ShoveHitbox', {
    Text = "Shove Hitbox Expander",
    Default = false,
    Tooltip = "Will make the Shove Hitbox Larger.",
    Callback = function(v)
        ShoveHitboxExpanderEnabled = v
        if not v and ShoveHitboxAnimConnection then
            pcall(function() ShoveHitboxAnimConnection:Disconnect() end)
            ShoveHitboxAnimConnection = nil
        elseif v then
            if _G.AttachShoveHitboxWatcher then
                pcall(_G.AttachShoveHitboxWatcher)
            end
        end
        Library:Notify({
            Title = "Shove Hitbox Expander",
            Description = v and "Shove Hitbox Expander Enabled" or "Shove Hitbox Expander Disabled",
            Time = 2,
            Icon = v and "zap" or "x"
        })
    end
})
_G.ArreyToggleElements.ShoveHitbox = ShoveHitboxToggle

ShoveHitboxGroup:AddSlider('ShoveRange', {
    Text = "Hit Range",
    Default = 12,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(v)
        ShoveHitboxExpanderRange = v
    end
})

ShoveHitboxGroup:AddSlider('ShoveTargets', {
    Text = "Max Targets",
    Default = 10,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(v)
        ShoveHitboxExpanderTargets = v
    end
})

AutoParrySapperMeleeEnabled = false

ShoveHitboxGroup:AddDivider()

local AutoParrySapperToggle = ShoveHitboxGroup:AddToggle('AutoParrySapper', {
    Text = "Auto Parry Sapper",
    Default = false,
    Tooltip = "Will Parry An Zapper When Its Attacking (Axe And Pickaxe).",
    Callback = function(v)
        AutoParrySapperMeleeEnabled = v
        if v then
            pcall(function()
                if _G.ArreyStartAutoParrySapperMeleeLoop then
                    _G.ArreyStartAutoParrySapperMeleeLoop()
                end
            end)
        else
            pcall(function()
                if _G.ArreyStopAutoParrySapperMeleeLoop then
                    _G.ArreyStopAutoParrySapperMeleeLoop()
                end
            end)
        end
        Library:Notify({
            Title = "Auto Parry Sapper",
            Description = v and "Auto Parry Enabled" or "Auto Parry Disabled",
            Time = 2,
            Icon = v and "shield" or "shield-off"
        })
    end
})
_G.ArreyToggleElements.AutoParrySapper = AutoParrySapperToggle

local function cleanup()
    HeadHitEnabled = false
    headshotEnabled = false
    pcall(updateHitHooks)
end

_G.ArreyHeadHitCleanup = cleanup

end -- // Main Tab

do -- // ESP Tab
-- ===== ESP TAB =====

local EspTab = Tabs.ESP

local ESPTab_InitComplete = false

-- Zombie ESP selector moved into ESP tabbox

local IdentifiedIgniters = setmetatable({}, { __mode = "k" })

ESPConfigs = _G.ESPConfigs or {
    Bomber = {
        color = c3rgb(255, 180, 60),
        label = "Barrel",
        match = function(model)
            if not model or not model:IsA("Model") then return false end
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Bomber" end
            return model:FindFirstChild("Barrel") ~= nil
        end,
    },
    Cuirassier = {
        color = c3rgb(0, 200, 255),
        label = "Cuirassier",
        match = function(model)
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Cuirassier" end
            return model:FindFirstChild("Sword") ~= nil
        end,
    },
    Runner = {
        color = c3rgb(255, 0, 0),
        label = "Runner",
        match = function(model)
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Runner" end
            return model:FindFirstChild("Eye") and not model:FindFirstChild("Axe") and model:FindFirstChild("Head")
        end,
    },
    Zapper = {
        color = c3rgb(0, 255, 0),
        label = "Zapper",
        match = function(model)
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Zapper" end
            return model:FindFirstChild("Axe") and model:FindFirstChild("Head")
        end,
    },
    Igniter = {
        color = c3rgb(255, 255, 0),
        label = "Igniter",
        match = function(model)
            if not model or not model:IsA("Model") then return false end
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Igniter" end
            if model:FindFirstChild("Whale Oil Lantern") then
                IdentifiedIgniters[model] = true
                return true
            end
            if IdentifiedIgniters[model] and not model:FindFirstChild("Whale Oil Lantern") then
                IdentifiedIgniters[model] = nil
                return false
            end
            return false
        end,
    },
    Shambler = {
        color = c3rgb(180, 180, 255),
        label = "Shambler",
        match = function(model)
            if not model or not model:IsA("Model") then return false end
            local zType = _G.GetZombieTypeFromModel and _G.GetZombieTypeFromModel(model)
            if zType then return zType == "Shambler" end
            if model.Name ~= "m_Zombie" then return false end
            if model:FindFirstChild("Barrel") then return false end
            if model:FindFirstChild("Sword") then return false end
            if model:FindFirstChild("Eye") then return false end
            if model:FindFirstChild("Axe") then return false end
            if model:FindFirstChild("Whale Oil Lantern") then return false end
            return true
        end,
    },
}

local _limiterHiddenSet = {}

local ESPData = {
    Bomber = setmetatable({}, { __mode = "k" }),
    Cuirassier = setmetatable({}, { __mode = "k" }),
    Runner = setmetatable({}, { __mode = "k" }),
    Zapper = setmetatable({}, { __mode = "k" }),
    Igniter = setmetatable({}, { __mode = "k" }),
    Shambler = setmetatable({}, { __mode = "k" }),
}

local EnabledESPs = {
    Bomber = false,
    Cuirassier = false,
    Runner = false,
    Zapper = false,
    Igniter = false,
    Shambler = false,
}

local ESPModes = {
    Bomber = "Both",
    Cuirassier = "Both",
    Runner = "Both",
    Zapper = "Both",
    Igniter = "Both",
    Shambler = "Both",
}

local ShowBillboards = false
local ChamsTransparency = 0.6
local PerformanceMode = false
local ChamsMaxDistance = 2000

local ESP_CREATION_MAX_DISTANCE = 500

local espLoopRunning = false
local espHeartbeatConn = nil
local espLastTick = 0
local ESP_TICK_INTERVAL = 0.2

local function GetAdorneePart(model)
    if not model or not model:IsA("Model") then return nil end
    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    local children = model:GetChildren()
    for _, p in children do
        if p:IsA("BasePart") and p.Name ~= "Whale Oil Lantern" then
            return p
        end
    end
    for _, child in children do
        if child:IsA("Folder") or child:IsA("Model") then
            for _, p in child:GetChildren() do
                if p:IsA("BasePart") and p.Name ~= "Whale Oil Lantern" then
                    return p
                end
            end
        end
    end
    return nil
end

local function CreateESPFollowPart()
    local part = Instance.new("Part")
    part.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("P_" .. math.random(10000, 99999))
    part.Size = v3new(0.2, 0.2, 0.2)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Massless = true
    part.CastShadow = false
    part.Parent = workspace
    return part
end

-- ===== BOMBER FUSE COUNTDOWN (integrated into zombie ESP highlight) =====
-- Burn time in seconds: red fill rises bottom-up + countdown ticks below.
-- (Matches game fuse approx; Lit removal always ends the marker early on boom.)
local BOOM_FUSE_DURATION = 3.5

local function RemoveBoomCover(data)
    if data._boomCover then
        pcall(function() data._boomCover:Destroy() end)
        data._boomCover = nil
    end
    if data._boomCount then
        pcall(function() data._boomCount:Destroy() end)
        data._boomCount = nil
        data._boomCountLabel = nil
        data._boomLastTenth = nil
    end
    -- Restore pre-lit highlight colors
    local hl = data.highlight
    if hl and hl.Parent and data._boomHLFill then
        pcall(function()
            hl.FillColor = data._boomHLFill
            hl.OutlineColor = data._boomHLOutline
        end)
    end
    data._boomHLFill = nil
    data._boomHLOutline = nil
end

-- Tint highlight red + attach below-head countdown while the fuse burns.
local function SetBoomTint(data, lit)
    if not lit then
        RemoveBoomCover(data)
        return
    end
    local hl = data.highlight
    if hl and hl.Parent and not data._boomHLFill then
        data._boomHLFill = hl.FillColor
        data._boomHLOutline = hl.OutlineColor
        pcall(function()
            hl.FillColor = c3rgb(255, 0, 0)
            hl.OutlineColor = c3rgb(255, 0, 0)
        end)
    end
    if not (data._boomCount and data._boomCount.Parent) then
        local headPart = (data._headPart and data._headPart.Parent) and data._headPart or nil
        if headPart then
            local bb = Instance.new("BillboardGui")
            bb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BC_" .. math.random(10000, 99999))
            bb.Adornee = headPart
            bb.AlwaysOnTop = true
            bb.LightInfluence = 0
            bb.Size = UDim2.new(0, 90, 0, 32)
            bb.StudsOffsetWorldSpace = v3new(0, -4, 0)
            bb.MaxDistance = 1000
            bb.Enabled = true
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Count"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = strFormat("%.1f", BOOM_FUSE_DURATION)
            lbl.TextColor3 = c3rgb(255, 200, 0)
            lbl.TextStrokeTransparency = 0.2
            lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamBold
            lbl.Parent = bb
            bb.Parent = headPart
            data._boomCount = bb
            data._boomCountLabel = lbl
            data._boomLastTenth = nil
            pcall(function() if _G.protectESP then _G.protectESP(bb) end end)
        end
    end
end

local function UpdateBoomCover(data, zombie)
    local litStart = data._litStart
    if not litStart then
        RemoveBoomCover(data)
        return
    end
    -- Re-assert red tint + countdown if they were lost (recreated visuals etc.)
    if not data._boomHLFill then SetBoomTint(data, true) end

    local alpha = (tick_() - litStart) / BOOM_FUSE_DURATION
    if alpha >= 1 then
        -- Color covers the whole zombie -> countdown ended.
        RemoveBoomCover(data)
        data._litStart = nil
        return
    end

    -- Resolve a valid anchor part (cached head part preferred).
    local headPart = data._headPart
    if not (headPart and headPart.Parent) then
        headPart = GetAdorneePart(zombie)
        if not headPart then
            RemoveBoomCover(data)
            return
        end
        data._headPart = headPart
    end

    local size = data._boomSize
    local offset = data._boomOffset
    if not (size and offset) then
        -- Cache the model bounds once (bbox center relative to the head part).
        pcall(function()
            local cf, bsize = zombie:GetBoundingBox()
            data._boomSize = bsize
            data._boomOffset = cf.Position - headPart.Position
        end)
        size = data._boomSize
        offset = data._boomOffset
        if not (size and offset) then return end
    end

    local cover = data._boomCover
    if not (cover and cover.Parent) then
        cover = Instance.new("Part")
        cover.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BC_" .. math.random(10000, 99999))
        cover.Anchored = true
        cover.CanCollide = false
        cover.CanQuery = false
        cover.CanTouch = false
        cover.CastShadow = false
        cover.Massless = true
        cover.Color = c3rgb(255, 0, 0)
        cover.Material = Enum.Material.Neon
        cover.Transparency = 0.55
        cover.Parent = workspace
        data._boomCover = cover
    end

    local center = headPart.Position + offset
    local fullH = size.Y
    local curH = mathMax(0.25, fullH * alpha)
    local bottomY = center.Y - fullH / 2

    cover.Size = v3new(size.X, curH, size.Z)
    cover.CFrame = cfNew(center.X, bottomY + curH / 2, center.Z)

    -- Countdown label below the zombie (yellow -> red as the fuse burns).
    local countLbl = data._boomCountLabel
    if countLbl and countLbl.Parent then
        local remain = BOOM_FUSE_DURATION - (tick_() - litStart)
        if remain < 0 then remain = 0 end
        local tenth = mathFloor(remain * 10 + 0.5)
        if tenth ~= data._boomLastTenth then
            data._boomLastTenth = tenth
            countLbl.Text = strFormat("%.1f", tenth / 10)
            local r = mathClamp(remain / BOOM_FUSE_DURATION, 0, 1)
            countLbl.TextColor3 = c3rgb(255, mathFloor(200 * r), 0)
        end
        local countBb = data._boomCount
        if countBb and countBb.Parent and headPart and countBb.Adornee ~= headPart then
            countBb.Adornee = headPart
        end
    end
end

local function CreateVisual(espType, zombie)
    if not zombie or not zombie:IsA("Model") or ESPData[espType][zombie] then return end
    local config = ESPConfigs[espType]
    local headPart = GetAdorneePart(zombie)
    if not headPart then return end

    local mode = ESPModes[espType] or "Both"
    local data = {}
    ESPData[espType][zombie] = data
    data.maxDistance = ChamsMaxDistance
    data._headPart = headPart

    local wantHighlight = (mode == "Both" or mode == "Highlight Only") and (not PerformanceMode)
    local wantBillboard = (mode == "Both" or mode == "Billboard Only")
    local wantDot = (mode == "Dot Only") or PerformanceMode

    if wantDot then
        local dotBb = Instance.new("BillboardGui")
        dotBb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("Dot_" .. math.random(10000, 99999))
        dotBb.Adornee = headPart
        dotBb.AlwaysOnTop = true
        dotBb.Size = UDim2.new(0, 8, 0, 8)
        dotBb.StudsOffset = v3new(0, 0, 0)
        dotBb.MaxDistance = ChamsMaxDistance
        dotBb.Parent = zombie
        data.dot = dotBb

        local dotFrame = Instance.new("Frame")
        dotFrame.Size = UDim2.new(1, 0, 1, 0)
        dotFrame.BackgroundColor3 = config.color
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = dotFrame
        dotFrame.Parent = dotBb
    end

    if wantHighlight then
        local hl = Instance.new("Highlight")
        hl.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("HL_" .. math.random(10000, 99999))
        hl.Adornee = zombie
        hl.FillColor = config.color
        hl.OutlineColor = c3rgb(255, 255, 255)
        hl.FillTransparency = ChamsTransparency
        hl.OutlineTransparency = 0
        hl.Parent = zombie
        data.highlight = hl
    end

    if wantBillboard then
        local bb = Instance.new("BillboardGui")
        bb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BB_" .. math.random(10000, 99999))
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Size = UDim2.new(0, 100, 0, 40)
        bb.StudsOffsetWorldSpace = v3new(0, 3, 0)
        bb.MaxDistance = 1000
        bb.Enabled = ShowBillboards
        data.billboard = bb

        local followPart = CreateESPFollowPart()
        followPart.CFrame = headPart.CFrame
        data.followPart = followPart
        bb.Adornee = followPart

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = c3rgb(30, 30, 30)
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 1
        frame.BorderColor3 = config.color
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        data.frame = frame

        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = v2new(0.5, 0)
        lbl.Position = UDim2.new(0.5, 0, 0.1, 0)
        lbl.Size = UDim2.new(0.9, 0, 0.5, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = config.label
        lbl.TextColor3 = config.color
        lbl.TextStrokeTransparency = 0.8
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = frame
        data.label = lbl

        local distLbl = Instance.new("TextLabel")
        distLbl.AnchorPoint = v2new(0.5, 1)
        distLbl.Position = UDim2.new(0.5, 0, 0.9, 0)
        distLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "0 studs"
        distLbl.TextColor3 = c3rgb(200, 200, 200)
        distLbl.TextScaled = true
        distLbl.Font = Enum.Font.Gotham
        distLbl.Parent = frame
        data.distLabel = distLbl

        frame.Parent = bb
        bb.Parent = followPart

        -- Force the GUI to the desired state after parenting.
        bb.Enabled = ShowBillboards
    end

    local stateFolder = zombie:FindFirstChild("State")
    if stateFolder then
        data._litConn = stateFolder.ChildAdded:Connect(function(c)
            if c.Name == "Lit" then
                data._litStart = tick_()
                SetBoomTint(data, true)
            end
        end)
        data._litOutConn = stateFolder.ChildRemoved:Connect(function(c)
            if c.Name == "Lit" then
                data._litStart = nil
                SetBoomTint(data, false)
            end
        end)
        if stateFolder:FindFirstChild("Lit") then
            data._litStart = tick_()
            SetBoomTint(data, true)
        end
    end

    pcall(function()
        if _G.protectESP then
            if data.highlight then _G.protectESP(data.highlight) end
            if data.billboard then _G.protectESP(data.billboard) end
            if data.dot then _G.protectESP(data.dot) end
        end
    end)
end

local function RemoveVisual(espType, zombie)
    local data = ESPData[espType][zombie]
    if not data then return end
    if data.highlight then pcall(function() data.highlight:Destroy() end) end
    if data.billboard then pcall(function() data.billboard:Destroy() end) end
    if data.dot then pcall(function() data.dot:Destroy() end) end
    if data.followPart then pcall(function() data.followPart:Destroy() end) end
    if data._litConn then pcall(function() data._litConn:Disconnect() end) end
    if data._litOutConn then pcall(function() data._litOutConn:Disconnect() end) end
    RemoveBoomCover(data)
    data._litConn = nil
    data._litOutConn = nil
    data._litStart = nil
    data._boomCount = nil
    data._boomCountLabel = nil
    data._boomLastTenth = nil
    data._boomHLFill = nil
    data._boomHLOutline = nil
    data.highlight = nil
    data.billboard = nil
    data.dot = nil
    data.followPart = nil
    data.frame = nil
    data.label = nil
    data.distLabel = nil
    ESPData[espType][zombie] = nil
    if zombie then
        IdentifiedIgniters[zombie] = nil
    end
end

local function EnsureZombieBillboard(espType, zombie)
    if not (zombie and zombie:IsA("Model")) then return false end
    local config = ESPConfigs[espType]
    if not config then return false end

    local data = ESPData[espType][zombie]
    if not data then return false end

    -- Already valid
    if data.billboard and data.billboard.Parent then
        return true
    end

    local headPart = GetAdorneePart(zombie)
    if not headPart then return false end

    -- Ensure the invisible follow part exists, then reuse it.
    local followPart = data.followPart
    if not followPart or not followPart.Parent then
        followPart = CreateESPFollowPart()
        data.followPart = followPart
    end
    followPart.CFrame = headPart.CFrame

    local bb = Instance.new("BillboardGui")
    bb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BB_" .. math.random(10000, 99999))
    bb.Adornee = followPart
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffsetWorldSpace = v3new(0, 3, 0)
    bb.MaxDistance = 1000
    bb.Enabled = ShowBillboards
    data.billboard = bb

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = c3rgb(30, 30, 30)
    frame.BackgroundTransparency = 0.7
    frame.BorderSizePixel = 1
    frame.BorderColor3 = config.color

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.AnchorPoint = v2new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0.1, 0)
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = config.label
    label.TextColor3 = config.color
    label.TextStrokeTransparency = 0.8
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.AnchorPoint = v2new(0.5, 1)
    distLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
    distLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 studs"
    distLabel.TextColor3 = c3rgb(200, 200, 200)
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = frame

    frame.Parent = bb
    -- Parent to the invisible follow part (escapes zombie-model scanning).
    bb.Parent = followPart

    data.billboard = bb
    data.frame = frame
    data.label = label
    data.distLabel = distLabel

    pcall(function()
        if _G.protectESP then
            _G.protectESP(bb)
        end
    end)

    data.billboard.Adornee = followPart
    data.billboard.Enabled = true

    return true
end

local _zombiesBuf = {}
local _zombiesBufLen = 0
local _zombieSetBuf = {}

local function CollectZombies()
    _zombiesBufLen = 0
    local cache = _G.CentralZombieCache
    local count = _G.CentralZombieCount
    for i = 1, count do
        local z = cache[i]
        local hasCharacter = z:FindFirstChild("Character")
        local nameStartsWithUnderscore = z.Name:sub(1, 1) == "_"
        if not hasCharacter and not nameStartsWithUnderscore then
            _zombiesBufLen = _zombiesBufLen + 1
            _zombiesBuf[_zombiesBufLen] = z
        end
    end
    for i = _zombiesBufLen + 1, #_zombiesBuf do _zombiesBuf[i] = nil end
    return _zombiesBuf, _zombiesBufLen
end

local function ScanAll()
    local zombies, zombieCount = CollectZombies()


    table.clear(_zombieSetBuf)
    for i = 1, zombieCount do
        _zombieSetBuf[zombies[i]] = true
    end

    local cam = workspace.CurrentCamera
    local camPos = cam and cam.CFrame.Position or v3new(0, 0, 0)

    local anyEnabled = false
    for _, v in EnabledESPs do
        if v then anyEnabled = true; break end
    end
    if not anyEnabled then
        for espType in ESPData do
            if tableHasEntries(ESPData[espType]) then
                for z in ESPData[espType] do
                    RemoveVisual(espType, z)
                end
                ESPData[espType] = setmetatable({}, { __mode = "k" })
            end
        end
        return
    end

    -- Remove visuals for zombies that are gone, disabled, or no longer match
    for espType, dataTable in ESPData do
        if tableHasEntries(dataTable) then
            for z in dataTable do
                if not _zombieSetBuf[z] or not EnabledESPs[espType] or not ESPConfigs[espType].match(z) then
                    RemoveVisual(espType, z)
                end
            end
        end
    end

    local createBudget = 3
    for i = 1, zombieCount do
        local z = zombies[i]
        if not z:IsA("Model") then continue end

        local espType = nil
        for t, enabled in EnabledESPs do
            if enabled and ESPConfigs[t].match(z) then
                espType = t
                break
            end
        end
        if not espType then continue end

        local zombiePart = z.PrimaryPart or z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Head")
        if not zombiePart then continue end
        local dist = (camPos - zombiePart.Position).Magnitude

        local data = ESPData[espType][z]
        if not data then
            if dist <= ESP_CREATION_MAX_DISTANCE and createBudget > 0 then
                createBudget = createBudget - 1
                CreateVisual(espType, z)
            end
            continue
        end

        local maxDist = data.maxDistance or ChamsMaxDistance

        if data.highlight then
            local hlWant = (not PerformanceMode) and dist <= maxDist
            if data.highlight.Enabled ~= hlWant then data.highlight.Enabled = hlWant end
        end
        if data.dot then
            local dotWant = PerformanceMode and dist <= maxDist
            if data.dot.Enabled ~= dotWant then data.dot.Enabled = dotWant end
        end
        if ShowBillboards then
            EnsureZombieBillboard(espType, z)

            if data.billboard then
                local wantEnabled = dist < (PerformanceMode and 500 or 300)


                if data.billboard.Enabled ~= wantEnabled then
                    data.billboard.Enabled = wantEnabled
                end

                if wantEnabled and data.distLabel then
                    local flooredDist = mathFloor(dist)

                    if data._lastDist ~= flooredDist then
                        data._lastDist = flooredDist
                        data.distLabel.Text = flooredDist .. " studs"
                    end
                end
            end
        elseif data.billboard then
            data.billboard.Enabled = false
        end
    end
end

local function UpdateAllTransparencies()
    for espType, dataTable in ESPData do
        for _, data in dataTable do
            if data.highlight then data.highlight.FillTransparency = ChamsTransparency end
        end
    end
end

-- ===== DEDICATED ZOMBIE BILLBOARD FOLLOW LOOP =====
local billboardFollowConn = nil
local billboardFollowLast = 0
local BILLBOARD_FOLLOW_INTERVAL = 0.033
local ZOMBIE_BB_BASE_SIZE = v2new(100, 40)
local ZOMBIE_BB_MIN_SCALE = 0.4
local ZOMBIE_BB_MAX_SCALE = 1.5

local function UpdateZombieBillboards()
    local cam = workspace.CurrentCamera
    local camPos = cam and cam.CFrame.Position
    if not camPos then
        -- Camera can be briefly missing; still update countdowns.
        for _, dataTable in ESPData do
            for z, data in dataTable do
                if data then UpdateBoomCover(data, z) end
            end
        end
        return
    end

    for espType, dataTable in ESPData do
        for z, data in dataTable do
            if data then
                UpdateBoomCover(data, z)
            end
            if data and data.billboard and data.billboard.Parent and data.billboard.Enabled then
                local headPart = data._headPart
                if not (headPart and headPart.Parent) then
                    headPart = GetAdorneePart(z)
                    if not headPart then continue end
                    data._headPart = headPart
                end
                local fp = data.followPart
                if not (fp and fp.Parent) then
                    -- Recreate the follow part if it was cleaned up externally.
                    fp = CreateESPFollowPart()
                    data.followPart = fp
                end
                if fp then
                    -- Always re-assert the billboard onto the follow part.
                    if data.billboard.Adornee ~= fp then data.billboard.Adornee = fp end
                    if data.billboard.Parent ~= fp then data.billboard.Parent = fp end
                end
                if headPart then
                    fp.CFrame = headPart.CFrame
                end

                local dist = headPart and (camPos - headPart.Position).Magnitude or 1
                local scale = mathClamp(40 / mathMax(dist, 1), ZOMBIE_BB_MIN_SCALE, ZOMBIE_BB_MAX_SCALE)
                local w = mathFloor(ZOMBIE_BB_BASE_SIZE.X * scale)
                local h = mathFloor(ZOMBIE_BB_BASE_SIZE.Y * scale)
                if data._lastBBW ~= w or data._lastBBH ~= h then
                    data._lastBBW = w
                    data._lastBBH = h
                    data.billboard.Size = UDim2.new(0, w, 0, h)
                end
            end
        end
    end
end

local function StartBillboardFollow()
    if billboardFollowConn then return end
    billboardFollowConn = RunService.Heartbeat:Connect(function()
        local now = time()
        if now - billboardFollowLast < BILLBOARD_FOLLOW_INTERVAL then return end
        billboardFollowLast = now
        UpdateZombieBillboards()
    end)
end

local function StopBillboardFollow()
    if billboardFollowConn then
        billboardFollowConn:Disconnect()
        billboardFollowConn = nil
    end
end

local function StartShared()
    if espLoopRunning then return end
    espLoopRunning = true
    ScanAll()
    espHeartbeatConn = RunService.Heartbeat:Connect(function()
        local now = time()
        if now - espLastTick < ESP_TICK_INTERVAL then return end
        espLastTick = now
        ScanAll()
    end)
    StartBillboardFollow()
end

local function StopShared()
    espLoopRunning = false
    StopBillboardFollow()
    if espHeartbeatConn then
        espHeartbeatConn:Disconnect()
        espHeartbeatConn = nil
    end
    for k in IdentifiedIgniters do IdentifiedIgniters[k] = nil end
    for espType in ESPData do
        for zombie in ESPData[espType] do
            RemoveVisual(espType, zombie)
        end
        ESPData[espType] = setmetatable({}, { __mode = "k" })
    end
end

local function TogglePerformanceMode(state)
    PerformanceMode = state
    for espType in ESPConfigs do
        for zombie, data in ESPData[espType] do
            if data.highlight then
                data.highlight.Enabled = not state
            end
            if data.dot then
                data.dot.Enabled = state
            end
        end
    end
end

local LastChargeState = false
local NotifyCuirassierCharge = false
local CuirassierStateLoop
local CuirassierStateConn = nil
local CuirassierWatchedState = nil

local function CuirassierUnwatch()
    if CuirassierStateConn then
        pcall(function() CuirassierStateConn:Disconnect() end)
        CuirassierStateConn = nil
    end
    CuirassierWatchedState = nil
end

local function IsCharging(state)
    if state == "begincharge" or state == "charge" then return true end
    state = tostring(state or ""):lower()
    return (state == "begincharge" or state == "charge")
end

local function UpdateCuirassierState()
    local zFolder = workspace:FindFirstChild("Zombies")
    if not zFolder then LastChargeState = false CuirassierUnwatch() return end
    local slim = zFolder:FindFirstChild("Slim")
    if not slim then LastChargeState = false CuirassierUnwatch() return end
    local stateVal = slim:FindFirstChild("State")
    if not stateVal or not stateVal:IsA("StringValue") then LastChargeState = false CuirassierUnwatch() return end

    -- Instant edge detection on top of the poll below (short charges can
    -- start and end between two polls).
    if stateVal ~= CuirassierWatchedState or not (CuirassierStateConn and CuirassierStateConn.Connected) then
        CuirassierUnwatch()
        CuirassierWatchedState = stateVal
        pcall(function()
            CuirassierStateConn = stateVal.Changed:Connect(function()
                pcall(UpdateCuirassierState)
            end)
        end)
    end

    local charging = IsCharging(stateVal.Value)
    for _, data in pairs(ESPData.Cuirassier) do
        if data.label and (data.frame or true) then
            if charging then
                data.label.Text = "Charging"
                data.label.TextColor3 = c3rgb(255, 80, 80)
                if data.frame then data.frame.BorderColor3 = c3rgb(255, 80, 80) end
                if data.highlight then
                    data.highlight.FillColor = c3rgb(255, 0, 0)
                    data.highlight.OutlineColor = c3rgb(255, 0, 0)
                end
            else
                data.label.Text = "Cuirassier"
                data.label.TextColor3 = ESPConfigs.Cuirassier.color
                if data.frame then data.frame.BorderColor3 = ESPConfigs.Cuirassier.color end
                if data.highlight then
                    data.highlight.FillColor = ESPConfigs.Cuirassier.color
                    data.highlight.OutlineColor = c3rgb(255, 255, 255)
                end
            end
        end
    end
    if charging and NotifyCuirassierCharge and not LastChargeState then
        pcall(function()
            if Library and typeof(Library.Notify) == "function" then
                Library:Notify({ Title = "Cuirassier Charge", Description = "A Cuirassier is Charging!", Icon = "bell", Time = 3 })
            end
        end)
    end
    LastChargeState = charging
end

local function StartCuirassierSpecific()
    LastChargeState = false
    UpdateCuirassierState()
    CuirassierStateLoop = task.spawn(function()
        while EnabledESPs.Cuirassier do
            UpdateCuirassierState()
            task.wait(0.15)
        end
    end)
end

local function StopCuirassierSpecific()
    if CuirassierStateLoop then task.cancel(CuirassierStateLoop); CuirassierStateLoop = nil end
    CuirassierUnwatch()
    LastChargeState = false
end

local function ApplyColorToExisting(espType, color)
    local dataTable = ESPData[espType]
    if not dataTable then return end
    for zombie, data in dataTable do
        pcall(function()
            if data.highlight then data.highlight.FillColor = color end
            if data.frame then data.frame.BorderColor3 = color end
            if data.label then data.label.TextColor3 = color end
            if data.dot then
                for _, child in data.dot:GetDescendants() do
                    if child:IsA("Frame") then child.BackgroundColor3 = color end
                end
            end
        end)
    end
end

local EspList = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SelectedESPs = _G.SelectedESPs or {}
previousSelectedESPs = _G.previousSelectedESPs or {}
local espToggle -- forward ref

local function RemoveAllVisualsForType(typeName)
    local t = ESPData[typeName]
    if not t then return end
    for zombieModel, data in t do
        if data then
            if data.highlight then pcall(function() data.highlight:Destroy() end) end
            if data.billboard then pcall(function() data.billboard:Destroy() end) end
            if data.dot then pcall(function() data.dot:Destroy() end) end
            data.highlight = nil
            data.billboard = nil
            data.dot = nil
            data.frame = nil
            data.label = nil
            data.distLabel = nil
        end
        if zombieModel then
            IdentifiedIgniters[zombieModel] = nil
        end
    end
    ESPData[typeName] = setmetatable({}, { __mode = "k" })
end

local function AnyESPEnabled()
    for k, v in EnabledESPs do
        if v then return true end
    end
    return false
end

-- UI: Select ESP Types dropdown (multi-select)
Tabs.ZombieESP:AddDropdown('EspTypes', {
    Text = "Select ESP Types",
    Multi = true,
    Values = EspList,
    Default = {},
    Callback = function(newSelection)
        local newSelection = newSelection or {}

        local newSet = {}
        for key, _ in newSelection do newSet[tostring(key)] = true end

        for _, removedKey in previousSelectedESPs do
            if not newSet[tostring(removedKey)] then
                RemoveAllVisualsForType(removedKey)
                EnabledESPs[removedKey] = false
                if removedKey == "Cuirassier" then
                    pcall(function() StopCuirassierSpecific() end)
                end
                if not AnyESPEnabled() then pcall(function() StopShared() end) end

                if ESPTab_InitComplete then
                    pcall(function()
                        Library:Notify({
                            Title = (removedKey .. " ESP"),
                            Description = (removedKey .. " ESP disabled (deselected)"),
                            Icon = "eye-off",
                            Time = 1
                        })
                    end)
                end
            end
        end

        SelectedESPs = {}
        for key, _ in newSelection do table.insert(SelectedESPs, key) end

        previousSelectedESPs = {}
        for _, v in SelectedESPs do table.insert(previousSelectedESPs, v) end

        if espToggle and not _G.ArreySilentConfigLoad then
            local anySelected = (#SelectedESPs > 0)
            if not anySelected then
                pcall(function() espToggle:SetValue(false) end)
            else
                local allEnabled = true
                for _, key in SelectedESPs do
                    if not EnabledESPs[key] then
                        allEnabled = false
                        break
                    end
                end
                pcall(function() espToggle:SetValue(allEnabled) end)
            end
        end

        if ESPTab_InitComplete then
            pcall(function()
                Library:Notify({
                    Title = "ESP Selection",
                    Description = (#SelectedESPs > 0) and ("Selected: " .. table.concat(SelectedESPs, ", ")) or "No selection",
                    Icon = "eye",
                    Time = 1
                })
            end)
        end
    end
})

-- UI: Enable selected ESP toggle
espToggle = Tabs.ZombieESP:AddToggle('EspSelect', {
    Text = "Enable Selected ESP",
    Default = false,
    Tooltip = "Enable Esp From The Selected Type.",
    Callback = function(state)
        if _G.ArreySilentConfigLoad and (not SelectedESPs or #SelectedESPs == 0) then
            return
        end

        if not SelectedESPs or #SelectedESPs == 0 then
            if state then
                pcall(function() Library:Notify({ Title = "ESP", Description = "No ESP types selected.", Icon = "alert-circle", Time = 2 }) end)
            end
            pcall(function() espToggle:SetValue(false) end)
            return
        end

        for _, key in SelectedESPs do
            if key then
                if EnabledESPs[key] ~= state then
                    EnabledESPs[key] = state

                    if state then
                        ESPData[key] = ESPData[key] or {}
                        pcall(function() StartShared() end)
                        if key == "Cuirassier" then pcall(function() StartCuirassierSpecific() end) end
                        pcall(function()
                            Library:Notify({ Title = (key .. " ESP"), Description = (key .. " ESP enabled"), Icon = "eye", Time = 1 })
                        end)
                    else
                        pcall(function() RemoveAllVisualsForType(key) end)
                        EnabledESPs[key] = false
                        if key == "Cuirassier" then pcall(function() StopCuirassierSpecific() end) end
                        if not AnyESPEnabled() then pcall(function() StopShared() end) end
                        pcall(function()
                            Library:Notify({ Title = (key .. " ESP"), Description = (key .. " ESP disabled"), Icon = "eye-off", Time = 1 })
                        end)
                    end
                end
            end
        end
    end
})

-- UI: ESP Colors groupbox (right side)
local ColorsSection = EspTab:AddGroupbox({ Side = "Left", Name = "ESP Colors", Description = "ESP colors", IconName = "palette" })
ColorsSection:AddLabel("Barrel (Bomber)"):AddColorPicker('BomberColor', {
    Default = ESPConfigs.Bomber.color,
    Callback = function(color)
        ESPConfigs.Bomber.color = color
        ApplyColorToExisting("Bomber", color)
    end
})
ColorsSection:AddLabel("Cuirassier"):AddColorPicker('CuirassierColor', {
    Default = ESPConfigs.Cuirassier.color,
    Callback = function(color)
        ESPConfigs.Cuirassier.color = color
        ApplyColorToExisting("Cuirassier", color)
    end
})
ColorsSection:AddLabel("Runner"):AddColorPicker('RunnerColor', {
    Default = ESPConfigs.Runner.color,
    Callback = function(color)
        ESPConfigs.Runner.color = color
        ApplyColorToExisting("Runner", color)
    end
})
ColorsSection:AddLabel("Zapper"):AddColorPicker('ZapperColor', {
    Default = ESPConfigs.Zapper.color,
    Callback = function(color)
        ESPConfigs.Zapper.color = color
        ApplyColorToExisting("Zapper", color)
    end
})
ColorsSection:AddLabel("Igniter"):AddColorPicker('IgniterColor', {
    Default = ESPConfigs.Igniter.color,
    Callback = function(color)
        ESPConfigs.Igniter.color = color
        ApplyColorToExisting("Igniter", color)
    end
})
ColorsSection:AddLabel("Shambler (Normal)"):AddColorPicker('ShamblerColor', {
    Default = ESPConfigs.Shambler.color,
    Callback = function(color)
        ESPConfigs.Shambler.color = color
        ApplyColorToExisting("Shambler", color)
    end
})

-- UI: Settings groupbox
local SettingsSection = EspTab:AddGroupbox({ Side = "Left", Name = "Settings", Description = "ESP settings", IconName = "settings" })
SettingsSection:AddToggle('ShowBillboard', {
    Text = "Show Billboard",
    Default = false,
    Tooltip = "Toggles billboards above the zombies",
    Callback = function(state)
        ShowBillboards = state

        -- Immediately refresh existing visuals.
        for espType, dataTable in ESPData do
            for zombie, data in dataTable do
                if data then
                    if state then
                        EnsureZombieBillboard(espType, zombie)

                        if data.billboard and data.billboard.Parent then
                            data.billboard.Enabled = true
                        end
                    else
                        -- Don't destroy it; just hide it.
                        if data.billboard then
                            data.billboard.Enabled = false
                        end
                    end
                end
            end
        end

        -- Force an immediate scan after changing the setting.
        if AnyESPEnabled() then
            if not espLoopRunning then
                StartShared()
            else
                pcall(ScanAll)
            end
        end
    end
})
SettingsSection:AddSlider('ChamsTransparency', {
    Text = "Chams Transparency",
    Default = 0.6,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        ChamsTransparency = mathClamp(tonumber(value) or 0.6, 0, 1)
        UpdateAllTransparencies()
    end
})
SettingsSection:AddSlider('ChamsViewDistance', {
    Text = "Chams View Distance",
    Default = 2000,
    Min = 500,
    Max = 5000,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(value)
        ChamsMaxDistance = mathClamp(tonumber(value) or 2000, 500, 5000)
        for _, dataTable in ESPData do
            for _, data in dataTable do
                data.maxDistance = ChamsMaxDistance
                if data.dot then
                    data.dot.MaxDistance = ChamsMaxDistance
                end
            end
        end
    end
})
SettingsSection:AddToggle('PerformanceMode', {
    Text = "Performance",
    Default = false,
    Tooltip = "Makes chams into a dot and makes billboard simple",
    Callback = function(state) TogglePerformanceMode(state) end
})
SettingsSection:AddToggle('NotifyCuirassierCharge', {
    Text = "Notify Cuirassier Charge",
    Default = false,
    Tooltip = "Sends a notification when a Cuirassier starts charging",
    Callback = function(state) NotifyCuirassierCharge = state end
})

-- PERFORMANCE FIX: Mark ESP Tab initialization as complete
ESPTab_InitComplete = true

-- FIX: Proper config-load refresh (re-run toggle logic after all callbacks settle)
_G.ESP_ForceRefresh = function()
    pcall(function()
        for _, key in SelectedESPs or {} do
            if key then
                if not EnabledESPs[key] then
                    EnabledESPs[key] = true
                    ESPData[key] = ESPData[key] or setmetatable({}, { __mode = "k" })
                    if key == "Cuirassier" then pcall(function() StartCuirassierSpecific() end) end
                end
            end
        end
        if AnyESPEnabled() then
            if not espLoopRunning then
                StartShared()
            else
                ScanAll()
            end
        end
    end)
end

end -- // ESP Tab

do -- // Performance Tab
-- ===== PERFORMANCE TAB =====

local PerformanceTab = Tabs.Misc

local Fpsbooster = PerformanceTab:AddGroupbox({ Side = "Left", Name = "Frames per sometimes", Description = "FPS improvements", IconName = "activity" })

local fpsBoosterEnabled = false
local fpsBoosterConnection = nil

-- Igniter fire preservation (verified against game files):
-- * Ground fire = Part named "IgniterFire" directly under Workspace with
--   CollectionService tag "Fire" (ReplicatedStorage.Client.Modules.Misc
--   special-cases a1.Name == "IgniterFire"). Server clones ParticleEmitters
--   Fire / Glow / GroundFire / Smoke from ReplicatedStorage.GameAssets.
--   Particles.Fire into it + client adds a Sound.
-- * Throw explosion = anything with tag "IgniterExplosion"
--   (ReplicatedStorage.Client.Modules.Particles: FireSmoke1, FireSmoke2,
--   Blaze emitters + PointLight under IgniteRootPart).
-- * Living Igniter lantern flame = inside "Whale Oil Lantern"
--   (ReplicatedFirst.ZombieReplication.ZombieReplications.Igniter.m_Zombie:
--   ParticleEmitter + PointLight + Flame part).
-- Never strip anything under any of these.
local function isIgniterFireObject(obj)
    local cur = obj
    while cur do
        local name = cur.Name
        if name == "IgniterFire" or name == "Whale Oil Lantern" then
            return true
        end
        local ok, tagged = pcall(function()
            return CollectionService:HasTag(cur, "IgniterExplosion")
        end)
        if ok and tagged then
            return true
        end
        cur = cur.Parent
    end
    return false
end

local function processFPSObject(obj)
    pcall(function()
        if isIgniterFireObject(obj) then return end -- preserve Igniter fire
        if obj:IsA("Texture") or obj:IsA("Decal") then
            obj.Transparency = 1
        elseif obj:IsA("SpecialMesh") then
            obj.TextureId = ""
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif obj:IsA("Sky") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

local function applyFPSBoost()
    pcall(function()
        for _, obj in Workspace:GetDescendants() do
            processFPSObject(obj)
        end

        for _, effect in Lighting:GetChildren() do
            pcall(function()
                if effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
                or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect")
                or effect:IsA("DepthOfFieldEffect") then
                    effect:Destroy()
                end
            end)
        end

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        end)
    end)
end

local FPSBoosterToggle = Fpsbooster:AddToggle('FPSBooster', {
    Text = "FPS Booster",
    Default = false,
    Tooltip = "Deletes textures, lighting & particles for maximum FPS.",
    Callback = function(state)
        fpsBoosterEnabled = state
        if state then
            if fpsBoosterConnection then
                pcall(function() fpsBoosterConnection:Disconnect() end)
                fpsBoosterConnection = nil
            end
            applyFPSBoost()
            local _fpsBatch = {}
            local _fpsBatchPending = false
            local function _processFPSBatch()
                _fpsBatchPending = false
                for i = 1, #_fpsBatch do
                    local obj = _fpsBatch[i]
                    _fpsBatch[i] = nil
                    if not fpsBoosterEnabled then break end
                    processFPSObject(obj)
                end
            end
            fpsBoosterConnection = Workspace.DescendantAdded:Connect(function(obj)
                if not fpsBoosterEnabled then return end
                _fpsBatch[#_fpsBatch + 1] = obj
                if not _fpsBatchPending then
                    _fpsBatchPending = true
                    task.defer(_processFPSBatch)
                end
            end)
            Library:Notify({
                Title = "FPS Booster",
                Description = "Textures deleted. Reapplies on map change.",
                Time = 3,
                Icon = "zap"
            })
        else
            if fpsBoosterConnection then
                fpsBoosterConnection:Disconnect()
                fpsBoosterConnection = nil
            end
            Library:Notify({
                Title = "FPS Booster",
                Description = "FPS Booster disabled.",
                Time = 2,
                Icon = "zap-off"
            })
        end
    end
})

_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.FPSBooster = FPSBoosterToggle

local PerfGeneralGroup = PerformanceTab:AddGroupbox({ Side = "Right", Name = "Horses per sometimes", Description = "Horse cleanup", IconName = "settings" })

AutoRemoveHorsesEnabled = false
local autoRemoveConn = nil
local removeTicker = 0

local function removeHorsesOnce()
    pcall(function()
        local sp = Workspace:FindFirstChild("Saint Petersburg")
        if sp and sp:FindFirstChild("Modes") then
            local modes = sp.Modes
            if modes:FindFirstChild("Holdout") and modes.Holdout:FindFirstChild("HorseCarriage") then
                local hc = modes.Holdout.HorseCarriage
                local horses = hc:FindFirstChild("Horses")
                if horses then
                    horses:Destroy()
                end
            end
        end
    end)

    pcall(function()
        local west = Workspace:FindFirstChild("Westminster")
        if west and west:FindFirstChild("Modes") then
            local modes = west.Modes
            if modes:FindFirstChild("Objective") then
                local obj = modes.Objective

                if obj:FindFirstChild("SecondWagon") and obj.SecondWagon:FindFirstChild("Wagon") then
                    local horses = obj.SecondWagon.Wagon:FindFirstChild("Horses")
                    if horses then horses:Destroy() end
                end

                if obj:FindFirstChild("WagonEvent") and obj.WagonEvent:FindFirstChild("Wagon") then
                    local horses = obj.WagonEvent.Wagon:FindFirstChild("Horses")
                    if horses then horses:Destroy() end
                end
            end
        end
    end)
end

local AutoRemoveHorsesToggle = PerfGeneralGroup:AddToggle('AutoRemoveHorses', {
    Text = "Auto Remove Horses",
    Default = false,
    Tooltip = "Removes the horses to reduce lag, mainly on westminster.",
    Callback = function(state)
        AutoRemoveHorsesEnabled = state
        if state then
            pcall(removeHorsesOnce)

            if autoRemoveConn then
                pcall(function() autoRemoveConn:Disconnect() end)
                autoRemoveConn = nil
            end
            removeTicker = 0
            autoRemoveConn = RunService.Heartbeat:Connect(function(dt)
                if not AutoRemoveHorsesEnabled then return end
                removeTicker = removeTicker + (dt or 0)
                if removeTicker >= 1 then
                    removeTicker = 0
                    pcall(removeHorsesOnce)
                end
            end)

            pcall(function()
                if Library then
                    Library:Notify({ Title = "Visual", Description = "Auto Remove Horses enabled", Time = 2, Icon = "trash" })
                end
            end)
        else
            if autoRemoveConn then
                pcall(function() autoRemoveConn:Disconnect() end)
                autoRemoveConn = nil
            end
            pcall(function()
                if Library then
                    Library:Notify({ Title = "Visual", Description = "Auto Remove Horses disabled", Time = 2, Icon = "trash-off" })
                end
            end)
        end
    end
})

_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.AutoRemoveHorses = AutoRemoveHorsesToggle

end -- // Performance Tab

do -- // Kill Aura Tab (merged into Main & Combat)
-- ===== KILL AURA TAB =====

local KillAuraTab = Tabs.Main

-- === Kill Aura + Hitbox Expander (Position-match Barrel Mapping) ===

-- PERFORMANCE FIX: Flag to suppress notifications during UI initialization
local KillAuraTab_InitComplete = false

-- Config
local DEBUG = false

-- State variables (Global for keybind access)
KillAuraEnabled = false
KillAuraRange = 10
KillAuraAttackSpeed = 0.1 -- Default attack speed (seconds)
KillAuraRandomness = 0 -- Random variation (0-1, percentage of attack speed)
KillAura_MaxRange = 30 -- Max range restored to 30 studs
KillAuraAutoLook = false
KillAura_AutoEquipMelee = false
IgnoreSpawningZombies = true
KillAura_HitboxExpanderEnabled = false

-- Swing speed: two independent settings that both write the same
-- "SwingSpeedBuff" NumberValue onto melee tools.
--   SwingSpeedValue    -> standalone Swing Speed (Effects tab)
--   KillAuraSwingSpeed -> Kill Aura's own swing speed (Attack tab)
-- While Kill Aura (or Reach) is on, KillAuraSwingSpeed OVERRIDES the standalone
-- slider instead of stacking with it.
--
-- HOW THE GAME READS IT (ReplicatedStorage.Modules.Weapons.MeleeBase,
-- CalculateBuffScalar / line ~581):
--     v1 = (character:GetAttribute("SwingSpeedScalar") or 1)
--           * (self.Stats.SwingSpeedMultiplier or 1)
--     if tool:FindFirstChild("SwingSpeedBuff") then
--         v1 = v1 * (1 + SwingSpeedBuff.Value * 0.35)
--     end
--     self.buffScalar = self.baseSpeed * v1          -- baseSpeed is 1
-- then buffScalar is used as BOTH the animation playback speed
-- (Anim:Play(0, 1, buffScalar)) and the cooldown divisor
-- (tick() + Anim.Length / buffScalar).
--
-- So SwingSpeedBuff.Value is a MULTIPLIER BONUS, not seconds:
--   0    -> 1.00x (normal swing)
--   1    -> 1.35x
--   2.86 -> 2.00x
-- A negative value is legal and gives a SLOWER swing (min useful is about -0.71
-- for 0.75x, since 1 + v*0.35 must stay > 0).
--
-- The sliders are exposed in "speed" units (1.0 = normal, higher = faster) and
-- converted to the raw buff value here, which is why the old 25/seconds formula
-- was wrong: it produced huge values (25/0.05 = 500 -> 176x) and the slider had
-- no usable effect at the top end.
SwingSpeedEnabled = false        -- Standalone Swing Speed toggle (Effects tab)
SwingSpeedValue = 2.0            -- Standalone swing speed multiplier (1 = normal)
KillAuraSwingSpeed = 2.0         -- Kill Aura swing speed multiplier (1 = normal)

-- MeleeBase applies the buff as (1 + Value * 0.35), so invert that to turn a
-- user-facing speed multiplier into the raw SwingSpeedBuff value.
local function SwingSpeedToBuffValue(speed)
    local s = tonumber(speed) or 1
    if s < 0.05 then s = 0.05 end
    return (s - 1) / 0.35
end

KillAura_SelectedZombieTypes = {
    ["Shambler"] = true,
    ["Bomber"] = false,
    ["Runner"] = true,
    ["Zapper"] = true,
    ["Igniter"] = true,
    ["Cuirassier"] = true
}

KillAura_ZombiePriority = {
    ["Shambler"]   = 0,
    ["Bomber"]     = 0,
    ["Runner"]     = 0,
    ["Zapper"]     = 0,
    ["Igniter"]    = 0,
    ["Cuirassier"] = 0,
}
KillAura_PriorityEnabled = false -- master switch

-- NEW: bayonet setting (global for config)
KillAura_EnableBayonet = false

-- ADDED: Store reference to Hitbox Expander toggle for programmatic control
local HitboxExpanderToggleElement = nil

local KillAura_remotes = setmetatable({}, { __mode = "k" })
local KillAura_lastRemoteScan = 0

-- Primary remote optimization
local KillAura_primaryRemote = nil
local KillAura_remotesCount = 0

local KillAura_weaponRangeOverrides = {
    Pike = 11,
    Axe = 9,
    -- OPTIONAL: tweak musket / bayonet range if you want it a bit longer
    Musket = 15,
}

local function KillAura_valIndicatesTrue(v)
    if not v or v.Value == nil then return false end
    local val = v.Value
    if val == true then return true end
    local n = tonumber(val)
    if n and n > 0 then return true end
    local vs = tostring(val)
    if vs:lower() == "true" then return true end
    if vs == "RunnerAttack" or vs == "RunnerClaw" or vs == "RunnerVomit" then return true end
    return false
end

local function KillAura_isPinnedOrGrabbed()
    local wsPlayers = Workspace:FindFirstChild("Players")
    if not wsPlayers then return false end
    local folder = wsPlayers:FindFirstChild(LocalPlayer and LocalPlayer.Name or "")
    if not folder then return false end
    local userStates = folder:FindFirstChild("UserStates")
    if not userStates then return false end

    local grabbedVal = userStates:FindFirstChild("Grabbed")
    local pinVal = userStates:FindFirstChild("Pin")

    return KillAura_valIndicatesTrue(grabbedVal) or KillAura_valIndicatesTrue(pinVal)
end

-- Helper functions

local function KillAura_isSpawning(model, agent)
    if not (model and model:IsA("Model")) then return false end
    -- Arrey location: Agent/State StringValue
    if agent == nil then agent = model:FindFirstChild("Agent") end
    if agent then
        local state = agent:FindFirstChild("State")
        if state and state:IsA("StringValue") and state.Value == "Spawn" then
            return true
        end
    end
    -- Alternate location: direct State child on the model (other representation)
    local direct = model:FindFirstChild("State")
    if direct and tostring(direct.Value) == "Spawn" then
        return true
    end
    return false
end


local function KillAura_registerRemote(remote)
    if not (remote and remote:IsA("RemoteEvent")) then return nil end
    if not KillAura_remotes[remote] then
        KillAura_remotes[remote] = true
        KillAura_remotesCount = KillAura_remotesCount + 1
    end
    return remote
end

-- Primary remote getter
local function KillAura_getPrimaryRemote()
    if KillAura_primaryRemote and KillAura_remotes[KillAura_primaryRemote] then
        return KillAura_primaryRemote
    end
    for r,_ in KillAura_remotes do
        KillAura_primaryRemote = r
        return r
    end
    return nil
end

-- Remote scanning
local function KillAura_ScanRemotesNow()
    table.clear(KillAura_remotes)
    KillAura_primaryRemote = nil
    KillAura_remotesCount = 0
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in char:GetChildren() do
        if tool:IsA("Tool") then
            for _, c in tool:GetChildren() do
                if KillAura_registerRemote(c) and not KillAura_primaryRemote then
                    KillAura_primaryRemote = c
                end
            end
        end
    end
    KillAura_lastRemoteScan = time()
end

-- Debounce remote scanning to prevent lag when spamming equip/unequip
local KillAura_scanDebounce = false
local function KillAura_DebouncedScan()
    if KillAura_scanDebounce then return end
    KillAura_scanDebounce = true
    task.delay(0.15, function()
        KillAura_scanDebounce = false
        KillAura_ScanRemotesNow()
    end)
end

-- FIX: Store KillAura CharacterAdded connection to prevent accumulation
local killAuraCharConnection = nil
local killAuraChildConnections = {}

local function setupKillAuraCharConnection()
    -- Disconnect old connection if exists
    if killAuraCharConnection then
        pcall(function() killAuraCharConnection:Disconnect() end)
    end
    -- Disconnect old child connections
    for _, conn in killAuraChildConnections do
        pcall(function() conn:Disconnect() end)
    end
    killAuraChildConnections = {}

    -- Create new connection
    killAuraCharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.6)
        KillAura_ScanRemotesNow()
        local c1 = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then KillAura_DebouncedScan() end
        end)
        local c2 = char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then KillAura_DebouncedScan() end
        end)
        table.insert(killAuraChildConnections, c1)
        table.insert(killAuraChildConnections, c2)
    end)
end
setupKillAuraCharConnection()
if LocalPlayer.Character then KillAura_ScanRemotesNow() end

local function KillAura_isGun(tool)
    return isGunTool(tool)
end

-- Helper: detect bayonet-usable tool (Musket) when enabled
local function KillAura_isBayonetTool(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    if not KillAura_EnableBayonet then return false end
    local name = string.lower(tool.Name)
    -- Match Musket / Flintlock (the bayonet weapon module) and any "bayonet" tool
    return name == "musket" or string.find(name, "musket")
        or string.find(name, "flintlock") or string.find(name, "bayonet")
end

local function KillAura_isMelee(tool)
    if not tool or not tool:IsA("Tool") then return false end

    -- Normal rule: guns are not melee
    if KillAura_isGun(tool) and not KillAura_isBayonetTool(tool) then
        return false
    end

    -- If bayonet is enabled and this is a Musket, treat it as melee
    if KillAura_isBayonetTool(tool) then
        return true
    end

    if tool:GetAttribute("Melee") == true then return true end
    if tool:FindFirstChild("Melee") or tool:FindFirstChild("MeleeConfig") then return true end
    local name = string.lower(tool.Name)
    return name:find("axe") or name:find("pike") or name:find("sword") or name:find("sabre") or name:find("bayonet") or name:find("dagger") or name:find("knife")
end

local function KillAura_findMeleeToolIn(container)
    if not container then return nil end
    for _, tool in container:GetChildren() do
        if KillAura_isMelee(tool) then
            return tool
        end
    end
    return nil
end

local function KillAura_hasZombieInRange()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local zombiesFolder = KillAura_getZombiesFolder()
    if not zombiesFolder then return false end
    local pos = root.Position
    local range = KillAuraRange or 10
    local rangeSq = range * range
    for _, z in zombiesFolder:GetChildren() do
        if z:IsA("Model") then
            local zroot = z:FindFirstChild("HumanoidRootPart")
            if zroot then
                local zp = zroot.Position
                local dx, dy, dz = zp.X - pos.X, zp.Y - pos.Y, zp.Z - pos.Z
                if dx*dx + dy*dy + dz*dz <= rangeSq then
                    return true
                end
            end
        end
    end
    return false
end

local function KillAura_getMeleeTool()
    local char = LocalPlayer.Character
    if not char then return nil end

    local equipped = KillAura_findMeleeToolIn(char)
    if equipped then return equipped end

    if _G.ShoveAuraEnabled then
        local anyEquipped = char:FindFirstChildOfClass("Tool")
        if anyEquipped then
            -- Check if the equipped tool has a remote we can use
            local playersFolder = Workspace:FindFirstChild("Players")
            local toolFolder = playersFolder and playersFolder:FindFirstChild(LocalPlayer.Name)
            if toolFolder then
                local remoteFolder = toolFolder:FindFirstChild(anyEquipped.Name)
                if remoteFolder and remoteFolder:FindFirstChild("RemoteEvent") then
                    -- This tool can be used for both - don't switch
                    return anyEquipped
                end
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end

    local stored = KillAura_findMeleeToolIn(backpack)
    -- Safety: only auto-equip when a zombie is actually in range
    if stored and KillAura_AutoEquipMelee and KillAura_hasZombieInRange() then
        -- COORDINATION: Don't equip if Shove Aura recently fired (prevents fighting)
        local coord = _G.AuraCoordination
        if coord and _G.ShoveAuraEnabled then
            local timeSinceShoveAura = time() - (coord.shoveAuraLastFire or 0)
            if timeSinceShoveAura < 0.15 then
                -- Shove Aura just fired, skip equip this cycle
                return nil
            end
        end

        local ok = pcall(function()
            stored.Parent = char
        end)
        if ok then
            task.defer(KillAura_ScanRemotesNow)
            return stored
        end
    end

    return nil
end

local function KillAura_getWeaponRange(tool)
    local range = KillAuraRange
    if not tool then return range end

    local attrRange = tonumber(tool:GetAttribute("Range"))
    if attrRange then
        range = mathMax(range, attrRange)
    end

    local override = KillAura_weaponRangeOverrides[tool.Name]
    if override then
        range = mathMax(range, override)
    end

    return range
end

local function KillAura_getRemoteForTool(tool)
    if tool then
        local remote = getToolRemote(tool)
        if not remote then
            local ok, r = pcall(function() return tool:FindFirstChildWhichIsA("RemoteEvent") end)
            if ok then remote = r end
        end
        if not remote and type(_G.findRemoteForTool) == "function" then
            local ok2, r2 = pcall(_G.findRemoteForTool, tool)
            if ok2 then remote = r2 end
        end
        if remote then
            KillAura_registerRemote(remote)
            KillAura_primaryRemote = remote
            return remote
        end
    end
    return KillAura_getPrimaryRemote()
end

-- Helper: Get zombie type from model (accepts short + full game names)
local KillAura_TYPE_MAP = {
    normal = "Shambler", shambler = "Shambler",
    barrel = "Bomber", bomber = "Bomber",
    fast = "Runner", runner = "Runner",
    sapper = "Zapper", zapper = "Zapper",
    igniter = "Igniter", cuirassier = "Cuirassier",
}
local function KillAura_getZombieType(model, agent)
    if not (model and model:IsA("Model")) then return nil end

    -- Prefer the shared resolver (exported as _G once gun logic loads).
    local shared = _G.GetZombieTypeFromModel
    if type(shared) == "function" and agent == nil then
        local ok, sharedType = pcall(shared, model)
        if ok and sharedType then return sharedType end
    end

    -- Fallback for load order (KillAura section runs before gun section):
    -- Agent folder Type value, then model attribute.
    if agent == nil then agent = model:FindFirstChild("Agent") end
    if agent then
        local typeValue = agent:FindFirstChild("Type")
        if typeValue and typeValue:IsA("StringValue") then
            local hit = KillAura_TYPE_MAP[string.lower(typeValue.Value or "")]
            if hit then return hit end
        end
    end

    -- Fallback: check model attributes
    local attrType = model:GetAttribute("Type")
    if attrType ~= nil then
        local hit = KillAura_TYPE_MAP[string.lower(tostring(attrType))]
        if hit then return hit end
    end

    -- Default to Shambler if no type found
    return "Shambler"
end


local function KillAura_shouldSkipZombie(model)
    if not (model and model:IsA("Model")) then return true end
    -- Spawning rigs can't be killed yet (hits don't register), so when the
    -- ignore-spawning option is on they are skipped for every type.
    if IgnoreSpawningZombies and KillAura_isSpawning(model) then
        return true
    end
    -- Dead-but-lingering rigs can't be killed anymore either.
    local rigHum = model:FindFirstChildOfClass("Humanoid")
    if rigHum and rigHum.Health <= 0 then return true end

    -- Get the zombie type and check if it's selected
    local zombieType = KillAura_getZombieType(model)
    if zombieType and not KillAura_SelectedZombieTypes[zombieType] then
        return true -- Skip this zombie type (not selected)
    end

    return false
end

-- ===== KILL AURA TARGET HELPERS (no UI changes) =====
local KillAura_ATTACK_ANGLE = 180
local function KillAura_isTargetInAngle(myRootPos, myLookVec, targetPos)
    if KillAura_ATTACK_ANGLE >= 360 then return true end
    local dirToTarget = (targetPos - myRootPos).Unit
    local dot = myLookVec:Dot(dirToTarget)
    if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
    local angle = math.deg(math.acos(dot))
    return angle <= KillAura_ATTACK_ANGLE / 2
end

-- Adaptive burst: fewer simultaneous attacks when crowded so the aura keeps
-- firing instead of stalling on remote spam.
local function KillAura_burstForCount(n)
    if n <= 5 then return 5 end
    if n <= 10 then return 3 end
    return 2
end

local function KillAura_attackCmp(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.d2 < b.d2
end

local function KillAura_buildAttackList(targets, targetCount)
    if targetCount == 0 then return targets, 0 end
    local burst = KillAura_burstForCount(targetCount)
    -- Partition bombers (barrel handling), but only when priority is off:
    -- with priority on, pure rank order wins so prioritized types go first.
    local bomberSelected = KillAura_SelectedZombieTypes["Bomber"] == true
    local hasBomber = false
    for i = 1, targetCount do
        if targets[i].zombieType == "Bomber" then hasBomber = true break end
    end
    if bomberSelected and hasBomber and targetCount >= 2 and not KillAura_PriorityEnabled then
        local barrels, normals = {}, {}
        for i = 1, targetCount do
            local e = targets[i]
            if e.zombieType == "Bomber" then barrels[#barrels + 1] = e
            else normals[#normals + 1] = e end
        end
        table.sort(barrels, KillAura_attackCmp)
        table.sort(normals, KillAura_attackCmp)
        local out, n = {}, 0
        -- Rule: closest bomber first, then closest normals
        if #barrels > 0 then n = n + 1 out[n] = barrels[1] end
        for i = 1, #normals do
            if n >= burst then break end
            n = n + 1 out[n] = normals[i]
        end
        -- Fill remainder with other bombers if slots left
        for i = 2, #barrels do
            if n >= burst then break end
            n = n + 1 out[n] = barrels[i]
        end
        return out, n
    end
    -- Default path: sort all by priority rank, then distance
    table.sort(targets, KillAura_attackCmp)
    if targetCount > burst then
        for i = targetCount, burst + 1, -1 do targets[i] = nil end
        return targets, burst
    end
    return targets, targetCount
end

-- Fast mode helper: fires remotes for anti-detection
local function KillAura_performFastAttack(meleeTool, primaryRemote, entry, isBayonet, hrpPos)
    -- Quick validation
    local model = entry.model
    local head = entry.head
    if not model or not model.Parent or not head or not head.Parent then return end

    -- Get attack position (Head.Position is always a Vector3)
    local attackPos = head.Position

    local char = LocalPlayer.Character
    local playerHead = char and char:FindFirstChild("Head")
    local Direction = playerHead and (attackPos - playerHead.Position).Unit or v3new(0, 1, 0)

    -- Fires inline (same tick the target is found), no deferred spawn.
    pcall(function()
        if isBayonet then
            if model and model.Parent then -- Re-validate
                local orig = model:FindFirstChild("Orig")
                local ref = (orig and orig.Value) or model
                primaryRemote:FireServer("ThrustBayonet")
                primaryRemote:FireServer("Bayonet_HitZombie", ref, attackPos, true, "Head", "Down")
                pcall(function()
                    ref:SetAttribute("WepHitID", tick())
                    ref:SetAttribute("WepHitDirection", Direction * 10)
                    ref:SetAttribute("WepHitPos", attackPos)
                end)
            end
        else
            primaryRemote:FireServer("Swing", "Thrust")
            primaryRemote:FireServer("PrepareSwing")
            if model and model.Parent then -- Re-validate
                primaryRemote:FireServer("HitZombieM", model, attackPos, true, attackPos, "Head", Direction)
            end
        end
    end)
end

-- Cached zombies folder reference for speed
local KillAura_zombiesFolder = nil
local KillAura_lastZombieFolderCheck = 0

local function KillAura_getZombiesFolder()
    local now = time()
    if now - KillAura_lastZombieFolderCheck > 2 then
        KillAura_zombiesFolder = Workspace:FindFirstChild("Zombies")
        KillAura_lastZombieFolderCheck = now
    end
    return KillAura_zombiesFolder
end

-- Pre-allocated targets table reused every tick to avoid GC pressure
local _killAuraTargetsBuf = {}

-- Latest attacked models, published for the range visualizer markers.
local KillAura_markedModels = {}

local function KillAura_performKillAura(hrp, minRange)
    if not KillAuraEnabled then return end
    -- Clear stale target markers up front (early returns must not freeze them).
    for i = 1, 5 do KillAura_markedModels[i] = nil end

    local meleeTool = KillAura_getMeleeTool()
    if not meleeTool then return end

    local primaryRemote = KillAura_getRemoteForTool(meleeTool)
    if not primaryRemote then return end

    local isBayonet = KillAura_isBayonetTool(meleeTool)
    local hrpPos = hrp.Position
    local effectiveRange = KillAura_getWeaponRange(meleeTool)
    if minRange and minRange > effectiveRange then
        effectiveRange = minRange
    end
    local rangeSq = effectiveRange * effectiveRange

    local lookVec = hrp.CFrame.LookVector

    -- Use cached zombies folder
    local zombiesFolder = KillAura_getZombiesFolder()
    if not zombiesFolder then return end

    -- Reuse pre-allocated buffer (clear without creating new table)
    local targets = _killAuraTargetsBuf
    local targetCount = 0
    for i = #targets, 1, -1 do targets[i] = nil end

    for _, model in zombiesFolder:GetChildren() do
        if model:IsA("Model") then
            -- Cheap filters first (position), expensive type work last, so
            -- crowded ticks stay fast.
            local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
            if head then
                local headPos = head.Position
                local dx, dy, dz = headPos.X - hrpPos.X, headPos.Y - hrpPos.Y, headPos.Z - hrpPos.Z
                local d2 = dx*dx + dy*dy + dz*dz
                if d2 <= rangeSq and headPos ~= hrpPos
                    and KillAura_isTargetInAngle(hrpPos, lookVec, headPos) then
                    local agent = model:FindFirstChild("Agent")
                    -- Detect type once and store it in the entry to avoid double-calling later
                    local zombieType = KillAura_getZombieType(model, agent)

                    if not zombieType or KillAura_SelectedZombieTypes[zombieType] then
                        -- Skip rigs that can't die yet (still spawning) or anymore
                        -- (already dead but lingering): hits on them never register,
                        -- so aiming at them only wastes the burst. This used to exempt
                        -- Bombers + Cuirassiers; spawning Cuirassiers in particular
                        -- sat unkillable while eating every attack.
                        local zt = zombieType or "Shambler"
                        local shouldSkip = false
                        if IgnoreSpawningZombies and KillAura_isSpawning(model, agent) then
                            shouldSkip = true
                        end
                        if not shouldSkip then
                            local rigHum = model:FindFirstChildOfClass("Humanoid")
                            if rigHum and rigHum.Health <= 0 then
                                shouldSkip = true
                            end
                        end

                        if not shouldSkip then
                            targetCount = targetCount + 1
                            local zr = KillAura_ZombiePriority[zt] or 0
                            if KillAura_PriorityEnabled and zr <= 0 then zr = mathHuge end
                            targets[targetCount] = { model = model, head = head, d2 = d2, zombieType = zt, rank = zr }
                        end
                    end
                end
            end
        end
    end

    if targetCount == 0 then return end

    local attackList, attackN = KillAura_buildAttackList(targets, targetCount)
    -- Publish current targets for the range visualizer markers.
    for i = 1, 5 do KillAura_markedModels[i] = nil end
    for i = 1, mathMin(attackN, 5) do
        local e = attackList[i]
        KillAura_markedModels[i] = (e and e.model and e.model.Parent) and e.model or nil
    end
    if attackN == 0 then return end
    for i = 1, attackN do
        local entry = attackList[i]
        if entry and entry.model and entry.model.Parent and entry.head and entry.head.Parent then
            KillAura_performFastAttack(meleeTool, primaryRemote, entry, isBayonet, hrpPos)
        end
    end
end

local KillAura_autoLookGyro = nil
KillAura_autoLookHasTarget = false -- Global: Track if we have a target (for fly to check)
local AUTO_LOOK_MAX_PITCH_DOWN = 60 -- Maximum degrees to look down (like fly limit)
local AUTO_LOOK_MAX_PITCH_UP = 45 -- Maximum degrees to look up
local autoLook_lastFlyState = false -- Track fly state to detect transitions
local autoLook_cachedHead = nil -- Cached nearest zombie head
local autoLook_cacheTime = 0
local autoLook_turnedOffAutoRotate = false -- restored on cleanup
local autoLook_hadTarget = false -- edge-triggered tracking notices below
local AUTO_LOOK_CACHE_INTERVAL = 0.1 -- Re-scan zombies every 100ms (10fps) instead of every frame

local function KillAura_cleanupAutoLook()
    -- Mark no target
    KillAura_autoLookHasTarget = false

    -- Clean up our own gyro (only used when not flying)
    if KillAura_autoLookGyro then
        local g = KillAura_autoLookGyro
        KillAura_autoLookGyro = nil
        pcall(function() g:Destroy() end)
    end
    -- Also search and destroy any lingering gyros
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local gyro = hrp and hrp:FindFirstChild("ArreyAutoLookGyro")
    if gyro then pcall(function() gyro:Destroy() end) end
    local lookAtt = hrp and hrp:FindFirstChild("ArreyAutoLookAtt")
    if lookAtt then pcall(function() lookAtt:Destroy() end) end
    -- Note: Fly's BodyGyro is NOT touched here - fly loop handles its own gyro
    if autoLook_turnedOffAutoRotate then
        autoLook_turnedOffAutoRotate = false
        pcall(function()
            if not _G.FlyEnabled then
                local char2 = LocalPlayer and LocalPlayer.Character
                local hum2 = char2 and char2:FindFirstChildOfClass("Humanoid")
                if hum2 then hum2.AutoRotate = true end
            end
        end)
    end
end

-- Clean up only the ground gyro (used when transitioning to fly mode)
local function KillAura_cleanupGroundGyro()
    pcall(function()
        if KillAura_autoLookGyro then
            KillAura_autoLookGyro:Destroy()
            KillAura_autoLookGyro = nil
        end
    end)
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local gyro = hrp:FindFirstChild("ArreyAutoLookGyro")
                if gyro then gyro:Destroy() end
                local lookAtt = hrp:FindFirstChild("ArreyAutoLookAtt")
                if lookAtt then lookAtt:Destroy() end
            end
        end
    end)
end

local function KillAura_performAutoLook(hrp)
    -- If disabled, clean up everything and return
    if not KillAuraAutoLook then
        KillAura_cleanupAutoLook()
        autoLook_lastFlyState = _G.FlyEnabled
        return
    end

    -- Detect fly state transition
    local flyStateChanged = (_G.FlyEnabled ~= autoLook_lastFlyState)
    autoLook_lastFlyState = _G.FlyEnabled

    -- If fly state changed, clean up ground gyro to prevent conflicts
    if flyStateChanged then
        KillAura_cleanupGroundGyro()
    end

    local hrpPos = hrp.Position

    -- Find the actual nearest zombie (independent of Kill Aura targeting)
    local zombiesFolder = KillAura_getZombiesFolder()
    if not zombiesFolder then
        KillAura_cleanupAutoLook()
        return
    end

    local nearestHead = nil
    local nearestDistSq = mathHuge
    local nearestRank = mathHuge
    local maxRange = 50 -- Auto look range (independent of kill aura range)
    local maxRangeSq = maxRange * maxRange

    local now = time()
    if now - autoLook_cacheTime >= AUTO_LOOK_CACHE_INTERVAL or not autoLook_cachedHead or not autoLook_cachedHead.Parent then
        autoLook_cacheTime = now
        -- Scan zombies only every 100ms
        for _, model in zombiesFolder:GetChildren() do
            if model:IsA("Model") then
                -- Filter by Kill Aura zombie types (only target selected types)
                local zombieType = KillAura_getZombieType(model)
                if zombieType and not KillAura_SelectedZombieTypes[zombieType] then
                    -- Skip this zombie - not in selected types
                else
                    -- Mirror kill aura: fall back to HumanoidRootPart when a
                    -- model has no Head part, or nothing is ever targeted.
                    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                    if head then
                        local headPos = head.Position
                        local dx, dy, dz = headPos.X - hrpPos.X, headPos.Y - hrpPos.Y, headPos.Z - hrpPos.Z
                        local d2 = dx*dx + dy*dy + dz*dz
                        if d2 <= maxRangeSq then
                            local r = 0
                            if KillAura_PriorityEnabled then
                                r = KillAura_ZombiePriority[zombieType] or 0
                                if r <= 0 then r = mathHuge end
                            end
                            if r < nearestRank or (r == nearestRank and d2 < nearestDistSq) then
                                nearestRank = r
                                nearestDistSq = d2
                                nearestHead = head
                            end
                        end
                    end
                end
            end
        end
        autoLook_cachedHead = nearestHead
    else
        nearestHead = autoLook_cachedHead
    end

    if nearestHead and nearestHead.Parent then
        -- Shiftlock: follow the player's own camera instead of targets.
        -- (Shiftlock holds the mouse centered, so face where they look;
        -- unshiftlocked falls through to nearest-zombie tracking below.)
        -- Checked BEFORE the tracking notice so holding shiftlock never
        -- flaps the notification.
        local shiftLocked = false
        pcall(function()
            shiftLocked = game:GetService("UserInputService").MouseBehavior == Enum.MouseBehavior.LockCenter
        end)
        if shiftLocked then
            KillAura_autoLookHasTarget = false
            local flyingNow = _G.FlyEnabled and _G.FlyBodyGyro and _G.FlyBodyGyro.Parent
            if not flyingNow then
                local cam = game.Workspace.CurrentCamera
                if cam then
                    local lv = cam.CFrame.LookVector
                    if lv.X * lv.X + lv.Z * lv.Z > 0.0001 then
                        hrp.CFrame = CFrame.lookAt(hrpPos, hrpPos + v3new(lv.X, 0, lv.Z))
                    end
                end
            end
            return
        end
        if not autoLook_hadTarget then
            autoLook_hadTarget = true
            Library:Notify({ Title = "Auto Look", Description = "Tracking target", Time = 2, Icon = "eye" })
        end
        -- Stop the humanoid auto-rotating us back (it fights the aligner
        -- and makes it look like nothing happens while moving).
        pcall(function()
            local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.AutoRotate then
                hum.AutoRotate = false
                autoLook_turnedOffAutoRotate = true
            end
        end)
        local targetPos = nearestHead.Position
        local direction = (targetPos - hrpPos)

        if direction.X * direction.X + direction.Y * direction.Y + direction.Z * direction.Z > 0.01 then
            local targetCFrame

            -- Check if flying (FlyEnabled AND FlyBodyGyro exists)
            local isFlying = _G.FlyEnabled and _G.FlyBodyGyro and _G.FlyBodyGyro.Parent

            if isFlying then
                local horizontalDist = mathSqrt(direction.X * direction.X + direction.Z * direction.Z)
                local verticalDist = direction.Y
                local pitchRad = math.atan2(-verticalDist, horizontalDist) -- Negative because down is negative Y
                local pitchDeg = math.deg(pitchRad)

                -- Clamp pitch to limits
                local clampedPitchDeg = mathClamp(pitchDeg, -AUTO_LOOK_MAX_PITCH_UP, AUTO_LOOK_MAX_PITCH_DOWN)
                local clampedPitchRad = mathRad(clampedPitchDeg)

                -- Calculate the look-at position with clamped pitch
                local horizontalDir = v3new(direction.X, 0, direction.Z)
                if horizontalDir.Magnitude > 0.01 then
                    horizontalDir = horizontalDir.Unit
                else
                    horizontalDir = hrp.CFrame.LookVector * v3new(1, 0, 1)
                    if horizontalDir.Magnitude > 0.01 then horizontalDir = horizontalDir.Unit else horizontalDir = v3new(1, 0, 0) end
                end

                -- Create look-at point at clamped pitch angle
                local lookDist = 10 -- Arbitrary distance for look-at calculation
                local clampedY = -math.sin(clampedPitchRad) * lookDist
                local clampedHorizontal = math.cos(clampedPitchRad) * lookDist
                local lookAt = hrpPos + horizontalDir * clampedHorizontal + v3new(0, clampedY, 0)

                targetCFrame = CFrame.lookAt(hrpPos, lookAt)

                -- Use Fly's BodyGyro directly
                KillAura_autoLookHasTarget = true
                _G.FlyBodyGyro.CFrame = targetCFrame

                -- Destroy our own gyro if it exists (not needed when flying)
                if KillAura_autoLookGyro and KillAura_autoLookGyro.Parent then
                    KillAura_autoLookGyro:Destroy()
                    KillAura_autoLookGyro = nil
                end
            else
                -- NOT FLYING: rotate by direct CFrame write. (Physics
                -- aligners do not actuate this character, verified live,
                -- so a gyro here would just sit stale. CFrame writes stick.)
                local dxz = v3new(targetPos.X - hrpPos.X, 0, targetPos.Z - hrpPos.Z)
                if dxz.Magnitude < 0.05 then
                    -- Directly above/below: nothing to yaw toward, and
                    -- lookAt would equal our position (CFrame.lookAt errors).
                    KillAura_autoLookHasTarget = true
                    return
                end
                local lookAt = v3new(targetPos.X, hrpPos.Y, targetPos.Z)
                targetCFrame = CFrame.lookAt(hrpPos, lookAt)

                KillAura_autoLookHasTarget = true
                -- Remove any stale aligner so nothing fights the write.
                pcall(function()
                    for _, v in ipairs(hrp:GetChildren()) do
                        if ((v:IsA("AlignOrientation") or v:IsA("BodyGyro")) and v.Name == "ArreyAutoLookGyro")
                            or (v:IsA("Attachment") and v.Name == "ArreyAutoLookAtt") then
                            v:Destroy()
                        end
                    end
                end)
                if KillAura_autoLookGyro then
                    KillAura_autoLookGyro = nil
                end
                hrp.CFrame = targetCFrame
            end
        else
            -- Target too close, cleanup
            if autoLook_hadTarget then
                autoLook_hadTarget = false
                Library:Notify({ Title = "Auto Look", Description = "Target lost", Time = 2, Icon = "eye-off" })
            end
            KillAura_cleanupAutoLook()
        end
    else
        -- No target
        if autoLook_hadTarget then
            autoLook_hadTarget = false
            Library:Notify({ Title = "Auto Look", Description = "No target in range", Time = 2, Icon = "eye-off" })
        end
        KillAura_cleanupAutoLook()
    end
end

local function KillAura_performAutoHead(hrp)
    if not KillAura_HitboxExpanderEnabled then return end
    local wasEnabled = KillAuraEnabled
    KillAuraEnabled = true
    pcall(KillAura_performKillAura, hrp, KillAura_MaxRange)
    KillAuraEnabled = wasEnabled
end

-- ===== Arrey RANGE VISUALIZER =====
if KillAura_ShowRangeVisual == nil then KillAura_ShowRangeVisual = false end
local KillAura_RangeVis = {
    folder = nil, tiles = {}, halos = {}, innerTiles = {}, innerHalos = {},
    edgeMarkers = {}, edgeHalos = {},
    diamond = nil, diamondHalo = nil, disc = nil, markers = {},
    conn = nil, t = 0, TILE_N = 48, INNER_N = 24,
    hidden = false, innerVisible = false,
    rayParams = nil,
}
local Arrey_VIS_IDLE = c3rgb(150, 120, 255) -- violet
local Arrey_VIS_ACTIVE = c3rgb(255, 70, 110) -- Arrey pink-red
local Arrey_VIS_INNER = c3rgb(255, 255, 255) -- white inner ring

local function KillAuraVis_activeRange()
    if KillAuraEnabled and KillAura_HitboxExpanderEnabled then
        return mathMax(KillAuraRange or 10, KillAura_MaxRange or 30)
    elseif KillAuraEnabled then
        return KillAuraRange or 10
    elseif KillAura_HitboxExpanderEnabled then
        return KillAura_MaxRange or 30
    end
    return KillAuraRange or 10
end

-- Inner ring range: only distinct when Reach extends past Kill Aura range.
local function KillAuraVis_innerRange(activeRadius)
    if KillAuraEnabled and KillAura_HitboxExpanderEnabled then
        local inner = KillAuraRange or 10
        if inner < (activeRadius or 0) - 0.5 then return inner end
    end
    return nil
end

local function KillAuraVis_hasTarget(pos, lookVec, radius)
    local zombiesFolder = KillAura_getZombiesFolder()
    if not zombiesFolder then return false end
    local rSq = radius * radius
    for _, m in zombiesFolder:GetChildren() do
        if m:IsA("Model") and not KillAura_shouldSkipZombie(m) then
            local h = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart")
            if h then
                local hp = h.Position
                local dx, dy, dz = hp.X - pos.X, hp.Y - pos.Y, hp.Z - pos.Z
                if dx*dx + dy*dy + dz*dz <= rSq then
                    if KillAura_isTargetInAngle(pos, lookVec, hp) then return true end
                end
            end
        end
    end
    return false
end

local function KillAuraVis_build()
    KillAuraVis_clear()
    local folder = Instance.new("Folder")
    folder.Name = "ArreyAuraRange"
    folder.Parent = Workspace
    for i = 1, KillAura_RangeVis.TILE_N do
        local p = Instance.new("Part")
        p.Name = "KTile"
        p.Shape = Enum.PartType.Block -- square tiles
        p.Size = v3new(1.0, 0.2, 1.0)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Color = Arrey_VIS_IDLE
        p.Transparency = 0.3
        p.Parent = folder
        KillAura_RangeVis.tiles[i] = p
        -- X-ray halo follows the tile automatically, renders through walls
        local halo = Instance.new("BoxHandleAdornment")
        halo.Name = "KXHalo"
        halo.Adornee = p
        halo.AlwaysOnTop = true
        halo.ZIndex = 1
        halo.Size = v3new(1.2, 0.4, 1.2)
        halo.Color3 = Arrey_VIS_IDLE
        halo.Transparency = 0.55
        halo.Parent = folder
        KillAura_RangeVis.halos[i] = halo
    end
    for i = 1, KillAura_RangeVis.INNER_N do -- inner kill-range ring (white)
        local p = Instance.new("Part")
        p.Name = "KInner"
        p.Shape = Enum.PartType.Block
        p.Size = v3new(0.55, 0.15, 0.55)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Color = Arrey_VIS_INNER
        p.Transparency = 1 -- hidden until Reach out-ranges Kill Aura
        p.Parent = folder
        KillAura_RangeVis.innerTiles[i] = p
        local halo = Instance.new("BoxHandleAdornment")
        halo.Name = "KXInner"
        halo.Adornee = p
        halo.AlwaysOnTop = true
        halo.ZIndex = 1
        halo.Size = v3new(0.75, 0.35, 0.75)
        halo.Color3 = Arrey_VIS_INNER
        halo.Transparency = 0.55
        halo.Visible = false -- inner ring starts hidden
        halo.Parent = folder
        KillAura_RangeVis.innerHalos[i] = halo
    end
    -- Filled ground disc (flat cylinder, resized per-frame to match range)
    local disc = Instance.new("Part")
    disc.Name = "KDisc"
    disc.Shape = Enum.PartType.Block
    disc.Size = v3new(0.25, 20, 20)
    disc.Material = Enum.Material.Neon
    disc.Anchored = true
    disc.CanCollide = false
    disc.CanTouch = false
    disc.CanQuery = false
    disc.Color = Arrey_VIS_IDLE
    disc.Transparency = 0.93
    local discMesh = Instance.new("CylinderMesh")
    discMesh.Parent = disc
    disc.Parent = folder
    KillAura_RangeVis.disc = disc
    for i = 1, 2 do -- facing edge markers (front-cone edges, follow look)
        local p = Instance.new("Part")
        p.Name = "KEdge"
        p.Shape = Enum.PartType.Block
        p.Size = v3new(0.5, 1.2, 0.5)
        p.Material = Enum.Material.Neon
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Color = Arrey_VIS_IDLE
        p.Transparency = 0.35
        p.Parent = folder
        KillAura_RangeVis.edgeMarkers[i] = p
        local halo = Instance.new("BoxHandleAdornment")
        halo.Name = "KXEdge"
        halo.Adornee = p
        halo.AlwaysOnTop = true
        halo.ZIndex = 1
        halo.Size = v3new(0.7, 1.4, 0.7)
        halo.Color3 = Arrey_VIS_IDLE
        halo.Transparency = 0.55
        halo.Parent = folder
        KillAura_RangeVis.edgeHalos[i] = halo
    end
    local d = Instance.new("Part") -- spinning center diamond
    d.Name = "KDiamond"
    d.Shape = Enum.PartType.Block
    d.Size = v3new(1.2, 0.2, 1.2)
    d.Material = Enum.Material.Neon
    d.Anchored = true
    d.CanCollide = false
    d.CanTouch = false
    d.CanQuery = false
    d.Color = Arrey_VIS_IDLE
    d.Transparency = 0.25
    d.Parent = folder
    KillAura_RangeVis.diamond = d
    local diamondHalo = Instance.new("BoxHandleAdornment")
    diamondHalo.Name = "KXDia"
    diamondHalo.Adornee = d
    diamondHalo.AlwaysOnTop = true
    diamondHalo.ZIndex = 1
    diamondHalo.Size = v3new(1.45, 0.4, 1.45)
    diamondHalo.Color3 = Arrey_VIS_IDLE
    diamondHalo.Transparency = 0.55
    diamondHalo.Parent = folder
    KillAura_RangeVis.diamondHalo = diamondHalo
    -- Current-target markers (pooled red X-ray highlights)
    for i = 1, 5 do
        local mk = Instance.new("Highlight")
        mk.Name = "KMark"
        mk.FillColor = c3rgb(255, 0, 0)
        mk.OutlineColor = c3rgb(255, 255, 255)
        mk.FillTransparency = 0.5
        mk.OutlineTransparency = 0
        mk.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        mk.Parent = folder
        KillAura_RangeVis.markers[i] = mk
    end
    KillAura_RangeVis.folder = folder
end

function KillAuraVis_clear()
    if KillAura_RangeVis.folder then
        pcall(function() KillAura_RangeVis.folder:Destroy() end)
    end
    KillAura_RangeVis.folder = nil
    table.clear(KillAura_RangeVis.tiles)
    table.clear(KillAura_RangeVis.halos)
    table.clear(KillAura_RangeVis.innerTiles)
    table.clear(KillAura_RangeVis.innerHalos)
    table.clear(KillAura_RangeVis.edgeMarkers)
    table.clear(KillAura_RangeVis.edgeHalos)
    KillAura_RangeVis.diamondHalo = nil
    for i = 1, #KillAura_RangeVis.markers do
        local mk = KillAura_RangeVis.markers[i]
        if mk then pcall(function() mk:Destroy() end) end
    end
    table.clear(KillAura_RangeVis.markers)
    KillAura_RangeVis.diamond = nil
    KillAura_RangeVis.disc = nil
    KillAura_RangeVis.hidden = false
    KillAura_RangeVis.innerVisible = false
end

local function KillAuraVis_shouldShow()
    return KillAura_ShowRangeVisual == true
        and (KillAuraEnabled or KillAura_HitboxExpanderEnabled)
end

function KillAuraVis_refresh()
    local on = KillAuraVis_shouldShow()
    if on and not KillAura_RangeVis.conn then
        KillAuraVis_build()
        KillAura_RangeVis.t = 0
        if not KillAura_RangeVis.rayParams then
            KillAura_RangeVis.rayParams = RaycastParams.new()
            KillAura_RangeVis.rayParams.FilterType = Enum.RaycastFilterType.Exclude
        end
        KillAura_RangeVis.conn = RunService.RenderStepped:Connect(function(dt)
            if not KillAuraVis_shouldShow() then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            -- Hide while dead/respawning instead of freezing a stale ring mid-air
            if not hrp or not KillAura_RangeVis.folder then
                if KillAura_RangeVis.folder and not KillAura_RangeVis.hidden then
                    KillAura_RangeVis.folder.Parent = nil
                    KillAura_RangeVis.hidden = true
                end
                return
            end
            if KillAura_RangeVis.hidden then
                KillAura_RangeVis.folder.Parent = Workspace
                KillAura_RangeVis.hidden = false
            end
            local pos = hrp.Position
            local lookVec = hrp.CFrame.LookVector
            local radius = KillAuraVis_activeRange()
            local innerR = KillAuraVis_innerRange(radius)
            KillAura_RangeVis.t = KillAura_RangeVis.t + (dt or 0.016)
            local t = KillAura_RangeVis.t
            local active = KillAuraVis_hasTarget(pos, lookVec, radius)
            local col = active and Arrey_VIS_ACTIVE or Arrey_VIS_IDLE
            -- Ring rides at HRP/torso height (no ground raycast), slow rotation
            local rot = -t * 0.45
            local baseY = pos.Y
            local n = #KillAura_RangeVis.tiles
            for i = 1, n do
                local tile = KillAura_RangeVis.tiles[i]
                if tile then
                    local a = (i / n) * math.pi * 2 + rot
                    tile.Position = v3new(pos.X + math.cos(a) * radius, baseY, pos.Z + math.sin(a) * radius)
                    tile.Color = col
                    local halo = KillAura_RangeVis.halos[i]
                    if halo then halo.Color3 = col end
                    -- Traveling wave transparency around the ring
                    tile.Transparency = 0.25 + 0.45 * (0.5 + 0.5 * math.sin(t * 4 - i * 0.55))
                end
            end
            -- Inner kill-range ring (only when Reach out-ranges Kill Aura)
            local showInner = innerR ~= nil
            if showInner ~= KillAura_RangeVis.innerVisible then
                KillAura_RangeVis.innerVisible = showInner
                if not showInner then
                    for j = 1, #KillAura_RangeVis.innerTiles do
                        local ip = KillAura_RangeVis.innerTiles[j]
                        if ip then ip.Transparency = 1 end
                    end
                    for j = 1, #KillAura_RangeVis.innerHalos do
                        local h = KillAura_RangeVis.innerHalos[j]
                        if h then h.Visible = false end
                    end
                else
                    for j = 1, #KillAura_RangeVis.innerHalos do
                        local h = KillAura_RangeVis.innerHalos[j]
                        if h then h.Visible = true end
                    end
                end
            end
            if showInner then
                local m = #KillAura_RangeVis.innerTiles
                for j = 1, m do
                    local ip = KillAura_RangeVis.innerTiles[j]
                    if ip then
                        local a = (j / m) * math.pi * 2 - rot * 0.7
                        ip.Position = v3new(pos.X + math.cos(a) * innerR, baseY, pos.Z + math.sin(a) * innerR)
                        ip.Transparency = 0.3 + 0.3 * (0.5 + 0.5 * math.sin(t * 3 + j * 0.6))
                        local halo = KillAura_RangeVis.innerHalos[j]
                        if halo then halo.Color3 = ip.Color end
                    end
                end
            end
            -- Filled ground disc marks the actual area covered
            local disc = KillAura_RangeVis.disc
            if disc then
                disc.Size = v3new(0.25, radius * 2, radius * 2)
                disc.CFrame = CFrame.new(v3new(pos.X, pos.Y, pos.Z)) * CFrame.Angles(0, 0, math.pi / 2)
                disc.Color = col
                disc.Transparency = active and 0.88 or 0.93
            end
            local flat = v3new(lookVec.X, 0, lookVec.Z)
            if flat.Magnitude < 0.01 then flat = v3new(1, 0, 0) else flat = flat.Unit end
            local ex, ez = -flat.Z, flat.X
            for k = 1, 2 do
                local marker = KillAura_RangeVis.edgeMarkers[k]
                if marker then
                    local s = (k == 1) and 1 or -1
                    marker.Position = v3new(pos.X + ex * s * radius, pos.Y + 0.7, pos.Z + ez * s * radius)
                    marker.Color = col
                    local halo = KillAura_RangeVis.edgeHalos[k]
                    if halo then halo.Color3 = col end
                end
            end
            local dia = KillAura_RangeVis.diamond
            if dia then
                dia.Position = v3new(pos.X, baseY + 0.1, pos.Z)
                dia.CFrame = CFrame.new(dia.Position) * CFrame.Angles(0, t * 1.8, 0)
                dia.Color = col
                if KillAura_RangeVis.diamondHalo then
                    KillAura_RangeVis.diamondHalo.Color3 = col
                end
            end
            -- Current-target markers (red X-ray highlights)
            local marks = KillAura_RangeVis.markers
            for mi = 1, 5 do
                local mk = marks[mi]
                if mk then
                    local tm = KillAura_markedModels[mi]
                    if tm and tm.Parent and tm:IsA("Model") then
                        if mk.Adornee ~= tm then mk.Adornee = tm end
                    elseif mk.Adornee ~= nil then
                        mk.Adornee = nil
                    end
                end
            end
        end)
    elseif not on and KillAura_RangeVis.conn then
        pcall(function() KillAura_RangeVis.conn:Disconnect() end)
        KillAura_RangeVis.conn = nil
        KillAuraVis_clear()
    elseif on and KillAura_RangeVis.folder == nil then
        KillAuraVis_build()
    end
end

local KillAura_swingBuffCache = setmetatable({}, { __mode = "k" }) -- tool -> SwingSpeedBuff

-- Is the swing-speed buff wanted right now? Kill Aura and the standalone
-- Combat swing toggle both feed the same buff.
local function KillAura_swingBuffActive()
    if KillAuraEnabled or KillAura_HitboxExpanderEnabled then return true end
    if SwingSpeedEnabled then return true end
    if HitDraculaEnabled then return true end
    return false
end

-- Kill Aura (or Reach) OVERRIDES the standalone swing setting while it is on.
-- Dracula aura also feeds the same buff so both auras swing identically.
local function KillAura_swingBuffValue()
    if KillAuraEnabled or KillAura_HitboxExpanderEnabled or HitDraculaEnabled then
        return SwingSpeedToBuffValue(KillAuraSwingSpeed)
    end
    if SwingSpeedEnabled then
        return SwingSpeedToBuffValue(SwingSpeedValue)
    end
    return nil
end

-- Applied from the single unified KillAura heartbeat below (no second loop).
local function KillAura_applySwingBuff(char)
    if not char then return end
    if not KillAura_swingBuffActive() then return end
    local buffValue = KillAura_swingBuffValue()
    if not buffValue then return end
    for _, tool in char:GetChildren() do
        if tool:IsA("Tool") and KillAura_isMelee(tool) then
            local buff = KillAura_swingBuffCache[tool]
            if not buff or buff.Parent ~= tool then
                buff = tool:FindFirstChild("SwingSpeedBuff")
                if not buff then
                    buff = Instance.new("NumberValue")
                    buff.Name = "SwingSpeedBuff"
                    buff.Parent = tool
                end
                KillAura_swingBuffCache[tool] = buff
            end
            buff.Value = buffValue
        end
    end
end
local function KillAura_updateSwingSpeed()
    -- Buffs are applied by the unified heartbeat; here only clean up when off.
    -- Loop lifecycle is owned by refreshKillAuraHeartbeat (AutoLook may need it).
    if not KillAura_swingBuffActive() then
        local char = LocalPlayer.Character
        if char then
            for _, tool in char:GetChildren() do
                if tool:IsA("Tool") then
                    local buff = tool:FindFirstChild("SwingSpeedBuff")
                    if buff then buff:Destroy() end
                end
            end
        end
    end
end

-- Heartbeat loop - continuous (deferred to prevent load freeze)
local KillAura_nextTick = 0
local killAuraHeartbeatConn = nil -- stored so it can be disconnected if needed

local function stopKillAuraHeartbeat()
    if killAuraHeartbeatConn then
        pcall(function() killAuraHeartbeatConn:Disconnect() end)
        killAuraHeartbeatConn = nil
    end
end

local function startKillAuraHeartbeat()
    if killAuraHeartbeatConn then return end
    killAuraHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not KillAuraEnabled and not KillAura_HitboxExpanderEnabled
            and not KillAuraAutoLook and not KillAura_swingBuffActive() then return end

        local char = LocalPlayer.Character
        if not char then return end

        -- Swing-speed buffs ride on this same heartbeat (no second loop)
        KillAura_applySwingBuff(char)

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if KillAuraAutoLook then
            KillAura_performAutoLook(hrp)
        end

        -- PERFORMANCE: Skip attack logic if both features are disabled
        if not KillAuraEnabled and not KillAura_HitboxExpanderEnabled then return end

        -- Pause attacks while grabbed/pinned (but Auto Look already ran above)
        if KillAura_isPinnedOrGrabbed() then return end

        local now = time()

        -- COORDINATION: Check if Shove Aura just fired (avoid overlapping)
        local coord = _G.AuraCoordination
        if coord then
            local timeSinceShoveAura = now - (coord.shoveAuraLastFire or 0)
            -- If Shove Aura fired very recently and is enabled, tiny delay
            if _G.ShoveAuraEnabled and timeSinceShoveAura < 0.02 then
                return -- Skip this frame, try next heartbeat
            end
        end

        -- Attack speed throttle
        if now < KillAura_nextTick then return end

        -- Delay based on attack speed with optional random variation
        local baseDelay = KillAuraAttackSpeed
        if KillAuraRandomness > 0 then
            local variation = baseDelay * KillAuraRandomness
            baseDelay = baseDelay + (math.random() * variation * 2 - variation)
        end

        KillAura_nextTick = now + baseDelay

        -- Scan remotes periodically
        if now - KillAura_lastRemoteScan > 2 then KillAura_ScanRemotesNow() end

        -- COORDINATION: Mark when Kill Aura fires
        if coord then
            coord.killAuraLastFire = now
        end

        if KillAuraEnabled then
            local reachMinRange = KillAura_HitboxExpanderEnabled and KillAura_MaxRange or nil
            KillAura_performKillAura(hrp, reachMinRange)
        elseif KillAura_HitboxExpanderEnabled then
            KillAura_performAutoHead(hrp)
        end
    end)
end

local function refreshKillAuraHeartbeat()
    if KillAuraEnabled or KillAura_HitboxExpanderEnabled or KillAuraAutoLook or SwingSpeedEnabled or HitDraculaEnabled then
        startKillAuraHeartbeat()
    else
        stopKillAuraHeartbeat()
    end
    pcall(KillAuraVis_refresh)
    pcall(KillAura_updateSwingSpeed)
end
_G.ArreyRefreshKillAuraHeartbeat = refreshKillAuraHeartbeat
-- Shared Kill Aura method for event bosses (Dracula reuses the exact same
-- tool resolution + remote protocol instead of its own divergent packets).
_G.ArreyKillAura = {
    getMeleeTool = KillAura_getMeleeTool,
    getRemoteForTool = KillAura_getRemoteForTool,
    isBayonetTool = KillAura_isBayonetTool,
    isMelee = KillAura_isMelee,
}

task.defer(function()
    task.wait(0.5) -- Stagger start
    refreshKillAuraHeartbeat()
end)

-- ===== AURA ATTACK — Kill Aura (master switch + tuning) =====
-- Kill Aura moved into Aura tabbox (Target/Attack tabs)

local KillAuraToggle = Tabs.AuraAttack:AddToggle('KillAura', {
    Text = "Kill Aura",
    Default = false,
    Tooltip = "Automatically Kills Zombie In Range",
    Callback = function(v)
        KillAuraEnabled = v
        refreshKillAuraHeartbeat()


        Library:Notify({
            Title = "Kill Aura",
            Description = v and "Kill Aura Enabled" or "Kill Aura Disabled",
            Time = 2,
            Icon = v and "sword" or "x"
        })
    end
})
_G.ArreyToggleElements.KillAura = KillAuraToggle

Tabs.AuraAttack:AddSlider('KillAuraRange', {
    Text = "Range",
    Default = KillAuraRange or 10,
    Min = 5,
    Max = 50,
    Rounding = 1,
    Tooltip = "Range of kill aura.",
    Callback = function(v)
        KillAuraRange = v
    end
})

Tabs.AuraAttack:AddSlider('KillAuraAttackSpeed', {
    Text = "Attack Speed",
    Default = KillAuraAttackSpeed or 0.1,
    Min = 0.05,
    Max = 1,
    Rounding = 3,
    Tooltip = "Seconds between attacks (lower = faster).",
    Callback = function(v)
        KillAuraAttackSpeed = v
    end
})

Tabs.AuraAttack:AddSlider('KillAuraRandomness', {
    Text = "Randomness",
    Default = KillAuraRandomness or 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Tooltip = "Random delay in attack timing.",
    Callback = function(v)
        KillAuraRandomness = v
    end
})

-- Kill Aura's own swing speed. Overrides the standalone Swing slider in the
-- Effects tab while Kill Aura (or Reach) is on.
Tabs.AuraAttack:AddSlider('KillAuraSwingSpeed', {
    Text = "Swing Speed",
    Default = KillAuraSwingSpeed or 2.0,
    Min = 0.5,
    Max = 10,
    Rounding = 2,
    Suffix = "x",
    Description = "Faster swing speed = stronger aura",
    Tooltip = "Swing speed multiplier.",
    Callback = function(v)
        KillAuraSwingSpeed = v
    end
})

Tabs.AuraAttack:AddDivider()

-- ===== AURA ATTACK — Reach (position-match barrel mapping) =====
-- Store toggle element reference and use helper function

HitboxExpanderToggleElement = Tabs.AuraAttack:AddToggle('Reach', {
    Text = "Reach",
    Default = false,
    Tooltip = "Will Reach The Zombie For About 30 studs (Might Be Lower)",
    Callback = function(v)
        KillAura_HitboxExpanderEnabled = v
        refreshKillAuraHeartbeat()
        Library:Notify({
            Title = "Reach",
            Description = v and "Reach Enabled" or "Reach Disabled",
            Time = 2,
            Icon = v and "scan" or "x"
        })
    end
})
_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.Reach = HitboxExpanderToggleElement

Tabs.AuraAttack:AddSlider('ReachRange', {
    Text = "Reach Range",
    Default = KillAura_MaxRange or 30,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Tooltip = "Range of Reach",
    Callback = function(v)
        KillAura_MaxRange = v
    end
})

Tabs.AuraAttack:AddDivider()

-- ===== AURA TARGET — Weapon setup (auto-equip + bayonet) =====
local AutoEquipMeleeToggle = Tabs.AuraTarget:AddToggle('AutoEquipMelee', {
    Text = "Auto Equip Melee",
    Default = KillAura_AutoEquipMelee,
    Tooltip = "Automatically equips a melee from backpack when Kill Aura is on.",
    Callback = function(v)
        KillAura_AutoEquipMelee = v
    end
})
_G.ArreyToggleElements.AutoEquipMelee = AutoEquipMeleeToggle

-- NEW: Enable Bayonet Kill Aura setting
local BayonetKillAuraToggle = Tabs.AuraTarget:AddToggle('BayonetKillAura', {
    Text = "Enable Bayonet Kill Aura",
    Default = KillAura_EnableBayonet,
    Tooltip = "Kill aura will use bayonet.",
    Callback = function(v)
        KillAura_EnableBayonet = v
        Library:Notify({
            Title = "Kill Aura",
            Description = v and "Bayonet Kill Aura Enabled" or "Bayonet Kill Aura Disabled",
            Time = 2,
            Icon = v and "sword" or "x"
        })
    end
})
_G.ArreyToggleElements.BayonetKillAura = BayonetKillAuraToggle

Tabs.AuraTarget:AddDivider()

-- ===== AURA TARGET — Which zombies to hit =====
Tabs.AuraTarget:AddDropdown('KillAuraZombieTypes', {
    Text = "Target Zombie Types",
    Multi = true,
    Values = {"Shambler", "Bomber", "Runner", "Zapper", "Igniter", "Cuirassier"},
    Default = {"Shambler", "Runner", "Zapper", "Igniter", "Cuirassier"},
    Tooltip = "Select which zombie types to target",
    Callback = function(selected)
        -- Reset all to false
        for k, _ in KillAura_SelectedZombieTypes do
            KillAura_SelectedZombieTypes[k] = false
        end
        -- Enable selected types (selected is a dict of value->true)
        if type(selected) == "table" then
            for typeName in next, selected do
                KillAura_SelectedZombieTypes[typeName] = true
            end
        end
        if KillAuraTab_InitComplete then
            local count = 0
            for _, v in KillAura_SelectedZombieTypes do
                if v then count = count + 1 end
            end
            Library:Notify({
                Title = "Kill Aura",
                Description = "Targeting " .. count .. " zombie type(s)",
                Time = 2,
                Icon = "target"
            })
        end
    end
})

local SkipSpawningToggle = Tabs.AuraTarget:AddToggle('SkipSpawning', {
    Text = "Ignore Spawning Zombies",
    Default = IgnoreSpawningZombies,
    Tooltip = "Skips zombies that are still spawning (reduces misfires).",
    Callback = function(v)
        IgnoreSpawningZombies = v
        Library:Notify({
            Title = "Kill Aura",
            Description = v and "Spawning zombies ignored" or "Spawning zombies targeted",
            Time = 2,
            Icon = v and "eye-off" or "eye"
        })
    end
})
_G.ArreyToggleElements.SkipSpawning = SkipSpawningToggle

Tabs.AuraTarget:AddDivider()

-- ===== AURA TARGET — Priority (which types first) =====
-- Priority: toggle
Tabs.AuraTarget:AddToggle('KillAuraPriorityEnabled', {
    Text = "Zombie Priority",
    Default = KillAura_PriorityEnabled,
    Tooltip = "When enabled, specific zombie types are targeted before others regardless of distance.",
    Callback = function(v)
        KillAura_PriorityEnabled = v
        if KillAuraTab_InitComplete then
            Library:Notify({
                Title = "Kill Aura",
                Description = v and "Zombie Priority ON" or "Zombie Priority OFF",
                Time = 2,
                Icon = v and "arrow-up-circle" or "circle"
            })
        end
    end
})

-- Priority: which types to prioritise (ordered 1 = highest, 6 = lowest)
Tabs.AuraTarget:AddDropdown('KillAuraPriorityOrder', {
    Text = "Priority Order",
    Multi = true,
    Values = {"Shambler", "Bomber", "Runner", "Zapper", "Igniter", "Cuirassier"},
    Default = {},
    Tooltip = "Select and prioritize zombies to be killed first.",
    Callback = function(selected)
        -- Reset all priorities
        for k in KillAura_ZombiePriority do
            KillAura_ZombiePriority[k] = 0
        end
        local ordered = {}
        if type(selected) == "table" then
            local rank = 1
            for _, typeName in {"Shambler", "Bomber", "Runner", "Zapper", "Igniter", "Cuirassier"} do
                if selected[typeName] then
                    KillAura_ZombiePriority[typeName] = rank
                    rank = rank + 1
                    table.insert(ordered, typeName)
                end
            end
        end
        if KillAuraTab_InitComplete then
            Library:Notify({
                Title = "Kill Aura",
                Description = (#ordered > 0) and ("Priority: " .. table.concat(ordered, " > ")) or "No priority set",
                Time = 2,
                Icon = "list"
            })
        end
    end
})

-- ===== AURA ATTACK — Assists (aim + visuals) =====
local AutoLookToggle = Tabs.AuraAttack:AddToggle('AutoLook', {
    Text = "Auto Look",
    Default = false,
    Tooltip = "Automatically looks at the nearest zombie",
    Callback = function(v)
        KillAuraAutoLook = v
        if not v then
            -- Immediately cleanup when disabled
            KillAura_cleanupAutoLook()
        end
        refreshKillAuraHeartbeat()
        Library:Notify({
            Title = "Kill Aura",
            Description = v and "Auto Look ON" or "Auto Look OFF",
            Time = 2,
            Icon = v and "eye" or "eye-off"
        })
    end
})
_G.ArreyToggleElements.AutoLook = AutoLookToggle

local ShowRangeToggle = Tabs.AuraAttack:AddToggle('ShowRangeVisual', {
    Text = "Show Range Visual",
    Default = false,
    Tooltip = "Shows kill aura / reach range ring around you.",
    Callback = function(v)
        KillAura_ShowRangeVisual = v
        pcall(KillAuraVis_refresh)
        Library:Notify({
            Title = "Range Visual",
            Description = v and "Range Visual ON" or "Range Visual OFF",
            Time = 2,
            Icon = v and "eye" or "eye-off"
        })
    end
})
_G.ArreyToggleElements.ShowRangeVisual = ShowRangeToggle

-- ===== AURA EFFECTS — Swing (standalone swing speed, same buff kill aura uses) =====
-- Lives on the Effects tab but is defined here because it drives the shared
-- KillAura heartbeat. While Kill Aura / Reach is on, the Attack tab's
-- "Swing Speed" slider overrides this setting.
local SwingSpeedToggle = Tabs.AuraEffects:AddToggle('SwingSpeed', {
    Text = "Swing Speed",
    Default = SwingSpeedEnabled,
    Description = "Faster swing speed = stronger aura",
    Tooltip = "Faster swing speed = stronger aura",
    Callback = function(v)
        SwingSpeedEnabled = v
        refreshKillAuraHeartbeat()
        Library:Notify({
            Title = "Swing Speed",
            Description = v and "Swing Speed Enabled" or "Swing Speed Disabled",
            Time = 2,
            Icon = v and "zap" or "x"
        })
    end
})
_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.SwingSpeed = SwingSpeedToggle

Tabs.AuraEffects:AddSlider('SwingSpeedValue', {
    Text = "Swing",
    Default = SwingSpeedValue or 2.0,
    Min = 0.5,
    Max = 10,
    Rounding = 2,
    Suffix = "x",
    Tooltip = "Swing speed multiplier.",
    Callback = function(v)
        SwingSpeedValue = v
    end
})

-- PERFORMANCE FIX: Mark KillAura Tab initialization as complete
KillAuraTab_InitComplete = true
ArreyLoadStep(3, "Combat ready...")
end -- // Kill Aura Tab

do -- // Local Player Tab
local LocalPlayerTab = Tabs.LocalPlayer

-- ===== LOCAL PLAYER TAB — Movement (Fly / Noclip / WalkSpeed) =====
    local LP_MovementSection = LocalPlayerTab:AddGroupbox({ Side = "Left", Name = "Movement", Description = "Flight and movement", IconName = "move" })

-- === Fly (Climbing-based smooth flight) ===
FlyEnabled = false -- Global for keybind access
FlySpeed = 25 -- Default fly speed
FlyBodyGyro = nil -- Global so Auto Look can detect flying
local flyBodyPos = nil -- BodyPosition: original fly's physics carrier (server-replicating)
local flyConnection = nil
local flyAnimConnection = nil -- Connection to stop climb animations
local flyStateConnection = nil -- Connection to enforce climbing state
local flyMobileGui = nil -- Mobile UI for up/down buttons
local flyLastMoveTime = 0 -- Track when player last moved (for anti-AFK)
flyMobileUp = false -- Is mobile up button held (global for noclip access)
flyMobileDown = false -- Is mobile down button held (global for noclip access)
local flyAntiAfkRunning = false -- Anti-AFK loop flag
local flyAntiAfkResetting = false -- True during anti-AFK state reset
local flyHealthLockRunning = false -- Health lock loop flag
local flyDiedConnection = nil -- Connection for death reparent

local flyTargetPos = nil
local FLY_PHYS_SPEED_MULT = 0.7
local FLY_TP_SPEED_MULT = 1.0 -- TP fly honors the FlySpeed slider exactly
local FLY_TP_STEP = 15
-- Wall detection for true noclip: 12 radial rays * 3 vertical layers
local noclipOriginalCanCollide = {}
local function noclipDisableCollision(char)
    if not char then return end
    for _, part in char:GetDescendants() do
        if part:IsA("BasePart") and noclipOriginalCanCollide[part] == nil then
            noclipOriginalCanCollide[part] = part.CanCollide
            part.CanCollide = false
        end
    end
end
local function noclipRestoreCollision()
    for part, state in noclipOriginalCanCollide do
        if part and part.Parent then
            part.CanCollide = state
        end
    end
    table.clear(noclipOriginalCanCollide)
end

-- Create mobile fly controls
local function createFlyMobileUI()
    if flyMobileGui and flyMobileGui.Parent then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    flyMobileGui = Instance.new("ScreenGui")
    flyMobileGui.ResetOnSpawn = false
    flyMobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if _G.protectGUI then _G.protectGUI(flyMobileGui) else flyMobileGui.Parent = playerGui end -- Use stealth protection

    -- Container frame on the right side
    local container = Instance.new("Frame")
    -- Use randomized name for anti-detection
    container.Name = "Frame_" .. math.random(10000, 99999)
    container.Size = UDim2.new(0, 70, 0, 150)
    container.Position = UDim2.new(1, -85, 0.5, -75)
    container.BackgroundTransparency = 1
    container.Parent = flyMobileGui

    -- Up button
    local upBtn = Instance.new("TextButton")
    -- Use randomized name
    upBtn.Name = "Button_" .. math.random(10000, 99999)
    upBtn.Size = UDim2.new(1, 0, 0, 65)
    upBtn.Position = UDim2.new(0, 0, 0, 0)
    upBtn.BackgroundColor3 = c3rgb(50, 150, 255)
    upBtn.BackgroundTransparency = 0.3
    upBtn.Text = "▲"
    upBtn.TextColor3 = c3rgb(255, 255, 255)
    upBtn.TextSize = 32
    upBtn.Font = Enum.Font.GothamBold
    upBtn.Parent = container

    local upCorner = Instance.new("UICorner")
    upCorner.CornerRadius = UDim.new(0, 12)
    upCorner.Parent = upBtn

    local upStroke = Instance.new("UIStroke")
    upStroke.Color = c3rgb(255, 255, 255)
    upStroke.Thickness = 2
    upStroke.Transparency = 0.5
    upStroke.Parent = upBtn

    -- Down button
    local downBtn = Instance.new("TextButton")
    -- Use randomized name
    downBtn.Name = "Button_" .. math.random(10000, 99999)
    downBtn.Size = UDim2.new(1, 0, 0, 65)
    downBtn.Position = UDim2.new(0, 0, 0, 85)
    downBtn.BackgroundColor3 = c3rgb(255, 100, 50)
    downBtn.BackgroundTransparency = 0.3
    downBtn.Text = "▼"
    downBtn.TextColor3 = c3rgb(255, 255, 255)
    downBtn.TextSize = 32
    downBtn.Font = Enum.Font.GothamBold
    downBtn.Parent = container

    local downCorner = Instance.new("UICorner")
    downCorner.CornerRadius = UDim.new(0, 12)
    downCorner.Parent = downBtn

    local downStroke = Instance.new("UIStroke")
    downStroke.Color = c3rgb(255, 255, 255)
    downStroke.Thickness = 2
    downStroke.Transparency = 0.5
    downStroke.Parent = downBtn

    -- Connect button events
    upBtn.MouseButton1Down:Connect(function() flyMobileUp = true end)
    upBtn.MouseButton1Up:Connect(function() flyMobileUp = false end)
    upBtn.MouseLeave:Connect(function() flyMobileUp = false end)

    downBtn.MouseButton1Down:Connect(function() flyMobileDown = true end)
    downBtn.MouseButton1Up:Connect(function() flyMobileDown = false end)
    downBtn.MouseLeave:Connect(function() flyMobileDown = false end)

    -- Touch events for mobile
    upBtn.TouchLongPress:Connect(function() flyMobileUp = true end)
    upBtn.TouchEnded:Connect(function() flyMobileUp = false end)

    downBtn.TouchLongPress:Connect(function() flyMobileDown = true end)
    downBtn.TouchEnded:Connect(function() flyMobileDown = false end)
end

local function destroyFlyMobileUI()
    flyMobileUp = false
    flyMobileDown = false
    if flyMobileGui then
        flyMobileGui:Destroy()
        flyMobileGui = nil
    end
end

local stopFly -- forward-declared: startFly + Died handler run before the real teardown below
local function startFly()
    pcall(stopFly, true) -- respawn/re-toggle guard: full teardown, keep armed flag
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Respawn/double-start guard: destroy any stale fly carriers already in
    -- this HRP before creating ours. Otherwise two infinite-force
    -- BodyPositions fight and the character is stuck permanently.
    pcall(function()
        for _, obj in hrp:GetChildren() do
            if obj:IsA("BodyPosition") and obj ~= flyBodyPos then
                local tagged = false
                pcall(function() tagged = obj:HasTag("ArreyFlyBP") end)
                if tagged then obj:Destroy() end
            end
        end
    end)
    -- Our tracked carrier may point at a destroyed instance; drop it so the
    -- loop below can't revive it into the new character.
    if flyBodyPos and not flyBodyPos.Parent then
        pcall(function() flyBodyPos:Destroy() end)
        flyBodyPos = nil
    end

    -- Use Climbing state to bypass anti-cheat
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
    end)

    -- Initialize the teleport target accumulator at our current spot
    flyTargetPos = hrp.Position

    flyBodyPos = Instance.new("BodyPosition")
    flyBodyPos.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BP_" .. math.random(10000, 99999))
    flyBodyPos.MaxForce = v3new(mathHuge, mathHuge, mathHuge)
    flyBodyPos.P = 100000 -- Extremely strong spring → snaps to target within one frame
    flyBodyPos.D = 5000  -- Heavy damping → no oscillation
    flyBodyPos.Position = hrp.Position
    flyBodyPos.Parent = hrp
    -- Tag our carrier so respawns can sweep stale ones (a previous
    -- BodyPosition can outlive its character and end up here fighting us).
    pcall(function() flyBodyPos:AddTag("ArreyFlyBP") end)

    -- Create BodyGyro for full 3D rotation following camera
    FlyBodyGyro = Instance.new("BodyGyro")
    -- Use randomized name
    FlyBodyGyro.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BG_" .. math.random(10000, 99999))
    FlyBodyGyro.MaxTorque = v3new(mathHuge, mathHuge, mathHuge)
    FlyBodyGyro.P = 50000
    FlyBodyGyro.D = 1000
    FlyBodyGyro.Parent = hrp

    _G.FlyEnabled = true
    _G.FlyBodyGyro = FlyBodyGyro

    local blockList = {
        [Enum.HumanoidStateType.Dead] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.Physics] = true,
    }

    local function tryEnforceClimb()
        if not FlyEnabled then return end
        if humanoid and humanoid.Parent and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
            end)
        end
    end

    -- Immediately enforce climbing on start
    tryEnforceClimb()

    flyStateConnection = humanoid.StateChanged:Connect(function(_, newState)
        if not FlyEnabled then return end
        if blockList[newState] then return end
        -- Small delay to avoid rapid flip-flop, then force back to climbing
        task.defer(tryEnforceClimb)
    end)

    -- Mark anti-AFK as running (no separate loop needed now)
    flyAntiAfkRunning = true

    flyHealthLockRunning = true
    task.spawn(function()
        while flyHealthLockRunning do
            if FlyEnabled and humanoid and humanoid.Parent then
                if humanoid.Health <= 0 then
                    pcall(function()
                        humanoid.Health = humanoid.MaxHealth
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                end
            end
            task.wait(0.1)
        end
    end)
    -- True death is server-authoritative: reviving the corpse here only leaves
    -- a desynced model fighting the real respawn (duplicate physics carriers
    -- = stuck permanently). Tear down fully; the respawn handler restarts
    -- clean on the new character if fly is still armed.
    flyDiedConnection = humanoid.Died:Connect(function()
        if FlyEnabled then
            pcall(stopFly, true)
        end
    end)

    noclipDisableCollision(char)
    -- Drop any previous watcher first (double startFly otherwise leaks it).
    if noclipCharCollCon then pcall(function() noclipCharCollCon:Disconnect() end) noclipCharCollCon = nil end
    noclipCharCollCon = char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and noclipOriginalCanCollide[desc] == nil then
            noclipOriginalCanCollide[desc] = desc.CanCollide
            desc.CanCollide = false
        end
    end)

    -- Stop climbing and falling animations when they play (so character looks still)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        flyAnimConnection = animator.AnimationPlayed:Connect(function(track)
            if not FlyEnabled then return end
            local name = track.Name:lower()
            -- Stop climbing and falling animations (plain finds: literals, no patterns)
            if name:find("climb", 1, true) or name:find("fall", 1, true) then
                pcall(function() track:Stop(0) end)
            else
                local animId = ""
                pcall(function() animId = track.Animation and track.Animation.AnimationId or "" end)
                animId = animId:lower()
                if animId:find("climb", 1, true) or animId:find("fall", 1, true) then
                    pcall(function() track:Stop(0) end)
                end
            end
        end)
        -- Stop any currently playing climb or fall animations
        for _, track in animator:GetPlayingAnimationTracks() do
            local name = track.Name:lower()
            if name:find("climb", 1, true) or name:find("fall", 1, true) then
                pcall(function() track:Stop(0) end)
            else
                local animId = ""
                pcall(function() animId = track.Animation and track.Animation.AnimationId or "" end)
                animId = animId:lower()
                if animId:find("climb", 1, true) or animId:find("fall", 1, true) then
                    pcall(function() track:Stop(0) end)
                end
            end
        end
    end

    local flyFrameCounter = 0
    local FLY_STATE_REFRESH_INTERVAL = 30 -- Force refresh every 30 frames (~0.5 sec at 60fps)

    flyConnection = RunService.RenderStepped:Connect(function(dt)
        dt = dt or (1 / 60)
        if not FlyEnabled then return end

        local char = LocalPlayer and LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if _G.AntiTackleSuspendFly then
            if hrp and hrp.Anchored then
                hrp.Anchored = false
            end
            return
        end

        if not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local camera = Workspace.CurrentCamera

        if not hrp or not humanoid or not camera then return end

        if not flyAntiAfkResetting then
            flyFrameCounter = flyFrameCounter + 1
            local ok, state = pcall(function() return humanoid:GetState() end)

            if ok then
                local isDead = state == Enum.HumanoidStateType.Dead
                local isRagdoll = state == Enum.HumanoidStateType.Ragdoll

                if not isDead and not isRagdoll then
                    -- Every frame: if not climbing, force it back
                    if state ~= Enum.HumanoidStateType.Climbing then
                        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Climbing) end)
                    end

                    -- Every N frames: force a state refresh cycle to reset game's internal ladder timer
                    if flyFrameCounter >= FLY_STATE_REFRESH_INTERVAL then
                        flyFrameCounter = 0
                        pcall(function()
                            -- Quickly toggle to Running then back to Climbing to reset the timer
                            humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        end)
                        task.defer(function()
                            if FlyEnabled and humanoid and humanoid.Parent and not flyAntiAfkResetting then
                                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Climbing) end)
                            end
                        end)
                    end
                end
            else
                -- Fallback: attempt to set climbing regardless
                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Climbing) end)
            end
        end

        -- Get camera CFrame for full 3D rotation
        local camCF = camera.CFrame
        local lookVector = camCF.LookVector
        local rightVector = camCF.RightVector

        -- Calculate movement based on input
        local moveDirection = v3new(0, 0, 0)

        -- Check if we're on mobile/touch device
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

        if isMobile then
            -- Mobile: Use humanoid MoveDirection for horizontal movement (from joystick)
            local humMoveDir = humanoid.MoveDirection
            if humMoveDir.X * humMoveDir.X + humMoveDir.Y * humMoveDir.Y + humMoveDir.Z * humMoveDir.Z > 0.01 then
                -- Project move direction onto camera's horizontal plane
                local flatLook = v3new(lookVector.X, 0, lookVector.Z).Unit
                local flatRight = v3new(rightVector.X, 0, rightVector.Z).Unit

                -- Get forward/back and left/right components from humanoid move direction
                local forwardAmount = humMoveDir:Dot(flatLook)
                local rightAmount = humMoveDir:Dot(flatRight)

                -- Apply to full 3D camera vectors for proper pitch following
                moveDirection = moveDirection + lookVector * forwardAmount
                moveDirection = moveDirection + rightVector * rightAmount
            end

            -- Mobile up/down buttons
            if flyMobileUp then
                moveDirection = moveDirection + v3new(0, 1, 0)
            end
            if flyMobileDown then
                moveDirection = moveDirection - v3new(0, 1, 0)
            end
        else
            -- PC: Use keyboard input
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                moveDirection = moveDirection + v3new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                moveDirection = moveDirection - v3new(0, 1, 0)
            end
        end

        -- Normalize and apply speed
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * FlySpeed
            -- Update last move time for anti-AFK (player is actively moving)
            flyLastMoveTime = time()
        end
        local noclipActiveEarly = _G.ArreyNoclipEnabled or false

        local noclipActive = noclipActiveEarly

        if not noclipActive then
            -- === ORIGINAL FLY (BodyPosition / physics) ===
            local moving = moveDirection.Magnitude > 0
            flyTargetPos = hrp.Position
            if flyBodyPos then
                flyBodyPos.Parent = hrp
                flyBodyPos.Position = hrp.Position + moveDirection * FLY_PHYS_SPEED_MULT
            end
            hrp.Anchored = not moving
            if not moving then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = cfNew(hrp.Position) * (hrp.CFrame - hrp.CFrame.Position)
            end
        else
            -- === TP FLY (micro-step loop + true noclip) ===
            if flyBodyPos and flyBodyPos.Parent then
                flyBodyPos.Parent = nil
            end

            if flyTargetPos == nil then
                flyTargetPos = hrp.Position
            end
            flyTargetPos = flyTargetPos + moveDirection * dt * FLY_TP_SPEED_MULT

            local remaining = flyTargetPos - hrp.Position
            local distance = remaining.Magnitude
            local moving = distance > 0.001

            if not moving then
                hrp.Anchored = true
            else
                hrp.Anchored = false -- fast-toggled per micro-step below
            end

            if moving then
                local steps = mathMax(1, mathCeil(distance / FLY_TP_STEP))
                local stepVec = remaining / steps
                local curPos = hrp.Position
                for i = 1, steps do
                    hrp.Anchored = (i % 2 == 0)
                    curPos = curPos + stepVec
                    hrp.CFrame = cfNew(curPos) * (hrp.CFrame - hrp.CFrame.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                hrp.Anchored = false
                flyLastMoveTime = time()
            else
                hrp.CFrame = cfNew(flyTargetPos) * (hrp.CFrame - hrp.CFrame.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = cfNew(flyTargetPos) * (hrp.CFrame - hrp.CFrame.Position)
            end
        end

        if FlyBodyGyro and FlyBodyGyro.Parent then
            if not (KillAuraAutoLook and KillAura_autoLookHasTarget) then
                FlyBodyGyro.CFrame = camCF
            end
        end
    end)
end

stopFly = function(keepEnabled)
    -- Stop anti-AFK loop
    flyAntiAfkRunning = false
    flyAntiAfkResetting = false

    -- Stop health lock + death reparent
    flyHealthLockRunning = false
    if flyDiedConnection then
        flyDiedConnection:Disconnect()
        flyDiedConnection = nil
    end

    -- Disconnect the fly loop
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    -- Disconnect animation stopper
    if flyAnimConnection then
        flyAnimConnection:Disconnect()
        flyAnimConnection = nil
    end

    -- Disconnect state enforcer
    if flyStateConnection then
        flyStateConnection:Disconnect()
        flyStateConnection = nil
    end

    -- Remove BodyPosition (original fly's physics carrier)
    if flyBodyPos then
        flyBodyPos:Destroy()
        flyBodyPos = nil
    end
    -- Reset teleport accumulator for next start
    flyTargetPos = nil

    -- Remove BodyGyro
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
        FlyBodyGyro = nil
    end

    -- FIX: clear the globals Auto Look uses to detect flying.
    -- keepEnabled (death/respawn guard) preserves the armed flag so the
    -- respawn handler restarts clean; manual toggle-off clears it.
    _G.FlyBodyGyro = nil
    if not keepEnabled then
        _G.FlyEnabled = false
    end

    -- Clean up Auto Look BodyGyro if it exists (since fly is stopping)
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
            local autoLookGyro = hrp:FindFirstChild("ArreyAutoLookGyro")
            if autoLookGyro then
                autoLookGyro:Destroy()
            end
        end
    end

    -- Restore CanCollide on every body part
    if noclipCharCollCon then
        pcall(function() noclipCharCollCon:Disconnect() end)
        noclipCharCollCon = nil
    end
    pcall(noclipRestoreCollision)
    -- Reset humanoid state to normal
    char = LocalPlayer and LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
            -- Force back to running state after a brief moment
            task.delay(0.1, function()
                pcall(function()
                    if humanoid and humanoid.Parent then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
            end)
        end
    end
end

-- Handle character respawn
_G.ArreyConns = _G.ArreyConns or {}
local flyLastRespawnStart = 0
if _G.ArreyConns.flyRespawn then pcall(function() _G.ArreyConns.flyRespawn:Disconnect() end) end
_G.ArreyConns.flyRespawn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    if FlyEnabled then
        -- Death teardown already ran via Died (toggle stays on). Wait for the
        -- new model to be fully built, then restart ONLY on the live
        -- character. Stale/double events must never double-start carriers.
        local hum = newChar:WaitForChild("Humanoid", 5)
        local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if not FlyEnabled then return end
        if LocalPlayer.Character ~= newChar then return end
        if not hum or not hrp then return end
        task.wait(0.5)
        if not FlyEnabled then return end
        if LocalPlayer.Character ~= newChar then return end
        local now = time()
        if now - flyLastRespawnStart < 1 then return end
        flyLastRespawnStart = now
        startFly()
    end
end)

local FlyToggle = LP_MovementSection:AddToggle('Fly', {
    Text = "Fly",
    Default = false,
    Tooltip = "Fly Bypass.",
    Callback = function(state)
        FlyEnabled = state

        if state then
            startFly()
            -- Unlock Noclip toggle when Fly is enabled
            if _G.ArreyToggleElements and _G.ArreyToggleElements.NoclipBypass then
                pcall(function()
                    local noclipToggle = _G.ArreyToggleElements.NoclipBypass
                    noclipToggle:SetDisabled(false)
                end)
            end
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Fly enabled.",
                Time = 3,
                Icon = "plane",
            })
        else
            stopFly()
            -- Force stop noclip directly (don't just set toggle - call the function)
            if _G.ArreyStopNoclip then
                pcall(_G.ArreyStopNoclip)
            end
            -- Also update the toggle UI to reflect disabled state
            if _G.ArreyToggleElements and _G.ArreyToggleElements.NoclipBypass then
                pcall(function()
                    _G.ArreyToggleElements.NoclipBypass:SetValue(false)
                    _G.ArreyToggleElements.NoclipBypass:SetDisabled(true)
                end)
            end
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Fly disabled.",
                Time = 2,
                Icon = "plane-landing",
            })
        end
    end
})

-- Register Fly toggle for mobile button and keybinds
_G.ArreyToggleElements = _G.ArreyToggleElements or {}
_G.ArreyToggleElements.Fly = FlyToggle

-- === Visual Noclip Bypass v3 (CFrame Fly Method) ===

local NoclipEnabled = false
_G.ArreyNoclipEnabled = false -- Global reference for keybinds
local noclipCFlyConn = nil
local noclipCollisionConn = nil

local lastNoclipPosition = nil -- Where we are visually (client)
local serverNoclipPosition = nil -- Where server thinks we are

-- All parts for collision disable
_G.NOCLIP_PARTS = {
    "Head", "Torso", "HumanoidRootPart",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

-- Raycast params for wall detection
local noclipRayParams = nil
local _noclipRayParamsLastRebuild = 0
local _noclipRayParamsPlayerCount = 0
local NOCLIP_RAYPARAMS_REBUILD_INTERVAL = 3 -- Only rebuild every 3 seconds, not every frame

-- Pre-built direction tables (constants, not rebuilt every call)
_G.NOCLIP_DIRECTIONS_18 = {
    v3new(1, 0, 0), v3new(-1, 0, 0),
    v3new(0, 0, 1), v3new(0, 0, -1),
    v3new(0, 1, 0), v3new(0, -1, 0),
    v3new(1, 0, 1).Unit, v3new(1, 0, -1).Unit,
    v3new(-1, 0, 1).Unit, v3new(-1, 0, -1).Unit,
    v3new(1, 1, 0).Unit, v3new(-1, 1, 0).Unit,
    v3new(0, 1, 1).Unit, v3new(0, 1, -1).Unit,
    v3new(1, -1, 0).Unit, v3new(-1, -1, 0).Unit,
    v3new(0, -1, 1).Unit, v3new(0, -1, -1).Unit,
}

local function setupNoclipRayParams()
    local now = time()
    local playerCount = #Players:GetPlayers()
    -- Only rebuild if params don't exist, or enough time has passed, or player count changed
    if noclipRayParams and (now - _noclipRayParamsLastRebuild < NOCLIP_RAYPARAMS_REBUILD_INTERVAL) and (playerCount == _noclipRayParamsPlayerCount) then
        return
    end
    _noclipRayParamsLastRebuild = now
    _noclipRayParamsPlayerCount = playerCount

    noclipRayParams = RaycastParams.new()
    noclipRayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Build filter list: local player, all other players, zombies
    local filterList = {}

    -- Add local player character
    local char = LocalPlayer.Character
    if char then table.insert(filterList, char) end

    -- Add all other player characters
    for _, plr in Players:GetPlayers() do
        if plr.Character and plr.Character ~= char then
            table.insert(filterList, plr.Character)
        end
    end

    -- Add zombies folder (real zombie hitboxes)
    local zombiesFolder = workspace:FindFirstChild("Zombies")
    if zombiesFolder then table.insert(filterList, zombiesFolder) end

    -- Add Camera folder (visual zombie models)
    local cameraFolder = workspace:FindFirstChild("Camera")
    if cameraFolder then table.insert(filterList, cameraFolder) end

    noclipRayParams.FilterDescendantsInstances = filterList
end

local function startNoclip()
    -- A stale (disconnected) conn from a previous life must not block restart.
    if noclipCFlyConn then
        local alive = false
        pcall(function() alive = noclipCFlyConn.Connected end)
        if alive then return end
        pcall(function() noclipCFlyConn:Disconnect() end)
        noclipCFlyConn = nil
    end

    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return end

    _G.NoclipBypassEnabled = true
    setupNoclipRayParams()

    -- Initialize positions
    serverNoclipPosition = hrp.Position
    lastNoclipPosition = hrp.Position

    noclipCFlyConn = RunService.RenderStepped:Connect(function(deltaTime)
        -- SAFETY: Don't run if noclip is disabled OR if fly is disabled
        if not NoclipEnabled then return end
        if not FlyEnabled then
            -- Fly was disabled but noclip is still on - force stop noclip
            if _G.ArreyStopNoclip then pcall(_G.ArreyStopNoclip) end
            return
        end

        local character = LocalPlayer.Character
        if not character then return end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        -- Track our valid position
        lastNoclipPosition = rootPart.Position
        serverNoclipPosition = rootPart.Position

        _G.NoclipLastValidPosition = serverNoclipPosition
    end)

    local _noclipCollisionChar = nil
    local _noclipCollisionParts = {}
    local function _rebuildNoclipCollisionCache(char)
        _noclipCollisionChar = char
        _noclipCollisionParts = {}
        for _, partName in _G.NOCLIP_PARTS do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                table.insert(_noclipCollisionParts, part)
            end
        end
        for _, child in char:GetChildren() do
            if child:IsA("Accessory") or child:IsA("Hat") then
                local handle = child:FindFirstChild("Handle")
                if handle then table.insert(_noclipCollisionParts, handle) end
            end
        end
    end

    noclipCollisionConn = RunService.Stepped:Connect(function()
        -- SAFETY: Don't run if noclip is disabled OR if fly is disabled
        if not NoclipEnabled then return end
        if not FlyEnabled then
            -- Fly was disabled but noclip is still on - force disable noclip
            NoclipEnabled = false
            _G.ArreyNoclipEnabled = false
            return
        end

        local character = LocalPlayer.Character
        if not character then return end

        -- Rebuild cache if character changed
        if character ~= _noclipCollisionChar then
            _rebuildNoclipCollisionCache(character)
        end

        for _, part in _noclipCollisionParts do
            if part.Parent then
                part.CanCollide = false
            end
        end
    end)
end

-- Make stopNoclip global so fly toggle can call it directly
local function stopNoclip()
    NoclipEnabled = false
    _G.ArreyNoclipEnabled = false
    _G.NoclipBypassEnabled = false
    _G.NoclipLastValidPosition = nil

    -- Clean up connections
    if noclipCFlyConn then
        noclipCFlyConn:Disconnect()
        noclipCFlyConn = nil
    end

    if noclipCollisionConn then
        noclipCollisionConn:Disconnect()
        noclipCollisionConn = nil
    end

    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if hrp then
            hrp.Anchored = false
        end

        if humanoid then
            humanoid.PlatformStand = false
        end

        -- Restore collision on all parts
        for _, partName in _G.NOCLIP_PARTS do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end

    -- Reset state
    lastNoclipPosition = nil
    serverNoclipPosition = nil
end

-- Expose globally so fly toggle can call it
_G.ArreyStopNoclip = stopNoclip

-- Re-setup on respawn
_G.ArreyConns = _G.ArreyConns or {}
if _G.ArreyConns.noclipRespawn then pcall(function() _G.ArreyConns.noclipRespawn:Disconnect() end) end
_G.ArreyConns.noclipRespawn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    lastNoclipPosition = nil
    serverNoclipPosition = nil

    if NoclipEnabled then
        task.wait(0.3)
        startNoclip()
    end
end)

local NoclipToggle = LP_MovementSection:AddToggle('NoclipBypass', {
    Text = "Fly Noclip Bypass",
    Default = false,
    Disabled = true,
    Tooltip = "Fly through walls",
    Callback = function(state)
        NoclipEnabled = state
        _G.ArreyNoclipEnabled = state -- Update global reference for keybinds

        if state then
            startNoclip()
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Noclip enabled - walk into walls freely!",
                Time = 3,
                Icon = "ghost",
            })
        else
            stopNoclip()
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Noclip disabled.",
                Time = 2,
                Icon = "ghost",
            })
        end
    end
})
_G.ArreyToggleElements.NoclipBypass = NoclipToggle

local FlyMobileButtonsEnabled = false
LP_MovementSection:AddToggle('FlyMobileButtons', {
    Text = "Fly Mobile Buttons",
    Default = false,
    Tooltip = "Show buttons on screen for mobile fly controls",
    Callback = function(state)
        FlyMobileButtonsEnabled = state
        if state then
            createFlyMobileUI()
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Mobile fly buttons enabled.",
                Time = 2,
                Icon = "smartphone",
            })
        else
            destroyFlyMobileUI()
            Library:Notify({
                Title = "Server Modifiers",
                Description = "Mobile fly buttons disabled.",
                Time = 2,
                Icon = "smartphone",
            })
        end
    end
})

LP_MovementSection:AddSlider('FlySpeed', {
    Text = "Fly Speed",
    Default = 25,
    Min = 10,
    Max = 35,
    Rounding = 1,
    Tooltip = "Adjust flight speed",
    Callback = function(v)
        FlySpeed = tonumber(v) or 25
    end
})

-- Freecam Fly
do
    -- State variables
    local freecamEnabled = false
    local flySpeed = 50
    local soulTransparency = 0.6
    local soulHoverPosition = v3new()
    local idleThreshold = 0.1

    -- Soul mode variables
    local soulCameraSubject = nil
    local soulModel = nil -- Transparent clone of character
    local originalCameraType = nil
    local originalCameraSubject = nil

    -- Saved positions for teleport
    local savedPositions = {} -- { {name=..., position=Vector3}, ... }
    local selectedPositionIndex = nil -- Currently selected position in dropdown
    local teleportLoopEnabled = false
    local teleportLoopConnection = nil

    -- Input state
    local keysHeld = { W = false, A = false, S = false, D = false, Space = false, Shift = false }
    local moveDir = v3new()

    -- Connections
    local flyRenderConn = nil
    local flyInputBeganConn = nil
    local flyInputEndedConn = nil

    -- UI references (forward declarations)
    local FreecamToggle = nil
    local TeleportDropdown = nil
    local LoopTeleportToggle = nil

    -- Get character parts
    local function getCharParts()
        local char = LocalPlayer.Character
        if not char then return nil, nil, nil end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        return char, rootPart, humanoid
    end

    -- Update movement direction based on CURRENT camera orientation (called every frame)
    local function updateMoveDir()
        local camera = workspace.CurrentCamera
        if not camera then moveDir = v3new(); return end

        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = v3new(0, 1, 0)

        local direction = v3new()

        if keysHeld.W then direction = direction + forward end
        if keysHeld.S then direction = direction - forward end
        if keysHeld.A then direction = direction - right end
        if keysHeld.D then direction = direction + right end
        if keysHeld.Space then direction = direction + up end
        if keysHeld.Shift then direction = direction - up end

        if direction.Magnitude > 0.1 then
            moveDir = direction.Unit * flySpeed
        else
            moveDir = v3new()
        end
    end

    -- Create soul model (blue transparent orb)
    local function createSoulModel(position)
        if soulModel then soulModel:Destroy() end

        -- Create simple blue orb
        soulModel = Instance.new("Part")
        -- Use randomized name for anti-detection
        soulModel.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("Part_" .. math.random(10000, 99999))
        soulModel.Shape = Enum.PartType.Ball
        soulModel.Size = v3new(4, 4, 4)
        soulModel.Position = position
        soulModel.Anchored = true
        soulModel.CanCollide = false
        soulModel.Material = Enum.Material.Neon
        soulModel.Color = c3rgb(50, 150, 255)
        soulModel.Transparency = soulTransparency
        soulModel.Parent = workspace

        return soulModel
    end

    -- Update soul model position
    local function updateSoulModel()
        if not soulModel or not freecamEnabled then return end

        soulModel.Position = soulHoverPosition
    end

    -- Stop teleport loop
    local function stopTeleportLoop()
        teleportLoopEnabled = false
        if teleportLoopConnection then
            teleportLoopConnection:Disconnect()
            teleportLoopConnection = nil
        end
    end

    -- Start teleport loop to selected position
    local function startTeleportLoop()
        if not selectedPositionIndex or not savedPositions[selectedPositionIndex] then
            Library:Notify({ Title = "Loop Teleport", Description = "Select a position from dropdown first!", Time = 3, Icon = "alert-circle" })
            return false
        end

        stopTeleportLoop()
        teleportLoopEnabled = true

        local position = savedPositions[selectedPositionIndex].position

        teleportLoopConnection = RunService.Heartbeat:Connect(function()
            local char, rootPart = getCharParts()
            if not rootPart or not rootPart.Parent then
                stopTeleportLoop()
                return
            end

            local currentRot = rootPart.CFrame - rootPart.CFrame.Position
            rootPart.CFrame = cfNew(position) * currentRot
        end)

        return true
    end

    -- Start freecam mode
    local function startFreecam()
        local char, rootPart, humanoid = getCharParts()
        if not rootPart then return false end

        local camera = workspace.CurrentCamera
        if not camera then return false end

        freecamEnabled = true

        originalCameraType = camera.CameraType
        originalCameraSubject = camera.CameraSubject

        -- Anchor character in place
        rootPart.Anchored = true
        rootPart.AssemblyLinearVelocity = v3new()
        rootPart.AssemblyAngularVelocity = v3new()

        -- Create invisible camera subject for freecam
        soulCameraSubject = Instance.new("Part")
        -- Use randomized name for anti-detection
        soulCameraSubject.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("Part_" .. math.random(10000, 99999))
        soulCameraSubject.Size = v3new(1, 1, 1)
        soulCameraSubject.Transparency = 1
        soulCameraSubject.Anchored = true
        soulCameraSubject.CanCollide = false
        soulCameraSubject.Position = camera.CFrame.Position
        soulCameraSubject.Parent = workspace

        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = soulCameraSubject

        soulHoverPosition = soulCameraSubject.Position

        -- Create soul clone (transparent copy of character)
        createSoulModel(soulHoverPosition)

        -- Connect render loop directly
        if flyRenderConn then flyRenderConn:Disconnect(); flyRenderConn = nil end
        flyRenderConn = RunService.RenderStepped:Connect(function(dt)
            if not freecamEnabled then return end
            updateMoveDir()
            updateSoulModel()
            if soulCameraSubject then
                pcall(function()
                    if moveDir.Magnitude > idleThreshold then
                        soulCameraSubject.CFrame = soulCameraSubject.CFrame + moveDir * dt
                        soulHoverPosition = soulCameraSubject.Position
                    else
                        soulCameraSubject.CFrame = cfNew(soulHoverPosition) * soulCameraSubject.CFrame.Rotation
                    end
                end)
            end
        end)

        return true
    end

    -- Stop freecam mode
    local function stopFreecam()
        freecamEnabled = false

        -- Clean up loop connection
        if flyRenderConn then
            flyRenderConn:Disconnect()
            flyRenderConn = nil
        end

        local char, rootPart, humanoid = getCharParts()
        local camera = workspace.CurrentCamera

        if camera then
            camera.CameraType = originalCameraType or Enum.CameraType.Custom
            camera.CameraSubject = humanoid or originalCameraSubject
        end

        if rootPart then rootPart.Anchored = false end
        if soulCameraSubject then soulCameraSubject:Destroy(); soulCameraSubject = nil end
        if soulModel then soulModel:Destroy(); soulModel = nil end

        -- Reset keys
        for k in keysHeld do keysHeld[k] = false end
        moveDir = v3new()
    end

    -- Refresh dropdown with saved positions
    local function refreshDropdown()
        if TeleportDropdown then
            local names = {}
            for _, p in savedPositions do
                table.insert(names, p.name)
            end
            pcall(function() TeleportDropdown:SetValues(names) end)
        end
    end

    -- Save current position (saves soul position)
    local function saveCurrentPosition()
        if not freecamEnabled then
            Library:Notify({ Title = "Save Position", Description = "Enable Freecam first to scout and save positions!", Time = 3, Icon = "alert-circle" })
            return
        end

        local pos = soulHoverPosition
        local name = "Pos " .. (#savedPositions + 1)
        table.insert(savedPositions, { name = name, position = pos })

        Library:Notify({
            Title = "Position Saved",
            Description = strFormat("%s: (%.0f, %.0f, %.0f)", name, pos.X, pos.Y, pos.Z),
            Time = 3,
            Icon = "map-pin"
        })

        -- Refresh dropdown
        refreshDropdown()
    end

    -- Setup input handlers
    local function setupFlyInput()
        if flyInputBeganConn then flyInputBeganConn:Disconnect() end
        if flyInputEndedConn then flyInputEndedConn:Disconnect() end

        -- Mobile thumbstick tracking
        local isMobile = UserInputService.TouchEnabled

        -- Get move direction from mobile thumbstick/controls
        local function getMobileMovement()
            local success, moveVector = pcall(function()
                local PlayerModule = LocalPlayer:FindFirstChild("PlayerScripts")
                    and LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                if PlayerModule then
                    local ControlModule = require(PlayerModule):GetControls()
                    if ControlModule and ControlModule.GetMoveVector then
                        return ControlModule:GetMoveVector()
                    end
                end
                return v3new()
            end)
            return success and moveVector or v3new()
        end

        -- Update movement direction including mobile input
        updateMoveDir = function()
            local camera = workspace.CurrentCamera
            if not camera then moveDir = v3new(); return end

            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local up = v3new(0, 1, 0)

            local direction = v3new()

            -- Keyboard input
            if keysHeld.W then direction = direction + forward end
            if keysHeld.S then direction = direction - forward end
            if keysHeld.A then direction = direction - right end
            if keysHeld.D then direction = direction + right end
            if keysHeld.Space then direction = direction + up end
            if keysHeld.Shift then direction = direction - up end

            -- Mobile thumbstick input (if no keyboard input)
            if direction.Magnitude < 0.1 and isMobile then
                local mobileMove = getMobileMovement()
                if mobileMove.Magnitude > 0.1 then
                    direction = direction + (right * mobileMove.X)
                    direction = direction + (forward * -mobileMove.Z) -- Negative because Z is inverted
                end
            end

            if direction.Magnitude > 0.1 then
                moveDir = direction.Unit * flySpeed
            else
                moveDir = v3new()
            end
        end

        flyInputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not freecamEnabled then return end

            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.W then keysHeld.W = true
                elseif key == Enum.KeyCode.A then keysHeld.A = true
                elseif key == Enum.KeyCode.S then keysHeld.S = true
                elseif key == Enum.KeyCode.D then keysHeld.D = true
                elseif key == Enum.KeyCode.Space then keysHeld.Space = true
                elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.LeftControl then keysHeld.Shift = true
                end
            end

            -- Mobile: Jump button = go up
            if input.UserInputType == Enum.UserInputType.Touch then
            end
        end)

        flyInputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if not freecamEnabled then return end

            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.W then keysHeld.W = false
                elseif key == Enum.KeyCode.A then keysHeld.A = false
                elseif key == Enum.KeyCode.S then keysHeld.S = false
                elseif key == Enum.KeyCode.D then keysHeld.D = false
                elseif key == Enum.KeyCode.Space then keysHeld.Space = false
                elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.LeftControl then keysHeld.Shift = false
                end
            end
        end)

        -- Mobile: Jump request = go up
        if isMobile then
            local jumpConn = nil
            jumpConn = UserInputService.JumpRequest:Connect(function()
                if freecamEnabled then
                    -- Toggle Space held for 0.3 seconds
                    keysHeld.Space = true
                    task.delay(0.3, function()
                        keysHeld.Space = false
                    end)
                end
            end)

            -- Store connection for cleanup
            _G.FreecamMobileConns = _G.FreecamMobileConns or {}
            table.insert(_G.FreecamMobileConns, jumpConn)
        end
    end

    -- Initialize
    setupFlyInput()

    local freecamCharConnection = nil
    local function setupFreecamCharConnection()
        if freecamCharConnection then
            pcall(function() freecamCharConnection:Disconnect() end)
        end
        freecamCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            if freecamEnabled then
                stopFreecam()
                pcall(function() if FreecamToggle then FreecamToggle:SetValue(false) end end)
            end
            stopTeleportLoop()
            pcall(function() if LoopTeleportToggle then LoopTeleportToggle:SetValue(false) end end)
        end)
    end
    setupFreecamCharConnection()

    -- ===== UI ELEMENTS =====

    -- Freecam Toggle
    FreecamToggle = LP_MovementSection:AddToggle('Freecam', {
        Text = "Freecam Fly",
        Default = false,
        Tooltip = "Freecam Fly to save positions.",
        Callback = function(state)
            if state then
                local success = startFreecam()
                if success then
                    Library:Notify({ Title = "Freecam", Description = "Flying.", Time = 4, Icon = "ghost" })
                else
                    Library:Notify({ Title = "Freecam", Description = "Failed", Time = 3, Icon = "x" })
                    pcall(function() FreecamToggle:SetValue(false) end)
                end
            else
                stopFreecam()
                Library:Notify({ Title = "Freecam", Description = "Freecam disabled", Time = 2, Icon = "x" })
            end
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.Freecam = FreecamToggle

    -- Fly Speed Slider
    LP_MovementSection:AddSlider('FreecamFlySpeed', {
        Text = "Fly Speed",
        Default = 25,
        Min = 10,
        Max = 200,
        Rounding = 1,
        Tooltip = "Adjust freecam fly speed",
        Callback = function(value)
            flySpeed = value
        end
    })

    -- Save Position Button
    LP_MovementSection:AddButton({
        Text = "Save Position",
        Tooltip = "Save current position. Requires Freecam to be active.",
        Func = function()
            saveCurrentPosition()
        end
    })

    -- Select Position Dropdown (just selects, doesn't teleport)
    TeleportDropdown = LP_MovementSection:AddDropdown('SelectPosition', {
        Text = "Select Position",
        Values = {},
        Multi = false,
        Tooltip = "Select a saved position for Loop Teleport",
        Callback = function(selected)
            if not selected or type(selected) ~= "string" or selected == "" then
                selectedPositionIndex = nil
                return
            end

            for i, posData in savedPositions do
                if posData.name == selected then
                    selectedPositionIndex = i
                    Library:Notify({ Title = "Selected", Description = posData.name .. " selected for teleport", Time = 2, Icon = "check" })
                    break
                end
            end
        end
    })

    -- Loop Teleport Toggle
    LoopTeleportToggle = LP_MovementSection:AddToggle('LoopTeleport', {
        Text = "Loop Teleport",
        Default = false,
        Tooltip = "Continuously teleport to selected position",
        Callback = function(state)
            if state then
                -- Exit freecam if active
                if freecamEnabled then
                    stopFreecam()
                    pcall(function() FreecamToggle:SetValue(false) end)
                end

                local success = startTeleportLoop()
                if success then
                    Library:Notify({ Title = "Loop Teleport", Description = "Looping to " .. savedPositions[selectedPositionIndex].name, Time = 3, Icon = "repeat" })
                else
                    pcall(function() LoopTeleportToggle:SetValue(false) end)
                end
            else
                stopTeleportLoop()
                Library:Notify({ Title = "Loop Teleport", Description = "Loop stopped", Time = 2, Icon = "x" })
            end
        end
    })
    _G.ArreyToggleElements.LoopTeleport = LoopTeleportToggle

    -- Clear Saved Positions Button
    LP_MovementSection:AddButton({
        Text = "Clear All Saved Positions",
        Tooltip = "Delete all saved teleport positions",
        Func = function()
            stopTeleportLoop()
            pcall(function() LoopTeleportToggle:SetValue(false) end)
            savedPositions = {}
            selectedPositionIndex = nil

            -- Clear dropdown
            refreshDropdown()

            Library:Notify({ Title = "Cleared", Description = "All saved positions deleted", Time = 2, Icon = "trash-2" })
        end
    })
end

    -- ===== PROTECTION TAB — Self (Server Modifiers) =====
    local LP_SelfSection = Tabs.Protection:AddGroupbox({ Side = "Right", Name = "God mode (kinda)", Description = "Player protection", IconName = "shield" })

    -- === Server Modifiers ===
    noFallDamageEnabled = false -- Global for keybind access
    noFallDamageThread = nil -- Global for keybind access

    function noFallDamageLoop() -- Global for keybind access
        while noFallDamageEnabled do
            task.wait(1)

            local char = LocalPlayer and LocalPlayer.Character
            if not char then
                continue
            end

            -- Guts & BlackPowder style "Health" instance with ForceSelfDamage
            local health = char:FindFirstChild("Health")
            if not health then
                continue
            end

            local forceSelfDamage = health:FindFirstChild("ForceSelfDamage")
            if not forceSelfDamage then
                continue
            end

            -- Send 0 damage repeatedly to neutralize fall damage
            pcall(function()
                forceSelfDamage:FireServer(0)
            end)
        end
    end

    local NoFallDamageToggle = LP_SelfSection:AddToggle('NoFallDamage', {
        Text = "No Fall Damage",
        Default = false,
        Tooltip = "Removes fall damage",
        Callback = function(state)
            noFallDamageEnabled = state

            if state then
                -- (Re)start the loop
                if noFallDamageThread then
                    pcall(task.cancel, noFallDamageThread)
                end

                noFallDamageThread = task.spawn(noFallDamageLoop)

                Library:Notify({
                    Title = "Server Modifiers",
                    Description = "No Fall Damage enabled.",
                    Time = 2,
                    Icon = "shield-check",
                })
            else
                -- Stop the loop
                if noFallDamageThread then
                    pcall(task.cancel, noFallDamageThread)
                    noFallDamageThread = nil
                end

                Library:Notify({
                    Title = "Server Modifiers",
                    Description = "No Fall Damage disabled.",
                    Time = 2,
                    Icon = "shield-off",
                })
            end
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.NoFallDamage = NoFallDamageToggle

    --[[  ANTI BREAK LEGS (improved)  ]]
do
    local _abl_enabled          = false              -- master flag
    local _abl_renderConn = nil          -- RenderStepped connection
    local _abl_charConn   = nil          -- CharacterAdded re-attach
    local ANTI_BREAK_LEGS_FALL_SPEED = -18

    -- Cached per-character state (rebuilt on each respawn)
    local _abl_hum        = nil
    local _abl_root       = nil
    local _abl_brokenLegs = nil   -- ObjectValue / BoolValue in UserStates
    local _abl_userStates = nil

    -- Find and cache relevant instances for the current character
    local function _abl_rebuildCache(char)
        _abl_hum        = char and char:FindFirstChildOfClass("Humanoid")
        _abl_root       = char and char:FindFirstChild("HumanoidRootPart")
        _abl_userStates = LocalPlayer:FindFirstChild("UserStates")
        _abl_brokenLegs = _abl_userStates and _abl_userStates:FindFirstChild("BrokenLegs")
        -- Also try workspace.Players folder
        if not _abl_brokenLegs then
            local wsP = Workspace:FindFirstChild("Players")
            local pFolder = wsP and wsP:FindFirstChild(LocalPlayer.Name)
            local us2 = pFolder and pFolder:FindFirstChild("UserStates")
            _abl_brokenLegs = us2 and us2:FindFirstChild("BrokenLegs")
        end
    end

    -- Cache refresh timer (avoids FindFirstChild every single frame)
    local _abl_cacheTimer = 0
    local CACHE_REFRESH_INTERVAL = 3   -- seconds

    local function _abl_startConn()
        if _abl_renderConn then return end
        _abl_rebuildCache(LocalPlayer.Character)

        _abl_renderConn = RunService.RenderStepped:Connect(function()
            if not _abl_enabled then return end

            -- Periodically refresh cache in case values got re-created after map change
            local now = time()
            if now - _abl_cacheTimer >= CACHE_REFRESH_INTERVAL then
                _abl_cacheTimer = now
                _abl_rebuildCache(LocalPlayer.Character)
            end

            local hum  = _abl_hum
            local root = _abl_root
            if not hum or not hum.Parent then return end
            if not root or not root.Parent then return end

            -- 1. Clear broken-legs flag (write only when true to avoid spam)
            local bl = _abl_brokenLegs
            if bl and bl.Value ~= false then
                pcall(function() bl.Value = false end)
            end

            local floorMat = hum.FloorMaterial
            if floorMat == Enum.Material.Air then
                local yVel = root.AssemblyLinearVelocity.Y
                if yVel < ANTI_BREAK_LEGS_FALL_SPEED then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.Climbing)
                    end)
                end
            end

            if floorMat ~= Enum.Material.Air then
                local yVel = root.AssemblyLinearVelocity.Y
                -- Just landed (floor mat changed this frame) while fast  override
                if yVel < ANTI_BREAK_LEGS_FALL_SPEED * 0.6 then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end)
                end
            end
        end)
    end

    local function _abl_stopConn()
        if _abl_renderConn then
            pcall(function() _abl_renderConn:Disconnect() end)
            _abl_renderConn = nil
        end
    end

    local function _abl_setupCharConn()
        if _abl_charConn then pcall(function() _abl_charConn:Disconnect() end) end
        _abl_charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            _abl_hum = nil; _abl_root = nil
            _abl_brokenLegs = nil; _abl_userStates = nil
            _abl_cacheTimer = 0
            if _abl_enabled then
                task.wait(0.5)   -- wait for UserStates to replicate
                _abl_rebuildCache(newChar)
            end
        end)
    end
    _abl_setupCharConn()

    local AntiBreakLegsToggle = LP_SelfSection:AddToggle('AntiBreakLegs', {
        Text   = "Anti Break Legs",
        Default = false,
        Tooltip = "Prevents broken legs on hard landings.",
        Callback = function(state)
            _abl_enabled = state
            _G.AntiBreakLegsEnabled = state
            if state then
                _abl_startConn()
                Library:Notify({
                    Title   = "Server Modifiers",
                    Description = "Anti Break Legs enabled.",
                    Time = 2,
                    Icon    = "activity"
                })
            else
                _abl_stopConn()
                Library:Notify({
                    Title   = "Server Modifiers",
                    Description = "Anti Break Legs disabled.",
                    Time = 2,
                    Icon    = "activity"
                })
            end
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.AntiBreakLegs = AntiBreakLegsToggle
    -- expose for the Local Player tab shortcut
    _G.Arrey_AntiBreakLegsToggle = AntiBreakLegsToggle
    _G.Arrey_AntiBreakLegsEnabled = function() return _abl_enabled end
end

    -- ------------------------------------------------------------
    -- ------------------------------------------------------------
    local LP_MiscSection = LocalPlayerTab:AddGroupbox({ Side = "Right", Name = "Misc", Description = "Player utilities", IconName = "package" })

    -- === Hotbar Always Visible + Force Equip (tool inventory bar) ===
    -- Game files: PlayerScripts.PlayerModule.BackpackModule drives
    -- PlayerGui.BackpackGui.Backpack.Hotbar (slots 1-0, e.g. Musket/Sabre).
    -- The server hides the bar via the LocalPlayer "GuiEnabled" attribute
    -- (Arrow/Hotbar.Visible = GuiEnabled) and blocks number-key/click equip
    -- while the character carries "NoEquip"/"NoTool" tags
    -- (BackpackModule:147-150, BackpackGui:792-796).
    -- This forces the bar visible and strips both tags every heartbeat (the
    -- server re-adds them), so tools equip at any time.
    -- _G.ArreyForceEquip(name) equips a backpack tool directly.
    local invA = { visible = false, charConn = nil, attrConn = nil, hbConn = nil, propConns = {}, loopToken = 0, saved = nil, applying = false, bmMod = nil, origToggle = nil }
    -- Forward declare: the re-hide hooks below call Apply, so it must resolve
    -- to this local (never a nil global).
    local invAlwaysApply

    local function invHotbarUI()
        if not LocalPlayer then return nil end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local bg = pg and pg:FindFirstChild("BackpackGui")
        local bp = bg and bg:FindFirstChild("Backpack")
        if not bg or not bp then return nil end
        return { gui = bg, pack = bp, hot = bp:FindFirstChild("Hotbar"), arrow = bp:FindFirstChild("Arrow") }
    end

    local function invStripTags()
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                if c:HasTag("NoEquip") then CollectionService:RemoveTag(c, "NoEquip") end
                if c:HasTag("NoTool") then CollectionService:RemoveTag(c, "NoTool") end
            end
        end)
    end

    _G.ArreyForceEquip = _G.ArreyForceEquip or function(name)
        invStripTags()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not bp or not hum then return false end
        local tool = bp:FindFirstChild(name)
        if tool and tool:IsA("Tool") then
            hum:EquipTool(tool)
            return true
        end
        return false
    end

    -- PieceControlManager (pushing cannon, ladders, ropes, objectives...) hides the
    -- whole backpack via BackpackModule.Toggle(false). Swallow hide requests
    -- while enabled so the bar survives stun/pin/push/objective states.
    local function invHookModule()
        if invA.origToggle ~= nil then return end
        pcall(function()
            local bm = require(LocalPlayer.PlayerScripts.PlayerModule.BackpackModule)
            if type(bm) == "table" and type(bm.Toggle) == "function" then
                invA.bmMod = bm
                invA.origToggle = bm.Toggle
                bm.Toggle = function(p1, p2)
                    if invA.visible and p1 == false then return end
                    return invA.origToggle(p1, p2)
                end
            end
        end)
    end

    local function invUnhookModule()
        pcall(function()
            if invA.bmMod and invA.origToggle then
                invA.bmMod.Toggle = invA.origToggle
            end
        end)
        invA.bmMod, invA.origToggle = nil, nil
    end

    local function invAlwaysClearProps()
        if invA.attrConn then pcall(function() invA.attrConn:Disconnect() end) invA.attrConn = nil end
        for i = 1, #invA.propConns do
            pcall(function() invA.propConns[i]:Disconnect() end)
            invA.propConns[i] = nil
        end
    end

    local function invAlwaysHook()
        invAlwaysClearProps()
        -- Re-show the instant the server hides the bar (menu/dead states).
        pcall(function()
            local u = invHotbarUI()
            if not u then return end
            if u.hot then
                invA.propConns[#invA.propConns + 1] = u.hot:GetPropertyChangedSignal("Visible"):Connect(function()
                    if invA.visible and not invA.applying then invAlwaysApply() end
                end)
            end
            if u.pack then
                invA.propConns[#invA.propConns + 1] = u.pack:GetPropertyChangedSignal("Visible"):Connect(function()
                    if invA.visible and not invA.applying then invAlwaysApply() end
                end)
            end
            invA.propConns[#invA.propConns + 1] = u.gui:GetPropertyChangedSignal("Enabled"):Connect(function()
                if invA.visible and not invA.applying then invAlwaysApply() end
            end)
        end)
        pcall(function()
            invA.attrConn = LocalPlayer:GetAttributeChangedSignal("GuiEnabled"):Connect(function()
                if invA.visible and not invA.applying then invAlwaysApply() end
            end)
        end)
    end

    invAlwaysApply = function()
        if not invA.visible or invA.applying then return end
        invA.applying = true
        pcall(function()
            invStripTags()
            -- Drive the game's own listeners: GuiEnabled shows Arrow/Hotbar.
            if LocalPlayer:GetAttribute("GuiEnabled") ~= true then
                LocalPlayer:SetAttribute("GuiEnabled", true)
            end
            local u = invHotbarUI()
            if not u then return end
            if not invA.saved then
                invA.saved = {
                    gui = u.gui.Enabled,
                    pack = u.pack.Visible,
                    hot = u.hot and u.hot.Visible,
                    arrow = u.arrow and u.arrow.Visible,
                }
                invAlwaysHook()
                invHookModule()
            end
            if not u.gui.Enabled then u.gui.Enabled = true end
            if not u.pack.Visible then u.pack.Visible = true end
            if u.hot and not u.hot.Visible then u.hot.Visible = true end
            if u.arrow and not u.arrow.Visible then u.arrow.Visible = true end
        end)
        invA.applying = false
    end

    local function invAlwaysRestore()
        invAlwaysClearProps()
        invUnhookModule()
        if invA.hbConn then pcall(function() invA.hbConn:Disconnect() end) invA.hbConn = nil end
        local s = invA.saved
        invA.saved = nil
        if s then
            pcall(function()
                local u = invHotbarUI()
                if not u then return end
                u.gui.Enabled = s.gui
                u.pack.Visible = s.pack
                if u.hot and s.hot ~= nil then u.hot.Visible = s.hot end
                if u.arrow and s.arrow ~= nil then u.arrow.Visible = s.arrow end
            end)
        end
    end

    local function invAlwaysStart()
        if not invA.charConn then
            invA.charConn = LocalPlayer.CharacterAdded:Connect(function()
                -- Backpack rebuilds on spawn; keep saved visibility, re-assert.
                invAlwaysClearProps()
                invA.saved = nil
                task.wait(0.5)
                if invA.visible then invAlwaysApply() end
            end)
        end
        if not invA.hbConn then
            -- Server re-adds NoEquip/NoTool and flips GuiEnabled; win every frame.
            invA.hbConn = RunService.Heartbeat:Connect(function()
                if invA.visible then invAlwaysApply() end
            end)
        end
        invA.loopToken = invA.loopToken + 1
        local myToken = invA.loopToken
        task.spawn(function()
            while invA.visible and myToken == invA.loopToken do
                invAlwaysApply()
                task.wait(0.5)
            end
        end)
        invAlwaysApply()
    end

    local function invAlwaysStop()
        if invA.charConn then pcall(function() invA.charConn:Disconnect() end); invA.charConn = nil end
        if invA.hbConn then pcall(function() invA.hbConn:Disconnect() end); invA.hbConn = nil end
        invA.loopToken = invA.loopToken + 1
        invAlwaysRestore()
    end

    local InventoryAlwaysToggle = LP_MiscSection:AddToggle('InventoryAlwaysVisible', {
        Text = "Inventory Always Visible",
        Default = false,
        Tooltip = "Keeps the custom inventory UI up and lets you equip items (force equip).",
        Callback = function(state)
            invA.visible = state
            if state then
                invAlwaysStart()
            else
                invAlwaysStop()
            end
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.InventoryAlwaysVisible = InventoryAlwaysToggle

    -- ===== PROTECTION TAB — Zombie (Anti Grab / Anti Tackle) =====
    local LP_ZombieSection = Tabs.Protection:AddGroupbox({ Side = "Right", Name = "Zombie Related Stuff", Description = "Zombie defense", IconName = "skull" })

    -- ------------------------------------------------------------
    -- ------------------------------------------------------------
    local _antiGrabEnabled = false
    local _antiGrabConn    = nil

    local function _antiGrab_tick()
        if not _antiGrabEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            pcall(function()
                humanoid:Move(v3new(0, 100000, 0))
            end)
        end
    end

    local function _antiGrab_start()
        if not _antiGrabConn then
            _antiGrabConn = RunService.Heartbeat:Connect(_antiGrab_tick)
        end
    end

    local function _antiGrab_stop()
        if _antiGrabConn then
            pcall(function() _antiGrabConn:Disconnect() end)
            _antiGrabConn = nil
        end
    end

    LP_ZombieSection:AddDivider()
    LP_ZombieSection:AddToggle('AntiGrab', {
        Text    = "Anti Grab",
        Default = false,
        Tooltip = "Prevents shamblers from grabbing you by forcing them to scratch you.",
        Callback = function(state)
            _antiGrabEnabled = state
            if state then
                _antiGrab_start()
                Library:Notify({
                    Title   = "Anti Grab",
                    Description = "Anti Grab enabled -- zombies can't hold you.",
                    Time = 3,
                    Icon    = "shield-check",
                })
            else
                _antiGrab_stop()
                Library:Notify({
                    Title   = "Anti Grab",
                    Description = "Anti Grab disabled.",
                    Time = 2,
                    Icon    = "shield-off",
                })
            end
        end,
    })

    -- ---------- Anti Tackle engine (structured escape contexts) ----------
    -- Pin escape: event-driven pin watch, void trip, anchored landing.
    type EscapeContext = {
        character: Model,
        root: BasePart,
        humanoid: Humanoid,
        rootWasAnchored: boolean,
        landing: CFrame,
        inVoid: boolean,
    }

    local AntiTackle = {}

    AntiTackle.Config = {
        Cooldown = 1.5,
        VoidOffset = 5000000000,
        ReplicateDelay = 0.1,
        VoidHold = 0.1,
        SettleDelay = 0.1,
        AnimationWindow = 3,
        CollisionRadius = 60,
        GroundProbeRise = 2,
        GroundProbeDepth = 200,
        GroundClearance = 2.5,
        MissingGroundDrop = 3,
        PinAnimationFragments = { "tackle", "pinned", "getup", "standup", "standingup" },
    }

    AntiTackle.Enabled = false
    AntiTackle.Escaping = false
    AntiTackle.WasPinned = false
    AntiTackle.LastEscapeStart = 0
    AntiTackle.Character = nil
    AntiTackle.PinObject = nil
    AntiTackle.PinConnection = nil
    AntiTackle.Escape = nil
    AntiTackle.EscapeThread = nil
    AntiTackle.RecheckThread = nil
    AntiTackle.AnimationThread = nil
    AntiTackle.AnimationConnection = nil
    AntiTackle.CharacterConnections = {}
    AntiTackle.PlayerConnections = {}
    AntiTackle.SavedCollisions = {}

    _G.AntiTackleSuspendFly = false

    function AntiTackle.disconnectAll(list)
        for _, connection in list do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(list)
    end

    function AntiTackle.isPinValueActive(pin)
        if not pin:IsA("ValueBase") then
            return false
        end
        local value = pin.Value
        if typeof(value) == "string" then
            return value ~= "" and value ~= "None"
        end
        return value ~= nil and value ~= false
    end

    function AntiTackle.isPinned()
        local pin = AntiTackle.PinObject
        return pin ~= nil and pin.Parent ~= nil and AntiTackle.isPinValueActive(pin)
    end

    function AntiTackle.watchChild(parent, name, callback)
        local existing = parent:FindFirstChild(name)
        if existing then
            callback(existing)
        end
        return parent.ChildAdded:Connect(function(child)
            if child.Name == name then
                callback(child)
            end
        end)
    end

    function AntiTackle.isPinAnimation(track)
        local name = string.lower(track.Name)
        if string.find(name, "%f[%a]pin%f[%A]") then
            return true
        end
        local compact = string.gsub(name, "[%s_%-]+", "")
        for _, fragment in AntiTackle.Config.PinAnimationFragments do
            if string.find(compact, fragment, 1, true) then
                return true
            end
        end
        return false
    end

    function AntiTackle.stopAnimationSuppression()
        local connection = AntiTackle.AnimationConnection
        if connection then
            AntiTackle.AnimationConnection = nil
            pcall(function() connection:Disconnect() end)
        end
        local thread = AntiTackle.AnimationThread
        if thread then
            AntiTackle.AnimationThread = nil
            pcall(task.cancel, thread)
        end
    end

    function AntiTackle.startAnimationSuppression(humanoid)
        AntiTackle.stopAnimationSuppression()
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            return
        end
        for _, track in animator:GetPlayingAnimationTracks() do
            if AntiTackle.isPinAnimation(track) then
                pcall(track.Stop, track, 0)
            end
        end
        AntiTackle.AnimationConnection = animator.AnimationPlayed:Connect(function(track)
            if AntiTackle.isPinAnimation(track) then
                pcall(track.Stop, track, 0)
            end
        end)
        AntiTackle.AnimationThread = task.delay(AntiTackle.Config.AnimationWindow, function()
            AntiTackle.AnimationThread = nil
            AntiTackle.stopAnimationSuppression()
        end)
    end

    function AntiTackle.suppressZombieCollisions(origin)
        local zombies = workspace:FindFirstChild("Zombies")
        if not zombies then
            return
        end
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = { zombies }
        local saved = AntiTackle.SavedCollisions
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInRadius(origin, AntiTackle.Config.CollisionRadius, params)
        end)
        if not ok or type(parts) ~= "table" then return end
        for _, part in parts do
            local model = part.Parent
            if model and model.Name == "m_Zombie" and model:IsA("Model") and not saved[part] then
                saved[part] = {
                    CanCollide = part.CanCollide,
                    CanTouch = part.CanTouch,
                    CanQuery = part.CanQuery,
                }
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
            end
        end
    end

    function AntiTackle.restoreZombieCollisions()
        local saved = AntiTackle.SavedCollisions
        for part, properties in saved do
            if part.Parent then
                part.CanCollide = properties.CanCollide
                part.CanTouch = properties.CanTouch
                part.CanQuery = properties.CanQuery
            end
        end
        table.clear(saved)
    end

    function AntiTackle.computeLanding(context)
        local config = AntiTackle.Config
        local root = context.root
        local origin = root.Position
        local filter = { context.character }
        local zombies = workspace:FindFirstChild("Zombies")
        if zombies then
            table.insert(filter, zombies)
        end
        for _, player in Players:GetPlayers() do
            local playerCharacter = player.Character
            if playerCharacter and playerCharacter ~= context.character then
                table.insert(filter, playerCharacter)
            end
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = filter
        params.IgnoreWater = true
        local hit = workspace:Raycast(
            origin + v3new(0, config.GroundProbeRise, 0),
            v3new(0, -config.GroundProbeDepth, 0),
            params
        )
        local groundY = (hit and hit.Position.Y) or (origin.Y - config.MissingGroundDrop)
        return cfNew(origin.X, groundY + config.GroundClearance, origin.Z)
    end

    function AntiTackle.isEscapeValid(context)
        return AntiTackle.Enabled
            and AntiTackle.Escape == context
            and AntiTackle.Character == context.character
            and context.character.Parent ~= nil
            and context.root.Parent == context.character
            and context.humanoid.Health > 0
    end

    function AntiTackle.clearPinState(context)
        local pin = AntiTackle.PinObject
        if pin and pin:IsA("ValueBase") then
            pcall(function()
                pin.Value = "None"
            end)
        end
        AntiTackle.startAnimationSuppression(context.humanoid)
        pcall(context.humanoid.ChangeState, context.humanoid, Enum.HumanoidStateType.Running)
        -- Recovery mover (~3s): keep Running, keep pin cleared, and break
        -- any welds gluing us to the zombie so movement actually works.
        task.spawn(function()
            local t0 = tick_()
            while tick_() - t0 < 3 do
                if not AntiTackle.Enabled then break end
                local char = AntiTackle.Character
                if not char or char.Parent == nil then break end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(hum.ChangeState, hum, Enum.HumanoidStateType.Running)
                end
                local p = AntiTackle.PinObject
                if p and p.Parent and p:IsA("ValueBase") then
                    pcall(function() p.Value = "None" end)
                end
                pcall(function()
                    for _, d in char:GetDescendants() do
                        if d:IsA("Weld") or d:IsA("WeldConstraint") then
                            local p0, p1 = d.Part0, d.Part1
                            local mine0 = p0 and p0:IsDescendantOf(char)
                            local mine1 = p1 and p1:IsDescendantOf(char)
                            if (mine0 and not mine1) or (mine1 and not mine0) then
                                d:Destroy()
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end

    function AntiTackle.performEscape(context)
        local config = AntiTackle.Config
        local root = context.root
        local origin = root.Position

        context.landing = AntiTackle.computeLanding(context)
        AntiTackle.suppressZombieCollisions(origin)

        root.CFrame = cfNew(origin + v3new(0, config.VoidOffset, 0))
        context.inVoid = true
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(config.ReplicateDelay)
        if not AntiTackle.isEscapeValid(context) then
            return false
        end

        root.Anchored = true
        task.wait(config.VoidHold)
        if not AntiTackle.isEscapeValid(context) then
            return false
        end

        root.CFrame = context.landing
        context.inVoid = false
        root.AssemblyLinearVelocity = Vector3.zero

        AntiTackle.clearPinState(context)
        task.wait(config.SettleDelay)
        return AntiTackle.isEscapeValid(context)
    end

    function AntiTackle.finishEscape(success)
        local context = AntiTackle.Escape
        AntiTackle.Escape = nil
        AntiTackle.EscapeThread = nil
        AntiTackle.Escaping = false
        if context then
            local root = context.root
            pcall(function()
                if not root.Parent then
                    return
                end
                if context.inVoid then
                    root.CFrame = context.landing
                    root.AssemblyLinearVelocity = Vector3.zero
                end
                if success then
                    for _, descendant in context.character:GetDescendants() do
                        if descendant:IsA("BasePart") and descendant.Anchored then
                            descendant.Anchored = false
                        end
                    end
                else
                    root.Anchored = context.rootWasAnchored
                end
            end)
        end
        AntiTackle.restoreZombieCollisions()
        if not success then
            AntiTackle.stopAnimationSuppression()
        end
        _G.AntiTackleSuspendFly = false
    end

    function AntiTackle.abortEscape()
        if not AntiTackle.Escaping then
            return
        end
        local thread = AntiTackle.EscapeThread
        if thread then
            AntiTackle.EscapeThread = nil
            task.cancel(thread)
        end
        AntiTackle.finishEscape(false)
    end

    function AntiTackle.scheduleRecheck(delay)
        local pending = AntiTackle.RecheckThread
        if pending then
            AntiTackle.RecheckThread = nil
            task.cancel(pending)
        end
        AntiTackle.RecheckThread = task.delay(delay, function()
            AntiTackle.RecheckThread = nil
            if AntiTackle.Enabled and AntiTackle.isPinned() then
                AntiTackle.requestEscape(true)
            end
        end)
    end

    function AntiTackle.runEscape()
        local context = AntiTackle.Escape
        if not context then
            return
        end
        local ok, completed = pcall(AntiTackle.performEscape, context)
        if AntiTackle.Escape ~= context then
            return
        end
        AntiTackle.finishEscape(ok and completed == true)
        if AntiTackle.Enabled then
            local remaining = AntiTackle.Config.Cooldown - (tick_() - AntiTackle.LastEscapeStart)
            AntiTackle.scheduleRecheck(math.max(0, remaining))
        end
    end

    function AntiTackle.beginEscape(char, root, humanoid)
        AntiTackle.Escaping = true
        AntiTackle.LastEscapeStart = tick_()
        _G.AntiTackleSuspendFly = true
        AntiTackle.Escape = {
            character = char,
            root = root,
            humanoid = humanoid,
            rootWasAnchored = root.Anchored,
            landing = root.CFrame,
            inVoid = false,
        }
        local thread = task.spawn(AntiTackle.runEscape)
        if AntiTackle.Escaping then
            AntiTackle.EscapeThread = thread
        end
    end

    function AntiTackle.requestEscape(bypassCooldown)
        if not AntiTackle.Enabled or AntiTackle.Escaping then
            return
        end
        local char = AntiTackle.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and root and humanoid) or not root:IsA("BasePart") or humanoid.Health <= 0 then
            return
        end
        local remaining = AntiTackle.Config.Cooldown - (tick_() - AntiTackle.LastEscapeStart)
        if not bypassCooldown and remaining > 0 then
            AntiTackle.scheduleRecheck(remaining)
            return
        end
        AntiTackle.beginEscape(char, root, humanoid)
    end

    function AntiTackle.onPinChanged()
        local pinned = AntiTackle.isPinned()
        local risingEdge = pinned and not AntiTackle.WasPinned
        AntiTackle.WasPinned = pinned
        if pinned then
            AntiTackle.requestEscape(risingEdge)
        end
    end

    function AntiTackle.bindPin(pin)
        local previous = AntiTackle.PinConnection
        if previous then
            AntiTackle.PinConnection = nil
            pcall(function() previous:Disconnect() end)
        end
        AntiTackle.PinObject = pin
        if pin:IsA("ValueBase") then
            AntiTackle.PinConnection = pin:GetPropertyChangedSignal("Value"):Connect(AntiTackle.onPinChanged)
        end
        AntiTackle.onPinChanged()
    end

    function AntiTackle.unbindCharacter()
        AntiTackle.disconnectAll(AntiTackle.CharacterConnections)
        local pinConnection = AntiTackle.PinConnection
        if pinConnection then
            AntiTackle.PinConnection = nil
            pcall(function() pinConnection:Disconnect() end)
        end
        AntiTackle.PinObject = nil
        AntiTackle.Character = nil
        AntiTackle.WasPinned = false
    end

    function AntiTackle.bindCharacter(newCharacter)
        AntiTackle.unbindCharacter()
        AntiTackle.Character = newCharacter
        table.insert(AntiTackle.CharacterConnections, AntiTackle.watchChild(newCharacter, "UserStates", function(states)
            table.insert(AntiTackle.CharacterConnections, AntiTackle.watchChild(states, "Pin", AntiTackle.bindPin))
        end))
    end

    -- Block RunnerTackle / ViralTackle stun states at the source.
    AntiTackle.BlockedStates = {
        RunnerTackle = true,
        RunnerClawTackle = true,
        RunnerVomitTackle = true,
        RunnerViralTackle = true,
        RunnerAttack = true,
        RunnerClaw = true,
        RunnerVomit = true,
        Grabbed = true,
        RecoverRunner =true,
    }
    AntiTackle.BlockedCount = 0
    AntiTackle.StateHooked = false
    function AntiTackle.hookStates()
        if AntiTackle.StateHooked then return end
        if type(hookfunction) ~= "function" then return end
        local ok, SMC = pcall(function()
            local mods = ReplicatedStorage:FindFirstChild("Modules")
            local comps = mods and mods:FindFirstChild("Components")
            local cs = comps and comps:FindFirstChild("CharacterStates")
            local mod = cs and cs:FindFirstChild("StateManagerComponent")
            if mod and mod:IsA("ModuleScript") then
                return require(mod)
            end
            return nil
        end)
        if not ok or type(SMC) ~= "table" or type(SMC.AddState) ~= "function" then
            return
        end
        local origAdd = nil
        local newc = (type(newcclosure) == "function") and newcclosure or function(f) return f end
        local okHook = pcall(function()
            origAdd = hookfunction(SMC.AddState, newc(function(self, stateName, ...)
                if AntiTackle.Enabled and type(stateName) == "string" then
                    if AntiTackle.BlockedStates[stateName] then
                        AntiTackle.BlockedCount = AntiTackle.BlockedCount + 1
                        return
                    end
                    local lower = string.lower(stateName)
                    if string.find(lower, "tackle", 1, true)
                        or string.find(lower, "claw", 1, true)
                        or string.find(lower, "vomit", 1, true) then
                        AntiTackle.BlockedCount = AntiTackle.BlockedCount + 1
                        return
                    end
                end
                return origAdd(self, stateName, ...)
            end))
        end)
        if okHook and type(origAdd) == "function" then
            AntiTackle.StateHooked = true
        end
    end

    function AntiTackle.start()
        if AntiTackle.Enabled then
            return
        end
        AntiTackle.Enabled = true
        pcall(AntiTackle.hookStates)
        table.insert(AntiTackle.PlayerConnections, LocalPlayer.CharacterAdded:Connect(AntiTackle.bindCharacter))
        table.insert(AntiTackle.PlayerConnections, LocalPlayer.CharacterRemoving:Connect(function()
            AntiTackle.abortEscape()
            AntiTackle.unbindCharacter()
        end))
        local current = LocalPlayer.Character
        if current then
            AntiTackle.bindCharacter(current)
        end
    end

    function AntiTackle.stop()
        AntiTackle.Enabled = false
        AntiTackle.disconnectAll(AntiTackle.PlayerConnections)
        local recheck = AntiTackle.RecheckThread
        if recheck then
            AntiTackle.RecheckThread = nil
            task.cancel(recheck)
        end
        AntiTackle.abortEscape()
        AntiTackle.stopAnimationSuppression()
        AntiTackle.unbindCharacter()
        AntiTackle.restoreZombieCollisions()
        _G.AntiTackleSuspendFly = false
    end

    _G.ArreyAntiTackle = AntiTackle
    LP_ZombieSection:AddToggle('AntiTackle', {
        Text    = "Anti Tackle (Runner)",
        Default = false,
        Tooltip = "Escape any runner pin instantly",
        Callback = function(state)
            if state then
                AntiTackle.start()
                Library:Notify({
                    Title   = "Anti Tackle",
                    Description = "Anti Tackle enabled -- runner pins auto-escape.",
                    Time = 3,
                    Icon    = "shield-check",
                })
            else
                AntiTackle.stop()
                Library:Notify({
                    Title   = "Anti Tackle",
                    Description = "Anti Tackle disabled.",
                    Time = 2,
                    Icon    = "shield-off",
                })
            end
        end,
    })


end   -- end Local Player tab block

do -- // Classes Tab (Musician, Medic, Sapper, Chaplain)

local ClassesTab = Tabs.Classes

do -- Musician scope (split to stay under 200 local registers)
-- ===== CLASSES TAB — Musician (Auto Fife) =====
local MusicianGroup = ClassesTab:AddGroupbox({ Side = "Left", Name = "Musician", Description = "Instrument playback", IconName = "music-2" })

-- start OFF by default; toggle controls everything
local AutoInstrumentEnabled = false
local autoplay = false

local playInterval     = 2          -- re-issue Play often so the song never dies between loops
local accuracyInterval = 0.5         -- ping UpdateAccuracy fast enough that the buff never decays
local defaultSong = "La Marseillaise" -- change this or wire a dropdown

-- state & caches
local guiCache = { fife = nil, drum = nil, bagpipe = nil }
local connections = {}
local heartbeatConn
local currentSong = defaultSong

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function()
            conn:Disconnect()
        end)
    end
end

local function instrumentTools()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return {} end
    local list = {}
    for _, tool in char:GetChildren() do
        if tool:IsA("Tool") and (tool.Name:find("Fife") or tool.Name:find("Drum") or tool.Name:find("Bagpipe")) then
            table.insert(list, tool)
        end
    end
    return list
end

local function tintInstrumentGui(enabled)
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    local function handleGui(name, cacheKey)
        if enabled and guiCache[cacheKey] then
            return
        end

        local gui = pg:FindFirstChild(name)
            or (ReplicatedStorage:FindFirstChild("Modules")
            and ReplicatedStorage.Modules:FindFirstChild("Weapons")
            and ReplicatedStorage.Modules.Weapons:FindFirstChild(name:gsub("Gui", ""))
            and ReplicatedStorage.Modules.Weapons[name:gsub("Gui", "")]:FindFirstChild(name))
        if not gui then return end
        local root = gui:FindFirstChild("Root")
        if not root then return end
        local bg = root:FindFirstChild("BG")
        if not bg then return end
        if enabled then
            if not guiCache[cacheKey] then
                guiCache[cacheKey] = { bg.BackgroundColor3, bg.BackgroundTransparency }
            end
            bg.BackgroundColor3 = c3rgb(255, 255, 255)
            bg.BackgroundTransparency = 0
        elseif guiCache[cacheKey] then
            bg.BackgroundColor3 = guiCache[cacheKey][1]
            bg.BackgroundTransparency = guiCache[cacheKey][2]
        end
    end

    handleGui("FifeGui", "fife")
    handleGui("DrumGui", "drum")
    handleGui("BagpipesGui", "bagpipe")
end

local function fireUpdateAccuracy()
    if not autoplay then return end
    local tools = instrumentTools()
    for _, tool in tools do
        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Remote")
        if remote then
            pcall(function()
                remote:FireServer("UpdateAccuracy", 100)
            end)
        end
    end
end

local function firePlay()
    if not autoplay then return end
    local tools = instrumentTools()
    for _, tool in tools do
        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Remote")
        if not remote then continue end

        local model = tool:FindFirstChild("Model")
        local handle = model and model:FindFirstChild("Handle")
        local soundSource = handle and handle:FindFirstChild("SoundSource")

        if (not soundSource) or (not soundSource.IsPlaying) then
            pcall(function()
                remote:FireServer("Play", currentSong)
            end)
        end
    end
end

-- single heartbeat loop (no spawn/wait spam)
local function startAutoplayHeartbeat()
    if heartbeatConn then return end
    local playTimer = 0
    local accuracyTimer = 0
    local tintTimer = 0

    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not autoplay then return end

        playTimer = playTimer - dt
        accuracyTimer = accuracyTimer - dt
        tintTimer = tintTimer - dt

        if playTimer <= 0 then
            playTimer = playInterval
            firePlay()
        end

        if accuracyTimer <= 0 then
            accuracyTimer = accuracyInterval
            fireUpdateAccuracy()
        end

        if tintTimer <= 0 then
            tintTimer = 0.5
            tintInstrumentGui(true)
        end
    end)
end

local function stopAutoplayHeartbeat()
    safeDisconnect(heartbeatConn)
    heartbeatConn = nil
end

local function startAutoplay()
    if autoplay then return end
    autoplay = true
    AutoInstrumentEnabled = true
    tintInstrumentGui(true)
    startAutoplayHeartbeat()
end

local function stopAutoplay()
    if not autoplay then return end
    autoplay = false
    AutoInstrumentEnabled = false
    tintInstrumentGui(false)
    stopAutoplayHeartbeat()
end

-- song picker helper: call this from your UI when player picks a song

local function setAutoInstrument(state)
    if state then
        startAutoplay()
    else
        stopAutoplay()
    end
end

MusicianGroup:AddToggle('AutoInstrument', {
    Text = "Auto Play Fife/Drum/Bagpipe",
    Default = AutoInstrumentEnabled,
    Tooltip = "Automatically plays instruments.",
    Callback = function(state)
        setAutoInstrument(state)
        Library:Notify({
            Title = "Gun Modifiers",
            Description = state and "Auto instrument ON" or "Auto instrument OFF",
            Time = 2,
            Icon = state and "music-2" or "x"
        })
    end
})

end -- end Musician scope
do -- Medic scope (split to stay under 200 local registers)
-- ===== CLASSES TAB — Medic (Auto Heal) =====
local MedicGroup = ClassesTab:AddGroupbox({ Side = "Right", Name = "Medic", Description = "Healing support", IconName = "heart" })

local AutoRequestHealEnabled = false
local HealRange = 10
local HealCooldown = 3
local HealThreshold = 25
-- Use weak keys so entries for players who left are garbage collected
local HealData = setmetatable({}, { __mode = "k" })
local HealNotify = setmetatable({}, { __mode = "k" })

local function RequestHeal(player, humanoid)
    if not player or not humanoid then return end
    if humanoid.Health > humanoid.MaxHealth * (HealThreshold / 100) then return end

    local lastReq = HealData[player] or 0
    if time() - lastReq < HealCooldown then return end
    HealData[player] = time()

    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    local targetParent = humanoid.Parent
    if not targetParent then return end
    local targetHRP = targetParent:FindFirstChild("HumanoidRootPart") or targetParent:FindFirstChild("Torso")
    if not targetHRP then return end

    if (localHRP.Position - targetHRP.Position).Magnitude > HealRange then return end

    local medSupplies = localChar:FindFirstChild("Medical Supplies")
    if not medSupplies then return end
    local remote = medSupplies:FindFirstChild("RemoteEvent")
    if not remote then return end

    pcall(function()
        remote:FireServer("SendRequest", humanoid)
        local lastNotify = HealNotify[player] or 0
        if time() - lastNotify >= HealCooldown then
            HealNotify[player] = time()
            Library:Notify({
                Title = "Auto Heal",
                Description = "Requested heal for " .. player.Name,
                Time = 2,
                Icon = "heart",
            })
        end
    end)
end

local autoHealLoopRunning = false
local autoHealLoopThread = nil
local function stopAutoHealLoop()
    autoHealLoopRunning = false
    if autoHealLoopThread then
        pcall(function() task.cancel(autoHealLoopThread) end)
        autoHealLoopThread = nil
    end
end
_G.ArreyStopAutoHealLoop = stopAutoHealLoop

local function startAutoHealLoop()
    if autoHealLoopThread then return end
    autoHealLoopRunning = true
    autoHealLoopThread = task.spawn(function()
        while autoHealLoopRunning and AutoRequestHealEnabled do
            -- PERF FIX: Increased from 0.35s to 0.7s - heal requests don't need sub-second polling
            task.wait(0.7)
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
                    if humanoid and humanoid.Health <= humanoid.MaxHealth * (HealThreshold / 100) then
                        pcall(function() RequestHeal(player, humanoid) end)
                    end
                end
            end
        end
        autoHealLoopThread = nil
    end)
end

MedicGroup:AddToggle('AutoRequestHeal', {
    Text = "Auto Request Heal Dying Players",
    Default = false,
    Tooltip = "Automatically requests heal for players with low health when nearby",
    Callback = function(state)
        AutoRequestHealEnabled = state
        if state then
            startAutoHealLoop()
        else
            stopAutoHealLoop()
        end
        Library:Notify({
            Title = "Auto Heal",
            Description = state and "Auto Request Heal Enabled" or "Auto Request Heal Disabled",
            Time = 2,
            Icon = state and "heart" or "x",
        })
    end
})

MedicGroup:AddSlider('HealThreshold', {
    Text = "Heal Threshold (%)",
    Default = HealThreshold or 25,
    Min = 1,
    Max = 100,
    Rounding = 1,
    Suffix = "%",
    Tooltip = "Health percentage threshold for auto heal",
    Callback = function(val)
        HealThreshold = val
    end
})

-- Auto Pick Up Supplies feature
local AutoPickUpSuppliesEnabled = false


-- Cache for supply prompts to avoid searching all descendants every frame
local cachedSupplyPrompts = {}
local lastPromptCacheTime = 0
local PROMPT_CACHE_DURATION = 60

local function _doScanSupplyPrompts()
    cachedSupplyPrompts = {}
    local searchLocations = {
        Workspace:FindFirstChild("Supplies"),
        Workspace:FindFirstChild("SupplyBoxes"),
        Workspace:FindFirstChild("Interactables"),
        Workspace:FindFirstChild("Map"),
    }
    local function searchIn(container)
        if not container then return end
        for _, obj in container:GetDescendants() do
            if obj:IsA("ProximityPrompt") then
                local name = obj.Name:lower()
                if name:find("replenish") or name:find("supply") or obj.Name == "ReplenishPrompt" then
                    table.insert(cachedSupplyPrompts, obj)
                end
            end
        end
    end
    for _, loc in searchLocations do searchIn(loc) end
    -- Workspace fallback only if named folders didn't find anything
    if #cachedSupplyPrompts == 0 then
        for _, obj in Workspace:GetDescendants() do
            if obj:IsA("ProximityPrompt") then
                local name = obj.Name:lower()
                if name:find("replenish") or name:find("supply") or obj.Name == "ReplenishPrompt" then
                    table.insert(cachedSupplyPrompts, obj)
                end
            end
        end
    end
end

local function RefreshPromptCache()
    local now = time()
    -- FIX: Skip expensive rescan if cache is fresh
    if now - lastPromptCacheTime < PROMPT_CACHE_DURATION then
        -- Validate existing cache: if any entry is gone, force a rescan now
        local allValid = true
        for _, p in cachedSupplyPrompts do
            if not p or not p.Parent then allValid = false; break end
        end
        if allValid then return end
    end
    lastPromptCacheTime = now
    _doScanSupplyPrompts()
end

local function FireReplenishPrompt()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Refresh cache periodically
    RefreshPromptCache()

    -- Find the CLOSEST replenish/supply prompt to the player from cache
    local bestPrompt = nil
    local bestDist = 8 -- max search range in studs

    for _, prompt in cachedSupplyPrompts do
        if prompt and prompt.Parent then
            local parent = prompt.Parent
            local part = nil

            if parent and parent:IsA("BasePart") then
                part = parent
            elseif parent and parent:IsA("Model") then
                part = parent:FindFirstChild("HumanoidRootPart") or parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
            elseif parent then
                part = parent:FindFirstAncestorWhichIsA("BasePart") or parent:FindFirstChildWhichIsA("BasePart")
            end

            if part then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestPrompt = prompt
                end
            end
        end
    end

    -- No prompt found nearby
    if not bestPrompt then return end

    -- Fire the closest proximity prompt
    pcall(function()
        fireproximityprompt(bestPrompt)
    end)
end

-- FIX: Do not keep an idle picker loop alive when the feature is off.
local autoPickupLoopRunning = false
local autoPickupLoopThread = nil
local function stopAutoPickupLoop()
    autoPickupLoopRunning = false
    if autoPickupLoopThread then
        pcall(function() task.cancel(autoPickupLoopThread) end)
        autoPickupLoopThread = nil
    end
end
_G.ArreyStopAutoPickupLoop = stopAutoPickupLoop

local function startAutoPickupLoop()
    if autoPickupLoopThread then return end
    autoPickupLoopRunning = true
    autoPickupLoopThread = task.spawn(function()
        while autoPickupLoopRunning and AutoPickUpSuppliesEnabled do
            FireReplenishPrompt()
            task.wait(0.25) -- Active: check every 0.25s
        end
        autoPickupLoopThread = nil
    end)
end

MedicGroup:AddToggle('AutoPickUpSupplies', {
    Text = "Auto Pick Up Supplies",
    Default = false,
    Tooltip = "Automatically picks up supplies.",
    Callback = function(state)
        AutoPickUpSuppliesEnabled = state
        if state then
            startAutoPickupLoop()
        else
            stopAutoPickupLoop()
        end
        Library:Notify({
            Title = "Auto Pick Up Supplies",
            Description = state and "Auto Pickup Supplies Enabled" or "Auto Pickup Supplies Disabled",
            Time = 2,
            Icon = state and "package" or "x",
        })
    end
})

end -- end Medic scope
do -- Sapper scope (split to stay under 200 local registers)
-- ===== CLASSES TAB — Sapper (Auto Repair) =====
local SapperGroup = ClassesTab:AddGroupbox({ Side = "Left", Name = "Sapper", Description = "Repairs and shove", IconName = "hammer" })

local AutoRepairEnabled = false
local AutoRepairConn = nil
local AutoRepairRange = 25 -- Range to search for buildable structures
local AutoRepairCooldown = 0.5 -- OPTIMIZED: 0.5s instead of 0.15s (repairs happen server-side, no need for spam)
local AutoRepairTargetMode = "None"

-- OPTIMIZED: Cache hammer remote and folder references
local cachedHammerRemote = nil
local cachedHammerRemoteTime = 0
local HAMMER_CACHE_TTL = 2 -- Re-check hammer every 2 seconds

-- OPTIMIZED: Cache buildable folder references (they don't change during gameplay)
local cachedBuildableFolders = nil
local cachedBuildableFoldersTime = 0
local FOLDER_CACHE_TTL = 10 -- Re-check folders every 10 seconds

-- Helper: Find hammer remote (cached)
local function getHammerRemote()
    local now = time()
    if cachedHammerRemote and (now - cachedHammerRemoteTime) < HAMMER_CACHE_TTL then
        -- Validate cached remote still exists
        if cachedHammerRemote.Parent then return cachedHammerRemote end
        cachedHammerRemote = nil
    end

    local char = LocalPlayer.Character
    if not char then return nil end

    -- Method 1: workspace.Players folder (where remotes actually are)
    local wsPlayers = Workspace:FindFirstChild("Players")
    if wsPlayers then
        local playerFolder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        if playerFolder then
            local hammerFolder = playerFolder:FindFirstChild("Hammer")
                or playerFolder:FindFirstChild("Claw Hammer")
            if hammerFolder then
                local re = hammerFolder:FindFirstChild("RemoteEvent")
                if re then
                    cachedHammerRemote = re
                    cachedHammerRemoteTime = now
                    return re
                end
            end
        end
    end

    -- Method 2: backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local hammer = backpack:FindFirstChild("Hammer") or backpack:FindFirstChild("Claw Hammer")
        if hammer then
            local re = hammer:FindFirstChild("RemoteEvent")
            if re then
                cachedHammerRemote = re
                cachedHammerRemoteTime = now
                return re
            end
        end
    end

    -- Method 3: character (equipped)
    local hammer = char:FindFirstChild("Hammer") or char:FindFirstChild("Claw Hammer")
    if hammer then
        local re = hammer:FindFirstChild("RemoteEvent")
        if re then
            cachedHammerRemote = re
            cachedHammerRemoteTime = now
            return re
        end
    end

    return nil
end

-- OPTIMIZED: Get buildable folder references (cached)
local function getBuildableFolders()
    local now = time()
    if cachedBuildableFolders and (now - cachedBuildableFoldersTime) < FOLDER_CACHE_TTL then
        return cachedBuildableFolders
    end

    local folders = {}
    local folderNames = {"Buildables", "Stakes", "Barricades", "Structures", "Buildings"}
    for _, name in folderNames do
        local folder = Workspace:FindFirstChild(name)
        if folder then folders[#folders + 1] = folder end
    end

    -- Check map-specific folders (Berezina, etc.) - only Modes sub-folders
    for _, mapFolder in Workspace:GetChildren() do
        if mapFolder:IsA("Folder") or mapFolder:IsA("Model") then
            local modes = mapFolder:FindFirstChild("Modes")
            if modes then folders[#folders + 1] = modes end
        end
    end

    cachedBuildableFolders = folders
    cachedBuildableFoldersTime = now
    return folders
end


local _richBuildBuf = {}    -- reused result buffer
local _richBuildSeen = {}   -- reused dedup table
local _richBuildCount = 0
local MAX_RICH_BUILDABLES = 32 -- Cap results to prevent excessive sorting

local function getRichBuildables()
    local char = LocalPlayer.Character
    if not char then return _richBuildBuf, 0 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return _richBuildBuf, 0 end
    local rootPos = root.Position
    local rangeSq = AutoRepairRange * AutoRepairRange

    -- Reset reusable buffers
    _richBuildCount = 0
    -- Clear seen table (wipe keys)
    for k in _richBuildSeen do _richBuildSeen[k] = nil end

    local folders = getBuildableFolders()

    -- Inline tryAdd to avoid closure creation
    local function tryAdd(inst)
        if _richBuildCount >= MAX_RICH_BUILDABLES then return end
        local pos = nil
        if inst:IsA("BasePart") then
            pos = inst.Position
        elseif inst:IsA("Model") then
            local p = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
            if p then pos = p.Position end
        end
        if not pos then return end

        local dx, dy, dz = pos.X - rootPos.X, pos.Y - rootPos.Y, pos.Z - rootPos.Z
        local distSq = dx*dx + dy*dy + dz*dz
        if distSq > rangeSq then return end

        local healthObj = inst:FindFirstChild("BuildingHealth")
            or inst:FindFirstChild("ConstructHealth")
        if not healthObj then
            local h = inst:FindFirstChild("Health")
            if h and h:IsA("NumberValue") then healthObj = h end
        end
        if not healthObj or _richBuildSeen[healthObj] then return end
        _richBuildSeen[healthObj] = true

        -- PERF FIX: Direct access instead of pcall (saves closure alloc per health object)
        local cur = healthObj.Value
        if not cur then return end
        local max = healthObj:GetAttribute("MaxHealth") or healthObj:GetAttribute("Max") or 100
        if max == 0 then return end
        if cur >= max then return end -- fully repaired, skip

        _richBuildCount = _richBuildCount + 1
        local entry = _richBuildBuf[_richBuildCount]
        if entry then
            -- Reuse existing table entry
            entry.obj = healthObj
            entry.cur = cur
            entry.max = max
            entry.ratio = cur / max
            entry.dist = distSq -- Store squared dist, only sqrt when needed
        else
            -- First time: create entry (only happens once per slot)
            _richBuildBuf[_richBuildCount] = {
                obj = healthObj,
                cur = cur,
                max = max,
                ratio = cur / max,
                dist = distSq
            }
        end
    end

    for _, folder in folders do
        if _richBuildCount >= MAX_RICH_BUILDABLES then break end
        for _, inst in folder:GetChildren() do
            if _richBuildCount >= MAX_RICH_BUILDABLES then break end
            tryAdd(inst)
            if inst:IsA("Model") or inst:IsA("Folder") then
                for _, sub in inst:GetChildren() do
                    if _richBuildCount >= MAX_RICH_BUILDABLES then break end
                    tryAdd(sub)
                end
            end
        end
    end

    -- Clear stale tail entries
    for i = _richBuildCount + 1, #_richBuildBuf do
        _richBuildBuf[i] = nil
    end

    return _richBuildBuf, _richBuildCount
end

local function doAutoRepair()
    if AutoRepairTargetMode == "None" then return end

    local hammerRemote = getHammerRemote()
    if not hammerRemote then return end

    local buf, count = getRichBuildables()
    if count == 0 then return end

    local target = nil

    if AutoRepairTargetMode == "Closest" then
        -- Find min by dist (squared)  no sort needed for single best
        local bestDist = buf[1].dist
        target = buf[1].obj
        for i = 2, count do
            if buf[i].dist < bestDist then
                bestDist = buf[i].dist
                target = buf[i].obj
            end
        end

    elseif AutoRepairTargetMode == "LowestHealth" then
        -- Find min by ratio, tie-break by raw HP  no sort needed
        local bestRatio = buf[1].ratio
        local bestCur = buf[1].cur
        target = buf[1].obj
        for i = 2, count do
            local e = buf[i]
            if e.ratio < bestRatio or (e.ratio == bestRatio and e.cur < bestCur) then
                bestRatio = e.ratio
                bestCur = e.cur
                target = e.obj
            end
        end
    end

    if target then
        pcall(function()
            hammerRemote:FireServer("Repair", target)
        end)
    end
end

local autoRepairTicker = 0

SapperGroup:AddToggle('AutoRepair', {
    Text = "Auto Repair",
    Default = false,
    Tooltip = "Auto repair's Buildings",
    Callback = function(state)
        AutoRepairEnabled = state
        if state then
            if AutoRepairConn then AutoRepairConn:Disconnect() end
            autoRepairTicker = 0
            AutoRepairConn = RunService.Heartbeat:Connect(function(dt)
                if not AutoRepairEnabled then return end
                autoRepairTicker = autoRepairTicker + (dt or 0)
                if autoRepairTicker < AutoRepairCooldown then return end
                autoRepairTicker = 0
                doAutoRepair()
            end)
            Library:Notify({
                Title = "Auto Repair",
                Description = "Auto Repair enabled",
                Time = 2,
                Icon = "wrench",
            })
        else
            if AutoRepairConn then
                AutoRepairConn:Disconnect()
                AutoRepairConn = nil
            end
            Library:Notify({
                Title = "Auto Repair",
                Description = "Auto Repair disabled",
                Time = 2,
                Icon = "x",
            })
        end
    end
})

SapperGroup:AddDropdown('AutoRepairMode', {
    Text = "Repair Target Mode",
    Values = { "Closest Structure", "Lowest Health Structure" },
    Default = nil,
    AllowNull = true,
    Tooltip = "Select A Target",
    Callback = function(value)
        if value == "Closest Structure" then
            AutoRepairTargetMode = "Closest"
        elseif value == "Lowest Health Structure" then
            AutoRepairTargetMode = "LowestHealth"
        else
            AutoRepairTargetMode = "None"
        end
    end
})


-- ===== SHOVE AURA ENGINE — config + loop =====

-- config
local ToolNamesPriority = {"Carbine", "Navy Pistol", "Axe", "Pickaxe", "Baguette"}

local ShoveAuraRange = 12
local ShoveTargets = 3
local ShoveAuraCooldown = 0.10
local ShovePreferEquipped = true
local AutoParrySapperEnabled = false

-- Carbine/Navy combo settings
local ComboStunRange = 15
local ComboStunMaxTargets = 10
local ComboStunDelay = 0.10

ShoveHitboxExpanderEnabled = ShoveHitboxExpanderEnabled or false
ShoveHitboxExpanderRange = ShoveHitboxExpanderRange or 20
ShoveHitboxExpanderTargets = ShoveHitboxExpanderTargets or 10
ShoveHitboxExpanderDelay = ShoveHitboxExpanderDelay or 0.03
ShoveHitboxAnimConnection = ShoveHitboxAnimConnection or nil
AutoParrySapperMeleeEnabled = AutoParrySapperMeleeEnabled or false

ShoveAuraEnabled = false -- Global for keybind access

local function safeWait(t)
    t = tonumber(t) or 0
    if t > 0 then task.wait(t) end
end

local function GetBackpack()
    if not LocalPlayer then return nil end
    return LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:FindFirstChild("BackPack")
end

local function FindToolInstanceByName(toolName)
    if type(toolName) ~= "string" or toolName == "" or not LocalPlayer then
        return nil
    end

    local function findToolIn(container)
        if not container then return nil end
        local tool = container:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            return tool
        end
        return nil
    end

    local char = LocalPlayer.Character
    local tool = findToolIn(char)
    if tool then return tool end

    local bp = GetBackpack()
    tool = findToolIn(bp)
    if tool then return tool end

    local wsPlayers = Workspace:FindFirstChild("Players")
    local folder = wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name)
    tool = findToolIn(folder)
    if tool then return tool end

    return nil
end

local function TryEquipToolInstance(tool)
    if not tool or not tool:IsA("Tool") or not LocalPlayer then return false end

    local toolName = tool.Name

    local function isEquipped(char, candidate)
        if not char then return false end
        if candidate and candidate.Parent == char then
            return true
        end
        local equipped = char:FindFirstChild(toolName)
        return equipped ~= nil and equipped:IsA("Tool")
    end

    local function waitForEquip(candidate)
        for _ = 1, 8 do
            local char = LocalPlayer.Character
            if isEquipped(char, candidate) then
                return true
            end
            safeWait(0.05)
        end
        return isEquipped(LocalPlayer.Character, candidate)
    end

    local char = LocalPlayer.Character
    if isEquipped(char, tool) then return true end
    if not char then return false end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local ok = pcall(function()
            humanoid:EquipTool(tool)
        end)
        if ok and waitForEquip(tool) then
            return true
        end
    end

    if LocalPlayer and LocalPlayer.EquipTool then
        local ok = pcall(function()
            LocalPlayer:EquipTool(tool)
        end)
        if ok and waitForEquip(tool) then
            return true
        end
    end

    local ok = pcall(function()
        tool.Parent = char
    end)
    if ok and waitForEquip(tool) then
        return true
    end

    local refreshedTool = FindToolInstanceByName(toolName)
    if refreshedTool and refreshedTool ~= tool then
        if isEquipped(LocalPlayer.Character, refreshedTool) then
            return true
        end
    end

    return false
end

local function TryEquipFromBackpack(timeout)
    timeout = mathMax(0, tonumber(timeout) or 0.8)
    if not LocalPlayer then return nil end

    local start = time()
    local attemptedTools = setmetatable({}, { __mode = "k" })

    while time() - start < timeout do
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not humanoid or humanoid.Health <= 0 then
            safeWait(0.05)
        else
            for _, name in ToolNamesPriority do
                local equipped = char:FindFirstChild(name)
                if equipped and equipped:IsA("Tool") then
                    return name
                end

                local candidate = FindToolInstanceByName(name)
                if candidate and candidate:IsA("Tool") then
                    local shouldRetry = attemptedTools[candidate] == nil or candidate.Parent ~= attemptedTools[candidate]
                    if shouldRetry then
                        attemptedTools[candidate] = candidate.Parent
                        if TryEquipToolInstance(candidate) then
                            safeWait(0.06)

                            local equippedAfter = char:FindFirstChild(name)
                            if equippedAfter and equippedAfter:IsA("Tool") then
                                return name
                            end

                            local refreshedCandidate = FindToolInstanceByName(name)
                            if refreshedCandidate and refreshedCandidate:IsA("Tool") and refreshedCandidate.Parent == char then
                                return name
                            end
                        end
                    end
                end
            end

            safeWait(0.06)
        end
    end

    local char = LocalPlayer.Character
    if char then
        for _, name in ToolNamesPriority do
            local equipped = char:FindFirstChild(name)
            if equipped and equipped:IsA("Tool") then
                return name
            end
        end
    end

    return nil
end

local RemoteFromToolInstance

local function GetToolRemoteByName(toolName)
    if type(toolName) ~= "string" or toolName == "" or not LocalPlayer then
        return nil
    end

    local tool = FindToolInstanceByName(toolName)
    local remote = tool and RemoteFromToolInstance(tool) or nil

    if remote and remote:IsA("RemoteEvent") then
        return remote
    end

    local wsPlayers = Workspace:FindFirstChild("Players")
    local folder = wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name)
    local toolFolder = folder and folder:FindFirstChild(toolName)
    local fallbackRemote = toolFolder and toolFolder:FindFirstChild("RemoteEvent")
    if fallbackRemote and fallbackRemote:IsA("RemoteEvent") then
        return fallbackRemote
    end

    return nil
end

local function FindNearestAgentParts(pos, maxRange, n)
    if not pos then return {} end
    n = n or 1
    local results, resultN = queryZombies(pos, maxRange or mathHuge, nil, n)
    local out = {}
    for i = 1, mathMin(n, resultN) do
        out[i] = results[i].root
    end
    return out
end

local function GetZombiesInComboRange(originPos, radius, maxTargets)
    if not originPos then return {} end
    radius = radius or ComboStunRange
    maxTargets = maxTargets or ComboStunMaxTargets
    local results, resultN = queryZombies(originPos, radius, nil, maxTargets)
    local out = {}
    for i = 1, mathMin(maxTargets, resultN) do
        out[i] = { model = results[i].model, part = results[i].root, dist = mathSqrt(results[i].d2) }
    end
    return out
end

local function PerformGunStunCombo(remote, originPos)
    if not remote or not originPos then return end
    local targets = GetZombiesInComboRange(originPos, ComboStunRange, ComboStunMaxTargets)
    for i, entry in targets do
        if entry.model and entry.part then
            pcall(function() remote:FireServer("FeedbackStun", entry.model, entry.part.Position) end)
            if i < #targets then safeWait(ComboStunDelay) end
        end
    end
end

-- Shove Aura: unchanged aside from using the same robust remote lookup and gun/melee behavior
RemoteFromToolInstance = function(tool)
    return getToolRemote(tool)
end

local function GetBestToolRemoteAndName()
    if not LocalPlayer then
        return nil, nil
    end

    if ShovePreferEquipped and LocalPlayer.Character then
        local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if equipped then
            local r = RemoteFromToolInstance(equipped)
            if r then return r, equipped.Name end
        end
    end

    for _, name in ToolNamesPriority do
        local remote = GetToolRemoteByName(name)
        if remote then
            return remote, name
        end
    end

    return nil, nil
end

local function FireShove(remote, agentPart, toolName)
    if not remote then return end
    local tname = tostring(toolName or ""):lower()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    -- Baguette uses same shove mechanics as melee weapons
    if tname == "carbine" or tname == "navy pistol" then
        pcall(function() remote:FireServer("Shove") end)
        if hrp then PerformGunStunCombo(remote, hrp.Position) end
    else
        if not agentPart then return end
        pcall(function() remote:FireServer("FeedbackStun", agentPart.Parent, agentPart.Position) end)
        pcall(function() remote:FireServer("StopBraceBlock") end)
    end
end

-- ===== SHARED COORDINATION SYSTEM FOR KILL AURA + SHOVE AURA =====

-- Shared state (accessible by both systems)
_G.AuraCoordination = _G.AuraCoordination or {
    lastEquipAttempt = 0,
    equipCooldown = 0.5, -- Minimum time between equip attempts
    currentEquipOwner = nil, -- "KillAura" or "ShoveAura" or nil
    shoveAuraLastFire = 0, -- Track when Shove Aura last fired
    killAuraLastFire = 0, -- Track when Kill Aura last fired
}

-- PERFORMANCE: Cache for Shove Aura remote (prevents expensive lookups every cycle)
local ShoveAura_cachedRemote = nil
local ShoveAura_cachedRemoteName = nil
local ShoveAura_lastRemoteCheck = 0
local SHOVE_AURA_REMOTE_CACHE_TIME = 2 -- Recheck remote every 2 seconds

local function ShoveAura_getRemote()
    local now = time()

    -- Check if cache is still valid
    if ShoveAura_cachedRemote and (now - ShoveAura_lastRemoteCheck) < SHOVE_AURA_REMOTE_CACHE_TIME then
        -- Verify remote still exists
        if ShoveAura_cachedRemote.Parent then
            return ShoveAura_cachedRemote, ShoveAura_cachedRemoteName
        end
    end

    -- Try to get remote from currently equipped tool FIRST (no equipping)
    local char = LocalPlayer.Character
    if char then
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            local r = RemoteFromToolInstance(equipped)
            if r then
                ShoveAura_cachedRemote = r
                ShoveAura_cachedRemoteName = equipped.Name
                ShoveAura_lastRemoteCheck = now
                return r, equipped.Name
            end
        end
    end

    -- If Kill Aura is enabled, DON'T try to equip - let Kill Aura handle tools
    if KillAuraEnabled and KillAura_AutoEquipMelee then
        -- Just use any available remote from workspace or backpack (no equipping)
        local remote, rname = GetBestToolRemoteAndName()
        if remote then
            ShoveAura_cachedRemote = remote
            ShoveAura_cachedRemoteName = rname
            ShoveAura_lastRemoteCheck = now
            return remote, rname
        end
        return nil, nil
    end

    -- Kill Aura not active or not auto-equipping - Shove Aura can try to get a tool
    local remote, rname = GetBestToolRemoteAndName()
    if remote then
        ShoveAura_cachedRemote = remote
        ShoveAura_cachedRemoteName = rname
        ShoveAura_lastRemoteCheck = now
        return remote, rname
    end

    return nil, nil
end

local shoveAuraLoopRunning = false
local shoveAuraLoopThread = nil
local function stopShoveAuraLoop()
    shoveAuraLoopRunning = false
    if shoveAuraLoopThread then
        pcall(function() task.cancel(shoveAuraLoopThread) end)
        shoveAuraLoopThread = nil
    end
end
_G.ArreyStopShoveAuraLoop = stopShoveAuraLoop

local function startShoveAuraLoop()
    if shoveAuraLoopThread then return end
    shoveAuraLoopRunning = true
    shoveAuraLoopThread = task.spawn(function()
        while shoveAuraLoopRunning and ShoveAuraEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- COORDINATION: Check if Kill Aura just fired (avoid overlapping)
                local coord = _G.AuraCoordination
                local now = time()
                local timeSinceKillAura = now - (coord.killAuraLastFire or 0)

                if KillAuraEnabled and timeSinceKillAura < 0.03 then
                    task.wait(0.05)
                end

                -- Use cached remote lookup (fast, non-blocking)
                local remote, rname = ShoveAura_getRemote()

                if remote then
                    local targets = FindNearestAgentParts(hrp.Position, ShoveAuraRange, ShoveTargets)
                    if #targets > 0 then
                        -- Mark when Shove Aura fires
                        coord.shoveAuraLastFire = time()

                        -- Fire shoves directly (no spawn needed - already non-blocking)
                        for _, part in targets do
                            FireShove(remote, part, rname)
                        end
                    end
                end
            end

            if KillAuraEnabled then
                -- When Kill Aura is also active, use slightly longer cooldown to share time
                task.wait(mathMax(ShoveAuraCooldown, 0.15))
            else
                -- Solo Shove Aura - use configured cooldown
                task.wait(ShoveAuraCooldown)
            end
        end
        -- Clear cache when disabled/stopped so dead remotes are not retained.
        ShoveAura_cachedRemote = nil
        ShoveAura_cachedRemoteName = nil
        shoveAuraLoopThread = nil
    end)
end

-- ===== SHOVE HITBOX EXPANDER - ANIMATION DETECTION =====

-- Helper: Check if animation name contains "shove" (case insensitive)
local function IsShoveAnimation(track)
    if not track then return false end
    local name = track.Name or ""
    if string.lower(name):find("shove") then return true end
    -- Also check animation object name
    local anim = track.Animation
    if anim and anim.Name then
        if string.lower(anim.Name):find("shove") then return true end
    end
    return false
end

-- Perform the extended shove (same logic as Shove Aura)
local function PerformShoveHitboxExpander()
    if not ShoveHitboxExpanderEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Get remote and tool name (same as Shove Aura)
    local remote, rname = GetBestToolRemoteAndName()
    if not remote then return end

    -- Get zombies in extended range
    local targets = FindNearestAgentParts(hrp.Position, ShoveHitboxExpanderRange, ShoveHitboxExpanderTargets)
    if #targets == 0 then return end

    -- Fire at each target (same as Shove Aura)
    for i, part in targets do
        FireShove(remote, part, rname)
        if i < #targets and ShoveHitboxExpanderDelay > 0 then
            safeWait(ShoveHitboxExpanderDelay)
        end
    end
end

-- Animation detection callback
local function OnShoveAnimationPlayed(track)
    if not ShoveHitboxExpanderEnabled then return end
    if not track then return end

    -- Check if this is a shove animation
    if IsShoveAnimation(track) then
        -- Fire extended shove immediately
        task.spawn(function()
            PerformShoveHitboxExpander()
        end)
    end
end

-- Attach animation watcher to humanoid (global so toggle can call it)
_G.AttachShoveHitboxWatcher = function()
    -- Disconnect previous connection if exists
    if ShoveHitboxAnimConnection then
        pcall(function() ShoveHitboxAnimConnection:Disconnect() end)
        ShoveHitboxAnimConnection = nil
    end

    -- Only attach watcher if feature is enabled
    if not ShoveHitboxExpanderEnabled then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Connect to AnimationPlayed
    local ok, conn = pcall(function()
        return hum.AnimationPlayed:Connect(OnShoveAnimationPlayed)
    end)
    if ok and conn then
        ShoveHitboxAnimConnection = conn
    end
end

local shoveHitboxCharConnection = nil
local function setupShoveHitboxCharConnection()
    if shoveHitboxCharConnection then
        pcall(function() shoveHitboxCharConnection:Disconnect() end)
    end
    shoveHitboxCharConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.2)
        if ShoveHitboxExpanderEnabled then
            _G.AttachShoveHitboxWatcher()
        end
    end)
end
setupShoveHitboxCharConnection()

-- Initial attach if character already loaded (only if feature is enabled)
task.spawn(function()
    task.wait(0.5)
    if ShoveHitboxExpanderEnabled then
        _G.AttachShoveHitboxWatcher()
    end
end)

-- Auto Parry Zapper: spam BraceBlock when a zapper is close (uses ESP detection)
local function FindNearestZapper(pos, maxRange)
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder or not pos then return nil end
    local nearest = nil
    local nearestDist = mathHuge
    for _, z in zombiesFolder:GetChildren() do
        if z and z:IsA("Model") and _G.isZombieOfType and _G.isZombieOfType(z, "Zapper") then
            local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - pos).Magnitude
                if d <= (maxRange or mathHuge) and d < nearestDist then
                    nearestDist = d
                    nearest = part
                end
            end
        end
    end
    return nearest, nearestDist
end

local autoParryZapperLoopRunning = false
local autoParryZapperLoopThread = nil
local function stopAutoParryZapperLoop()
    autoParryZapperLoopRunning = false
    if autoParryZapperLoopThread then
        pcall(function() task.cancel(autoParryZapperLoopThread) end)
        autoParryZapperLoopThread = nil
    end
end
_G.ArreyStopAutoParryZapperLoop = stopAutoParryZapperLoop

local function startAutoParryZapperLoop()
    if autoParryZapperLoopThread then return end
    autoParryZapperLoopRunning = true
    autoParryZapperLoopThread = task.spawn(function()
        while autoParryZapperLoopRunning and AutoParrySapperEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local threshold = ShoveAuraEnabled and 5 or 10
                local zapperPart, dist = FindNearestZapper(hrp.Position, threshold)
                if zapperPart and dist and dist <= threshold then
                    local remote, rname = GetBestToolRemoteAndName()
                    if not remote then
                        local equipName = TryEquipFromBackpack(0.4)
                        remote = equipName and GetToolRemoteByName(equipName) or nil
                        rname = rname or equipName
                    end
                    if remote then
                        pcall(function() remote:FireServer("BraceBlock") end)
                    end
                end
            end
            -- PERF FIX: Increased from 0.08s to 0.15s - parry checks still responsive but less CPU intensive
            task.wait(0.08)
        end
        autoParryZapperLoopThread = nil
    end)
end
_G.ArreyStartAutoParryZapperLoop = startAutoParryZapperLoop

-- Auto Parry Sapper (Melee only - Axe/Pickaxe): spam BraceBlock when any zombie is within 8 studs
local function FindNearestZombieForParry(pos, maxRange)
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder or not pos then return nil end
    local nearest = nil
    local nearestDist = mathHuge
    local function checkZombie(z)
        if z and z:IsA("Model") then
            local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - pos).Magnitude
                if d <= (maxRange or mathHuge) and d < nearestDist then
                    nearestDist = d
                    nearest = part
                end
            end
        end
    end

    for _, topChild in zombiesFolder:GetChildren() do
        if topChild:IsA("Folder") then
            for _, z in topChild:GetChildren() do
                checkZombie(z)
            end
        elseif topChild:IsA("Model") then
            checkZombie(topChild)
        end
    end

    return nearest, nearestDist
end

-- Helper: Check if player has Axe or Pickaxe equipped
local function HasMeleeEquipped()
    local char = LocalPlayer.Character
    if not char then return false, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local name = tool.Name
        if name == "Axe" or name == "Pickaxe" then
            return true, name
        end
    end
    return false, nil
end

-- Helper: Get remote for Axe or Pickaxe
local function GetMeleeRemote()
    local hasMelee, toolName = HasMeleeEquipped()
    if not hasMelee then return nil, nil end

    local wsPlayers = Workspace:FindFirstChild("Players")
    if wsPlayers then
        local playerFolder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        if playerFolder then
            local toolFolder = playerFolder:FindFirstChild(toolName)
            if toolFolder then
                local remote = toolFolder:FindFirstChild("RemoteEvent")
                if remote then return remote, toolName end
            end
        end
    end
    return nil, nil
end

local autoParrySapperMeleeLoopRunning = false
local autoParrySapperMeleeLoopThread = nil
local function stopAutoParrySapperMeleeLoop()
    autoParrySapperMeleeLoopRunning = false
    if autoParrySapperMeleeLoopThread then
        pcall(function() task.cancel(autoParrySapperMeleeLoopThread) end)
        autoParrySapperMeleeLoopThread = nil
    end
end
_G.ArreyStopAutoParrySapperMeleeLoop = stopAutoParrySapperMeleeLoop

local function startAutoParrySapperMeleeLoop()
    if autoParrySapperMeleeLoopThread then return end
    autoParrySapperMeleeLoopRunning = true
    autoParrySapperMeleeLoopThread = task.spawn(function()
        while autoParrySapperMeleeLoopRunning and AutoParrySapperMeleeEnabled do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hasMelee, meleeName = HasMeleeEquipped()
                if hasMelee then
                    local zombiePart, dist = FindNearestZombieForParry(hrp.Position, 8)
                    if zombiePart and dist and dist <= 8 then
                        local remote = GetMeleeRemote()
                        if remote then
                            pcall(function() remote:FireServer("BraceBlock") end)
                        end
                    end
                end
            end
            -- PERF FIX: Increased from 0.08s to 0.15s - parry checks still responsive but less CPU intensive
            task.wait(0.08)
        end
        autoParrySapperMeleeLoopThread = nil
    end)
end
_G.ArreyStartAutoParrySapperMeleeLoop = startAutoParrySapperMeleeLoop

_G.ArreyToggleElements = _G.ArreyToggleElements or {}

SapperGroup:AddDivider()

local ShoveAuraToggle = SapperGroup:AddToggle('ShoveAura', {
    Text = "Shove Aura",
    Default = ShoveAuraEnabled,
    Tooltip = "Auto Shoves Zombies Near You.",
    Callback = function(v)
        ShoveAuraEnabled = v
        if v then
            startShoveAuraLoop()
        else
            stopShoveAuraLoop()
        end
        Library:Notify({
            Title = "Shove Aura",
            Description = v and ("Enabled range: "..tostring(ShoveAuraRange)) or "Disabled",
            Time = 2,
            Icon = v and "zap" or "x",
        })
    end
})
_G.ArreyToggleElements.ShoveAura = ShoveAuraToggle

SapperGroup:AddSlider('ShoveAuraRange', {
    Text = "Shove Range",
    Default = ShoveAuraRange or 12,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Tooltip = "How Far Shove Aura Will Shove",
    Callback = function(val)
        ShoveAuraRange = mathMax(1, mathFloor(tonumber(val) or 1))
        Library:Notify({ Title = "Shove Range", Description = tostring(ShoveAuraRange).." studs", Time = 1 })
    end
})

SapperGroup:AddSlider('ShoveAuraTargets', {
    Text = "Shove Targets",
    Default = ShoveTargets or 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Tooltip = "How many nearest Zombies to target in 1 shove.",
    Callback = function(val)
        ShoveTargets = mathMax(1, mathFloor(tonumber(val) or 1))
    end
})

SapperGroup:AddSlider('ShoveDelay', {
    Text = "Shove Delay",
    Default = ShoveAuraCooldown or 0.10,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Tooltip = "controls how fast to shove.",
    Callback = function(val)
        ShoveAuraCooldown = mathClamp(tonumber(val) or 0.1, 0.01, 0.5)
    end
})

end -- end Sapper scope
do -- Chaplain scope (split to stay under 200 local registers)
-- ===== CLASSES TAB — Chaplain (Auto Bless) =====
local ChaplainGroup = ClassesTab:AddGroupbox({ Side = "Right", Name = "Chaplain", Description = "Blessings and mercy", IconName = "cross" })

local AutoBlessEnabled = false
local AutoMercyEnabled = false
local BlessThreshold = 50         -- numeric threshold
local BlessCooldown = 2           -- seconds between blessings to same player
local MercyCooldown = 2           -- seconds between mercy to same player
local BlessRange = 15             -- proximity requirement (studs)
local MercyRange = 15             -- proximity requirement for mercy (studs)
local BlessData = {}
local MercyData = {}

-- PERF FIX: Clean up BlessData/MercyData when a player leaves so entries don't accumulate.
Players.PlayerRemoving:Connect(function(player)
    local uid = player.UserId or player.Name
    BlessData[uid] = nil
    MercyData[uid] = nil
end)

-- Only look for the Blessing or Divinity tool when it's equipped (in Character). If not equipped, do nothing silently.
local function GetEquippedBlessRemote()
    local localChar = LocalPlayer and LocalPlayer.Character
    if not localChar then return nil end

    -- Check for Blessing tool
    local blessing = localChar:FindFirstChild("Blessing")
    if blessing and blessing:FindFirstChild("RemoteEvent") then
        return blessing:FindFirstChild("RemoteEvent")
    end

    -- Check for Divinity tool
    local divinity = localChar:FindFirstChild("Divinity")
    if divinity and divinity:FindFirstChild("RemoteEvent") then
        return divinity:FindFirstChild("RemoteEvent")
    end

    -- also accept tools with 'bless' or 'divinity' in the name (case-insensitive) when equipped
    for _, child in localChar:GetChildren() do
        if child:IsA("Tool") then
            local nameLower = child.Name:lower()
            if (nameLower:find("bless") or nameLower:find("divinity")) and child:FindFirstChild("RemoteEvent") then
                return child:FindFirstChild("RemoteEvent")
            end
        end
    end
    return nil
end

-- Get equipped Mercy tool remote
local function GetEquippedMercyRemote()
    local localChar = LocalPlayer and LocalPlayer.Character
    if not localChar then return nil end

    local mercy = localChar:FindFirstChild("Mercy")
    if mercy and mercy:FindFirstChild("RemoteEvent") then
        return mercy:FindFirstChild("RemoteEvent")
    end

    -- also accept tools with 'mercy' in the name (case-insensitive) when equipped
    for _, child in localChar:GetChildren() do
        if child:IsA("Tool") and child.Name:lower():find("mercy") and child:FindFirstChild("RemoteEvent") then
            return child:FindFirstChild("RemoteEvent")
        end
    end
    return nil
end

-- Helper: returns true if target player is within range of local player
local function InRangeOfLocal(player, maxRange)
    local localChar = LocalPlayer and LocalPlayer.Character
    if not (localChar and localChar:FindFirstChild("HumanoidRootPart")) then return false end
    if not (player and player.Character) then return false end
    local targetHRP = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    if not targetHRP then return false end
    return (localChar.HumanoidRootPart.Position - targetHRP.Position).Magnitude <= (maxRange or BlessRange)
end

-- Fire bless using the player's humanoid. Fail silently if tool not equipped, out of range, or humanoid missing.
local function FireBlessByPlayer_Silent(player)
    if not player then return false end

    -- require the blessing/divinity tool to be equipped (in character)
    local remote = GetEquippedBlessRemote()
    if not remote then
        return false
    end

    -- must be in range
    if not InRangeOfLocal(player, BlessRange) then
        return false
    end

    local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then
        return false
    end

    local ok, err = pcall(function()
        -- match Medic pattern: remote:FireServer("SendRequest", humanoid)
        remote:FireServer("SendRequest", humanoid)
    end)
    if not ok then
        -- fail silently
        return false
    end

    return true
end

-- Fire mercy using the player's humanoid. Fail silently if tool not equipped, out of range, or humanoid missing.
local function FireMercyByPlayer_Silent(player)
    if not player then return false end

    -- require the mercy tool to be equipped (in character)
    local remote = GetEquippedMercyRemote()
    if not remote then
        return false
    end

    -- must be in range
    if not InRangeOfLocal(player, MercyRange) then
        return false
    end

    local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then
        return false
    end

    local ok, err = pcall(function()
        -- remote:FireServer("SendRequest", humanoid)
        remote:FireServer("SendRequest", humanoid)
    end)
    if not ok then
        -- fail silently
        return false
    end

    return true
end

-- Try common locations for a player's "Infected" value
local function GetPlayerInfectedValue(player)
    local ok, val = pcall(function()
        local wsPlayers = Workspace:FindFirstChild("Players")
        if wsPlayers then
            local wsP = wsPlayers:FindFirstChild(player.Name)
            if wsP and wsP:FindFirstChild("UserStates") and wsP.UserStates:FindFirstChild("Infected") then
                return wsP.UserStates.Infected.Value
            end
        end
        if player:FindFirstChild("UserStates") and player.UserStates:FindFirstChild("Infected") then
            return player.UserStates.Infected.Value
        end
        if player.Character and player.Character:FindFirstChild("UserStates") and player.Character.UserStates:FindFirstChild("Infected") then
            return player.Character.UserStates.Infected.Value
        end
        return nil
    end)
    if ok then return val end
    return nil
end

local autoBlessLoopRunning = false
local autoBlessLoopThread = nil
local function stopAutoBlessLoop()
    autoBlessLoopRunning = false
    if autoBlessLoopThread then
        pcall(function() task.cancel(autoBlessLoopThread) end)
        autoBlessLoopThread = nil
    end
end
_G.ArreyStopAutoBlessLoop = stopAutoBlessLoop

local function startAutoBlessLoop()
    if autoBlessLoopThread then return end
    autoBlessLoopRunning = true
    autoBlessLoopThread = task.spawn(function()
        while autoBlessLoopRunning and AutoBlessEnabled do
        -- PERF FIX: Increased from 0.35s to 0.7s - bless checks don't need sub-second polling
        task.wait(0.7)
        for _, player in Players:GetPlayers() do
            if player and player ~= LocalPlayer then
                    local infectedVal = nil
                    pcall(function()
                        infectedVal = GetPlayerInfectedValue(player)
                    end)

                    if infectedVal ~= nil then
                        -- normalize infectedVal to number
                        local numeric = nil
                        if type(infectedVal) == "number" then
                            numeric = infectedVal
                        elseif type(infectedVal) == "string" then
                            numeric = tonumber(infectedVal)
                        elseif type(infectedVal) == "boolean" then
                            numeric = infectedVal and 1 or 0
                        end

                        local thresholdNum = tonumber(BlessThreshold) or 0

                        if numeric and numeric >= thresholdNum and numeric < 100 then
                            local uid = player.UserId or player.Name
                            local last = BlessData[uid] or 0
                            if time() - last >= (tonumber(BlessCooldown) or 0) then
                                local success = false
                                pcall(function()
                                    success = FireBlessByPlayer_Silent(player)
                                end)
                                if success then
                                    BlessData[uid] = time()
                                    Library:Notify({
                                        Title = "Auto Bless",
                                        Description = "Sent bless to " .. player.Name,
                                        Time = 2,
                                        Icon = "cross"
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        autoBlessLoopThread = nil
    end)
end

-- Auto Mercy loop (only for players with 100% infection)
local autoMercyLoopRunning = false
local autoMercyLoopThread = nil
local function stopAutoMercyLoop()
    autoMercyLoopRunning = false
    if autoMercyLoopThread then
        pcall(function() task.cancel(autoMercyLoopThread) end)
        autoMercyLoopThread = nil
    end
end
_G.ArreyStopAutoMercyLoop = stopAutoMercyLoop

local function startAutoMercyLoop()
    if autoMercyLoopThread then return end
    autoMercyLoopRunning = true
    autoMercyLoopThread = task.spawn(function()
        while autoMercyLoopRunning and AutoMercyEnabled do
        -- PERF FIX: Increased from 0.35s to 0.7s - mercy checks don't need sub-second polling
        task.wait(0.7)
        for _, player in Players:GetPlayers() do
            if player and player ~= LocalPlayer then
                    local infectedVal = nil
                    pcall(function()
                        infectedVal = GetPlayerInfectedValue(player)
                    end)

                    if infectedVal ~= nil then
                        -- normalize infectedVal to number
                        local numeric = nil
                        if type(infectedVal) == "number" then
                            numeric = infectedVal
                        elseif type(infectedVal) == "string" then
                            numeric = tonumber(infectedVal)
                        elseif type(infectedVal) == "boolean" then
                            numeric = infectedVal and 100 or 0
                        end

                        -- Only mercy players with 100% infection
                        if numeric and numeric >= 100 then
                            local uid = player.UserId or player.Name
                            local last = MercyData[uid] or 0
                            if time() - last >= (tonumber(MercyCooldown) or 0) then
                                local success = false
                                pcall(function()
                                    success = FireMercyByPlayer_Silent(player)
                                end)
                                if success then
                                    MercyData[uid] = time()
                                    Library:Notify({
                                        Title = "Auto Mercy",
                                        Description = "Sent mercy to " .. player.Name,
                                        Time = 2,
                                        Icon = "heart"
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        autoMercyLoopThread = nil
    end)
end

-- UI Controls
ChaplainGroup:AddToggle('AutoBless', {
    Text = "Auto Bless Infected Players",
    Default = false,
    Tooltip = "Automatically bless players with infection",
    Callback = function(state)
        AutoBlessEnabled = state
        if state then
            startAutoBlessLoop()
        else
            stopAutoBlessLoop()
        end
        Library:Notify({
            Title = "Chaplain",
            Description = state and "Auto Bless Enabled" or "Auto Bless Disabled",
            Time = 2,
            Icon = state and "cross" or "x"
        })
    end
})

ChaplainGroup:AddToggle('AutoMercy', {
    Text = "Auto Mercy Fully Infected",
    Default = false,
    Tooltip = "Automatically mercy players with 100% infection",
    Callback = function(state)
        AutoMercyEnabled = state
        if state then
            startAutoMercyLoop()
        else
            stopAutoMercyLoop()
        end
        Library:Notify({
            Title = "Chaplain",
            Description = state and "Auto Mercy Enabled" or "Auto Mercy Disabled",
            Time = 2,
            Icon = state and "heart" or "x"
        })
    end
})

ChaplainGroup:AddSlider('InfectedThreshold', {
    Text = "Infected Threshold",
    Default = BlessThreshold or 50,
    Min = 0,
    Max = 99,
    Rounding = 1,
    Tooltip = "Threshold for auto bless (won't bless players at 100%)",
    Callback = function(val)
        BlessThreshold = tonumber(val) or 0
    end
})

end -- end Chaplain scope
end -- end Classes Tab block

do -- // Events Tab — Dracula (unified Kill Aura method + ESP)

    -- ===== SETTINGS (defaults) =====
    local DEBUG = false
    local DraculaLoopInterval = 0.1

    HitDraculaEnabled   = _G.HitDraculaEnabled or false
    DraculaRange        = _G.DraculaRange or 15
    -- Same pacing settings as Kill Aura (same defaults, same throttle).
    DraculaAttackSpeed  = _G.DraculaAttackSpeed or KillAuraAttackSpeed or 0.1
    DraculaRandomness   = _G.DraculaRandomness or KillAuraRandomness or 0
    DraculaEspEnabled   = _G.DraculaEspEnabled or false
    SilverEspEnabled    = _G.SilverEspEnabled or false
    SilverEspColor      = _G.SilverEspColor or c3rgb(180, 220, 255)
    SilverEspShowDistance = (_G.SilverEspShowDistance == nil) and true or _G.SilverEspShowDistance
    SilverEspMaxDistance  = _G.SilverEspMaxDistance or 2000
    DraculaHitboxEnabled  = _G.DraculaHitboxEnabled or false
    DraculaHitboxSize     = _G.DraculaHitboxSize or 10

    -- ===== INTERNALS =====
    local draculaHighlight = nil
    local draculaHighlightModel = nil
    -- Use weak keys so destroyed models get garbage collected
    local silverVisuals = setmetatable({}, { __mode = "k" })  -- [Model] = {Highlight = hl, Billboard = bb, Text = txt, Part = part}

    -- ===== HELPERS =====

    local function getDracula()
        local trans = Workspace:FindFirstChild("Transylvania")
        local modes = trans and trans:FindFirstChild("Modes")
        local boss = modes and modes:FindFirstChild("Boss")
        local drac = boss and boss:FindFirstChild("Dracula")
        if drac then return drac end
        -- Fallback: boss folder may stream in late or sit elsewhere.
        if boss then
            for _, ch in boss:GetChildren() do
                if ch:IsA("Model") and string.find(string.lower(ch.Name), "dracula", 1, true) then
                    return ch
                end
            end
        end
        return nil
    end

    -- Best part to aim at / attach ESP to. Never assigns PrimaryPart
    -- (mutating the game model is what made the old Silver ESP flaky).
    local function getDraculaHead(dracModel)
        if not (dracModel and dracModel:IsA("Model")) then return nil end
        local head = dracModel:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        local hrp = dracModel:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        if dracModel.PrimaryPart and dracModel.PrimaryPart:IsA("BasePart") then
            return dracModel.PrimaryPart
        end
        return dracModel:FindFirstChildWhichIsA("BasePart")
    end

    local function getSilverFolder()
        local trans = Workspace:FindFirstChild("Transylvania")
        local modes = trans and trans:FindFirstChild("Modes")
        local boss = modes and modes:FindFirstChild("Boss")
        local folder = boss and boss:FindFirstChild("SilverTrinkets")
        if folder then return folder end
        -- Fallback: search by name in case the event hierarchy changes.
        if boss then
            for _, ch in boss:GetChildren() do
                if string.find(string.lower(ch.Name), "silver", 1, true) then
                    return ch
                end
            end
        end
        return nil
    end

    local function getTrinketPart(trinket)
        if not (trinket and trinket:IsA("Model")) then return nil end
        if trinket.PrimaryPart and trinket.PrimaryPart:IsA("BasePart") then
            return trinket.PrimaryPart
        end
        return trinket:FindFirstChildWhichIsA("BasePart")
    end

    -- ===== Unified Kill Aura method =====
    -- Dracula uses the EXACT same tool resolution + remote protocol as the
    -- main Kill Aura (Swing "Thrust" + PrepareSwing + HitZombieM on "Head",
    -- or the bayonet pair when a bayonet tool is equipped). The old Dracula
    -- loop used Swing "Side" + HitZombie/"Collision" with random offsets,
    -- which is why it behaved differently.
    local function getDraculaToolAndRemote()
        local shared = _G.ArreyKillAura
        if type(shared) == "table" then
            local tool = shared.getMeleeTool and shared.getMeleeTool()
            if tool then
                local remote = shared.getRemoteForTool and shared.getRemoteForTool(tool)
                if remote then
                    local isBayonet = shared.isBayonetTool and shared.isBayonetTool(tool)
                    return tool, remote, isBayonet
                end
            end
            return nil, nil, false
        end
        -- Fallback (Kill Aura block not loaded): same lookup order, same protocol.
        local char = LocalPlayer and LocalPlayer.Character
        if not char then return nil, nil, false end
        for _, tool in char:GetChildren() do
            if tool:IsA("Tool") then
                local remote = getToolRemote(tool)
                if remote then return tool, remote, false end
            end
        end
        return nil, nil, false
    end

    local function fireDraculaHit(remote, tool, dracModel, isBayonet)
        if not (remote and remote:IsA("RemoteEvent") and dracModel and dracModel.Parent) then return end
        local attackPart = getDraculaHead(dracModel)
        if not (attackPart and attackPart.Parent) then return end
        local attackPos = attackPart.Position
        local char = LocalPlayer.Character
        local playerHead = char and char:FindFirstChild("Head")
        local ok, dir = pcall(function()
            return (attackPos - playerHead.Position).Unit
        end)
        local Direction
        if ok and dir and playerHead then
            Direction = dir
        else
            Direction = v3new(0, 1, 0)
        end
        pcall(function()
            if isBayonet then
                local orig = dracModel:FindFirstChild("Orig")
                local ref = (orig and orig.Value) or dracModel
                remote:FireServer("ThrustBayonet")
                remote:FireServer("Bayonet_HitZombie", ref, attackPos, true, "Head", "Down")
                pcall(function()
                    ref:SetAttribute("WepHitID", tick())
                    ref:SetAttribute("WepHitDirection", Direction * 10)
                    ref:SetAttribute("WepHitPos", attackPos)
                end)
            else
                remote:FireServer("Swing", "Thrust")
                remote:FireServer("PrepareSwing")
                if dracModel and dracModel.Parent then
                    remote:FireServer("HitZombieM", dracModel, attackPos, true, attackPos, "Head", Direction)
                end
            end
        end)
    end

    -- ===== ESP helpers (parented to the models themselves: no CoreGui risk) =====
    local function safeCreateHighlight(adornee, fillColor, outlineColor, fillTransparency)
        local ok, hl = pcall(function()
            local h = makeHighlight(adornee, fillColor or outlineColor, fillTransparency, nil)
            if outlineColor then h.OutlineColor = outlineColor end
            h.Parent = adornee
            return h
        end)
        if not ok then return nil end
        return hl
    end

    local function safeCreateBillboard(attachPart, text)
        local ok, bb, txt = pcall(function()
            local b, t = makeBillboard(attachPart, text or "", c3rgb(255, 255, 255), v3new(0, 3, 0))
            b.Size = UDim2.new(0, 200, 0, 30)
            b.Parent = attachPart
            t.Font = Enum.Font.GothamBold
            t.TextSize = 14
            t.TextScaled = false
            t.TextStrokeTransparency = 0
            return b, t
        end)
        if not ok then return nil, nil end
        return bb, txt
    end

    -- Dracula ESP: recreates on respawn (old code kept a stale highlight
    -- on the dead model forever because it early-returned when non-nil).
    local function updateDraculaESP()
        local drac = getDracula()
        if not DraculaEspEnabled or not drac then
            if draculaHighlight then
                pcall(function() draculaHighlight:Destroy() end)
                draculaHighlight = nil
                draculaHighlightModel = nil
            end
            return
        end
        if draculaHighlight and draculaHighlightModel == drac and draculaHighlight.Parent then
            return
        end
        if draculaHighlight then
            pcall(function() draculaHighlight:Destroy() end)
            draculaHighlight = nil
            draculaHighlightModel = nil
        end
        local hl = safeCreateHighlight(drac, c3rgb(255, 0, 0), c3rgb(255, 255, 255), 0.6)
        if not hl then return end
        draculaHighlight = hl
        draculaHighlightModel = drac
    end

    -- clear all silver visuals
    local function clearSilverESP()
        for model, data in silverVisuals do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            silverVisuals[model] = nil
        end
    end

    -- Improved Silver ESP: no PrimaryPart mutation, visuals live on the
    -- trinkets themselves, distance-culled, color + distance options.
    local function updateSilverESP()
        local silverFolderNow = getSilverFolder()
        if not silverFolderNow then
            clearSilverESP()
            return
        end

        if not SilverEspEnabled then
            clearSilverESP()
            return
        end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hrpPos = hrp and hrp.Position
        local maxDist = tonumber(SilverEspMaxDistance) or 2000
        local espColor = SilverEspColor or c3rgb(180, 220, 255)

        for _, trinket in silverFolderNow:GetChildren() do
            if not trinket:IsA("Model") then continue end

            local mainPart = getTrinketPart(trinket)
            if not mainPart then continue end

            -- Distance cull before creating anything (saves instances).
            if hrpPos then
                local d = (hrpPos - mainPart.Position).Magnitude
                if d > maxDist then
                    local old = silverVisuals[trinket]
                    if old then
                        pcall(function()
                            if old.Highlight then old.Highlight:Destroy() end
                            if old.Billboard then old.Billboard:Destroy() end
                        end)
                        silverVisuals[trinket] = nil
                    end
                    continue
                end
            end

            local data = silverVisuals[trinket]
            -- Recreate if the anchor part changed (model streamed a new part).
            if data and data.Part ~= mainPart then
                pcall(function()
                    if data.Highlight then data.Highlight:Destroy() end
                    if data.Billboard then data.Billboard:Destroy() end
                end)
                silverVisuals[trinket] = nil
                data = nil
            end
            if data and ((not data.Highlight or not data.Highlight.Parent) and (not data.Billboard or not data.Billboard.Parent)) then
                silverVisuals[trinket] = nil
                data = nil
            end

            if not data then
                local hl = safeCreateHighlight(trinket, espColor, c3rgb(255, 255, 255), 0.4)
                local bb, txt = safeCreateBillboard(mainPart, "Silver")
                if not hl and not bb then continue end
                data = { Highlight = hl, Billboard = bb, Text = txt, Part = mainPart }
                silverVisuals[trinket] = data
            else
                -- Live-apply color changes without recreating.
                if data.Highlight then
                    pcall(function()
                        data.Highlight.FillColor = espColor
                        data.Highlight.OutlineColor = c3rgb(255, 255, 255)
                    end)
                end
                if data.Billboard and data.Billboard.Parent ~= mainPart then
                    pcall(function() data.Billboard.Parent = mainPart end)
                    data.Part = mainPart
                end
            end
        end

        -- Update labels and drop collected trinkets.
        for model, data in silverVisuals do
            local part = data.Part
            if not model.Parent or not (part and part.Parent) then
                pcall(function()
                    if data.Highlight then data.Highlight:Destroy() end
                    if data.Billboard then data.Billboard:Destroy() end
                end)
                silverVisuals[model] = nil
            elseif data.Text and data.Billboard then
                if SilverEspShowDistance == false then
                    data.Text.Text = "Silver"
                elseif hrpPos and part then
                    local dist = (hrpPos - part.Position).Magnitude
                    if dist > maxDist then
                        pcall(function()
                            if data.Highlight then data.Highlight:Destroy() end
                            if data.Billboard then data.Billboard:Destroy() end
                        end)
                        silverVisuals[model] = nil
                    else
                        data.Text.Text = strFormat("Silver • %dm", mathFloor(dist + 0.5))
                    end
                end
            end
        end
    end

    -- background updater for Silver ESP
    local silverEspLoopRunning = false
    local silverEspLoopThread = nil
    local function stopSilverEspLoop()
        silverEspLoopRunning = false
        if silverEspLoopThread then
            pcall(function() task.cancel(silverEspLoopThread) end)
            silverEspLoopThread = nil
        end
    end
    _G.ArreyStopSilverEspLoop = stopSilverEspLoop

    local function startSilverEspLoop()
        if silverEspLoopThread then return end
        silverEspLoopRunning = true
        silverEspLoopThread = task.spawn(function()
            while silverEspLoopRunning and SilverEspEnabled do
                pcall(updateSilverESP)
                task.wait(0.25) -- Active: update every 0.25s
            end
            silverEspLoopThread = nil
        end)
    end

    -- ===== Dracula hitbox expander (same trick as the zombie one) =====
    -- Invisible Massless welded parts on HRP (full size) + Head (half size)
    -- so melee raycasts catch Dracula like the zombie Hitbox Expander does.
    local function addDraculaHitboxes(dracModel)
        dracModel = dracModel or getDracula()
        if not (dracModel and dracModel.Parent) then return end
        local size = mathClamp(tonumber(DraculaHitboxSize) or 10, 1, 30)
        local hrp = dracModel:FindFirstChild("HumanoidRootPart")
        if hrp and not dracModel:FindFirstChild("OuterHitbox") then
            pcall(function()
                local part = Instance.new("Part")
                part.Name = "OuterHitbox"
                part.Size = v3new(size, size, size)
                part.Transparency = 1
                part.Anchored = false
                part.CanCollide = false
                part.Massless = true
                part.CanTouch = true
                part.CFrame = hrp.CFrame
                part.Parent = dracModel
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = hrp
                weld.Part1 = part
                weld.Parent = part
            end)
        end
        local head = dracModel:FindFirstChild("Head") or getDraculaHead(dracModel)
        if head and not dracModel:FindFirstChild("HeadHitbox") then
            pcall(function()
                local part = Instance.new("Part")
                part.Name = "HeadHitbox"
                local hs = size / 2
                part.Size = v3new(hs, hs, hs)
                part.Transparency = 1
                part.Anchored = false
                part.CanCollide = false
                part.Massless = true
                part.CanTouch = true
                part.CFrame = head.CFrame
                part.Parent = dracModel
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = head
                weld.Part1 = part
                weld.Parent = part
            end)
        end
    end

    local function removeDraculaHitboxes(dracModel)
        dracModel = dracModel or getDracula()
        if not dracModel then return end
        pcall(function()
            local outer = dracModel:FindFirstChild("OuterHitbox")
            local head = dracModel:FindFirstChild("HeadHitbox")
            if outer then outer:Destroy() end
            if head then head:Destroy() end
        end)
    end

    local function refreshDraculaHitboxes()
        if DraculaHitboxEnabled then
            pcall(addDraculaHitboxes)
        else
            pcall(removeDraculaHitboxes)
        end
    end

    -- Re-apply on respawn/stream-in (loop ensure covers it even if the
    -- boss folder appears later; ChildAdded makes it instant).
    local draculaHitboxLoopRunning = false
    local draculaHitboxLoopThread = nil
    local function stopDraculaHitboxLoop()
        draculaHitboxLoopRunning = false
        if draculaHitboxLoopThread then
            pcall(function() task.cancel(draculaHitboxLoopThread) end)
            draculaHitboxLoopThread = nil
        end
    end
    _G.ArreyStopDraculaHitboxLoop = stopDraculaHitboxLoop

    local function startDraculaHitboxLoop()
        if draculaHitboxLoopThread then return end
        draculaHitboxLoopRunning = true
        draculaHitboxLoopThread = task.spawn(function()
            while draculaHitboxLoopRunning and DraculaHitboxEnabled do
                pcall(addDraculaHitboxes)
                task.wait(1)
            end
            draculaHitboxLoopThread = nil
        end)
    end

    local function refreshDraculaHitboxLoop()
        if DraculaHitboxEnabled then
            startDraculaHitboxLoop()
            refreshDraculaHitboxes()
        else
            stopDraculaHitboxLoop()
            pcall(removeDraculaHitboxes)
        end
    end

    do
        local trans = Workspace:FindFirstChild("Transylvania")
        local modes = trans and trans:FindFirstChild("Modes")
        local boss = modes and modes:FindFirstChild("Boss")
        if boss then
            boss.ChildAdded:Connect(function(child)
                if not DraculaHitboxEnabled then return end
                if child:IsA("Model") and string.find(string.lower(child.Name), "dracula", 1, true) then
                    task.delay(0.5, function()
                        if DraculaHitboxEnabled then pcall(addDraculaHitboxes, child) end
                    end)
                end
            end)
        end
    end

    -- ===== Dracula attack loop: same packets AND same pacing as Kill Aura =====
    local Dracula_nextTick = 0

    local draculaAttackLoopRunning = false
    local draculaAttackLoopThread = nil
    local function stopDraculaAttackLoop()
        draculaAttackLoopRunning = false
        if draculaAttackLoopThread then
            pcall(function() task.cancel(draculaAttackLoopThread) end)
            draculaAttackLoopThread = nil
        end
    end
    _G.ArreyStopDraculaAttackLoop = stopDraculaAttackLoop

    local function startDraculaAttackLoop()
        if draculaAttackLoopThread then return end
        draculaAttackLoopRunning = true
        draculaAttackLoopThread = task.spawn(function()
            while draculaAttackLoopRunning and (HitDraculaEnabled or DraculaEspEnabled) do
                task.wait(DraculaLoopInterval)
                if not HitDraculaEnabled then
                    -- keep ESP in sync (only if ESP enabled)
                    if DraculaEspEnabled then pcall(updateDraculaESP) end
                    continue
                end

                -- Same throttle as Kill Aura: attack-speed gate with random
                -- variation. One hit per cycle — this is what stops the aura
                -- running 5x spam × every 0.1s tick like before.
                local now = time()
                if now < Dracula_nextTick then
                    pcall(updateDraculaESP)
                    continue
                end
                local baseDelay = DraculaAttackSpeed or 0.1
                local randAmount = DraculaRandomness or 0
                if randAmount > 0 then
                    local variation = baseDelay * randAmount
                    baseDelay = baseDelay + (math.random() * variation * 2 - variation)
                end
                Dracula_nextTick = now + baseDelay

                local drac = getDracula()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not (drac and hrp) then
                    pcall(updateDraculaESP)
                    continue
                end

                -- Keep expander parts on Dracula while the aura loop runs.
                if DraculaHitboxEnabled then pcall(addDraculaHitboxes, drac) end

                -- distance check on the aim part (same part we hit)
                local aimPart = getDraculaHead(drac)
                local pivot = aimPart and aimPart.Position
                if not pivot then
                    local ok, pv = pcall(function() return drac:GetPivot().Position end)
                    pivot = (ok and pv) or nil
                end
                if not pivot then
                    pcall(updateDraculaESP)
                    continue
                end
                local dist = (pivot - hrp.Position).Magnitude
                if dist > DraculaRange then
                    pcall(updateDraculaESP)
                    continue
                end

                -- COORDINATION: don't overlap Shove Aura's fire window.
                local coord = _G.AuraCoordination
                if coord and _G.ShoveAuraEnabled then
                    local timeSinceShove = time() - (coord.shoveAuraLastFire or 0)
                    if timeSinceShove < 0.02 then
                        pcall(updateDraculaESP)
                        continue
                    end
                end

                -- Resolve tool + remote via the shared Kill Aura method.
                local tool, remote, isBayonet = getDraculaToolAndRemote()
                if not remote then
                    pcall(updateDraculaESP)
                    continue
                end

                -- update ESP
                pcall(updateDraculaESP)
                if coord then coord.killAuraLastFire = time() end

                -- Single hit per cycle, exactly like Kill Aura (no spam burst).
                if HitDraculaEnabled then
                    fireDraculaHit(remote, tool, drac, isBayonet)
                end
            end
            draculaAttackLoopThread = nil
        end)
    end

    local function refreshDraculaWorkers()
        if HitDraculaEnabled or DraculaEspEnabled then
            startDraculaAttackLoop()
        else
            stopDraculaAttackLoop()
        end
        -- Dracula aura feeds the shared swing-speed buff (same as Kill Aura).
        pcall(function()
            if type(_G.ArreyRefreshKillAuraHeartbeat) == "function" then
                _G.ArreyRefreshKillAuraHeartbeat()
            end
        end)
    end

    -- ===== UI (Events tab — Dracula groupbox, left side) =====
    local DraculaBox = Tabs.EventsDracula

    DraculaBox:AddToggle('HitDracula', {
        Text = "Dracula Killaura",
        Default = HitDraculaEnabled,
        Tooltip = "dracula kill aura.",
        Callback = function(v)
            HitDraculaEnabled = v
            Dracula_nextTick = 0 -- re-arm so the next tick fires promptly
            refreshDraculaWorkers()
            Library:Notify({
                Title = "Dracula",
                Description = v and "Hit Dracula Enabled" or "Hit Dracula Disabled",
                Time = 2,
                Icon = v and "flame" or "x",
            })
            pcall(updateDraculaESP)
        end
    })

    DraculaBox:AddSlider('DraculaAttackSpeed', {
        Text = "Attack Speed",
        Default = DraculaAttackSpeed or 0.1,
        Min = 0.05,
        Max = 1,
        Rounding = 3,
        Tooltip = "Seconds between attacks (lower = faster).",
        Callback = function(v)
            DraculaAttackSpeed = v
            _G.DraculaAttackSpeed = v
        end
    })

    DraculaBox:AddSlider('DraculaRandomness', {
        Text = "Randomness",
        Default = DraculaRandomness or 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Tooltip = "Random delay in attack timing.",
        Callback = function(v)
            DraculaRandomness = v
            _G.DraculaRandomness = v
        end
    })

    DraculaBox:AddSlider('DraculaRange', {
        Text = "Dracula Range",
        Default = DraculaRange or 15,
        Min = 1,
        Max = 25,
        Rounding = 1,
        Tooltip = "Attack distance (25 studs).",
        Callback = function(v) DraculaRange = mathClamp(tonumber(v) or 1, 1, 25) end
    })

    local DraculaHitboxToggle = DraculaBox:AddToggle('DraculaHitbox', {
        Text = "Dracula Hitbox Expander",
        Default = DraculaHitboxEnabled,
        Tooltip = "Expands Dracula hitbox.",
        Callback = function(v)
            DraculaHitboxEnabled = v
            _G.DraculaHitboxEnabled = v
            refreshDraculaHitboxLoop()
            Library:Notify({
                Title = "Dracula Hitbox",
                Description = v and "Hitbox Expander enabled" or "Hitbox Expander disabled",
                Time = 2,
                Icon = v and "scan" or "x",
            })
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.DraculaHitbox = DraculaHitboxToggle

    DraculaBox:AddSlider('DraculaHitboxSize', {
        Text = "Dracula Hitbox Size",
        Default = DraculaHitboxSize or 10,
        Min = 1,
        Max = 30,
        Rounding = 0,
        Tooltip = "Size of the expanded Dracula hitbox.",
        Callback = function(v)
            DraculaHitboxSize = mathClamp(mathFloor(tonumber(v) or 10), 1, 30)
            _G.DraculaHitboxSize = DraculaHitboxSize
            if DraculaHitboxEnabled then
                pcall(removeDraculaHitboxes)
                task.delay(0.05, function()
                    if DraculaHitboxEnabled then pcall(addDraculaHitboxes) end
                end)
            end
        end
    })

    -- Dracula ESP lives in the Events tab now.

    DraculaBox:AddToggle('DraculaEsp', {
        Text = "Dracula ESP",
        Default = DraculaEspEnabled,
        Tooltip = "Highlight Dracula.",
        Callback = function(v)
            DraculaEspEnabled = v
            if not v and draculaHighlight then
                pcall(function() draculaHighlight:Destroy() end)
                draculaHighlight = nil
            end
            refreshDraculaWorkers()
            Library:Notify({
                Title = "Dracula ESP",
                Description = v and "Enabled" or "Disabled",
                Time = 2,
                Icon = v and "eye" or "x",
            })
            pcall(updateDraculaESP)
        end
    })

    DraculaBox:AddToggle('SilverEsp', {
        Text = "Silver ESP",
        Default = SilverEspEnabled,
        Tooltip = "Highlights Silver Trinkets + shows distance.",
        Callback = function(v)
            SilverEspEnabled = v
            _G.SilverEspEnabled = v
            if v then
                startSilverEspLoop()
                pcall(updateSilverESP)
            else
                stopSilverEspLoop()
                clearSilverESP()
            end
            Library:Notify({
                Title = "Silver ESP",
                Description = v and "Enabled" or "Disabled",
                Time = 2,
                Icon = v and "eye" or "x",
            })
        end
    })

    DraculaBox:AddLabel("Silver Color"):AddColorPicker('SilverEspColor', {
        Default = SilverEspColor,
        Callback = function(color)
            SilverEspColor = color
            _G.SilverEspColor = color
        end
    })

    DraculaBox:AddToggle('SilverEspDistance', {
        Text = "Show Silver Distance",
        Default = SilverEspShowDistance,
        Tooltip = "Show distance text under Silver trinkets.",
        Callback = function(v)
            SilverEspShowDistance = v
            _G.SilverEspShowDistance = v
            if SilverEspEnabled then pcall(updateSilverESP) end
        end
    })

    DraculaBox:AddSlider('SilverEspMaxDistance', {
        Text = "Silver Max Distance",
        Default = SilverEspMaxDistance or 2000,
        Min = 100,
        Max = 5000,
        Rounding = 0,
        Suffix = " studs",
        Tooltip = "Hide Silver ESP past this distance.",
        Callback = function(v)
            SilverEspMaxDistance = mathClamp(tonumber(v) or 2000, 100, 5000)
            _G.SilverEspMaxDistance = SilverEspMaxDistance
        end
    })
end -- end Dracula block (Events tab)

do -- // Players Tab

    local PlayersTab = Tabs.ESP

    -- ===== PLAYER ESP =====
    -- Player ESP moved into Player ESP tabbox

    -- flags (global for config save/load)
    ChamsESPEnabled = false
    BillboardESPEnabled = false
    NotifyLowHealthEnabled = false
    -- Use weak keys so entries for players who left are garbage collected
    local PlayerESPData = setmetatable({}, { __mode = "k" })

    -- New toggles for bars (default OFF) - global for config
    ShowHealthBarEnabled = false
    ShowInfectionBarEnabled = false

    -- Configuration variables - global for config
    ChamsFillTransparency = 0.45
    PerformanceModeEnabled = false
    BillboardShowDistance = 5 -- Slider value for "too close" fade
    NotifyGrabbedPinnedEnabled = false

    -- CONFIG (tweak to taste)
    local BILLBOARD_MAX_DISTANCE = 1000 -- generous native MaxDistance; script controls visibility
    -- sits above the player's head (matches Self ESP, which renders correctly)
    local HEALTH_BILLBOARD_OFFSET = v3new(0, 3, 0)
    local STUDS_SMOOTH_ALPHA = 0.22

    -- Make the whole billboard smaller per request
    local BILLBOARD_BASE_SIZE = v2new(120, 52)
    local BILLBOARD_ENABLE_DISTANCE = 1000 -- Max distance to render billboard
    local BILLBOARD_MIN_SCALE = 0.4
    local BILLBOARD_MAX_SCALE = 1.5

    -- Fade animation configuration
    local FADE_DISTANCE_BUFFER = 10 -- Studs for smooth fade transition

    local function CreatePlayerFollowPart(position)
        local part = Instance.new("Part")
        part.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("P_" .. math.random(10000, 99999))
        part.Size = v3new(0.2, 0.2, 0.2)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Transparency = 1
        part.Massless = true
        part.CastShadow = false
        part.CFrame = cfNew(position)
        part.Parent = workspace
        return part
    end

    -- Height BELOW the player where the follow part sits (below the legs).
    local PLAYER_FOLLOW_OFFSET = v3new(0, -6, 0)

    local function RemovePlayerESP(player)
        local data = PlayerESPData[player]
        if not data then return end
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            if data.FollowPart then data.FollowPart:Destroy() end
        end)
        PlayerESPData[player] = nil
    end

    local function CreatePlayerESP(player)
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        RemovePlayerESP(player)

        local highlight = nil
        if ChamsESPEnabled then
            highlight = Instance.new("Highlight")
            -- Use stealth name for anti-detection
            highlight.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("HL_" .. math.random(10000, 99999))
            highlight.Adornee = char
            highlight.FillColor = c3rgb(0, 255, 0)
            highlight.FillTransparency = ChamsFillTransparency
            highlight.OutlineColor = c3rgb(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        end

        local billboard = nil
        local espFrame = nil -- Declare outside to ensure it's in scope
        local nameLabel = nil
        local distanceLabel = nil
        local statusBg = nil
        local statusLabel = nil
        local followPart = nil
        local healthOuter = nil
        local healthInner = nil
        local healthLabelInside = nil
        local infectOuter = nil
        local infectInner = nil
        local infectLabelInside = nil

        if BillboardESPEnabled then
            billboard = Instance.new("BillboardGui")
            -- Use stealth name for anti-detection
            billboard.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BB_" .. math.random(10000, 99999))
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, BILLBOARD_BASE_SIZE.X, 0, BILLBOARD_BASE_SIZE.Y)
            billboard.StudsOffset = HEALTH_BILLBOARD_OFFSET
            billboard.AlwaysOnTop = true
            billboard.LightInfluence = 0
            billboard.MaxDistance = BILLBOARD_MAX_DISTANCE
            billboard.Enabled = true

            followPart = CreatePlayerFollowPart(
                head.Position + PLAYER_FOLLOW_OFFSET
            )
            billboard.Adornee = followPart
            billboard.StudsOffset = v3new(0, 0, 0)

            espFrame = Instance.new("Frame")
            -- Use randomized name for anti-detection
            espFrame.Name = "Frame_" .. math.random(10000, 99999)
            espFrame.Size = UDim2.new(1, 0, 1, 0)
            espFrame.BackgroundColor3 = c3rgb(0, 0, 0)
            espFrame.BackgroundTransparency = PerformanceModeEnabled and 1 or 0.6
            espFrame.BorderSizePixel = 0
            -- espFrame will be parented to billboard at end of block (FIX: deferred)

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 8)
            uiCorner.Parent = espFrame

            -- Status background (semi-transparent rounded box) - used for center MERCY or full-cover grabbed
            statusBg = Instance.new("Frame")
            -- Use randomized name
            statusBg.Name = "Frame_" .. math.random(10000, 99999)
            statusBg.Size = UDim2.new(0.9, 0, 0.36, 0)
            statusBg.Position = UDim2.new(0.05, 0, 0.32, 0) -- centered vertically by default
            statusBg.BackgroundColor3 = c3rgb(0, 0, 0)
            statusBg.BorderSizePixel = 0
            statusBg.BackgroundTransparency = 0.45
            statusBg.Visible = false
            statusBg.Parent = espFrame

            local statusBgCorner = Instance.new("UICorner")
            statusBgCorner.CornerRadius = UDim.new(0, 8)
            statusBgCorner.Parent = statusBg

            -- Status label (centered inside statusBg)
            statusLabel = Instance.new("TextLabel")
            statusLabel.Name = "Status"
            statusLabel.Text = ""
            statusLabel.Size = UDim2.new(1, -8, 1, 0)
            statusLabel.Position = UDim2.new(0, 4, 0, 0)
            statusLabel.BackgroundTransparency = 1
            statusLabel.TextColor3 = c3rgb(255, 255, 255)
            statusLabel.TextStrokeTransparency = 0.3
            statusLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            statusLabel.TextSize = 16
            statusLabel.Font = Enum.Font.SourceSansBold
            statusLabel.TextWrapped = true
            statusLabel.TextXAlignment = Enum.TextXAlignment.Center
            statusLabel.TextYAlignment = Enum.TextYAlignment.Center
            statusLabel.Visible = false
            statusLabel.Parent = statusBg

            -- Name label (small, above the bars)
            nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Name"
            nameLabel.Text = player.Name
            nameLabel.Size = UDim2.new(1, 0, 0.14, 0)
            nameLabel.Position = UDim2.new(0, 0, 0.12, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = c3rgb(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextWrapped = true
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.Parent = espFrame

            -- Health BAR (outer frame + inner fill + centered label)
            healthOuter = Instance.new("Frame")
            healthOuter.Name = "HealthOuter"
            healthOuter.Size = UDim2.new(0.9, 0, 0.16, 0) -- relative to billboard
            healthOuter.Position = UDim2.new(0.05, 0, 0.40, 0)
            healthOuter.BackgroundColor3 = c3rgb(30, 30, 30)
            healthOuter.BorderSizePixel = 0
            healthOuter.Parent = espFrame

            local healthOuterCorner = Instance.new("UICorner")
            healthOuterCorner.CornerRadius = UDim.new(0, 6)
            healthOuterCorner.Parent = healthOuter

            healthInner = Instance.new("Frame")
            healthInner.Name = "HealthInner"
            healthInner.Size = UDim2.new(0, 0, 1, 0) -- will be set per-health percent
            healthInner.Position = UDim2.new(0, 0, 0, 0)
            healthInner.BorderSizePixel = 0
            healthInner.BackgroundColor3 = c3rgb(0, 255, 0)
            healthInner.Parent = healthOuter

            local healthInnerCorner = Instance.new("UICorner")
            healthInnerCorner.CornerRadius = UDim.new(0, 6)
            healthInnerCorner.Parent = healthInner

            healthLabelInside = Instance.new("TextLabel")
            healthLabelInside.Name = "HealthLabelInside"
            healthLabelInside.Text = "100/100"
            healthLabelInside.Size = UDim2.new(1, 0, 1, 0)
            healthLabelInside.Position = UDim2.new(0, 0, 0, 0)
            healthLabelInside.BackgroundTransparency = 1
            healthLabelInside.TextColor3 = c3rgb(255, 255, 255)
            healthLabelInside.TextStrokeTransparency = 0.6
            healthLabelInside.TextStrokeColor3 = c3rgb(0, 0, 0)
            healthLabelInside.TextSize = 12
            healthLabelInside.Font = Enum.Font.SourceSansBold
            healthLabelInside.TextWrapped = false
            healthLabelInside.TextXAlignment = Enum.TextXAlignment.Center
            healthLabelInside.TextYAlignment = Enum.TextYAlignment.Center
            healthLabelInside.Parent = healthOuter

            -- Infection BAR (outer + inner + label)
            infectOuter = Instance.new("Frame")
            infectOuter.Name = "InfectOuter"
            infectOuter.Size = UDim2.new(0.9, 0, 0.16, 0)
            infectOuter.Position = UDim2.new(0.05, 0, 0.60, 0)
            infectOuter.BackgroundColor3 = c3rgb(30, 30, 30)
            infectOuter.BorderSizePixel = 0
            infectOuter.Parent = espFrame

            local infectOuterCorner = Instance.new("UICorner")
            infectOuterCorner.CornerRadius = UDim.new(0, 6)
            infectOuterCorner.Parent = infectOuter

            infectInner = Instance.new("Frame")
            infectInner.Name = "InfectInner"
            infectInner.Size = UDim2.new(0, 0, 1, 0) -- will be set by infection percent
            infectInner.Position = UDim2.new(0, 0, 0, 0)
            infectInner.BorderSizePixel = 0
            infectInner.BackgroundColor3 = c3rgb(0, 255, 0)
            infectInner.Parent = infectOuter

            local infectInnerCorner = Instance.new("UICorner")
            infectInnerCorner.CornerRadius = UDim.new(0, 6)
            infectInnerCorner.Parent = infectInner

            infectLabelInside = Instance.new("TextLabel")
            infectLabelInside.Name = "InfectLabelInside"
            infectLabelInside.Text = "0/100"
            infectLabelInside.Size = UDim2.new(1, 0, 1, 0)
            infectLabelInside.Position = UDim2.new(0, 0, 0, 0)
            infectLabelInside.BackgroundTransparency = 1
            infectLabelInside.TextColor3 = c3rgb(255, 255, 255)
            infectLabelInside.TextStrokeTransparency = 0.6
            infectLabelInside.TextStrokeColor3 = c3rgb(0, 0, 0)
            infectLabelInside.TextSize = 12
            infectLabelInside.Font = Enum.Font.SourceSansBold
            infectLabelInside.TextWrapped = false
            infectLabelInside.TextXAlignment = Enum.TextXAlignment.Center
            infectLabelInside.TextYAlignment = Enum.TextYAlignment.Center
            infectLabelInside.Parent = infectOuter

            -- Distance label (moved down a bit)
            distanceLabel = Instance.new("TextLabel")
            distanceLabel.Name = "Distance"
            distanceLabel.Text = "0 studs"
            distanceLabel.Size = UDim2.new(1, 0, 0.12, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.86, 0)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.TextColor3 = c3rgb(255, 255, 255)
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.SourceSans
            distanceLabel.TextWrapped = true
            distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
            distanceLabel.Parent = espFrame
            espFrame.Parent = billboard  -- full sub-tree enters billboard (still detached from workspace)
            -- Parent to the invisible follow part (escapes player-model scans).
            billboard.Parent = followPart -- ONE reflow: entire billboard tree enters workspace

            -- Parent other objects to allow easy retrieval
        end

        PlayerESPData[player] = {
            Char = char,
            Humanoid = hum,
            Head = head,
            Highlight = highlight,
            Billboard = billboard,
            FollowPart = followPart,
            ESPFrame = espFrame,
            NameLabel = nameLabel,
            -- bars & labels (may be nil if billboard disabled)
            HealthOuter = healthOuter,
            HealthInner = healthInner,
            HealthLabelInside = healthLabelInside,
            InfectOuter = infectOuter,
            InfectInner = infectInner,
            InfectLabelInside = infectLabelInside,
            DistanceLabel = distanceLabel,
            StatusBg = statusBg,
            StatusLabel = statusLabel,
            NotifState = nil,
            LastNotify = 0,
            CurrentStudsOffset = v3new(0, 0, 0),
            DesiredStudsOffset = v3new(0, 0, 0)
        }

        -- PROTECT Player ESP visuals from anti-cheat detection
        pcall(function()
            if _G.protectESP then
                if highlight then _G.protectESP(highlight) end
                if billboard then _G.protectESP(billboard) end
            end
        end)

        -- ensure initial visibility respects settings
        if PlayerESPData[player].HealthOuter then
            PlayerESPData[player].HealthOuter.Visible = ShowHealthBarEnabled and BillboardESPEnabled
        end
        if PlayerESPData[player].InfectOuter then
            PlayerESPData[player].InfectOuter.Visible = ShowInfectionBarEnabled and BillboardESPEnabled
        end
    end

    local function EnsurePlayerBillboard(player)
        if not BillboardESPEnabled then
            return false
        end

        local char = player.Character
        if not char or not char.Parent then
            return false
        end

        local head = char:FindFirstChild("Head")
        if not head then
            return false
        end

        local data = PlayerESPData[player]

        local needsRebuild =
            (not data) or
            (data.Char ~= char) or
            (not data.Billboard) or
            (not data.Billboard.Parent)

        if needsRebuild then
            CreatePlayerESP(player)
            data = PlayerESPData[player]
        end

        if data and data.Billboard then
            data.Char = char
            data.Head = head

            -- Ensure the follow part exists, then re-assert the billboard on it.
            local fp = data.FollowPart
            if not fp or not fp.Parent then
                fp = CreatePlayerFollowPart(head.Position + PLAYER_FOLLOW_OFFSET)
                data.FollowPart = fp
            else
                fp.CFrame = cfNew(head.Position + PLAYER_FOLLOW_OFFSET)
            end
            data.Billboard.Adornee = fp
            if data.Billboard.Parent ~= fp then
                data.Billboard.Parent = fp
            end
            data.Billboard.Enabled = true
            return true
        end

        return false
    end

    -- Create/refresh ESP for all existing players immediately (used when enabling)
    local function CreatePlayerESPForAll()
        for _, pl in Players:GetPlayers() do
            if pl ~= LocalPlayer then
                pcall(CreatePlayerESP, pl)
            end
        end
    end

    -- Pre-built Color3 constants  avoids allocating new Color3 objects every update tick
    local C3_WHITE          = c3rgb(255, 255, 255)

    -- Per-player health-gradient cache: skip c3rgb when pct hasn't changed enough
    local playerHealthPctCache = setmetatable({}, { __mode = "k" })

    -- Tolerant state check, same contract as the kill-aura side: boolean true,
    -- positive numbers, "true" (any case) and Runner attack states all count.
    -- (Pin keeps its own ~= "None" comparison; only Grabbed uses this.)
    local function espStateIndicatesTrue(v)
        if not v or v.Value == nil then return false end
        local val = v.Value
        if val == true then return true end
        local n = tonumber(val)
        if n and n > 0 then return true end
        local vs = tostring(val)
        if vs:lower() == "true" then return true end
        if vs == "RunnerAttack" or vs == "RunnerClaw" or vs == "RunnerVomit" then return true end
        return false
    end

    local function UpdateESPLoop()
        if not (ChamsESPEnabled or BillboardESPEnabled) then return end
        local localChar = LocalPlayer and LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera
        if not camera then return end

        -- PERFORMANCE: Cache workspace.Players reference once per update cycle
        local wPlayers = Workspace:FindFirstChild("Players")
        -- PERFORMANCE: Compute time() once for pulse animations
        local now = time()

        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer then
                local data = PlayerESPData[player]
                local char = player.Character
                if not char or not char.Parent then
                    if data then RemovePlayerESP(player) end
                    continue
                end

                -- Re-create ESP if character changed or components missing
                if not data or data.Char ~= char then
                    CreatePlayerESP(player)
                    data = PlayerESPData[player]
                    if not data then continue end
                end

                if ChamsESPEnabled and (not data.Highlight or not data.Highlight.Parent) then
                    CreatePlayerESP(player)
                    data = PlayerESPData[player]
                    if not data then continue end
                end

                if BillboardESPEnabled then
                    EnsurePlayerBillboard(player)
                    data = PlayerESPData[player]

                    if not data or not data.Billboard then
                        continue
                    end

                    -- Hard-repair the render attachment every update.
                    local currentHead = char:FindFirstChild("Head")
                    if currentHead then
                        data.Head = currentHead
                        local fp = data.FollowPart
                        if not fp or not fp.Parent then
                            fp = CreatePlayerFollowPart(currentHead.Position + PLAYER_FOLLOW_OFFSET)
                            data.FollowPart = fp
                        else
                            fp.CFrame = cfNew(currentHead.Position + PLAYER_FOLLOW_OFFSET)
                        end
                        data.Billboard.Adornee = fp
                        if data.Billboard.Parent ~= fp then
                            data.Billboard.Parent = fp
                        end
                        data.Billboard.MaxDistance = BILLBOARD_MAX_DISTANCE
                        data.Billboard.Enabled = true
                    end
                end

                local hum = data.Humanoid
                if not hum then continue end
                local health, max, percent
                local okH = true
                if not hum.Parent then okH = false end
                if okH then
                    health = hum.Health
                    max = hum.MaxHealth
                end
                if not okH or not health then continue end
                max = (max and max > 0) and max or 1
                percent = mathClamp(health / max, 0, 1)

                -- Check grabbed/pinned/infected
                local grabbed = false
                local pinned = false
                local infectionLevel = 0
                if wPlayers then
                    -- PERF FIX: Cache workspace player folder to avoid FindFirstChild every tick
                    local playerFolder = data._wsFolder
                    if not playerFolder or not playerFolder.Parent then
                        playerFolder = wPlayers:FindFirstChild(player.Name)
                        data._wsFolder = playerFolder
                    end
                    if playerFolder then
                        -- PERF FIX: Cache UserStates reference
                        local userStates = data._userStates
                        if not userStates or not userStates.Parent then
                            userStates = playerFolder:FindFirstChild("UserStates")
                            data._userStates = userStates
                        end
                        if userStates then
                            local grabbedVal = data._grabbedVal
                            if not grabbedVal or not grabbedVal.Parent then
                                grabbedVal = userStates:FindFirstChild("Grabbed")
                                data._grabbedVal = grabbedVal
                            end
                            grabbed = espStateIndicatesTrue(grabbedVal)
                            local pinVal = data._pinVal
                            if not pinVal or not pinVal.Parent then
                                pinVal = userStates:FindFirstChild("Pin")
                                data._pinVal = pinVal
                            end
                            pinned = tostring(pinVal and pinVal.Value or "None") ~= "None"
                            local infectedVal = data._infectedVal
                            if not infectedVal or not infectedVal.Parent then
                                infectedVal = userStates:FindFirstChild("Infected")
                                data._infectedVal = infectedVal
                            end
                            infectionLevel = infectedVal and tonumber(infectedVal.Value) or 0
                        end
                    end
                end

                -- distance calculation
                local playerRoot = char:FindFirstChild("HumanoidRootPart")
                local dist = nil
                if localRoot and playerRoot then
                    dist = (localRoot.Position - playerRoot.Position).Magnitude
                end

                -- CRITICAL FIX: Proper distance-based fade logic
                local fadeFactor = 1 -- 1 = fully visible, 0 = fully transparent
                local shouldRender = true

                if dist then
                    -- Disable if beyond max render distance
                    if dist >= BILLBOARD_ENABLE_DISTANCE then
                        shouldRender = false
                    end

                    -- Apply fade effect if within "too close" range (slider)
                    if BillboardShowDistance > 0 and dist < BillboardShowDistance then
                        local fadeStart = mathMax(BillboardShowDistance - FADE_DISTANCE_BUFFER, 0)

                        if dist <= fadeStart then
                            fadeFactor = 0.5 -- Never fully hidden up close
                        else
                            -- Smooth fade from 0.5 to 1
                            fadeFactor = mathClamp((dist - fadeStart) / (BillboardShowDistance - fadeStart), 0.5, 1)
                        end
                    end
                end

                ----------------------------------------------------------------
                ----------------------------------------------------------------

                -- Determine base transparency just for the main background frame
                local frameTransparency
                local isGrabbedPinned = grabbed or pinned
                local isMercy = false
                do
                    local shouldBeRed = isGrabbedPinned or infectionLevel >= 70
                    -- if PerformanceModeEnabled => hide only the background frame
                    local baseTransparency = PerformanceModeEnabled and 1 or (shouldBeRed and 0.4 or 0.6)
                    frameTransparency = baseTransparency + (1 - fadeFactor) * 0.5
                end

                -- FIX: Only write background transparency when fadeFactor changed
                local fadeChanged = data._lastFadeFactor ~= fadeFactor
                if fadeChanged then
                    data._lastFadeFactor = fadeFactor
                end
                if data.ESPFrame and (fadeChanged or data._lastFrameTrans ~= frameTransparency) then
                    data._lastFrameTrans = frameTransparency
                    data.ESPFrame.BackgroundTransparency = frameTransparency
                end
                if data.StatusBg and fadeChanged then
                    data.StatusBg.BackgroundTransparency = mathClamp(
                        (PerformanceModeEnabled and 0.7 or 0.45) + (1 - fadeFactor) * 0.3,
                        0, 1
                    )
                end

                -- === Bars have their own transparency, independent from PerformanceModeEnabled ===
                if fadeChanged then
                    -- Health bar
                    if data.HealthOuter then
                        local healthOuterTransp = 0.3 + (1 - fadeFactor) * 0.4
                        data.HealthOuter.BackgroundTransparency = mathClamp(healthOuterTransp, 0, 1)
                    end
                    if data.HealthInner then
                        local healthInnerTransp = (1 - fadeFactor) * 0.25
                        data.HealthInner.BackgroundTransparency = mathClamp(healthInnerTransp, 0, 1)
                    end
                    if data.HealthLabelInside then
                        data.HealthLabelInside.TextTransparency = 1 - fadeFactor
                    end

                    -- Infection bar
                    if data.InfectOuter then
                        local infectOuterTransp = 0.3 + (1 - fadeFactor) * 0.4
                        data.InfectOuter.BackgroundTransparency = mathClamp(infectOuterTransp, 0, 1)
                    end
                    if data.InfectInner then
                        local infectInnerTransp = (1 - fadeFactor) * 0.25
                        data.InfectInner.BackgroundTransparency = mathClamp(infectInnerTransp, 0, 1)
                    end
                    if data.InfectLabelInside then
                        data.InfectLabelInside.TextTransparency = 1 - fadeFactor
                    end
                end

                ----------------------------------------------------------------
                ----------------------------------------------------------------

                -- Guard Visible writes  only write when value changes
                if data.StatusBg and data.StatusBg.Visible    then data.StatusBg.Visible = false end
                if data.StatusLabel and data.StatusLabel.Visible then data.StatusLabel.Visible = false end
                if data.NameLabel and not data.NameLabel.Visible  then data.NameLabel.Visible = true end
                if data.HealthOuter and data.HealthOuter.Visible ~= ShowHealthBarEnabled then
                    data.HealthOuter.Visible = ShowHealthBarEnabled
                end
                if data.InfectOuter and data.InfectOuter.Visible ~= ShowInfectionBarEnabled then
                    data.InfectOuter.Visible = ShowInfectionBarEnabled
                end
                if data.DistanceLabel and not data.DistanceLabel.Visible then data.DistanceLabel.Visible = true end

                -- ESPFrame BackgroundColor3 is always black  no need to reset it every frame

                -- Normal chams (skip gradient write if health hasn't moved >1%)
                if ChamsESPEnabled and data.Highlight then
                    local cachedPct = playerHealthPctCache[player] or -1
                    if mathAbs(percent - cachedPct) >= 0.01 then
                        playerHealthPctCache[player] = percent
                        local r = mathFloor(255 * (1 - percent))
                        local g = mathFloor(255 * percent)
                        local healthColor = c3rgb(r, g, 0)
                        -- Team ESP: use team color if enabled
                        if _G._PlayerESP_TeamESPEnabled and _G._PlayerESP_getTeamColor then
                            local tc = _G._PlayerESP_getTeamColor(player)
                            if tc then
                                data.Highlight.FillColor = tc
                                data.Highlight.OutlineColor = tc
                            else
                                data.Highlight.FillColor = healthColor
                                data.Highlight.OutlineColor = C3_WHITE
                            end
                        else
                            data.Highlight.FillColor = healthColor
                            data.Highlight.OutlineColor = C3_WHITE
                        end
                        data.Highlight.FillTransparency = ChamsFillTransparency
                    end
                end

                -- Billboard updates
                if BillboardESPEnabled and data.Billboard then
                    -- FIX: Only write .Enabled when it actually changes
                    if data.Billboard.Enabled ~= shouldRender then
                        data.Billboard.Enabled = shouldRender
                    end

                    if shouldRender then
                        -- Scale calculation
                        local scale = 1
                        if dist and dist < BILLBOARD_ENABLE_DISTANCE then
                            scale = mathClamp(40 / mathMax(dist, 1), BILLBOARD_MIN_SCALE, BILLBOARD_MAX_SCALE)
                        end

                        -- FIX: Only resize billboard when scale changes by more than 2px
                        local w = mathFloor(BILLBOARD_BASE_SIZE.X * scale)
                        local h = mathFloor(BILLBOARD_BASE_SIZE.Y * scale)
                        if data._lastBBW ~= w or data._lastBBH ~= h then
                            data._lastBBW = w
                            data._lastBBH = h
                            data.Billboard.Size = UDim2.new(0, w, 0, h)

                            -- FIX: Only recompute text sizes when billboard size changed
                            local baseTextSize = mathMax(mathFloor(12 * scale), 8)
                            local nameTextSize = mathMax(mathFloor(14 * scale), 8)
                            local statusSize   = mathMax(mathFloor(16 * scale), 8)

                            if data.StatusLabel then
                                data.StatusLabel.TextSize = statusSize
                            end
                            if data.NameLabel then
                                data.NameLabel.TextSize = nameTextSize
                            end
                            if data.DistanceLabel then
                                data.DistanceLabel.TextSize = baseTextSize
                            end
                            if data.HealthLabelInside then
                                data.HealthLabelInside.TextSize = mathMax(baseTextSize - 2, 8)
                            end
                            if data.InfectLabelInside then
                                data.InfectLabelInside.TextSize = mathMax(baseTextSize - 2, 8)
                            end
                        end
                        local baseTextSize = mathMax(mathFloor(12 * scale), 8) -- needed below

                        -- FIX: player.Name never changes after join  only write once (first tick it's nil)
                        if data.NameLabel and data._nameSet ~= player.Name then
                            data._nameSet = player.Name
                            data.NameLabel.Text = player.Name
                        end
                        -- FIX: Only write TextTransparency when fadeFactor actually changes
                        if data.NameLabel then
                            local newTrans = 1 - fadeFactor
                            if data._lastFade ~= newTrans then
                                data._lastFade = newTrans
                                data.NameLabel.TextTransparency = newTrans
                                data.NameLabel.TextStrokeTransparency = 0.5 + (1 - fadeFactor) * 0.5
                            end
                        end

                        -- Health bar update (hide when grabbed/pinned or mercy)
                        if data.HealthOuter and data.HealthInner and ShowHealthBarEnabled and (not isGrabbedPinned) and (not isMercy) then
                            local healthPercent = percent
                            data.HealthInner.Size = UDim2.new(healthPercent, 0, 1, 0)
                            -- Only recompute gradient color if health changed enough
                            local cachedPct2 = (playerHealthPctCache[player] or -1)
                            if mathAbs(healthPercent - cachedPct2) >= 0.01 then
                                local healthR = mathFloor(255 * (1 - healthPercent))
                                local healthG = mathFloor(255 * healthPercent)
                                data.HealthInner.BackgroundColor3 = c3rgb(healthR, healthG, 0)
                                if not (ChamsESPEnabled and data.Highlight) then
                                    playerHealthPctCache[player] = healthPercent
                                end
                            end
                            if data.HealthLabelInside then
                                -- PERF FIX #6: Only write .Text when value changes
                                local healthText = mathFloor(health) .. "/" .. mathFloor(max)
                                if data._lastHealthText ~= healthText then
                                    data._lastHealthText = healthText
                                    data.HealthLabelInside.Text = healthText
                                end
                                -- FIX: TextSize now set only when scale changes (above); skip here
                                data.HealthLabelInside.TextTransparency = 1 - fadeFactor
                            end
                            data.HealthOuter.Visible = true
                        elseif data.HealthOuter then
                            data.HealthOuter.Visible = false
                            if data.HealthInner then data.HealthInner.Size = UDim2.new(0,0,1,0) end
                        end

                        -- Infection bar update (hide only when grabbed/pinned; show during mercy)
                        if data.InfectOuter and data.InfectInner and ShowInfectionBarEnabled and (not isGrabbedPinned) then
                            local infectPercent = mathClamp((infectionLevel or 0) / 100, 0, 1)
                            data.InfectInner.Size = UDim2.new(infectPercent, 0, 1, 0)
                            -- Only recompute if infection changed meaningfully
                            local cachedInfect = data._lastInfectPct or -1
                            if mathAbs(infectPercent - cachedInfect) >= 0.01 then
                                data._lastInfectPct = infectPercent
                                local infectR = mathFloor(255 * infectPercent)
                                local infectG = mathFloor(255 * (1 - infectPercent))
                                data.InfectInner.BackgroundColor3 = c3rgb(infectR, infectG, 0)
                            end
                            if data.InfectLabelInside then
                                -- PERF FIX #6: Only write .Text when value changes
                                local infectText = mathFloor(infectionLevel) .. "/100"
                                if data._lastInfectText ~= infectText then
                                    data._lastInfectText = infectText
                                    data.InfectLabelInside.Text = infectText
                                end
                                -- FIX: TextSize now set only when scale changes (above); skip here
                                data.InfectLabelInside.TextTransparency = 1 - fadeFactor
                            end
                            data.InfectOuter.Visible = true
                        elseif data.InfectOuter then
                            data.InfectOuter.Visible = false
                            if data.InfectInner then data.InfectInner.Size = UDim2.new(0,0,1,0) end
                        end

                        if data.DistanceLabel and data.DistanceLabel.Visible then
                            -- PERF: Only rebuild string when distance changes by 1 stud
                            local flooredDist = mathFloor(dist or 0)
                            if flooredDist ~= (data._lastDist or -1) then
                                data._lastDist = flooredDist
                                data.DistanceLabel.Text = flooredDist .. " studs"
                            end
                            data.DistanceLabel.TextTransparency = 1 - fadeFactor
                            data.DistanceLabel.TextStrokeTransparency = 0.5 + (1 - fadeFactor) * 0.5
                        end
                    end

                local curOff = data.CurrentStudsOffset
                if curOff then
                    local cx, cy, cz = curOff.X, curOff.Y, curOff.Z
                    if cx * cx + cy * cy + cz * cz > 0.0001 then
                        curOff = curOff:Lerp(v3new(0, 0, 0), STUDS_SMOOTH_ALPHA)
                        data.CurrentStudsOffset = curOff
                        data.Billboard.StudsOffset = curOff
                    end
                end
            end
        end
    end
    end

    -- PERFORMANCE: Throttle Player ESP updates
    local playerESPLastUpdate = 0
    local PLAYER_ESP_UPDATE_INTERVAL = 0.4 -- PERF FIX: Increased from 0.25s to 0.4s - ESP updates don't need high frequency, reduces CPU usage significantly
    local playerESPHeartbeatConn = nil -- stored so it can be disconnected if needed

    -- ===== DEDICATED PLAYER BILLBOARD FOLLOW LOOP =====
    local playerFollowConn = nil
    local playerFollowLast = 0
    local PLAYER_FOLLOW_INTERVAL = 0.033

    local function UpdatePlayerFollowParts()
        if not BillboardESPEnabled then return end
        for player, data in PlayerESPData do
            if data and data.Billboard and data.Billboard.Parent then
                local char = player.Character
                if char and char.Parent then
                    -- PERF: prefer the cached head ref; only re-resolve when stale
                    local head = (data.Head and data.Head.Parent) and data.Head or char:FindFirstChild("Head")
                    if head and head ~= data.Head then data.Head = head end
                    if head then
                        local fp = data.FollowPart
                        if not fp or not fp.Parent then
                            fp = CreatePlayerFollowPart(head.Position + PLAYER_FOLLOW_OFFSET)
                            data.FollowPart = fp
                            data.Billboard.Adornee = fp
                            data.Billboard.Parent = fp
                        else
                            fp.CFrame = cfNew(head.Position + PLAYER_FOLLOW_OFFSET)
                        end
                    end
                end
            end
        end
    end

    local function startPlayerFollowLoop()
        if playerFollowConn then return end
        playerFollowConn = RunService.Heartbeat:Connect(function()
            local now = time()
            if now - playerFollowLast < PLAYER_FOLLOW_INTERVAL then return end
            playerFollowLast = now
            UpdatePlayerFollowParts()
        end)
    end

    local function stopPlayerFollowLoop()
        if playerFollowConn then
            playerFollowConn:Disconnect()
            playerFollowConn = nil
        end
    end

    local function startPlayerESPLoop()
        if playerESPHeartbeatConn then return end -- already running
        -- PERF FIX: Only start if at least one ESP type is enabled
        if not ChamsESPEnabled and not BillboardESPEnabled then return end
        playerESPLastUpdate = 0 -- reset so first tick runs immediately
        playerESPHeartbeatConn = RunService.Heartbeat:Connect(function()
            local now = time()
            if now - playerESPLastUpdate < PLAYER_ESP_UPDATE_INTERVAL then return end
            playerESPLastUpdate = now
            UpdateESPLoop()
        end)
        if BillboardESPEnabled then
            startPlayerFollowLoop()
        end
    end
    local function stopPlayerESPLoop()
        stopPlayerFollowLoop()
        if playerESPHeartbeatConn then
            playerESPHeartbeatConn:Disconnect()
            playerESPHeartbeatConn = nil
        end
    end

    _G.ArreyConns = _G.ArreyConns or {}
    if _G.ArreyConns.playerRemoving then pcall(function() _G.ArreyConns.playerRemoving:Disconnect() end) end
    if _G.ArreyConns.playerAdded then pcall(function() _G.ArreyConns.playerAdded:Disconnect() end) end
    _G.ArreyConns.playerRemoving = Players.PlayerRemoving:Connect(RemovePlayerESP)
    _G.ArreyConns.playerAdded = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(char)
            if not (ChamsESPEnabled or BillboardESPEnabled) then
                return
            end

            task.spawn(function()
                local hum = char:WaitForChild("Humanoid", 10)
                local head = char:WaitForChild("Head", 10)
                if hum and head and char.Parent and p.Character == char then
                    pcall(CreatePlayerESP, p)
                end
            end)
        end)

        task.spawn(function()
            task.wait(0.4)
            if (ChamsESPEnabled or BillboardESPEnabled) and p.Character then
                pcall(CreatePlayerESP, p)
            end
        end)
    end)

    Tabs.PlayerESP:AddToggle('ChamsESP', {
        Text = "Players Chams ESP",
        Default = false,
        Tooltip = "Show Chams ESP on Players",
        Callback = function(state)
            ChamsESPEnabled = state
            if state then
                startPlayerESPLoop() -- PERF FIX: start heartbeat on demand
                CreatePlayerESPForAll()
                Library:Notify({
                    Title = "Player ESP",
                    Description = "Player Chams ESP enabled",
                    Time = 2,
                    Icon = "eye",
                })
            else
                for p in PlayerESPData do
                    local data = PlayerESPData[p]
                    if data and data.Highlight then
                        data.Highlight:Destroy()
                        data.Highlight = nil
                    end
                end
                -- PERF FIX: stop heartbeat if both ESP types are off
                if not BillboardESPEnabled then stopPlayerESPLoop() end
                Library:Notify({
                    Title = "Player ESP",
                    Description = "Player Chams ESP disabled",
                    Time = 2,
                    Icon = "eye-off",
                })
            end
        end
    })

    Tabs.PlayerESP:AddToggle('BillboardESP', {
        Text = "Players Billboard ESP",
        Default = false,
        Tooltip = "Show Billboard Text On Players",
        Callback = function(state)
            BillboardESPEnabled = state
            if state then
                for _, player in Players:GetPlayers() do
                    if player ~= LocalPlayer and player.Character then
                        pcall(function()
                            CreatePlayerESP(player)
                            EnsurePlayerBillboard(player)
                        end)
                    end
                end

                startPlayerESPLoop()
                startPlayerFollowLoop()
                pcall(UpdateESPLoop)

                -- Refresh visibility after the rebuild.
                for _, data in PlayerESPData do
                    if data then
                        if data.Billboard then
                            -- Re-assert onto the invisible follow part below the player.
                            local fp = data.FollowPart
                            if not fp or not fp.Parent then
                                local char = data.Char
                                local head = char and char:FindFirstChild("Head")
                                if head then
                                    fp = CreatePlayerFollowPart(head.Position + PLAYER_FOLLOW_OFFSET)
                                    data.FollowPart = fp
                                end
                            end
                            if fp then
                                data.Billboard.Adornee = fp
                                data.Billboard.Parent = fp
                            end
                            data.Billboard.Enabled = true
                        end

                        if data.HealthOuter then
                            data.HealthOuter.Visible = ShowHealthBarEnabled
                        end

                        if data.InfectOuter then
                            data.InfectOuter.Visible = ShowInfectionBarEnabled
                        end
                    end
                end

                Library:Notify({
                    Title = "Player ESP",
                    Description = "Player Billboard ESP enabled",
                    Time = 2,
                    Icon = "eye",
                })
            else
                for _, data in PlayerESPData do
                    if data and data.Billboard then
                        data.Billboard.Enabled = false
                    end

                    if data and data.HealthOuter then
                        data.HealthOuter.Visible = false
                    end

                    if data and data.InfectOuter then
                        data.InfectOuter.Visible = false
                    end
                end

                if not ChamsESPEnabled then
                    stopPlayerESPLoop()
                end

                Library:Notify({
                    Title = "Player ESP",
                    Description = "Player Billboard ESP disabled",
                    Time = 2,
                    Icon = "eye-off",
                })
            end
        end
    })

    -- ===== SELF ESP SECTION =====
    -- Self ESP moved into Player ESP tabbox

    local SelfESPEnabled = false
    local SelfBillboardEnabled = false
    local SelfNoBillboardBg = false
    local SelfHealthBarESPEnabled = false
    local SelfInfectionBarESPEnabled = false
    local selfESPData = { Highlight = nil, Billboard = nil, ESPFrame = nil, HealthInner = nil, HealthLabel = nil, HealthOuter = nil, InfectionInner = nil, InfectionLabel = nil, InfectionOuter = nil }

    local function RemoveSelfESP()
        if selfESPData.Highlight then
            pcall(function() selfESPData.Highlight:Destroy() end)
            selfESPData.Highlight = nil
        end
        if selfESPData.Billboard then
            pcall(function() selfESPData.Billboard:Destroy() end)
            selfESPData.Billboard = nil
            selfESPData.ESPFrame = nil
            selfESPData.HealthLabel = nil
            selfESPData.HealthInner = nil
            selfESPData.HealthOuter = nil
            selfESPData.InfectionOuter = nil
            selfESPData.InfectionInner = nil
            selfESPData.InfectionLabel = nil
        end
    end

    local function CreateSelfESP()
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        RemoveSelfESP()

        -- Create Highlight (Chams)
        if SelfESPEnabled then
            local hl = Instance.new("Highlight")
            hl.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("HL_Self_" .. math.random(10000, 99999))
            hl.Adornee = char
            hl.FillColor = c3rgb(0, 200, 255) -- Cyan for self
            hl.OutlineColor = c3rgb(255, 255, 255)
            hl.FillTransparency = 0.45
            hl.OutlineTransparency = 0
            hl.Parent = char
            selfESPData.Highlight = hl

            pcall(function()
                if _G.protectESP then _G.protectESP(hl) end
            end)
        end

        -- Create Billboard (matching Player ESP style)
        if SelfBillboardEnabled then
            -- Compute height: 58 base (name+you) + 20 per bar row enabled
            local bbHeight = 58
            if SelfHealthBarESPEnabled  then bbHeight = bbHeight + 20 end
            if SelfInfectionBarESPEnabled then bbHeight = bbHeight + 20 end

            local bb = Instance.new("BillboardGui")
            bb.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BB_Self_" .. math.random(10000, 99999))
            bb.Adornee = head
            bb.Size = UDim2.new(0, 160, 0, bbHeight)
            bb.StudsOffset = v3new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.LightInfluence = 0
            bb.MaxDistance = 150
            -- PERF FIX #7: Do NOT parent yet  build entire child tree first, then parent for ONE reflow.
            selfESPData.Billboard = bb

            local espFrame = Instance.new("Frame")
            espFrame.Name = "Frame_" .. math.random(10000, 99999)
            espFrame.Size = UDim2.new(1, 0, 1, 0)
            espFrame.BackgroundColor3 = c3rgb(0, 0, 0)
            espFrame.BackgroundTransparency = SelfNoBillboardBg and 1 or 0.6
            espFrame.BorderSizePixel = 0
            espFrame.Parent = bb
            selfESPData.ESPFrame = espFrame

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 8)
            uiCorner.Parent = espFrame

            -- Name label (absolute pixels for stable layout)
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Name"
            nameLabel.Text = LocalPlayer.Name
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Position = UDim2.new(0, 0, 0, 2)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = c3rgb(0, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            nameLabel.TextSize = 16
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextWrapped = true
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.Parent = espFrame

            -- (YOU) label
            local youLabel = Instance.new("TextLabel")
            youLabel.Name = "YouLabel"
            youLabel.Text = "(YOU)"
            youLabel.Size = UDim2.new(1, 0, 0, 14)
            youLabel.Position = UDim2.new(0, 0, 0, 23)
            youLabel.BackgroundTransparency = 1
            youLabel.TextColor3 = c3rgb(180, 255, 255)
            youLabel.TextStrokeTransparency = 0.5
            youLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            youLabel.TextSize = 13
            youLabel.Font = Enum.Font.SourceSans
            youLabel.TextWrapped = true
            youLabel.TextXAlignment = Enum.TextXAlignment.Center
            youLabel.Parent = espFrame

            --  Health Bar row (inside billboard)
            local hpRowY = 40  -- pixels from top of frame
            local healthOuter = Instance.new("Frame")
            healthOuter.Name = "HealthOuter"
            healthOuter.Size = UDim2.new(0, 144, 0, 15)
            healthOuter.Position = UDim2.new(0, 8, 0, hpRowY)
            healthOuter.BackgroundColor3 = c3rgb(30, 30, 30)
            healthOuter.BorderSizePixel = 0
            healthOuter.Visible = SelfHealthBarESPEnabled
            healthOuter.Parent = espFrame
            Instance.new("UICorner", healthOuter).CornerRadius = UDim.new(0, 5)
            selfESPData.HealthOuter = healthOuter

            local healthInner = Instance.new("Frame")
            healthInner.Name = "HealthInner"
            healthInner.Size = UDim2.new(1, 0, 1, 0)
            healthInner.BorderSizePixel = 0
            healthInner.BackgroundColor3 = c3rgb(0, 255, 0)
            healthInner.Parent = healthOuter
            Instance.new("UICorner", healthInner).CornerRadius = UDim.new(0, 5)
            selfESPData.HealthInner = healthInner

            local healthLabel = Instance.new("TextLabel")
            healthLabel.Name = "HealthLabelInside"
            healthLabel.Text = "100/100"
            healthLabel.Size = UDim2.new(1, 0, 1, 0)
            healthLabel.BackgroundTransparency = 1
            healthLabel.TextColor3 = c3rgb(255, 255, 255)
            healthLabel.TextStrokeTransparency = 0.6
            healthLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            healthLabel.TextSize = 11
            healthLabel.Font = Enum.Font.SourceSansBold
            healthLabel.TextWrapped = false
            healthLabel.TextXAlignment = Enum.TextXAlignment.Center
            healthLabel.TextYAlignment = Enum.TextYAlignment.Center
            healthLabel.Parent = healthOuter
            selfESPData.HealthLabel = healthLabel

            --  Infection Bar row (inside billboard, below health bar)
            local infRowY = hpRowY + (SelfHealthBarESPEnabled and 18 or 0)
            local infOuter = Instance.new("Frame")
            infOuter.Name = "InfectionOuter"
            infOuter.Size = UDim2.new(0, 144, 0, 15)
            infOuter.Position = UDim2.new(0, 8, 0, infRowY)
            infOuter.BackgroundColor3 = c3rgb(30, 30, 30)
            infOuter.BorderSizePixel = 0
            infOuter.Visible = SelfInfectionBarESPEnabled
            infOuter.Parent = espFrame
            Instance.new("UICorner", infOuter).CornerRadius = UDim.new(0, 5)
            selfESPData.InfectionOuter = infOuter

            local infInner = Instance.new("Frame")
            infInner.Name = "InfInner"
            infInner.Size = UDim2.new(0, 0, 1, 0)
            infInner.BackgroundColor3 = c3rgb(0, 220, 80)
            infInner.BorderSizePixel = 0
            infInner.Parent = infOuter
            Instance.new("UICorner", infInner).CornerRadius = UDim.new(0, 5)
            selfESPData.InfectionInner = infInner

            local infLabel = Instance.new("TextLabel")
            infLabel.Name = "InfLabel"
            infLabel.Size = UDim2.new(1, 0, 1, 0)
            infLabel.BackgroundTransparency = 1
            infLabel.Text = "0%"
            infLabel.TextColor3 = c3rgb(200, 255, 200)
            infLabel.TextStrokeTransparency = 0.5
            infLabel.TextStrokeColor3 = c3rgb(0, 0, 0)
            infLabel.TextSize = 10
            infLabel.Font = Enum.Font.SourceSansBold
            infLabel.TextXAlignment = Enum.TextXAlignment.Center
            infLabel.TextYAlignment = Enum.TextYAlignment.Center
            infLabel.Parent = infOuter
            selfESPData.InfectionLabel = infLabel

            pcall(function()
                if _G.protectESP then _G.protectESP(bb) end
            end)

            -- PERF FIX #7: Parent billboard LAST  entire sub-tree enters workspace in ONE reflow.
            bb.Parent = head
        end
    end  -- end of CreateSelfESP

    -- Update self health display (event-driven: no polling loop, no redundant writes)
    local selfHealthConn = nil
    local selfLastHealthPct = -1 -- cached to skip redundant Color3/Size writes

    local COLOR_GREEN  = c3rgb(0, 255, 0)
    local COLOR_YELLOW = c3rgb(255, 255, 0)
    local COLOR_RED    = c3rgb(255, 0, 0)
    local COLOR_WHITE  = c3rgb(255, 255, 255)

    local function UpdateSelfHealth(hum)
        if not SelfBillboardEnabled then return end
        if not selfESPData.HealthLabel then return end
        local health    = mathFloor(hum.Health)
        local maxHealth = mathFloor(hum.MaxHealth)
        local pct       = mathClamp(hum.Health / mathMax(maxHealth, 1), 0, 1)
        if mathAbs(pct - selfLastHealthPct) < 0.005 then return end
        selfLastHealthPct = pct
        selfESPData.HealthLabel.Text = health .. "/" .. maxHealth
        if selfESPData.HealthInner then
            selfESPData.HealthInner.Size = UDim2.new(pct, 0, 1, 0)
            selfESPData.HealthInner.BackgroundColor3 = pct > 0.5 and COLOR_GREEN or pct > 0.25 and COLOR_YELLOW or COLOR_RED
        end
        selfESPData.HealthLabel.TextColor3 = COLOR_WHITE
    end

    -- Infection bar update (polls every 0.5s since Infected value may not fire events)
    local selfLastInfectionPct = -1
    local COLOR_INFECT_LOW    = c3rgb(0, 220, 80)
    local COLOR_INFECT_MID    = c3rgb(200, 100, 255)
    local COLOR_INFECT_HIGH   = c3rgb(255, 30, 30)
    local COLOR_INFECT_TXT_LO = c3rgb(200, 255, 200)
    local COLOR_INFECT_TXT_HI = c3rgb(255, 200, 255)

    local function UpdateSelfInfection()
        if not SelfInfectionBarESPEnabled then return end
        if not selfESPData.InfectionInner or not selfESPData.InfectionLabel then return end

        -- Infected lives under Workspace.Players.<name>.UserStates (verified live:
        -- NumberValue). Fall back through the other two known locations.
        -- (Single-threaded between check and read, so the guarded lookups cannot
        -- throw the way the old pcall wrapper assumed.)
        local rawVal = nil
        local wsPlayers = Workspace:FindFirstChild("Players")
        local wsP = wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name)
        local wsStates = wsP and wsP:FindFirstChild("UserStates")
        local inf = wsStates and wsStates:FindFirstChild("Infected")
        if inf then rawVal = inf.Value end
        if rawVal == nil and LocalPlayer:FindFirstChild("UserStates") then
            inf = LocalPlayer.UserStates:FindFirstChild("Infected")
            if inf then rawVal = inf.Value end
        end
        if rawVal == nil and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("UserStates") then
            inf = LocalPlayer.Character.UserStates:FindFirstChild("Infected")
            if inf then rawVal = inf.Value end
        end

        local numeric = tonumber(rawVal) or (rawVal == true and 100 or 0)
        numeric = mathClamp(numeric, 0, 100)
        local pct = numeric / 100

        if mathAbs(pct - selfLastInfectionPct) < 0.005 then return end
        selfLastInfectionPct = pct

        selfESPData.InfectionInner.Size = UDim2.new(pct, 0, 1, 0)
        if pct <= 0.5 then
            selfESPData.InfectionInner.BackgroundColor3 = COLOR_INFECT_LOW:Lerp(COLOR_INFECT_MID, pct * 2)
        else
            selfESPData.InfectionInner.BackgroundColor3 = COLOR_INFECT_MID:Lerp(COLOR_INFECT_HIGH, (pct - 0.5) * 2)
        end
        selfESPData.InfectionLabel.Text = "" .. mathFloor(numeric) .. "%"
        selfESPData.InfectionLabel.TextColor3 = pct < 0.5 and COLOR_INFECT_TXT_LO or COLOR_INFECT_TXT_HI
    end

    local selfInfectionEspLoopRunning = false
    local selfInfectionEspLoopThread = nil
    local function stopSelfInfectionEspLoop()
        selfInfectionEspLoopRunning = false
        if selfInfectionEspLoopThread then
            pcall(function() task.cancel(selfInfectionEspLoopThread) end)
            selfInfectionEspLoopThread = nil
        end
    end
    _G.ArreyStopSelfInfectionEspLoop = stopSelfInfectionEspLoop

    local function startSelfInfectionEspLoop()
        if selfInfectionEspLoopThread then return end
        selfInfectionEspLoopRunning = true
        selfInfectionEspLoopThread = task.spawn(function()
            while selfInfectionEspLoopRunning and SelfInfectionBarESPEnabled do
                pcall(UpdateSelfInfection)
                task.wait(0.5)
            end
            selfInfectionEspLoopThread = nil
        end)
    end

    local function BindSelfHealthEvents()
        if selfHealthConn then selfHealthConn:Disconnect(); selfHealthConn = nil end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            UpdateSelfHealth(hum) -- immediate refresh
            selfHealthConn = hum.HealthChanged:Connect(function()
                UpdateSelfHealth(hum)
            end)
        end
    end

    -- Bind now for the current character, and re-bind on respawn
    BindSelfHealthEvents()
    _G.ArreyConns = _G.ArreyConns or {}
    if _G.ArreyConns.selfHealthRespawn then pcall(function() _G.ArreyConns.selfHealthRespawn:Disconnect() end) end
    _G.ArreyConns.selfHealthRespawn = LocalPlayer.CharacterAdded:Connect(function(char)
        selfLastHealthPct = -1
        -- wait for Humanoid to exist before binding
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then BindSelfHealthEvents() end
    end)

    Tabs.PlayerESP:AddToggle('SelfHighlight', {
        Text = "Self Highlight ESP",
        Default = false,
        Tooltip = "Show cyan highlight on yourself",
        Callback = function(state)
            SelfESPEnabled = state
            if state then
                CreateSelfESP()
                Library:Notify({
                    Title = "Self ESP",
                    Description = "Self Highlight enabled",
                    Time = 2,
                    Icon = "user"
                })
            else
                if selfESPData.Highlight then
                    pcall(function() selfESPData.Highlight:Destroy() end)
                    selfESPData.Highlight = nil
                end
            end
        end
    })

    Tabs.PlayerESP:AddToggle('SelfBillboard', {
        Text = "Self Billboard ESP",
        Default = false,
        Tooltip = "Show billboard with your name and health",
        Callback = function(state)
            SelfBillboardEnabled = state
            if state then
                CreateSelfESP()
                Library:Notify({
                    Title = "Self ESP",
                    Description = "Self Billboard enabled",
                    Time = 2,
                    Icon = "user"
                })
            else
                if selfESPData.Billboard then
                    pcall(function() selfESPData.Billboard:Destroy() end)
                    selfESPData.Billboard = nil
                    selfESPData.HealthLabel = nil
                end
            end
        end
    })

    Tabs.PlayerESP:AddToggle('NoBillboardBg', {
        Text = "No Billboard Background",
        Default = false,
        Tooltip = "Removes the dark background from your self billboard",
        Callback = function(state)
            SelfNoBillboardBg = state
            if selfESPData.ESPFrame then
                selfESPData.ESPFrame.BackgroundTransparency = state and 1 or 0.6
            end
        end
    })

    local selfESPCharConnection = nil
    local function setupSelfESPCharConnection()
        if selfESPCharConnection then
            pcall(function() selfESPCharConnection:Disconnect() end)
        end
        selfESPCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1) -- Wait for character to fully load
            selfLastInfectionPct = -1
            if SelfESPEnabled or SelfBillboardEnabled or SelfHealthBarESPEnabled or SelfInfectionBarESPEnabled then
                CreateSelfESP()
            end
        end)
    end
    setupSelfESPCharConnection()

    -- Helper: recalculate billboard height and reposition infection row
    local function RefreshBillboardLayout()
        if not selfESPData.Billboard then return end
        local bbHeight = 58
        if SelfHealthBarESPEnabled  then bbHeight = bbHeight + 20 end
        if SelfInfectionBarESPEnabled then bbHeight = bbHeight + 20 end
        selfESPData.Billboard.Size = UDim2.new(0, 160, 0, bbHeight)
        -- Reposition infection bar based on whether health bar is above it
        if selfESPData.InfectionOuter then
            local infRowY = 40 + (SelfHealthBarESPEnabled and 18 or 0)
            selfESPData.InfectionOuter.Position = UDim2.new(0, 8, 0, infRowY)
        end
    end

    Tabs.PlayerESP:AddToggle('HealthBar', {
        Text = "Health Bar ESP",
        Default = false,
        Tooltip = "Show your HP bar inside the self billboard",
        Callback = function(state)
            SelfHealthBarESPEnabled = state
            selfLastHealthPct = -1
            if selfESPData.HealthOuter then
                -- Billboard exists: just toggle visibility + resize
                selfESPData.HealthOuter.Visible = state
                RefreshBillboardLayout()
                if state then
                    -- Force an immediate health update
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then UpdateSelfHealth(hum) end
                end
            elseif SelfBillboardEnabled then
                -- Billboard not built yet  create it
                CreateSelfESP()
            end
        end
    })

    Tabs.PlayerESP:AddToggle('InfectionBar', {
        Text = "Infection Bar ESP",
        Default = false,
        Tooltip = "Show your infection level inside the self billboard",
        Callback = function(state)
            SelfInfectionBarESPEnabled = state
            selfLastInfectionPct = -1
            if state then
                startSelfInfectionEspLoop()
            else
                stopSelfInfectionEspLoop()
            end
            if selfESPData.InfectionOuter then
                -- Billboard exists: just toggle visibility + resize
                selfESPData.InfectionOuter.Visible = state
                RefreshBillboardLayout()
                if state then pcall(UpdateSelfInfection) end
            elseif SelfBillboardEnabled then
                CreateSelfESP()
            end
        end
    })

    -- ===== SETTINGS =====
    -- Player ESP settings moved into Player ESP tabbox

    Tabs.PlayerESP:AddToggle('NotifyGrabbedPinned', {
        Text = "Notify Grabbed and Pinned Players",
        Default = false,
        Tooltip = "Notifies when a player is grabbed or pinned, and shows in chams and billboard.",
        Callback = function(state)
            NotifyGrabbedPinnedEnabled = state
            Library:Notify({
                Title = "Grabbed/Pinned Monitor",
                Description = "Grabbed/Pinned monitor " .. (state and "ON" or "OFF"),
                Time = 2,
                Icon = state and "eye" or "eye-off",
            })
        end
    })

    Tabs.PlayerESP:AddToggle('ShowHealthBar', {
        Text = "Show Health Bar",
        Default = false,
        Tooltip = "Shows Health Bar On BillBoard",
        Callback = function(state)
            ShowHealthBarEnabled = state
            Library:Notify({
                Title = "Health Bar",
                Description = state and "Health bar ON" or "Health bar OFF",
                Time = 2,
                Icon = state and "heart" or "heart-off",
            })
            -- update existing billboards immediately
            for _, data in PlayerESPData do
                if data and data.HealthOuter then
                    data.HealthOuter.Visible = state and data.Billboard and data.Billboard.Enabled and (not data.StatusLabel or not data.StatusLabel.Visible)
                end
            end
        end
    })

    Tabs.PlayerESP:AddToggle('ShowInfectionBar', {
        Text = "Show Infection Bar",
        Default = false,
        Tooltip = "Shows Infection Bar In BillBoard",
        Callback = function(state)
            ShowInfectionBarEnabled = state
            Library:Notify({
                Title = "Infection Bar",
                Description = state and "Infection bar ON" or "Infection bar OFF",
                Time = 2,
                Icon = state and "thermometer" or "thermometer-off",
            })
            for _, data in PlayerESPData do
                if data and data.InfectOuter then
                    data.InfectOuter.Visible = state and data.Billboard and data.Billboard.Enabled and (not data.StatusLabel or not data.StatusLabel.Visible)
                end
            end
        end
    })

    Tabs.PlayerESP:AddToggle('NotifyLowHealth', {
        Text = "Notify Low Health Players",
        Default = false,
        Tooltip = "Notify when players reach Low / Dying health",
        Callback = function(state)
            NotifyLowHealthEnabled = state
            Library:Notify({
                Title = "Low Health Notify",
                Description = state and "Low health notifications ON" or "Low health notifications OFF",
                Time = 2,
                Icon = state and "bell" or "bell-off",
            })
        end
    })

    -- Team ESP Toggle
    local TeamESPEnabled = false
    local TeamESPColors = {} -- [teamName] = Color3

    -- Generate consistent colors for teams
    local function getTeamColor(player)
        if not player or not player.Team then return nil end
        local team = player.Team
        -- Use the team's actual TeamColor (BrickColor) if available
        local ok, color = pcall(function() return team.TeamColor.Color end)
        if ok and color then return color end
        -- Fallback: hash team name to a color
        local name = team.Name
        if not TeamESPColors[name] then
            local hash = 0
            for i = 1, #name do hash = hash + string.byte(name, i) * (i * 7) end
            local hue = (hash % 360) / 360
            TeamESPColors[name] = Color3.fromHSV(hue, 0.8, 1)
        end
        return TeamESPColors[name]
    end

    -- Make getTeamColor accessible to UpdateESPLoop
    _G._PlayerESP_TeamESPEnabled = false
    _G._PlayerESP_getTeamColor = getTeamColor

    Tabs.PlayerESP:AddToggle('TeamESP', {
        Text = "Team ESP",
        Default = false,
        Tooltip = "Color players by their team. Overrides health-based chams color.",
        Callback = function(state)
            TeamESPEnabled = state
            _G._PlayerESP_TeamESPEnabled = state
            Library:Notify({
                Title = "Team ESP",
                Description = state and "Team colors ON" or "Team colors OFF",
                Time = 2,
                Icon = state and "users" or "users",
            })
            -- Update existing highlights immediately
            if ChamsESPEnabled then
                for player, data in PlayerESPData do
                    if data.Highlight and player ~= LocalPlayer then
                        if state then
                            local tc = getTeamColor(player)
                            if tc then
                                data.Highlight.FillColor = tc
                                data.Highlight.OutlineColor = tc
                            end
                        end
                    end
                end
            end
        end
    })

    -- Performance Mode Toggle
    Tabs.PlayerESP:AddToggle('NoBillboardBgPlayers', {
        Text = "No billboard Background",
        Default = true,
        Tooltip = "Removes billboard background",
        Callback = function(state)
            PerformanceModeEnabled = state
            -- Update existing billboards immediately (only touch backgrounds, not bars)
            for _, data in PlayerESPData do
                if data.ESPFrame then
                    data.ESPFrame.BackgroundTransparency = state and 1 or 0.6
                end
                if data.StatusBg then
                    data.StatusBg.BackgroundTransparency = state and 0.7 or 0.45
                end
            end
            Library:Notify({
                Title = "Billboard",
                Description = state and "Billboard Background hidden" or "Billboard Background shown.",
                Time = 2,
                Icon = state and "zap" or "zap-off",
            })
        end
    })

    -- Billboard Distance Slider
    Tabs.PlayerESP:AddSlider('BillboardDist', {
        Text = "Billboard Showing Distance",
        Default = 5,
        Min = 5,
        Max = 50,
        Rounding = 1,
        Tooltip = "Hide billboard when closer than this distance",
        Callback = function(value)
            -- Clamp value to avoid edge cases
            BillboardShowDistance = mathClamp(value, 0, 100)
        end
    })

    -- Player Chams Transparency Slider
    Tabs.PlayerESP:AddSlider('PlayerChamsTransparency', {
        Text = "Chams Transparency",
        Default = 0.45,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Tooltip = "Controls the transparency of player chams/highlights",
        Callback = function(value)
            local transparency = mathClamp(value, 0, 1)
            ChamsFillTransparency = transparency  -- <-- update global

            -- Update existing player highlights
            for _, data in PlayerESPData do
                if data.Highlight then
                    data.Highlight.FillTransparency = transparency
                end
            end
        end
    })
end -- end of Players Tab

do -- // Headless Horseman (Events tab — right groupbox)
    local Camera = Workspace.CurrentCamera

    -- Headless features live in Tabs.EventsHeadless now.

    -- State
    HeadlessESPEnabled = _G.HeadlessESPEnabled or false
    HeadlessSilentAimEnabled = _G.HeadlessSilentAimEnabled or false

    -- Use weak keys so destroyed models get garbage collected
    local highlightInstances = setmetatable({}, { __mode = "k" }) -- model -> Highlight
    -- separate ESP heartbeat connection so it isn't accidentally disconnected
    local espHeartbeatConn = nil

    local function safeDestroy(obj)
        pcall(function() if obj then obj:Destroy() end end)
    end

    local _headlessFallbackFailCount = 0
    local _headlessFallbackNextRetry = 0

    local function findHeadlessBossModel()
        local rootNames = {"Sleepy Hollow", "SleepyHollow", "Sleepy_Hollow"}
        for _, rn in rootNames do
            local root = Workspace:FindFirstChild(rn)
            if root then
                local modes = root:FindFirstChild("Modes") or root:FindFirstChild("modes")
                if modes then
                    local bossFolder = modes:FindFirstChild("Boss") or modes:FindFirstChild("boss")
                    if bossFolder then
                        local hh = bossFolder:FindFirstChild("HeadlessHorsemanBoss") or bossFolder:FindFirstChild("HeadlessHorseman")
                        if hh then _headlessFallbackFailCount = 0; return hh end
                    end
                    local hh2 = modes:FindFirstChild("HeadlessHorsemanBoss") or modes:FindFirstChild("HeadlessHorseman")
                    if hh2 then _headlessFallbackFailCount = 0; return hh2 end
                end
                local hh3 = root:FindFirstChild("HeadlessHorsemanBoss") or root:FindFirstChild("HeadlessHorseman")
                if hh3 then _headlessFallbackFailCount = 0; return hh3 end
            end
        end

        local top = Workspace:FindFirstChild("HeadlessHorsemanBoss") or Workspace:FindFirstChild("HeadlessHorseman")
        if top then _headlessFallbackFailCount = 0; return top end

        local now = time()
        if _headlessFallbackFailCount >= 3 then
            if now < _headlessFallbackNextRetry then
                return nil -- on cooldown, skip the expensive scan
            end
            -- cooldown expired, try once more
            _headlessFallbackFailCount = 0
        end

        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        local searchRoot = zombiesFolder or Workspace
        for _, desc in searchRoot:GetDescendants() do
            if desc:IsA("Model") and desc:FindFirstChild("ZOMBIE_HITBOX") then
                _headlessFallbackFailCount = 0
                return desc
            end
        end

        -- Not found  increment failure counter and set cooldown
        _headlessFallbackFailCount = _headlessFallbackFailCount + 1
        if _headlessFallbackFailCount >= 3 then
            _headlessFallbackNextRetry = now + 30 -- wait 30s before trying again
        end
        return nil
    end

    -- Heartbeat: manage ESP highlights (keeps reference to camera updated)
    local headlessLastCheck = 0
    local headlessCachedModel = nil
    local HEADLESS_CHECK_INTERVAL = 0.5 -- Only search for boss every 0.5 seconds instead of every frame
    local headlessEspCleanupFrame = 0
    local ESP_CLEANUP_INTERVAL = 30 -- Only clean highlight table every ~0.5s (30 heartbeat frames)

    local function clearHeadlessESP()
        if tableHasEntries(highlightInstances) then
            for model, h in highlightInstances do
                safeDestroy(h)
                highlightInstances[model] = nil
            end
        end
        headlessCachedModel = nil
    end

    local function stopHeadlessESPHeartbeat()
        if espHeartbeatConn then
            pcall(function() espHeartbeatConn:Disconnect() end)
            espHeartbeatConn = nil
        end
        headlessEspCleanupFrame = 0
        clearHeadlessESP()
    end

    local function startHeadlessESPHeartbeat()
        if espHeartbeatConn then return end
        headlessEspCleanupFrame = 0
        espHeartbeatConn = RunService.Heartbeat:Connect(function()
            Camera = Workspace.CurrentCamera or Camera

            headlessEspCleanupFrame = headlessEspCleanupFrame + 1
            if headlessEspCleanupFrame >= ESP_CLEANUP_INTERVAL then
                headlessEspCleanupFrame = 0
                for model, h in highlightInstances do
                    if not model or not model.Parent or (h and not h.Parent) then
                        safeDestroy(h)
                        highlightInstances[model] = nil
                    end
                end
            end

            local now = time()
            if now - headlessLastCheck > HEADLESS_CHECK_INTERVAL or not headlessCachedModel or not headlessCachedModel.Parent then
                headlessLastCheck = now
                headlessCachedModel = findHeadlessBossModel()
            end

            local hhModel = headlessCachedModel
            if not hhModel then
                clearHeadlessESP()
                return
            end

            if not highlightInstances[hhModel] then
                local h = Instance.new("Highlight")
                h.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("HL_" .. math.random(10000, 99999))
                h.FillColor = c3rgb(255, 100, 100)
                h.OutlineColor = c3rgb(255, 255, 255)
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = hhModel
                highlightInstances[hhModel] = h
            end
        end)
    end

    local function refreshHeadlessESPHeartbeat()
        if HeadlessESPEnabled then
            startHeadlessESPHeartbeat()
        else
            stopHeadlessESPHeartbeat()
        end
    end

    task.defer(function()
        task.wait(1.5) -- Stagger start
        refreshHeadlessESPHeartbeat()
    end)

    -- safe helper to locate hitbox part (ZOMBIE_HITBOX)
    local _aimCachedModel = nil
    local _aimCachedHitbox = nil
    local function getHeadlessHitbox()
        local model = findHeadlessBossModel()
        if not model then
            _aimCachedModel = nil
            _aimCachedHitbox = nil
            return nil
        end

        if model == _aimCachedModel and _aimCachedHitbox and _aimCachedHitbox.Parent then
            return _aimCachedHitbox
        end

        local hh = model:FindFirstChild("HeadlessHorseman") or model
        local found = nil
        if hh and hh:FindFirstChild("ZOMBIE_HITBOX") then
            found = hh:FindFirstChild("ZOMBIE_HITBOX")
        elseif model:FindFirstChild("ZOMBIE_HITBOX") then
            found = model:FindFirstChild("ZOMBIE_HITBOX")
        else
            -- fallback: search children
            for _, child in model:GetDescendants() do
                if child:IsA("BasePart") and child.Name == "ZOMBIE_HITBOX" then
                    found = child
                    break
                end
            end
        end

        _aimCachedModel = model
        _aimCachedHitbox = found
        return found
    end

    -- Headless targeting for Silent Aim (guns): the boss resolves through
    -- findHeadlessBossModel/getHeadlessHitbox above; selection happens in the
    -- Silent Aim loop via HeadlessSilentAimEnabled below.
    _G.ArreyFindHeadlessBoss = findHeadlessBossModel
    _G.ArreyGetHeadlessHitbox = getHeadlessHitbox

    -- Aimlock removed: Headless now uses the main Silent Aim (guns) instead.
    -- See the Headless Silent Aim toggle in the Events tab UI below.

    -- Obsidian UI (Events tab — Headless Horseman groupbox, right side)
    local HeadlessBox = Tabs.EventsHeadless
    local HeadlessSilentAimToggle = HeadlessBox:AddToggle('HeadlessSilentAim', {
        Text = "Headless Silent Aim",
        Default = HeadlessSilentAimEnabled,
        Tooltip = "silent aim for headless horseman.",
        Callback = function(state)
            HeadlessSilentAimEnabled = state
            _G.HeadlessSilentAimEnabled = state
            pcall(function()
                if type(_G.ArreySetupSilentAimHooks) == "function" then
                    _G.ArreySetupSilentAimHooks()
                end
                if type(_G.ArreyRefreshSilentAimLoop) == "function" then
                    _G.ArreyRefreshSilentAimLoop()
                end
            end)
            Library:Notify({
                Title = "Headless Silent Aim",
                Description = state and "Enabled (+0.2 prediction)" or "Disabled",
                Time = 2,
                Icon = state and "crosshair" or "x",
            })
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.HeadlessSilentAim = HeadlessSilentAimToggle

    HeadlessBox:AddToggle('HeadlessESP', {
        Text = "Headless Horseman ESP",
        Default = HeadlessESPEnabled,
        Tooltip = "Highlight the Headless Horseman boss",
        Callback = function(state)
            HeadlessESPEnabled = state
            refreshHeadlessESPHeartbeat()
            Library:Notify({
                Title = "Headless ESP",
                Description = state and "Headless Horseman ESP Enabled" or "Headless Horseman ESP Disabled",
                Time = 2,
                Icon = state and "eye" or "eye-off",
            })
        end
    })

    -- Cleanup entrypoint (ESP only; silent aim state is owned by the gun tab)
    local function cleanup()
        if espHeartbeatConn then
            pcall(function() espHeartbeatConn:Disconnect() end)
            espHeartbeatConn = nil
        end

        for model, h in highlightInstances do
            safeDestroy(h)
            highlightInstances[model] = nil
        end
    end

    _G.ArreyHeadlessAimlockCleanup = cleanup
end -- end of Headless Horseman (Events tab)

-- ===== MISC TAB =====

do -- // Misc Tab
        local MiscTab = Tabs.Misc

    local ServerModifiersSection = MiscTab:AddGroupbox({ Side = "Left", Name = "Server Modifiers", Description = "Server tools", IconName = "shield" })

        -- === Voivode Purchase ===
        ServerModifiersSection:AddButton('Misc_2', {
            Text = "Get Voivode",
            Tooltip = "Purchase the Voivode item from the server",
            Func = function()
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local customize = events and events:FindFirstChild("Customize")
                    local purchaseEvent = customize and customize:FindFirstChild("PurchaseEvent")
                    if purchaseEvent then purchaseEvent:FireServer("Voivode") end
                end)
                Library:Notify({
                    Title = "Server Modifiers",
                    Description = "Voivode purchase requested!",
                    Time = 2,
                    Icon = "crown"
                })
            end
        })

        -- === Iron Stake Purchase ===
        ServerModifiersSection:AddButton('Misc_3', {
            Text = "Get Iron Stake",
            Tooltip = "Purchase the Iron Stake item from the server",
            Func = function()
                pcall(function()
                    local events = ReplicatedStorage:FindFirstChild("Events")
                    local customize = events and events:FindFirstChild("Customize")
                    local purchaseEvent = customize and customize:FindFirstChild("PurchaseEvent")
                    if purchaseEvent then purchaseEvent:FireServer("Iron Stake") end
                end)
                Library:Notify({
                    Title = "Server Modifiers",
                    Description = "Iron Stake purchase requested!",
                    Time = 2,
                    Icon = "swords"
                })
            end
        })

        -- === WALK NOCLIP (Independent from Fly) ===
        local WalkNoclipEnabled = false
        _G.ArreyWalkNoclipEnabled = false
        local walkNoclipConn = nil
        local walkNoclipCollisionConn = nil
        local walkNoclipTeleportConn = nil

        -- Walk noclip state (using Fly Noclip bypass mechanics)
        local walkLastPosition = nil
        local walkServerPosition = nil
        local walkIsLoopTeleporting = false
        local walkTeleportEndTime = 0
        local walkHeadAnchored = false
        local walkIsInsideWall = false
        local walkWallEntryTime = 0
        local walkClearFrameCount = 0
        local WALK_WALL_COOLDOWN = 1 -- 1 second cooldown
        local WALK_CLEAR_FRAMES_NEEDED = 5 -- Need 5 frames clearly outside
        local walkNoclipSpeed = 16 -- Speed for movement inside walls

        -- Walk noclip raycast params (separate from fly noclip)
        local walkNoclipRayParams = nil
        local _walkNoclipRayParamsLastRebuild = 0
        local _walkNoclipRayParamsPlayerCount = 0

        local function setupWalkNoclipRayParams()
            local now = time()
            local playerCount = #Players:GetPlayers()
            -- Only rebuild if params don't exist, or enough time has passed, or player count changed
            if walkNoclipRayParams and (now - _walkNoclipRayParamsLastRebuild < 3) and (playerCount == _walkNoclipRayParamsPlayerCount) then
                return
            end
            _walkNoclipRayParamsLastRebuild = now
            _walkNoclipRayParamsPlayerCount = playerCount

            walkNoclipRayParams = RaycastParams.new()
            walkNoclipRayParams.FilterType = Enum.RaycastFilterType.Exclude

            local filterList = {}
            local char = LocalPlayer.Character
            if char then table.insert(filterList, char) end

            for _, plr in Players:GetPlayers() do
                if plr.Character and plr.Character ~= char then
                    table.insert(filterList, plr.Character)
                end
            end

            local zombiesFolder = workspace:FindFirstChild("Zombies")
            if zombiesFolder then table.insert(filterList, zombiesFolder) end

            local cameraFolder = workspace:FindFirstChild("Camera")
            if cameraFolder then table.insert(filterList, cameraFolder) end

            walkNoclipRayParams.FilterDescendantsInstances = filterList
        end

        local function isWalkInWall(pos)
            -- Rebuild params only when needed (throttled), not every frame
            setupWalkNoclipRayParams()

            -- Use shared pre-built constant directions table (not rebuilt each call)
            for _, dir in _G.NOCLIP_DIRECTIONS_18 do
                local result = workspace:Raycast(pos, dir * 2, walkNoclipRayParams)
                if result and result.Instance and result.Instance.CanCollide then
                    return true
                end
            end

            return false
        end

        local function isWalkClearlyOutside(pos)
            -- Reuse already-cached params (setupWalkNoclipRayParams was just called in isWalkInWall)
            if not walkNoclipRayParams then setupWalkNoclipRayParams() end

            -- Use shared pre-built constant directions table
            for _, dir in _G.NOCLIP_DIRECTIONS_18 do
                local result = workspace:Raycast(pos, dir * 4, walkNoclipRayParams)
                if result and result.Instance and result.Instance.CanCollide then
                    return false
                end
            end

            return true
        end

        local function isWalkUnderground(pos)
            if not walkNoclipRayParams then setupWalkNoclipRayParams() end

            local char = LocalPlayer.Character
            walkNoclipRayParams.FilterDescendantsInstances = char and {char} or {}

            local floorCheck = workspace:Raycast(pos, v3new(0, -500, 0), walkNoclipRayParams)

            if floorCheck and floorCheck.Instance then
                if floorCheck.Instance:IsA("Terrain") then
                    return floorCheck.Distance < 0.1 or pos.Y < floorCheck.Position.Y
                end
            end

            local ceilingCheck = workspace:Raycast(pos, v3new(0, 500, 0), walkNoclipRayParams)
            if ceilingCheck and ceilingCheck.Instance and ceilingCheck.Instance:IsA("Terrain") then
                return true
            end

            return false
        end

        -- Loop teleport to position (bypass mechanic from Fly Noclip)
        local function walkNoclipLoopTP(targetPos, duration)
            walkIsLoopTeleporting = true
            walkTeleportEndTime = time() + (duration or 1)

            if walkNoclipTeleportConn then
                walkNoclipTeleportConn:Disconnect()
            end

            walkNoclipTeleportConn = RunService.Heartbeat:Connect(function()
                if not walkIsLoopTeleporting or time() > walkTeleportEndTime then
                    walkIsLoopTeleporting = false
                    if walkNoclipTeleportConn then
                        walkNoclipTeleportConn:Disconnect()
                        walkNoclipTeleportConn = nil
                    end
                    return
                end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local rot = hrp.CFrame - hrp.CFrame.Position
                    hrp.CFrame = cfNew(targetPos) * rot
                end
            end)
        end

        local function stopWalkNoclipLoopTP()
            walkIsLoopTeleporting = false
            if walkNoclipTeleportConn then
                walkNoclipTeleportConn:Disconnect()
                walkNoclipTeleportConn = nil
            end
        end

        -- Enter CFrame mode (when going into wall) - bypass mechanic
        local function enterWalkCFrameMode()
            if walkHeadAnchored then return end

            local char = LocalPlayer.Character
            if not char then return end

            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if not head or not humanoid or not hrp then return end

            -- Store server position before entering wall
            walkServerPosition = hrp.Position
            walkLastPosition = hrp.Position

            -- Enable CFrame fly mode (bypass mechanic)
            humanoid.PlatformStand = true
            head.Anchored = true
            walkHeadAnchored = true

            walkIsInsideWall = true
            walkWallEntryTime = time()
        end

        -- Exit CFrame mode (when leaving wall) - bypass mechanic
        local function exitWalkCFrameMode()
            if not walkHeadAnchored then return end

            local char = LocalPlayer.Character
            if not char then return end

            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            -- Restore character state
            if head then
                head.Anchored = false
            end

            if humanoid then
                humanoid.PlatformStand = false
            end

            walkHeadAnchored = false
            walkIsInsideWall = false

            -- Teleport to current visual position (bypass mechanic)
            if walkLastPosition then
                walkNoclipLoopTP(walkLastPosition, 1)
            end
        end

        -- Walk Noclip uses Fly Noclip bypass mechanics but stays grounded!

        local function startWalkNoclip()
            if walkNoclipConn then return end

            local char = LocalPlayer.Character
            if not char then return end

            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if not head or not humanoid or not hrp then return end

            _G.WalkNoclipBypassEnabled = true
            setupWalkNoclipRayParams()

            -- Initialize positions (bypass mechanic)
            walkServerPosition = hrp.Position
            walkLastPosition = hrp.Position
            walkIsInsideWall = false
            walkHeadAnchored = false

            local _walkWallCheckFrame = 0
            local _walkLastInWall = false
            -- PERF: cache character parts; rebuilt on character change or reparent
            local _walkCacheChar, _walkHum, _walkHead, _walkRoot = nil, nil, nil, nil
            walkNoclipConn = RunService.RenderStepped:Connect(function(deltaTime)
                if not WalkNoclipEnabled then return end

                local character = LocalPlayer.Character
                if not character then return end

                if character ~= _walkCacheChar then
                    _walkCacheChar = character
                    _walkHum = character:FindFirstChildOfClass("Humanoid")
                    _walkHead = character:FindFirstChild("Head")
                    _walkRoot = character:FindFirstChild("HumanoidRootPart")
                end
                local hum, headPart, rootPart = _walkHum, _walkHead, _walkRoot
                if not hum or not headPart or not rootPart then return end
                if hum.Parent ~= character or headPart.Parent ~= character or rootPart.Parent ~= character then
                    _walkCacheChar = nil
                    return
                end

                -- Get current position
                local currentPos = walkHeadAnchored and headPart.Position or rootPart.Position

                -- PERF: Only run expensive wall raycasts every 3 frames
                _walkWallCheckFrame = _walkWallCheckFrame + 1
                local inWall = _walkLastInWall
                if _walkWallCheckFrame >= 3 then
                    _walkWallCheckFrame = 0
                    inWall = isWalkInWall(currentPos)
                    _walkLastInWall = inWall
                end

                if inWall and not walkIsInsideWall then
                    -- Just entered a wall - start CFrame mode (BYPASS)
                    walkClearFrameCount = 0
                    enterWalkCFrameMode()
                elseif walkIsInsideWall then
                    -- We're in CFrame mode - check if cooldown passed before checking wall exit
                    local timeInWall = time() - walkWallEntryTime
                    if timeInWall >= WALK_WALL_COOLDOWN then
                        -- Cooldown passed, check if we CLEARLY left the wall
                        if isWalkClearlyOutside(currentPos) then
                            walkClearFrameCount = walkClearFrameCount + 1
                            if walkClearFrameCount >= WALK_CLEAR_FRAMES_NEEDED then
                                -- Been clearly outside for multiple frames, safe to exit
                                exitWalkCFrameMode()
                                walkClearFrameCount = 0
                            end
                        else
                            -- Still near a wall, reset counter
                            walkClearFrameCount = 0
                        end
                    end
                end

                -- If in CFrame mode (inside wall), handle FULL 3D movement (like Fly Noclip)
                if walkHeadAnchored then
                    -- Keep anchored and platform stand (BYPASS)
                    if not headPart.Anchored then headPart.Anchored = true end
                    if not hum.PlatformStand then hum.PlatformStand = true end

                    -- Get movement from humanoid MoveDirection
                    local step = walkNoclipSpeed * deltaTime
                    local moveDirection = hum.MoveDirection * step

                    -- Vertical movement (E = up, Q = down) - SAME AS FLY NOCLIP
                    local verticalMove = 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                        verticalMove = step
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                        verticalMove = -step
                    end

                    local headCFrame = headPart.CFrame
                    local camera = workspace.CurrentCamera
                    local cameraCFrame = camera.CFrame

                    -- Calculate camera offset
                    local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
                    cameraCFrame = cameraCFrame * cfNew(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)

                    local cameraPosition = cameraCFrame.Position
                    local headPosition = headCFrame.Position

                    -- Convert movement to camera-relative (FULL 3D like Fly Noclip)
                    local objectSpaceVelocity = cfNew(cameraPosition, v3new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
                    objectSpaceVelocity = objectSpaceVelocity + v3new(0, verticalMove, 0)

                    -- Calculate new position (full 3D movement)
                    local newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)

                    -- Prevent underground (safety check)
                    if isWalkUnderground(newPos) then
                        if objectSpaceVelocity.Y < 0 then
                            objectSpaceVelocity = v3new(objectSpaceVelocity.X, 0, objectSpaceVelocity.Z)
                        end
                        newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)

                        if isWalkUnderground(newPos) then
                            newPos = headPosition
                        end
                    end

                    -- Move head via CFrame (bypass mechanic - client-only movement)
                    headPart.CFrame = cfNew(newPos) * (cameraCFrame - cameraPosition)

                    -- Update last position
                    walkLastPosition = headPart.Position
                else
                    -- Not in CFrame mode, just track position
                    walkLastPosition = rootPart.Position
                    walkServerPosition = rootPart.Position
                end

                _G.WalkNoclipLastValidPosition = walkServerPosition
            end)

            local _walkNoclipCollisionChar = nil
            local _walkNoclipCollisionParts = {}
            local function _rebuildWalkNoclipCollisionCache(char)
                _walkNoclipCollisionChar = char
                _walkNoclipCollisionParts = {}
                for _, partName in _G.NOCLIP_PARTS do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        table.insert(_walkNoclipCollisionParts, part)
                    end
                end
                for _, child in char:GetChildren() do
                    if child:IsA("Accessory") or child:IsA("Hat") then
                        local handle = child:FindFirstChild("Handle")
                        if handle then table.insert(_walkNoclipCollisionParts, handle) end
                    end
                end
            end

            walkNoclipCollisionConn = RunService.Stepped:Connect(function()
                if not WalkNoclipEnabled then return end

                local character = LocalPlayer.Character
                if not character then return end

                -- Rebuild cache if character changed
                if character ~= _walkNoclipCollisionChar then
                    _rebuildWalkNoclipCollisionCache(character)
                end

                for _, part in _walkNoclipCollisionParts do
                    if part.Parent and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        end

        local function stopWalkNoclip()
            WalkNoclipEnabled = false
            _G.ArreyWalkNoclipEnabled = false
            _G.WalkNoclipBypassEnabled = false
            _G.WalkNoclipLastValidPosition = nil

            -- Get final position before cleanup (bypass mechanic)
            local finalPos = walkLastPosition
            local wasInCFrameMode = walkHeadAnchored

            -- Clean up connections
            if walkNoclipConn then
                walkNoclipConn:Disconnect()
                walkNoclipConn = nil
            end

            if walkNoclipCollisionConn then
                walkNoclipCollisionConn:Disconnect()
                walkNoclipCollisionConn = nil
            end

            -- Restore character state (bypass mechanic)
            local char = LocalPlayer.Character
            if char then
                local head = char:FindFirstChild("Head")
                local humanoid = char:FindFirstChildOfClass("Humanoid")

                if head and walkHeadAnchored then
                    head.Anchored = false
                end

                if humanoid then
                    humanoid.PlatformStand = false
                end

                -- Restore collision on all parts
                for _, partName in _G.NOCLIP_PARTS do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end

            walkHeadAnchored = false
            walkIsInsideWall = false

            -- If we were in CFrame mode, teleport to final position (bypass mechanic)
            if wasInCFrameMode and finalPos then
                walkNoclipLoopTP(finalPos, 1)
            end

            -- Reset state
            walkLastPosition = nil
            walkServerPosition = nil
        end

        _G.ArreyStopWalkNoclip = stopWalkNoclip

        -- Re-setup on respawn (bypass mechanic)
        _G.ArreyConns = _G.ArreyConns or {}
        if _G.ArreyConns.walkNoclipRespawn then pcall(function() _G.ArreyConns.walkNoclipRespawn:Disconnect() end) end
        _G.ArreyConns.walkNoclipRespawn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            stopWalkNoclipLoopTP()
            walkLastPosition = nil
            walkServerPosition = nil
            walkHeadAnchored = false
            walkIsInsideWall = false

            if WalkNoclipEnabled then
                task.wait(0.3)
                startWalkNoclip()
            end
        end)

        -- Walk Noclip Toggle (same as Fly Noclip but independent)
        local WalkNoclipToggle = ServerModifiersSection:AddToggle('ServerMods_WalkNoclipBypass', {
            Text = "Walk Noclip Bypass",
            Tooltip = "Fly through walls (doesn't require Fly enabled, Kinda unstable)",
            Default = false,
            Callback = function(state)
                WalkNoclipEnabled = state
                _G.ArreyWalkNoclipEnabled = state

                if state then
                    startWalkNoclip()
                    Library:Notify({
                        Title = "Server Modifiers",
                        Description = "Walk Noclip enabled - fly through walls freely!",
                        Time = 3,
                        Icon = "move",
                    })
                else
                    stopWalkNoclip()
                    Library:Notify({
                        Title = "Server Modifiers",
                        Description = "Walk Noclip disabled.",
                        Time = 2,
                        Icon = "move",
                    })
                end
            end
        })
        _G.ArreyToggleElements.WalkNoclipBypass = WalkNoclipToggle

        -- Walk Noclip Speed (controls movement speed in all directions)
        ServerModifiersSection:AddSlider('ServerMods_WalkNoclipSpeed', {
            Text = "Walk Noclip Speed",
            Tooltip = "Speed when flying through walls",
            Rounding = 1,
            Min = 8,
            Max = 35,
            Default = 16,
            Callback = function(v)
                walkNoclipSpeed = tonumber(v) or 16
            end
        })

        -- ===== BYPASS SLOWDOWN =====

        _G.ArreyBypassSlowState = _G.ArreyBypassSlowState or {
            enabled = false,
            conn = nil,
            charConn = nil
        }

        _G.ArreyAttachBypassSlow = function(character)
            local stateRef = _G.ArreyBypassSlowState
            if stateRef.conn then pcall(function() stateRef.conn:Disconnect() end) end
            stateRef.conn = nil
            if not stateRef.enabled then return end
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            stateRef.conn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if not stateRef.enabled then return end
                if hum.WalkSpeed < 16 then
                    pcall(function() hum.WalkSpeed = 16 end)
                end
            end)
        end

        _G.ArreyStartBypassSlow = function()
            local char = LocalPlayer.Character
            if char then _G.ArreyAttachBypassSlow(char) end
            if _G.ArreyBypassSlowState.charConn then pcall(function() _G.ArreyBypassSlowState.charConn:Disconnect() end) end
            _G.ArreyBypassSlowState.charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                _G.ArreyAttachBypassSlow(newChar)
            end)
        end

        _G.ArreyStopBypassSlow = function()
            if _G.ArreyBypassSlowState.conn then
                pcall(function() _G.ArreyBypassSlowState.conn:Disconnect() end)
                _G.ArreyBypassSlowState.conn = nil
            end
            if _G.ArreyBypassSlowState.charConn then
                pcall(function() _G.ArreyBypassSlowState.charConn:Disconnect() end)
                _G.ArreyBypassSlowState.charConn = nil
            end
        end

        ServerModifiersSection:AddToggle('ServerMods_BypassSlow', {
            Text = "Bypass Slowdown",
            Tooltip = "Prevents Lance/Cuirass, etc from slowing you.",
            Default = false,
            Callback = function(state)
                _G.ArreyBypassSlowState.enabled = state
                if state then
                    _G.ArreyStartBypassSlow()
                    Library:Notify({ Title = "Server Modifiers", Description = "Bypass Slowdown ON", Time = 3, Icon = "zap" })
                else
                    _G.ArreyStopBypassSlow()
                    Library:Notify({ Title = "Server Modifiers", Description = "Bypass Slowdown OFF", Time = 2, Icon = "zap" })
                end
            end
        })

    local MovementSection = Tabs.LocalPlayer:AddGroupbox({ Side = "Right", Name = "Movement", Description = "WalkSpeed controls", IconName = "move" })
    local VisualSection = MiscTab:AddGroupbox({ Side = "Right", Name = "Visual", Description = "Visual controls", IconName = "eye" })
    local ServerSection = MiscTab:AddGroupbox({ Side = "Right", Name = "Server Utilities", Description = "Server controls", IconName = "server" })

        -- === Server utilities ===
        ServerSection:AddButton('Misc_4', {
            Text = "Rejoin Server",
            Tooltip = "Leave and rejoin the same game",
            Func = function()
                Library:Notify({ Title = "Server", Description = "Rejoining server...", Time = 3, Icon = "refresh-cw" })
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        })

        ServerSection:AddButton('Misc_5', {
            Text = "Server Hop",
            Tooltip = "Switch to a different server",
            Func = function()
                Library:Notify({ Title = "Server", Description = "Finding new server...", Time = 3, Icon = "server" })
                local servers = {}
                local success, result = pcall(function()
                    return game:HttpGet(strFormat("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
                end)
                if success and result and type(result) == "string" then
                    local ok, data = pcall(function() return HttpService:JSONDecode(result) end)
                    if ok and data and data.data then
                        for _, v in data.data do
                            if v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(servers, v.id) end
                        end
                    end
                end
                if #servers > 0 then
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LocalPlayer) end)
                else
                    Library:Notify({ Title = "Error", Description = "No available servers found.", Time = 5, Icon = "server-crash" })
                end
            end
        })

    -- === Simplified Visuals: Fullbright & NoFog (IMPROVED & OPTIMIZED) ===

    local fullbrightEnabled = false
    local noFogEnabled = false

    -- Save originals for restoration with better error handling
    local originalLighting = {}
    local atmosphereBackup = {} -- Store removed atmospheres for restoration (NoFog)

    local originalsSaved = false
    local function saveOriginalLighting()
        if originalsSaved then return end
        local success, err = pcall(function()
            originalLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Ambient = Lighting.Ambient,
            }
            originalsSaved = true
        end)
        if not success then
            warn("[Visual Fix] Failed to save original lighting:", err)
        end
    end

    saveOriginalLighting()

    -- Stronger fullbright targets (3x brightness, bright ambient, noon).
    -- Brightness + ambient are both adjustable: on high graphics the
    -- Bloom/SunRays combo blows parts out white like the sun, so lower
    -- either slider until it looks right.
    local FB_BRIGHTNESS   = 3
    local FB_CLOCKTIME    = 12
    local FB_AMBIENT_LEVEL = 140 -- grey 0-255 for Ambient; Outdoor = min(level+70, 255)
    local FB_FOGEND       = 100000

    local function fbColors()
        local a = math.clamp(math.floor(tonumber(FB_AMBIENT_LEVEL) or 140), 0, 255)
        local o = math.clamp(a + 70, 0, 255)
        return c3rgb(a, a, a), c3rgb(o, o, o)
    end

    local function fullbrightTargetsMatch()
        local wantAmbient, wantOutdoor = fbColors()
        if Lighting.Brightness ~= FB_BRIGHTNESS then return false end
        if Lighting.ClockTime ~= FB_CLOCKTIME then return false end
        if Lighting.GlobalShadows ~= false then return false end
        if Lighting.OutdoorAmbient ~= wantOutdoor then return false end
        if Lighting.Ambient ~= wantAmbient then return false end
        if not noFogEnabled and Lighting.FogEnd ~= FB_FOGEND then return false end
        return true
    end

    -- IMPROVED: Fullbright now works independently from NoFog
    local function applyFullbright()
        local success, err = pcall(function()
            local wantAmbient, wantOutdoor = fbColors()
            Lighting.Brightness = FB_BRIGHTNESS
            Lighting.ClockTime = FB_CLOCKTIME
            -- Only set FogEnd if NoFog is NOT enabled (independent control)
            if not noFogEnabled then
                Lighting.FogEnd = FB_FOGEND
            end
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = wantOutdoor
            Lighting.Ambient = wantAmbient
        end)
        if not success then
            warn("[Visual Fix] Fullbright apply failed:", err)
            Library:Notify({ Title = "Visual Error", Description = "Fullbright failed to apply", Time = 3, Icon = "alert-triangle" })
        end
    end

    local function restoreFullbright()
        local success, err = pcall(function()
            local wantAmbient, wantOutdoor = fbColors()
            Lighting.Brightness = originalLighting.Brightness or 1
            Lighting.ClockTime = originalLighting.ClockTime or 12
            -- Only restore FogEnd if NoFog is NOT enabled (independent control)
            if not noFogEnabled then
                Lighting.FogEnd = originalLighting.FogEnd or FB_FOGEND
            end
            Lighting.GlobalShadows = originalLighting.GlobalShadows ~= nil and originalLighting.GlobalShadows or true
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or wantOutdoor
            Lighting.Ambient = originalLighting.Ambient or wantAmbient
        end)
        if not success then
            warn("[Visual Fix] Fullbright restore failed:", err)
        end
    end

    -- IMPROVED: NoFog with atmosphere backup and better error handling
    local function applyNoFog()
        local success, err = pcall(function()
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0

            -- Backup and remove atmospheres (non-destructive)
            atmosphereBackup = {}
            for _, v in Lighting:GetDescendants() do
                if v:IsA("Atmosphere") then
                    table.insert(atmosphereBackup, {
                        Instance = v,
                        Parent = v.Parent,
                        Density = v.Density,
                        Offset = v.Offset,
                        Color = v.Color,
                        Decay = v.Decay,
                        Glare = v.Glare,
                        Haze = v.Haze
                    })
                    v.Parent = nil -- Hide instead of destroy
                end
            end
        end)
        if not success then
            warn("[Visual Fix] NoFog apply failed:", err)
            Library:Notify({ Title = "Visual Error", Description = "NoFog failed to apply", Time = 3, Icon = "alert-triangle" })
        end
    end

    local function restoreNoFog()
        local success, err = pcall(function()
            -- Only restore FogEnd if Fullbright is NOT enabled (independent control)
            if not fullbrightEnabled then
                Lighting.FogEnd = originalLighting.FogEnd or 100000
                Lighting.FogStart = originalLighting.FogStart or 0
            end

            -- Restore backed up atmospheres
            for _, backup in atmosphereBackup do
                if backup.Instance and backup.Parent then
                    backup.Instance.Parent = backup.Parent
                end
            end
            atmosphereBackup = {}
        end)
        if not success then
            warn("[Visual Fix] NoFog restore failed:", err)
        end
    end

    -- ===== FULLBRIGHT & NOFOG: Signal-based (no polling loops) =====

    local fullbrightConns   = {} -- active signal connections for fullbright
    local noFogConns        = {} -- active signal connections for nofog

    local function disconnectAll(tbl)
        for _, c in tbl do pcall(function() c:Disconnect() end) end
        table.clear(tbl)
    end

    local function onFullbrightPropertyChanged()
        if not fullbrightEnabled then return end
        if fullbrightTargetsMatch() then return end
        pcall(applyFullbright)
    end

    local function onNoFogPropertyChanged()
        if not noFogEnabled then return end
        if Lighting.FogEnd == 100000 and Lighting.FogStart == 0 then
            local hasFoggedAtmosphere = false
            for _, v in Lighting:GetDescendants() do
                if v:IsA("Atmosphere") and v.Parent then
                    hasFoggedAtmosphere = true
                    break
                end
            end
            if not hasFoggedAtmosphere then return end
        end
        pcall(applyNoFog)
    end

    local function startFullbrightAutoRefresh()
        disconnectAll(fullbrightConns)
        -- Watch every property fullbright cares about
        local props = {"Brightness", "ClockTime", "GlobalShadows", "OutdoorAmbient", "Ambient", "FogEnd"}
        for _, prop in props do
            pcall(function()
                fullbrightConns[#fullbrightConns+1] =
                    Lighting:GetPropertyChangedSignal(prop):Connect(onFullbrightPropertyChanged)
            end)
        end
        -- Watch for new Atmosphere instances (map change can add one)
        pcall(function()
            fullbrightConns[#fullbrightConns+1] = Lighting.DescendantAdded:Connect(function(inst)
                if inst:IsA("Atmosphere") then
                    onFullbrightPropertyChanged()
                end
            end)
        end)
    end

    local function stopFullbrightAutoRefresh()
        disconnectAll(fullbrightConns)
    end

    local function startNoFogMonitor()
        disconnectAll(noFogConns)
        -- Watch fog properties
        for _, prop in {"FogEnd", "FogStart"} do
            pcall(function()
                noFogConns[#noFogConns+1] =
                    Lighting:GetPropertyChangedSignal(prop):Connect(onNoFogPropertyChanged)
            end)
        end
        -- Watch for new Atmosphere instances being added (map change adds one)
        pcall(function()
            noFogConns[#noFogConns+1] = Lighting.DescendantAdded:Connect(function(inst)
                if inst:IsA("Atmosphere") then
                    onNoFogPropertyChanged()
                end
            end)
        end)
    end

    local function stopNoFogMonitor()
        disconnectAll(noFogConns)
    end


    -- UI toggles with improved error handling
    VisualSection:AddToggle('Visual_1', {
        Text = "Fullbright",
        Tooltip = "Enable fullbright lighting",
        Default = false,
        Callback = function(state)
            local success, err = pcall(function()
                fullbrightEnabled = state
                if state then
                    applyFullbright()
                    startFullbrightAutoRefresh()
                    Library:Notify({ Title = "Visual", Description = "Fullbright enabled.", Time = 2, Icon = "sun" })
                else
                    stopFullbrightAutoRefresh()
                    restoreFullbright()
                    Library:Notify({ Title = "Visual", Description = "Fullbright disabled.", Time = 2, Icon = "moon" })
                end
            end)

            if not success then
                warn("[Visual Fix] Fullbright toggle error:", err)
                Library:Notify({
                    Title = "Visual Error",
                    Description = "Fullbright toggle failed: " .. tostring(err),
                    Time = 4,
                    Icon = "alert-triangle"
                })
            end
        end
    })

    VisualSection:AddSlider('Visual_FullbrightBrightness', {
        Text = "Fullbright Brightness",
        Tooltip = "Adjust fullbright brightness",
        Rounding = 1,
        Min = 0,
        Max = 5,
        Default = 3,
        Callback = function(value)
            FB_BRIGHTNESS = tonumber(value) or 3
            if fullbrightEnabled then
                pcall(applyFullbright)
            end
        end
    })

    VisualSection:AddSlider('Visual_FullbrightAmbient', {
        Text = "Fullbright Ambient",
        Tooltip = "Adjust fullbright ambient",
        Rounding = 0,
        Min = 0,
        Max = 255,
        Default = 140,
        Callback = function(value)
            FB_AMBIENT_LEVEL = math.clamp(math.floor(tonumber(value) or 140), 0, 255)
            if fullbrightEnabled then
                pcall(applyFullbright)
            end
        end
    })

    VisualSection:AddToggle('Visual_2', {
        Text = "No Fog",
        Tooltip = "Remove fog and atmospheres",
        Default = false,
        Callback = function(state)
            local success, err = pcall(function()
                noFogEnabled = state
                if state then
                    applyNoFog()
                    startNoFogMonitor() -- Start monitoring for map changes
                    Library:Notify({ Title = "Visual", Description = "NoFog enabled with auto-reapply.", Time = 2, Icon = "cloud-off" })
                else
                    stopNoFogMonitor() -- Stop monitoring
                    restoreNoFog()
                    Library:Notify({ Title = "Visual", Description = "NoFog disabled.", Time = 2, Icon = "cloud" })
                end
            end)

            if not success then
                warn("[Visual Fix] NoFog toggle error:", err)
                Library:Notify({
                    Title = "Visual Error",
                    Description = "NoFog toggle failed: " .. tostring(err),
                    Time = 4,
                    Icon = "alert-triangle"
                })
            end
        end
    })

    -- === FOV Changer ===
    local originalFieldOfView = nil
    local fovChangerEnabled = false
    local currentFOV = 70
    local fovLockConnection = nil
    local fovCameraConnection = nil
    local fovPropertyConnection = nil

    pcall(function()
        originalFieldOfView = workspace.CurrentCamera.FieldOfView
    end)

    -- Force FOV on the current camera
    local function forceFOV()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.FieldOfView = currentFOV
            end
        end)
    end

    -- Hook into camera's FieldOfView property changes
    local function hookCameraFOV()
        if fovPropertyConnection then
            pcall(function() fovPropertyConnection:Disconnect() end)
        end
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                fovPropertyConnection = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                    if fovChangerEnabled and cam.FieldOfView ~= currentFOV then
                        cam.FieldOfView = currentFOV
                    end
                end)
            end
        end)
    end

    -- Force FOV every frame to prevent game from overriding it
    local fovPollToken = 0
    local function startFOVLock()
        fovPollToken = fovPollToken + 1
        if fovLockConnection then fovLockConnection:Disconnect() end
        if fovCameraConnection then fovCameraConnection:Disconnect() end

        -- Hook current camera
        hookCameraFOV()

        -- Listen for camera changes (game might swap cameras)
        fovCameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if fovChangerEnabled then
                task.defer(function()
                    forceFOV()
                    hookCameraFOV()
                end)
            end
        end)

        -- Also force via polling as backup (avoids RenderStepped)
        local _myToken = fovPollToken
        task.spawn(function()
            while fovChangerEnabled and _myToken == fovPollToken do
                forceFOV()
                task.wait(0.17)
            end
        end)
    end

    local function stopFOVLock()
        if fovLockConnection then
            fovLockConnection:Disconnect()
            fovLockConnection = nil
        end
        if fovCameraConnection then
            fovCameraConnection:Disconnect()
            fovCameraConnection = nil
        end
        if fovPropertyConnection then
            pcall(function() fovPropertyConnection:Disconnect() end)
            fovPropertyConnection = nil
        end
    end

    local function applyFOV(fov)
        pcall(function()
            workspace.CurrentCamera.FieldOfView = fov
        end)
    end

    local function restoreFOV()
        pcall(function()
            workspace.CurrentCamera.FieldOfView = originalFieldOfView or 70
        end)
    end

    local fovChangerCharConnection = nil
    local function setupFOVChangerCharConnection()
        if fovChangerCharConnection then
            pcall(function() fovChangerCharConnection:Disconnect() end)
        end
        fovChangerCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            if fovChangerEnabled then
                task.delay(0.1, function()
                    forceFOV()
                    hookCameraFOV()
                end)
                task.delay(0.5, function()
                    forceFOV()
                end)
                task.delay(1, function()
                    forceFOV()
                end)
            end
        end)
    end
    setupFOVChangerCharConnection()

    VisualSection:AddToggle('Visual_FOVChanger', {
        Text = "FOV Changer",
        Tooltip = "Change your camera field of view",
        Default = false,
        Callback = function(state)
            fovChangerEnabled = state
            if state then
                applyFOV(currentFOV)
                startFOVLock() -- Lock FOV so nothing can change it
                Library:Notify({ Title = "Visual", Description = "FOV Changer enabled (" .. currentFOV .. ") - Locked", Time = 2, Icon = "eye" })
            else
                stopFOVLock()
                restoreFOV()
                Library:Notify({ Title = "Visual", Description = "FOV Changer disabled.", Time = 2, Icon = "eye-off" })
            end
        end
    })

    VisualSection:AddSlider('Visual_FOVValue', {
        Text = "FOV Value",
        Tooltip = "Adjust field of view (default: 70)",
        Rounding = 1,
        Min = 30,
        Max = 120,
        Default = 70,
        Callback = function(value)
            currentFOV = tonumber(value) or 70
            if fovChangerEnabled then
                applyFOV(currentFOV)
            end
        end
    })

    -- === Infinite Zoom ===
    local infiniteZoomEnabled = false
    local originalMinZoomDistance = nil
    local originalMaxZoomDistance = nil
    local zoomConnection = nil

    local function applyInfiniteZoom()
        pcall(function()
            local player = Players.LocalPlayer
            if not player then return end

            -- Store original values
            if originalMinZoomDistance == nil then
                originalMinZoomDistance = player.CameraMinZoomDistance
            end
            if originalMaxZoomDistance == nil then
                originalMaxZoomDistance = player.CameraMaxZoomDistance
            end

            -- Set infinite zoom
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 9999
        end)
    end

    local function restoreZoom()
        pcall(function()
            local player = Players.LocalPlayer
            if not player then return end

            player.CameraMinZoomDistance = originalMinZoomDistance or 0.5
            player.CameraMaxZoomDistance = originalMaxZoomDistance or 128
        end)
    end

    VisualSection:AddToggle('Visual_InfiniteZoom', {
        Text = "Infinite Zoom",
        Tooltip = "Remove zoom distance limits",
        Default = false,
        Callback = function(state)
            infiniteZoomEnabled = state
            if state then
                applyInfiniteZoom()
                -- Keep applying in case game resets it
                if zoomConnection then zoomConnection:Disconnect() end
                local _zoomFrameCounter = 0
                zoomConnection = RunService.Heartbeat:Connect(function()
                    if not infiniteZoomEnabled then return end
                    _zoomFrameCounter = _zoomFrameCounter + 1
                    if _zoomFrameCounter < 30 then return end -- check every ~0.5s not every frame
                    _zoomFrameCounter = 0
                    pcall(function()
                        local player = Players.LocalPlayer
                        if player and player.CameraMaxZoomDistance < 9999 then
                            player.CameraMaxZoomDistance = 9999
                        end
                    end)
                end)
                Library:Notify({ Title = "Visual", Description = "Infinite Zoom enabled.", Time = 2, Icon = "zoom-in" })
            else
                if zoomConnection then zoomConnection:Disconnect(); zoomConnection = nil end
                restoreZoom()
                Library:Notify({ Title = "Visual", Description = "Infinite Zoom disabled.", Time = 2, Icon = "zoom-out" })
            end
        end
    })


        -- === CUSTOM ANIMATION ID SECTION ===
    local CustomAnimSection = Tabs.Anims:AddGroupbox({ Side = "Left", Name = "Custom Animation ID", Description = "Custom animations", IconName = "link" })

        do -- Custom Animation scope
            local customAnimId = ""
            local customLoopEnabled = false
            local customAnimTrack = nil
            local customPlayingTracks = {}

            -- Input for custom animation ID
            CustomAnimSection:AddInput('Misc_12', {
                Text = "Animation ID",
                Tooltip = "Paste an animation ID (e.g. rbxassetid://123456)",
                Placeholder = "rbxassetid://...",
                Callback = function(text)
                    customAnimId = text
                end
            })

            -- Loop toggle for custom animation
            CustomAnimSection:AddToggle('Misc_13', {
                Text = "Loop Animation",
                Tooltip = "Loop the custom animation until disabled",
                Default = false,
                Callback = function(state)
                    customLoopEnabled = state
                    if state then
                        if not customAnimId or customAnimId == "" then
                            Library:Notify({
                                Title = "Custom Animation",
                                Description = "No animation ID entered!",
                                Time = 2,
                                Icon = "alert-circle"
                            })
                            return
                        end

                        pcall(function()
                            local char = LocalPlayer.Character
                            if not char then return end
                            local humanoid = char:FindFirstChildOfClass("Humanoid")
                            if not humanoid then return end
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if not animator then
                                animator = Instance.new("Animator")
                                animator.Parent = humanoid
                            end

                            local anim = Instance.new("Animation")
                            anim.AnimationId = customAnimId
                            customAnimTrack = animator:LoadAnimation(anim)
                            customAnimTrack.Looped = true
                            customAnimTrack:Play()
                            table.insert(customPlayingTracks, customAnimTrack)
                            -- FIX: Auto-remove track when it stops to prevent unbounded growth
                            customAnimTrack.Stopped:Once(function()
                                for i = #customPlayingTracks, 1, -1 do
                                    if customPlayingTracks[i] == customAnimTrack then
                                        table.remove(customPlayingTracks, i)
                                        break
                                    end
                                end
                            end)
                            anim:Destroy()

                            Library:Notify({
                                Title = "Custom Animation",
                                Description = "Looping animation!",
                                Time = 2,
                                Icon = "repeat"
                            })
                        end)
                    else
                        -- Stop the looping animation
                        if customAnimTrack then
                            pcall(function()
                                customAnimTrack:Stop()
                            end)
                            customAnimTrack = nil
                        end
                        Library:Notify({
                            Title = "Custom Animation",
                            Description = "Stopped looping animation!",
                            Time = 2,
                            Icon = "square"
                        })
                    end
                end
            })

            -- Play custom animation button
            CustomAnimSection:AddButton('Misc_14', {
                Text = "Play Animation",
                Tooltip = "Play the custom animation once",
                Func = function()
                    if not customAnimId or customAnimId == "" then
                        Library:Notify({
                            Title = "Custom Animation",
                            Description = "No animation ID entered!",
                            Time = 2,
                            Icon = "alert-circle"
                        })
                        return
                    end

                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if not humanoid then return end
                        local animator = humanoid:FindFirstChildOfClass("Animator")
                        if not animator then
                            animator = Instance.new("Animator")
                            animator.Parent = humanoid
                        end

                        local anim = Instance.new("Animation")
                        anim.AnimationId = customAnimId
                        local track = animator:LoadAnimation(anim)
                        track:Play()
                        table.insert(customPlayingTracks, track)
                        -- FIX: Auto-remove track when it stops to prevent unbounded growth
                        track.Stopped:Once(function()
                            for i = #customPlayingTracks, 1, -1 do
                                if customPlayingTracks[i] == track then
                                    table.remove(customPlayingTracks, i)
                                    break
                                end
                            end
                        end)
                        anim:Destroy()

                        Library:Notify({
                            Title = "Custom Animation",
                            Description = "Playing animation!",
                            Time = 2,
                            Icon = "play"
                        })
                    end)
                end
            })

            -- Stop custom animation button
            CustomAnimSection:AddButton('Misc_15', {
                Text = "Stop Animation",
                Tooltip = "Stop all custom animations",
                Func = function()
                    pcall(function()
                        -- Stop tracked custom animations
                        for _, track in customPlayingTracks do
                            pcall(function()
                                if track and track.Stop then
                                    track:Stop()
                                end
                            end)
                        end
                        customPlayingTracks = {}

                        -- Stop the loop track too
                        if customAnimTrack then
                            pcall(function()
                                customAnimTrack:Stop()
                            end)
                            customAnimTrack = nil
                        end
                    end)

                    Library:Notify({
                        Title = "Custom Animation",
                        Description = "Stopped animations!",
                        Time = 2,
                        Icon = "square"
                    })
                end
            })
        end -- End Custom Animation scope

        -- === ANIMATION PRESETS SECTION ===
    local AnimPresetSection = Tabs.Anims:AddGroupbox({ Side = "Right", Name = "Animation Presets", Description = "Animation presets", IconName = "film" })

        do -- Animation Presets scope
            -- Animation preset state tracking
            local presetPlayingTracks = {}
            local presetLoopConnections = {}
            local presetActiveStates = {}

            -- Helper function to get animator
            local function getAnimator()
                local char = LocalPlayer.Character
                if not char then return nil end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid then return nil end
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end
                return animator, humanoid
            end

            local function stopAndDestroyTrack(track)
                if not track then return end
                pcall(function()
                    if track.IsPlaying then
                        track:Stop(0.05)
                    end
                end)
                pcall(function() track:Destroy() end)
            end

            local function loadPresetTrack(animator, animationId, priority, looped)
                if not animator or not animationId then return nil end

                local anim = Instance.new("Animation")
                local animString = tostring(animationId)
                anim.AnimationId = string.find(animString, "rbxassetid://", 1, true) and animString or ("rbxassetid://" .. animString)

                local track
                local ok = pcall(function()
                    track = animator:LoadAnimation(anim)
                end)
                anim:Destroy()

                if not ok or not track then
                    return nil
                end

                if priority then
                    track.Priority = priority
                end
                if looped ~= nil then
                    track.Looped = looped
                end
                return track
            end

            -- Helper function to stop all preset animations
            local function stopAllPresets()
                for name, tracks in presetPlayingTracks do
                    for _, track in tracks do
                        stopAndDestroyTrack(track)
                    end
                end
                presetPlayingTracks = {}
                for name, conn in presetLoopConnections do
                    pcall(function()
                        if type(conn) == "thread" then
                            task.cancel(conn)
                        elseif typeof(conn) == "RBXScriptConnection" then
                            conn:Disconnect()
                        elseif typeof(conn) == "Instance" then
                            if conn:IsA("Sound") then
                                conn:Stop()
                            end
                            conn:Destroy()
                        end
                    end)
                end
                presetLoopConnections = {}
                presetActiveStates = {}
                -- Restore walkspeed
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid then humanoid.WalkSpeed = 16 end
                    end
                end)
            end

            local function removePresetTrack(name, targetTrack)
                local tracks = presetPlayingTracks[name]
                if not tracks then return end
                for i = #tracks, 1, -1 do
                    if tracks[i] == targetTrack then
                        table.remove(tracks, i)
                        break
                    end
                end
                if #tracks == 0 then
                    presetPlayingTracks[name] = nil
                end
            end

            local function finalizeCompletedPreset(name)
                local tracks = presetPlayingTracks[name]
                if tracks then
                    for _, track in tracks do
                        stopAndDestroyTrack(track)
                    end
                end
                presetPlayingTracks[name] = nil
                presetLoopConnections[name] = nil
                presetActiveStates[name] = nil
            end

            -- Helper function to play idle/walk animation preset
            local function playIdleWalkPreset(name, idleId, walkId, priority, walkSpeed)
                local animator, humanoid = getAnimator()
                if not animator then return end

                stopAllPresets()
                presetActiveStates[name] = true
                presetPlayingTracks[name] = {}

                local idleTrack = loadPresetTrack(animator, idleId, priority or Enum.AnimationPriority.Action3, true)
                if not idleTrack then return end
                table.insert(presetPlayingTracks[name], idleTrack)

                local walkTrack = loadPresetTrack(animator, walkId, priority or Enum.AnimationPriority.Action3, true)
                if not walkTrack then
                    stopAndDestroyTrack(idleTrack)
                    presetPlayingTracks[name] = {}
                    presetActiveStates[name] = nil
                    return
                end
                table.insert(presetPlayingTracks[name], walkTrack)

                -- Set walk speed if specified
                if walkSpeed then
                    humanoid.WalkSpeed = walkSpeed
                end

                -- Play based on movement
                local lastMoving = false
                idleTrack:Play()

                presetLoopConnections[name] = RunService.Heartbeat:Connect(function()
                    if not presetActiveStates[name] then return end
                    local isMoving = humanoid.MoveDirection.Magnitude > 0.1
                    if isMoving ~= lastMoving then
                        if isMoving then
                            idleTrack:Stop()
                            walkTrack:Play()
                        else
                            walkTrack:Stop()
                            idleTrack:Play()
                        end
                        lastMoving = isMoving
                    end
                end)

                Library:Notify({ Title = "Animation Preset", Description = name .. " activated!", Time = 2, Icon = "play" })
            end

            -- Helper function to play one-shot animation
            local function playOneShotPreset(name, animId, duration)
                local animator, humanoid = getAnimator()
                if not animator then return end

                local track = loadPresetTrack(animator, animId, Enum.AnimationPriority.Action4, false)
                if not track then return end
                track:Play()

                if not presetPlayingTracks[name] then presetPlayingTracks[name] = {} end
                table.insert(presetPlayingTracks[name], track)
                track.Stopped:Once(function()
                    removePresetTrack(name, track)
                    pcall(function() track:Destroy() end)
                end)

                if duration then
                    task.delay(duration, function()
                        pcall(function() track:Stop() end)
                    end)
                end

                Library:Notify({ Title = "Animation Preset", Description = name .. " playing!", Time = 2, Icon = "play" })
            end

            -- Helper function to play looping one-shot animation
            local function playLoopingPreset(name, animId, interval)
                local animator, humanoid = getAnimator()
                if not animator then return end

                stopAllPresets()
                presetActiveStates[name] = true
                presetPlayingTracks[name] = {}

                local track = loadPresetTrack(animator, animId, Enum.AnimationPriority.Action4, false)
                if not track then
                    presetActiveStates[name] = nil
                    return
                end
                table.insert(presetPlayingTracks[name], track)

                presetLoopConnections[name] = task.spawn(function()
                    while presetActiveStates[name] do
                        track:Play()
                        task.wait(interval or track.Length or 1)
                    end
                end)

                Library:Notify({ Title = "Animation Preset", Description = name .. " activated!", Time = 2, Icon = "play" })
            end

            -- Stop All Presets Button
            AnimPresetSection:AddButton('Misc_16', {
                Text = "Stop All Presets",
                Tooltip = "Stop all animation presets and restore normal state",
                Func = function()
                    stopAllPresets()
                    Library:Notify({ Title = "Animation Preset", Description = "All presets stopped!", Time = 2, Icon = "square" })
                end
            })

            -- ===== ZOMBIE ANIMATIONS =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Zombie Animations ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_17', {
                Text = "Zapper",
                Tooltip = "Zapper zombie animation with effect",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end
                    playIdleWalkPreset("Zapper", "12333488814", "12333490576", Enum.AnimationPriority.Action2, nil)

                    local effectTrack = loadPresetTrack(animator, "12638401607", Enum.AnimationPriority.Action3, true)
                    if effectTrack and presetPlayingTracks["Zapper"] then
                        effectTrack:Play()
                        table.insert(presetPlayingTracks["Zapper"], effectTrack)
                    end
                end
            })

            AnimPresetSection:AddButton('Misc_18', {
                Text = "Zapper Animation",
                Tooltip = "Standard Zapper zombie animation",
                Func = function() playIdleWalkPreset("Zapper", "14498563473", "14498289874", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_19', {
                Text = "Zapper Effect",
                Tooltip = "Play Zapper special effect once",
                Func = function() playOneShotPreset("Zapper Effect", "14499470197", nil) end
            })

            AnimPresetSection:AddButton('Misc_20', {
                Text = "Shambler Animation",
                Tooltip = "Shambler zombie idle/walk",
                Func = function() playIdleWalkPreset("Shambler", "12333488814", "14463730540", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_21', {
                Text = "Old Shambler",
                Tooltip = "Old Shambler zombie animation",
                Func = function() playIdleWalkPreset("Old Shambler", "12333488814", "12333490857", Enum.AnimationPriority.Idle, nil) end
            })

            AnimPresetSection:AddButton('Misc_22', {
                Text = "Shambler Eating",
                Tooltip = "Shambler eating animation (10 sec)",
                Func = function() playOneShotPreset("Shambler Eating", "18339432914", 10) end
            })

            AnimPresetSection:AddButton('Misc_23', {
                Text = "Lantern",
                Tooltip = "Lantern zombie animation",
                Func = function() playIdleWalkPreset("Lantern", "14678879479", "14678880308", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_24', {
                Text = "Cuirassier Animation",
                Tooltip = "Cuirassier zombie animation",
                Func = function() playIdleWalkPreset("Cuirassier", "87579228279296", "102081698785465", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_25', {
                Text = "Cuirassier Alt",
                Tooltip = "Alternate Cuirassier animation",
                Func = function() playIdleWalkPreset("Cuirassier Alt", "82800474630427", "118210337289087", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_26', {
                Text = "Headless zombie",
                Tooltip = "Headless zombie animation",
                Func = function() playIdleWalkPreset("Headless zombie", "107080941320600", "74764025513892", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_27', {
                Text = "Crawler",
                Tooltip = "Crawling zombie animation",
                Func = function() playIdleWalkPreset("Crawler", "13726632691", "13726634549", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_28', {
                Text = "Bomber Animation",
                Tooltip = "Self-destruct bomber animation",
                Func = function() playIdleWalkPreset("Bomber Animation", "13211198049", "13211207597", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_29', {
                Text = "Default",
                Tooltip = "Default zombie animation",
                Func = function() playIdleWalkPreset("Default", "180435571", "180426354", Enum.AnimationPriority.Idle, nil) end
            })

            -- ===== CHARACTER ANIMATIONS =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Character Animations ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_30', {
                Text = "Boxer",
                Tooltip = "Boxing animation (click to punch)",
                Func = function() playIdleWalkPreset("Boxer", "124381258015151", "127477273497271", Enum.AnimationPriority.Action3, 17) end
            })

            AnimPresetSection:AddButton('Misc_31', {
                Text = "Dracula",
                Tooltip = "Dracula vampire animation",
                Func = function() playIdleWalkPreset("Dracula", "14970033333", "15486477524", Enum.AnimationPriority.Action3, 16) end
            })

            AnimPresetSection:AddButton('Misc_32', {
                Text = "Impaled walk",
                Tooltip = "Impaled walk (slow walk)",
                Func = function() playIdleWalkPreset("Impaled walk", "111210841378590", "139186204185685", Enum.AnimationPriority.Action3, 5) end
            })

            AnimPresetSection:AddButton('Misc_33', {
                Text = "Red Eyes",
                Tooltip = "Red eyes animation with speed boost (35)",
                Func = function() playIdleWalkPreset("Red Eyes", "12581784105", "12581785298", Enum.AnimationPriority.Action3, 35) end
            })

            AnimPresetSection:AddButton('Misc_34', {
                Text = "Napoleon Hands Behind",
                Tooltip = "Napoleon hands behind back pose",
                Func = function() playIdleWalkPreset("Napoleon", "103557875332543", "103557875332543", Enum.AnimationPriority.Action4, nil) end
            })

            AnimPresetSection:AddButton('Misc_35', {
                Text = "Freezing/Cold",
                Tooltip = "Cold shivering animation",
                Func = function() playIdleWalkPreset("Cold", "16863977222", "16876434500", Enum.AnimationPriority.Action3, nil) end
            })

            AnimPresetSection:AddButton('Misc_36', {
                Text = "Low Health",
                Tooltip = "Injured/low health animation",
                Func = function() playIdleWalkPreset("Low Health", "14970034680", "15530089342", Enum.AnimationPriority.Idle, nil) end
            })

            -- ===== COMBAT ANIMATIONS =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Combat Animations ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_37', {
                Text = "Musket Charge",
                Tooltip = "Musket charging animation (speed 24)",
                Func = function() playIdleWalkPreset("Musket Charge", "14292935158", "14292937831", Enum.AnimationPriority.Action3, 24) end
            })

            AnimPresetSection:AddButton('Misc_38', {
                Text = "Greatsword Charge",
                Tooltip = "Greatsword charging animation (speed 24)",
                Func = function() playIdleWalkPreset("Greatsword Charge", "14284611111", "17406602570", Enum.AnimationPriority.Action3, 24) end
            })

            AnimPresetSection:AddButton('Misc_39', {
                Text = "Bayonet Charge",
                Tooltip = "Standard bayonet charge (speed 24)",
                Func = function() playIdleWalkPreset("Bayonet Charge", "14284611111", "14284623849", Enum.AnimationPriority.Idle, 24) end
            })

            AnimPresetSection:AddButton('Misc_40', {
                Text = "Fake Bayonet",
                Tooltip = "Fake bayonet stance (click for stab)",
                Func = function() playIdleWalkPreset("Fake Bayonet", "12333492041", "12333492041", Enum.AnimationPriority.Action3, 17) end
            })

            AnimPresetSection:AddButton('Misc_41', {
                Text = "Gun Spin",
                Tooltip = "Spinning gun trick (looping)",
                Func = function() playLoopingPreset("Gun Spin", "15827239870", 0.73) end
            })

            AnimPresetSection:AddButton('Misc_42', {
                Text = "Elbow Strike",
                Tooltip = "Elbow strike combo (looping)",
                Func = function() playLoopingPreset("Elbow Strike", "15345113937", 0.6) end
            })

            AnimPresetSection:AddButton('Misc_43', {
                Text = "Skibidi Fast Slash Ahhh",
                Tooltip = "Super fast slashing with spin",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end
                    local char = LocalPlayer.Character
                    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end

                    stopAllPresets()
                    presetActiveStates["Skibidi Fast Slash Ahhh"] = true
                    presetPlayingTracks["Skibidi Fast Slash Ahhh"] = {}

                    local track = loadPresetTrack(animator, "12591938344", Enum.AnimationPriority.Action4, false)
                    if not track then
                        presetActiveStates["Skibidi Fast Slash Ahhh"] = nil
                        return
                    end
                    table.insert(presetPlayingTracks["Skibidi Fast Slash Ahhh"], track)

                    local rotationSpeed = 1440

                    presetLoopConnections["Skibidi Fast Slash Ahhh"] = task.spawn(function()
                        while presetActiveStates["Skibidi Fast Slash Ahhh"] do
                            track:Play()
                            local deltaTime = task.wait(0.1)
                            if rootPart then
                                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, mathRad(rotationSpeed * 0.1), 0)
                            end
                        end
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "Skibidi Fast Slash Ahhh activated!", Time = 2, Icon = "play" })
                end
            })

            -- ===== SPECIAL ANIMATIONS =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Special Animations ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_44', {
                Text = "Play Dead",
                Tooltip = "Play dead/faint animation",
                Func = function() playOneShotPreset("Play Dead", "89945348540089", nil) end
            })

            AnimPresetSection:AddButton('Misc_45', {
                Text = "Sad Dance",
                Tooltip = "Sad dance (20 sec)",
                Func = function() playOneShotPreset("Sad Dance", "14860627011", 20) end
            })

            AnimPresetSection:AddButton('Misc_46', {
                Text = "Flying",
                Tooltip = "Flying pose animation (looping)",
                Func = function() playLoopingPreset("Flying", "110087359963835", nil) end
            })

            AnimPresetSection:AddButton('Misc_47', {
                Text = "Headless Horseman",
                Tooltip = "Headless horseman with music (speed 38)",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end
                    local char = LocalPlayer.Character

                    stopAllPresets()
                    presetActiveStates["Headless Horseman"] = true
                    presetPlayingTracks["Headless Horseman"] = {}

                    -- Create and play music
                    local music = Instance.new("Sound")
                    music.SoundId = "rbxassetid://1836635087"
                    music.Looped = true
                    music.Volume = 5
                    music.Parent = char:FindFirstChild("Head") or char
                    music:Play()

                    humanoid.WalkSpeed = 38

                    playIdleWalkPreset("Headless Horseman", "13936362530", "13936362530", Enum.AnimationPriority.Action3, 38)

                    -- Store music for cleanup
                    presetLoopConnections["Headless Horseman Music"] = music
                end
            })

            AnimPresetSection:AddButton('Misc_48', {
                Text = "Eating Long Stick",
                Tooltip = "Eating something long (Gagging Noises)",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["Eating"] = true
                    presetPlayingTracks["Eating"] = {}

                    local track = loadPresetTrack(animator, "16863982325", Enum.AnimationPriority.Action4, false)
                    if not track then
                        presetActiveStates["Eating"] = nil
                        return
                    end
                    table.insert(presetPlayingTracks["Eating"], track)

                    presetLoopConnections["Eating"] = task.spawn(function()
                        while presetActiveStates["Eating"] do
                            track:Play()
                            track:AdjustSpeed(0)
                            track.TimePosition = 1.8
                            track:AdjustSpeed(1)
                            task.wait(0.1)
                        end
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "Eating activated!", Time = 2, Icon = "play" })
                end
            })

            AnimPresetSection:AddButton('Misc_49', {
                Text = "Cross Use",
                Tooltip = "Using a cross animation",
                Func = function() playOneShotPreset("Cross Use", "15210536563", nil) end
            })

            AnimPresetSection:AddButton('Misc_50', {
                Text = "Zombie Breaking The Door",
                Tooltip = "Zombie breaking door animation",
                Func = function() playOneShotPreset("Door Breach", "15593727441", nil) end
            })

            AnimPresetSection:AddButton('Misc_51', {
                Text = "Crawford",
                Tooltip = "Crawford special animation",
                Func = function() playOneShotPreset("Crawford", "77859967130018", nil) end
            })

            -- ===== INJURY ANIMATIONS =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Injury Animations ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_52', {
                Text = "Cuirassier Stabbed",
                Tooltip = "Stabbed by cuirassier animation",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["CuirassierStabbed"] = true
                    presetPlayingTracks["CuirassierStabbed"] = {}
                    humanoid.WalkSpeed = 0

                    local track1 = loadPresetTrack(animator, "121955221153387", Enum.AnimationPriority.Action4, false)
                    if not track1 then
                        humanoid.WalkSpeed = 16
                        presetActiveStates["CuirassierStabbed"] = nil
                        presetPlayingTracks["CuirassierStabbed"] = nil
                        return
                    end
                    table.insert(presetPlayingTracks["CuirassierStabbed"], track1)
                    track1:Play()

                    track1.Stopped:Once(function()
                        -- Check if preset was stopped manually
                        if not presetActiveStates["CuirassierStabbed"] then
                            humanoid.WalkSpeed = 16
                            return
                        end

                        local track2 = loadPresetTrack(animator, "111210841378590", Enum.AnimationPriority.Action4, true)
                        if not track2 then
                            presetActiveStates["CuirassierStabbed"] = nil
                            presetPlayingTracks["CuirassierStabbed"] = nil
                            humanoid.WalkSpeed = 16
                            return
                        end
                        table.insert(presetPlayingTracks["CuirassierStabbed"], track2)
                        track2:Play()

                        track2.Stopped:Once(function()
                            finalizeCompletedPreset("CuirassierStabbed")
                            humanoid.WalkSpeed = 16
                        end)
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "Stabbed animation playing!", Time = 2, Icon = "play" })
                end
            })

            AnimPresetSection:AddButton('Misc_53', {
                Text = "Breaking Bones",
                Tooltip = "Bone breaking/fracture animation",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["Breaking Bones"] = true
                    presetPlayingTracks["Breaking Bones"] = {}
                    humanoid.WalkSpeed = 0

                    local track1 = loadPresetTrack(animator, "12333490324", Enum.AnimationPriority.Action4, false)
                    if not track1 then
                        humanoid.WalkSpeed = 16
                        presetActiveStates["Breaking Bones"] = nil
                        return
                    end
                    table.insert(presetPlayingTracks["Breaking Bones"], track1)
                    track1:Play()

                    track1.Stopped:Once(function()
                        local track2 = loadPresetTrack(animator, "12333489072", Enum.AnimationPriority.Action4, false)
                        if not track2 then
                            humanoid.WalkSpeed = 16
                            finalizeCompletedPreset("Breaking Bones")
                            return
                        end
                        table.insert(presetPlayingTracks["Breaking Bones"], track2)
                        track2:Play()
                        task.delay(3, function()
                            humanoid.WalkSpeed = 16
                            finalizeCompletedPreset("Breaking Bones")
                        end)
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "Fracture animation playing!", Time = 2, Icon = "play" })
                end
            })

            -- ===== CINEMATIC SEQUENCES =====
            AnimPresetSection:AddLabel({
                Text = "━━━ Cinematic Sequences ━━━",
                DoesWrap = true,
                Size = 14,
            })

            AnimPresetSection:AddButton('Misc_54', {
                Text = "BlÃ¼cher",
                Tooltip = "BlÃ¼cher cinematic sequence",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["Blucher"] = true

                    -- Stop all current animations
                    for _, track in humanoid:GetPlayingAnimationTracks() do
                        track:Stop()
                    end

                    local animIds = {"15603033178", "16168689655", "15680560478", "15688743558", "15637342030"}
                    local tracks = {}
                    presetPlayingTracks["Blucher"] = tracks

                    for i, id in animIds do
                        tracks[i] = loadPresetTrack(animator, id, Enum.AnimationPriority.Action4, false)
                        if not tracks[i] then
                            stopAllPresets()
                            return
                        end
                    end

                    presetLoopConnections["Blucher"] = task.spawn(function()
                        if not presetActiveStates["Blucher"] then return end
                        tracks[1]:Play()
                        tracks[1].Stopped:Wait()

                        if not presetActiveStates["Blucher"] then return end
                        tracks[2]:Play()
                        tracks[2].Stopped:Wait()

                        if not presetActiveStates["Blucher"] then return end
                        tracks[3]:Play()
                        task.wait(3)
                        if tracks[3].IsPlaying then tracks[3]:Stop() end

                        if not presetActiveStates["Blucher"] then return end
                        tracks[4]:Play()
                        tracks[4].Stopped:Wait()

                        if not presetActiveStates["Blucher"] then return end
                        tracks[3]:Play()
                        task.wait(3)
                        if tracks[3].IsPlaying then tracks[3]:Stop() end

                        if not presetActiveStates["Blucher"] then return end
                        tracks[5]:Play()
                        tracks[5].Stopped:Wait()

                        finalizeCompletedPreset("Blucher")
                        Library:Notify({ Title = "Animation Preset", Description = "BlÃ¼cher sequence complete!", Time = 2, Icon = "check" })
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "BlÃ¼cher sequence started!", Time = 2, Icon = "play" })
                end
            })

            AnimPresetSection:AddButton('Misc_55', {
                Text = "idk",
                Tooltip = "idk officer cinematic sequence",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["Adjutant"] = true

                    for _, track in humanoid:GetPlayingAnimationTracks() do
                        track:Stop()
                    end

                    local animIds = {"15603037116", "15622136729", "15688841016", "15637317651"}
                    local tracks = {}
                    presetPlayingTracks["Adjutant"] = tracks

                    for i, id in animIds do
                        tracks[i] = loadPresetTrack(animator, id, Enum.AnimationPriority.Action4, false)
                        if not tracks[i] then
                            stopAllPresets()
                            return
                        end
                    end

                    presetLoopConnections["Adjutant"] = task.spawn(function()
                        if not presetActiveStates["Adjutant"] then return end
                        tracks[1]:Play()
                        tracks[1].Stopped:Wait()

                        if not presetActiveStates["Adjutant"] then return end
                        tracks[2]:Play()
                        tracks[2].Stopped:Wait()

                        if not presetActiveStates["Adjutant"] then return end
                        tracks[3]:Play()
                        task.wait(9)
                        if tracks[3].IsPlaying then tracks[3]:Stop() end

                        if not presetActiveStates["Adjutant"] then return end
                        tracks[4]:Play()
                        tracks[4].Stopped:Wait()

                        finalizeCompletedPreset("Adjutant")
                        Library:Notify({ Title = "Animation Preset", Description = "idk sequence complete!", Time = 2, Icon = "check" })
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "idk sequence started!", Time = 2, Icon = "play" })
                end
            })

            AnimPresetSection:AddButton('Misc_56', {
                Text = "Barry",
                Tooltip = "Barry getting bitten cinematic sequence",
                Func = function()
                    local animator, humanoid = getAnimator()
                    if not animator then return end

                    stopAllPresets()
                    presetActiveStates["Barry"] = true

                    for _, track in humanoid:GetPlayingAnimationTracks() do
                        track:Stop()
                    end

                    local animIds = {"14284371664", "14284387207", "14284382730", "14304936421"}
                    local tracks = {}
                    presetPlayingTracks["Barry"] = tracks

                    for i, id in animIds do
                        tracks[i] = loadPresetTrack(animator, id, Enum.AnimationPriority.Action4, false)
                        if not tracks[i] then
                            stopAllPresets()
                            return
                        end
                    end

                    presetLoopConnections["Barry"] = task.spawn(function()
                        if not presetActiveStates["Barry"] then return end
                        tracks[1]:Play()
                        tracks[1].Stopped:Wait()

                        if not presetActiveStates["Barry"] then return end
                        tracks[2]:Play()
                        task.wait(10)
                        if tracks[2].IsPlaying then tracks[2]:Stop() end

                        if not presetActiveStates["Barry"] then return end
                        tracks[3]:Play()
                        tracks[3].Stopped:Wait()

                        if not presetActiveStates["Barry"] then return end
                        tracks[2]:Play(0, 1, -1) -- Play reversed
                        task.wait(3)
                        if tracks[2].IsPlaying then tracks[2]:Stop() end

                        if not presetActiveStates["Barry"] then return end
                        tracks[4]:Play()
                        tracks[4].Stopped:Wait()

                        finalizeCompletedPreset("Barry")
                        Library:Notify({ Title = "Animation Preset", Description = "Barry sequence complete!", Time = 2, Icon = "check" })
                    end)

                    Library:Notify({ Title = "Animation Preset", Description = "Barry sequence started!", Time = 2, Icon = "play" })
                end
            })

        end -- End Animation Presets scope

        do -- WalkSpeed scope (split to stay under 200 local registers)
        -- === WalkSpeed forcing ===
        desiredWalkSpeed = 16 -- Global for keybind access
        walkLoopEnabled = false -- Global for keybind access
        local heartbeatConn = nil
        -- Use weak keys so entries for destroyed humanoids are garbage collected
        local humPropConns = setmetatable({}, { __mode = "k" }) -- [Humanoid] = connection

        local function safeSetWalk(hum, speed)
            if not (hum and hum.Parent) then return end
            -- Game owns WalkSpeed via UserStates.SpeedController (priority
            -- sort; highest priority wins). Raw hum.WalkSpeed sets lose to it,
            -- so drive the "Haste" modifier at priority 100 instead.
            local sc = nil
            pcall(function()
                local wsPlayers = Workspace:FindFirstChild("Players")
                local pf = wsPlayers and LocalPlayer and wsPlayers:FindFirstChild(LocalPlayer.Name)
                local us = pf and pf:FindFirstChild("UserStates")
                local scMod = us and us:FindFirstChild("SpeedController")
                if (not scMod) and LocalPlayer and LocalPlayer.Character then
                    local cus = LocalPlayer.Character:FindFirstChild("UserStates")
                    scMod = cus and cus:FindFirstChild("SpeedController")
                end
                if scMod and scMod:IsA("ModuleScript") then
                    sc = require(scMod)
                end
            end)
            if type(sc) == "table" and type(sc.SetModifier) == "function" then
                pcall(function() sc.SetModifier("Haste", speed, 100) end)
            else
                pcall(function()
                    hum.WalkSpeed = speed
                end)
            end
        end

        local function clearWalkMod()
            pcall(function()
                local wsPlayers = Workspace:FindFirstChild("Players")
                local pf = wsPlayers and LocalPlayer and wsPlayers:FindFirstChild(LocalPlayer.Name)
                local us = pf and pf:FindFirstChild("UserStates")
                local scMod = us and us:FindFirstChild("SpeedController")
                if scMod and scMod:IsA("ModuleScript") then
                    local sc = require(scMod)
                    if type(sc) == "table" and type(sc.RemoveModifier) == "function" then
                        sc.RemoveModifier("Haste")
                    end
                end
            end)
        end

        local function onHumanoidPropChanged(hum)
            -- immediate restore if WalkSpeed changed by something else
            return hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if walkLoopEnabled then
                    safeSetWalk(hum, desiredWalkSpeed)
                end
            end)
        end

        function attachToCharacter(character) -- Global for keybind access
            if not character then return end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hum then
                hum = character:WaitForChild("Humanoid", 2)
            end
            if hum then
                -- ensure no duplicate connection
                if humPropConns[hum] then
                    pcall(function() humPropConns[hum]:Disconnect() end)
                    humPropConns[hum] = nil
                end
                humPropConns[hum] = onHumanoidPropChanged(hum)
                -- immediate enforce
                safeSetWalk(hum, desiredWalkSpeed)
            end
        end

        local function detachAllHumanoidConns()
            for hum, conn in humPropConns do
                pcall(function() conn:Disconnect() end)
            end
            humPropConns = setmetatable({}, { __mode = "k" })
        end

        function startWalkForceLoop() -- Global for keybind access
            if heartbeatConn then heartbeatConn:Disconnect() end
            local _walkForceLastCheck = 0
            heartbeatConn = RunService.Heartbeat:Connect(function()
                if not walkLoopEnabled then return end
                local now = time()
                if now - _walkForceLastCheck < 0.5 then return end
                _walkForceLastCheck = now
                local char = LocalPlayer and LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        -- enforce periodically as a safety net
                        safeSetWalk(hum, desiredWalkSpeed)
                        -- ensure we have a property watcher attached
                        if not humPropConns[hum] then
                            humPropConns[hum] = onHumanoidPropChanged(hum)
                        end
                    end
                end
            end)
        end

        function stopWalkForceLoop() -- Global for keybind access
            if heartbeatConn then
                heartbeatConn:Disconnect()
                heartbeatConn = nil
            end
            detachAllHumanoidConns()
            clearWalkMod()
            -- restore default on toggle off
            pcall(function()
                local char = LocalPlayer and LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end)
        end

        -- keep hooking on character spawn
        if LocalPlayer then
            _G.ArreyConns = _G.ArreyConns or {}
            if _G.ArreyConns.walkForceRespawn then pcall(function() _G.ArreyConns.walkForceRespawn:Disconnect() end) end
            _G.ArreyConns.walkForceRespawn = LocalPlayer.CharacterAdded:Connect(function(char)
                -- wait briefly for humanoid to exist
                task.wait(0.15)
                if walkLoopEnabled then
                    attachToCharacter(char)
                    startWalkForceLoop()
                end
            end)
        end

        -- Movement UI: slider max 60 via SpeedController "Haste" (does NOT immediately apply - waits for toggle)
        MovementSection:AddSlider('Movement_1', {
            Text = "WalkSpeed",
            Tooltip = "Set walkspeed value",
            Rounding = 1,
            Min = 16,
            Max = 60,
            Default = desiredWalkSpeed or 16,
            Callback = function(v)
                desiredWalkSpeed = mathClamp(tonumber(v) or desiredWalkSpeed, 16, 60)
                -- Only apply if the toggle is already enabled
                if walkLoopEnabled then
                    local char = LocalPlayer and LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then safeSetWalk(hum, desiredWalkSpeed) end
                    end
                end
            end
        })

        local ApplyWalkSpeedToggle = MovementSection:AddToggle('Movement_2', {
            Text = "Apply WalkSpeed",
            Tooltip = "Force Walkspeed",
            Default = false,
            Callback = function(state)
                walkLoopEnabled = state
                if state then
                    -- attach to current character, start heartbeat enforcement
                    if LocalPlayer and LocalPlayer.Character then attachToCharacter(LocalPlayer.Character) end
                    startWalkForceLoop()
                    Library:Notify({ Title = "Movement", Description = "WalkSpeed enabled.", Time = 2, Icon = "check" })
                else
                    stopWalkForceLoop()
                    Library:Notify({ Title = "Movement", Description = "WalkSpeed disabled.", Time = 2, Icon = "x" })
                end
            end
        })
        _G.ArreyToggleElements = _G.ArreyToggleElements or {}
        _G.ArreyToggleElements.ApplyWalkSpeed = ApplyWalkSpeedToggle

        end -- end WalkSpeed scope
        do -- NoJump scope (split to stay under 200 local registers)
        -- === No Jump Cooldown ===
        -- Game files: Workspace.Players.<name>.Interact gates JumpRequest
        -- behind a 1s debounce (u186 flag): each accepted jump sets JumpPower
        -- 30 for one frame, then task.wait(1) before the next is allowed.
        -- While debounced the game zeroes JumpPower, so the impulse below
        -- re-asserts 30 AND forces the jump in the same frame (order-free).
        -- Pin lock and the impulse itself are untouched.
        NoJumpCooldownEnabled = false -- Global for keybind access
        local jumpCooldownConn = nil
        local njcPowerLockConn = nil
        local njcCharHooked = false
        local njcLastImpulse = 0
        local njcReleaseHooked = false

        local function njcGetPin()
            local wp = Workspace:FindFirstChild("Players")
            local f = wp and LocalPlayer and wp:FindFirstChild(LocalPlayer.Name)
            local us = f and f:FindFirstChild("UserStates")
            return us and us:FindFirstChild("Pin")
        end

        -- Normal jump, no cooldown (diddy-style): JumpPower pinned at 30 so
        -- the game's debounce can never zero it, and the jump itself is a
        -- grounded velocity kick + ChangeState. Grounded-only means it never
        -- fights ladders, swimming or mid-air states (no sinking).
        local function njcImpulse()
            if not NoJumpCooldownEnabled then return false end
            local char = LocalPlayer and LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hum.Parent or not hrp then return false end
            local pin = njcGetPin()
            if pin and pin.Value ~= "None" then return false end
            if hum.FloorMaterial == Enum.Material.Air then return false end
            -- One clean hop per takeoff: stacked impulses right after liftoff
            -- would pile velocity and make held jumps higher than taps.
            local nowKick = os.clock()
            if nowKick - njcLastImpulse < 0.2 then return false end
            njcLastImpulse = nowKick
            local ok = pcall(function()
                hum.JumpPower = 30
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = v3new(v.X, 30, v.Z)
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
            return ok
        end

        local function njcOnJump()
            njcImpulse()
        end

        -- Mobile hold-to-bhop: the touch jump button only fires per tap, so
        -- holding it loops the impulse. Buttons are discovered at runtime
        -- (default TouchGui JumpButton + any custom jump button).
        local njcJumpHeld = false
        local njcJumpLoopRunning = false
        local njcHookedButtons = {}

        local function njcHoldLoop()
            if njcJumpLoopRunning then return end
            njcJumpLoopRunning = true
            -- Dead-man cap: a missed release can never stick the loop forever.
            local deadline = os.clock() + 5
            while njcJumpHeld and NoJumpCooldownEnabled and os.clock() < deadline do
                njcImpulse()
                task.wait(0.07)
            end
            njcJumpHeld = false
            njcJumpLoopRunning = false
        end

        local function njcHookButton(btn)
            if not btn or njcHookedButtons[btn] then return end
            njcHookedButtons[btn] = true
            pcall(function()
                btn.InputBegan:Connect(function(input)
                    -- Hold-to-bhop is touch-only; mouse clicks fire one impulse
                    -- so a desktop click can never stick the hold loop on.
                    if input.UserInputType == Enum.UserInputType.Touch then
                        njcImpulse()
                        njcJumpHeld = true
                        task.spawn(njcHoldLoop)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        njcImpulse()
                    end
                end)
            end)
            pcall(function()
                btn.InputEnded:Connect(function(input)
                    local t = input.UserInputType
                    if t == Enum.UserInputType.Touch then
                        njcFinishHop()
                        njcJumpHeld = false
                    elseif t == Enum.UserInputType.MouseButton1 then
                        njcJumpHeld = false
                    end
                end)
            end)
        end

        local function njcFindJumpButtons()
            local found = {}
            pcall(function()
                local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    local touchGui = pg:FindFirstChild("TouchGui")
                    if touchGui then
                        local frame = touchGui:FindFirstChild("TouchControlFrame")
                        local jb = frame and frame:FindFirstChild("JumpButton")
                        if jb then table.insert(found, jb) end
                    end
                    for _, d in pg:GetDescendants() do
                        if d:IsA("TextButton") or d:IsA("ImageButton") then
                            local nm = tostring(d.Name or ""):lower()
                            local tx = ""
                            pcall(function() tx = tostring(d.Text or ""):lower() end)
                            if nm:find("jump", 1, true) or (tx ~= "" and tx:find("jump", 1, true)) then
                                table.insert(found, d)
                            end
                        end
                    end
                end
            end)
            return found
        end

        -- Hop completer: a quick tap releases mid-ascent and the engine cuts
        -- the hop short (tap = no jump, hold = full hop). Re-kick on early
        -- release so every tap delivers the same full hop as a hold.
        local function njcFinishHop()
            if not NoJumpCooldownEnabled then return end
            local nowRel = os.clock()
            if nowRel - njcLastImpulse > 0.3 then return end
            local char = LocalPlayer and LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hum.Parent or not hrp then return end
            local pin = njcGetPin()
            if pin and pin.Value ~= "None" then return end
            local v = hrp.AssemblyLinearVelocity
            if v.Y < 5 then return end
            njcLastImpulse = nowRel
            pcall(function()
                hum.JumpPower = 30
                hrp.AssemblyLinearVelocity = v3new(v.X, 30, v.Z)
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end

        -- Pin JumpPower at 30 on this humanoid; re-applied instantly on
        -- toggle (no respawn needed) and re-pinned after every respawn.
        local function njcLockPower(hum)
            if njcPowerLockConn then
                pcall(function() njcPowerLockConn:Disconnect() end)
                njcPowerLockConn = nil
            end
            if not hum or not hum.Parent then return end
            hum.JumpPower = 30
            njcPowerLockConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                if NoJumpCooldownEnabled and hum.Parent and hum.JumpPower ~= 30 then
                    hum.JumpPower = 30
                end
            end)
        end

        function setNoJumpCooldown(state) -- Global for keybind access
            NoJumpCooldownEnabled = state
            if state then
                if jumpCooldownConn then
                    pcall(function() jumpCooldownConn:Disconnect() end)
                    jumpCooldownConn = nil
                end
                jumpCooldownConn = UserInputService.JumpRequest:Connect(njcOnJump)
                local char = LocalPlayer and LocalPlayer.Character
                njcLockPower(char and char:FindFirstChildOfClass("Humanoid"))
                if not njcCharHooked then
                    njcCharHooked = true
                    pcall(function()
                        LocalPlayer.CharacterAdded:Connect(function(newChar)
                            if not NoJumpCooldownEnabled then return end
                            task.wait(0.3)
                            if LocalPlayer.Character ~= newChar then return end
                            njcLockPower(newChar and newChar:FindFirstChildOfClass("Humanoid"))
                        end)
                    end)
                end
                task.spawn(function()
                    while NoJumpCooldownEnabled do
                        for _, b in njcFindJumpButtons() do njcHookButton(b) end
                        task.wait(2)
                    end
                end)
                if not njcReleaseHooked then
                    njcReleaseHooked = true
                    pcall(function()
                        UserInputService.InputEnded:Connect(function(input)
                            if input.KeyCode == Enum.KeyCode.Space then
                                njcFinishHop()
                            end
                        end)
                    end)
                end
                Library:Notify({ Title = "Movement", Description = "No Jump Cooldown enabled.", Time = 2, Icon = "check" })
            else
                njcJumpHeld = false
                if jumpCooldownConn then
                    pcall(function() jumpCooldownConn:Disconnect() end)
                    jumpCooldownConn = nil
                end
                if njcPowerLockConn then
                    pcall(function() njcPowerLockConn:Disconnect() end)
                    njcPowerLockConn = nil
                end
                pcall(function()
                    local char = LocalPlayer and LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = 0 end
                end)
                Library:Notify({ Title = "Movement", Description = "No Jump Cooldown disabled.", Time = 2, Icon = "x" })
            end
        end

        local NoJumpCooldownToggle = MovementSection:AddToggle('NoJumpCooldown', {
            Text = "No Jump Cooldown",
            Tooltip = "Removes the jump cooldown. Nothing else changed.",
            Default = false,
            Callback = function(state)
                setNoJumpCooldown(state)
            end
        })
        _G.ArreyToggleElements = _G.ArreyToggleElements or {}
        _G.ArreyToggleElements.NoJumpCooldown = NoJumpCooldownToggle

        end -- end NoJump scope
        do -- Music scope (split to stay under 200 local registers)
        -- === SHARED MUSIC SYSTEM VARIABLES (used by both Presets and Background Music sections) ===
        local currentMusicSound = nil
        local musicEnabled = false
        local musicVolume = 0.5
        local selectedAudioData = nil

        local function getMusicSound()
            if not currentMusicSound or not currentMusicSound.Parent then
                currentMusicSound = Instance.new("Sound")
                currentMusicSound.Name = "BackgroundMusic_Arrey"
                currentMusicSound.Parent = SoundService
                currentMusicSound.Looped = true
                currentMusicSound.Volume = musicVolume
            end
            return currentMusicSound
        end

        -- === MUSIC PRESETS SECTION ===
        local MUSIC_PRESETS = {
            { name = "1812 Overture",                           id = "1838603000"      },
            { name = "Facing the Inevitable",                   id = "1848015112"      },
            { name = "Fraught Anxiety",                         id = "1835318303"      },
            { name = "Finale London",                           id = "1835264051"      },
            { name = "The Final Push",                          id = "1835172813"      },
            { name = "Winter",                                  id = "1848052307"      },
            { name = "Summer",                                  id = "1842159809"      },
            { name = "Egmont Overture",                         id = "1843531626"      },
            { name = "Bach's Fugue in G Minor",                 id = "107360532004113" },
            { name = "Bach's Toccata and Fugue in D Minor",     id = "1836635015"      },
            { name = "Pachelbel's Toccata and Fugue in D Minor",id = "1847145765"      },
            { name = "My Love Is but a Lassie Yet",             id = "1840466666"      },
            { name = "Ode To Joy",                              id = "1848044822"      },
        }

        local presetDropdownValues = {}
        local presetNameToData = {}
        for _, preset in MUSIC_PRESETS do
            table.insert(presetDropdownValues, preset.name)
            presetNameToData[preset.name] = preset
        end

        local selectedPreset = nil
    local MusicPresetsSection = MiscTab:AddGroupbox({ Side = "Left", Name = "Music Presets", Description = "Music presets", IconName = "disc" })

        MusicPresetsSection:AddDropdown('BGMusic_Preset', {
            Text = "Select Preset",
            Tooltip = "Choose a preset track to play",
            Multi = false,
            Values = presetDropdownValues,
            Callback = function(selected)
                if selected and presetNameToData[selected] then
                    selectedPreset = presetNameToData[selected]
                end
            end
        })

        MusicPresetsSection:AddButton('Misc_67', {
            Text = "Play Preset",
            Tooltip = "Play the selected preset track",
            Func = function()
                if selectedPreset then
                    pcall(function()
                        local sound = getMusicSound()
                        sound.SoundId = "rbxassetid://" .. selectedPreset.id
                        sound.Volume = musicVolume
                        sound:Play()
                        selectedAudioData = {name = selectedPreset.name, id = tonumber(selectedPreset.id)}
                        musicEnabled = true
                        Library:Notify({Title = "Music Presets", Description = "Playing: " .. selectedPreset.name, Time = 3, Icon = "music"})
                    end)
                else
                    Library:Notify({Title = "Music Presets", Description = "Select a preset first!", Time = 3, Icon = "alert-circle"})
                end
            end
        })

        MusicPresetsSection:AddButton('Misc_68', {
            Text = "Stop All Music",
            Tooltip = "Stop all sounds playing in the game",
            Func = function()
                pcall(function()
                    if currentMusicSound and currentMusicSound.Parent then
                        currentMusicSound:Stop()
                    end
                    musicEnabled = false
                    selectedAudioData = nil
                    selectedPreset = nil
                    local function stopAllSounds(parent)
                        for _, child in parent:GetDescendants() do
                            if child:IsA("Sound") then
                                pcall(function() child:Stop() end)
                            end
                        end
                    end
                    stopAllSounds(game:GetService("Workspace"))
                    stopAllSounds(SoundService)
                end)
                Library:Notify({Title = "Music Presets", Description = "All music stopped!", Time = 3, Icon = "volume-x"})
            end
        })

        -- === BACKGROUND MUSIC SYSTEM (Game Audio Scanner) ===
    local BackgroundMusicSection = MiscTab:AddGroupbox({ Side = "Right", Name = "Background Music", Description = "Background audio", IconName = "music" })

        -- Function to extract audio ID
        local function extractAudioId(soundIdString)
            if not soundIdString or soundIdString == "" then return nil end
            local id = string.match(soundIdString, "rbxassetid://(%d+)")
            if id then return tonumber(id) end
            id = string.match(soundIdString, "^(%d+)$")
            if id then return tonumber(id) end
            return nil
        end

        -- Play music
        local function playMusic(audioData)
            if not audioData then return end
            pcall(function()
                local sound = getMusicSound()
                sound.SoundId = "rbxassetid://" .. audioData.id
                sound.Volume = musicVolume
                sound:Play()
                selectedAudioData = audioData
                Library:Notify({Title = "Background Music", Description = "Playing: " .. audioData.name, Time = 2, Icon = "music"})
            end)
        end

        -- Stop music
        local function stopMusic()
            if currentMusicSound and currentMusicSound.Parent then
                currentMusicSound:Stop()
            end
        end

        -- Update volume
        local function updateVolume(volume)
            musicVolume = volume
            if currentMusicSound and currentMusicSound.Parent then
                currentMusicSound.Volume = volume
            end
        end

        -- Cleanup
        local function cleanupMusic()
            stopMusic()
            if currentMusicSound and currentMusicSound.Parent then
                currentMusicSound:Destroy()
                currentMusicSound = nil
            end
        end

        -- Custom ID input
        local customAudioId = ""

            BackgroundMusicSection:AddLabel({
                Text = "Custom Audio ID" .. "\n" .. "Enter any Roblox audio asset ID to play it directly",
                DoesWrap = true,
                Size = 14,
            })

        BackgroundMusicSection:AddInput('Misc_71', {
            Text = "Audio ID",
            Tooltip = "Paste a Roblox audio asset ID (numbers only)",
            Placeholder = "e.g. 1836635087",
            Callback = function(text)
                customAudioId = text:match("^%s*(.-)%s*$") -- trim whitespace
            end
        })

        BackgroundMusicSection:AddButton('Misc_72', {
            Text = "Play Custom ID",
            Tooltip = "Play the audio ID entered above",
            Func = function()
                local id = customAudioId:match("rbxassetid://(%d+)") or customAudioId:match("^(%d+)$")
                if id and id ~= "" then
                    pcall(function()
                        local sound = getMusicSound()
                        sound.SoundId = "rbxassetid://" .. id
                        sound.Volume = musicVolume
                        sound:Play()
                        selectedAudioData = {name = "Custom ID: " .. id, id = tonumber(id)}
                        musicEnabled = true
                        Library:Notify({Title = "Background Music", Description = "Playing Custom ID: " .. id, Time = 3, Icon = "music"})
                    end)
                else
                    Library:Notify({Title = "Background Music", Description = "Enter a valid audio ID first!", Time = 3, Icon = "alert-circle"})
                end
            end
        })

        -- Enable toggle
        BackgroundMusicSection:AddToggle('BGMusic_Enable', {
            Text = "Enable Background Music",
            Tooltip = "Play selected background music",
            Default = false,
            Callback = function(state)
                musicEnabled = state
                if state then
                    if selectedAudioData then
                        playMusic(selectedAudioData)
                    end
                else
                    stopMusic()
                    Library:Notify({Title = "Background Music", Description = "Stopped", Time = 2, Icon = "music"})
                end
            end
        })

        -- Volume
        BackgroundMusicSection:AddSlider('BGMusic_Volume', {
            Text = "Volume",
            Tooltip = "Adjust volume (0-100%)",
            Rounding = 1,
            Min = 0,
            Max = 100,
            Default = 50,
            Callback = function(value)
                updateVolume(value / 100)
            end
        })

        -- Pause/Resume
        BackgroundMusicSection:AddButton('Misc_73', {
            Text = "Pause",
            Tooltip = "Pause music",
            Func = function()
                if currentMusicSound and currentMusicSound.Parent then
                    currentMusicSound:Pause()
                    Library:Notify({Title = "Background Music", Description = "Paused", Time = 2, Icon = "pause"})
                end
            end
        })

        BackgroundMusicSection:AddButton('Misc_74', {
            Text = "Resume",
            Tooltip = "Resume music",
            Func = function()
                if currentMusicSound and currentMusicSound.Parent then
                    currentMusicSound:Resume()
                    Library:Notify({Title = "Background Music", Description = "Resumed", Time = 2, Icon = "play"})
                end
            end
        })

        BackgroundMusicSection:AddButton('Misc_75', {
            Text = "Copy Audio ID",
            Tooltip = "Copy the current audio ID to clipboard",
            Func = function()
                if selectedAudioData and selectedAudioData.id then
                    setclipboard(tostring(selectedAudioData.id))
                    Library:Notify({Title = "Background Music", Description = "Copied ID: " .. tostring(selectedAudioData.id), Time = 3, Icon = "clipboard"})
                elseif currentMusicSound and currentMusicSound.Parent and currentMusicSound.SoundId ~= "" then
                    local id = extractAudioId(currentMusicSound.SoundId)
                    if id then
                        setclipboard(tostring(id))
                        Library:Notify({Title = "Background Music", Description = "Copied ID: " .. tostring(id), Time = 3, Icon = "clipboard"})
                    else
                        Library:Notify({Title = "Background Music", Description = "No audio ID found!", Time = 3, Icon = "alert-circle"})
                    end
                else
                    Library:Notify({Title = "Background Music", Description = "No audio selected!", Time = 3, Icon = "alert-circle"})
                end
            end
        })

        -- Cleanup
        game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
            cleanupMusic()
        end)

        end -- end Music scope
        do -- Streamer scope (split to stay under 200 local registers)
    -- ===== STREAMER MODE =====
    local playerOriginalNames = setmetatable({}, {__mode="k"})
    local playerAnonNames = setmetatable({}, {__mode="k"})
    local streamerModeConnections = {}
    local streamerPlayerConnections = {} -- [player] = { charConn = ... }
    local anonymousNamePool = {
        "Player", "Gamer", "Soldier", "Warrior", "Fighter", "Guardian", "Knight", "Scout",
        "Hunter", "Ranger", "Trooper", "Captain", "Sergeant", "Private", "Recruit", "Veteran",
        "Hero", "Champion", "Legend", "Rookie", "Streamer", "Viewer", "Subscriber", "Chatter",
        "Anonymous", "Mystery", "Unknown", "Hidden", "Secret", "Shadow", "Ghost", "Phantom",
        "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel",
        "RedTeam", "BlueTeam", "GreenTeam", "YellowTeam", "OrangeTeam", "PurpleTeam"
    }

    local function generateRandomName()
        local baseName = anonymousNamePool[math.random(1, #anonymousNamePool)]
        local suffix = math.random(1000, 9999)
        return baseName .. suffix
    end

    local function getAnonymousName(player)
        -- 1. Check if we already have an anonymous name for this player
        local anonName = playerAnonNames[player]

        -- 2. If we don't have one yet, generate it and store it directly
        if not anonName then
            anonName = generateRandomName()

            playerOriginalNames[player] = player.DisplayName or player.Name
            playerAnonNames[player] = anonName
        end

        -- 3. Return the name (Super fast direct lookup!)
        return anonName
    end

    local function applyStreamerModeToPlayer(player)
        if not streamerModeEnabled then return end
        if not player or not player.Character then return end

        local anonymousName = getAnonymousName(player)

        -- PERF: already anonymized (periodic refresh) - nothing to do
        local currentHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if currentHum and currentHum.DisplayName == anonymousName then
            return
        end

        -- Find and modify all name displays on the character
        pcall(function()
            local char = player.Character

            -- Look for Humanoid and modify DisplayName (visual only, doesn't affect actual name)
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                pcall(function()
                    humanoid.DisplayName = anonymousName
                end)
            end

            -- Look for any BillboardGui with name labels
            for _, gui in char:GetDescendants() do
                if gui:IsA("BillboardGui") then
                    for _, label in gui:GetDescendants() do
                        if label:IsA("TextLabel") or label:IsA("TextButton") then
                            -- Check if label contains the player's name
                            local text = label.Text or ""
                            if text:find(player.Name) or text:find(player.DisplayName or "") then
                                label.Text = text:gsub(player.Name, anonymousName):gsub(player.DisplayName or player.Name, anonymousName)
                            end
                        end
                    end
                end
            end
        end)
    end

    local function restorePlayerName(player)
        if not player or not player.Character then return end

        local data = playerOriginalNames[player]
        if not data then return end

        pcall(function()
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                pcall(function()
                    humanoid.DisplayName = data.original
                end)
            end
        end)
    end

    local function applyStreamerModeToAllPlayers()
        for _, player in Players:GetPlayers() do
            applyStreamerModeToPlayer(player)
        end
    end


    local function setupStreamerModeConnections()
        -- Clean up existing connections
        for _, conn in streamerModeConnections do
            pcall(function() conn:Disconnect() end)
        end
        streamerModeConnections = {}

        for player, conns in streamerPlayerConnections do
            for _, conn in conns do
                pcall(function() conn:Disconnect() end)
            end
        end
        streamerPlayerConnections = {}

        if not streamerModeEnabled then return end

        local function setupPlayerStreamerConn(player)
            if streamerPlayerConnections[player] then return end
            local conns = {}
            local charConn = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                applyStreamerModeToPlayer(player)
            end)
            table.insert(conns, charConn)
            streamerPlayerConnections[player] = conns
        end

        -- Apply to new players
        table.insert(streamerModeConnections, Players.PlayerAdded:Connect(function(player)
            setupPlayerStreamerConn(player)
        end))

        -- Clean caches and dynamic connections for players that leave so they don't leak
        table.insert(streamerModeConnections, Players.PlayerRemoving:Connect(function(player)
            restorePlayerName(player)
            playerOriginalNames[player] = nil
            playerAnonNames[player] = nil
            local conns = streamerPlayerConnections[player]
            if conns then
                for _, conn in conns do
                    pcall(function() conn:Disconnect() end)
                end
                streamerPlayerConnections[player] = nil
            end
        end))

        -- Re-apply when characters respawn for existing players
        for _, player in Players:GetPlayers() do
            setupPlayerStreamerConn(player)
        end

        -- Periodic refresh to catch any reset names - PERF: increased to 10s (was 2s)
        local _streamerLastRefresh = 0
        table.insert(streamerModeConnections, RunService.Heartbeat:Connect(function()
            if not streamerModeEnabled then return end
            local now = time()
            if now - _streamerLastRefresh < 10 then return end
            _streamerLastRefresh = now
            applyStreamerModeToAllPlayers()
        end))
    end

    -- Auto-enable streamer mode if _G.StreamerMode is true
    if streamerModeEnabled then
        task.defer(function()
            task.wait(0.5) -- Wait for UI to initialize
            applyStreamerModeToAllPlayers()
            setupStreamerModeConnections()
            Library:Notify({
                Title = "Streamer Mode",
                Description = "Enabled - All player names are anonymous",
                Time = 3,
                Icon = "eye-off"
            })
        end)
    end

        end -- end Streamer scope
end -- end of Misc Tab

do -- // Maps Hacks Tab
    local MapsHacksTab = Tabs.Automation

    local BerezinaSection = MapsHacksTab:AddGroupbox({ Side = "Left", Name = "Berezina", Description = "Bridge objectives", IconName = "hammer", PopOut = true })
    do

    -- ===== BEREZINA MAP FEATURES =====

    -- Auto Repair Bridge
    local autoRepairBridgeEnabled = false
    local autoRepairBridgeConn = nil

    -- Cache bridge reference to avoid repeated FindFirstChild calls
    local cachedBridge = nil
    local lastBridgeCheck = 0
    local BRIDGE_CACHE_INTERVAL = 2 -- Re-check bridge existence every 2 seconds

    local function getNearestBridgeConstruct()
        local char = LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local rootPos = root.Position

        -- Cache bridge reference
        local now = time()
        if now - lastBridgeCheck > BRIDGE_CACHE_INTERVAL then
            lastBridgeCheck = now
            cachedBridge = nil
            pcall(function()
                local berezina = Workspace:FindFirstChild("Berezina")
                if berezina then
                    local modes = berezina:FindFirstChild("Modes")
                    if modes then
                        local holdout = modes:FindFirstChild("Holdout")
                        if holdout then
                            cachedBridge = holdout:FindFirstChild("Bridge")
                        end
                    end
                end
            end)
        end

        if not cachedBridge or not cachedBridge.Parent then
            cachedBridge = nil
            return nil
        end

        local nearest, dist = nil, mathHuge

        -- Use GetChildren once and iterate (avoids creating new table every call)
        local sections = cachedBridge:GetChildren()
        for i = 1, #sections do
            local section = sections[i]
            if not section then continue end

            -- Check Posts
            local posts = section:FindFirstChild("Posts")
            if posts then
                local postParts = posts:GetChildren()
                for j = 1, #postParts do
                    local part = postParts[j]
                    if part and part:IsA("BasePart") then
                        local health = part:FindFirstChild("ConstructHealth")
                        if health then
                            local d = (part.Position - rootPos).Magnitude
                            if d < dist then
                                dist = d
                                nearest = health
                            end
                        end
                    end
                end
            end

            -- Check Beam
            local beam = section:FindFirstChild("Beam")
            if beam then
                local beamHealth = beam:FindFirstChild("ConstructHealth")
                if beamHealth then
                    local d = (beam.Position - rootPos).Magnitude
                    if d < dist then
                        dist = d
                        nearest = beamHealth
                    end
                end
            end

            -- Check Joists
            local sectionChildren = section:GetChildren()
            for j = 1, #sectionChildren do
                local joists = sectionChildren[j]
                if joists and joists.Name == "Joists" then
                    local joistsHealth = joists:FindFirstChild("ConstructHealth")
                    if joistsHealth then
                        local d = (joists.Position - rootPos).Magnitude
                        if d < dist then
                            dist = d
                            nearest = joistsHealth
                        end
                    end
                end
            end
        end

        return nearest
    end

    local function doRepairBridge()
        local target = getNearestBridgeConstruct()
        if not target then return end

        local char = LocalPlayer.Character
        if not char then return end

        -- Method 1: Check workspace.Players folder (where remotes actually are)
        local hammerRemote = nil
        local wsPlayers = Workspace:FindFirstChild("Players")
        if wsPlayers then
            local playerFolder = wsPlayers:FindFirstChild(LocalPlayer.Name)
            if playerFolder then
                local hammerFolder = playerFolder:FindFirstChild("Hammer")
                    or playerFolder:FindFirstChild("Claw Hammer")
                if hammerFolder and hammerFolder:FindFirstChild("RemoteEvent") then
                    hammerRemote = hammerFolder.RemoteEvent
                end
            end
        end

        -- Method 2: Find hammer in backpack or character
        if not hammerRemote then
            local hammer = LocalPlayer.Backpack:FindFirstChild("Hammer")
                or LocalPlayer.Backpack:FindFirstChild("Claw Hammer")
                or char:FindFirstChild("Hammer")
                or char:FindFirstChild("Claw Hammer")

            if hammer and hammer:FindFirstChild("RemoteEvent") then
                hammerRemote = hammer.RemoteEvent
            end
        end

        if not hammerRemote then return end

        pcall(function()
            hammerRemote:FireServer("Repair", target)
        end)
    end

    local autoRepairBridgeTicker = 0
    local AutoRepairBridgeToggle = BerezinaSection:AddToggle('Berezina_AutoRepairBridge', {
        Text = "Auto Repair Bridge",
        Flag = "Berezina_AutoRepairBridge",
        Description = "Automatically repairs the bridge.",
        Default = false,
        Callback = function(state)
            autoRepairBridgeEnabled = state
            if state then
                if autoRepairBridgeConn then autoRepairBridgeConn:Disconnect() end
                autoRepairBridgeTicker = 0
                autoRepairBridgeConn = RunService.Heartbeat:Connect(function(dt)
                    if not autoRepairBridgeEnabled then return end
                    -- Throttle to once every 0.2 seconds for performance
                    autoRepairBridgeTicker = autoRepairBridgeTicker + (dt or 0)
                    if autoRepairBridgeTicker < 0.2 then return end
                    autoRepairBridgeTicker = 0
                    doRepairBridge()
                end)
                Library:Notify({
                    Title = "Auto Repair Bridge",
                    Description = "Enabled",
                    Time = 3,
                    Icon = "hammer"
                })
            else
                if autoRepairBridgeConn then
                    autoRepairBridgeConn:Disconnect()
                    autoRepairBridgeConn = nil
                end
            end
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.AutoRepairBridge = AutoRepairBridgeToggle

    -- Auto Grab Log (finds nearest log)
    local autoGrabLogEnabled = false
    local autoGrabLogThread = nil
    local AUTO_GRAB_LOG_MAX_DISTANCE = 7 -- Only fire if within 7 studs

    -- Helper: Find nearest log interact remote (returns remote and distance)
    local function findNearestLogInteract()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, mathHuge end
        local root = char.HumanoidRootPart

        local holdout = Workspace:FindFirstChild("Berezina")
            and Workspace.Berezina:FindFirstChild("Modes")
            and Workspace.Berezina.Modes:FindFirstChild("Holdout")

        if not holdout then return nil, mathHuge end

        local nearest, nearestDist = nil, mathHuge

        -- Search for all Log folders in Holdout
        for _, child in pairs(holdout:GetChildren()) do
            if child.Name:find("Log") then
                -- Check for Log model inside
                local logModel = child:FindFirstChild("Log")
                if logModel then
                    local interact = logModel:FindFirstChild("Interact")
                    if interact and interact:IsA("RemoteEvent") then
                        -- Get position of log
                        local logPart = logModel:FindFirstChildWhichIsA("BasePart")
                        if logPart then
                            local dist = (logPart.Position - root.Position).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearest = interact
                            end
                        else
                            -- No part found, just use this one
                            nearest = nearest or interact
                        end
                    end
                end
                -- Also check if child itself has Interact
                local directInteract = child:FindFirstChild("Interact")
                if directInteract and directInteract:IsA("RemoteEvent") then
                    local logPart = child:FindFirstChildWhichIsA("BasePart")
                    if logPart then
                        local dist = (logPart.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = directInteract
                        end
                    end
                end
            end
        end

        return nearest, nearestDist
    end

    local AutoGrabLogToggle = BerezinaSection:AddToggle('Berezina_AutoGrabLog', {
        Text = "Auto Grab Log",
        Flag = "Berezina_AutoGrabLog",
        Description = "Automatically grabs the nearest log.",
        Default = false,
        Callback = function(state)
            autoGrabLogEnabled = state
            if state then
                if autoGrabLogThread then pcall(function() task.cancel(autoGrabLogThread) end) end
                autoGrabLogThread = task.spawn(function()
                    while autoGrabLogEnabled do
                        local ok = pcall(function()
                            local logInteract, dist = findNearestLogInteract()
                            -- Only fire if within 7 studs
                            if logInteract and logInteract.Parent and dist <= AUTO_GRAB_LOG_MAX_DISTANCE then
                                logInteract:FireServer()
                            end
                        end)
                        task.wait(0.05) -- Faster loop for quicker pickup
                    end
                end)
                Library:Notify({
                    Title = "Auto Grab Log",
                    Description = "Enabled - Grabs nearest log.",
                    Time = 3,
                    Icon = "package"
                })
            else
                if autoGrabLogThread then
                    pcall(function() task.cancel(autoGrabLogThread) end)
                    autoGrabLogThread = nil
                end
            end
        end
    })
    _G.ArreyToggleElements.AutoGrabLog = AutoGrabLogToggle

    -- Auto Place Log (FIXED - no more memory leak from GetDescendants)
    local autoPlaceLogEnabled = false
    local autoPlaceLogThread = nil
    local cachedPlaceLogPrompts = {} -- Simple table, cleared on disable
    local lastPromptScan = 0
    local PROMPT_SCAN_INTERVAL = 3 -- Re-scan every 3 seconds (was 2)
    local cachedBerezinaRef = nil -- Cache Berezina reference

    -- Helper: Find nearest PlaceLog prompt (optimized - no GetDescendants spam)
    local function findNearestPlaceLogPrompt()
        local char = LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local rootPos = root.Position

        local now = time()

        -- Re-scan for prompts periodically (but much less aggressively)
        if now - lastPromptScan > PROMPT_SCAN_INTERVAL then
            lastPromptScan = now

            -- Clear old cache properly
            for i = #cachedPlaceLogPrompts, 1, -1 do
                cachedPlaceLogPrompts[i] = nil
            end

            -- Cache Berezina reference
            if not cachedBerezinaRef or not cachedBerezinaRef.Parent then
                cachedBerezinaRef = Workspace:FindFirstChild("Berezina")
            end

            -- Only scan if Berezina exists
            if cachedBerezinaRef then
                local modes = cachedBerezinaRef:FindFirstChild("Modes")
                if modes then
                    local holdout = modes:FindFirstChild("Holdout")
                    if holdout then
                        local bridge = holdout:FindFirstChild("Bridge")
                        if bridge then
                            -- Search only bridge sections for prompts
                            local sections = bridge:GetChildren()
                            for i = 1, #sections do
                                local section = sections[i]
                                if section then
                                    -- Check direct children and one level deep
                                    local children = section:GetChildren()
                                    for j = 1, #children do
                                        local child = children[j]
                                        if child then
                                            -- Check for prompt on this child
                                            local prompt = child:FindFirstChild("PlaceLogProximityPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                table.insert(cachedPlaceLogPrompts, prompt)
                                            end
                                            -- Check grandchildren
                                            local grandchildren = child:GetChildren()
                                            for k = 1, #grandchildren do
                                                local gc = grandchildren[k]
                                                if gc then
                                                    local gcPrompt = gc:FindFirstChild("PlaceLogProximityPrompt")
                                                    if gcPrompt and gcPrompt:IsA("ProximityPrompt") then
                                                        table.insert(cachedPlaceLogPrompts, gcPrompt)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Find nearest prompt from cache
        local nearest, nearestDist = nil, mathHuge
        local cacheSize = #cachedPlaceLogPrompts
        for i = cacheSize, 1, -1 do
            local prompt = cachedPlaceLogPrompts[i]
            if prompt and prompt.Parent then
                local promptPart = prompt:FindFirstAncestorWhichIsA("BasePart")
                if promptPart then
                    local dist = (promptPart.Position - rootPos).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = prompt
                    end
                end
            else
                -- Prompt was destroyed, remove from cache (swap-remove for speed)
                cachedPlaceLogPrompts[i] = cachedPlaceLogPrompts[cacheSize]
                cachedPlaceLogPrompts[cacheSize] = nil
                cacheSize = cacheSize - 1
            end
        end

        return nearest, nearestDist
    end

    local AUTO_PLACE_LOG_MAX_DISTANCE = 10 -- Only place if within 10 studs

    local AutoPlaceLogToggle = BerezinaSection:AddToggle('Berezina_AutoPlaceLog', {
        Text = "Auto Place Log",
        Flag = "Berezina_AutoPlaceLog",
        Description = "Automatically places logs on nearest bridge spot.",
        Default = false,
        Callback = function(state)
            autoPlaceLogEnabled = state
            if state then
                if autoPlaceLogThread then pcall(function() task.cancel(autoPlaceLogThread) end) end
                -- Reset cache on enable
                for i = #cachedPlaceLogPrompts, 1, -1 do cachedPlaceLogPrompts[i] = nil end
                lastPromptScan = 0
                cachedBerezinaRef = nil

                autoPlaceLogThread = task.spawn(function()
                    while autoPlaceLogEnabled do
                        local ok = pcall(function()
                            local prompt, dist = findNearestPlaceLogPrompt()
                            -- Only place if within range
                            if prompt and prompt.Parent and fireproximityprompt and dist <= AUTO_PLACE_LOG_MAX_DISTANCE then
                                fireproximityprompt(prompt)
                            end
                        end)
                        task.wait(0.08) -- Faster loop for quicker placement
                    end
                end)
                Library:Notify({
                    Title = "Auto Place Log",
                    Description = "Enabled - Places on nearest spot.",
                    Time = 3,
                    Icon = "box"
                })
            else
                if autoPlaceLogThread then
                    pcall(function() task.cancel(autoPlaceLogThread) end)
                    autoPlaceLogThread = nil
                end
                -- Properly clear cache
                for i = #cachedPlaceLogPrompts, 1, -1 do cachedPlaceLogPrompts[i] = nil end
                cachedBerezinaRef = nil
            end
        end
    })
    _G.ArreyToggleElements.AutoPlaceLog = AutoPlaceLogToggle

    local buildingCharConnection = nil
    local function setupBuildingCharConnection()
        if buildingCharConnection then
            pcall(function() buildingCharConnection:Disconnect() end)
        end
        buildingCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            -- Disable all features properly on respawn and clear all caches

            -- Clear bridge cache
            cachedBridge = nil
            lastBridgeCheck = 0

            if autoRepairBridgeEnabled then
            autoRepairBridgeEnabled = false
            if autoRepairBridgeConn then
                autoRepairBridgeConn:Disconnect()
                autoRepairBridgeConn = nil
            end
            if AutoRepairBridgeToggle then pcall(function() AutoRepairBridgeToggle:SetValue(false) end) end
        end
        if autoGrabLogEnabled then
            autoGrabLogEnabled = false
            if autoGrabLogThread then
                pcall(function() task.cancel(autoGrabLogThread) end)
                autoGrabLogThread = nil
            end
            if AutoGrabLogToggle then pcall(function() AutoGrabLogToggle:SetValue(false) end) end
        end
        if autoPlaceLogEnabled then
            autoPlaceLogEnabled = false
            if autoPlaceLogThread then
                pcall(function() task.cancel(autoPlaceLogThread) end)
                autoPlaceLogThread = nil
            end
            -- Properly clear all cached data
            for i = #cachedPlaceLogPrompts, 1, -1 do cachedPlaceLogPrompts[i] = nil end
            cachedBerezinaRef = nil
            lastPromptScan = 0
            if AutoPlaceLogToggle then pcall(function() AutoPlaceLogToggle:SetValue(false) end) end
        end
        end)
    end
    setupBuildingCharConnection()

    -- ===== END BEREZINA FEATURES =====
    end -- Berezina scope

    -- ===== VARDOHUS FORTRESS MAP FEATURES =====
    local VardohusSection = MapsHacksTab:AddGroupbox({ Side = "Right", Name = "Vardohus Fortress", Description = "Fortress ESP", IconName = "crosshair", PopOut = true })
    do

    local roundshotESPData = setmetatable({}, { __mode = "k" }) -- Weak keys - auto GC
    local swabESPData = setmetatable({}, { __mode = "k" }) -- Weak keys - auto GC
    local vardohusUpdateConn = nil

    -- Track items pending removal (grace period to prevent flicker like zombie ESP)
    local ESPPendingRemoval = setmetatable({}, { __mode = "k" }) -- [item] = time() when marked
    local ESP_REMOVAL_GRACE_PERIOD = 0.5 -- Same as zombie ESP

    -- Performance constants (copied from zombie ESP pattern)
    local VARDOHUS_MAX_DISTANCE = 250 -- Reduced to 250 studs for better performance
    local VARDOHUS_CREATION_MAX_DISTANCE = 250 -- Create ESP within 250 studs
    local VARDOHUS_SCAN_BATCH_SIZE = 20 -- Same as zombie ESP batch size
    local ChamsTransparency = 0.5

    -- Camera caching (same as zombie ESP)
    local cachedCameraPos = v3new(0, 0, 0)
    local lastCameraCacheTime = 0
    local CAMERA_CACHE_INTERVAL = 0.2 -- Update camera cache every 0.2 seconds (these are static items)

    -- Colors
    local ROUNDSHOT_COLOR = c3rgb(255, 100, 100) -- Red for 12 lb. Roundshots
    local SWAB_COLOR = c3rgb(255, 255, 0) -- Yellow for swab

    -- Enabled state
    local roundshotESPEnabled = false
    local swabESPEnabled = false

    -- Cache Vardohus reference
    local cachedVardohusRef = nil
    local lastVardohusScan = 0
    local VARDOHUS_SCAN_INTERVAL = 3.0 -- Scan every 3 seconds (items are static, no need to scan fast)

    -- PERFORMANCE: Cache collected items to avoid GetDescendants() every scan
    local cachedRoundshots = {}
    local cachedSwabs = {}
    local lastItemCollectTime = 0
    local ITEM_COLLECT_INTERVAL = 5.0 -- Re-collect items every 5 seconds (they rarely change)

    -- Get adorned part efficiently (copied from zombie ESP GetAdorneePart)
    local function GetItemPart(item)
        if not item or not item:IsA("Model") then return nil end
        -- Check PrimaryPart first
        if item.PrimaryPart and item.PrimaryPart:IsA("BasePart") then return item.PrimaryPart end
        -- Use GetChildren instead of GetDescendants (much faster)
        local children = item:GetChildren()
        local _ipArr1 = children
        for _ipI1 = 1, #_ipArr1 do local p = _ipArr1[_ipI1]
            if p:IsA("BasePart") then
                return p
            end
        end
        -- Fallback: check first-level folders only
        local _ipArr2 = children
        for _ipI2 = 1, #_ipArr2 do local child = _ipArr2[_ipI2]
            if child:IsA("Folder") or child:IsA("Model") then
                local _ipArr3 = child:GetChildren()
                for _ipI3 = 1, #_ipArr3 do local p = _ipArr3[_ipI3]
                    if p:IsA("BasePart") then
                        return p
                    end
                end
            end
        end
        return nil
    end

    -- Create ESP visuals (copied zombie ESP CreateVisual pattern)
    local function createVardohusESP(item, espData, color, labelText)
        if not item or not item:IsA("Model") or espData[item] then return end

        local mainPart = GetItemPart(item)
        if not mainPart then return end


        local data = {}
        espData[item] = data
        data.maxDistance = VARDOHUS_MAX_DISTANCE
        local offset = v3new(0, 3, 0)

        -- CREATE HIGHLIGHT (same as zombie ESP)
        local hl = Instance.new("Highlight")
        hl.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("HL_" .. math.random(10000, 99999))
        hl.Adornee = item
        hl.FillColor = color
        hl.OutlineColor = c3rgb(255, 255, 255)
        hl.FillTransparency = ChamsTransparency
        hl.OutlineTransparency = 0
        hl.Parent = item
        data.highlight = hl

        -- CREATE BILLBOARD (same as zombie ESP)
        local bb = Instance.new("BillboardGui")
        bb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BB_" .. math.random(10000, 99999))
        bb.Adornee = mainPart
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Size = UDim2.new(0, 120, 0, 50)
        bb.StudsOffset = offset
        bb.MaxDistance = VARDOHUS_MAX_DISTANCE
        bb.Parent = item
        data.billboard = bb

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = c3rgb(30, 30, 30)
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 1
        frame.BorderColor3 = color
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        frame.Parent = bb

        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = v2new(0.5, 0)
        lbl.Position = UDim2.new(0.5, 0, 0.1, 0)
        lbl.Size = UDim2.new(0.9, 0, 0.5, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0.8
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = frame
        data.label = lbl

        local distLbl = Instance.new("TextLabel")
        distLbl.AnchorPoint = v2new(0.5, 1)
        distLbl.Position = UDim2.new(0.5, 0, 0.9, 0)
        distLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "0 studs"
        distLbl.TextColor3 = c3rgb(200, 200, 200)
        distLbl.TextScaled = true
        distLbl.Font = Enum.Font.Gotham
        distLbl.Parent = frame
        data.distLabel = distLbl

        -- PROTECT ESP from anti-cheat detection (same as zombie ESP)
        pcall(function()
            if _G.protectESP then
                if data.highlight then _G.protectESP(data.highlight) end
                if data.billboard then _G.protectESP(data.billboard) end
            end
        end)
    end

    -- Remove ESP (safe - destroys instances directly)
    local function removeVardohusESP(item, espData)
        local data = espData[item]
        if not data then return end
        -- Disable visuals FIRST so they disappear immediately even if Destroy fails
        if data.highlight then pcall(function() data.highlight.Enabled = false end) end
        if data.billboard then pcall(function() data.billboard.Enabled = false end) end
        -- Detach from game hierarchy before destroying
        if data.highlight then pcall(function() data.highlight.Parent = nil end) end
        if data.billboard then pcall(function() data.billboard.Parent = nil end) end
        -- Now destroy
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        data.highlight = nil
        data.billboard = nil
        data.label = nil
        data.distLabel = nil
        espData[item] = nil
        ESPPendingRemoval[item] = nil
    end

    -- Safe clear all ESP from a table (collect first to avoid modifying during iteration)
    local function clearESPData(espData)
        local toRemove = {}
        for item in pairs(espData) do
            table.insert(toRemove, item)
        end
        local _ipArr4 = toRemove
        for _ipI4 = 1, #_ipArr4 do local item = _ipArr4[_ipI4]
            removeVardohusESP(item, espData)
        end
    end

    local function CollectVardohusItems(forceRefresh)
        -- Cache Vardohus reference
        if not cachedVardohusRef or not cachedVardohusRef.Parent then
            cachedVardohusRef = Workspace:FindFirstChild("Vardohus Fortress")
        end
        if not cachedVardohusRef then return {}, {} end

        local now = time()
        -- Return cached results if still fresh (items are static, no need to rescan often)
        if not forceRefresh and (now - lastItemCollectTime) < ITEM_COLLECT_INTERVAL then
            return cachedRoundshots, cachedSwabs
        end
        lastItemCollectTime = now

        local roundshots = {}
        local swabs = {}

        -- Collect all descendants once (expensive operation, cached for ITEM_COLLECT_INTERVAL)
        local descendants = cachedVardohusRef:GetDescendants()
        local _ipArr5 = descendants
        for _ipI5 = 1, #_ipArr5 do local obj = _ipArr5[_ipI5]
            if obj:IsA("Model") then
                local name = obj.Name:lower()
                -- Check for 12 lb. Roundshots
                if name:find("12 lb") or name:find("roundshot") then
                    table.insert(roundshots, obj)
                -- Check for Swab
                elseif name:find("swab") then
                    table.insert(swabs, obj)
                end
            end
        end

        -- Cache the results
        cachedRoundshots = roundshots
        cachedSwabs = swabs

        return roundshots, swabs
    end

    -- Scan and create ESP (same pattern as zombie ESP ScanAll)
    local function ScanAllVardohus()
        local now = time()

        -- Throttle scanning (same as zombie ESP)
        if now - lastVardohusScan < VARDOHUS_SCAN_INTERVAL then
            return
        end
        lastVardohusScan = now

        local roundshots, swabs = CollectVardohusItems()

        -- Update camera cache (same as zombie ESP)
        if now - lastCameraCacheTime >= CAMERA_CACHE_INTERVAL then
            local cam = workspace.CurrentCamera
            cachedCameraPos = cam and cam.CFrame.Position or v3new(0, 0, 0)
            lastCameraCacheTime = now
        end

        -- Build item sets for fast lookups (same pattern as zombie ESP)
        local roundshotSet = {}
        local _ipArr6 = roundshots
        for _ipI6 = 1, #_ipArr6 do local r = _ipArr6[_ipI6]
            roundshotSet[r] = true
        end
        local swabSet = {}
        local _ipArr7 = swabs
        for _ipI7 = 1, #_ipArr7 do local s = _ipArr7[_ipI7]
            swabSet[s] = true
        end

        -- Process Roundshots ESP
        if roundshotESPEnabled then
            -- Safe remove: collect first, then remove
            local toRemove = {}
            for item in pairs(roundshotESPData) do
                if not roundshotSet[item] then
                    table.insert(toRemove, item)
                end
            end
            local _ipArr8 = toRemove
            for _ipI8 = 1, #_ipArr8 do local item = _ipArr8[_ipI8]
                removeVardohusESP(item, roundshotESPData)
            end

            -- Add ESP for new items (with batch limiting like zombie ESP)
            local created = 0
            local _ipArr9 = roundshots
            for _ipI9 = 1, #_ipArr9 do local item = _ipArr9[_ipI9]
                if created >= VARDOHUS_SCAN_BATCH_SIZE then break end
                -- Re-check flag here: the toggle may have flipped while we were iterating
                if not roundshotESPEnabled then clearESPData(roundshotESPData) break end
                if not roundshotESPData[item] then
                    local itemPart = GetItemPart(item)
                    if itemPart then
                        local dist = (cachedCameraPos - itemPart.Position).Magnitude
                        if dist <= VARDOHUS_CREATION_MAX_DISTANCE then
                            createVardohusESP(item, roundshotESPData, ROUNDSHOT_COLOR, "12 lb. Roundshots")
                            created = created + 1
                        end
                    end
                end
            end
        else
            clearESPData(roundshotESPData)
        end

        -- Process Swab ESP (same logic)
        if swabESPEnabled then
            local toRemove = {}
            for item in pairs(swabESPData) do
                if not swabSet[item] then
                    table.insert(toRemove, item)
                end
            end
            local _ipArr10 = toRemove
            for _ipI10 = 1, #_ipArr10 do local item = _ipArr10[_ipI10]
                removeVardohusESP(item, swabESPData)
            end

            local created = 0
            local _ipArr11 = swabs
            for _ipI11 = 1, #_ipArr11 do local item = _ipArr11[_ipI11]
                if created >= VARDOHUS_SCAN_BATCH_SIZE then break end
                -- Re-check flag here: the toggle may have flipped while we were iterating
                if not swabESPEnabled then clearESPData(swabESPData) break end
                if not swabESPData[item] then
                    local itemPart = GetItemPart(item)
                    if itemPart then
                        local dist = (cachedCameraPos - itemPart.Position).Magnitude
                        if dist <= VARDOHUS_CREATION_MAX_DISTANCE then
                            createVardohusESP(item, swabESPData, SWAB_COLOR, "Swab")
                            created = created + 1
                        end
                    end
                end
            end
        else
            clearESPData(swabESPData)
        end
    end

    local _vardohusLastUpdate = 0
    local VARDOHUS_UPDATE_INTERVAL = 0.25 -- 4fps is plenty for static item ESP (was 0.1)
    local function UpdateAllVardohus()
        local now = time()
        if now - _vardohusLastUpdate < VARDOHUS_UPDATE_INTERVAL then return end
        _vardohusLastUpdate = now

        local Camera = workspace.CurrentCamera
        if not Camera then return end
        local cameraPos = Camera.CFrame.Position

        local function updateTable(espData, enabled)
            local toRemove = {}
            for item, data in pairs(espData) do
                if not item or not item.Parent then
                    -- Grace period before removing
                    if not ESPPendingRemoval[item] then
                        ESPPendingRemoval[item] = now
                    elseif (now - ESPPendingRemoval[item]) >= ESP_REMOVAL_GRACE_PERIOD then
                        table.insert(toRemove, item)
                    end
                    if data.highlight then data.highlight.Enabled = false end
                    if data.billboard then data.billboard.Enabled = false end
                elseif not enabled then
                    -- ESP disabled  destroy immediately, don't just hide
                    table.insert(toRemove, item)
                else
                    if ESPPendingRemoval[item] then ESPPendingRemoval[item] = nil end

                    local adornee = data.billboard and data.billboard.Adornee
                    if not adornee or not adornee.Parent then
                        local newPart = GetItemPart(item)
                        if newPart then
                            if data.billboard then data.billboard.Adornee = newPart end
                            adornee = newPart
                        else
                            table.insert(toRemove, item)
                        end
                    end

                    if adornee then
                        local dist = (cameraPos - adornee.Position).Magnitude
                        local maxDist = data.maxDistance or VARDOHUS_MAX_DISTANCE
                        local visible = dist <= maxDist

                        if data.highlight then data.highlight.Enabled = visible end
                        if data.billboard then
                            data.billboard.Enabled = visible
                            if visible and data.distLabel then
                                data.distLabel.Text = mathFloor(dist) .. " studs"
                            end
                        end
                    end
                end
            end
            -- Remove dead / disabled items safely after iteration
            local _ipArr12 = toRemove
            for _ipI12 = 1, #_ipArr12 do local item = _ipArr12[_ipI12]
                removeVardohusESP(item, espData)
            end
        end

        updateTable(roundshotESPData, roundshotESPEnabled)
        updateTable(swabESPData, swabESPEnabled)
    end

    -- PERFORMANCE: Single shared scan loop (instead of per-toggle loops)
    local sharedScanThread = nil

    -- Start or stop the shared scan loop based on enabled state
    local function ensureSharedScanLoop()
        local anyEnabled = roundshotESPEnabled or swabESPEnabled

        if anyEnabled and not sharedScanThread then
            sharedScanThread = task.spawn(function()
                while roundshotESPEnabled or swabESPEnabled do
                    pcall(ScanAllVardohus)
                    task.wait(VARDOHUS_SCAN_INTERVAL)
                end
                sharedScanThread = nil
            end)
        end
        -- If nothing is enabled, the loop will exit naturally on next iteration
    end

    -- Force destroy all ESP instances in a table

    -- Brute-force scan Vardohus Fortress and remove ALL orphaned ESP visuals from items
    local function nukeAllVardohusESPVisuals()
        pcall(function()
            local fortress = Workspace:FindFirstChild("Vardohus Fortress")
            if not fortress then return end
            local _ipArr13 = fortress:GetDescendants()
            for _ipI13 = 1, #_ipArr13 do local desc = _ipArr13[_ipI13]
                if desc:IsA("Model") then
                    local name = desc.Name:lower()
                    if name:find("12 lb") or name:find("roundshot") or name:find("swab") then
                        local _ipArr14 = desc:GetChildren()
                        for _ipI14 = 1, #_ipArr14 do local child = _ipArr14[_ipI14]
                            if child:IsA("Highlight") or child:IsA("BillboardGui") then
                                pcall(function() child.Enabled = false end)
                                pcall(function() child.Parent = nil end)
                                pcall(function() child:Destroy() end)
                            end
                        end
                    end
                end
            end
        end)
    end

    -- 12 lb. Roundshots ESP Toggle
    local RoundshotESPToggle = VardohusSection:AddToggle('Vardohus_RoundshotESP', {
        Text = "12 lb. Roundshots ESP",
        Flag = "Vardohus_RoundshotESP",
        Description = "Shows red ESP for 12 lb. Roundshots (ammunition for cannon)",
        Default = false,
        Callback = function(state)
            roundshotESPEnabled = state
            if state then
                -- Start update connection (Heartbeat, not RenderStepped - less overhead)
                if not vardohusUpdateConn then
                    vardohusUpdateConn = RunService.Heartbeat:Connect(UpdateAllVardohus)
                end

                -- Start shared scan loop (one loop for both toggles)
                ensureSharedScanLoop()

                Library:Notify({
                    Title = "12 lb. Roundshots ESP",
                    Description = "Enabled - Red markers show ammunition.",
                    Time = 3,
                    Icon = "box"
                })
            else
                -- Force destroy all roundshot ESP (uses full removeVardohusESP path)
                clearESPData(roundshotESPData)
                -- Reset to fresh weak table to discard any stale weak references
                roundshotESPData = setmetatable({}, { __mode = "k" })
                -- Invalidate item cache so next enable does a fresh collect
                cachedRoundshots = {}
                lastItemCollectTime = 0

                -- Single deferred cleanup pass (not multiple expensive nukeAll calls)
                task.defer(function()
                    if not roundshotESPEnabled then
                        nukeAllVardohusESPVisuals()
                    end
                end)

                -- Stop update connection if swab also disabled
                if not swabESPEnabled then
                    if vardohusUpdateConn then
                        vardohusUpdateConn:Disconnect()
                        vardohusUpdateConn = nil
                    end
                    cachedVardohusRef = nil
                end
            end
        end
    })
    _G.ArreyToggleElements.RoundshotESP = RoundshotESPToggle

    -- Swab ESP Toggle
    local SwabESPToggle = VardohusSection:AddToggle('Vardohus_SwabESP', {
        Text = "Swab ESP (Yellow)",
        Flag = "Vardohus_SwabESP",
        Description = "Shows yellow ESP for Swab items.",
        Default = false,
        Callback = function(state)
            swabESPEnabled = state
            if state then
                -- Start update connection (Heartbeat, not RenderStepped - less overhead)
                if not vardohusUpdateConn then
                    vardohusUpdateConn = RunService.Heartbeat:Connect(UpdateAllVardohus)
                end

                -- Start shared scan loop (one loop for both toggles)
                ensureSharedScanLoop()

                Library:Notify({
                    Title = "Swab ESP",
                    Description = "Enabled - Yellow markers show swabs.",
                    Time = 3,
                    Icon = "droplet"
                })
            else
                -- Force destroy all swab ESP (uses full removeVardohusESP path)
                clearESPData(swabESPData)
                -- Reset to fresh weak table to discard any stale weak references
                swabESPData = setmetatable({}, { __mode = "k" })
                -- Invalidate item cache so next enable does a fresh collect
                cachedSwabs = {}
                lastItemCollectTime = 0

                -- Single deferred cleanup pass (not multiple expensive nukeAll calls)
                task.defer(function()
                    if not swabESPEnabled then
                        nukeAllVardohusESPVisuals()
                    end
                end)

                -- Stop update connection if roundshot also disabled
                if not roundshotESPEnabled then
                    if vardohusUpdateConn then
                        vardohusUpdateConn:Disconnect()
                        vardohusUpdateConn = nil
                    end
                    cachedVardohusRef = nil
                end
            end
        end
    })
    _G.ArreyToggleElements.SwabESP = SwabESPToggle

    local vardohusCharConnection = nil
    local function setupVardohusCharConnection()
        if vardohusCharConnection then
            pcall(function() vardohusCharConnection:Disconnect() end)
        end
        vardohusCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            roundshotESPEnabled = false
            swabESPEnabled = false

        -- Stop shared scan loop (it will exit naturally since both flags are false)
        if sharedScanThread then
            pcall(function() task.cancel(sharedScanThread) end)
            sharedScanThread = nil
        end

        clearESPData(roundshotESPData)
        clearESPData(swabESPData)
        roundshotESPData = setmetatable({}, { __mode = "k" })
        swabESPData = setmetatable({}, { __mode = "k" })

        -- Single cleanup pass (not multiple)
        nukeAllVardohusESPVisuals()

        if vardohusUpdateConn then
            vardohusUpdateConn:Disconnect()
            vardohusUpdateConn = nil
        end

        -- Invalidate all caches
        cachedVardohusRef = nil
        cachedRoundshots = {}
        cachedSwabs = {}
        lastItemCollectTime = 0
        lastVardohusScan = 0

        if RoundshotESPToggle then pcall(function() RoundshotESPToggle:SetValue(false) end) end
        if SwabESPToggle then pcall(function() SwabESPToggle:SetValue(false) end) end
        end)
    end
    setupVardohusCharConnection()

    -- ===== END VARDOHUS FORTRESS FEATURES =====
    end -- Vardohus scope

    -- ===== SAINT PETERSBURG MAP FEATURES =====
    local SaintPetersburgSection = MapsHacksTab:AddGroupbox({ Side = "Left", Name = "Saint Petersburg", Description = "Map supplies", IconName = "shopping-cart", PopOut = true })
    do

    local STPETE_ITEMS = {
        "LampLighter",
        "GrenadeBox",
        "BandageBox",
        "CanisterShot",
        "Roundshot",
    }

    local selectedSupply = "LampLighter"

    SaintPetersburgSection:AddDropdown('StPete_SupplyItem', {
        Text = "Supply Item",
        Flag = "StPete_SupplyItem",
        Description = "Select the item to purchase from Hobo's Shop even when he isn't even there.",
        Values = STPETE_ITEMS,
        Default = "LampLighter",
        Multi = false,
        Callback = function(selection)
            selectedSupply = tostring(selection or "LampLighter")
        end
    })

    SaintPetersburgSection:AddButton({
        Text = "Buy Supply",
        Func = function()
            if not selectedSupply or selectedSupply == "" then
                Library:Notify({
                    Title = "Saint Petersburg",
                    Description = "Select an item first!",
                    Time = 2,
                    Icon = "alert-circle"
                })
                return
            end
            local success, err = pcall(function()
                local Event = ReplicatedStorage.Remotes.HoldoutOrderShopEvent
                Event:FireServer("BuySupply", selectedSupply)
            end)
            if success then
                Library:Notify({
                    Title = "Saint Petersburg",
                    Description = "Purchased: " .. selectedSupply,
                    Time = 2,
                    Icon = "check"
                })
            else
                Library:Notify({
                    Title = "Saint Petersburg",
                    Description = "Purchase failed — wrong map?",
                    Time = 3,
                    Icon = "x"
                })
            end
        end
    })

    -- ===== CATACOMBES DE PARIS FEATURES =====
    end -- Saint Petersburg scope
    local CatacombesSection = MapsHacksTab:AddGroupbox({ Side = "Right", Name = "Catacombes De Paris", Description = "Key objectives", IconName = "key", PopOut = true })
    do

    local autoKeyEnabled = false
    local autoKeyWeEnabledKA = false
    local autoKeyWeEnabledAutoEquip = false
    local autoKeyZombieConn = nil
    local autoKeyAnchorPos = nil
    local RS = RunService

    local function cdpSpamTP(targetPos, duration)
        local conn
        local endTime = time() + (duration or 1)
        conn = RS.Heartbeat:Connect(function()
            if time() > endTime then
                if conn then pcall(function() conn:Disconnect() end) end
                return
            end
            local c = LocalPlayer.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rot = hrp.CFrame - hrp.CFrame.Position
                hrp.CFrame = cfNew(targetPos) * rot
            end
        end)
    end

    local function cdpFindKeyPrompt()
        local pk = workspace:FindFirstChild("Pickup")
        if pk and pk.Parent then
            local p = pk:FindFirstChildWhichIsA("ProximityPrompt")
            if p and p.Enabled then return p end
        end
        local _ipArr15 = workspace:GetDescendants()
        for _ipI15 = 1, #_ipArr15 do local p = _ipArr15[_ipI15]
            if p:IsA("ProximityPrompt") and p.Enabled then
                local at = string.lower(p.ActionText or "")
                if string.find(at, "take key") then return p end
            end
        end
        return nil
    end

    local function cdpFindZombies()
        -- Central cache instead of workspace:GetDescendants() (called per Heartbeat).
        local list = {}
        local cache = _G.CentralZombieCache
        local count = _G.CentralZombieCount or 0
        for i = 1, count do
            local m = cache[i]
            if m and m.Parent and m:IsA("Model") and m.Name == "m_Zombie" then
                list[#list + 1] = m
            end
        end
        return list
    end

    local function cdpNearestZombie()
        local anchor = autoKeyAnchorPos
        if not anchor then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end
            anchor = hrp.Position
        end
        local best, bd = nil, mathHuge
        local _ipArr17 = cdpFindZombies()
        for _ipI17 = 1, #_ipArr17 do local m = _ipArr17[_ipI17]
            local root = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("Head")
            if root then
                local d = (root.Position - anchor).Magnitude
                if d < bd then bd = d; best = m end
            end
        end
        return best
    end

    local function cdpStartPin()
        if autoKeyZombieConn then autoKeyZombieConn:Disconnect() end
        autoKeyZombieConn = RS.Heartbeat:Connect(function()
            if not autoKeyEnabled then return end
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if not h then return end
            local z = cdpNearestZombie()
            if not z then return end
            local zr = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso") or z:FindFirstChild("Head")
            if not zr then return end
            local toPlayer = h.Position - zr.Position
            if toPlayer.Magnitude < 0.1 then toPlayer = v3new(0, 0, 1) end
            toPlayer = toPlayer.Unit
            local target = zr.Position - toPlayer * 3
            h.CFrame = cfNew(target, zr.Position)
        end)
    end

    local function cdpStopAutoKey()
        autoKeyEnabled = false
        autoKeyAnchorPos = nil
        if autoKeyZombieConn then pcall(function() autoKeyZombieConn:Disconnect() end) autoKeyZombieConn = nil end
        if autoKeyWeEnabledKA then
            pcall(function() _G.ArreyToggleElements.KillAura:SetValue(false) end)
            autoKeyWeEnabledKA = false
        end
        if autoKeyWeEnabledAutoEquip then
            pcall(function() _G.ArreyToggleElements.AutoEquipMelee:SetValue(false) end)
            autoKeyWeEnabledAutoEquip = false
        end
    end

    CatacombesSection:AddButton({
        Text = "Auto get key objective",
        Func = function()
            if autoKeyEnabled then
                cdpStopAutoKey()
                Library:Notify({ Title = "Catacombes De Paris", Description = "Auto get key stopped.", Time = 2, Icon = "x" })
                return
            end

            if not workspace:FindFirstChild("Catacombes de Paris") then
                Library:Notify({ Title = "Error", Description = "Please make sure you are on the right objective or map.", Time = 4, Icon = "alert-circle" })
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                Library:Notify({ Title = "Error", Description = "Character not found. Try again.", Time = 3, Icon = "alert-circle" })
                return
            end

            local KEY_POS = v3new(-586, 13, -373)
            if (hrp.Position - KEY_POS).Magnitude > 400 then
                Library:Notify({ Title = "Error", Description = "Please make sure you are on the right objective or map.", Time = 4, Icon = "alert-circle" })
                return
            end

            if not KillAuraEnabled then
                pcall(function() _G.ArreyToggleElements.KillAura:SetValue(true) end)
                autoKeyWeEnabledKA = true
            end

            if not KillAura_AutoEquipMelee then
                pcall(function() _G.ArreyToggleElements.AutoEquipMelee:SetValue(true) end)
                autoKeyWeEnabledAutoEquip = true
            end

            autoKeyEnabled = true
            autoKeyAnchorPos = KEY_POS

            cdpSpamTP(KEY_POS, 1)
            task.wait(1.5)

            cdpStartPin()

            task.spawn(function()
                while autoKeyEnabled do
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    local keyTool = bp and bp:FindFirstChild("Key")
                    if keyTool then
                        if autoKeyZombieConn then pcall(function() autoKeyZombieConn:Disconnect() end) autoKeyZombieConn = nil end
                        pcall(function()
                            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum:EquipTool(keyTool) end
                        end)
                        local trigPos = v3new(-540.36, 20.13, -174.14)
                        cdpSpamTP(trigPos, 1)
                        local map = workspace:FindFirstChild("Catacombes de Paris")
                        local trig = map and map:FindFirstChild("KeyTrigger", true)
                        if trig then
                            cdpSpamTP(trig.Position, 1)
                            local kp = trig:FindFirstChildWhichIsA("ProximityPrompt")
                            if kp then
                                pcall(function() kp:InputHoldBegin() task.wait(0.1) kp:InputHoldEnd() end)
                            end
                        end
                        cdpStopAutoKey()
                        Library:Notify({ Title = "Catacombes De Paris", Description = "Key objective complete!", Time = 3, Icon = "check" })
                        return
                    end

                    local kp = cdpFindKeyPrompt()
                    if kp then
                        if autoKeyZombieConn then pcall(function() autoKeyZombieConn:Disconnect() end) autoKeyZombieConn = nil end
                        local parent = kp.Parent
                        local tgt = parent:IsA("Model") and parent:GetPivot().Position or parent.Position
                        cdpSpamTP(tgt, 0.6)
                        pcall(function() kp:InputHoldBegin() task.wait(0.1) kp:InputHoldEnd() end)
                    else
                        if not autoKeyZombieConn then cdpStartPin() end
                    end
                    task.wait(0.15)
                end
            end)

            Library:Notify({ Title = "Catacombes De Paris", Description = "Auto get key started.", Time = 2, Icon = "play" })
        end
    })

    -- ===== CATACOMBES: AUTO BREAK WALL =====
    local autoBreakWallEnabled = false
    local autoBreakWallConn = nil
    local autoBreakWallLast = 0
    local BREAK_POS = v3new(-624, 18, -260)

    local function cdpGetSledge()
        local c = LocalPlayer.Character
        local tool = c and c:FindFirstChild("Sledgehammer")
        if not tool then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            tool = bp and bp:FindFirstChild("Sledgehammer")
        end
        return tool
    end

    local function cdpBreakWall()
        local tool = cdpGetSledge()
        if not tool then return false end
        local remote = tool:FindFirstChild("RemoteEvent")
        if not remote then return false end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        remote:FireServer("Equip", hrp)
        remote:FireServer("PrepareSwing")
        remote:FireServer("Swing", "Side")
        local map = workspace:FindFirstChild("Catacombes de Paris")
        local obj = map and map:FindFirstChild("Modes") and map.Modes:FindFirstChild("Objective")
        local bw = obj and obj:FindFirstChild("brickwall")
        if bw then
            local kids = bw:GetChildren()
            if #kids > 0 then
                remote:FireServer("HitBreakable", kids, v3new(0.92962449789047, -0.14883053302765, -0.33711683750153))
            end
        end
        return true
    end

    CatacombesSection:AddToggle('AutoBreakWall', {
        Text = "Auto Break Wall",
        Default = false,
        Callback = function(v)
            autoBreakWallEnabled = v
            if autoBreakWallConn then pcall(function() autoBreakWallConn:Disconnect() end) autoBreakWallConn = nil end
            if v then
                autoBreakWallConn = RS.Heartbeat:Connect(function()
                    if not autoBreakWallEnabled then return end
                    if time() - autoBreakWallLast < 1.2 then return end
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    if (hrp.Position - BREAK_POS).Magnitude > 10 then return end
                    if not LocalPlayer.Character:FindFirstChild("Sledgehammer") then return end
                    autoBreakWallLast = time()
                    cdpBreakWall()
                end)
            end
        end
    })

    -- ===== CATACOMBES: HOLDOUT SPAWN KILL =====
    local holdoutEnabled = false
    local holdoutConn = nil
    local holdoutReturnConn = nil
    local holdoutOriginalPos = nil
    local holdoutWeEnabledKA = false
    local holdoutWeEnabledAutoEquip = false
    local HOLDOUT_POS = v3new(-360, 64, 63)

    CatacombesSection:AddToggle('SpawnKillZombiesHoldout', {
        Text = "Spawn kill zombies in hold out (last part)",
        Default = false,
        Callback = function(v)
            holdoutEnabled = v
            if holdoutConn then pcall(function() holdoutConn:Disconnect() end) holdoutConn = nil end
            if holdoutReturnConn then pcall(function() holdoutReturnConn:Disconnect() end) holdoutReturnConn = nil end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if v then
                if hrp then holdoutOriginalPos = hrp.Position end
                if not KillAuraEnabled then pcall(function() _G.KatchhiToggleElements.KillAura:SetValue(true) end) holdoutWeEnabledKA = true end
                if not KillAura_AutoEquipMelee then pcall(function() _G.ArreyToggleElements.AutoEquipMelee:SetValue(true) end) holdoutWeEnabledAutoEquip = true end
                holdoutConn = RS.Heartbeat:Connect(function()
                    if not holdoutEnabled then return end
                    local c = LocalPlayer.Character
                    local h = c and c:FindFirstChild("HumanoidRootPart")
                    if h then
                        local rot = h.CFrame - h.CFrame.Position
                        h.CFrame = cfNew(HOLDOUT_POS) * rot
                    end
                end)
            else
                if holdoutOriginalPos then
                    local endTime = time() + 1.5
                    holdoutReturnConn = RS.Heartbeat:Connect(function()
                        if time() > endTime then
                            if holdoutReturnConn then pcall(function() holdoutReturnConn:Disconnect() end) holdoutReturnConn = nil end
                            return
                        end
                        local c = LocalPlayer.Character
                        local h = c and c:FindFirstChild("HumanoidRootPart")
                        if h then
                            local rot = h.CFrame - h.CFrame.Position
                            h.CFrame = cfNew(holdoutOriginalPos) * rot
                        end
                    end)
                end
                if holdoutWeEnabledKA then pcall(function() _G.KatchhiToggleElements.KillAura:SetValue(false) end) holdoutWeEnabledKA = false end
                if holdoutWeEnabledAutoEquip then pcall(function() _G.KatchhiToggleElements.AutoEquipMelee:SetValue(false) end) holdoutWeEnabledAutoEquip = false end
            end
        end
    })

    -- ===== MOSS IRONWORKS OBJECTIVE FEATURES =====
    end -- Catacombes scope
    do
    local MossIronworksSection = MapsHacksTab:AddGroupbox({ Side = "Right", Name = "Moss Ironworks", Description = "Ironworks objectives", IconName = "hammer", PopOut = true })

    local mossObjectiveRunning = false

    local function mossSpamTP(targetPos, duration)
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local endTime = time() + (duration or 1.5)
        while time() < endTime do
            if not mossObjectiveRunning then break end
            h.CFrame = cfNew(targetPos)
            task.wait(0.01)
        end
    end

    local function mossTweenTo(targetPos, duration)
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local start = h.CFrame
        local t0 = time()
        local d = (duration or 0.45)
        while mossObjectiveRunning and time() - t0 < d do
            h.CFrame = start:Lerp(cfNew(targetPos), mathMin(1, (time() - t0) / d))
            task.wait(0.01)
        end
        -- Land right on target so we're actually in range to grab
        h.CFrame = cfNew(targetPos)
    end

    local function mossPromptPos(p)
        if not p then return nil end
        local holder = p.Parent
        if holder and holder:IsA("BasePart") then return holder.Position end
        if holder and holder:IsA("Attachment") then return holder.WorldPosition end
        return nil
    end

    -- TTL cache: full-workspace prompt scans are expensive; callers run per-Heartbeat.
    local _mossPromptCache = {}
    local _mossPromptCacheTime = 0
    local MOSS_PROMPT_CACHE_TTL = 0.5
    local function mossFindPrompt(sub, exact, skip)
        local now = time()
        local key = tostring(sub) .. "|" .. tostring(exact)
        local hit = _mossPromptCache[key]
        if hit and now - _mossPromptCacheTime < MOSS_PROMPT_CACHE_TTL then
            if hit.Parent and not (skip and skip[hit]) then
                return hit
            end
        end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        local myPos = h and h.Position or v3new(0, 0, 0)
        local best, bestDist = nil, mathHuge
        local _ipArr18 = workspace:GetDescendants()
        for _ipI18 = 1, #_ipArr18 do local obj = _ipArr18[_ipI18]
            if obj:IsA("ProximityPrompt") and obj.Enabled and (not skip or not skip[obj]) then
                local at = string.lower(obj.ActionText or "")
                local matches = exact and (at == sub) or (not exact and string.find(at, sub, 1, true) ~= nil)
                if matches then
                    local pos = mossPromptPos(obj)
                    if pos then
                        local d = (myPos - pos).Magnitude
                        if d < bestDist then bestDist = d; best = obj end
                    end
                end
            end
        end
        if best then
            _mossPromptCache[key] = best
            _mossPromptCacheTime = now
        end
        return best
    end

    local function mossFirePrompt(p)
        if not p then return end
        pcall(function()
            p:InputHoldBegin()
            task.wait(0.03)
            p:InputHoldEnd()
        end)
    end

    local mossSaved = nil
    local function mossSaveSettings()
        mossSaved = {
            autoLook = KillAuraAutoLook,
            autoEquip = KillAura_AutoEquipMelee,
            enabled = KillAuraEnabled,
            range = KillAuraRange,
            atkSpeed = KillAuraAttackSpeed,
            bomber = KillAura_SelectedZombieTypes and KillAura_SelectedZombieTypes["Bomber"],
            priEnabled = KillAura_PriorityEnabled,
            pri = {},
        }
        if KillAura_ZombiePriority then
            for k, v in pairs(KillAura_ZombiePriority) do
                mossSaved.pri[k] = v
            end
        end
    end

    local function mossRestoreSettings()
        if not mossSaved then return end
        local te = _G.ArreyToggleElements or {}
        if te.AutoLook and te.AutoLook.Value ~= mossSaved.autoLook then
            pcall(function() te.AutoLook:SetValue(mossSaved.autoLook) end)
        else
            KillAuraAutoLook = mossSaved.autoLook
        end
        if te.AutoEquipMelee and te.AutoEquipMelee.Value ~= mossSaved.autoEquip then
            pcall(function() te.AutoEquipMelee:SetValue(mossSaved.autoEquip) end)
        else
            KillAura_AutoEquipMelee = mossSaved.autoEquip
        end
        KillAuraRange = mossSaved.range
        KillAuraAttackSpeed = mossSaved.atkSpeed
        if KillAura_SelectedZombieTypes then
            KillAura_SelectedZombieTypes["Bomber"] = mossSaved.bomber
        end
        for k in KillAura_ZombiePriority do
            KillAura_ZombiePriority[k] = 0
        end
        for k, v in pairs(mossSaved.pri) do
            KillAura_ZombiePriority[k] = v
        end
        KillAura_PriorityEnabled = mossSaved.priEnabled
        if te.KillAura and te.KillAura.Value ~= mossSaved.enabled then
            pcall(function() te.KillAura:SetValue(mossSaved.enabled) end)
        else
            KillAuraEnabled = mossSaved.enabled
        end
        mossSaved = nil
    end

    local function mossEnableKillAura()
        mossSaveSettings()
        -- Auto look on (kills look behaviour while collecting)
        local te = _G.ArreyToggleElements or {}
        if te.AutoLook then
            pcall(function()
                if not te.AutoLook.Value then te.AutoLook:SetValue(true) end
            end)
        else
            KillAuraAutoLook = true
        end
        -- Auto equip melee on (dont touch if already on)
        local meleeEl = te.AutoEquipMelee
        if meleeEl then
            pcall(function()
                if not meleeEl.Value then meleeEl:SetValue(true) end
            end)
        else
            KillAura_AutoEquipMelee = true
        end
        -- Kill aura itself on last so the heartbeat refresher sees it
        local kaEl = te.KillAura
        if kaEl then
            pcall(function()
                if not kaEl.Value then kaEl:SetValue(true) end
            end)
        else
            KillAuraEnabled = true
        end
        -- Temporary settings
        KillAuraRange = 26
        KillAuraAttackSpeed = 0.05
        -- Never target bombers (their explosion kills us)
        if KillAura_SelectedZombieTypes then
            KillAura_SelectedZombieTypes["Bomber"] = false
        end
        -- Prioritise runners while on the objective
        if KillAura_ZombiePriority then
            for k in KillAura_ZombiePriority do
                KillAura_ZombiePriority[k] = 0
            end
            KillAura_ZombiePriority["Runner"] = 1
        end
        KillAura_PriorityEnabled = true
    end


    local function mossCollectKindling()
        mossEnableKillAura()
        local done = {}
        local retries = {}
        local totalGuard = 0
        while mossObjectiveRunning and totalGuard < 150 do
            totalGuard = totalGuard + 1
            local p = mossFindPrompt("grab", true, done)
            if not p then break end
            local pos = mossPromptPos(p)
            if pos then
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                local dist = h and (h.Position - pos).Magnitude or mathHuge
                if dist > 10 then
                    mossSpamTP(pos, 0.5)
                elseif dist < 5 then
                    -- Close enough: glide in instead of teleporting so we end up closer
                    mossTweenTo(pos)
                end
                local pickedUp = false
                local t0 = time()
                while mossObjectiveRunning and time() - t0 < 4.0 do
                    if h and h.Parent then
                        local d = (h.Position - pos).Magnitude
                        if d > 4 then
                            h.CFrame = cfNew(pos)
                        end
                    end
                    mossFirePrompt(p)
                    task.wait(0.05)
                    if not p.Parent or not p.Enabled then pickedUp = true break end
                end
                if pickedUp then
                    done[p] = true
                else
                    retries[p] = (retries[p] or 0) + 1
                    if retries[p] >= 3 then
                        done[p] = true
                    end
                end
            else
                done[p] = true
            end
        end
        return 0
    end

    local function mossPourVisible()
        return (mossFindPrompt("pour") or mossFindPrompt("powder")) ~= nil
    end

    local function mossPlaceKindlings()
        local p = mossFindPrompt("place")
        if not p then return end
        local pos = mossPromptPos(p)
        if pos then mossSpamTP(pos, 1.5) end
        local guard = 0
        while mossObjectiveRunning and guard < 40 do
            guard = guard + 1
            if mossPourVisible() then break end
            local pp = mossFindPrompt("place")
            if not pp then break end
            mossFirePrompt(pp)
            task.wait(0.15)
        end
    end

    local MOSS_SPARK_POS = v3new(-181, 98, 149)

    local function mossPourPowder()
        local p = mossFindPrompt("pour") or mossFindPrompt("powder")
        if not p then return false end
        -- Go to the pour prompt first so we actually reach it to pour.
        local pos = mossPromptPos(p)
        if pos then mossSpamTP(pos, 1.5) end
        mossFirePrompt(p)
        task.wait(0.25)
        mossSpamTP(MOSS_SPARK_POS, 1.0)
        return true
    end

    local function mossFindNewTool()
        local lp = LocalPlayer
        local _ipArr19 = { "Tinder Pistol", "TinderPistol", "Tinder" }
        for _ipI19 = 1, #_ipArr19 do local n = _ipArr19[_ipI19]
            local t = lp.Character and lp.Character:FindFirstChild(n)
            if not t then t = lp.Backpack and lp.Backpack:FindFirstChild(n) end
            if t and t:IsA("Tool") then return t end
        end
        -- Fallback: any non-melee tool that is not the Hammer
        if lp.Character then
            local _ipArr20 = lp.Character:GetChildren()
            for _ipI20 = 1, #_ipArr20 do local c = _ipArr20[_ipI20]
                if c:IsA("Tool") and c.Name ~= "Axe" and c.Name ~= "Hammer" then return c end
            end
        end
        if lp.Backpack then
            local _ipArr21 = lp.Backpack:GetChildren()
            for _ipI21 = 1, #_ipArr21 do local c = _ipArr21[_ipI21]
                if c:IsA("Tool") and c.Name ~= "Axe" and c.Name ~= "Hammer" then return c end
            end
        end
        return nil
    end

    local function mossTakeTinderPistol()
        local p = mossFindPrompt("tinder")
        if not p then return false, "No Tinder Pistol prompt found" end
        local pos = mossPromptPos(p)
        -- Keep spam teleporting to the Tinder pistol until we actually get it
        local got = nil
        local t0 = time()
        while mossObjectiveRunning and time() - t0 < 6.0 do
            -- Re-approach the pistol if it (or we) moved, then grab it
            if pos then mossSpamTP(pos, 0.3) end
            mossFirePrompt(p)
            got = mossFindNewTool()
            if got then break end
            task.wait(0.15)
        end
        local char = LocalPlayer.Character
        if got and char and got.Parent ~= char then
            pcall(function() got.Parent = char end)
        end
        return got and true or false, got and "Tinder Pistol taken" or "Tinder Pistol did not appear"
    end

    local function mossBomberNearSpark()
        local zf = workspace:FindFirstChild("Zombies")
        if not zf then return false end
        local _ipArr22 = zf:GetDescendants()
        for _ipI22 = 1, #_ipArr22 do local m = _ipArr22[_ipI22]
            if m:IsA("Model") then
                local zt = nil
                pcall(function() zt = KillAura_getZombieType(m) end)
                if zt == "Bomber" then
                    local rp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")
                    if rp and rp:IsA("BasePart") and (rp.Position - MOSS_SPARK_POS).Magnitude <= 10 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function mossWaitForSpark(timeout)
        local t0 = time()
        while mossObjectiveRunning and time() - t0 < (timeout or 10) do
            local p = mossFindPrompt("spark")
            if p then
                local pos = mossPromptPos(p)
                -- Pause Kill Aura's auto-equip so it can't drop the Tinder pistol
                local autoEquipWas = KillAura_AutoEquipMelee
                KillAura_AutoEquipMelee = false
                local char = LocalPlayer.Character
                local pistol = mossFindNewTool()
                if pistol then
                    pcall(function()
                        if pistol.Parent ~= char then pistol.Parent = char end
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(pistol) end
                    end)
                    task.wait(0.2)
                end
                -- Now teleport to the spark prompt and fire it immediately
                if pos then mossSpamTP(pos, 1.5) end
                -- Spark vanished while holding the pistol (a teammate did it) - done
                if not p.Parent or not p.Enabled then
                    KillAura_AutoEquipMelee = autoEquipWas
                    return true
                end
                mossFirePrompt(p)
                KillAura_AutoEquipMelee = autoEquipWas
                task.spawn(function()
                    local holdT = time() + 3.0
                    while time() < holdT do
                        local c1 = LocalPlayer.Character
                        local h1 = c1 and c1:FindFirstChild("HumanoidRootPart")
                        if h1 then h1.CFrame = cfNew(MOSS_SPARK_POS) end
                        task.wait(0.05)
                    end
                end)
                return true
            end
            if mossBomberNearSpark() then
                task.wait(0.3)
            else
                mossSpamTP(MOSS_SPARK_POS, 0.8)
            end
            task.wait(0.1)
        end
        return false
    end

    MossIronworksSection:AddButton({
        Text = "Auto Kindling Objective",
        Func = function()
            if mossObjectiveRunning then
                mossObjectiveRunning = false
                Library:Notify({ Title = "Moss Ironworks", Description = "Auto objective stopped.", Time = 2, Icon = "x" })
                return
            end
            if not workspace:FindFirstChild("Moss Ironworks") then
                Library:Notify({ Title = "Error", Description = "Please make sure you are on the Moss Ironworks map.", Time = 4, Icon = "alert-circle" })
                return
            end
            local _pg = LocalPlayer:FindFirstChild("PlayerGui")
            local _ri = _pg and _pg:FindFirstChild("RoundInfo")
            local _o = _ri and _ri:FindFirstChild("Objective")
            local _objText = ""
            if _o then pcall(function() _objText = string.lower(_o.Text or "") end) end
            if not string.find(_objText, "find kindling", 1, true) then
                Library:Notify({ Title = "Moss Ironworks", Description = "Not on the kindling objective yet.", Time = 3, Icon = "alert-circle" })
                return
            end
            mossObjectiveRunning = true
            Library:Notify({ Title = "Moss Ironworks", Description = "Auto objective started.", Time = 2, Icon = "play" })
            -- Stop everything if we die mid-process so settings get reverted
            task.spawn(function()
                while mossObjectiveRunning do
                    task.wait(0.25)
                    local c = LocalPlayer.Character
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health <= 0 then
                        mossObjectiveRunning = false
                    end
                end
            end)
            task.spawn(function()
                local ok, err = pcall(function()
                    if not mossTakeTinderPistol() then
                        Library:Notify({ Title = "Moss Ironworks", Description = "No Tinder Pistol prompt found.", Time = 3, Icon = "alert-circle" })
                    else
                        mossCollectKindling()
                        mossPlaceKindlings()
                        if not mossPourPowder() then
                            Library:Notify({ Title = "Moss Ironworks", Description = "No pour powder prompt found.", Time = 3, Icon = "alert-circle" })
                        elseif not mossWaitForSpark(10) then
                            Library:Notify({ Title = "Moss Ironworks", Description = "No spark prompt appeared.", Time = 3, Icon = "alert-circle" })
                        end
                    end
                end)
                mossObjectiveRunning = false
                mossRestoreSettings()
                if not ok then
                    warn("Moss objective error: " .. tostring(err))
                    Library:Notify({ Title = "Moss Ironworks", Description = "Error: " .. tostring(err), Time = 4, Icon = "alert-circle" })
                end
            end)
        end
    })

    local CROWBAR_OBJECTIVE = "steal a crowbar and pry the logs off the door"
    local crowbarHighlightRunning = false
    local crowbarHighlights = {}

    local function mossClearCrowbarHighlights()
        local _ipArr23 = crowbarHighlights
        for _ipI23 = 1, #_ipArr23 do local h = _ipArr23[_ipI23]
            pcall(function()
                if h and h.Parent then h:Destroy() end
            end)
        end
        crowbarHighlights = {}
    end

    local function mossCrowbarObjectiveActive()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local ri = pg and pg:FindFirstChild("RoundInfo")
        local o = ri and ri:FindFirstChild("Objective")
        local t = ""
        if o then pcall(function() t = o.Text or "" end) end
        return string.lower(t):find(CROWBAR_OBJECTIVE) ~= nil
    end

    local function mossFindCrowbarModels()
        local found = {}
        -- Only look inside BoardedDoorObj (where the crowbar boxes live), not the whole map
        local map = workspace:FindFirstChild("Moss Ironworks")
        local modes = map and map:FindFirstChild("Modes")
        local obj = modes and modes:FindFirstChild("Objective")
        local bd = obj and obj:FindFirstChild("BoardedDoorObj")
        local boxes = bd and bd:FindFirstChild("CrowbarBoxes")
        local scope = boxes or bd or obj or map
        if not scope then return {} end
        local _ipArr24 = scope:GetDescendants()
        for _ipI24 = 1, #_ipArr24 do local c = _ipArr24[_ipI24]
            if c:IsA("ProximityPrompt") then
                local at = ""
                pcall(function() at = c.ActionText or "" end)
                if string.lower(at):find("crowbar") ~= nil then
                    local model = c:FindFirstAncestorOfClass("Model")
                    if model and not found[model] then
                        found[model] = true
                    end
                end
            end
        end
        local list = {}
        for m in pairs(found) do list[#list+1] = m end
        return list
    end

    local function mossHighlightCrowbarModel(m)
        local _ipArr25 = crowbarHighlights
        for _ipI25 = 1, #_ipArr25 do local h = _ipArr25[_ipI25]
            if h.Adornee == m and h.Parent then return end
        end
        local h = Instance.new("Highlight")
        h.Name = "CrowbarHL"
        h.Adornee = m
        h.FillColor = c3rgb(255, 30, 30)
        h.FillTransparency = 0.45
        h.OutlineColor = c3rgb(255, 220, 40)
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = m.Parent
        crowbarHighlights[#crowbarHighlights + 1] = h
    end

    local function mossSyncCrowbarHighlights(models)
        local keep = {}
        local _ipArr26 = models
        for _ipI26 = 1, #_ipArr26 do local m = _ipArr26[_ipI26] keep[m] = true end
        local alive = {}
        local _ipArr27 = crowbarHighlights
        for _ipI27 = 1, #_ipArr27 do local h = _ipArr27[_ipI27]
            local _sok = pcall(function()
            if h.Parent then
                if h.Adornee and keep[h.Adornee] then
                    alive[#alive + 1] = h
                else
                    pcall(function()
                        if h.Parent then h:Destroy() end
                    end)
                end
            end
            end)
            if not _sok then pcall(function() if h and h.Parent then h:Destroy() end end) end
        end
        crowbarHighlights = alive
    end

    local crowbarHighlightThread = nil
    local function mossStartCrowbarHighlight()
        if crowbarHighlightThread then return end
        crowbarHighlightRunning = true
        crowbarHighlightThread = task.spawn(function()
            while crowbarHighlightRunning do
                if mossCrowbarObjectiveActive() then
                    local models = mossFindCrowbarModels()
                    local _ipArr28 = models
                    for _ipI28 = 1, #_ipArr28 do local m = _ipArr28[_ipI28]
                        pcall(function() mossHighlightCrowbarModel(m) end)
                    end
                    mossSyncCrowbarHighlights(models)
                else
                    mossClearCrowbarHighlights()
                end
                task.wait(1.0)
            end
            mossClearCrowbarHighlights()
            crowbarHighlightThread = nil
        end)
    end

    local function mossStopCrowbarHighlight()
        crowbarHighlightRunning = false
        crowbarHighlightThread = nil
        mossClearCrowbarHighlights()
    end

    MossIronworksSection:AddToggle('Moss_HighlightCrowbar', {
        Text = "Highlight Crowbar Location",
        Default = false,
        Callback = function(v)
            if v then
                mossStartCrowbarHighlight()
            else
                mossStopCrowbarHighlight()
            end
        end,
    })

    local MOSS_LOGS_OBJECTIVE = "steal a crowbar and pry the logs off the door"
    local MOSS_DOOR_OBJECTIVE = "break down the locked door"
    local mossAutoBreakEnabled = false
    local mossAutoBreakConn = nil
    local mossBreakLast = 0

    local function mossObjectiveText()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local ri = pg and pg:FindFirstChild("RoundInfo")
        local o = ri and ri:FindFirstChild("Objective")
        local t = ""
        if o then pcall(function() t = o.Text or "" end) end
        return string.lower(t)
    end

    local function mossObjFolder()
        local map = workspace:FindFirstChild("Moss Ironworks")
        local modes = map and map:FindFirstChild("Modes")
        return modes and modes:FindFirstChild("Objective")
    end

    local function mossBreakDoor()
        local obj = mossObjFolder()
        local bd = obj and obj:FindFirstChild("BoardedDoorObj")
        local hd = bd and bd:FindFirstChild("HouseDoor")
        return hd and hd:FindFirstChild("Door")
    end

    local function mossCollectLogParts()
        local obj = mossObjFolder()
        local bd = obj and obj:FindFirstChild("BoardedDoorObj")
        local logs = bd and bd:FindFirstChild("Logs")
        local res = {}
        if logs then
            local _ipArr29 = logs:GetChildren()
            for _ipI29 = 1, #_ipArr29 do local j = _ipArr29[_ipI29]
                local pp = j:IsA("Model") and j.PrimaryPart
                if pp and pp:IsA("BasePart") and pp.Anchored then
                    local hp = 0
                    pcall(function() hp = pp:GetAttribute("Health") or 0 end)
                    if hp > 0 then res[#res + 1] = pp end
                end
            end
        end
        return res
    end

    local function mossCollectDoorParts()
        local door = mossBreakDoor()
        local res = {}
        if door then
            local _ipArr30 = door:GetChildren()
            for _ipI30 = 1, #_ipArr30 do local c = _ipArr30[_ipI30]
                if c:IsA("BasePart") and c.Anchored then
                    res[#res + 1] = c
                end
            end
        end
        return res
    end

    local function mossFindCrowbar()
        local char = LocalPlayer.Character
        local crow = char and char:FindFirstChild("Crowbar")
        if not crow then local bp = LocalPlayer:FindFirstChildOfClass("Backpack") if bp then crow = bp:FindFirstChild("Crowbar") end end
        return crow
    end

    local function mossBreakCycle(mode, part)
        local crow = mossFindCrowbar()
        local char = LocalPlayer.Character
        if not crow or not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        if (hrp.Position - part.Position).Magnitude > 14 then return false end
        if crow.Parent ~= char then
            pcall(function() crow.Parent = char end)
        end
        local remote = crow:FindFirstChild("RemoteEvent")
        if not remote then return false end
        -- Mirror the game's melee swing: prepare, swing, then report the hit
        pcall(function() remote:FireServer("Equip", hrp) end)
        pcall(function() remote:FireServer("PrepareSwing") end)
        pcall(function() remote:FireServer("Swing", "Over") end)
        if mode == "logs" then
            local dir = (part.Position - hrp.Position).Unit
            pcall(function() remote:FireServer("HitBreakable", { part }, dir) end)
        else
            local normal = (hrp.Position - part.Position).Unit
            pcall(function() remote:FireServer("HitCon", part, part.Position, normal) end)
        end
        return true
    end

    MossIronworksSection:AddToggle('Moss_AutoBreakLogs', {
        Text = "Auto Break Logs",
        Default = false,
        Callback = function(v)
            mossAutoBreakEnabled = v
            if mossAutoBreakConn then
                pcall(function() mossAutoBreakConn:Disconnect() end)
                mossAutoBreakConn = nil
            end
            if not v then return end
            mossAutoBreakConn = RunService.Heartbeat:Connect(function()
                if not mossAutoBreakEnabled then return end
                if time() - mossBreakLast < 0.05 then return end
                -- Pick a phase from the current objective, then do nothing on other objectives
                local t = mossObjectiveText()
                local mode = nil
                if string.find(t, MOSS_LOGS_OBJECTIVE, 1, true) then
                    mode = "logs"
                elseif string.find(t, MOSS_DOOR_OBJECTIVE, 1, true) then
                    mode = "door"
                end
                if not mode then return end
                local parts = (mode == "logs") and mossCollectLogParts() or mossCollectDoorParts()
                -- Logs gone / door down: objective is done, stop swinging
                if #parts == 0 then return end
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local best, bestDist = nil, mathHuge
                local _ipArr31 = parts
                for _ipI31 = 1, #_ipArr31 do local p = _ipArr31[_ipI31]
                    local d = (hrp.Position - p.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = p
                    end
                end
                mossBreakLast = time()
                mossBreakCycle(mode, best)
            end)
        end,
    })

    local MOSS_PUSH_OBJECTIVE = "push the sled"
    local mossAutoPushEnabled = false
    local mossAutoPushConn = nil
    local mossAutoPushJumpConn = nil

    local function mossFindPushBlock()
        local map = workspace:FindFirstChild("Moss Ironworks")
        local modes = map and map:FindFirstChild("Modes")
        local obj = modes and modes:FindFirstChild("Objective")
        local sled = obj and obj:FindFirstChild("SledObj")
        local cannon = sled and sled:FindFirstChild("SledCannon")
        return cannon and cannon:FindFirstChild("PushBlock")
    end

    local function mossBypassPushAFK()
        local ok, ctrl = pcall(function()
            return require(game.ReplicatedStorage.Client.Modules.PieceControlManager.PushBlockController)
        end)
        if not ok or type(ctrl) ~= "table" or ctrl.__mossAFKBypassed then return end
        local _pushUpdate = function(self, dt)
            if self and not self.destroying then
                self.nonPushTime = 0
                if self.humanoid then
                    self.humanoid.AutoRotate = true
                end
                if self.animations then
                    local a = self.animations
                    local _ipArr32 = { "Pushing", "ToIdle", "Idle" }
                    for _ipI32 = 1, #_ipArr32 do local k = _ipArr32[_ipI32]
                        local anim = a[k]
                        if anim then
                            pcall(function()
                                if anim.IsPlaying then anim:Stop(0) end
                            end)
                        end
                    end
                end
            end
        end
        pcall(function() ctrl.Update = _pushUpdate end)
        pcall(function() ctrl.__mossAFKBypassed = true end)
    end

    MossIronworksSection:AddToggle('Moss_AutoPushSled', {
        Text = "Auto Push Sled",
        Default = false,
        Callback = function(v)
            mossAutoPushEnabled = v
            if mossAutoPushConn then
                pcall(function() mossAutoPushConn:Disconnect() end)
                mossAutoPushConn = nil
            end
            if mossAutoPushJumpConn then
                pcall(function() mossAutoPushJumpConn:Disconnect() end)
                mossAutoPushJumpConn = nil
            end
            if not v then return end
            mossBypassPushAFK()
            mossAutoPushJumpConn = UserInputService.JumpRequest:Connect(function()
                if not mossAutoPushEnabled then return end
                mossAutoPushEnabled = false
                if mossAutoPushConn then
                    pcall(function() mossAutoPushConn:Disconnect() end)
                    mossAutoPushConn = nil
                end
                if mossAutoPushJumpConn then
                    pcall(function() mossAutoPushJumpConn:Disconnect() end)
                    mossAutoPushJumpConn = nil
                end
            end)
            mossAutoPushConn = RunService.Heartbeat:Connect(function()
                mossBypassPushAFK()
                if not mossAutoPushEnabled then return end
                if not string.find(mossObjectiveText(), MOSS_PUSH_OBJECTIVE, 1, true) then return end
                local block = mossFindPushBlock()
                if not block then return end
                -- Keep firing "Push true" each frame (credits progress per tick)
                local remote = block:FindFirstChild("RemoteEvent")
                if remote then
                    pcall(function() remote:FireServer("Push", true) end)
                end
            end)
        end,
    })

    end -- Moss Ironworks scope

    -- ===== END SAINT PETERSBURG FEATURES =====
end

task.wait(0.1) -- Delay to prevent lag
do -- // PVP Tab
    local PVPTab = Tabs.PVP

    local PVPSection = PVPTab:AddGroupbox({ Side = "Left", Name = "Player Combat", Description = "Player combat", IconName = "crosshair", PopOut = false })

    -- ===== PVP FEATURES =====

    -- Shared PVP Settings (used by both Melee and Bayonet)
    local PVP_RANGE = 15
    local PVP_DELAY = 0.05
    local PVP_MULTI_TARGET = 3

    -- PVP Kill Aura (Melee)
    local pvpMeleeEnabled = false
    local pvpAutoEquipEnabled = true -- Default to true for better UX
    local pvpMeleeConn = nil

    local function getMeleeWeapon()
        local char = LocalPlayer.Character
        if not char then return nil end

        -- Check equipped
        local _ipArr33 = char:GetChildren()
        for _ipI33 = 1, #_ipArr33 do local tool = _ipArr33[_ipI33]
            if tool:IsA("Tool") and tool:FindFirstChild("MeleeBase") then
                return tool
            end
        end

        -- Check backpack
        local _ipArr34 = LocalPlayer.Backpack:GetChildren()
        for _ipI34 = 1, #_ipArr34 do local tool = _ipArr34[_ipI34]
            if tool:IsA("Tool") and tool:FindFirstChild("MeleeBase") then
                return tool
            end
        end

        return nil
    end


    local function isSameTeam(targetPlayer)
        if not LocalPlayer.Team or not targetPlayer.Team then
            return false
        end
        return LocalPlayer.Team == targetPlayer.Team
    end

    local function attackPlayerMelee(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        if isSameTeam(targetPlayer) then return end

        local weapon = getMeleeWeapon()
        if not weapon then return end

        local char = LocalPlayer.Character
        if not char then return end

        -- PERF FIX: Wrapped in task.spawn so task.wait() does NOT stall the heartbeat thread
        task.spawn(function()
            -- Auto-equip if enabled and weapon is in backpack
            if pvpAutoEquipEnabled and weapon.Parent ~= char then
                weapon.Parent = char
                task.wait(0.1) -- Wait for tool to be ready
            end

            -- If still not equipped (auto-equip off or failed), don't attack
            if weapon.Parent ~= char then return end

            local remoteEvent = weapon:FindFirstChild("RemoteEvent")
            if not remoteEvent then return end

            pcall(function()
                remoteEvent:FireServer("PrepareSwing")
                remoteEvent:FireServer("Swing", "Side")
                local head = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head")
                if head then
                    remoteEvent:FireServer("HitPlayer", targetPlayer.Character:FindFirstChild("Humanoid"), head.Position)
                end
            end)
        end)
    end

    -- Pre-allocated buffers for getNearbyEnemyPlayers (reused each tick, no GC)
    local _pvpTargetsBuf = {}
    local _pvpDistsBuf = {}
    local _pvpResultBuf = {}

    -- Get sorted list of nearby enemy players
    local function getNearbyEnemyPlayers(range, maxTargets)
        local char = LocalPlayer.Character
        if not char then return _pvpResultBuf end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return _pvpResultBuf end

        -- Clear buffers without allocating new tables
        local tCount = 0
        for i = #_pvpTargetsBuf, 1, -1 do _pvpTargetsBuf[i] = nil end
        for i = #_pvpDistsBuf, 1, -1 do _pvpDistsBuf[i] = nil end
        for i = #_pvpResultBuf, 1, -1 do _pvpResultBuf[i] = nil end

        local _ipArr35 = Players:GetPlayers()
        for _ipI35 = 1, #_ipArr35 do local targetPlayer = _ipArr35[_ipI35]
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and not isSameTeam(targetPlayer) then
                    local dist = (targetRoot.Position - myRoot.Position).Magnitude
                    if dist <= range then
                        tCount = tCount + 1
                        _pvpTargetsBuf[tCount] = targetPlayer
                        _pvpDistsBuf[tCount] = dist
                    end
                end
            end
        end

        -- Sort by distance using parallel arrays (insertion sort - fast for small N)
        if tCount > 1 then
            for i = 2, tCount do
                local tp, td = _pvpTargetsBuf[i], _pvpDistsBuf[i]
                local j = i - 1
                while j >= 1 and _pvpDistsBuf[j] > td do
                    _pvpTargetsBuf[j+1] = _pvpTargetsBuf[j]
                    _pvpDistsBuf[j+1] = _pvpDistsBuf[j]
                    j = j - 1
                end
                _pvpTargetsBuf[j+1] = tp
                _pvpDistsBuf[j+1] = td
            end
        end

        -- Return up to maxTargets
        local rCount = mathMin(tCount, maxTargets)
        for i = 1, rCount do
            _pvpResultBuf[i] = _pvpTargetsBuf[i]
        end
        return _pvpResultBuf
    end

    local pvpMeleeLastAttack = 0
    local function pvpMeleeUpdate()
        if not pvpMeleeEnabled then return end

        if time() - pvpMeleeLastAttack < PVP_DELAY then return end

        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        pvpMeleeLastAttack = time()

        local targets = getNearbyEnemyPlayers(PVP_RANGE, PVP_MULTI_TARGET)
        local _ipArr36 = targets
        for _ipI36 = 1, #_ipArr36 do local targetPlayer = _ipArr36[_ipI36]
            attackPlayerMelee(targetPlayer)
        end
    end

    local PVPMeleeToggle = PVPSection:AddToggle('PVP_MeleeKillAura', {
        Text = "PVP Kill Aura",
        Flag = "PVP_MeleeKillAura",
        Description = "Automatically attacks nearby enemy players with melee",
        Default = false,
        Callback = function(state)
            pvpMeleeEnabled = state
            if state then
                if pvpMeleeConn then pvpMeleeConn:Disconnect() end
                pvpMeleeConn = RunService.Heartbeat:Connect(pvpMeleeUpdate)
                Library:Notify({
                    Title = "PVP Kill Aura",
                    Description = "Enabled PVP Kill Aura.",
                    Time = 3,
                    Icon = "swords"
                })
            else
                if pvpMeleeConn then
                    pvpMeleeConn:Disconnect()
                    pvpMeleeConn = nil
                end
            end
        end
    })
    _G.ArreyToggleElements.PVPMelee = PVPMeleeToggle

    local PVPAutoEquipToggle = PVPSection:AddToggle('PVP_AutoEquip', {
        Text = "PVP Auto Equip",
        Flag = "PVP_AutoEquip",
        Description = "Automatically equips melee weapon from backpack for Kill Aura",
        Default = true,
        Callback = function(state)
            pvpAutoEquipEnabled = state
        end
    })
    _G.ArreyToggleElements.PVPAutoEquip = PVPAutoEquipToggle

    -- PVP Kill Aura (Bayonet)
    local pvpBayonetEnabled = false
    local pvpBayonetConn = nil

    local function getMusket()
        local char = LocalPlayer.Character
        if not char then return nil end

        local _ipArr37 = char:GetChildren()
        for _ipI37 = 1, #_ipArr37 do local tool = _ipArr37[_ipI37]
            if tool:IsA("Tool") and tool.Name == "Musket" then
                return tool
            end
        end

        local _ipArr38 = LocalPlayer.Backpack:GetChildren()
        for _ipI38 = 1, #_ipArr38 do local tool = _ipArr38[_ipI38]
            if tool:IsA("Tool") and tool.Name == "Musket" then
                return tool
            end
        end

        return nil
    end

    local function attackPlayerBayonet(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        if isSameTeam(targetPlayer) then return end

        local weapon = getMusket()
        if not weapon then return end

        local char = LocalPlayer.Character
        if not char then return end

        -- PERF FIX: Wrapped in task.spawn so task.wait() does NOT stall the heartbeat thread
        task.spawn(function()
            if weapon.Parent ~= char then
                weapon.Parent = char
                task.wait(0.1)
            end

            local remoteEvent = weapon:FindFirstChild("RemoteEvent")
            if not remoteEvent then return end

            pcall(function()
                remoteEvent:FireServer("ThrustBayonet")
                local head = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head")
                if head then
                    remoteEvent:FireServer("Bayonet_HitPlayer", targetPlayer.Character:FindFirstChild("Humanoid"), head.Position)
                end
            end)
        end)
    end

    local pvpBayonetLastAttack = 0
    local function pvpBayonetUpdate()
        if not pvpBayonetEnabled then return end

        if time() - pvpBayonetLastAttack < PVP_DELAY then return end

        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        pvpBayonetLastAttack = time()

        local targets = getNearbyEnemyPlayers(PVP_RANGE, PVP_MULTI_TARGET)
        local _ipArr39 = targets
        for _ipI39 = 1, #_ipArr39 do local targetPlayer = _ipArr39[_ipI39]
            attackPlayerBayonet(targetPlayer)
        end
    end

    local PVPBayonetToggle = PVPSection:AddToggle('PVP_BayonetKillAura', {
        Text = "PVP Kill Aura Bayonet",
        Flag = "PVP_BayonetKillAura",
        Description = "Automatically attacks nearby enemy players with bayonet",
        Default = false,
        Callback = function(state)
            pvpBayonetEnabled = state
            if state then
                if pvpBayonetConn then pvpBayonetConn:Disconnect() end
                pvpBayonetConn = RunService.Heartbeat:Connect(pvpBayonetUpdate)
                Library:Notify({
                    Title = "PVP Kill Aura Bayonet",
                    Description = "Enabled PVP Kill Aura Bayonet.",
                    Time = 3,
                    Icon = "swords"
                })
            else
                if pvpBayonetConn then
                    pvpBayonetConn:Disconnect()
                    pvpBayonetConn = nil
                end
            end
        end
    })
    _G.ArreyToggleElements.PVPBayonet = PVPBayonetToggle

    -- Shared PVP Settings Sliders
    PVPSection:AddSlider('PVP_Range', {
        Text = "PVP Range",
        Description = "Attack range for both Melee and Bayonet Kill Aura",
        Flag = "PVP_Range",
        Min = 5,
        Max = 30,
        Default = PVP_RANGE or 15,
        Rounding = 0,
        Callback = function(value)
            PVP_RANGE = value
        end
    })

    PVPSection:AddSlider('PVP_Delay', {
        Text = "PVP Delay",
        Description = "Delay between attacks",
        Flag = "PVP_Delay",
        Min = 0.01,
        Max = 0.5,
        Default = PVP_DELAY or 0.05,
        Rounding = 2,
        Callback = function(value)
            PVP_DELAY = value
        end
    })

    PVPSection:AddSlider('PVP_MultiTarget', {
        Text = "PVP Multi-Target",
        Description = "Number of players to attack per swing",
        Flag = "PVP_MultiTarget",
        Min = 1,
        Max = 10,
        Default = PVP_MULTI_TARGET,
        Rounding = 0,
        Callback = function(value)
            PVP_MULTI_TARGET = value
        end
    })

    -- ===== PVP WHITELIST SYSTEM =====
    local PVP_Whitelist = {} -- Array of player names to NOT attack
    local PVP_WhitelistDropdown = nil
    local isPVPWhitelistRefreshing = false

    -- Helper: Check if player is whitelisted
    local function isPVPWhitelisted(playerName)
        local _ipArr40 = PVP_Whitelist
        for _ipI40 = 1, #_ipArr40 do local name = _ipArr40[_ipI40]
            if name == playerName then return true end
        end
        return false
    end

    -- Helper: Get list of enemy players for dropdown (not same team)
    local function getPVPWhitelistPlayers()
        local names = {"None"}
        local _ipArr41 = Players:GetPlayers()
        for _ipI41 = 1, #_ipArr41 do local player = _ipArr41[_ipI41]
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end

    -- Helper: Refresh whitelist dropdown values
    local function refreshPVPWhitelistDropdown()
        if isPVPWhitelistRefreshing then return end
        isPVPWhitelistRefreshing = true
        pcall(function()
            if PVP_WhitelistDropdown and PVP_WhitelistDropdown.SetValues then
                PVP_WhitelistDropdown:SetValues(getPVPWhitelistPlayers())
            end
        end)
        isPVPWhitelistRefreshing = false
    end

    -- Listen for player joins/leaves to update dropdown
    Players.PlayerAdded:Connect(function()
        task.delay(0.5, refreshPVPWhitelistDropdown)
    end)
    Players.PlayerRemoving:Connect(function(player)
        -- Remove from whitelist if they leave
        local _ipArr42 = PVP_Whitelist
        for i = 1, #_ipArr42 do local name = _ipArr42[i]
            if name == player.Name then
                table.remove(PVP_Whitelist, i)
                break
            end
        end
        task.delay(0.1, refreshPVPWhitelistDropdown)
    end)

    -- PVP Whitelist Dropdown
    PVP_WhitelistDropdown = PVPSection:AddDropdown('PVP_Whitelist', {
        Text = "PVP Whitelist",
        Flag = "PVP_Whitelist",
        Description = "Players who won't be attacked by any PVP feature",
        Values = getPVPWhitelistPlayers(),
        Default = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            for name in pairs(selection or {}) do
                if name == "None" then
                    hasNone = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasNone then
                filtered = {}
            end
            PVP_Whitelist = filtered
        end
    })

    -- Update getNearbyEnemyPlayers to respect whitelist
    local function getNearbyEnemyPlayersFiltered(range, maxTargets)
        -- PERF: reuse the pre-allocated parallel buffers (no per-call allocations)
        local tCount = 0
        for i = #_pvpTargetsBuf, 1, -1 do _pvpTargetsBuf[i] = nil end
        for i = #_pvpDistsBuf, 1, -1 do _pvpDistsBuf[i] = nil end
        for i = #_pvpResultBuf, 1, -1 do _pvpResultBuf[i] = nil end

        local char = LocalPlayer.Character
        if not char then return _pvpResultBuf end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return _pvpResultBuf end

        local _ipArr43 = Players:GetPlayers()
        for _ipI43 = 1, #_ipArr43 do local targetPlayer = _ipArr43[_ipI43]
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                -- Skip whitelisted players
                if isPVPWhitelisted(targetPlayer.Name) then continue end

                local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and not isSameTeam(targetPlayer) then
                    local dist = (targetRoot.Position - myRoot.Position).Magnitude
                    if dist <= range then
                        tCount = tCount + 1
                        _pvpTargetsBuf[tCount] = targetPlayer
                        _pvpDistsBuf[tCount] = dist
                    end
                end
            end
        end

        -- Sort by distance (closest first) - insertion sort on parallel arrays
        if tCount > 1 then
            for i = 2, tCount do
                local tp, td = _pvpTargetsBuf[i], _pvpDistsBuf[i]
                local j = i - 1
                while j >= 1 and _pvpDistsBuf[j] > td do
                    _pvpTargetsBuf[j+1] = _pvpTargetsBuf[j]
                    _pvpDistsBuf[j+1] = _pvpDistsBuf[j]
                    j = j - 1
                end
                _pvpTargetsBuf[j+1] = tp
                _pvpDistsBuf[j+1] = td
            end
        end

        -- Return up to maxTargets
        local rCount = mathMin(tCount, maxTargets)
        for i = 1, rCount do
            _pvpResultBuf[i] = _pvpTargetsBuf[i]
        end
        return _pvpResultBuf
    end

    -- Override the original function to use filtered version
    getNearbyEnemyPlayers = getNearbyEnemyPlayersFiltered

    -- God Mode Teleport Section
    local GodModeSection = PVPTab:AddGroupbox({ Side = "Right", Name = "Teleport Combat", Description = "Teleport combat", IconName = "zap", PopOut = true })

    local godTeleportEnabled = false
    local godTeleportConn = nil
    local currentGodTarget = nil
    local lastTargetSwitch = 0
    local floatOffset = 0
    local _godLastTargetScan = 0
    local _godCachedTargets = {}

    local GOD_SAFE_DISTANCE = 3
    local GOD_FLOAT_HEIGHT = 3
    local GOD_FLOAT_SPEED = 15
    local GOD_COOLDOWN = 0.6

    local _validPVPTargetsBuf = {}

    local function getValidPVPTargets()
        -- Clear without allocating new table
        for i = #_validPVPTargetsBuf, 1, -1 do _validPVPTargetsBuf[i] = nil end
        local count = 0

        local _ipArr44 = Players:GetPlayers()
        for _ipI44 = 1, #_ipArr44 do local targetPlayer = _ipArr44[_ipI44]
            if targetPlayer ~= LocalPlayer and
               targetPlayer.Character and
               targetPlayer.Character:FindFirstChild("HumanoidRootPart") and
               (not LocalPlayer.Team or not targetPlayer.Team or targetPlayer.Team ~= LocalPlayer.Team) and
               not isPVPWhitelisted(targetPlayer.Name) then
                count = count + 1
                _validPVPTargetsBuf[count] = targetPlayer
            end
        end

        return _validPVPTargetsBuf
    end

    local function godTeleport()
        local char = LocalPlayer.Character
        if not char then return end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        -- Only rescan players every 0.5s - player list rarely changes mid-combat
        local now = time()
        if now - _godLastTargetScan >= 0.5 then
            _godLastTargetScan = now
            _godCachedTargets = getValidPVPTargets()
        end
        local targets = _godCachedTargets
        if #targets == 0 then
            return
        end

        if time() - lastTargetSwitch >= GOD_COOLDOWN then
            currentGodTarget = targets[math.random(1, #targets)]
            lastTargetSwitch = time()
            floatOffset = 0
        end

        if currentGodTarget and currentGodTarget.Character then
            local targetRoot = currentGodTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                floatOffset = math.sin(time() * GOD_FLOAT_SPEED) * GOD_FLOAT_HEIGHT

                local backVector = targetRoot.CFrame.LookVector * -GOD_SAFE_DISTANCE
                local floatVector = v3new(0, floatOffset, 0)
                myRoot.CFrame = cfNew(
                    targetRoot.Position + backVector + floatVector,
                    targetRoot.Position + floatVector
                )
            end
        end
    end

    local GodTeleportToggle = GodModeSection:AddToggle('PVP_GodTeleport', {
        Text = "Orbit Teleport",
        Flag = "PVP_GodTeleport",
        Description = "Orbits random enemy players and floats around them",
        Default = false,
        Callback = function(state)
            godTeleportEnabled = state
            if state then
                currentGodTarget = nil
                lastTargetSwitch = 0
                if godTeleportConn then godTeleportConn:Disconnect() end
                godTeleportConn = RunService.Heartbeat:Connect(function()
                    if godTeleportEnabled then
                        godTeleport()
                    end
                end)
                Library:Notify({
                    Title = "Orbit Teleport",
                    Description = "Enabled - Orbiting around enemies.",
                    Time = 3,
                    Icon = "zap"
                })
            else
                if godTeleportConn then
                    godTeleportConn:Disconnect()
                    godTeleportConn = nil
                end
                currentGodTarget = nil
            end
        end
    })
    _G.ArreyToggleElements.GodTeleport = GodTeleportToggle


    -- ===== END PVP FEATURES =====
end

task.wait(0.1) -- Delay to prevent lag
do -- // Keybinds and UI Tab
    local KeybindsTab = Tabs.Misc

    -- Mobile Button UI System
    local MobileButtons = {}
    local MobileButtonSettings = {
        Transparency = 0.1,
        Size = 52
    }

    local function disconnectConnections(list)
        if not list then return end
        for i = #list, 1, -1 do
            local conn = list[i]
            list[i] = nil
            if conn then
                pcall(function() conn:Disconnect() end)
            end
        end
    end

    local destroyMobileButton

    -- Color palette (clean, professional)
    local Colors = {
        Background = c3rgb(22, 22, 26),
        Surface = c3rgb(32, 32, 38),
        SurfaceLight = c3rgb(45, 45, 52),
        Primary = c3rgb(229, 57, 53), -- #E53935
        PrimaryDark = c3rgb(198, 40, 40),
        Text = c3rgb(255, 255, 255),
        TextMuted = c3rgb(140, 140, 150),
        Border = c3rgb(55, 55, 62),
        Success = c3rgb(76, 175, 80),
    }

    local function createMobileButton(name, toggleKey, getStateFunc)
        if MobileButtons[name] then
            destroyMobileButton(name)
        end

        local PlayerGui = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5))
        if not PlayerGui then return end

        -- Create ScreenGui with full screen coverage
        local screenGui = Instance.new("ScreenGui")
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.IgnoreGuiInset = true
        if _G.protectGUI then _G.protectGUI(screenGui) else screenGui.Parent = PlayerGui end -- Use stealth protection

        -- Create blur effect (hidden by default)
        local blur = Instance.new("BlurEffect")
        -- Use randomized name for anti-detection
        blur.Name = "Effect_" .. math.random(10000, 99999)
        blur.Size = 0
        blur.Parent = Lighting

        -- Dark overlay
        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundColor3 = c3rgb(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 99
        overlay.Parent = screenGui

        -- ===== SETTINGS PANEL (Clean, Professional Design) =====
        local settingsPanel = Instance.new("Frame")
        settingsPanel.Name = "SettingsPanel"
        settingsPanel.Size = UDim2.new(0, 260, 0, 195)
        settingsPanel.Position = UDim2.new(0.5, -130, 0.5, -97)
        settingsPanel.BackgroundColor3 = Colors.Background
        settingsPanel.BorderSizePixel = 0
        settingsPanel.Visible = false
        settingsPanel.ZIndex = 101
        settingsPanel.Parent = screenGui

        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = UDim.new(0, 12)
        panelCorner.Parent = settingsPanel

        -- Subtle shadow (using a slightly larger dark frame behind)
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 8, 1, 8)
        shadow.Position = UDim2.new(0, -4, 0, 2)
        shadow.BackgroundColor3 = c3rgb(0, 0, 0)
        shadow.BackgroundTransparency = 0.7
        shadow.BorderSizePixel = 0
        shadow.ZIndex = 100
        shadow.Parent = settingsPanel

        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 14)
        shadowCorner.Parent = shadow

        -- Header section
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 48)
        header.BackgroundColor3 = Colors.Surface
        header.BorderSizePixel = 0
        header.ZIndex = 102
        header.Parent = settingsPanel

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 12)
        headerCorner.Parent = header

        -- Fix bottom corners of header
        local headerBottom = Instance.new("Frame")
        headerBottom.Size = UDim2.new(1, 0, 0, 12)
        headerBottom.Position = UDim2.new(0, 0, 1, -12)
        headerBottom.BackgroundColor3 = Colors.Surface
        headerBottom.BorderSizePixel = 0
        headerBottom.ZIndex = 102
        headerBottom.Parent = header

        -- Red accent icon
        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.new(0, 28, 0, 28)
        iconBg.Position = UDim2.new(0, 14, 0.5, -14)
        iconBg.BackgroundColor3 = Colors.Primary
        iconBg.BorderSizePixel = 0
        iconBg.ZIndex = 103
        iconBg.Parent = header

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 6)
        iconCorner.Parent = iconBg

        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.Text = string.upper(string.sub(name, 1, 1))
        iconText.TextColor3 = Colors.Text
        iconText.TextSize = 14
        iconText.Font = Enum.Font.GothamBold
        iconText.ZIndex = 104
        iconText.Parent = iconBg

        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -100, 1, 0)
        title.Position = UDim2.new(0, 52, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = name
        title.TextColor3 = Colors.Text
        title.TextSize = 15
        title.Font = Enum.Font.GothamMedium
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = 103
        title.Parent = header

        -- Content area
        local content = Instance.new("Frame")
        content.Name = "Content"
        content.Size = UDim2.new(1, -32, 0, 90)
        content.Position = UDim2.new(0, 16, 0, 56)
        content.BackgroundTransparency = 1
        content.ZIndex = 102
        content.Parent = settingsPanel

        -- Transparency input section
        local transpContainer = Instance.new("Frame")
        transpContainer.Size = UDim2.new(0.5, -6, 1, 0)
        transpContainer.Position = UDim2.new(0, 0, 0, 0)
        transpContainer.BackgroundTransparency = 1
        transpContainer.ZIndex = 102
        transpContainer.Parent = content

        local transpLabel = Instance.new("TextLabel")
        transpLabel.Size = UDim2.new(1, 0, 0, 18)
        transpLabel.Position = UDim2.new(0, 0, 0, 0)
        transpLabel.BackgroundTransparency = 1
        transpLabel.Text = "Transparency"
        transpLabel.TextColor3 = Colors.TextMuted
        transpLabel.TextSize = 12
        transpLabel.Font = Enum.Font.Gotham
        transpLabel.TextXAlignment = Enum.TextXAlignment.Left
        transpLabel.ZIndex = 102
        transpLabel.Parent = transpContainer

        local transpInputBg = Instance.new("Frame")
        transpInputBg.Size = UDim2.new(1, 0, 0, 40)
        transpInputBg.Position = UDim2.new(0, 0, 0, 24)
        transpInputBg.BackgroundColor3 = Colors.Surface
        transpInputBg.BorderSizePixel = 0
        transpInputBg.ZIndex = 102
        transpInputBg.Parent = transpContainer

        local transpInputCorner = Instance.new("UICorner")
        transpInputCorner.CornerRadius = UDim.new(0, 8)
        transpInputCorner.Parent = transpInputBg

        local transpInputStroke = Instance.new("UIStroke")
        transpInputStroke.Color = Colors.Border
        transpInputStroke.Thickness = 1
        transpInputStroke.Parent = transpInputBg

        local transpInput = Instance.new("TextBox")
        transpInput.Size = UDim2.new(1, 0, 1, 0)
        transpInput.BackgroundTransparency = 1
        transpInput.Text = tostring(MobileButtonSettings.Transparency)
        transpInput.TextColor3 = Colors.Text
        transpInput.TextSize = 14
        transpInput.Font = Enum.Font.Gotham
        transpInput.PlaceholderText = "0 - 1"
        transpInput.PlaceholderColor3 = Colors.TextMuted
        transpInput.ZIndex = 103
        transpInput.Parent = transpInputBg

        -- Size input section
        local sizeContainer = Instance.new("Frame")
        sizeContainer.Size = UDim2.new(0.5, -6, 1, 0)
        sizeContainer.Position = UDim2.new(0.5, 6, 0, 0)
        sizeContainer.BackgroundTransparency = 1
        sizeContainer.ZIndex = 102
        sizeContainer.Parent = content

        local sizeLabel = Instance.new("TextLabel")
        sizeLabel.Size = UDim2.new(1, 0, 0, 18)
        sizeLabel.Position = UDim2.new(0, 0, 0, 0)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.Text = "Button Size"
        sizeLabel.TextColor3 = Colors.TextMuted
        sizeLabel.TextSize = 12
        sizeLabel.Font = Enum.Font.Gotham
        sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
        sizeLabel.ZIndex = 102
        sizeLabel.Parent = sizeContainer

        local sizeInputBg = Instance.new("Frame")
        sizeInputBg.Size = UDim2.new(1, 0, 0, 40)
        sizeInputBg.Position = UDim2.new(0, 0, 0, 24)
        sizeInputBg.BackgroundColor3 = Colors.Surface
        sizeInputBg.BorderSizePixel = 0
        sizeInputBg.ZIndex = 102
        sizeInputBg.Parent = sizeContainer

        local sizeInputCorner = Instance.new("UICorner")
        sizeInputCorner.CornerRadius = UDim.new(0, 8)
        sizeInputCorner.Parent = sizeInputBg

        local sizeInputStroke = Instance.new("UIStroke")
        sizeInputStroke.Color = Colors.Border
        sizeInputStroke.Thickness = 1
        sizeInputStroke.Parent = sizeInputBg

        local sizeInput = Instance.new("TextBox")
        sizeInput.Size = UDim2.new(1, 0, 1, 0)
        sizeInput.BackgroundTransparency = 1
        sizeInput.Text = tostring(MobileButtonSettings.Size)
        sizeInput.TextColor3 = Colors.Text
        sizeInput.TextSize = 14
        sizeInput.Font = Enum.Font.Gotham
        sizeInput.PlaceholderText = "30 - 100"
        sizeInput.PlaceholderColor3 = Colors.TextMuted
        sizeInput.ZIndex = 103
        sizeInput.Parent = sizeInputBg

        -- Apply & Close button
        local applyBtn = Instance.new("TextButton")
        applyBtn.Size = UDim2.new(1, -32, 0, 42)
        applyBtn.Position = UDim2.new(0, 16, 1, -58)
        applyBtn.BackgroundColor3 = Colors.Primary
        applyBtn.BorderSizePixel = 0
        applyBtn.Text = "Apply & Close"
        applyBtn.TextColor3 = Colors.Text
        applyBtn.TextSize = 14
        applyBtn.Font = Enum.Font.GothamMedium
        applyBtn.ZIndex = 102
        applyBtn.AutoButtonColor = false
        applyBtn.Parent = settingsPanel

        local applyCorner = Instance.new("UICorner")
        applyCorner.CornerRadius = UDim.new(0, 8)
        applyCorner.Parent = applyBtn

        -- ===== MOBILE BUTTON (Clean Design) =====
        local btnSize = MobileButtonSettings.Size
        local button = Instance.new("Frame")
        button.Name = "MobileButton"
        button.Size = UDim2.new(0, btnSize, 0, btnSize)
        button.Position = UDim2.new(0, 20, 0.5, -btnSize/2)
        button.BackgroundColor3 = Colors.Background
        button.BackgroundTransparency = MobileButtonSettings.Transparency
        button.BorderSizePixel = 0
        button.ZIndex = 100
        button.Active = true
        button.Parent = screenGui

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 12)
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Colors.Primary
        buttonStroke.Thickness = 2
        buttonStroke.Transparency = 0.4
        buttonStroke.Parent = button

        -- Button label
        local buttonLabel = Instance.new("TextLabel")
        buttonLabel.Name = "Label"
        buttonLabel.Size = UDim2.new(1, 0, 0.55, 0)
        buttonLabel.Position = UDim2.new(0, 0, 0.08, 0)
        buttonLabel.BackgroundTransparency = 1
        buttonLabel.Text = string.upper(string.sub(name, 1, 3))
        buttonLabel.TextColor3 = Colors.Text
        buttonLabel.TextSize = 14
        buttonLabel.Font = Enum.Font.GothamBold
        buttonLabel.TextScaled = true
        buttonLabel.ZIndex = 101
        buttonLabel.Parent = button

        -- State indicator bar
        local stateBar = Instance.new("Frame")
        stateBar.Name = "StateBar"
        stateBar.Size = UDim2.new(0.6, 0, 0, 3)
        stateBar.Position = UDim2.new(0.2, 0, 0.72, 0)
        stateBar.BackgroundColor3 = Colors.Primary
        stateBar.BorderSizePixel = 0
        stateBar.ZIndex = 101
        stateBar.Parent = button

        local stateBarCorner = Instance.new("UICorner")
        stateBarCorner.CornerRadius = UDim.new(1, 0)
        stateBarCorner.Parent = stateBar

        -- State text
        local stateText = Instance.new("TextLabel")
        stateText.Name = "StateText"
        stateText.Size = UDim2.new(1, 0, 0, 12)
        stateText.Position = UDim2.new(0, 0, 0.82, 0)
        stateText.BackgroundTransparency = 1
        stateText.Text = "OFF"
        stateText.TextColor3 = Colors.TextMuted
        stateText.TextSize = 9
        stateText.Font = Enum.Font.GothamMedium
        stateText.ZIndex = 101
        stateText.Parent = button

        -- Dragging variables
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        local holdStart = nil
        local isHolding = false
        local settingsOpen = false
        local originalPos = button.Position
        local buttonConnections = {}
        local activeInputStateConn = nil
        local lastIndicatorState = nil
        local mobileButtonData

        local function bindConnection(conn)
            buttonConnections[#buttonConnections + 1] = conn
            return conn
        end

        local function disconnectActiveInputStateConn()
            if activeInputStateConn then
                pcall(function() activeInputStateConn:Disconnect() end)
                activeInputStateConn = nil
                if mobileButtonData then
                    mobileButtonData.InputStateConn = nil
                end
            end
        end

        local function updateStateIndicator(force)
            local state = getStateFunc and getStateFunc() or false
            if not force and state == lastIndicatorState then
                return
            end
            lastIndicatorState = state
            local targetColor = state and Colors.Success or Colors.Primary
            local targetText = state and "ON" or "OFF"

            stateBar.BackgroundColor3 = targetColor
            buttonStroke.Color = targetColor
            stateText.Text = targetText
            stateText.TextColor3 = state and Colors.Success or Colors.TextMuted
        end

        local function updateButtonAppearance()
            local newSize = MobileButtonSettings.Size
            TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, newSize, 0, newSize),
                BackgroundTransparency = MobileButtonSettings.Transparency
            }):Play()
        end

        local function updateDrag(input)
            if not dragging or not startPos then return end
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end

        local function openSettings()
            if settingsOpen then return end
            settingsOpen = true
            originalPos = button.Position

            TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 20}):Play()
            TweenService:Create(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()

            local centerPos = UDim2.new(0.5, -MobileButtonSettings.Size/2, 0.5, -MobileButtonSettings.Size/2 - 110)
            TweenService:Create(button, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = centerPos}):Play()

            settingsPanel.Position = UDim2.new(0.5, -130, 0.55, 0)
            settingsPanel.Visible = true
            settingsPanel.BackgroundTransparency = 1
            TweenService:Create(settingsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -130, 0.5, 0),
                BackgroundTransparency = 0
            }):Play()
        end

        local function closeSettings()
            if not settingsOpen then return end
            settingsOpen = false

            TweenService:Create(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
            TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

            TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = originalPos,
                Size = UDim2.new(0, MobileButtonSettings.Size, 0, MobileButtonSettings.Size)
            }):Play()

            TweenService:Create(settingsPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
            task.delay(0.2, function()
                if not settingsOpen then settingsPanel.Visible = false end
            end)
        end

        local releaseHandled = false
        local hasMoved = false

        -- Performs the "release" action: either toggles the keybind (short tap) or just resets state.
        local function handleRelease()
            if releaseHandled then return end
            releaseHandled = true

            TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, MobileButtonSettings.Size, 0, MobileButtonSettings.Size)
            }):Play()

            local heldDuration = holdStart and (time() - holdStart) or 1
            if isHolding and not settingsOpen and heldDuration < 0.5 and not hasMoved then
                local toggle = _G.ArreyToggleElements and _G.ArreyToggleElements[toggleKey]
                if toggle and toggle.SetValue then
                    local currentState = getStateFunc and getStateFunc() or false
                    pcall(function() toggle:SetValue(not currentState) end)
                end
                task.delay(0.1, updateStateIndicator)
            end
            dragging = false
            isHolding = false
            disconnectActiveInputStateConn()
        end

        -- Input handlers
        bindConnection(button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if settingsOpen then return end
                -- Reset per-press state
                releaseHandled = false
                hasMoved = false
                dragging = true
                dragStart = input.Position
                startPos = button.Position
                holdStart = time()
                isHolding = true

                TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(0, MobileButtonSettings.Size * 0.94, 0, MobileButtonSettings.Size * 0.94)
                }):Play()

                task.spawn(function()
                    while isHolding and time() - holdStart < 0.5 do
                        task.wait(0.02)
                    end
                    if isHolding and time() - holdStart >= 0.5 and not settingsOpen and not hasMoved then
                        releaseHandled = true
                        isHolding = false
                        dragging = false
                        TweenService:Create(buttonStroke, TweenInfo.new(0.08), {Thickness = 3}):Play()
                        task.delay(0.08, function()
                            TweenService:Create(buttonStroke, TweenInfo.new(0.08), {Thickness = 2}):Play()
                        end)
                        openSettings()
                    end
                end)

                disconnectActiveInputStateConn()
                activeInputStateConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        handleRelease()
                    end
                end)
                if mobileButtonData then
                    mobileButtonData.InputStateConn = activeInputStateConn
                end
            end
        end))

        bindConnection(button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end))

        bindConnection(UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 8 then
                    hasMoved = true
                end
                updateDrag(input)
            end
        end))

        bindConnection(button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                handleRelease()
            end
        end))

        bindConnection(overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                closeSettings()
            end
        end))

        bindConnection(applyBtn.MouseButton1Click:Connect(closeSettings))
        bindConnection(applyBtn.TouchTap:Connect(closeSettings))

        -- Button hover/press effects
        bindConnection(applyBtn.MouseEnter:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.PrimaryDark}):Play()
        end))
        bindConnection(applyBtn.MouseLeave:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Primary}):Play()
        end))
        bindConnection(applyBtn.MouseButton1Down:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.05), {BackgroundColor3 = c3rgb(170, 35, 35)}):Play()
        end))
        bindConnection(applyBtn.MouseButton1Up:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Primary}):Play()
        end))

        -- Input focus effects
        bindConnection(transpInput.Focused:Connect(function()
            TweenService:Create(transpInputStroke, TweenInfo.new(0.1), {Color = Colors.Primary}):Play()
        end))
        bindConnection(transpInput.FocusLost:Connect(function()
            TweenService:Create(transpInputStroke, TweenInfo.new(0.1), {Color = Colors.Border}):Play()
            local val = tonumber(transpInput.Text)
            if val and val >= 0 and val <= 1 then
                MobileButtonSettings.Transparency = val
                updateButtonAppearance()
            else
                transpInput.Text = tostring(MobileButtonSettings.Transparency)
            end
        end))

        bindConnection(sizeInput.Focused:Connect(function()
            TweenService:Create(sizeInputStroke, TweenInfo.new(0.1), {Color = Colors.Primary}):Play()
        end))
        bindConnection(sizeInput.FocusLost:Connect(function()
            TweenService:Create(sizeInputStroke, TweenInfo.new(0.1), {Color = Colors.Border}):Play()
            local val = tonumber(sizeInput.Text)
            if val and val >= 30 and val <= 100 then
                MobileButtonSettings.Size = val
                updateButtonAppearance()
            else
                sizeInput.Text = tostring(MobileButtonSettings.Size)
            end
        end))

        -- Update state periodically
        local stateLoopThread = task.spawn(function()
            while button and button.Parent do
                updateStateIndicator()
                task.wait(0.5)
            end
        end)

        updateStateIndicator(true)

        mobileButtonData = {
            Frame = screenGui,
            Blur = blur,
            Connections = buttonConnections,
            InputStateConn = activeInputStateConn,
            StateLoopThread = stateLoopThread,
            Update = function()
                updateStateIndicator(true)
            end
        }
        MobileButtons[name] = mobileButtonData

        return MobileButtons[name]
    end

    destroyMobileButton = function(name)
        if MobileButtons[name] then
            local data = MobileButtons[name]
            pcall(function()
                if data.StateLoopThread then
                    task.cancel(data.StateLoopThread)
                end
            end)
            pcall(function()
                if data.InputStateConn then
                    data.InputStateConn:Disconnect()
                end
            end)
            disconnectConnections(data.Connections)
            pcall(function()
                if data.Blur then
                    data.Blur:Destroy()
                end
                if data.Frame then
                    data.Frame:Destroy()
                end
            end)
            MobileButtons[name] = nil
        end
    end

    local KeybindsSection = KeybindsTab:AddGroupbox({ Side = "Left", Name = "Mobile Buttons", Description = "Mobile controls", IconName = "key", PopOut = false })
    KeybindsSection:AddToggle('ButtonUI_HeadHit', {
        Text = "Head Hit Button UI",
        Flag = "ButtonUI_HeadHit",
        Description = "Create mobile button for Head Hit",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Head Hit", "HeadHit", function() return HeadHitEnabled end)
            else
                destroyMobileButton("Head Hit")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_AutoJump', {
        Text = "Auto Jump Button UI",
        Flag = "ButtonUI_AutoJump",
        Description = "Create mobile button for Auto Jump",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Auto Jump", "AutoJump", function()
                    return game:GetService("Players").LocalPlayer:GetAttribute("AutoJumpEnabled") or false
                end)
            else
                destroyMobileButton("Auto Jump")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_HitboxExpander', {
        Text = "Hitbox Expander Button UI",
        Flag = "ButtonUI_HitboxExpander",
        Description = "Create mobile button for Hitbox Expander",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Hitbox", "HitboxExpander", function() return hitboxEnabled end)
            else
                destroyMobileButton("Hitbox")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_ShoveHitbox', {
        Text = "Shove Hitbox Button UI",
        Flag = "ButtonUI_ShoveHitbox",
        Description = "Create mobile button for Shove Hitbox",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Shove HB", "ShoveHitbox", function() return ShoveHitboxExpanderEnabled end)
            else
                destroyMobileButton("Shove HB")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_AutoParrySapper', {
        Text = "Auto Parry Sapper Button UI",
        Flag = "ButtonUI_AutoParrySapper",
        Description = "Create mobile button for Auto Parry Sapper",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Parry", "AutoParrySapper", function() return AutoParrySapperMeleeEnabled end)
            else
                destroyMobileButton("Parry")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_KillAura', {
        Text = "Kill Aura Button UI",
        Flag = "ButtonUI_KillAura",
        Description = "Create mobile button for Kill Aura",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("KillAura", "KillAura", function() return KillAuraEnabled end)
            else
                destroyMobileButton("KillAura")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_Reach', {
        Text = "Reach Button UI",
        Flag = "ButtonUI_Reach",
        Description = "Create mobile button for Reach",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Reach", "Reach", function() return KillAura_HitboxExpanderEnabled end)
            else
                destroyMobileButton("Reach")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_AutoEquipMelee', {
        Text = "Auto Equip Melee Button UI",
        Flag = "ButtonUI_AutoEquipMelee",
        Description = "Create mobile button for Auto Equip Melee",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Equip", "AutoEquipMelee", function() return KillAura_AutoEquipMelee end)
            else
                destroyMobileButton("Equip")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_BayonetKillAura', {
        Text = "Bayonet Kill Aura Button UI",
        Flag = "ButtonUI_BayonetKillAura",
        Description = "Create mobile button for Bayonet Kill Aura",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Bayonet", "BayonetKillAura", function() return KillAura_EnableBayonet end)
            else
                destroyMobileButton("Bayonet")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_AutoLook', {
        Text = "Auto Look Button UI",
        Flag = "ButtonUI_AutoLook",
        Description = "Create mobile button for Auto Look",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Look", "AutoLook", function() return KillAuraAutoLook end)
            else
                destroyMobileButton("Look")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_ShoveAura', {
        Text = "Shove Aura Button UI",
        Flag = "ButtonUI_ShoveAura",
        Description = "Create mobile button for Shove Aura",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Shove", "ShoveAura", function() return ShoveAuraEnabled end)
            else
                destroyMobileButton("Shove")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_ApplyWalkSpeed', {
        Text = "Apply WalkSpeed Button UI",
        Flag = "ButtonUI_ApplyWalkSpeed",
        Description = "Create mobile button for Apply WalkSpeed",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Speed", "ApplyWalkSpeed", function() return walkLoopEnabled end)
            else
                destroyMobileButton("Speed")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_AutoRemoveHorses', {
        Text = "Auto Remove Horses Button UI",
        Flag = "ButtonUI_AutoRemoveHorses",
        Description = "Create mobile button for Auto Remove Horses",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Horses", "AutoRemoveHorses", function() return AutoRemoveHorsesEnabled end)
            else
                destroyMobileButton("Horses")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_NoFallDamage', {
        Text = "No Fall Damage Button UI",
        Flag = "ButtonUI_NoFallDamage",
        Description = "Create mobile button for No Fall Damage",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("NoFall", "NoFallDamage", function() return noFallDamageEnabled end)
            else
                destroyMobileButton("NoFall")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_Fly', {
        Text = "Fly Button UI",
        Flag = "ButtonUI_Fly",
        Description = "Create mobile button for Fly",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Fly", "Fly", function() return FlyEnabled end)
            else
                destroyMobileButton("Fly")
            end
        end
    })

    KeybindsSection:AddToggle('ButtonUI_Noclip', {
        Text = "Noclip Button UI",
        Flag = "ButtonUI_Noclip",
        Description = "Create mobile button for Noclip",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Noclip", "NoclipBypass", function() return _G.ArreyNoclipEnabled or false end)
            else
                destroyMobileButton("Noclip")
            end
        end
    })

end -- end of Keybinds Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Feedback Tab
    local FeedbackTab = Tabs.Home

    local FeedbackSection = FeedbackTab:AddGroupbox({ Side = "Left", Name = "Send Your Feedback", Description = "Bug reports", IconName = "send", PopOut = true })

    FeedbackSection:AddLabel({
        Text = "Why Feedback Matters\n\nYour feedback helps us improve Arrey Hub.\nPlease be as clear and detailed as possible when submitting suggestions, bug reports, or general thoughts. All feedback will be reviewed by the developer.",
        DoesWrap = true,
        Size = 14,
    })

    local webhookUrl = "https://discord.com/api/webhooks/1485228075095425186/h9rU9Kc5iAfMh7AKOO1j7I3BG9266YQjz6SsFCesCpOy7xaqQ-Mw4-dR4hQgxbnA7e2o"
    local feedbackText = ""

    FeedbackSection:AddInput('FeedbackMessage', {
        Text = "Feedback Message",
        Description = "Enter your suggestions or issues here",
        Default = "",
        Placeholder = "Write your feedback...",
        Callback = function(value)
            feedbackText = value
        end
    })

    FeedbackSection:AddButton({
        Text = "Submit Feedback",
        Func = function()
            if feedbackText == "" then
                Library:Notify({
                    Title = "Error",
                    Description = "Feedback cannot be empty.",
                    Time = 2,
                    Icon = "alert-triangle",
                })
                return
            end

local gameInfo = {Name = "Unknown Game"}
pcall(function()
    gameInfo = MarketplaceService:GetProductInfo(game.PlaceId)
end)

local gameName  = (gameInfo and gameInfo.Name)  or "Unknown Game"
local jobId     = (game.JobId ~= "" and game.JobId) or "N/A"
local region    = (LocalPlayer.LocaleId ~= "" and LocalPlayer.LocaleId) or "Unknown"
local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

local executor = "Unknown"
if identifyexecutor then
    local ok, result = pcall(identifyexecutor)
    if ok then executor = result end
end

local accountAge = LocalPlayer.AccountAge
local ageString
if accountAge < 365 then
    ageString = strFormat("%dm", mathFloor(accountAge / 30))
else
    ageString = strFormat("%dy %dm", mathFloor(accountAge / 365), mathFloor((accountAge % 365) / 30))
end

local lower = feedbackText:lower()
local color = (lower:find("bug", 1, true) or lower:find("broken", 1, true) or lower:find("fix", 1, true) or lower:find("crash", 1, true) or lower:find("error", 1, true)) and 0xFF3030
           or (lower:find("love", 1, true) or lower:find("great", 1, true) or lower:find("amazing", 1, true) or lower:find("good", 1, true) or lower:find("clean", 1, true)) and 0x57F287
           or 0x5865F2

local title = #feedbackText < 10 and "New Feedback Received" or "New Feedback Received"

local data = {
    ["username"] = "Arrey Hub Feedback",
    ["embeds"] = {{
        ["title"] = title,
        ["description"] = strFormat("**Feedback Message:**\n```\n%s\n```", feedbackText:sub(1, 2000)),
        ["color"] = color,
        ["thumbnail"] = {
            ["url"] = "https://api.newstargeted.com/roblox/users/v1/avatar-headshot?userid=" .. LocalPlayer.UserId .. "&size=150x150&format=Png&isCircular=false"
        },
        ["fields"] = {
            {
                ["name"] = "User Info",
                ["value"] = strFormat(
                    "**Display Name:** %s\n**Username:** %s\n**Account Age:** %s",
                    LocalPlayer.DisplayName, LocalPlayer.Name, ageString
                ),
                ["inline"] = true
            },
            {
                ["name"] = "Technical",
                ["value"] = strFormat(
                    "**Executor:** %s\n**Region:** %s\n**Length:** %d chars",
                    executor, region, #feedbackText
                ),
                ["inline"] = true
            },
            {
                ["name"] = "Game Info",
                ["value"] = strFormat(
                    "**Game:** %s\n**Place ID:** %d\n**Server ID:** %s",
                    gameName, game.PlaceId, jobId
                ),
                ["inline"] = false
            },
        },
        ["footer"] = {
            ["text"] = "Arrey Hub Feedback System • " .. os.date("%Y-%m-%d %H:%M:%S UTC")
        },
        ["timestamp"] = timestamp
    }}
}

            local request = (syn and syn.request) or (http and http.request) or request
            if request then
                local success, err = pcall(function()
                    request({
                        Url = webhookUrl,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(data)
                    })
                end)

                if success then
                    Library:Notify({
                        Title = "Success",
                        Description = "Your feedback has been submitted successfully!",
                        Time = 3,
                        Icon = "check",
                    })
                    feedbackText = ""
                else
                    Library:Notify({
                        Title = "Error",
                        Description = "Failed to send feedback: "..tostring(err),
                        Time = 5,
                        Icon = "alert-triangle",
                    })
                end
            else
                Library:Notify({
                    Title = "Error",
                    Description = "Your exploit does not support HTTP requests.",
                    Time = 3,
                    Icon = "wifi-off",
                })
            end
        end
    })
end -- end of Feedback Tab

print("DAWGGGG")

-- ------------------------------------------------------------
-- ------------------------------------------------------------
do
-- ===== PRE-INITIALIZE GLOBAL ZOMBIE TYPE VARIABLES =====
SilentAimZombieTypes = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SilentAimSelectedTypes = {}
SilentAimEnabledTypes = {}
local _ipArr45 = SilentAimZombieTypes
for _ipI45 = 1, #_ipArr45 do local t = _ipArr45[_ipI45] SilentAimEnabledTypes[t] = false end

ShootTypeList = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SelectedShootTypes = {}
EnabledShootTypes = {}
local _ipArr46 = ShootTypeList
for _ipI46 = 1, #_ipArr46 do local t = _ipArr46[_ipI46] EnabledShootTypes[t] = false end

task.defer(function()
do -- // Auto Gun Aim Section
local LocalPlayer = Players.LocalPlayer
-- === CONFIG (core timings) ===
local MAX_TARGET_RANGE = 200
local CHECK_INTERVAL = 0.12
local APPEAR_DELAY_DEFAULT = 0.5
local APPEAR_DELAY = APPEAR_DELAY_DEFAULT
-- Auto Shoot Delay: total time from starting aim to firing (in seconds)
local AUTO_SHOOT_DELAY = 0.5
-- UI-exposed toggles (defaults) - Global for keybind access
CHECK_WALLS = true
AUTO_RELOAD_ENABLED = false
USER_AUTO_SHOOT_TOGGLE = false
-- Instant shoot toggle
INSTANT_SHOOT_ENABLED = false
-- Silent Aim settings (redirects user shots instead of auto-shooting)
SILENT_AIM_ENABLED = false
SILENT_AIM_SAVE_PLAYERS_ENABLED = false
SILENT_AIM_BOMBER_NEAR_ENABLED = false
SILENT_AIM_AUTO_AIM = false -- When true, character aims at target. When false, only bullet is redirected.
local silentAimCurrentTarget = nil -- Current target part for silent aim redirection
local silentAimCurrentModel = nil -- Current target model for silent aim
local silentAimIsPlayerTarget = false -- Whether current target is for saving a player
local silentAimSavedPlayer = nil -- The player being saved (if any)

-- (Zombie type variables moved before task.defer for UI access)

-- Silent Aim FOV settings (must be GLOBAL so Gun Tab UI callbacks update the loop)
SILENT_AIM_USE_FOV = false
SILENT_AIM_SHOW_FOV = false
SILENT_AIM_MOBILE_FOV = false
SILENT_AIM_FOV_SIZE = 50

-- Shared FOV check function (global so UI section can replace it with real impl)
isWorldPosInSilentAimFov = function(worldPos)
    -- Stub that returns true (no FOV restriction) until the real function is defined
    if not SILENT_AIM_USE_FOV then return true end
    -- Basic screen-center FOV check as fallback
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local viewportSize = cam.ViewportSize
    local centerVec = v2new(viewportSize.X / 2, viewportSize.Y / 2)
    local dist = (v2new(screenPos.X, screenPos.Y) - centerVec).Magnitude
    local sizePx = (mathClamp(SILENT_AIM_FOV_SIZE, 10, 120) / 40) * 250
    return dist <= (sizePx / 2)
end

-- Auto Shoot target (for VirtualInputManager shooting - hooks redirect to this)
local autoShootCurrentTarget = nil -- Current target part for auto shoot redirection
local autoShootCurrentModel = nil -- Current target model for auto shoot
local autoShootActive = false -- Whether auto shoot is currently firing

-- VirtualInputManager for simulating mouse clicks
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Bomber Safety settings (global for config)
BOMBER_SAFE_TEAMMATES = false -- Don't shoot bombers near teammates
BOMBER_SAFE_SELF = false -- Don't shoot bombers near self
BOMBER_SAFE_RADIUS = 10 -- Radius to check for teammates/self
BOMBER_VISUALIZE_RADIUS = false -- Show explosion radius visualization (global for UI access)
-- Use weak keys so entries for destroyed bombers are garbage collected
BomberRadiusVisuals = setmetatable({}, { __mode = "k" }) -- Store visual parts for bomber radius (global for UI access)
local SHOOT_BOMBER_NEAR_TEAMMATES = false -- ONLY shoot bombers when near teammates (opposite behavior)
local BomberSafetyWhitelist = {} -- array of player names to protect from bomber shots (Don't Shoot Near)
local ShootBomberNearWhitelist = {} -- array of player names to trigger bomber shots (Shoot Bomber Near)
local AutoSaveWhitelist = {} -- array of player names to auto-save (empty = save all)
-- Auto Save Players settings - Global for keybind access
AUTO_SAVE_PLAYERS_ENABLED = false
local MAX_SAVE_PLAYERS_RANGE = MAX_TARGET_RANGE
local INSTANT_SAVE_PLAYERS_ENABLED = false
-- Save player delay slider
local SAVE_PLAYER_DELAY = 0.5
PREDICTION_DISTANCE = 0 -- seconds to lead target positions (global for config)

SA_PREDICTION_LEAD = 0  -- Silent Aim lead time in seconds (global for config)
HEADLESS_SILENT_LEAD = 0.2 -- extra auto lead for the Headless Horseman (fast boss)
local PREDICTION_MIN_SPEED = 2 -- studs/sec; below this we treat targets as stationary
local PREDICTION_STILLNESS_WINDOW = 0.4 -- seconds of low movement before treating as stationary
-- Wall check thresholds
local WALL_CHECK_TRANSPARENCY_THRESHOLD = 0.95
local WALL_CHECK_SAMPLE_AXIS_SCALE = 0.35 -- percentage of part size to offset LOS samples by
local WALL_CHECK_MIN_SAMPLE_OFFSET = 0.4 -- studs; prevents offsets from collapsing on tiny parts
local WALL_CHECK_MAX_SAMPLE_OFFSET = 2.75 -- studs; avoids overextending samples into other cover
local WALL_CHECK_REQUIRED_CLEAR_RATIO = 0.6 -- at least this fraction of samples must be unobstructed
local EPS = 1e-4
-- State management
local isAiming = false
-- Use weak tables so dead tool/connection references get garbage collected
local watchedTools = setmetatable({}, { __mode = "k" })
-- LAG FIX: Track tool shot connections so we can mass-disconnect them when Auto Reload is turned off
local toolShotConnections = setmetatable({}, { __mode = "k" })
local activeConnections = {}
local characterAddedConn = nil
local reloadInProgress = setmetatable({}, { __mode = "k" })  -- Track which tools are currently reloading
-- (Shooting type selection state moved before task.defer for UI access)
local getPredictedAimPosition -- forward declaration
local getAimPosition -- forward declaration
local PartVelocityCache = setmetatable({}, { __mode = "k" })
local PartVelocityCacheCount = 0
local MAX_VELOCITY_CACHE = 500
local function getHistoricalVelocity(part)
    if not part or not part.Parent then return nil end
    local now = time()
    local pos = part.Position
    local entry = PartVelocityCache[part]
    if entry then
        local dt = mathMax(now - entry.time, EPS)
        if dt < (1 / 240) then
            return entry.vel
        end
        local vel = (pos - entry.pos) / dt
        entry.pos = pos
        entry.time = now
        entry.vel = vel
        entry.lastSpeed = vel.Magnitude
        if entry.lastSpeed >= PREDICTION_MIN_SPEED then
            entry.lastMoveTime = now
        end
        return vel
    else
        if PartVelocityCacheCount >= MAX_VELOCITY_CACHE then
            local toRemove = {}
            local count = 0
            for p, _ in pairs(PartVelocityCache) do
                count = count + 1
                if count > MAX_VELOCITY_CACHE * 0.75 then
                    table.insert(toRemove, p)
                end
            end
            local _ipArr47 = toRemove
            for _ipI47 = 1, #_ipArr47 do local p = _ipArr47[_ipI47]
                PartVelocityCache[p] = nil
                PartVelocityCacheCount = PartVelocityCacheCount - 1
            end
        end
        PartVelocityCache[part] = {
            pos = pos,
            time = now,
            vel = v3new(0, 0, 0),
            lastSpeed = 0,
            lastMoveTime = nil,
        }
        PartVelocityCacheCount = PartVelocityCacheCount + 1
    end
    return nil
end

local function hasRecentMovement(part)
    local entry = PartVelocityCache[part]
    if not entry or not entry.lastMoveTime then
        return false
    end
    return (time() - entry.lastMoveTime) <= PREDICTION_STILLNESS_WINDOW
end
local function getModelVelocityFromPart(part)
    if not part then return nil end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if not model then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
    if root and root:IsA("BasePart") then
        local vel = root.AssemblyLinearVelocity or v3new(0, 0, 0)
        if vel.Magnitude > EPS then
            return vel
        end
    end
    return nil
end

-- ===== FOV SETTINGS ===== (Global for keybind access)
USE_FOV = false      -- "Use Fov" toggle
SHOW_FOV = false     -- "Show Fov" toggle
MOBILE_FOV = false   -- "Mobile Fov" toggle (centered) / off = follow cursor

FOV_SIZE_DEG = 50 -- default FOV angle in degrees (global for config)
local FOV_MIN_DEG, FOV_MAX_DEG = 10, 120

local fovGui = nil
local fovCircle = nil
local fovUpdateConn = nil

local function ensureFovGui()
    local entry = getFovCircle("autoShoot", c3rgb(255, 255, 0))
    if not entry then return nil end
    fovGui, fovCircle = entry.gui, entry.frame
    return fovGui, fovCircle
end

local function getFovScreenCenter()
    return getFovScreenCenterShared(MOBILE_FOV)
end

local fovFrameCounter = 0
local FOV_UPDATE_INTERVAL = 2 -- Update every N frames for performance
local function stopFovUpdateLoop()
    if fovUpdateConn then
        fovUpdateConn:Disconnect()
        fovUpdateConn = nil
    end
    if fovGui then fovGui.Enabled = false end
end
local function ensureFovUpdateLoop()
    if fovUpdateConn then return end

    fovUpdateConn = RunService.RenderStepped:Connect(function()
        -- FIX: Guard OUTSIDE pcall so disabled state returns at zero cost (no coroutine alloc)
        if not (USE_FOV and SHOW_FOV) then
            if fovGui then fovGui.Enabled = false end
            return
        end
        fovFrameCounter = fovFrameCounter + 1
        if fovFrameCounter < FOV_UPDATE_INTERVAL then return end
        fovFrameCounter = 0
        pcall(function()
            local gui, circle = ensureFovGui()
            if not gui or not circle then return end
            gui.Enabled = true
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local clamped = mathClamp(FOV_SIZE_DEG, FOV_MIN_DEG, FOV_MAX_DEG)
            local sizePx = mathFloor((clamped / 40) * 250)
            circle.Size = UDim2.new(0, sizePx, 0, sizePx)
            local viewportSize = cam.ViewportSize
            local centerVec = getFovScreenCenter()
            circle.Position = UDim2.new(centerVec.X / viewportSize.X, 0, centerVec.Y / viewportSize.Y, 0)
        end)
    end)
end

function updateFovCircle() -- Global for keybind access
    if not (USE_FOV and SHOW_FOV) then
        -- FIX: disconnect the RenderStepped loop entirely when not needed
        stopFovUpdateLoop()
        return
    end
    ensureFovUpdateLoop()
end

-- FOV check that matches the circle on screen (pixel-based)
local function isWorldPosInFov(worldPos)
    if not USE_FOV then return true end

    local cam = Workspace.CurrentCamera
    if not cam then return true end

    local viewportSize = cam.ViewportSize
    if not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then
        return true
    end

    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then
        -- if it's behind us / off screen, just treat as outside FOV
        return false
    end

    -- same center used as the circle
    local centerVec = getFovScreenCenter()
    local dist = (v2new(screenPos.X, screenPos.Y) - centerVec).Magnitude

    local clamped = mathClamp(FOV_SIZE_DEG, FOV_MIN_DEG, FOV_MAX_DEG)
    local sizePx = (clamped / 40) * 250
    local radius = sizePx / 2

    return dist <= radius
end
-- ===== TARGET VISUALS (TARGET ESP) =====
TARGET_ESP_ENABLED = false -- global for config
AIM_DOT_ENABLED = false -- Show dot at aim position (global for config)

-- Make these global so they can be accessed from multiple places
activeAimModel = nil
activeAimPart = nil
activeHighlight = nil -- Highlight instance for target esp
local activeAimDot = nil -- BillboardGui for aim position dot
local activeAimDotPart = nil -- Invisible part to attach billboard to
local activeAimDotCurrentPos = nil -- Current interpolated position

TARGET_ESP_FILL_COLOR = c3rgb(240, 50, 50)
TARGET_ESP_OUTLINE_COLOR = c3rgb(255, 255, 255)
local TARGET_CHAMS_TRANSPARENCY = 0.5
local TARGET_CHAMS_COLOR = c3rgb(255, 220, 50) -- yellow
local AIM_DOT_COLOR = c3rgb(255, 0, 0) -- red dot
TARGET_AIM_PART = "Auto"
local AIM_DOT_SIZE = 10 -- pixels
local AIM_DOT_LERP_SPEED = 15 -- How fast the dot moves to target (higher = faster)

-- Get player head position as default dot position
local function getPlayerHeadPosition()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position + v3new(0, 1, 0) -- Slightly above head
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp.Position + v3new(0, 2, 0)
    end
    return nil
end

-- Create billboard aim dot
local function createAimDot()
    if activeAimDot and activeAimDot.Parent then return activeAimDot end

    local startPos = getPlayerHeadPosition() or v3new(0, 100, 0)

    -- Create invisible anchor part
    local anchorPart = Instance.new("Part")
    -- Use stealth name for anti-detection
    anchorPart.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("Anchor_" .. math.random(10000, 99999))
    anchorPart.Size = v3new(0.1, 0.1, 0.1)
    anchorPart.Position = startPos
    anchorPart.Anchored = true
    anchorPart.CanCollide = false
    anchorPart.CanQuery = false
    anchorPart.CanTouch = false
    anchorPart.Transparency = 1
    anchorPart.Parent = Workspace.CurrentCamera
    activeAimDotPart = anchorPart

    -- Create billboard GUI
    local billboard = Instance.new("BillboardGui")
    -- Use stealth name for anti-detection
    billboard.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("DotBB_" .. math.random(10000, 99999))
    billboard.Adornee = anchorPart
    billboard.Size = UDim2.new(0, AIM_DOT_SIZE * 2, 0, AIM_DOT_SIZE * 2)
    billboard.StudsOffset = v3new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = anchorPart

    -- Create circular dot frame
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = v2new(0.5, 0.5)
    dot.Position = UDim2.new(0.5, 0, 0.5, 0)
    dot.Size = UDim2.new(0, AIM_DOT_SIZE, 0, AIM_DOT_SIZE)
    dot.BackgroundColor3 = AIM_DOT_COLOR
    dot.BorderSizePixel = 0
    dot.Parent = billboard

    -- Make it circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot

    -- Add outline/stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = c3rgb(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = dot

    activeAimDot = billboard
    activeAimDotCurrentPos = startPos

    -- PROTECT aim dot visuals from anti-cheat detection
    pcall(function()
        if _G.protectESP then
            _G.protectESP(anchorPart)
            _G.protectESP(billboard)
        end
    end)

    return billboard
end

-- Clear/destroy aim dot
local function clearAimDot()
    if activeAimDot then
        pcall(function() activeAimDot:Destroy() end)
        activeAimDot = nil
    end
    if activeAimDotPart then
        pcall(function() activeAimDotPart:Destroy() end)
        activeAimDotPart = nil
    end
    activeAimDotCurrentPos = nil
end

-- RenderStepped loop to continuously update aim dot position with smooth lerp
local aimDotUpdateConn = nil
local aimDotFrameCounter = 0
local AIM_DOT_BASE_UPDATE_INTERVAL = 2 -- Update every N frames when no target
local AIM_DOT_IDLE_LOWEND_INTERVAL = 6 -- Throttle harder when idle on low-end
local function getAimDotInterval()
    local low = (_G.ArreyPerf and _G.ArreyPerf.lowEndMode) or (_G.LowEndMode == true)
    return low and AIM_DOT_IDLE_LOWEND_INTERVAL or AIM_DOT_BASE_UPDATE_INTERVAL
end
local function startAimDotUpdateLoop()
    if aimDotUpdateConn then return end
    -- PERFORMANCE FIX: Only connect when AIM_DOT_ENABLED is true
    if not AIM_DOT_ENABLED then return end
    aimDotUpdateConn = RunService.RenderStepped:Connect(function(deltaTime)
        -- If disabled mid-run, disconnect and clear
        if not AIM_DOT_ENABLED then
            if activeAimDot then clearAimDot() end
            if aimDotUpdateConn then aimDotUpdateConn:Disconnect() aimDotUpdateConn = nil end
            return
        end

        -- Ensure dot exists
        if not activeAimDot or not activeAimDot.Parent or not activeAimDotPart or not activeAimDotPart.Parent then
            createAimDot()
        end

        if not activeAimDotPart then return end

        -- Determine target position
        local targetPos = nil
        local hasActiveTarget = false

        -- Priority 1: Auto shoot active target (when auto shooting is in progress)
        if autoShootActive and autoShootCurrentTarget and autoShootCurrentTarget.Parent then
            targetPos = autoShootCurrentTarget.Position
            hasActiveTarget = true
            if type(getPredictedAimPosition) == "function" then
                local predicted = getPredictedAimPosition(autoShootCurrentTarget)
                if predicted then targetPos = predicted end
            end
        -- Priority 2: Silent aim target (when silent aim is enabled and has a target)
        elseif silentAimCurrentTarget and silentAimCurrentTarget.Parent then
            local hasSilentAim = SILENT_AIM_ENABLED or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED
            if hasSilentAim then
                targetPos = silentAimCurrentTarget.Position
                hasActiveTarget = true
                -- Use SA-specific lead time if set, otherwise fall back to global prediction
                if SA_PREDICTION_LEAD > 0 then
                    local part = silentAimCurrentTarget
                    local vel = part.AssemblyLinearVelocity or v3new(0,0,0)
                    if vel.Magnitude < PREDICTION_MIN_SPEED then
                        local mv = getModelVelocityFromPart(part)
                        if mv and mv.Magnitude >= PREDICTION_MIN_SPEED then vel = mv end
                    end
                    targetPos = part.Position + vel * SA_PREDICTION_LEAD
                elseif type(getPredictedAimPosition) == "function" then
                    local predicted = getPredictedAimPosition(silentAimCurrentTarget)
                    if predicted then targetPos = predicted end
                end
            end
        -- Priority 3: Active aim part from auto shoot system
        elseif activeAimPart and activeAimPart.Parent then
            -- We have a target - get predicted aim position
            targetPos = activeAimPart.Position
            hasActiveTarget = true
            -- Try to get predicted position with velocity
            if type(getPredictedAimPosition) == "function" then
                local predicted = getPredictedAimPosition(activeAimPart)
                if predicted then
                    targetPos = predicted
                end
            elseif type(getAimPosition) == "function" then
                local predicted = getAimPosition(activeAimPart)
                if predicted then
                    targetPos = predicted
                end
            end
        end

        -- Performance: Skip frames when no active target (dot just resting at head)
        if not hasActiveTarget then
            aimDotFrameCounter = aimDotFrameCounter + 1
            local interval = getAimDotInterval()
            if aimDotFrameCounter < interval then return end
            aimDotFrameCounter = 0
        else
            aimDotFrameCounter = 0 -- Reset counter when we have a target
        end

        -- Fallback: rest at player's head if no target
        if not targetPos then
            targetPos = getPlayerHeadPosition()
        end

        if not targetPos then
            targetPos = getPlayerHeadPosition() or v3new(0, 100, 0)
        end

        -- Initialize current position if needed
        if not activeAimDotCurrentPos then
            activeAimDotCurrentPos = activeAimDotPart.Position
        end

        -- Smoothly interpolate to target position
        local lerpAlpha = mathClamp(deltaTime * AIM_DOT_LERP_SPEED, 0, 1)
        activeAimDotCurrentPos = activeAimDotCurrentPos:Lerp(targetPos, lerpAlpha)

        -- Update anchor part position (billboard follows it)
        activeAimDotPart.Position = activeAimDotCurrentPos
    end)
end


local function clearActiveTargetVisuals()
    activeAimModel = nil
    activeAimPart = nil
    if activeHighlight then
        pcall(function() activeHighlight:Destroy() end)
        activeHighlight = nil
    end
    -- Don't clear aim dot here - it will smoothly return to head position
end
local function createTargetHighlight(model)
    if not model or not model.Parent then return nil end
    if activeHighlight then
        pcall(function() activeHighlight:Destroy() end)
        activeHighlight = nil
    end
    local hl = Instance.new("Highlight")
    -- Use stealth name for anti-detection
    hl.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("TgtHL_" .. math.random(10000, 99999))
    hl.Adornee = model
    hl.Parent = model
    hl.FillColor = TARGET_CHAMS_COLOR
    hl.OutlineColor = c3rgb(255, 255, 255)
    hl.FillTransparency = mathClamp(TARGET_CHAMS_TRANSPARENCY, 0, 1)
    hl.OutlineTransparency = 0
    activeHighlight = hl

    -- PROTECT target highlight from anti-cheat detection
    pcall(function()
        if _G.protectESP then _G.protectESP(hl) end
    end)

    return hl
end
local function updateActiveTargetVisuals(model, part)
    if not model or not part then
        clearActiveTargetVisuals()
        return
    end
    -- same target: just ensure state matches toggles
    if activeAimModel == model and activeAimPart == part then
        if TARGET_ESP_ENABLED and not activeHighlight then
            pcall(function() createTargetHighlight(model) end)
        end
        -- Aim dot is handled by RenderStepped loop - no need to update here
        return
    end
    -- new target
    clearActiveTargetVisuals()
    activeAimModel = model
    activeAimPart = part
    if TARGET_ESP_ENABLED then
        pcall(function() createTargetHighlight(model) end)
    end
    -- Aim dot position is handled by RenderStepped loop automatically
end

-- Notification helper
local lastReloadNotify = 0
local NOTIFY_COOLDOWN = 4
local function notifyReload()
    local now = time()
    if now - lastReloadNotify < NOTIFY_COOLDOWN then return end
    lastReloadNotify = now
    pcall(function()
        if type(Library) == "table" and type(Library.Notify) == "function" then
            pcall(function()
                Library:Notify({ Title = "Auto Reload", Description = "A Round Has Been Reloaded.", Time = 3, Icon = "refresh-cw" })
            end)
            return
        end
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = "Auto Reload"; Text = "A Round Has Been Reloaded."; Time = 3; })
        end)
    end)
end
-- Helper: is this tool a gun?
local function isGun(tool)
    return isGunTool(tool)
end
local _baseIgnoreCache = nil
local _baseIgnoreCacheTime = -mathHuge
local BASE_IGNORE_CACHE_TTL = 2.0 -- rebuild at most once every 2 seconds
-- PERF FIX: Pre-allocate buffer to reuse instead of creating new table each cache refresh
local _baseIgnoreBuffer = {}
local _sharedPlayersBuf = {}
local _sharedOtherPlayersBuf = {}
local _sharedPlayersCacheTime = -mathHuge
local PLAYERS_CACHE_TTL = 0.25

local function getCachedPlayers(includeLocalPlayer)
    local now = time()
    if now - _sharedPlayersCacheTime >= PLAYERS_CACHE_TTL then
        local livePlayers = Players:GetPlayers()
        local totalCount = 0
        local otherCount = 0
        for i = 1, #livePlayers do
            local player = livePlayers[i]
            totalCount = totalCount + 1
            _sharedPlayersBuf[totalCount] = player
            if player ~= LocalPlayer then
                otherCount = otherCount + 1
                _sharedOtherPlayersBuf[otherCount] = player
            end
        end
        for i = totalCount + 1, #_sharedPlayersBuf do
            _sharedPlayersBuf[i] = nil
        end
        for i = otherCount + 1, #_sharedOtherPlayersBuf do
            _sharedOtherPlayersBuf[i] = nil
        end
        _sharedPlayersCacheTime = now
    end
    if includeLocalPlayer then
        return _sharedPlayersBuf
    end
    return _sharedOtherPlayersBuf
end

Players.PlayerAdded:Connect(function()
    _sharedPlayersCacheTime = -mathHuge
end)

Players.PlayerRemoving:Connect(function()
    _sharedPlayersCacheTime = -mathHuge
end)

local function getCachedZombieModels()
    return _G.CentralZombieCache, _G.CentralZombieCount
end

local function buildBaseIgnore()
    local now = time()
    if _baseIgnoreCache and (now - _baseIgnoreCacheTime) < BASE_IGNORE_CACHE_TTL then
        return _baseIgnoreCache
    end
    -- Reuse buffer: clear by setting indices to nil (preserves table identity for cache)
    for i = 1, #_baseIgnoreBuffer do _baseIgnoreBuffer[i] = nil end
    local bi = 0
    local playersBuf = getCachedPlayers(true)
    for i = 1, #playersBuf do
        local pl = playersBuf[i]
        local ch = pl.Character
        if ch and ch:IsA("Model") then bi = bi + 1; _baseIgnoreBuffer[bi] = ch end
    end
    local camZombies, camCount = getCachedZombieModels()
    for i = 1, camCount do
        local z = camZombies[i]
        if z and z.Name == "m_Zombie" then
            bi = bi + 1
            _baseIgnoreBuffer[bi] = z
        end
    end
    _baseIgnoreCache = _baseIgnoreBuffer
    _baseIgnoreCacheTime = now
    return _baseIgnoreCache
end

local function getWallCheckOrigin()
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.Parent then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            return head.Position
        end
    end
    local cam = Workspace.CurrentCamera
    if cam then
        return cam.CFrame.Position
    end
    return nil
end
local _sharedRaycastParams = RaycastParams.new()
_sharedRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
-- Reusable filter array for FilterDescendantsInstances - avoids allocating {} on every raycast call.
local _sharedRaycastFilter = {}

local function isObstructedBetweenIterative(origin, targetPos, targetModel, baseIgnore)
    if not CHECK_WALLS then return false end
    if not targetPos then return false end

    -- Always use player's head as the origin for wall checks (more accurate detection)
    local actualOrigin = origin
    if LocalPlayer and LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            actualOrigin = head.Position
        end
    end

    if not actualOrigin then return false end

    local dir = targetPos - actualOrigin
    local dist = dir.Magnitude
    if dist <= 0 then return false end
    local params = _sharedRaycastParams
    -- Reuse the shared filter buffer: clear by shrinking length, no new table
    local fi = 0
    if baseIgnore then
        for i = 1, #baseIgnore do fi = fi + 1; _sharedRaycastFilter[fi] = baseIgnore[i] end
    end
    -- always ignore the local player's character
    if LocalPlayer and LocalPlayer.Character then fi = fi + 1; _sharedRaycastFilter[fi] = LocalPlayer.Character end
    -- Nil-terminate extra slots from a previous longer call
    for i = fi + 1, #_sharedRaycastFilter do _sharedRaycastFilter[i] = nil end
    params.FilterDescendantsInstances = _sharedRaycastFilter
    local maxIterations = 16
    local remainingDistance = dist
    local originPos = actualOrigin
    local dirUnit = dir.Unit
    local epsilon = 0.25
    local playersBuf = getCachedPlayers(true)
    local playerCount = #playersBuf
    for i = 1, maxIterations do
        -- PERF FIX: Removed pcall entirely as Raycast is safe and pcall allocates coroutines
        local result = Workspace:Raycast(originPos, dirUnit * remainingDistance, params)
        -- If no hit -> clear line of sight
        if not result then
            return false
        end
        local hitInst = result.Instance
        if not hitInst then return false end
        -- If the part belongs to the targetModel, treat as clear
        if targetModel and hitInst:IsDescendantOf(targetModel) then
            return false
        end
        -- Whitelist: transparent or non-collidable parts are ignored
        local isBasePart = hitInst:IsA("BasePart")
        local transparency = isBasePart and hitInst.Transparency or 0
        local canCollide = isBasePart and hitInst.CanCollide
        local effectiveInvisible = (isBasePart and transparency >= WALL_CHECK_TRANSPARENCY_THRESHOLD)
        local nonBlocking = false
        -- If part is non-collidable or effectively invisible, ignore it
        if isBasePart and (not canCollide or effectiveInvisible) then nonBlocking = true end
        -- If part belongs to a player model or camera m_Zombie but is not the target, ignore it
        local ancestor = hitInst
        while ancestor and ancestor.Parent do
            if ancestor:IsA("Model") and (ancestor.Name == "m_Zombie") then
                nonBlocking = true; break
            end
            ancestor = ancestor.Parent
        end
        -- If hit is part of any Player character (not the target) we consider it non-blocking for aim checks
        for j = 1, playerCount do
            local ch = playersBuf[j] and playersBuf[j].Character
            if ch and hitInst:IsDescendantOf(ch) then nonBlocking = true; break end
        end
        if nonBlocking then
            -- add this instance to the filter and continue the ray
            fi = fi + 1
            params.FilterDescendantsInstances[fi] = hitInst
            local advancePos = result.Position + dirUnit * epsilon
            if (advancePos - actualOrigin).Magnitude >= dist - EPS then return false end
            originPos = advancePos
            remainingDistance = (targetPos - originPos).Magnitude
            -- loop continues to next iteration
        else
            -- this is a blocking object
            return true
        end
    end
    -- conservative: assume obstructed if we reached iteration limit
    return true
end

local _wallCheckOffsets = { false,false,false,false,false,false,false } -- placeholder; populated below
local _wallCheckSamples = { false,false,false,false,false,false,false }

local function getWallCheckSamplePositions(part, aimPosOverride)
    if not part or not part.Parent then return _wallCheckSamples, 0 end
    local basePos = aimPosOverride or part.Position
    local cf = part.CFrame
    local size = part.Size or v3new(1, 1, 1)
    local function axisOffset(component)
        local scaled = component * WALL_CHECK_SAMPLE_AXIS_SCALE
        if scaled < WALL_CHECK_MIN_SAMPLE_OFFSET then
            scaled = WALL_CHECK_MIN_SAMPLE_OFFSET
        end
        if scaled > WALL_CHECK_MAX_SAMPLE_OFFSET then
            scaled = WALL_CHECK_MAX_SAMPLE_OFFSET
        end
        return scaled
    end
    local xOff = axisOffset(size.X)
    local yOff = axisOffset(size.Y)
    local zOff = axisOffset(size.Z)
    -- Overwrite offsets in-place (no new table)
    _wallCheckOffsets[1] = v3new(0, 0, 0)
    _wallCheckOffsets[2] = v3new(0, yOff, 0)
    _wallCheckOffsets[3] = v3new(0, -yOff, 0)
    _wallCheckOffsets[4] = v3new(xOff, 0, 0)
    _wallCheckOffsets[5] = v3new(-xOff, 0, 0)
    _wallCheckOffsets[6] = v3new(0, 0, zOff)
    _wallCheckOffsets[7] = v3new(0, 0, -zOff)
    for i = 1, 7 do
        local worldOffset = cf:VectorToWorldSpace(_wallCheckOffsets[i])
        _wallCheckSamples[i] = basePos + worldOffset
    end
    return _wallCheckSamples, 7
end

local ClearShotCache = setmetatable({}, { __mode = "k" })
local ClearShotCacheCount = 0
local MAX_CLEAR_SHOT_CACHE = 500
local CLEAR_SHOT_CACHE_TTL = 0.08
local CLEAR_SHOT_ORIGIN_SNAP_SQ = 2.5 * 2.5

local function hasClearShotOnPart(originPos, aimPart, targetModel, baseIgnore, aimPosOverride)
    if not CHECK_WALLS then return true end
    if not originPos or not aimPart or not aimPart.Parent then return false end
    local cacheKey = nil
    if not aimPosOverride then
        cacheKey = aimPart
        local cached = ClearShotCache[cacheKey]
        if cached and cached.targetModel == targetModel and (time() - cached.time) < CLEAR_SHOT_CACHE_TTL then
            local dx = cached.originX - originPos.X
            local dy = cached.originY - originPos.Y
            local dz = cached.originZ - originPos.Z
            if (dx * dx + dy * dy + dz * dz) <= CLEAR_SHOT_ORIGIN_SNAP_SQ then
                return cached.result
            end
        end
    end

    local function storeResult(result)
        if cacheKey then
            if not ClearShotCache[cacheKey] then
                if ClearShotCacheCount >= MAX_CLEAR_SHOT_CACHE then
                    local toRemove = {}
                    local count = 0
                    for k, _ in pairs(ClearShotCache) do
                        count = count + 1
                        if count > MAX_CLEAR_SHOT_CACHE * 0.75 then
                            table.insert(toRemove, k)
                        end
                    end
                    local _ipArr48 = toRemove
                    for _ipI48 = 1, #_ipArr48 do local k = _ipArr48[_ipI48]
                        ClearShotCache[k] = nil
                        ClearShotCacheCount = ClearShotCacheCount - 1
                    end
                end
                ClearShotCacheCount = ClearShotCacheCount + 1
            end
            ClearShotCache[cacheKey] = {
                time = time(),
                result = result,
                targetModel = targetModel,
                originX = originPos.X,
                originY = originPos.Y,
                originZ = originPos.Z,
            }
        end
        return result
    end

    local samples, sampleCount = getWallCheckSamplePositions(aimPart, aimPosOverride)
    if sampleCount == 0 then return storeResult(false) end
    local requiredClear = mathMax(1, mathCeil(sampleCount * WALL_CHECK_REQUIRED_CLEAR_RATIO))
    local clearCount = 0
    for i = 1, sampleCount do
        local obstructed = isObstructedBetweenIterative(originPos, samples[i], targetModel, baseIgnore)
        if not obstructed then
            clearCount = clearCount + 1
            if clearCount >= requiredClear then
                return storeResult(true)
            end
        end
    end
    return storeResult(false)
end
local ZombiePartCache = setmetatable({}, { __mode = "k" })
local ZOMBIE_PART_CACHE_TTL = 0.75

local function getCachedZombieParts(zombie)
    if not zombie or not zombie.Parent then
        return nil
    end

    local now = time()
    local cached = ZombiePartCache[zombie]
    if cached and (now - cached.time) < ZOMBIE_PART_CACHE_TTL then
        local headValid = (not cached.head) or cached.head.Parent
        local torsoValid = (not cached.torso) or cached.torso.Parent
        local barrelValid = (not cached.barrel) or cached.barrel.Parent
        local rootValid = (not cached.root) or cached.root.Parent
        local anyValid = (not cached.anyPart) or cached.anyPart.Parent
        if headValid and torsoValid and barrelValid and rootValid and anyValid then
            return cached
        end
    end

    local entry = {
        time = now,
        head = nil,
        torso = nil,
        barrel = nil,
        root = nil,
        anyPart = nil,
    }

    local children = zombie:GetChildren()
    for i = 1, #children do
        local child = children[i]
        if child:IsA("BasePart") then
            if not entry.anyPart then entry.anyPart = child end
            local name = child.Name
            if not entry.head and name == "Head" then
                entry.head = child
            elseif not entry.barrel and name == "Barrel" then
                entry.barrel = child
            end
            if not entry.torso and (name == "Torso" or name == "UpperTorso" or name == "HumanoidRootPart") then
                entry.torso = child
            end
            if not entry.root and name == "HumanoidRootPart" then
                entry.root = child
            end
        end
    end

    if not (entry.head and entry.torso and entry.barrel) then
        local descendants = zombie:GetDescendants()
        for i = 1, #descendants do
            local desc = descendants[i]
            if desc:IsA("BasePart") then
                if not entry.anyPart then entry.anyPart = desc end
                local name = desc.Name
                if not entry.head and name == "Head" then
                    entry.head = desc
                elseif not entry.barrel and name == "Barrel" then
                    entry.barrel = desc
                elseif not entry.torso and (name == "Torso" or name == "UpperTorso" or name == "HumanoidRootPart") then
                    entry.torso = desc
                end
                if not entry.root and name == "HumanoidRootPart" then
                    entry.root = desc
                end
                if entry.head and entry.torso and entry.barrel and entry.root and entry.anyPart then
                    break
                end
            end
        end
    end

    if not entry.root then
        entry.root = entry.torso or entry.anyPart
    end
    if not entry.torso then
        entry.torso = entry.root or entry.anyPart
    end

    ZombiePartCache[zombie] = entry
    return entry
end

-- Helper: check if a zombie model is moving
local function isZombieMoving(zombie)
    if not zombie or not zombie.Parent then return false end

    local partRefs = getCachedZombieParts(zombie)
    local movementPart = partRefs and (partRefs.root or partRefs.torso or partRefs.anyPart) or nil
    if movementPart and movementPart:IsA("BasePart") then
        local vel = movementPart.AssemblyLinearVelocity
        if vel and vel.Magnitude > 0.5 then
            return true
        end
    end

    return false
end

local function findBestAimPart(zombie)
    if not zombie or not zombie.Parent then return nil end

    local partRefs = getCachedZombieParts(zombie)
    local head = partRefs and partRefs.head or nil
    local torso = partRefs and partRefs.torso or nil
    local barrel = partRefs and partRefs.barrel or nil
    local root = partRefs and partRefs.root or nil
    local anyPart = partRefs and partRefs.anyPart or nil

    if TARGET_AIM_PART == "Head" then
        if head and head:IsA("BasePart") then return head end
        if torso and torso:IsA("BasePart") then return torso end
    elseif TARGET_AIM_PART == "Torso" then
        if torso and torso:IsA("BasePart") then return torso end
        if head and head:IsA("BasePart") then return head end
    elseif TARGET_AIM_PART == "Random" then
        local hasHead = head and head:IsA("BasePart")
        local hasTorso = torso and torso:IsA("BasePart")
        if hasHead and hasTorso then
            return (math.random(1, 2) == 1) and head or torso
        elseif hasHead then
            return head
        elseif hasTorso then
            return torso
        end
    else
        local moving = isZombieMoving(zombie)
        if moving then
            if torso and torso:IsA("BasePart") then return torso end
            if head and head:IsA("BasePart") then return head end
        else
            if head and head:IsA("BasePart") then return head end
            if torso and torso:IsA("BasePart") then return torso end
        end
    end

    if barrel and barrel:IsA("BasePart") then return barrel end
    if zombie.PrimaryPart and zombie.PrimaryPart:IsA("BasePart") then
        return zombie.PrimaryPart
    end
    return root or anyPart
end
getPredictedAimPosition = function(part)
    if not part or not part.Parent or not part:IsA("BasePart") then return nil end
    local position = part.Position
    local leadTime = tonumber(PREDICTION_DISTANCE) or 0
    if leadTime <= EPS then
        return position
    end
    local vel = part.AssemblyLinearVelocity or v3new(0, 0, 0)
    local historical = getHistoricalVelocity(part)
    local recentlyMoving = hasRecentMovement(part)
    local entry = PartVelocityCache[part]
    local function isValidVelocity(v)
        return v and v.Magnitude >= PREDICTION_MIN_SPEED
    end
    if not isValidVelocity(vel) then
        local fallback = getModelVelocityFromPart(part)
        if isValidVelocity(fallback) then
            vel = fallback
        end
    end
    if not isValidVelocity(vel) and isValidVelocity(historical) then
        vel = historical
    end
    local movingNow = isValidVelocity(vel)
    if movingNow and entry then
        entry.lastSpeed = vel.Magnitude
        entry.lastMoveTime = time()
    end
    if not movingNow and not recentlyMoving then
        return position
    end
    return position + vel * leadTime
end

local function getAimPosition(part, opts)
    if not part or not part.Parent or not part:IsA("BasePart") then return nil end
    opts = opts or {}
    if opts.skipPrediction then
        return part.Position
    end
    return getPredictedAimPosition(part) or part.Position
end

local ZombieTypeCache = setmetatable({}, { __mode = "k" })

local function GetZombieTypeFromModel(model)
    if not model or not model:IsA("Model") then return nil end

    -- PERFORMANCE: Return cached type if available
    local cached = ZombieTypeCache[model]
    if cached then return cached end

    local parent = model.Parent

    -- Cuirassier: any model under Zombies.Slim
    if parent and parent.Name == "Slim" and parent.Parent and parent.Parent.Name == "Zombies" then
        ZombieTypeCache[model] = "Cuirassier"
        return "Cuirassier"
    end

    -- Accepts the game's short names and the full display names.
    local function aliasType(raw)
        local t = string.lower(raw or "")
        if t == "normal" or t == "shambler" then return "Shambler"
        elseif t == "barrel" or t == "bomber" then return "Bomber"
        elseif t == "fast" or t == "runner" then return "Runner"
        elseif t == "sapper" or t == "zapper" then return "Zapper"
        elseif t == "igniter" then return "Igniter"
        elseif t == "cuirassier" then return "Cuirassier" end
        return nil
    end

    -- Agent types: check Agent folder inside the zombie model for Type
    local agent = model:FindFirstChild("Agent")
    if agent then
        local typeValue = agent:FindFirstChild("Type")
        if typeValue and typeValue:IsA("StringValue") then
            local result = aliasType(typeValue.Value)
            if result then
                ZombieTypeCache[model] = result
                return result
            end
        end
    end

    -- Fallback: check model attribute
    if typeof(model.GetAttribute) == "function" then
        local t = model:GetAttribute("Type")
        if type(t) == "string" then
            local result = aliasType(t)
            if result then
                ZombieTypeCache[model] = result
                return result
            end
        end
    end

    -- Fallback heuristics: single GetDescendants pass instead of 5-6 separate recursive FindFirstChild calls
    local result = "Shambler"
    local hasBarrel, hasLantern, hasSword, hasAxe, hasEye = false, false, false, false, false
    local _ipArr49 = model:GetChildren()
    for _ipI49 = 1, #_ipArr49 do local child = _ipArr49[_ipI49]
        local n = child.Name
        if n == "Barrel" then hasBarrel = true
        elseif n == "Whale Oil Lantern" then hasLantern = true
        elseif n == "Sword" then hasSword = true
        elseif n == "Axe" then hasAxe = true
        elseif n == "Eye" then hasEye = true
        end
    end
    if not (hasBarrel or hasLantern or hasSword or hasAxe or hasEye) then
        local _ipArr50 = model:GetDescendants()
        for _ipI50 = 1, #_ipArr50 do local desc = _ipArr50[_ipI50]
            local n = desc.Name
            if n == "Barrel" then hasBarrel = true
            elseif n == "Whale Oil Lantern" then hasLantern = true
            elseif n == "Sword" then hasSword = true
            elseif n == "Axe" then hasAxe = true
            elseif n == "Eye" then hasEye = true
            end
        end
    end
    if hasBarrel then result = "Bomber"
    elseif hasLantern then result = "Igniter"
    elseif hasSword then result = "Cuirassier"
    elseif hasAxe then result = "Zapper"
    elseif hasEye then result = "Runner"
    end

    ZombieTypeCache[model] = result
    return result
end
_G.GetZombieTypeFromModel = GetZombieTypeFromModel
-- Helper: check if model matches a given typeName
local function isZombieOfType(model, typeName)
    if not model or not model:IsA("Model") then return false end
    if type(typeName) ~= "string" then return false end

    -- Use the unified GetZombieTypeFromModel which has all detection logic
    local mappedType = GetZombieTypeFromModel(model)
    return mappedType == typeName
end

-- Helper: Check if a bomber is near any teammate (within radius)
local function isBomberNearTeammate(bomberModel, radius)
    if not bomberModel then return false end
    radius = radius or BOMBER_SAFE_RADIUS

    local bomberRefs = getCachedZombieParts(bomberModel)
    local bomberPart = bomberRefs and (bomberRefs.root or bomberRefs.torso or bomberRefs.anyPart) or nil
    if not bomberPart then return false end
    local bomberPos = bomberPart.Position

    local _ipArr51 = getCachedPlayers(false)
    for _ipI51 = 1, #_ipArr51 do local player = _ipArr51[_ipI51]
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - bomberPos).Magnitude
                if dist <= radius then
                    return true
                end
            end
        end
    end
    return false
end

-- Helper: Check if a bomber is near the local player (within radius)
local function isBomberNearSelf(bomberModel, radius)
    if not bomberModel then return false end
    radius = radius or BOMBER_SAFE_RADIUS

    local bomberRefs = getCachedZombieParts(bomberModel)
    local bomberPart = bomberRefs and (bomberRefs.root or bomberRefs.torso or bomberRefs.anyPart) or nil
    if not bomberPart then return false end
    local bomberPos = bomberPart.Position

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local dist = (hrp.Position - bomberPos).Magnitude
    return dist <= radius
end

-- Helper: Check if bomber should be skipped due to safety settings
local function shouldSkipBomberForSafety(model, zombieType)
    if zombieType ~= "Bomber" then return false end
    local bomberRefs = getCachedZombieParts(model)
    local bomberPart = bomberRefs and (bomberRefs.root or bomberRefs.torso or bomberRefs.anyPart) or nil

    if BOMBER_SAFE_TEAMMATES and isBomberNearTeammate(model, BOMBER_SAFE_RADIUS) then
        return true
    end

    if BOMBER_SAFE_SELF and isBomberNearSelf(model, BOMBER_SAFE_RADIUS) then
        return true
    end

    -- Check "Don't Shoot Near" whitelist - skip if any whitelisted player is near the bomber
    if #BomberSafetyWhitelist > 0 then
        local _ipArr52 = getCachedPlayers(false)
        for _ipI52 = 1, #_ipArr52 do local player = _ipArr52[_ipI52]
            if player then
                local isWhitelisted = false
                local _ipArr53 = BomberSafetyWhitelist
                for _ipI53 = 1, #_ipArr53 do local name = _ipArr53[_ipI53]
                    if player.Name == name or player.DisplayName == name then
                        isWhitelisted = true
                        break
                    end
                end
                if isWhitelisted then
                    local char = player.Character
                    if char and bomberPart then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (hrp.Position - bomberPart.Position).Magnitude
                            if dist <= BOMBER_SAFE_RADIUS then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    -- If SHOOT_BOMBER_NEAR_TEAMMATES is enabled, check whitelist or all teammates
    if SHOOT_BOMBER_NEAR_TEAMMATES then
        -- If whitelist has entries, only shoot if whitelisted player is near
        if #ShootBomberNearWhitelist > 0 then
            local whitelistedPlayerNear = false
            local _ipArr54 = getCachedPlayers(false)
            for _ipI54 = 1, #_ipArr54 do local player = _ipArr54[_ipI54]
                if player then
                    local isWhitelisted = false
                    local _ipArr55 = ShootBomberNearWhitelist
                    for _ipI55 = 1, #_ipArr55 do local name = _ipArr55[_ipI55]
                        if player.Name == name or player.DisplayName == name then
                            isWhitelisted = true
                            break
                        end
                    end
                    if isWhitelisted then
                        local char = player.Character
                        if char and bomberPart then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local dist = (hrp.Position - bomberPart.Position).Magnitude
                                if dist <= BOMBER_SAFE_RADIUS then
                                    whitelistedPlayerNear = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            -- Skip if no whitelisted player is near
            if not whitelistedPlayerNear then
                return true
            end
        else
            -- No whitelist, check any teammate
            if not isBomberNearTeammate(model, BOMBER_SAFE_RADIUS) then
                return true
            end
        end
    end

    return false
end

local _seenBombersBuf = {}
local BOMBER_RADIUS_DEFAULT_COLOR = c3rgb(255, 100, 0)
local BOMBER_RADIUS_TEAMMATE_COLOR = c3rgb(255, 255, 0)
local BOMBER_RADIUS_SELF_COLOR = c3rgb(255, 0, 0)
local BOMBER_RADIUS_ROTATION = CFrame.Angles(0, 0, mathRad(90))

local function getBomberRadiusPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function ensureBomberRadiusVisual(model)
    local visual = BomberRadiusVisuals[model]
    if visual and visual.Parent then
        return visual
    end

    visual = Instance.new("Part")
    visual.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("RadVis_" .. math.random(10000, 99999))
    visual.Shape = Enum.PartType.Cylinder
    visual.Size = v3new(0.2, BOMBER_SAFE_RADIUS * 2, BOMBER_SAFE_RADIUS * 2)
    visual.Anchored = true
    visual.CanCollide = false
    visual.Transparency = 0
    visual.Material = Enum.Material.Neon
    visual.Color = BOMBER_RADIUS_DEFAULT_COLOR
    visual.Parent = Workspace
    BomberRadiusVisuals[model] = visual
    return visual
end

local function getBomberRadiusColor(model)
    if BOMBER_SAFE_SELF and isBomberNearSelf(model, BOMBER_SAFE_RADIUS) then
        return BOMBER_RADIUS_SELF_COLOR
    end
    if BOMBER_SAFE_TEAMMATES and isBomberNearTeammate(model, BOMBER_SAFE_RADIUS) then
        return BOMBER_RADIUS_TEAMMATE_COLOR
    end
    return BOMBER_RADIUS_DEFAULT_COLOR
end

local function updateBomberRadiusVisualForModel(model)
    if not model or not model:IsA("Model") or GetZombieTypeFromModel(model) ~= "Bomber" then
        return
    end

    _seenBombersBuf[model] = true

    local bomberPart = getBomberRadiusPart(model)
    if not bomberPart then
        return
    end

    local bomberPos = bomberPart.Position
    local visual = ensureBomberRadiusVisual(model)
    visual.Size = v3new(0.2, BOMBER_SAFE_RADIUS * 2, BOMBER_SAFE_RADIUS * 2)
    visual.CFrame = cfNew(bomberPos.X, bomberPos.Y - 3, bomberPos.Z) * BOMBER_RADIUS_ROTATION
    visual.Color = getBomberRadiusColor(model)
end

local function scanBomberRadiusVisuals(zombiesFolder)
    local _ipArr56 = zombiesFolder:GetChildren()
    for _ipI56 = 1, #_ipArr56 do local topChild = _ipArr56[_ipI56]
        if topChild:IsA("Folder") then
            local _ipArr57 = topChild:GetChildren()
            for _ipI57 = 1, #_ipArr57 do local model = _ipArr57[_ipI57]
                updateBomberRadiusVisualForModel(model)
            end
        else
            updateBomberRadiusVisualForModel(topChild)
        end
    end
end

local function cleanupBomberRadiusVisuals()
    for model, visual in pairs(BomberRadiusVisuals) do
        if not _seenBombersBuf[model] or not model or not model.Parent then
            pcall(function() visual:Destroy() end)
            BomberRadiusVisuals[model] = nil
        end
    end
end

local function updateBomberRadiusVisuals()
    local results = table.pack(pcall(function()
        if not BOMBER_VISUALIZE_RADIUS then return end

        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        if not zombiesFolder then return end

        -- Reuse buffer instead of creating new table every call
        table.clear(_seenBombersBuf)

        scanBomberRadiusVisuals(zombiesFolder)
        cleanupBomberRadiusVisuals()
    end))
    if not results[1] then
        error(results[2], 0)
    end
    return _tableUnpack(results, 2, results.n)
end

local bomberVisualizationRunning = false
local bomberVisualizationThread = nil
local function stopBomberVisualization()
    bomberVisualizationRunning = false
    if bomberVisualizationThread then
        pcall(function() task.cancel(bomberVisualizationThread) end)
        bomberVisualizationThread = nil
    end
end
_G.ArreyStopBomberVisualization = stopBomberVisualization

local function startBomberVisualization()
    if bomberVisualizationThread then return end
    bomberVisualizationRunning = true
    bomberVisualizationThread = task.spawn(function()
        task.wait(0.1) -- Small yield so enabling stays responsive without startup spam
        while bomberVisualizationRunning and BOMBER_VISUALIZE_RADIUS do
            pcall(updateBomberRadiusVisuals)
            task.wait(0.5) -- Update at normal rate when active
        end
        bomberVisualizationThread = nil
    end)
end
_G.ArreyStartBomberVisualization = startBomberVisualization

-- Helper: Check if zombie is still spawning (skip if State == "Spawn")
local function isZombieSpawning(model)
    if not model then return false end
    -- Check direct State on model (workspace.Zombies.ZombieName.State)
    local state = model:FindFirstChild("State")
    if state and state:IsA("StringValue") and state.Value == "Spawn" then
        return true
    end
    -- Also check Agent.State (for some zombie types)
    local agent = model:FindFirstChild("Agent")
    if agent then
        local agentState = agent:FindFirstChild("State")
        if agentState and agentState:IsA("StringValue") and agentState.Value == "Spawn" then
            return true
        end
    end
    return false
end

local _nearestSelBuf = {}

local _saCandParts = {}
local _saCandModels = {}
local _saCandTypes = {}
local _saCandDistSq = {}
local _saCandPos = {}
local MAX_LOS_CHECKS_PER_SCAN = 3

local function getNearestSelectedZombie(range, selectionList, useFovFlag, fovChecker)
    local results = table.pack(pcall(function()
        range = range or MAX_TARGET_RANGE
        local rangeSq = range * range
        local cam = Workspace.CurrentCamera
        local originPos
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.Parent then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                originPos = head.Position
            end
        end
        if not originPos and cam then
            originPos = cam.CFrame.Position
        end
        if not originPos then
            return nil, nil, nil
        end
        local baseIgnore = buildBaseIgnore()
        local bestPart, bestDistSq, bestModel, bestType = nil, rangeSq + EPS, nil, nil

        -- PERF FIX: Reuse pre-allocated sel buffer; clear it without creating a new table
        local sel = _nearestSelBuf
        table.clear(sel)
        local selection = selectionList or SelectedShootTypes
        if type(selection) == "table" then
            local hasArrayValues = false
            local _ipArr58 = selection
            for _ipI58 = 1, #_ipArr58 do local t = _ipArr58[_ipI58]
                sel[t] = true
                hasArrayValues = true
            end
            if not hasArrayValues then
                for t, enabled in pairs(selection) do
                    if enabled then
                        sel[t] = true
                    end
                end
            end
        end
        if not next(sel) then
            return nil, nil, nil
        end
        -- choose FOV config (defaults to auto-shoot FOV)
        local useFov = (useFovFlag ~= nil) and useFovFlag or USE_FOV
        local fovFunc = fovChecker or isWorldPosInFov

        -- Scan real zombies using a short-lived flattened cache.
        local zombieModels, zombieModelCount = getCachedZombieModels()
        if zombieModelCount == 0 then
            return nil, nil, nil
        end

        local candCount = 0

        local function collectModel(model)
            if not model or not model.Parent or not model:IsA("Model") then return end
            -- Skip zombies that are still spawning
            if isZombieSpawning(model) then return end

            -- Use GetZombieTypeFromModel which checks GetAttribute("Type") first
            local matchedType = GetZombieTypeFromModel(model)

            -- Check if this zombie type is selected
            if not (matchedType and sel[matchedType]) then return end
            -- Check bomber safety before targeting (skip if too close to teammate/self)
            if shouldSkipBomberForSafety(model, matchedType) then return end

            local aimPart = findBestAimPart(model)
            if not (aimPart and aimPart:IsA("BasePart")) then return end

            local aimPos = getAimPosition(aimPart)
            if not aimPos then return end

            local offset = aimPos - originPos
            local dSq = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
            if dSq > rangeSq + EPS then return end

            if useFov and not fovFunc(aimPos) then return end

            candCount += 1
            _saCandParts[candCount] = aimPart
            _saCandModels[candCount] = model
            _saCandTypes[candCount] = matchedType
            _saCandDistSq[candCount] = dSq
            _saCandPos[candCount] = aimPos
        end

        for i = 1, zombieModelCount do
            collectModel(zombieModels[i])
        end

        if candCount == 0 then
            return nil, nil, nil
        end

        -- Closest-first insertion sort on the parallel buffers.
        for i = 2, candCount do
            local p, m, t, d = _saCandParts[i], _saCandModels[i], _saCandTypes[i], _saCandDistSq[i]
            local j = i - 1
            while j >= 1 and _saCandDistSq[j] > d do
                _saCandParts[j+1] = _saCandParts[j]
                _saCandModels[j+1] = _saCandModels[j]
                _saCandTypes[j+1] = _saCandTypes[j]
                _saCandDistSq[j+1] = _saCandDistSq[j]
                j -= 1
            end
            _saCandParts[j+1] = p
            _saCandModels[j+1] = m
            _saCandTypes[j+1] = t
            _saCandDistSq[j+1] = d
        end

        for i = 1, mathMin(candCount, MAX_LOS_CHECKS_PER_SCAN) do
            if hasClearShotOnPart(originPos, _saCandParts[i], _saCandModels[i], baseIgnore, _saCandPos[i]) then
                bestPart, bestDistSq, bestModel, bestType =
                    _saCandParts[i], _saCandDistSq[i], _saCandModels[i], _saCandTypes[i]
                break
            end
        end
        return bestPart, bestModel, bestType
    end))
    if not results[1] then
        error(results[2], 0)
    end
    return _tableUnpack(results, 2, results.n)
end

local _autoSaveCandidatePlayersBuf = {}
local _autoSaveCandidateRootsBuf = {}
local _autoSaveCandidateCount = 0
local _autoSaveCandidateCacheTime = -mathHuge
local AUTO_SAVE_CANDIDATE_CACHE_TTL = 0.1

local function isPlayerGrabbedOrPinned(userStates)
    if not userStates then
        return false
    end
    local grabbedVal = userStates:FindFirstChild("Grabbed")
    local pinVal = userStates:FindFirstChild("Pin")
    local grabbed = (grabbedVal and tonumber(grabbedVal.Value) or 0) ~= 0
    local pinnedVal = (pinVal and pinVal.Value) or ""
    local pinned = pinnedVal == "RunnerAttack" or pinnedVal == "RunnerClaw" or pinnedVal == "RunnerVomit"
    return grabbed or pinned
end

local function collectAutoSaveCandidates(originPos, wsPlayersFolder, baseIgnore)
    local now = time()
    if now - _autoSaveCandidateCacheTime < AUTO_SAVE_CANDIDATE_CACHE_TTL then
        return _autoSaveCandidatePlayersBuf, _autoSaveCandidateRootsBuf, _autoSaveCandidateCount
    end

    local count = 0
    local otherPlayers = getCachedPlayers(false)
    for i = 1, #otherPlayers do
        local player = otherPlayers[i]
        local shouldSavePlayer = true
        if #AutoSaveWhitelist > 0 then
            shouldSavePlayer = false
            local _ipArr59 = AutoSaveWhitelist
            for _ipI59 = 1, #_ipArr59 do local name = _ipArr59[_ipI59]
                if player.Name == name or player.DisplayName == name then
                    shouldSavePlayer = true
                    break
                end
            end
        end
        if shouldSavePlayer then
            local playerFolder = wsPlayersFolder:FindFirstChild(player.Name)
            local userStates = playerFolder and playerFolder:FindFirstChild("UserStates")
            if isPlayerGrabbedOrPinned(userStates) then
                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health >= 1 and character and character:IsA("Model") then
                    local playerRoot = character:FindFirstChild("HumanoidRootPart")
                    if playerRoot and playerRoot:IsA("BasePart") then
                        local hasClearToPlayer = hasClearShotOnPart(originPos, playerRoot, character, baseIgnore)
                        if hasClearToPlayer then
                            count = count + 1
                            _autoSaveCandidatePlayersBuf[count] = player
                            _autoSaveCandidateRootsBuf[count] = playerRoot
                        end
                    end
                end
            end
        end
    end

    for i = count + 1, #_autoSaveCandidatePlayersBuf do
        _autoSaveCandidatePlayersBuf[i] = nil
    end
    for i = count + 1, #_autoSaveCandidateRootsBuf do
        _autoSaveCandidateRootsBuf[i] = nil
    end

    _autoSaveCandidateCount = count
    _autoSaveCandidateCacheTime = now
    return _autoSaveCandidatePlayersBuf, _autoSaveCandidateRootsBuf, _autoSaveCandidateCount
end

local function getNearestZombieToSavePlayer(range)
    -- (unchanged from original)
    local cam = Workspace.CurrentCamera
    local originPos
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.Parent then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            originPos = head.Position
        end
    end
    if not originPos and cam then
        originPos = cam.CFrame.Position
    end
    if not originPos then
        return nil, nil, nil
    end
    local wsPlayersFolder = Workspace:FindFirstChild("Players")
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not wsPlayersFolder or not zombiesFolder then
        return nil, nil, nil
    end
    local baseIgnore = buildBaseIgnore()
    local candidatePlayers, candidateRoots, candidateCount = collectAutoSaveCandidates(originPos, wsPlayersFolder, baseIgnore)
    if candidateCount == 0 then
        return nil, nil, nil
    end
    local bestZombieTorso, bestZombieModel, bestPlayer, bestDist = nil, nil, nil, range + EPS
    local zombieModels, zombieModelCount = getCachedZombieModels()

    local function checkZombieModel(model)
        if not model or not model.Parent or not model:IsA("Model") then return end
        if isZombieSpawning(model) then return end

        local zombieTorso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
        if zombieTorso and zombieTorso:IsA("BasePart") then
            local zombiePos = getAimPosition(zombieTorso, { skipPrediction = true })
            for i = 1, candidateCount do
                local player = candidatePlayers[i]
                local playerRoot = candidateRoots[i]
                if player and playerRoot and playerRoot.Parent then
                    local d = (zombiePos - playerRoot.Position).Magnitude
                    if d <= range + EPS and d < bestDist then
                        local hasClearToZombie = hasClearShotOnPart(originPos, zombieTorso, model, baseIgnore)
                        if hasClearToZombie then
                            bestZombieTorso = zombieTorso
                            bestZombieModel = model
                            bestPlayer = player
                            bestDist = d
                        end
                    end
                end
            end
        end
    end

    for i = 1, zombieModelCount do
        checkZombieModel(zombieModels[i])
    end

    -- If no result from real zombies, fallback to Camera folder
    if not bestZombieTorso then
        local camFolder = Workspace:FindFirstChild("Camera")
        if camFolder then
            local cameraModels = camFolder:GetChildren()
            for i = 1, candidateCount do
                local player = candidatePlayers[i]
                local playerRoot = candidateRoots[i]
                if player and playerRoot and playerRoot.Parent then
                    for j = 1, #cameraModels do
                        local model = cameraModels[j]
                        if model:IsA("Model") and model.Name == "m_Zombie" then
                            -- Skip zombies that are still spawning
                            if isZombieSpawning(model) then
                                continue
                            end
                            local zombieTorso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
                            if zombieTorso and zombieTorso:IsA("BasePart") then
                                local zombiePos = getAimPosition(zombieTorso, { skipPrediction = true })
                                local d = (zombiePos - playerRoot.Position).Magnitude
                                if d <= range + EPS and d < bestDist then
                                    local hasClearToZombie = hasClearShotOnPart(originPos, zombieTorso, model, baseIgnore)
                                    if hasClearToZombie then
                                        bestZombieTorso = zombieTorso
                                        bestZombieModel = model
                                        bestPlayer = player
                                        bestDist = d
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestZombieTorso, bestZombieModel, bestPlayer
end
-- ShotsLoaded helper, findRemote, reload/watch functions (unchanged)
local function getShotsLoadedForTool(tool)
    if not tool then return 0 end
    local s = tool:FindFirstChild("ShotsLoaded")
    if s and (s:IsA("IntValue") or s:IsA("NumberValue")) then return s.Value end
    local wsPlayersFolder = Workspace:FindFirstChild("Players")
    if not wsPlayersFolder then return 0 end
    local playerFolder = wsPlayersFolder:FindFirstChild(LocalPlayer.Name)
    if not playerFolder then return 0 end
    local toolFolder = playerFolder:FindFirstChild(tool.Name)
    if not toolFolder then return 0 end
    local shots = toolFolder:FindFirstChild("ShotsLoaded")
    if shots and (shots:IsA("IntValue") or shots:IsA("NumberValue")) then return shots.Value end
    return 0
end
local function findRemoteForTool(tool)
    return getToolRemote(tool)
end

-- Special reload handlers for specific gun types
local function spamReloadUntil(tool, targetShots, useStartReload)
    if not tool then return end
    if reloadInProgress[tool] then return end
    reloadInProgress[tool] = true
    local shots = getShotsLoadedForTool(tool)
    local needReload = (targetShots > 2) and (shots < targetShots) or (shots == 0)
    if not needReload and targetShots <= 2 and shots ~= 0 then
        reloadInProgress[tool] = nil
        return
    end
    if targetShots > 2 and shots >= targetShots then
        reloadInProgress[tool] = nil
        return
    end
    local remote = getToolRemote(tool)
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    if useStartReload then
        pcall(function() remote:FireServer("StartReload") end)
        task.wait(0.1)
    end
    local attempts, maxAttempts = 0, 50
    while attempts < maxAttempts do
        if getShotsLoadedForTool(tool) >= targetShots then
            reloadInProgress[tool] = nil
            if tool and tool.Parent == LocalPlayer.Character then
                pcall(function() tool.Parent = LocalPlayer.Backpack end)
                task.wait(0.02)
                pcall(function() tool.Parent = LocalPlayer.Character end)
                task.wait(0.1)
            end
            return
        end
        pcall(function() remote:FireServer("Reload") end)
        task.wait(0.05)
        attempts = attempts + 1
    end
    reloadInProgress[tool] = nil
end

local function reloadNockGun(tool)
    -- Nock Gun: StartReload, then spam Reload until ShotsLoaded reaches 7 (only if under 7)
    return spamReloadUntil(tool, 7, true)
end

local function reloadDoubleBarrelPistol(tool)
    -- Double Barrel Pistol: spam Reload until ShotsLoaded reaches 2 (only if at 0)
    return spamReloadUntil(tool, 2, false)
end

local function reloadHorseArtilleryPistol(tool)
    -- Horse Artillery Pistol: StartReload, then spam Reload until ShotsLoaded reaches 2 (only if at 0)
    return spamReloadUntil(tool, 2, true)
end

local function quickUnequipReequip(tool)
    -- Quickly move tool from Character to Backpack and back
    if not tool or not tool.Parent then return end

    task.spawn(function()
        pcall(function()
            -- Move to Backpack
            tool.Parent = LocalPlayer.Backpack
        end)
        task.wait(0.02)  -- Very fast unequip
        pcall(function()
            -- Move back to Character
            tool.Parent = LocalPlayer.Character
        end)
    end)
end

local function reloadNormalGun(tool)
    -- All other guns: just fire Reload once
    if not tool then return end

    -- Prevent overlapping reloads for the same tool
    if reloadInProgress[tool] then return end
    reloadInProgress[tool] = true

    local remote = getToolRemote(tool)
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    pcall(function() remote:FireServer("Reload") end)

    -- When ShotsLoaded reaches 1, unequip and re-equip the gun
    task.wait(0.2)
    local shots = getShotsLoadedForTool(tool)
    if shots == 1 then
        quickUnequipReequip(tool)
    end

    reloadInProgress[tool] = nil
end
local ReloadStrategies = nil
local function tryReloadTool(tool)
    if not tool then return end
    if not AUTO_RELOAD_ENABLED then return end
    if not isGun(tool) then return end
    if not ReloadStrategies then
        ReloadStrategies = {
            ["Nock Gun"] = { fn = reloadNockGun, emptyOnly = false, target = 7 },
            ["Double Barrel Pistol"] = { fn = reloadDoubleBarrelPistol, emptyOnly = true },
            ["Horse Artillery Pistol"] = { fn = reloadHorseArtilleryPistol, emptyOnly = true },
        }
    end
    local shots = getShotsLoadedForTool(tool)
    local strat = ReloadStrategies[tool.Name]
    local shouldReload = (strat and (strat.emptyOnly and shots == 0 or not strat.emptyOnly and shots < strat.target))
        or (not strat and shots == 0)
    if shouldReload then
        task.spawn((strat and strat.fn) or reloadNormalGun, tool)
    end
end

local function disconnectAllToolWatches()
    for tool, conn in pairs(toolShotConnections) do
        pcall(function() conn:Disconnect() end)
        toolShotConnections[tool] = nil
    end
    -- Clear watchedTools so they can be re-watched if re-enabled
    table.clear(watchedTools)
end

local function watchShotsForTool(tool)
    if not tool then return end
    if not isGun(tool) then return end
    if watchedTools[tool] then return end
    -- LAG FIX: Do not attach shot watchers if Auto Reload is disabled
    if not AUTO_RELOAD_ENABLED then return end
    watchedTools[tool] = true
    local function attach(shotsObj, reloadRemote)
        if not shotsObj then return end
        local prevVal = (shotsObj.Value ~= nil) and shotsObj.Value or 0

        -- Initial check: reload if below threshold for this gun
        if AUTO_RELOAD_ENABLED and reloadRemote then
            pcall(tryReloadTool, tool)
        end

        local reloadDebounce = false
        local conn
        conn = shotsObj.Changed:Connect(function()
            local v = shotsObj.Value
            if AUTO_RELOAD_ENABLED and type(v) == "number" and type(prevVal) == "number" and v > prevVal then
                -- PERFORMANCE FIX: Cap notification spawns to prevent burst if value jumps significantly
                local notifyCount = mathMin(v - prevVal, 3)
                for i = 1, notifyCount do task.spawn(notifyReload) end
            end

            if reloadRemote and not reloadDebounce then
                reloadDebounce = true
                if AUTO_RELOAD_ENABLED then
                    pcall(tryReloadTool, tool)
                end
                task.delay(1.2, function() reloadDebounce = false end)
            end
            prevVal = v
        end)
        -- LAG FIX: Store connection for mass cleanup
        toolShotConnections[tool] = conn
        tool.AncestryChanged:Connect(function(_, parent)
            if not parent and conn then
                conn:Disconnect()
                toolShotConnections[tool] = nil
            end
        end)
    end
    local shotsInst = tool:FindFirstChild("ShotsLoaded")
    local remoteInst = tool:FindFirstChild("RemoteEvent")
    if shotsInst and (shotsInst:IsA("IntValue") or shotsInst:IsA("NumberValue")) then
        attach(shotsInst, remoteInst); return
    end
    local wsPlayersFolder = Workspace:FindFirstChild("Players")
    if not wsPlayersFolder then return end
    local playerFolder = wsPlayersFolder:FindFirstChild(LocalPlayer.Name)
    if not playerFolder then return end
    local toolFolder = playerFolder:FindFirstChild(tool.Name)
    local serverRemote = (toolFolder and toolFolder:FindFirstChild("RemoteEvent")) or remoteInst
    if toolFolder then
        local shots = toolFolder:FindFirstChild("ShotsLoaded")
        if shots and (shots:IsA("IntValue") or shots:IsA("NumberValue")) then attach(shots, serverRemote); return end
    end
end
-- Smoothing + animation helpers - improved with smoother easing
local _smoothLookQueue = {}
local _smoothLookConn = nil
local function _smoothLookStep()
    if #_smoothLookQueue == 0 then
        if _smoothLookConn then
            _smoothLookConn:Disconnect()
            _smoothLookConn = nil
        end
        return
    end
    local now = time()
    for i = #_smoothLookQueue, 1, -1 do
        local entry = _smoothLookQueue[i]
        local rootPart = entry.rootPart
        if not rootPart or not rootPart.Parent then
            table.remove(_smoothLookQueue, i)
            continue
        end

        local dt = now - entry.start
        local t = mathClamp(dt / entry.duration, 0, 1)

        local curPos = nil
        pcall(function() curPos = entry.getPosFunc() end)
        if not curPos then curPos = entry.initTarget end

        local desired = cfNew(rootPart.Position, v3new(curPos.X, rootPart.Position.Y, curPos.Z))
        local smoothT = entry.easeInOutQuint(t)
        local lerped = entry.startCFrame:Lerp(desired, smoothT)
        local safeCFrame = cfNew(rootPart.Position, rootPart.Position + lerped.LookVector)

        pcall(function() rootPart.CFrame = safeCFrame end)

        if t >= 1 then
            local finalPos = nil
            pcall(function() finalPos = entry.getPosFunc() end)
            if finalPos then
                pcall(function()
                    rootPart.CFrame = cfNew(rootPart.Position, rootPart.Position + cfNew(rootPart.Position, v3new(finalPos.X, rootPart.Position.Y, finalPos.Z)).LookVector)
                end)
            end
            table.remove(_smoothLookQueue, i)
        end
    end
end

local function _ensureSmoothLookConn()
    if _smoothLookConn then return end
    _smoothLookConn = RunService.RenderStepped:Connect(_smoothLookStep)
end

local function smoothLookAtDynamic(rootPart, getPosFunc, duration)
    if not rootPart or not getPosFunc then return end
    local ok, initTarget = pcall(getPosFunc)
    if not ok or not initTarget then return end

    local function easeInOutQuint(t)
        if t < 0.5 then
            return 16 * t * t * t * t * t
        else
            local f = (2 * t) - 2
            return 0.5 * f * f * f * f * f + 1
        end
    end

    table.insert(_smoothLookQueue, {
        rootPart = rootPart,
        getPosFunc = getPosFunc,
        duration = duration,
        start = time(),
        startCFrame = rootPart.CFrame,
        initTarget = initTarget,
        easeInOutQuint = easeInOutQuint
    })
    _ensureSmoothLookConn()
end
local animationCache = setmetatable({}, { __mode = "v" })
local animationCacheLastClean = 0
local function playAnimation(animId, animator)
    if not animId or not animator then return nil end
    local cacheKey = animId .. tostring(animator)

    -- Periodic cache cleanup (every 30 seconds)
    local now = time()
    if now - animationCacheLastClean > 30 then
        animationCacheLastClean = now
        for key, track in pairs(animationCache) do
            if not track or not track.IsPlaying then
                animationCache[key] = nil
            end
        end
    end

    -- Check cache first
    if animationCache[cacheKey] and animationCache[cacheKey].Parent then
        local track = animationCache[cacheKey]
        if track.IsPlaying then track:Stop(0.02) end
        track:Play(0.02, 1, 1)
        return track
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track
    local ok = pcall(function()
        track = animator:LoadAnimation(anim)
    end)
    anim:Destroy()
    if not ok or not track then return nil end
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.02, 1, 1)
    animationCache[cacheKey] = track
    return track
end
-- aimThenShootGun  Uses animations (Aim, Aiming, Fire) + remote:FireServer("Fire") with silent aim hooks
local function aimThenShootGun(targetModel, initialPart, tool, isPlayerTarget, savedPlayer)
    if not targetModel or not targetModel.Parent then return end
    if not initialPart or not initialPart.Parent or not initialPart:IsA("BasePart") then return end
    if not tool or not tool.Parent or not tool:IsDescendantOf(LocalPlayer.Character) then return end
    if not isGun(tool) then return end
    -- Bomber safety: abort if targeting a bomber that's near me or teammates
    local zombieType = GetZombieTypeFromModel and GetZombieTypeFromModel(targetModel) or nil
    if zombieType == "Bomber" and shouldSkipBomberForSafety(targetModel, zombieType) then
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    pcall(watchShotsForTool, tool)
    local remote = tool:FindFirstChild("RemoteEvent") or findRemoteForTool(tool)

    -- Discover animations from tool
    local animFolder = tool:FindFirstChild("Animations")
    local animAId, animBId, fireAnimId
    if animFolder then
        local aim = animFolder:FindFirstChild("Aim")
        local aiming = animFolder:FindFirstChild("Aiming")
        local fire = animFolder:FindFirstChild("Fire")
        if aim and aim:IsA("Animation") then animAId = aim.AnimationId end
        if aiming and aiming:IsA("Animation") then animBId = aiming.AnimationId end
        if fire and fire:IsA("Animation") then fireAnimId = fire.AnimationId end
    end
    -- Fallback animation IDs
    animAId = animAId or "rbxassetid://83511222574103"
    animBId = animBId or "rbxassetid://136849639865723"

    -- Origin function
    local function getAimOrigin()
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.Parent then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then return head.Position end
        end
        local cam = Workspace.CurrentCamera
        if cam then return cam.CFrame.Position end
        return nil
    end

    local currentTargetPart = initialPart
    local currentTargetModel = targetModel

    -- Helper to resolve aim position (with prediction for zombies, without for players)
    local function resolveAimPos(part)
        if not part or not part.Parent or not part:IsA("BasePart") then return nil end
        if isPlayerTarget then
            return getAimPosition(part, { skipPrediction = true })
        end
        return getAimPosition(part)
    end

    -- Wall check
    local origin = getAimOrigin()
    if CHECK_WALLS and origin and currentTargetPart and currentTargetPart.Parent then
        local baseIgnore = buildBaseIgnore()
        local hasClear = hasClearShotOnPart(origin, currentTargetPart, currentTargetModel, baseIgnore)
        if not hasClear then return end
    end

    -- Check zombie still alive
    local finalHum = currentTargetModel and currentTargetModel:FindFirstChildOfClass("Humanoid")
    if finalHum and finalHum.Health and finalHum.Health < 1 then return end

    -- Final bomber safety check right before firing
    if zombieType == "Bomber" and shouldSkipBomberForSafety(currentTargetModel, zombieType) then
        return
    end

    -- Set silent aim target so hooks redirect Mouse.Hit/Target/Raycast
    autoShootCurrentTarget = currentTargetPart
    autoShootCurrentModel = currentTargetModel
    autoShootActive = true

    -- Animation tracks
    local trackA, trackB, fireTrack

    -- Shared abort path: stop the aiming pose and release the silent-aim target
    local function abortShot()
        if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
    end

    -- Calculate timing based on AUTO_SHOOT_DELAY
    local totalDelay = AUTO_SHOOT_DELAY or 0.5
    local rotationTime = mathMax(totalDelay * 0.7, 0.2)

    -- Start Aim animation (trackA)
    trackA = playAnimation(animAId, animator)

    -- Smooth rotation to target
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local originalAutoRotate = humanoid.AutoRotate
        humanoid.AutoRotate = false

        local function getPosFunc()
            if currentTargetPart and currentTargetPart.Parent then
                return resolveAimPos(currentTargetPart)
            end
            return nil
        end

        -- Start rotation in parallel
        task.spawn(function()
            pcall(function() smoothLookAtDynamic(root, getPosFunc, rotationTime) end)
        end)

        -- Wait for Aim animation to finish briefly
        task.wait(0.15)

        -- Stop trackA and start trackB (Aiming pose)
        if trackA and trackA.IsPlaying then
            pcall(function() trackA:Stop(0.1) end)
        end

        trackB = playAnimation(animBId, animator)

        -- Wait remaining time for the total delay
        local remainingWait = totalDelay - 0.15 - 0.03
        if remainingWait > 0 then
            task.wait(remainingWait)
        end

        humanoid.AutoRotate = originalAutoRotate
    end

    -- Wait for shots to be loaded
    local WAIT_TIMEOUT = 3.0
    local waited = 0
    local POLL_INTERVAL = 0.06
    local shotsNow = getShotsLoadedForTool(tool)
    while (not shotsNow or shotsNow < 1) and waited < WAIT_TIMEOUT do
        if not tool or not tool.Parent then break end
        if not (USER_AUTO_SHOOT_TOGGLE or AUTO_SAVE_PLAYERS_ENABLED) then break end
        task.wait(POLL_INTERVAL)
        waited = waited + POLL_INTERVAL
        shotsNow = getShotsLoadedForTool(tool)
    end

    if not shotsNow or shotsNow < 1 then
        abortShot()
        return
    end

    -- Final checks before firing
    if not currentTargetPart or not currentTargetPart.Parent then
        abortShot()
        return
    end
    if not currentTargetModel or not currentTargetModel.Parent then
        abortShot()
        return
    end

    local hum = currentTargetModel:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health and hum.Health < 1 then
        abortShot()
        return
    end

    -- Play Fire animation
    if fireAnimId then
        fireTrack = playAnimation(fireAnimId, animator)
    end

    -- Fire the remote
    pcall(function()
        local modelRef = char:FindFirstChild("Model") or char
        local t = Workspace:GetServerTimeNow()
        local aimPos = resolveAimPos(currentTargetPart)
        if remote and aimPos then
            remote:FireServer("Fire", modelRef, aimPos, t)
        end
    end)

    -- Cleanup
    if fireTrack then task.delay(0.35, function() pcall(function() fireTrack:Stop(0.07) end) end) end
    if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end

    task.delay(0.1, function()
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
    end)
end

-- instantShootGun  Fires remote directly with silent aim (no animations for speed)
local function instantShootGun(targetModel, initialPart, tool, skipPrediction)
    if not targetModel or not targetModel.Parent then return end
    if not initialPart or not initialPart.Parent or not initialPart:IsA("BasePart") then return end
    if not tool or not tool.Parent or not tool:IsDescendantOf(LocalPlayer.Character) then return end
    if not isGun(tool) then return end
    -- Bomber safety: abort if targeting a bomber that's near me or teammates
    local zombieType = GetZombieTypeFromModel and GetZombieTypeFromModel(targetModel) or nil
    if zombieType == "Bomber" and shouldSkipBomberForSafety(targetModel, zombieType) then
        return
    end
    pcall(watchShotsForTool, tool)
    local char = LocalPlayer.Character
    if not char then return end
    local origin = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position) or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position)
    if origin and CHECK_WALLS then
        local baseIgnore = buildBaseIgnore()
        local hasClear = hasClearShotOnPart(origin, initialPart, targetModel, baseIgnore)
        if not hasClear then return end
    end
    -- additional check: alive
    if targetModel and (not targetModel.Parent) then return end
    local hum = (targetModel and targetModel:FindFirstChildOfClass("Humanoid")) or nil
    if hum and hum.Health and hum.Health < 1 then return end

    -- Set silent aim flags so hooks redirect Mouse.Hit/Target/Raycast
    autoShootCurrentTarget = initialPart
    autoShootCurrentModel = targetModel
    autoShootActive = true

    -- Get aim position
    local aimPos = getAimPosition(initialPart, skipPrediction and { skipPrediction = true }) or initialPart.Position

    -- Fire the remote directly
    pcall(function()
        local remote = tool:FindFirstChild("RemoteEvent") or findRemoteForTool(tool)
        local modelRef = char:FindFirstChild("Model") or char
        local t = Workspace:GetServerTimeNow()
        if remote and initialPart and initialPart.Parent then
            remote:FireServer("Fire", modelRef, aimPos, t)
        end
    end)

    -- Clear flags
    task.delay(0.05, function()
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
    end)
end
-- Cleanup function for profile load
local function cleanupConnections()
    local _ipArr60 = activeConnections
    for _ipI60 = 1, #_ipArr60 do local conn = _ipArr60[_ipI60]
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}
    watchedTools = setmetatable({}, { __mode = "k" })
    isAiming = false
    -- FIX: Clear base ignore cache so stale character refs are released
    _baseIgnoreCache = nil
    _baseIgnoreCacheTime = -mathHuge
end
-- MAIN LOOP  updated to use selected types rather than bombers only
local mainLoopRunning = false
local mainLoopThread = nil

local function stopMainLoop()
    mainLoopRunning = false
    if mainLoopThread then
        pcall(function() task.cancel(mainLoopThread) end)
        mainLoopThread = nil
    end
    isAiming = false
    pcall(function() clearActiveTargetVisuals() end)
end

local function shouldRunMainLoop()
    local hasSelectedShootTypes = SelectedShootTypes and #SelectedShootTypes > 0
    return AUTO_RELOAD_ENABLED or AUTO_SAVE_PLAYERS_ENABLED or (USER_AUTO_SHOOT_TOGGLE and hasSelectedShootTypes)
end

local function targetHasClearLOS(targetPart, targetModel, customIgnore)
    if not CHECK_WALLS then return true end
    if not targetPart or not targetPart.Parent then return false end
    local originPos = getWallCheckOrigin()
    if not originPos then return true end
    local ignoreList = customIgnore or buildBaseIgnore()
    local ok, res = pcall(function()
        return hasClearShotOnPart(originPos, targetPart, targetModel, ignoreList)
    end)
    return ok and res
end

local function startMainLoop()
    if mainLoopThread then return end
    mainLoopRunning = true
    mainLoopThread = task.spawn(function()
        while mainLoopRunning do
            -- LAG FIX: Immediately break if we no longer need to run
            if not shouldRunMainLoop() then
                mainLoopRunning = false
                break
            end
            local okRun, errRun = pcall(function()
                -- FIX: Skip all work (FindFirstChildOfClass, isGun, etc.) when every feature is off
                if not USER_AUTO_SHOOT_TOGGLE and not AUTO_SAVE_PLAYERS_ENABLED and not AUTO_RELOAD_ENABLED then
                    return
                end

                local equippedTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                local equippedIsGun = equippedTool and isGun(equippedTool)
                local shotsForEquipped = (equippedTool and equippedIsGun) and getShotsLoadedForTool(equippedTool) or 0

                -- Check if silent aim is handling targeting (don't auto-shoot if using silent aim)
                local hasSilentAimSelection = SILENT_AIM_ENABLED and (SilentAimSelectedTypes and #SilentAimSelectedTypes > 0)
                local usingSilentAimForZombies = hasSilentAimSelection
                local usingSilentAimForSave = SILENT_AIM_ENABLED and SILENT_AIM_SAVE_PLAYERS_ENABLED

                -- Only auto-shoot if NOT using silent aim for that feature
                local shouldAutoShootZombies = USER_AUTO_SHOOT_TOGGLE and (not usingSilentAimForZombies)
                local shouldAutoSavePlayers = AUTO_SAVE_PLAYERS_ENABLED and (not usingSilentAimForSave)

                local effectiveAutoShoot = (equippedTool ~= nil) and equippedIsGun and (shotsForEquipped >= 1) and (shouldAutoShootZombies or shouldAutoSavePlayers)
                -- Attempt to auto-reload on equip if requested
                if AUTO_RELOAD_ENABLED and equippedTool and equippedIsGun then
                pcall(tryReloadTool, equippedTool)
                end
                if effectiveAutoShoot and not isAiming then
                local targetPart, targetModel, isPlayerTarget, savedPlayer = nil, nil, false, nil
                -- Save players ALWAYS first (use pcall to avoid crashes from unexpected runtime errors)
                if shouldAutoSavePlayers then
                    local ok, zPart, zModel, pl = pcall(getNearestZombieToSavePlayer, MAX_SAVE_PLAYERS_RANGE)
                    if ok and zPart and zModel then targetPart, targetModel, isPlayerTarget, savedPlayer = zPart, zModel, true, pl end
                end
                -- Only check selected types if no save target found
                if not targetPart and shouldAutoShootZombies then
                    -- If no selection -> skip
                    if SelectedShootTypes and #SelectedShootTypes > 0 then
                    local sPart, sModel, sType = getNearestSelectedZombie(MAX_TARGET_RANGE)
                    if sPart and sModel then targetPart, targetModel, isPlayerTarget = sPart, sModel, false end
                    end
                end
                if targetPart and targetModel then
                    isAiming = true
                    -- update visuals immediately
                    pcall(function()
                    updateActiveTargetVisuals(targetModel, targetPart)
                    end)
                    -- smarter appear delay: poll during delay so we can abort quickly
                    local appearDelay = (isPlayerTarget and INSTANT_SAVE_PLAYERS_ENABLED and 0.1)
                    or (not isPlayerTarget and INSTANT_SHOOT_ENABLED and 0.1)
                    or APPEAR_DELAY
                    local startT = time()
                    local aborted = false
                    local targetZombieType = GetZombieTypeFromModel and GetZombieTypeFromModel(targetModel) or nil
                    while time() - startT < appearDelay do
                    -- abort if target removed
                    if not targetModel or not targetModel.Parent then aborted = true; break end
                    -- if target became dead
                    local hum = (targetModel and targetModel:FindFirstChildOfClass("Humanoid")) or nil
                    if hum and hum.Health and hum.Health < 1 then aborted = true; break end
                    -- Bomber safety: abort if targeting a bomber that enters safety zone
                    if targetZombieType == "Bomber" and shouldSkipBomberForSafety(targetModel, targetZombieType) then
                        aborted = true; break
                    end
                    -- if player target: ensure still grabbed
                    if isPlayerTarget and savedPlayer then
                        local wsPlayersFolder = Workspace:FindFirstChild("Players")
                        local playerFolder = (wsPlayersFolder and wsPlayersFolder:FindFirstChild(savedPlayer.Name)) or nil
                        local stillGrabbed = false
                        if playerFolder then
                        local userStates = playerFolder:FindFirstChild("UserStates")
                        if userStates then
                            local grabbedVal = userStates:FindFirstChild("Grabbed")
                            local pinVal = userStates:FindFirstChild("Pin")
                            local grabbed = (grabbedVal and tonumber(grabbedVal.Value) or 0) ~= 0
                            local pinState = (pinVal and pinVal.Value) or ""
                            local pinned = (pinState == "RunnerAttack" or pinState == "RunnerClaw" or pinState == "RunnerVomit")
                            stillGrabbed = grabbed or pinned
                        end
                        end
                        local plChar = savedPlayer.Character
                        local plHum = plChar and plChar:FindFirstChildOfClass("Humanoid")
                        if (not stillGrabbed) or (not plHum) or (plHum.Health < 1) then aborted = true; break end
                    end
                    if CHECK_WALLS then
                        if not targetHasClearLOS(targetPart, targetModel) then
                        aborted = true
                        break
                        end
                    end
                    task.wait(0.03)
                    end
                    if aborted then
                    pcall(function() clearActiveTargetVisuals() end)
                    isAiming = false
                    else
                    -- Final wall check before shooting
                    if CHECK_WALLS then
                        local freshIgnore = buildBaseIgnore()
                        if not targetHasClearLOS(targetPart, targetModel, freshIgnore) then
                        pcall(function() clearActiveTargetVisuals() end)
                        isAiming = false
                        end
                    end

                    -- Final bomber safety check
                    if isAiming and targetZombieType == "Bomber" and shouldSkipBomberForSafety(targetModel, targetZombieType) then
                        pcall(function() clearActiveTargetVisuals() end)
                        isAiming = false
                    end

                    -- Only proceed if still aiming (not aborted by wall check)
                    if isAiming then
                        if equippedTool and equippedTool.Parent and isGun(equippedTool) then
                        local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if currentTool and currentTool == equippedTool then
                            task.spawn(function()
                            local success, err = pcall(function()
                                if (isPlayerTarget and INSTANT_SAVE_PLAYERS_ENABLED) or (not isPlayerTarget and INSTANT_SHOOT_ENABLED) then
                                instantShootGun(targetModel, targetPart, currentTool, isPlayerTarget)
                                else
                                aimThenShootGun(targetModel, targetPart, currentTool, isPlayerTarget, savedPlayer)
                                end
                            end)
                            if not success then
                                warn("Error in shoot function: " .. tostring(err))
                            end
                            task.wait(0.05)
                            pcall(function() clearActiveTargetVisuals() end)
                            isAiming = false
                            end)
                        else
                            pcall(function() clearActiveTargetVisuals() end)
                            isAiming = false
                        end
                        else
                        pcall(function() clearActiveTargetVisuals() end)
                        isAiming = false
                        end
                    else
                        pcall(function() clearActiveTargetVisuals() end)
                        isAiming = false
                    end
                    isAiming = false
                    end
                end
                end
            end)
            if not okRun then
                local now = time()
                if now - (_lastGunLoopErrorWarn or 0) > 5 then
                    _lastGunLoopErrorWarn = now
                    warn("[Arrey] Gun loop tick error:", errRun)
                end
            end

            if not USER_AUTO_SHOOT_TOGGLE and not AUTO_SAVE_PLAYERS_ENABLED and not AUTO_RELOAD_ENABLED then
                task.wait(0.45)
            end
            task.wait(CHECK_INTERVAL)
        end
        mainLoopThread = nil
    end)
end

local function refreshMainLoop()
    if shouldRunMainLoop() then
        startMainLoop()
    else
        stopMainLoop()
    end
end
_G.ArreyRefreshMainLoop = refreshMainLoop

_G.ArreyClearActiveTargetVisuals = clearActiveTargetVisuals
_G.ArreyCreateTargetHighlight = createTargetHighlight
_G.ArreyCreateAimDot = createAimDot
_G.ArreyStartAimDotUpdateLoop = startAimDotUpdateLoop
_G.ArreyDisconnectAllToolWatches = disconnectAllToolWatches
_G.ArreyStopFovUpdateLoop = stopFovUpdateLoop

-- Attach watchers for tools that might be on character when script loads (and watch Equip)
local function monitorCharacterTools(char)
    if not char then return end
    -- Clean up existing connections for this character
    cleanupConnections()
    -- LAG FIX: If absolutely no gun features are enabled, do not monitor tools or attach watchers at all
    local gunFeaturesActive = AUTO_RELOAD_ENABLED or USER_AUTO_SHOOT_TOGGLE or AUTO_SAVE_PLAYERS_ENABLED or SILENT_AIM_ENABLED
    if not gunFeaturesActive then
        return
    end
    -- Attach hand mortar watcher once per character (not per tool) only if enabled
    if HAND_MORTAR_TIMING_ENABLED then
        pcall(function() attachHandMortarWatcher() end)
    end
    -- Watch existing tools
    local _ipArr61 = char:GetChildren()
    for _ipI61 = 1, #_ipArr61 do local c = _ipArr61[_ipI61]
        if c:IsA("Tool") then
            -- Watch guns
            if isGun(c) then
                -- LAG FIX: Only watch shots if auto reload is on
                if AUTO_RELOAD_ENABLED then
                    pcall(watchShotsForTool, c)
                end
                pcall(tryReloadTool, c)
                -- Equip listener
                local ok, eqConn = pcall(function()
                    return c.Equipped:Connect(function()
                        pcall(tryReloadTool, c)
                    end)
                end)
                if ok and eqConn then table.insert(activeConnections, eqConn) end
            end
        end
    end
    -- Set up new connections for tools added later
    local childAddedConn = char.ChildAdded:Connect(function(child)
        if child and child:IsA("Tool") then
            -- Watch guns added later
            if isGun(child) then
                -- LAG FIX: Only watch shots if auto reload is on
                if AUTO_RELOAD_ENABLED then
                    pcall(watchShotsForTool, child)
                end
                pcall(tryReloadTool, child)
                local ok, eqConn = pcall(function()
                    return child.Equipped:Connect(function()
                        pcall(tryReloadTool, child)
                    end)
                end)
                if ok and eqConn then table.insert(activeConnections, eqConn) end
            end
        end
    end)
    table.insert(activeConnections, childAddedConn)
end
-- Set up character monitoring
local function setupCharacterMonitoring()
    -- Disconnect any existing CharacterAdded connection if present
    local _ipArr62 = activeConnections
    for i = 1, #_ipArr62 do local conn = _ipArr62[i]
        if conn == characterAddedConn then
            pcall(function() conn:Disconnect() end)
            table.remove(activeConnections, i)
            break
        end
    end
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(monitorCharacterTools)
    table.insert(activeConnections, characterAddedConn)
    if LocalPlayer.Character then
        monitorCharacterTools(LocalPlayer.Character)
    end
end
-- Start the script
setupCharacterMonitoring()
refreshMainLoop()

-- ===== SILENT AIM HOOKS (ZOMBIE) =====

-- Silent Aim target update loop (updates current target for redirection)
local silentAimUpdateConn = nil
local silentAimFrameCounter = 0
local SILENT_AIM_UPDATE_INTERVAL = Library.IsMobile and 15 or 5 -- Update every N frames to reduce lag
local function stopSilentAimLoop()
    if silentAimUpdateConn then
        silentAimUpdateConn:Disconnect()
        silentAimUpdateConn = nil
    end
    silentAimFrameCounter = 0
    silentAimCurrentTarget = nil
    silentAimCurrentModel = nil
    silentAimIsPlayerTarget = false
    silentAimSavedPlayer = nil
    if TARGET_ESP_ENABLED and not autoShootActive then
        pcall(function() clearActiveTargetVisuals() end)
    end
end

local function shouldRunSilentAimLoop()
    if not (SILENT_AIM_ENABLED or HeadlessSilentAimEnabled) then return false end
    local hasZombieSelection = SILENT_AIM_ENABLED and SilentAimSelectedTypes and #SilentAimSelectedTypes > 0
    return hasZombieSelection or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED or HeadlessSilentAimEnabled
end

local function startSilentAimLoop()
    if silentAimUpdateConn then return end
    silentAimUpdateConn = RunService.Heartbeat:Connect(function()
        local hasZombieSelection = SILENT_AIM_ENABLED and (SilentAimSelectedTypes and #SilentAimSelectedTypes > 0)
        local active = (SILENT_AIM_ENABLED and (hasZombieSelection or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED)) or HeadlessSilentAimEnabled
        if not active then
            if silentAimCurrentTarget or silentAimCurrentModel or silentAimIsPlayerTarget or silentAimSavedPlayer then
                silentAimCurrentTarget = nil
                silentAimCurrentModel = nil
                silentAimIsPlayerTarget = false
                silentAimSavedPlayer = nil
            end
            return
        end

        -- Throttle updates to every N frames for performance
        silentAimFrameCounter = silentAimFrameCounter + 1
        if silentAimFrameCounter < SILENT_AIM_UPDATE_INTERVAL then return end
        silentAimFrameCounter = 0

        if not active then
            silentAimCurrentTarget = nil
            silentAimCurrentModel = nil
            silentAimIsPlayerTarget = false
            silentAimSavedPlayer = nil
            return
        end

        local equippedTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        local equippedIsGun = equippedTool and isGun(equippedTool)
        if not equippedIsGun then
            silentAimCurrentTarget = nil
            silentAimCurrentModel = nil
            return
        end

        local okRun, errRun = pcall(function()
            local targetPart, targetModel, isPlayerTarget, savedPlayer = nil, nil, false, nil

            -- Priority 0: Headless Horseman (Events tab toggle, guns only).
            -- Strictly the RIDER model: anything under the Horse model is
            -- rejected so shots never magnetize to the horse.
            if HeadlessSilentAimEnabled then
                local okB, bPart, bModel = pcall(function()
                    local findBoss = _G.ArreyFindHeadlessBoss
                    local boss = (type(findBoss) == "function" and findBoss()) or nil
                    if not (boss and boss.Parent) then return nil, nil end
                    local rider = boss:FindFirstChild("HeadlessHorseman")
                    if not (rider and rider.Parent) then return nil, nil end
                    local getBox = _G.ArreyGetHeadlessHitbox
                    local part = (type(getBox) == "function" and getBox()) or nil
                    local function isRiderPart(p)
                        return p and p:IsA("BasePart") and p.Parent
                            and p:FindFirstAncestor("HeadlessHorseman") == rider
                            and p:FindFirstAncestor("Horse") == nil
                    end
                    if not isRiderPart(part) then
                        part = rider:FindFirstChild("ZOMBIE_HITBOX")
                    end
                    if not isRiderPart(part) then return nil, nil end
                    return part, rider
                end)
                if okB and bPart and bModel then
                    targetPart, targetModel, isPlayerTarget = bPart, bModel, false
                end
            end

            -- Priority 1: Save players (if silent aim save players enabled)
            if SILENT_AIM_SAVE_PLAYERS_ENABLED and AUTO_SAVE_PLAYERS_ENABLED then
                local ok, zPart, zModel, pl = pcall(getNearestZombieToSavePlayer, MAX_SAVE_PLAYERS_RANGE)
                if ok and zPart and zModel then
                    targetPart, targetModel, isPlayerTarget, savedPlayer = zPart, zModel, true, pl
                end
            end

            -- Priority 2: Zombie targeting (if silent aim zombie enabled)
            if not targetPart and hasZombieSelection then
                if SilentAimSelectedTypes and #SilentAimSelectedTypes > 0 then
                    local sPart, sModel, sType = getNearestSelectedZombie(MAX_TARGET_RANGE, SilentAimSelectedTypes, SILENT_AIM_USE_FOV, isWorldPosInSilentAimFov)
                    if sPart and sModel then
                        -- Check bomber safety if targeting bomber with silent aim bomber near
                        local zombieType = GetZombieTypeFromModel and GetZombieTypeFromModel(sModel) or nil
                        local skipBomber = false
                        if zombieType == "Bomber" then
                            if SILENT_AIM_BOMBER_NEAR_ENABLED then
                                if not isBomberNearTeammate(sModel, BOMBER_SAFE_RADIUS) then
                                    skipBomber = true
                                end
                            elseif shouldSkipBomberForSafety(sModel, zombieType) then
                                skipBomber = true
                            end
                        end
                        if not skipBomber then
                            targetPart, targetModel, isPlayerTarget = sPart, sModel, false
                        end
                    end
                end
            end

            -- Wall check
            if targetPart and CHECK_WALLS then
                local origin = getWallCheckOrigin()
                if origin then
                    local baseIgnore = buildBaseIgnore()
                    local hasClear = hasClearShotOnPart(origin, targetPart, targetModel, baseIgnore)
                    if not hasClear then
                        targetPart = nil
                        targetModel = nil
                    end
                end
            end

            -- FOV check (Silent Aim-specific)
            if targetPart and SILENT_AIM_USE_FOV then
                local aimPos = getAimPosition(targetPart) or targetPart.Position
                if not isWorldPosInSilentAimFov(aimPos) then
                    targetPart = nil
                    targetModel = nil
                end
            end

            silentAimCurrentTarget = targetPart
            silentAimCurrentModel = targetModel
            silentAimIsPlayerTarget = isPlayerTarget
            silentAimSavedPlayer = savedPlayer

            -- Update visuals if target ESP is enabled and not fighting auto-shoot
            if TARGET_ESP_ENABLED then
                if targetPart and targetModel then
                    pcall(function() updateActiveTargetVisuals(targetModel, targetPart) end)
                elseif not autoShootActive then
                    -- Only clear visuals if auto shoot isn't currently using them
                    pcall(function() clearActiveTargetVisuals() end)
                end
            end

            -- Auto Aim: Make character look at target if enabled
            if SILENT_AIM_AUTO_AIM and targetPart and targetPart.Parent then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local aimPos = targetPart.Position
                        local flatAimPos = v3new(aimPos.X, hrp.Position.Y, aimPos.Z)
                        local lookDir = (flatAimPos - hrp.Position)
                        if lookDir.Magnitude > 0.1 then
                            hrp.CFrame = cfNew(hrp.Position, flatAimPos)
                        end
                    end
                end)
            end
        end)
        if not okRun then
            local now = time()
            if now - (_lastSilentAimErrorWarn or 0) > 5 then
                _lastSilentAimErrorWarn = now
                warn("[Arrey] Silent Aim tick error:", errRun)
            end
        end
    end)
end

local setupSilentAimHooks
local function refreshSilentAimLoop()
    if shouldRunSilentAimLoop() then
        setupSilentAimHooks()
        startSilentAimLoop()
    else
        stopSilentAimLoop()
    end
end
_G.ArreyRefreshSilentAimLoop = refreshSilentAimLoop

task.defer(function()
    task.wait(0.25)
    refreshSilentAimLoop()
end)

-- ===== SILENT AIM HOOKS =====
local silentAimOldNamecall = nil
local silentAimOldIndex = nil

-- Recursion guards to prevent C stack overflow
local inNamecallHook = false
local inIndexHook = false

setupSilentAimHooks = function()
    -- SAFE SILENT AIM (no global hookmetamethod).
    -- Old code hooked game __namecall/__index globally. In Guts & Blackpowder
    -- that trips the anti-cheat / breaks the client within seconds (every
    -- Workspace:Raycast and every RemoteEvent "Fire" got hijacked, including
    -- game-internal calls). Guns compute shots as
    --   remote:FireServer("Fire", model, self:GetMousePos(), time)
    -- so hooking the per-weapon GetMousePos closures via hookfunction redirects
    -- only gun aim with zero global surface. No Raycast hook, no Mouse hook.
    if type(hookfunction) ~= "function" then
        warn("[Arrey] Silent Aim needs hookfunction (missing on this executor)")
        return
    end
    local newcclosureFn = (type(newcclosure) == "function") and newcclosure or function(f) return f end
    _silentHookedGetMousePos = _silentHookedGetMousePos or setmetatable({}, { __mode = "k" })
    local function resolveTargetPos()
        if not (SILENT_AIM_ENABLED or HeadlessSilentAimEnabled) then return nil end
        local t = silentAimCurrentTarget
        if not t then return nil end
        local okPart, isPart = pcall(function() return t:IsA("BasePart") end)
        if not okPart or not isPart then return nil end
        local okPar, par = pcall(function() return t.Parent end)
        if not okPar or par == nil then return nil end
        local okPos, pos = pcall(function() return t.Position end)
        if not okPos or typeof(pos) ~= "Vector3" then return nil end
        local lead = tonumber(SA_PREDICTION_LEAD) or 0
        -- Headless Horseman always gets +0.2 auto lead: the boss rides fast
        -- and plain silent aim lands behind it. Rider only, never the horse.
        local isHeadless = false
        pcall(function()
            isHeadless = t.Name == "ZOMBIE_HITBOX"
                and t:FindFirstAncestor("Horse") == nil
                and t:FindFirstAncestor("HeadlessHorseman") ~= nil
        end)
        if isHeadless then
            lead = lead + (tonumber(HEADLESS_SILENT_LEAD) or 0.2)
        end
        if lead > 0 then
            local okV, vel = pcall(function() return t.AssemblyLinearVelocity end)
            if okV and typeof(vel) == "Vector3" and vel.Magnitude >= 2 then
                if lead > 1 then lead = 1 end
                pos = pos + vel * lead
            end
        end
        return pos
    end
    local function hookOne(fn)
        if not fn or _silentHookedGetMousePos[fn] then return end
        -- orig MUST receive the hookfunction return value: without this every
        -- passthrough call is orig(nil) -> "attempt to call a nil value",
        -- which breaks Flintlock update and disables shooting.
        local orig = nil
        local ok, res = pcall(function()
            return hookfunction(fn, newcclosureFn(function(self, ...)
                local redir = resolveTargetPos()
                if redir then return redir end
                return orig(self, ...)
            end))
        end)
        if ok and type(res) == "function" then
            orig = res
            _silentHookedGetMousePos[fn] = res
        end
    end
    -- Collect EVERY GetMousePos closure (one per weapon module: Flintlock,
    -- Revolver, Nockgun, MeleeBase, ...). The exclusive filtergc form returns
    -- only ONE of them, so union all scan forms with dedupe. Missing this
    -- meant only 1/6 guns got redirected.
    local seen = {}
    local fns = {}
    local function addFn(fn)
        if type(fn) == "function" and not seen[fn] then
            seen[fn] = true
            fns[#fns + 1] = fn
        end
    end
    if type(filtergc) == "function" then
        pcall(function()
            local r = filtergc("function", { Name = "GetMousePos" }, true)
            if type(r) == "function" then
                addFn(r)
            elseif type(r) == "table" then
                for _, v in pairs(r) do addFn(v) end
            end
        end)
        pcall(function()
            local r2 = filtergc("function", { Name = "GetMousePos" })
            if type(r2) == "function" then
                addFn(r2)
            elseif type(r2) == "table" then
                for _, v in pairs(r2) do addFn(v) end
            end
        end)
    end
    for i = 1, #fns do pcall(hookOne, fns[i]) end
    -- Late-loaded weapon modules (equipped after enable): rescan once after
    -- modules have had time to require.
    task.delay(3, function()
        if not (SILENT_AIM_ENABLED or HeadlessSilentAimEnabled) then return end
        local fns2, seen2 = {}, {}
        for fn in pairs(_silentHookedGetMousePos) do seen2[fn] = true end
        if type(filtergc) == "function" then
            pcall(function()
                local r = filtergc("function", { Name = "GetMousePos" })
                if type(r) == "table" then
                    for _, v in pairs(r) do
                        if type(v) == "function" and not seen2[v] then fns2[#fns2 + 1] = v end
                    end
                end
            end)
        end
        for i = 1, #fns2 do pcall(hookOne, fns2[i]) end
    end)
    if #fns == 0 then
        warn("[Arrey] Silent Aim: no GetMousePos closures found yet (equip a gun); will retry on next enable")
    end
    -- Debug probe (readable from outside the chunk): _G.ArreySilentDebug()
    _G.ArreySilentDebug = function()
        local n = 0
        local hookTbl = _silentHookedGetMousePos
        if hookTbl then for _ in pairs(hookTbl) do n = n + 1 end end
        local sel = 0
        pcall(function() sel = SilentAimSelectedTypes and #SilentAimSelectedTypes or 0 end)
        local hasT = false
        pcall(function() hasT = silentAimCurrentTarget ~= nil and silentAimCurrentTarget.Parent ~= nil end)
        return { hooked = n, enabled = SILENT_AIM_ENABLED == true, selected = sel, hasTarget = hasT }
    end
    -- Reachable from the Events tab (Headless Silent Aim toggle).
    _G.ArreySetupSilentAimHooks = setupSilentAimHooks
end


end -- End Auto Gun Aim Logic scope

do -- Gun Tab UI Section scope
local GunTab = Tabs.Main
    local function dictToArray(sel)
        local arr = {}
        if typeof(sel) == "table" then
            if #sel > 0 then
                local _ipArr63 = sel
                for _ipI63 = 1, #_ipArr63 do local v = _ipArr63[_ipI63] table.insert(arr, v) end
            else
                for k, v in next, sel do
                    if v then table.insert(arr, tostring(k)) end
                end
            end
        end
        return arr
    end

local refreshMainLoop = _G.ArreyRefreshMainLoop or function() end
local refreshSilentAimLoop = _G.ArreyRefreshSilentAimLoop or function() end
local startBomberVisualization = _G.ArreyStartBomberVisualization or function() end
local stopBomberVisualization = _G.ArreyStopBomberVisualization or function() end
local clearActiveTargetVisuals = _G.ArreyClearActiveTargetVisuals or function() end
local createTargetHighlight = _G.ArreyCreateTargetHighlight or function() end
local createAimDot = _G.ArreyCreateAimDot or function() end
local startAimDotUpdateLoop = _G.ArreyStartAimDotUpdateLoop or function() end
local disconnectAllToolWatches = _G.ArreyDisconnectAllToolWatches or function() end

local GunModSection, AutoShootSection, SilentAimSection, SavePlayersSection, SafetyTrollingSection, TargetsSection

-- PERFORMANCE FIX: Flag to suppress notifications during UI initialization
local GunTab_InitComplete = false

-- Silent Aim FOV GUI elements (local to UI section)
local silentAimFovGui = nil
local silentAimFovCircle = nil
local silentAimFovUpdateConn = nil
local function stopSilentAimFovLoop()
    if silentAimFovUpdateConn then
        silentAimFovUpdateConn:Disconnect()
        silentAimFovUpdateConn = nil
    end
    if silentAimFovGui then silentAimFovGui.Enabled = false end
end

-- Silent Aim whitelists
local SilentAimSavePlayersWhitelist = {} -- empty = all
local SilentAimBomberNearWhitelist = {} -- empty = all

-- Auto Save Players FOV settings
local AUTO_SAVE_USE_FOV = false
local AUTO_SAVE_SHOW_FOV = false
AUTO_SAVE_MOBILE_FOV = false
local AUTO_SAVE_FOV_SIZE = 50
local autoSaveFovGui = nil
local autoSaveFovCircle = nil
local autoSaveFovUpdateConn = nil
local function stopAutoSaveFovLoop()
    if autoSaveFovUpdateConn then
        autoSaveFovUpdateConn:Disconnect()
        autoSaveFovUpdateConn = nil
    end
    if autoSaveFovGui then autoSaveFovGui.Enabled = false end
end

-- Forward declarations for whitelist dropdown references (for mutual exclusion)
local DontShootNearWhitelistDropdown = nil
local ShootBomberNearWhitelistDropdown = nil
local ShootBomberNearTeammatesToggle = nil

-- Helper: Get available players excluding those in another whitelist
local function getAvailablePlayersExcluding(excludeList)
    local names = {}
    local _ipArr64 = Players:GetPlayers()
    for _ipI64 = 1, #_ipArr64 do local player = _ipArr64[_ipI64]
        if player ~= LocalPlayer then
            local isExcluded = false
            local _ipArr65 = excludeList or {}
            for _ipI65 = 1, #_ipArr65 do local excludedName = _ipArr65[_ipI65]
                if player.Name == excludedName or player.DisplayName == excludedName then
                    isExcluded = true
                    break
                end
            end
            if not isExcluded then
                table.insert(names, player.Name)
            end
        end
    end
    return names
end

local isRefreshingWhitelistDropdowns = false
local function refreshWhitelistDropdowns()
    -- Prevent infinite recursion - if we're already refreshing, don't re-enter
    if isRefreshingWhitelistDropdowns then return end
    isRefreshingWhitelistDropdowns = true

    pcall(function()
        if DontShootNearWhitelistDropdown and DontShootNearWhitelistDropdown.SetValues then
            local availableForDontShoot = getAvailablePlayersExcluding(ShootBomberNearWhitelist)
            table.insert(availableForDontShoot, 1, "None")
            DontShootNearWhitelistDropdown:SetValues(availableForDontShoot)
        end
    end)

    pcall(function()
        if ShootBomberNearWhitelistDropdown and ShootBomberNearWhitelistDropdown.SetValues then
            local availableForShootNear = getAvailablePlayersExcluding(BomberSafetyWhitelist)
            table.insert(availableForShootNear, 1, "None")
            ShootBomberNearWhitelistDropdown:SetValues(availableForShootNear)
        end
    end)

    isRefreshingWhitelistDropdowns = false
end

-- Helper: Lock/unlock toggle with notification
local function lockToggleWithNotify(toggle, title, reason)
    pcall(function()
        if Library then
            Library:Notify({
                Title = title,
                Description = reason,
                Time = 3,
                Icon = "lock",
            })
        end
    end)
    pcall(function()
        if toggle and toggle.SetDisabled then pcall(function() toggle:SetDisabled(true) end) end
    end)
end

local function unlockToggle(toggle)
    pcall(function()
        if toggle and toggle.SetDisabled then pcall(function() toggle:SetDisabled(false) end) end
    end)
end

-- Silent Aim FOV functions
local function ensureSilentAimFovGui()
    local entry = getFovCircle("silentAim", c3rgb(0, 200, 255))
    if not entry then return nil end
    silentAimFovGui, silentAimFovCircle = entry.gui, entry.frame
    return silentAimFovGui, silentAimFovCircle
end

local function getSilentAimFovScreenCenter()
    return getFovScreenCenterShared(SILENT_AIM_MOBILE_FOV)
end

local silentAimFovFrameCounter = 0
local SILENT_AIM_FOV_UPDATE_INTERVAL = 2 -- Update every N frames
local function ensureSilentAimFovUpdateLoop()
    if silentAimFovUpdateConn then return end
    -- PERF FIX: Only start loop if both Use FOV and Show FOV are enabled
    if not (SILENT_AIM_USE_FOV and SILENT_AIM_SHOW_FOV) then return end
    silentAimFovUpdateConn = RunService.RenderStepped:Connect(function()
        if not (SILENT_AIM_USE_FOV and SILENT_AIM_SHOW_FOV) then
            if silentAimFovGui then silentAimFovGui.Enabled = false end
            return
        end
        silentAimFovFrameCounter = silentAimFovFrameCounter + 1
        if silentAimFovFrameCounter < SILENT_AIM_FOV_UPDATE_INTERVAL then return end
        silentAimFovFrameCounter = 0
        pcall(function()
            local gui, circle = ensureSilentAimFovGui()
            if not gui or not circle then return end
            gui.Enabled = true
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local viewportSize = cam.ViewportSize
            local clamped = mathClamp(SILENT_AIM_FOV_SIZE, 10, 120)
            local sizePx = mathFloor((clamped / 40) * 250)
            circle.Size = UDim2.new(0, sizePx, 0, sizePx)
            local center = getSilentAimFovScreenCenter()
            circle.Position = UDim2.new(center.X / viewportSize.X, 0, center.Y / viewportSize.Y, 0)
        end)
    end)
end

local function updateSilentAimFovCircle()
    if not (SILENT_AIM_USE_FOV and SILENT_AIM_SHOW_FOV) then
        -- FIX: disconnect the RenderStepped loop entirely when not needed
        stopSilentAimFovLoop()
        return
    end
    ensureSilentAimFovUpdateLoop()
end

-- Replace the forward declaration stub with the real implementation
isWorldPosInSilentAimFov = function(worldPos)
    if not SILENT_AIM_USE_FOV then return true end
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    local viewportSize = cam.ViewportSize
    if not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then return true end
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local centerVec = getSilentAimFovScreenCenter()
    local dist = (v2new(screenPos.X, screenPos.Y) - centerVec).Magnitude
    local clamped = mathClamp(SILENT_AIM_FOV_SIZE, FOV_MIN_DEG, FOV_MAX_DEG)
    local sizePx = (clamped / 40) * 250
    local radius = sizePx / 2
    return dist <= radius
end

-- Auto Save FOV functions
local function ensureAutoSaveFovGui()
    local entry = getFovCircle("autoSave", c3rgb(0, 255, 100))
    if not entry then return nil end
    autoSaveFovGui, autoSaveFovCircle = entry.gui, entry.frame
    return autoSaveFovGui, autoSaveFovCircle
end

local function getAutoSaveFovScreenCenter()
    return getFovScreenCenterShared(AUTO_SAVE_MOBILE_FOV)
end

local autoSaveFovFrameCounter = 0
local AUTO_SAVE_FOV_UPDATE_INTERVAL = 2 -- Update every N frames
local function ensureAutoSaveFovUpdateLoop()
    if autoSaveFovUpdateConn then return end
    -- PERF FIX: Only start loop if both Use FOV and Show FOV are enabled
    if not (AUTO_SAVE_USE_FOV and AUTO_SAVE_SHOW_FOV) then return end
    autoSaveFovUpdateConn = RunService.RenderStepped:Connect(function()
        if not (AUTO_SAVE_USE_FOV and AUTO_SAVE_SHOW_FOV) then
            if autoSaveFovGui then autoSaveFovGui.Enabled = false end
            return
        end
        autoSaveFovFrameCounter = autoSaveFovFrameCounter + 1
        if autoSaveFovFrameCounter < AUTO_SAVE_FOV_UPDATE_INTERVAL then return end
        autoSaveFovFrameCounter = 0
        pcall(function()
            local gui, circle = ensureAutoSaveFovGui()
            if not gui or not circle then return end
            gui.Enabled = true
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local viewportSize = cam.ViewportSize
            local clamped = mathClamp(AUTO_SAVE_FOV_SIZE, 10, 120)
            local sizePx = mathFloor((clamped / 40) * 250)
            circle.Size = UDim2.new(0, sizePx, 0, sizePx)
            local center = getAutoSaveFovScreenCenter()
            circle.Position = UDim2.new(center.X / viewportSize.X, 0, center.Y / viewportSize.Y, 0)
        end)
    end)
end

local function updateAutoSaveFovCircle()
    if not (AUTO_SAVE_USE_FOV and AUTO_SAVE_SHOW_FOV) then
        -- FIX: disconnect the RenderStepped loop entirely when not needed
        stopAutoSaveFovLoop()
        return
    end
    ensureAutoSaveFovUpdateLoop()
end


if GunTab then
    -- ===== TARGET SETTINGS SECTION =====
    do -- Scoped block to reduce local register count
    TargetsSection = GunTab:AddGroupbox({ Side = "Right", Name = "Target Settings", Description = "Aim targets", IconName = "eye" })
    TargetsSection:AddDropdown('Targets_AimPart', {
        Text = "Target Part",
        Tooltip = "Choose which body part to aim for.",
        Values = {"Auto", "Head", "Torso", "Random"},
        Default = "Auto",
        Callback = function(val)
            TARGET_AIM_PART = val
            Library:Notify({
                Title = "Target settings",
                Description = "Set to " .. tostring(val),
                Time = 2,
                Icon = "target"
            })
        end
    })

    TargetsSection:AddToggle('Targets_BomberVisualize', {
        Text = "Visualize Bomber Explosion Radius",
        Tooltip = "Shows a circle around bombers showing the explosion radius.",
        Default = BOMBER_VISUALIZE_RADIUS,
        Callback = function(state)
            BOMBER_VISUALIZE_RADIUS = state
            if state then
                startBomberVisualization()
            else
                stopBomberVisualization()
                -- Clear all visuals when disabled
                for model, visual in pairs(BomberRadiusVisuals) do
                    pcall(function() visual:Destroy() end)
                end
                BomberRadiusVisuals = {}
            end
            Library:Notify({
                Title = "Bomber Visualization",
                Description = state and "Showing explosion radius" or "Hidden",
                Time = 2,
                Icon = state and "eye" or "eye-off"
            })
        end
    })

    TargetsSection:AddToggle('Targets_TargetEsp', {
        Text = "Target ESP",
        Tooltip = "Shows the zombie its currently targeting.",
        Default = TARGET_ESP_ENABLED,
        Callback = function(state)
            TARGET_ESP_ENABLED = state
            if not state then
                pcall(function() clearActiveTargetVisuals() end)
            else
                if activeAimModel then
                    pcall(function() createTargetHighlight(activeAimModel) end)
                end
            end
        end
    })

    TargetsSection:AddToggle('Targets_AimDot', {
        Text = "Show Aim Position",
        Tooltip = "Shows a red dot at the aim position.",
        Default = AIM_DOT_ENABLED,
        Callback = function(state)
            AIM_DOT_ENABLED = state
            if state then
                pcall(function() createAimDot() end)
                startAimDotUpdateLoop() -- LAG FIX: Explicitly start loop
                Library:Notify({
                    Title = "Aim Dot",
                    Description = "Aim position dot enabled",
                    Time = 2,
                    Icon = "target"
                })
            else
                pcall(function() clearAimDot() end)
                -- LAG FIX: Immediately disconnect aim dot loop instead of waiting one frame
                if aimDotUpdateConn then
                    pcall(function() aimDotUpdateConn:Disconnect() end)
                    aimDotUpdateConn = nil
                end
                Library:Notify({
                    Title = "Aim Dot",
                    Description = "Aim position dot disabled",
                    Time = 2,
                    Icon = "x"
                })
            end
        end
    })
    end -- End Target Settings scoped block

    -- ===== SAFETY & TROLLING SECTION =====
    do -- Scoped block to reduce local register count
    SafetyTrollingSection = GunTab:AddGroupbox({ Side = "Right", Name = "Safety & Trolling", Description = "Safety tools", IconName = "shield-alert" })
    -- Don't Shoot Bomber Near Teammates toggle
    SafetyTrollingSection:AddToggle('Safety_BomberSafeTeammates', {
        Text = "Don't Shoot Bomber Near Teammates",
        Tooltip = "Won't shoot bombers within the safety radius of teammates.",
        Default = BOMBER_SAFE_TEAMMATES,
        Callback = function(state)
            BOMBER_SAFE_TEAMMATES = state
            -- If enabled, lock and disable the opposite toggle
            if state then
                if SHOOT_BOMBER_NEAR_TEAMMATES then
                    SHOOT_BOMBER_NEAR_TEAMMATES = false
                    if ShootBomberNearTeammatesToggle then
                        pcall(function() ShootBomberNearTeammatesToggle:SetValue(false) end)
                    end
                end
                if ShootBomberNearTeammatesToggle then
                    lockToggleWithNotify(ShootBomberNearTeammatesToggle, "Safety Conflict", "Cannot use 'Shoot Bomber Near Teammates' while 'Don't Shoot' is enabled.")
                end
            else
                -- Unlock the opposite toggle
                if ShootBomberNearTeammatesToggle then
                    unlockToggle(ShootBomberNearTeammatesToggle)
                end
            end
            Library:Notify({
                Title = "Bomber Safety",
                Description = state and "Won't shoot bombers near teammates" or "Disabled",
                Time = 2,
                Icon = state and "shield" or "x"
            })
        end
    })

    -- Don't Shoot Near Teammates Whitelist (mutual exclusion with Shoot Near)
    DontShootNearWhitelistDropdown = SafetyTrollingSection:AddDropdown('Safety_DontShootNear_Whitelist', {
        Text = "Don't Shoot Near Teammates Whitelist",
        Tooltip = "Won't shoot bombers if these specific players are within blast radius",
        Values = (function()
            local names = {"None"}
            local _ipArr66 = Players:GetPlayers()
            for _ipI66 = 1, #_ipArr66 do local player = _ipArr66[_ipI66]
                if player ~= LocalPlayer then
                    table.insert(names, player.Name)
                end
            end
            return names
        end)(),
        Default = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            local _ipArr67 = dictToArray(selection)
            for _ipI67 = 1, #_ipArr67 do local name = _ipArr67[_ipI67]
                if name == "None" then
                    hasNone = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasNone then
                filtered = {}
            end
            BomberSafetyWhitelist = filtered
            -- Refresh the opposite whitelist to exclude these players (only after init complete)
            if GunTab_InitComplete then
                refreshWhitelistDropdowns()
                pcall(function()
                    Library:Notify({
                        Title = "Don't Shoot Near Whitelist",
                        Description = (#BomberSafetyWhitelist > 0) and ("Protecting: " .. table.concat(BomberSafetyWhitelist, ", ")) or "No players whitelisted",
                        Icon = "shield",
                        Time = 2
                    })
                end)
            end
        end
    })

    -- Shoot Bomber Near Teammates toggle
    ShootBomberNearTeammatesToggle = SafetyTrollingSection:AddToggle('Safety_ShootBomberNearTeammates', {
        Text = "Shoot Bomber Near Teammates",
        Tooltip = "ONLY shoot bombers when teammates are within the safety radius (trolling feature).",
        Default = SHOOT_BOMBER_NEAR_TEAMMATES,
        Callback = function(state)
            SHOOT_BOMBER_NEAR_TEAMMATES = state
            Library:Notify({
                Title = "Bomber Targeting",
                Description = state and "Will ONLY shoot bombers near teammates" or "Normal bomber targeting",
                Time = 2,
                Icon = state and "crosshair" or "target"
            })
        end
    })

    -- Lock it initially if Don't Shoot is enabled
    if BOMBER_SAFE_TEAMMATES and ShootBomberNearTeammatesToggle then
        task.defer(function()
            lockToggleWithNotify(ShootBomberNearTeammatesToggle, "Safety Conflict", "Cannot use while 'Don't Shoot Bomber Near Teammates' is enabled.")
        end)
    end

    -- Shoot Bomber Near Teammates Whitelist (mutual exclusion with Don't Shoot Near)
    ShootBomberNearWhitelistDropdown = SafetyTrollingSection:AddDropdown('Safety_ShootBomberNear_Whitelist', {
        Text = "Shoot Bomber Near Teammates Whitelist",
        Tooltip = "ONLY shoot bombers when these specific players are within blast radius",
        Values = (function()
            local names = {"None"}
            local _ipArr68 = Players:GetPlayers()
            for _ipI68 = 1, #_ipArr68 do local player = _ipArr68[_ipI68]
                if player ~= LocalPlayer then
                    table.insert(names, player.Name)
                end
            end
            return names
        end)(),
        Default = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            local _ipArr69 = dictToArray(selection)
            for _ipI69 = 1, #_ipArr69 do local name = _ipArr69[_ipI69]
                if name == "None" then
                    hasNone = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasNone then
                filtered = {}
            end
            ShootBomberNearWhitelist = filtered
            -- Refresh the opposite whitelist to exclude these players (only after init complete)
            if GunTab_InitComplete then
                refreshWhitelistDropdowns()
                pcall(function()
                    Library:Notify({
                        Title = "Shoot Near Whitelist",
                        Description = (#ShootBomberNearWhitelist > 0) and ("Will shoot bombers near: " .. table.concat(ShootBomberNearWhitelist, ", ")) or "Will shoot near any teammate",
                        Icon = "crosshair",
                        Time = 2
                    })
                end)
            end
        end
    })

    -- Don't Shoot Bomber Near Me toggle
    SafetyTrollingSection:AddDivider()
    SafetyTrollingSection:AddToggle('Safety_BomberSafeSelf', {
        Text = "Don't Shoot Bomber Near Me",
        Tooltip = "Won't shoot bombers within the safety radius of yourself.",
        Default = BOMBER_SAFE_SELF,
        Callback = function(state)
            BOMBER_SAFE_SELF = state
            Library:Notify({
                Title = "Bomber Safety",
                Description = state and "Won't shoot bombers near you" or "Disabled",
                Time = 2,
                Icon = state and "shield" or "x"
            })
        end
    })

    -- Bomber Safety Radius slider
    SafetyTrollingSection:AddSlider('Safety_BomberSafeRadius', {
        Text = "Bomber Safety Radius",
        Tooltip = "The radius (in studs) for all bomber safety/trolling features.",
        Rounding = 0,
        Default = BOMBER_SAFE_RADIUS or 10,
        Min = 5,
        Max = 30,
        Callback = function(val)
            BOMBER_SAFE_RADIUS = val
            -- Update any existing bomber visualizations to reflect new radius
            for model, visual in pairs(BomberRadiusVisuals) do
                if visual and visual.Parent then
                    visual.Size = v3new(0.2, BOMBER_SAFE_RADIUS * 2, BOMBER_SAFE_RADIUS * 2)
                end
            end
        end
    })
    end -- End Safety & Trolling scoped block

    -- ===== SAVE PLAYERS SECTION =====
    do -- Save Players Section scope
    SavePlayersSection = Tabs.Protection:AddGroupbox({ Side = "Left", Name = "Auto Save Players", Description = "Player protection", IconName = "shield" })
    local AutoSavePlayersToggle = SavePlayersSection:AddToggle('SavePlayers_AutoSavePlayers', {
        Text = "Auto Save Players",
        Tooltip = "Shoot Zombies Grabbing The player.",
        Default = AUTO_SAVE_PLAYERS_ENABLED,
        Callback = function(state)
            AUTO_SAVE_PLAYERS_ENABLED = state
            refreshMainLoop()
        end
    })
    _G.ArreyToggleElements.AutoSavePlayers = AutoSavePlayersToggle

    SavePlayersSection:AddToggle('SavePlayers_InstantSavePlayers', {
        Text = "Instant Save Players",
        Tooltip = "Instantly shoot the zombie grabbing the player (No Animations)",
        Default = INSTANT_SAVE_PLAYERS_ENABLED,
        Callback = function(state) INSTANT_SAVE_PLAYERS_ENABLED = state end
    })
    SavePlayersSection:AddSlider('SavePlayers_Delay', {
        Text = "Save Player Delay",
        Tooltip = "Delay before shooting when saving player (seconds)",
        Rounding = 1,
        Default = SAVE_PLAYER_DELAY or 0.5,
        Min = 0,
        Max = 5,
        Callback = function(val) SAVE_PLAYER_DELAY = val end
    })
    SavePlayersSection:AddSlider('SavePlayers_MaxRange', {
        Text = "Max Save Players Range",
        Tooltip = "Max save players distance.",
        Rounding = 0,
        Default = MAX_SAVE_PLAYERS_RANGE or 200,
        Min = 50,
        Max = 600,
        Callback = function(val) MAX_SAVE_PLAYERS_RANGE = val end
    })

    -- Auto Save Players FOV settings
    SavePlayersSection:AddToggle('SavePlayers_UseFov', {
        Text = "Use Fov",
        Tooltip = "Only save players if zombie is inside the FOV.",
        Default = AUTO_SAVE_USE_FOV,
        Callback = function(state)
            AUTO_SAVE_USE_FOV = state
            updateAutoSaveFovCircle()
        end
    })

    SavePlayersSection:AddToggle('SavePlayers_MobileFov', {
        Text = "Mobile Fov",
        Tooltip = "Fov stays in the middle (can be used in pc too).",
        Default = AUTO_SAVE_MOBILE_FOV,
        Callback = function(state)
            AUTO_SAVE_MOBILE_FOV = state
            updateAutoSaveFovCircle()
        end
    })

    SavePlayersSection:AddToggle('SavePlayers_ShowFov', {
        Text = "Show Fov",
        Tooltip = "Show the Auto Save FOV circle (green).",
        Default = AUTO_SAVE_SHOW_FOV,
        Callback = function(state)
            AUTO_SAVE_SHOW_FOV = state
            updateAutoSaveFovCircle()
        end
    })

    SavePlayersSection:AddSlider('SavePlayers_FovSize', {
        Text = "Fov Size",
        Tooltip = "Change the Auto Save FOV circle size.",
        Rounding = 0,
        Default = 50,
        Min = 10,
        Max = 120,
        Callback = function(val)
            AUTO_SAVE_FOV_SIZE = mathClamp(tonumber(val) or 50, 10, 120)
            -- RenderStepped loop picks up the new size automatically next frame
        end
    })

    -- Auto Save Whitelist Dropdown
    local function getAutoSavePlayerNames()
        local names = {"All"} -- Add All option first (default = save all)
        local _ipArr70 = Players:GetPlayers()
        for _ipI70 = 1, #_ipArr70 do local player = _ipArr70[_ipI70]
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end
    SavePlayersSection:AddDropdown('SavePlayers_Whitelist', {
        Text = "Auto Save Whitelist",
        Tooltip = "Only save these players",
        Values = getAutoSavePlayerNames(),
        Default = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            local _ipArr71 = dictToArray(selection)
            for _ipI71 = 1, #_ipArr71 do local name = _ipArr71[_ipI71]
                if name == "All" then
                    hasAll = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasAll then
                AutoSaveWhitelist = {}
            else
                AutoSaveWhitelist = filtered
            end
            if GunTab_InitComplete then
                pcall(function()
                    Library:Notify({
                        Title = "Auto Save Whitelist",
                        Description = (#AutoSaveWhitelist > 0) and ("Will only save: " .. table.concat(AutoSaveWhitelist, ", ")) or "Will save all players",
                        Icon = "users",
                        Time = 2
                    })
                end)
            end
        end
    })
    end -- End Save Players Section scope

    -- ===== SILENT AIM SECTION =====
    do -- Silent Aim Section scope
    SilentAimSection = GunTab:AddGroupbox({ Side = "Left", Name = "Silent Aim", Description = "Silent targeting", IconName = "crosshair" })
    local SilentAimToggle = SilentAimSection:AddToggle('SilentAim_Master', {
        Text = "Enable Silent Aim",
        Tooltip = "Master toggle for Silent Aim. Must be enabled for any silent aim features to work.",
        Default = SILENT_AIM_ENABLED,
        Callback = function(state)
            SILENT_AIM_ENABLED = state
            refreshSilentAimLoop()
            Library:Notify({
                Title = "Silent Aim",
                Description = state and "Silent Aim Enabled - Your shots will be redirected to targets" or "Silent Aim Disabled",
                Time = 2,
                Icon = state and "crosshair" or "x"
            })
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.SilentAim = SilentAimToggle


    -- Silent Aim zombie type dropdown (separate from auto shoot)
    SilentAimSection:AddDropdown('SilentAim_Type_Select', {
        Text = "Select Zombie Types",
        Tooltip = "Choose which zombie types Silent Aim will target.",
        Values = SilentAimZombieTypes,
        Default = {},
        Multi = true,
        Callback = function(selection)
            local newSelection = dictToArray(selection)
            SilentAimSelectedTypes = {}
            local _ipArr72 = newSelection
            for _ipI72 = 1, #_ipArr72 do local v = _ipArr72[_ipI72] table.insert(SilentAimSelectedTypes, tostring(v)) end
            local _ipArr73 = SilentAimZombieTypes
            for _ipI73 = 1, #_ipArr73 do local t = _ipArr73[_ipI73]
                local found = false
                local _ipArr74 = SilentAimSelectedTypes
                for _ipI74 = 1, #_ipArr74 do local s = _ipArr74[_ipI74] if s == t then found = true; break end end
                if not found then SilentAimEnabledTypes[t] = false else SilentAimEnabledTypes[t] = true end
            end
            if GunTab_InitComplete then
                pcall(function()
                    Library:Notify({
                        Title = "Silent Aim Selection",
                        Description = (#SilentAimSelectedTypes > 0) and ("Selected: " .. table.concat(SilentAimSelectedTypes, ", ")) or "No selection",
                        Icon = "crosshair",
                        Time = 1
                    })
                end)
            end
            refreshSilentAimLoop()
        end
    })

    -- Silent Aim FOV settings
    SilentAimSection:AddToggle('SilentAim_UseFov', {
        Text = "Use Fov",
        Tooltip = "Only target zombies inside the FOV for Silent Aim.",
        Default = SILENT_AIM_USE_FOV,
        Callback = function(state)
            SILENT_AIM_USE_FOV = state
            updateSilentAimFovCircle()
        end
    })

    SilentAimSection:AddToggle('SilentAim_MobileFov', {
        Text = "Mobile Fov",
        Tooltip = "Fov stays in the middle (can be used in pc too).",
        Default = SILENT_AIM_MOBILE_FOV,
        Callback = function(state)
            SILENT_AIM_MOBILE_FOV = state
            updateSilentAimFovCircle()
        end
    })

    SilentAimSection:AddDivider()
    SilentAimSection:AddToggle('SilentAim_ShowFov', {
        Text = "Show Fov",
        Tooltip = "Show the Silent Aim FOV circle (cyan).",
        Default = SILENT_AIM_SHOW_FOV,
        Callback = function(state)
            SILENT_AIM_SHOW_FOV = state
            updateSilentAimFovCircle()
        end
    })

    SilentAimSection:AddSlider('SilentAim_FovSize', {
        Text = "Fov Size",
        Tooltip = "Change the Silent Aim FOV circle size.",
        Rounding = 0,
        Default = 50,
        Min = 10,
        Max = 120,
        Callback = function(val)
            SILENT_AIM_FOV_SIZE = mathClamp(tonumber(val) or 50, 10, 120)
            -- RenderStepped loop picks up the new size automatically next frame
        end
    })

    SilentAimSection:AddToggle('SilentAim_SavePlayers', {
        Text = "Silent Aim Save Players",
        Tooltip = "Redirect shots to zombies grabbing players (higher priority than zombie targeting).",
        Default = SILENT_AIM_SAVE_PLAYERS_ENABLED,
        Callback = function(state)
            SILENT_AIM_SAVE_PLAYERS_ENABLED = state
            refreshSilentAimLoop()
            Library:Notify({
                Title = "Silent Aim Save Players",
                Description = state and "Shots will redirect to zombies grabbing players" or "Disabled",
                Time = 2,
                Icon = state and "shield" or "x"
            })
        end
    })

    -- Silent Aim Save Players Whitelist
    local function getSilentAimSavePlayersNames()
        local names = {"All"}
        local _ipArr75 = Players:GetPlayers()
        for _ipI75 = 1, #_ipArr75 do local player = _ipArr75[_ipI75]
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end

    SilentAimSection:AddDropdown('SilentAim_SavePlayers_Whitelist', {
        Text = "Save Players Whitelist",
        Tooltip = "Only redirect shots to save these players",
        Values = getSilentAimSavePlayersNames(),
        Default = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            local _ipArr76 = dictToArray(selection)
            for _ipI76 = 1, #_ipArr76 do local name = _ipArr76[_ipI76]
                if name == "All" then
                    hasAll = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasAll then
                SilentAimSavePlayersWhitelist = {}
            else
                SilentAimSavePlayersWhitelist = filtered
            end
            if GunTab_InitComplete then
                pcall(function()
                    Library:Notify({
                        Title = "Silent Aim Save Whitelist",
                        Description = (#SilentAimSavePlayersWhitelist > 0) and ("Will only save: " .. table.concat(SilentAimSavePlayersWhitelist, ", ")) or "Will save all players",
                        Icon = "users",
                        Time = 2
                    })
                end)
            end
        end
    })

    SilentAimSection:AddToggle('SilentAim_BomberNear', {
        Text = "Silent Aim Bomber Near Teammates",
        Tooltip = "Only redirect shots to bombers when they are near teammates.",
        Default = SILENT_AIM_BOMBER_NEAR_ENABLED,
        Callback = function(state)
            SILENT_AIM_BOMBER_NEAR_ENABLED = state
            refreshSilentAimLoop()
            Library:Notify({
                Title = "Silent Aim Bomber",
                Description = state and "Will only target bombers near teammates" or "Normal bomber targeting",
                Time = 2,
                Icon = state and "crosshair" or "x"
            })
        end
    })

    -- Silent Aim Bomber Near Whitelist
    local function getSilentAimBomberNearNames()
        local names = {"All"}
        local _ipArr77 = Players:GetPlayers()
        for _ipI77 = 1, #_ipArr77 do local player = _ipArr77[_ipI77]
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end

    SilentAimSection:AddDropdown('SilentAim_BomberNear_Whitelist', {
        Text = "Bomber Near Whitelist",
        Tooltip = "Only shoot bombers near these teammates",
        Values = getSilentAimBomberNearNames(),
        Default = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            local _ipArr78 = dictToArray(selection)
            for _ipI78 = 1, #_ipArr78 do local name = _ipArr78[_ipI78]
                if name == "All" then
                    hasAll = true
                else
                    table.insert(filtered, name)
                end
            end
            if hasAll then
                SilentAimBomberNearWhitelist = {}
            else
                SilentAimBomberNearWhitelist = filtered
            end
            if GunTab_InitComplete then
                pcall(function()
                    Library:Notify({
                        Title = "Silent Aim Bomber Near",
                        Description = (#SilentAimBomberNearWhitelist > 0) and ("Will shoot bombers near: " .. table.concat(SilentAimBomberNearWhitelist, ", ")) or "Will shoot near any teammate",
                        Icon = "crosshair",
                        Time = 2
                    })
                end)
            end
        end
    })

    SilentAimSection:AddSlider('SilentAim_Prediction', {
        Text = "Prediction",
        Tooltip  = "Movement lead time in seconds (0.20 is recommended)",
        Rounding = 2,
        Default = SA_PREDICTION_LEAD or 0,
        Min = 0,
        Max = 1,
        Callback = function(val)
            SA_PREDICTION_LEAD = mathClamp(tonumber(val) or 0, 0, 1)
        end
    })

    end -- End Silent Aim Section scope

    -- ===== AUTO SHOOT SECTION =====
    do -- Auto Shoot Section scope
    end -- End Auto Shoot Section scope

    -- ===== GUN MOD SECTION =====
    do -- Gun Mod Section scope
    GunModSection = GunTab:AddGroupbox({ Side = "Left", Name = "Gun Mod", Description = "Gun controls", IconName = "zap" })
    AutoShootSection = GunTab:AddGroupbox({ Side = "Right", Name = "Auto Shoot", Description = "Automatic firing", IconName = "target" })
    -- Multi-select dropdown for zombie types to auto-shoot
    AutoShootSection:AddDropdown('Shooting_Type_Select', {
        Text = "Select Zombie Types To AutoShoot",
        Tooltip = "Choose which zombie types to target.",
        Values = ShootTypeList,
        Default = {},
        Multi = true,
        Callback = function(selection)
            local newSelection = dictToArray(selection)
            SelectedShootTypes = {}
            local _ipArr79 = newSelection
            for _ipI79 = 1, #_ipArr79 do local v = _ipArr79[_ipI79] table.insert(SelectedShootTypes, tostring(v)) end
            -- Keep EnabledShootTypes consistent: if some types were deselected, disable them
            local _ipArr80 = ShootTypeList
            for _ipI80 = 1, #_ipArr80 do local t = _ipArr80[_ipI80]
                local found = false
                local _ipArr81 = SelectedShootTypes
                for _ipI81 = 1, #_ipArr81 do local s = _ipArr81[_ipI81] if s == t then found = true; break end end
                if not found then EnabledShootTypes[t] = false end
            end
            if GunTab_InitComplete then
                pcall(function()
                    Library:Notify({
                        Title = "Shooting Selection",
                        Description = (#SelectedShootTypes > 0) and ("Selected: " .. table.concat(SelectedShootTypes, ", ")) or "No selection",
                        Icon = "target",
                        Time = 1
                    })
                end)
            end
            refreshMainLoop()
        end
    })
    -- Toggle: enables/disables auto-shoot for selected types
    local AutoShootToggle = AutoShootSection:AddToggle('Shooting_Enable_Selected', {
        Text = "Enable Auto Shoot",
        Tooltip = "Enable Auto Shooting for the selected zombie types.",
        Default = USER_AUTO_SHOOT_TOGGLE,
        Callback = function(state)
            USER_AUTO_SHOOT_TOGGLE = state
            -- If disabled, clear per-type enabled flags
            if not state then
                for t, _ in pairs(EnabledShootTypes) do EnabledShootTypes[t] = false end
            else
                -- enable all selected types for simplicity
                local _ipArr82 = SelectedShootTypes
                for _ipI82 = 1, #_ipArr82 do local t = _ipArr82[_ipI82] EnabledShootTypes[t] = true end
            end
            refreshMainLoop()
        end
    })
    _G.ArreyToggleElements = _G.ArreyToggleElements or {}
    _G.ArreyToggleElements.AutoShoot = AutoShootToggle

    -- Keep "Instant Shoot" behavior but generalized: instant for any selected type
    local InstantShootToggle = AutoShootSection:AddToggle('Shooting_Instant', {
        Text = "Instant Shoot",
        Tooltip = "Instantly shoot selected zombies (No Animations)",
        Default = INSTANT_SHOOT_ENABLED,
        Callback = function(state)
            INSTANT_SHOOT_ENABLED = state
            APPEAR_DELAY = (INSTANT_SHOOT_ENABLED and 0.1) or APPEAR_DELAY_DEFAULT
        end
    })
    _G.ArreyToggleElements.InstantShoot = InstantShootToggle

    AutoShootSection:AddSlider('Shooting_AutoShootDelay', {
        Text = "Auto Shoot Delay",
        Tooltip = "Total time from aiming to firing (seconds). Set higher for smoother rotation.",
        Rounding = 1,
        Default = AUTO_SHOOT_DELAY or 0.5,
        Min = 0.5,
        Max = 5,
        Callback = function(val)
            AUTO_SHOOT_DELAY = mathClamp(tonumber(val) or 0.5, 0.3, 10)
        end
    })
    AutoShootSection:AddSlider('Shooting_Prediction', {
        Text = "Prediction",
        Tooltip = "Movement lead time in seconds (0.20 is recommended)",
        Rounding = 1,
        Default = PREDICTION_DISTANCE or 0,
        Min = 0,
        Max = 1,
        Callback = function(val)
            PREDICTION_DISTANCE = mathClamp(tonumber(val) or 0, 0, 50)
        end
    })
    AutoShootSection:AddSlider('Shooting_MaxRange', {
        Text = "Max Target Range",
        Tooltip = "Maximum detection range.",
        Rounding = 0,
        Default = MAX_TARGET_RANGE or 200,
        Min = 1,
        Max = 600,
        Callback = function(val) MAX_TARGET_RANGE = val end
    })
    -- ===== AUTO SHOOT FOV UI =====
    local UseFovToggle = AutoShootSection:AddToggle('Shooting_UseFov', {
        Text = "Use Fov",
        Tooltip = "Only target zombies inside the FOV.",
        Default = USE_FOV,
        Callback = function(state)
            USE_FOV = state
            updateFovCircle()
        end
    })
    _G.ArreyToggleElements.UseFov = UseFovToggle

    AutoShootSection:AddToggle('Shooting_MobileFov', {
        Text = "Mobile Fov",
        Tooltip = "Fov stays in the middle (can be used in pc too).",
        Default = MOBILE_FOV,
        Callback = function(state)
            MOBILE_FOV = state
            updateFovCircle()
        end
    })
    local ShowFovToggle = AutoShootSection:AddToggle('Shooting_ShowFov', {
        Text = "Show Fov",
        Tooltip = "Show the fov circle.",
        Default = SHOW_FOV,
        Callback = function(state)
            SHOW_FOV = state
            updateFovCircle()
        end
    })
    _G.ArreyToggleElements.ShowFov = ShowFovToggle

    AutoShootSection:AddSlider('Shooting_FovSize', {
        Text = "Fov Size",
        Tooltip = "Change the FOV circle size.",
        Rounding = 0,
        Default = 50,
        Min = 10,
        Max = 120,
        Callback = function(val)
            FOV_SIZE_DEG = mathClamp(tonumber(val) or 50, 10, 120)
            -- RenderStepped loop picks up the new size automatically next frame
        end
    })
    local WallCheckToggle = AutoShootSection:AddToggle('Shooting_WallCheck', {
        Text = "Wall Check (Raycast)",
        Tooltip = "Selected zombies behind walls will be ignored.",
        Default = CHECK_WALLS,
        Callback = function(state) CHECK_WALLS = state end
    })
    _G.ArreyToggleElements.WallCheck = WallCheckToggle

    local AutoReloadToggle = GunModSection:AddToggle('GunMod_AutoReload', {
        Text = "Auto Reload",
        Tooltip = "Automatically reload.",
        Default = AUTO_RELOAD_ENABLED,
        Callback = function(state)
            AUTO_RELOAD_ENABLED = state
            -- LAG FIX: If turning off, immediately disconnect all shot watchers
            if not state then
                disconnectAllToolWatches()
            end
            refreshMainLoop()
        end
    })
    _G.ArreyToggleElements.AutoReload = AutoReloadToggle
    end -- End Gun Mod Section scope
end

do -- Hand Mortar Feature scope (reduces local register count)
local HAND_MORTAR_TIMING_ENABLED = false
local HAND_MORTAR_DURATION = 5 -- seconds, displayed with milliseconds
local HAND_MORTAR_ANIM_IDS = {
    ["rbxassetid://117522716162453"] = true,
    ["rbxassetid://83761082384320"] = true,
}
local handMortarGui = nil
local handMortarUpdateConn = nil
local handMortarCameraConn = nil
local handMortarEndTick = nil
local handMortarRunning = false
local handMortarAnimConn = nil -- AnimationPlayed connection
-- Ensure PlayerGui exists
local function getPlayerGui()
    local _c = _G.ArreyCachedPlayerGui
    if _c and _c.Parent then return _c end
    if not LocalPlayer then return nil end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if pg then _G.ArreyCachedPlayerGui = pg end
    return pg
end
-- Detect first-person by checking camera position relative to head
local function isFirstPerson()
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return false end
    local dist = (cam.CFrame.Position - head.Position).Magnitude
    -- threshold: if camera is very close to head (inside head), treat as first-person
    return dist < 0.7
end
-- Create (or reuse) the BillboardGui + ScreenGui
local function createHandMortarGui()
    -- if existing and parented, return it
    if handMortarGui and ((handMortarGui.billboard and handMortarGui.billboard.Parent) or (handMortarGui.screen and handMortarGui.screen.Parent)) then
        return handMortarGui
    end
    local playerGui = getPlayerGui()
    -- BILLBOARD (for 3rd-person)
    local bg = Instance.new("BillboardGui")
    -- Use stealth name for anti-detection
    bg.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("TimerBB_" .. math.random(10000, 99999))
    bg.Size = UDim2.new(0, 90, 0, 60)
    bg.StudsOffset = v3new(2.2, 0, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = 200
    bg.Parent = playerGui
    local frame = Instance.new("Frame")
    frame.Name = "BG"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = bg
    local plate = Instance.new("Frame")
    plate.Name = "Plate"
    plate.Size = UDim2.new(0, 70, 0, 46)
    plate.Position = UDim2.new(0, 0, 0, 6)
    plate.BackgroundTransparency = 0.5
    plate.BackgroundColor3 = c3rgb(10, 10, 10)
    plate.BorderSizePixel = 0
    plate.Parent = frame
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(0, 10, 0, 36)
    barBg.Position = UDim2.new(0, 6, 0, 5)
    barBg.BackgroundColor3 = c3rgb(40, 40, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = plate
    barBg.AnchorPoint = v2new(0, 0)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = c3rgb(180, 80, 0)
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    fill.AnchorPoint = v2new(0, 1)
    fill.Position = UDim2.new(0, 0, 1, 0)
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Timer"
    lbl.Size = UDim2.new(0, 44, 0, 18)
    lbl.Position = UDim2.new(0, 22, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.TextScaled = false
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.Text = ""
    lbl.TextColor3 = c3rgb(255, 255, 255)
    lbl.Parent = plate
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 44, 0, 14)
    title.Position = UDim2.new(0, 22, 0, 27)
    title.BackgroundTransparency = 1
    title.TextScaled = false
    title.Font = Enum.Font.SourceSans
    title.TextSize = 12
    title.Text = "Hand Mortar"
    title.TextColor3 = c3rgb(200, 200, 200)
    title.Parent = plate
    -- SCREEN (for first-person)  overlay in PlayerGui
    local screen = Instance.new("ScreenGui")
    screen.ResetOnSpawn = false
    if _G.protectGUI then _G.protectGUI(screen) else screen.Parent = playerGui end -- Use stealth protection
    local sFrame = Instance.new("Frame")
    sFrame.Name = "Plate"
    sFrame.Size = UDim2.new(0, 120, 0, 60)
    -- Position: right of screen center (adjust as needed)
    sFrame.Position = UDim2.new(0.55, 0, 0.45, 0)
    sFrame.AnchorPoint = v2new(0, 0)
    sFrame.BackgroundTransparency = 0.25
    sFrame.BackgroundColor3 = c3rgb(10, 10, 10)
    sFrame.BorderSizePixel = 0
    sFrame.Parent = screen
    local sBarBg = Instance.new("Frame")
    sBarBg.Name = "BarBg"
    sBarBg.Size = UDim2.new(0, 10, 0, 36)
    sBarBg.Position = UDim2.new(0, 6, 0, 12)
    sBarBg.BackgroundColor3 = c3rgb(40, 40, 40)
    sBarBg.BorderSizePixel = 0
    sBarBg.Parent = sFrame
    local sFill = Instance.new("Frame")
    sFill.Name = "Fill"
    sFill.Size = UDim2.new(1, 0, 1, 0)
    sFill.Position = UDim2.new(0, 0, 0, 0)
    sFill.BackgroundColor3 = c3rgb(180, 80, 0)
    sFill.BorderSizePixel = 0
    sFill.Parent = sBarBg
    sFill.AnchorPoint = v2new(0, 1)
    sFill.Position = UDim2.new(0, 0, 1, 0)
    local sTimer = Instance.new("TextLabel")
    sTimer.Name = "Timer"
    sTimer.Size = UDim2.new(0, 80, 0, 24)
    sTimer.Position = UDim2.new(0, 22, 0, 12)
    sTimer.BackgroundTransparency = 1
    sTimer.TextScaled = false
    sTimer.Font = Enum.Font.SourceSansBold
    sTimer.TextSize = 18
    sTimer.Text = ""
    sTimer.TextColor3 = c3rgb(255, 255, 255)
    sTimer.Parent = sFrame
    local sTitle = Instance.new("TextLabel")
    sTitle.Name = "Title"
    sTitle.Size = UDim2.new(0, 80, 0, 16)
    sTitle.Position = UDim2.new(0, 22, 0, 38)
    sTitle.BackgroundTransparency = 1
    sTitle.TextScaled = false
    sTitle.Font = Enum.Font.SourceSans
    sTitle.TextSize = 12
    sTitle.Text = "Hand Mortar"
    sTitle.TextColor3 = c3rgb(200, 200, 200)
    sTitle.Parent = sFrame
    handMortarGui = {
        billboard = bg,
        screen = screen,
    }
    -- hide both initially; startHandMortarTimer will set visibility
    bg.Enabled = false
    screen.Enabled = false
    return handMortarGui
end
local function destroyHandMortarGui()
    if handMortarUpdateConn then
        pcall(function() handMortarUpdateConn:Disconnect() end)
        handMortarUpdateConn = nil
    end
    if handMortarCameraConn then
        pcall(function() handMortarCameraConn:Disconnect() end)
        handMortarCameraConn = nil
    end
    if handMortarGui then
        if handMortarGui.billboard and handMortarGui.billboard.Parent then
            pcall(function() handMortarGui.billboard:Destroy() end)
        end
        if handMortarGui.screen and handMortarGui.screen.Parent then
            pcall(function() handMortarGui.screen:Destroy() end)
        end
        handMortarGui = nil
    end
    handMortarRunning = false
    handMortarEndTick = nil
end
-- Start/restart the timer for given duration (seconds, float)
local function startHandMortarTimer(duration)
    if not HAND_MORTAR_TIMING_ENABLED then return end
    if not duration or type(duration) ~= "number" then duration = HAND_MORTAR_DURATION end
    -- create gui if not present
    local gui = createHandMortarGui()
    -- attach billboard to head if possible
    local char = LocalPlayer.Character
    if char then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if head and head:IsA("BasePart") and gui.billboard then
            gui.billboard.Adornee = head
        end
    end
    -- mark end tick
    handMortarEndTick = time() + duration
    handMortarRunning = true
    -- Decide initial visibility depending on first/third person
    local function updateVisibility()
        local fp = isFirstPerson()
        if gui.billboard then gui.billboard.Enabled = not fp end
        if gui.screen then gui.screen.Enabled = fp end
    end
    updateVisibility()
    -- Listen for camera changes so it toggles during countdown
    if handMortarCameraConn then
        -- already listening
    else
        handMortarCameraConn = RunService.RenderStepped:Connect(function()
            if not handMortarRunning then return end
            if handMortarGui then
                local fp = isFirstPerson()
                if handMortarGui.billboard then handMortarGui.billboard.Enabled = not fp end
                if handMortarGui.screen then handMortarGui.screen.Enabled = fp end
            end
        end)
    end
    -- ensure update connection for fill + text
    if handMortarUpdateConn then
        -- already updating; just restart (the loop will pick new end tick)
        return
    end
    handMortarUpdateConn = RunService.RenderStepped:Connect(function()
        if not handMortarRunning or not handMortarGui then
            destroyHandMortarGui()
            return
        end
        local remaining = mathMax(0, handMortarEndTick - time())
        local ratio = remaining / duration
        ratio = mathClamp(ratio, 0, 1)
        pcall(function()
            -- billboard
            if handMortarGui.billboard and handMortarGui.billboard.Parent then
                local plate = handMortarGui.billboard:FindFirstChild("BG") and handMortarGui.billboard.BG:FindFirstChild("Plate")
                if plate then
                    local barBg = plate:FindFirstChild("BarBg")
                    if barBg then
                        local fillFrame = barBg:FindFirstChild("Fill")
                        if fillFrame then
                            fillFrame.Size = UDim2.new(1, 0, ratio, 0)
                        end
                    end
                    local timerLabel = plate:FindFirstChild("Timer")
                    if timerLabel then
                        local ms = mathFloor(remaining * 1000 + 0.5)
                        local sec = mathFloor(ms / 1000)
                        local remMs = ms - sec * 1000
                        timerLabel.Text = strFormat("%d.%03ds", sec, remMs)
                    end
                end
            end
            -- screen
            if handMortarGui.screen and handMortarGui.screen.Parent then
                local sFrame = handMortarGui.screen:FindFirstChild("Plate")
                if sFrame then
                    local sBarBg = sFrame:FindFirstChild("BarBg")
                    if sBarBg then
                        local sFill = sBarBg:FindFirstChild("Fill")
                        if sFill then
                            sFill.Size = UDim2.new(1, 0, ratio, 0)
                        end
                    end
                    local sTimer = sFrame:FindFirstChild("Timer")
                    if sTimer then
                        local ms = mathFloor(remaining * 1000 + 0.5)
                        local sec = mathFloor(ms / 1000)
                        local remMs = ms - sec * 1000
                        sTimer.Text = strFormat("%d.%03ds", sec, remMs)
                    end
                end
            end
        end)
        if remaining <= 0 then
            -- finished
            destroyHandMortarGui()
        end
    end)
end
---------------------------------------------------------------------
---------------------------------------------------------------------
local function disconnectHandMortarWatcher()
    if handMortarAnimConn then
        pcall(function() handMortarAnimConn:Disconnect() end)
        handMortarAnimConn = nil
    end
end

local function attachHandMortarWatcher()
    if not HAND_MORTAR_TIMING_ENABLED then return end
    -- We only need one AnimationPlayed connection; ignore extra calls
    if handMortarAnimConn then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local function onAnimPlayed(track)
        local anim = track and track.Animation
        if not anim then return end
        local id = string.lower(tostring(anim.AnimationId or ""))
        -- If this is one of our Hand Mortar fuse animations, wait 1s then start the 5s countdown
        if HAND_MORTAR_ANIM_IDS[id] then
            -- we wait 1s from the animation start, then show the 5s countdown
            task.delay(1, function()
                -- safety checks
                if not HAND_MORTAR_TIMING_ENABLED then return end
                if not LocalPlayer.Character then return end
                -- start the 5s countdown after 1 second delay
                startHandMortarTimer(HAND_MORTAR_DURATION)
            end)
        end
    end
    local ok, conn = pcall(function()
        return hum.AnimationPlayed:Connect(onAnimPlayed)
    end)
    if ok and conn then
        handMortarAnimConn = conn
    end
end
local handMortarCharConnection = nil
local function setupHandMortarCharConnection()
    if handMortarCharConnection then
        pcall(function() handMortarCharConnection:Disconnect() end)
    end
    handMortarCharConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.1)
        disconnectHandMortarWatcher()
        if HAND_MORTAR_TIMING_ENABLED then
            attachHandMortarWatcher()
        end
        destroyHandMortarGui()
    end)
end
setupHandMortarCharConnection()
-- initial attach if character already loaded
pcall(function()
    if HAND_MORTAR_TIMING_ENABLED then
        attachHandMortarWatcher()
    end
end)
-- UI: Misc section and toggle (only if GunTab exists)
if GunTab then
    MiscGunSection = GunTab:AddGroupbox({ Side = "Left", Name = "Misc", Description = "Extra gun settings", IconName = "settings" })
    -- UI Toggle
    MiscGunSection:AddToggle('Misc_HandMortarTiming', {
        Text = "Hand Mortar Timing",
        Tooltip = "Shows The Timer Of The Mortar Before Blowing Up.",
        Default = HAND_MORTAR_TIMING_ENABLED,
        Callback = function(state)
            HAND_MORTAR_TIMING_ENABLED = state
            if state then
                attachHandMortarWatcher()
            else
                disconnectHandMortarWatcher()
                -- cleanup UI if disabled
                destroyHandMortarGui()
            end
        end
    })
end
end -- End Hand Mortar Feature scope
-- End hand mortar feature

-- PERFORMANCE FIX: Mark Gun Tab initialization as complete to enable notifications
GunTab_InitComplete = true

_G.ArreyGunUIReady = true

end -- End Gun Tab UI Section scope
end)
end
-- ==================== end Gun Modifiers port ====================

-- First autoload ran before the UI existed; re-apply now that every element
-- is built (restores late-created elements + stashes lazy toggle keybinds).
do
    local t0 = os.clock()
    while not _G.ArreyGunUIReady and os.clock() - t0 < 5 do task.wait(0.1) end
end

_G.ArreySuppressConfigNotify = true
local _origNotify = Library.Notify
Library.Notify = function() end -- hides the "Auto loaded config" popup
pcall(function() SaveManager:LoadAutoloadConfig() end)
task.wait(0.5)
Library.Notify = _origNotify
pcall(function()
    if SaveManager.ApplyPendingKeybinds then
        SaveManager:ApplyPendingKeybinds()
    end
end)
-- arm autosave only after the load's silent window (0.75s) has passed
task.delay(1.2, function()
    _G.ArreySuppressConfigNotify = false
    _G.ArreyAutoSaveArmed = true
end)

-- ===== LOADING SCREEN done (hub built) =====
pcall(function()
    if ArreyLoading then
        ArreyLoading:SetMessage("Ready")
        ArreyLoading:SetDescription("Guts & BlackPowder")
        ArreyLoading:SetCurrentStep(4)
    end
end)
task.wait(0.35)
pcall(function()
    if ArreyLoading then
        ArreyLoading:Destroy()
        ArreyLoading = nil
    end
end)

JD_NOTIFY(function(title, message, duration, kind)
    local parent = if gethui then gethui() else game:GetService("CoreGui")
    local TS = game:GetService("TweenService")
    local gui = parent:FindFirstChild("JnkieModernNotifications") or Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent = "JnkieModernNotifications", false, 120, parent
    local holder = gui:FindFirstChild("Holder") or Instance.new("Frame")
    holder.Name, holder.BackgroundTransparency = "Holder", 1
    holder.AnchorPoint, holder.Position = Vector2.new(1, 0), UDim2.new(1, -16, 0, 16)
    holder.Size = UDim2.new(0, math.min(320, math.max(180, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 360) - 24)), 1, -32)
    holder.Parent = gui
    if not holder:FindFirstChildOfClass("UIListLayout") then
        local list = Instance.new("UIListLayout", holder)
        list.VerticalAlignment, list.Padding = Enum.VerticalAlignment.Top, UDim.new(0, 8)
    end
    local color = ({Info=Color3.fromRGB(100,160,255), Success=Color3.fromRGB(70,210,110), Warning=Color3.fromRGB(255,190,60), Error=Color3.fromRGB(255,80,90)})[kind] or Color3.fromRGB(100,160,255)
    local body = tostring(message or ""):sub(1,400)
    local height = math.clamp(game:GetService("TextService"):GetTextSize(body, 13, Enum.Font.Gotham, Vector2.new(holder.Size.X.Offset - 40, 1000)).Y + 48, 72, 190)
    local n = Instance.new("Frame", holder)
    n.Size, n.BackgroundColor3, n.BorderSizePixel = UDim2.new(1,0,0,height), Color3.fromRGB(16, 16, 20), 0
    n.BackgroundTransparency, n.ClipsDescendants = 1, true
    Instance.new("UICorner", n).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", n)
    stroke.Color, stroke.Transparency = color, 0.55
    local accent = Instance.new("Frame", n)
    accent.Size, accent.BackgroundColor3, accent.BorderSizePixel = UDim2.new(0,4,1,0), color, 0
    local heading = Instance.new("TextLabel", n)
    heading.BackgroundTransparency, heading.Position, heading.Size = 1, UDim2.new(0,16,0,9), UDim2.new(1,-28,0,21)
    heading.Font, heading.TextSize, heading.TextColor3 = Enum.Font.GothamBold, 14, Color3.fromRGB(245, 245, 250)
    heading.Text, heading.TextXAlignment, heading.TextTruncate = tostring(title or "Notification"):sub(1,80), Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
    local detail = Instance.new("TextLabel", n)
    detail.BackgroundTransparency, detail.Position, detail.Size = 1, UDim2.new(0,16,0,33), UDim2.new(1,-28,0,height-40)
    detail.Font, detail.TextSize, detail.TextColor3 = Enum.Font.Gotham, 13, Color3.fromRGB(170, 170, 182)
    detail.Text, detail.TextWrapped = body, true
    detail.TextXAlignment, detail.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    duration = math.clamp(tonumber(duration) or 5, 2, 15)
    TS:Create(n, TweenInfo.new(0.2), {BackgroundTransparency=0}):Play()
    task.delay(duration, function()
        if not n.Parent then return end
        TS:Create(n, TweenInfo.new(0.2), {BackgroundTransparency=1}):Play()
        task.wait(0.22)
        n:Destroy()
    end)
end)
