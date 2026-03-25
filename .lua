do

--[[
    STREAMLINED ANTI-CHEAT BYPASS v3.0
    
    Lean bypass system - only essential hooks, zero background loops.
    All dead code removed for maximum performance.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- 1. ULTRA-FAST BYPASS (Minimal Overhead)
-- Only hooks namecall for specific detection remotes to save CPU.
local function setupUltraFastBypass()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if checkcaller() then
            return oldNamecall(self, ...)
        end
        
        local method = getnamecallmethod()
        if method == "FireServer" then
            local name = self.Name
            -- Only block known detection remotes to save CPU
            if name == "Check" or name == "Detect" or name == "Ban" or name == "Kick" or name == "Report" then
                return nil
            end
            -- Anti-KillBrick: Block ForceSelfDamage
            if name == "ForceSelfDamage" then
                return nil
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

-- 2. SERVER-MODIFIED ANTI-KILLBRICK
-- Works in modified servers by checking part names and properties dynamically.
local AntiKillBrickEnabled = true
local function setupAntiKillBrick(char)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if not AntiKillBrickEnabled then return end
                -- Flexible name check for modified servers
                local hitName = hit.Name:lower()
                if hitName:find("kill") or hitName:find("lava") or hitName:find("dead") or hitName:find("void") or hitName:find("damage") then
                    part.CanTouch = false
                    task.wait(0.1)
                    part.CanTouch = true
                end
            end)
        end
    end
end

-- 3. HEADLESS AIMBOT LOGIC (Aimbot Hub Edition)
local HeadlessAimbotEnabled = false
local HeadlessPrediction = 0.1
local function findHeadlessBoss()
    local s = workspace:FindFirstChild("Sleepy Hollow")
    local m = s and s:FindFirstChild("Modes")
    local w = m and m:FindFirstChild("Boss")
    local k = w and w:FindFirstChild("HeadlessHorsemanBoss")
    return k and k:FindFirstChild("HeadlessHorseman")
end

RunService.RenderStepped:Connect(function()
    if not HeadlessAimbotEnabled then return end
    local boss = findHeadlessBoss()
    if boss and boss.Parent then
        local targetPart = boss:FindFirstChild("Torso") or boss:FindFirstChild("UpperTorso")
        if targetPart then
            local camera = workspace.CurrentCamera
            local predictedPos = targetPart.Position + (targetPart.AssemblyLinearVelocity * HeadlessPrediction)
            camera.CFrame = CFrame.new(camera.CFrame.Position, predictedPos)
        end
    end
end)

-- Initialize Features
task.spawn(function()
    pcall(setupUltraFastBypass)
end)
LocalPlayer.CharacterAdded:Connect(setupAntiKillBrick)
if LocalPlayer.Character then task.spawn(setupAntiKillBrick, LocalPlayer.Character) end

-- Silent Background Operation
-- print("v1.9 Features Loaded")

do
--[[
    STREAMLINED ANTI-CHEAT BYPASS v3.0
    
    Lean bypass system - only essential hooks, zero background loops.
    All dead code removed for maximum performance.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- ===== EXECUTOR COMPATIBILITY CHECK (UNC Check) =====
local function getExecutorName()
    return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
end

local function isCompatible()
    local requiredFunctions = {
        "hookmetamethod",
        "getnamecallmethod",
        "checkcaller",
        "newcclosure",
        "hookfunction"
    }
    
    local missingCount = 0
    for _, func in ipairs(requiredFunctions) do
        local found = false
        pcall(function()
            if getfenv()[func] or _G[func] or shared[func] then
                found = true
            end
        end)
        if not found then missingCount = missingCount + 1 end
    end

    -- If 2 or more critical functions are missing, the bypass won't work safely
    return missingCount < 2
end

if not isCompatible() then
    local execName = getExecutorName()
    local msg = "Your " .. execName .. " Executor Not supposed"
    
    -- Attempt to notify the user via Roblox Notification
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Incompatibility Detected",
            Text = msg,
            Duration = 10,
            Button1 = "OK"
        })
    end)
    
    -- Also print to console
    warn("[Guts & Blackpowder | Better🔥] " .. msg)
    return -- STOP EXECUTION HERE
end

-- If compatible, continue script execution...


-- ===== 1. ADVANCED STEALTH GUI PROTECTION (Enhanced v3) =====
-- Multi-layer protection system with instance cloaking, hook-based hiding, and deep protection

-- Comprehensive list of names that look like legitimate Roblox/CoreGui elements
local STEALTH_GUI_NAMES = {
    -- Core Roblox GUI names (high priority - these are actual Roblox GUIs)
    "RobloxGui", "CoreGui", "SystemGui", "PlayerListGui", "ChatWindow",
    "BackpackGui", "HealthGui", "TopBarApp", "SettingsHub", "InspectMenu",
    -- Internal Roblox service names
    "RbxAnalyticsService", "RbxEventHandler", "RbxReplicatedFirst",
    "CoreScript_Internal", "PlayerDisplay_Handler", "SystemOverlay",
    "UIService_Manager", "CorePackages_Root", "VoiceChatShield",
    "BubbleChat_Container", "EmoteMenu_Core", "GameMenu_Handler",
    "NotificationFrame", "ControllerMenu", "TouchControlFrame",
    "VRService_Overlay", "StarterGui_Clone", "LoadingGui_Core",
    "AvatarContextMenu", "RobloxNetworkStats", "PerformanceStats",
    "TenFootInterface", "VirtualCursor", "InGameMenuCore",
    -- Additional stealth names
    "RbxLocalization", "RbxThumbnail", "RbxAssetService", "RbxTextFilter",
    "PolicyService_Internal", "SocialService_Handler", "VoiceChat_Internal",
    "ExperienceChat", "UnibarV2", "Chrome", "SelfView", "Unibar"
}

-- Stealth names for non-GUI instances (Parts, Highlights, BillboardGuis)
local STEALTH_INSTANCE_NAMES = {
    "RbxMeshPart", "CorePart_Internal", "SystemPart", "RbxBasePart",
    "PhysicsHandler", "CollisionPart", "RenderPart", "NetworkPart",
    "ReplicatorPart", "DataModelPart", "AnimationPart", "SoundPart",
    "LightingPart", "EffectPart", "StreamingPart", "TerrainPart",
    "RbxCharacterPart", "RbxAccessory", "RbxJoint", "RbxMotor",
    "CollisionGroup", "PhysicsGroup", "NetworkGroup", "ReplicaGroup"
}

-- Track all protected GUIs with weak references (auto-cleanup when destroyed)
local ProtectedGUIs = setmetatable({}, { __mode = "v" })
local ProtectedInstances = setmetatable({}, { __mode = "v" })



-- ===== ANTI-KILLBRICK SYSTEM =====
local AntiKillBrickEnabled = true
local function setupAntiKillBrick(char)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if not AntiKillBrickEnabled then return end
                if hit.Name:lower():find("kill") or hit.Name:lower():find("lava") or hit.Name:lower():find("dead") then
                    part.CanTouch = false
                    task.wait(0.1)
                    part.CanTouch = true
                end
            end)
        end
    end
    local health = char:FindFirstChild("Health")
    if health then
        local forceSelfDamage = health:FindFirstChild("ForceSelfDamage")
        if forceSelfDamage and forceSelfDamage:IsA("RemoteEvent") then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if AntiKillBrickEnabled and self == forceSelfDamage and method == "FireServer" then
                    return
                end
                return oldNamecall(self, ...)
            end)
        end
    end
end
LocalPlayer.CharacterAdded:Connect(setupAntiKillBrick)
if LocalPlayer.Character then task.spawn(setupAntiKillBrick, LocalPlayer.Character) end

local CloakedInstances = setmetatable({}, { __mode = "k" }) -- Instances hidden from GetChildren/GetDescendants

-- PERFORMANCE: Track GUIs we've already protected to prevent double-protection
local AlreadyProtectedGUIs = setmetatable({}, { __mode = "k" })
-- PERFORMANCE: Track OUR script-created GUIs (only protect these, not game GUIs)
local OurScriptGUIs = setmetatable({}, { __mode = "k" })

-- Generate unique stealth name with timestamp and random components
local function getRandomStealthName()
    local base = STEALTH_GUI_NAMES[math.random(1, #STEALTH_GUI_NAMES)]
    local rand1 = math.random(10000, 99999)
    local rand2 = string.format("%x", math.random(0, 0xFFFF))
    return base .. "_" .. rand1 .. "_" .. rand2
end

local function getRandomInstanceName()
    local base = STEALTH_INSTANCE_NAMES[math.random(1, #STEALTH_INSTANCE_NAMES)]
    local rand1 = math.random(10000, 99999)
    return base .. "_" .. rand1
end

-- ===== INSTANCE CLOAKING SYSTEM =====
-- Hooks GetChildren, GetDescendants, FindFirstChild to hide protected instances

local CloakingEnabled = false
local oldGetChildren, oldGetDescendants, oldFindFirstChild, oldFindFirstChildOfClass, oldFindFirstChildWhichIsA

local function setupInstanceCloaking()
    if CloakingEnabled then return end
    
    -- UNC Compatibility Check for Sunc and others
    local hook = hookfunction or replaceclosure or detour_function
    local closure = newcclosure or function(f) return f end -- Fallback if newcclosure missing
    
    if not hook then return end
    
    pcall(function()
        local folder = Instance.new("Folder")
        
        -- Hook GetChildren
        oldGetChildren = hook(folder.GetChildren, closure(function(self)
            local children = oldGetChildren(self)
            if not next(CloakedInstances) then return children end
            local filtered = {}
            for _, child in ipairs(children) do
                if not CloakedInstances[child] then
                    filtered[#filtered + 1] = child
                end
            end
            return filtered
        end))
        
        -- Hook GetDescendants
        oldGetDescendants = hook(folder.GetDescendants, closure(function(self)
            local descendants = oldGetDescendants(self)
            if not next(CloakedInstances) then return descendants end
            local filtered = {}
            for _, desc in ipairs(descendants) do
                if not CloakedInstances[desc] then
                    filtered[#filtered + 1] = desc
                end
            end
            return filtered
        end))
        
        -- Hook FindFirstChild
        oldFindFirstChild = hook(folder.FindFirstChild, closure(function(self, name, recursive)
            local result = (recursive == true) and oldFindFirstChild(self, name, true) or oldFindFirstChild(self, name)
            if result and CloakedInstances[result] then
                return nil
            end
            return result
        end))
        
        -- Hook FindFirstChildOfClass
        oldFindFirstChildOfClass = hook(folder.FindFirstChildOfClass, closure(function(self, className)
            local result = oldFindFirstChildOfClass(self, className)
            if result and CloakedInstances[result] then
                return nil
            end
            return result
        end))
        
        -- Hook FindFirstChildWhichIsA
        oldFindFirstChildWhichIsA = hook(folder.FindFirstChildWhichIsA, closure(function(self, className)
            local result = oldFindFirstChildWhichIsA(self, className)
            if result and CloakedInstances[result] then
                return nil
            end
            return result
        end))
        
        folder:Destroy()
        CloakingEnabled = true
    end)
end

-- Cloak an instance (hide from GetChildren/GetDescendants/FindFirstChild)
local function cloakInstance(instance)
    if not instance then return end
    CloakedInstances[instance] = true
    -- Also cloak all descendants
    pcall(function()
        for _, desc in ipairs(instance:GetDescendants()) do
            CloakedInstances[desc] = true
        end
    end)
end

-- Uncloak an instance
local function uncloakInstance(instance)
    if not instance then return end
    CloakedInstances[instance] = nil
    pcall(function()
        for _, desc in ipairs(instance:GetDescendants()) do
            CloakedInstances[desc] = nil
        end
    end)
end

-- ===== MAIN GUI PROTECTION FUNCTION =====
-- Lightweight GUI protection - just parent, name, and cloak
local function protectGUI(gui)
    if not gui then return end
    
    -- Skip if already protected
    if AlreadyProtectedGUIs[gui] then return end
    AlreadyProtectedGUIs[gui] = true
    OurScriptGUIs[gui] = true
    
    pcall(function()
        -- Step 1: Assign random stealth name
        gui.Name = getRandomStealthName()
        
        -- Step 2: Try multiple protection methods in order of preference
        local parented = false
        
        -- Method 1: gethui (most hidden - executor's hidden UI container)
        if not parented and gethui then
            pcall(function()
                gui.Parent = gethui()
                parented = true
            end)
        end
        
        -- Method 2: syn.protect_gui (Synapse X specific protection)
        if not parented and syn and syn.protect_gui then
            pcall(function()
                syn.protect_gui(gui)
                gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
                parented = true
            end)
        end
        
        -- Method 3: Try CoreGui (more hidden than PlayerGui)
        if not parented then
            pcall(function()
                local core = game:GetService("CoreGui")
                gui.Parent = core
                parented = true
            end)
        end
        
        -- Method 4: Fallback to PlayerGui
        if not parented then
            pcall(function()
                gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
                parented = true
            end)
        end
        
        -- Step 3: Set stealth properties
        pcall(function() gui.ResetOnSpawn = false end)
        pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
        
        -- Step 4: Track for protection
        ProtectedGUIs[gui] = true
        
        -- Step 5: Cloak the GUI from GetChildren/FindFirstChild
        cloakInstance(gui)
        

    end)
end

-- Protect non-GUI instances (Highlights, Parts, BillboardGuis on models)
local function protectInstance(instance)
    if not instance then return end
    pcall(function()
        instance.Name = getRandomInstanceName()
        ProtectedInstances[instance] = true
        CloakedInstances[instance] = true
    end)
end

-- Create protected ScreenGui with automatic stealth
local function createProtectedScreenGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = getRandomStealthName()
    gui.ResetOnSpawn = false
    protectGUI(gui)
    return gui
end

-- ===== PERIODIC NAME ROTATION =====
-- Rotates GUI names periodically to prevent pattern detection
-- PERFORMANCE: Reduced frequency and only rotates OUR GUIs

-- Track rotation state to spread work across cycles
local rotationIndex = 0
local guiList = {} -- Cached list of GUIs to rotate
local lastGuiListUpdate = 0
local GUI_LIST_CACHE_TIME = 60 -- Rebuild list every 60 seconds
local nameRotationRuns = 0
local MAX_ROTATION_RUNS = 20 -- PERFORMANCE: Stop after 20 rotations (pattern detection isn't that smart)

local function startNameRotation()
    task.defer(function()
        while nameRotationRuns < MAX_ROTATION_RUNS do
            task.wait(180) -- PERFORMANCE: Rotate every 3 minutes
            
            -- PERFORMANCE: Skip if no GUIs to rotate
            if not next(OurScriptGUIs) then
                task.wait(60) -- Sleep longer if nothing to do
                continue
            end
            
            -- Rebuild GUI list periodically (not every cycle)
            local now = os.clock()
            if now - lastGuiListUpdate > GUI_LIST_CACHE_TIME then
                guiList = {}
                for gui, _ in pairs(OurScriptGUIs) do
                    if gui and gui.Parent then
                        table.insert(guiList, gui)
                    else
                        -- Clean up dead references
                        OurScriptGUIs[gui] = nil
                        ProtectedGUIs[gui] = nil
                        AlreadyProtectedGUIs[gui] = nil
                    end
                end
                lastGuiListUpdate = now
                rotationIndex = 0
            end
            
            -- Rotate a batch of GUIs (spread work across cycles)
            -- Guard against division by zero if guiList is empty
            if #guiList > 0 then
                local batchSize = math.min(5, #guiList)
                local rotated = 0
                for i = 1, batchSize do
                    rotationIndex = (rotationIndex % #guiList) + 1
                    local gui = guiList[rotationIndex]
                    if gui and gui.Parent then
                        pcall(function()
                            gui.Name = getRandomStealthName()
                            rotated = rotated + 1
                        end)
                    end
                end
                nameRotationRuns = nameRotationRuns + 1
            end
        end
        -- PERFORMANCE: After max runs, name rotation stops (anti-cheat rarely rechecks names)
    end)
end

-- Initialize cloaking system
setupInstanceCloaking()
startNameRotation()

-- Expose for use throughout script
_G.protectGUI = protectGUI
_G.protectInstance = protectInstance
_G.createProtectedScreenGui = createProtectedScreenGui
_G.getRandomStealthName = getRandomStealthName
_G.getRandomInstanceName = getRandomInstanceName
_G.cloakInstance = cloakInstance
_G.uncloakInstance = uncloakInstance
_G.ProtectedGUIs = ProtectedGUIs
_G.ProtectedInstances = ProtectedInstances
_G.CloakedInstances = CloakedInstances

-- ===== ESP PROTECTION SYSTEM =====
-- Automatically protects Highlights and BillboardGuis created by this script
-- Call this function after creating any ESP visual to protect it from detection

local ESPProtectedInstances = setmetatable({}, { __mode = "k" }) -- Weak keys for GC

local function protectESP(instance)
    if not instance then return end
    if ESPProtectedInstances[instance] then return end -- Already protected
    pcall(function()
        ProtectedInstances[instance] = true
        CloakedInstances[instance] = true
        ESPProtectedInstances[instance] = true
        for _, desc in ipairs(instance:GetDescendants()) do
            ProtectedInstances[desc] = true
            CloakedInstances[desc] = true
            ESPProtectedInstances[desc] = true
        end
    end)
end

-- Expose protection functions (no background scanner needed - ESP is protected at creation)
_G.protectESP = protectESP
_G.ESPProtectedInstances = ESPProtectedInstances

-- ===== 2. KICK/BAN PREVENTION SYSTEM =====

local kickBlocked = 0
local banBlocked = 0
_G.AntiBreakLegsEnabled = _G.AntiBreakLegsEnabled or false

-- Block Player:Kick() (UNC Compatible)
local oldKick = nil
pcall(function()
    local hook = hookfunction or replaceclosure or detour_function
    local closure = newcclosure or function(f) return f end
    
    if hook then
        oldKick = hook(Players.LocalPlayer.Kick, closure(function(self, reason)
            kickBlocked = kickBlocked + 1
            -- Safety: If it's a legitimate game kick, we might want to let it through 
            -- but for now, we block all as requested for anti-ban
            return nil 
        end))
    end
end)

-- ===== 3. NAMECALL HOOK (ADVANCED PROTECTION) =====
-- Intercepts all method calls on Roblox instances

-- blockedRemotes reassigned by Anti-Detect Shield (obfuscated)
local blockedRemotes = {}

-- adminLogPatterns reassigned by Anti-Detect Shield (obfuscated)
local adminLogPatterns = {}

local function isAdminLogRemote(remoteName)
    if not remoteName or remoteName == "" then return false end
    local lower = remoteName:lower()
    for _, pattern in ipairs(adminLogPatterns) do
        if lower:find(pattern) then
            return true
        end
    end
    return false
end

-- suspiciousArgs reassigned by Anti-Detect Shield (obfuscated)
local suspiciousArgs = {}

local function containsSuspiciousArg(args)
    for _, arg in pairs(args) do
        if type(arg) == "string" then
            local lowerArg = arg:lower()
            for _, suspicious in ipairs(suspiciousArgs) do
                if lowerArg:find(suspicious) then
                    return true, suspicious
                end
            end
        end
    end
    return false
end

local oldNamecall
local namecallInHook = false
local adminLogBlockCount = 0

if hookmetamethod and checkcaller and getnamecallmethod then
    pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure and newcclosure(function(self, ...)
            if namecallInHook then
                return oldNamecall(self, ...)
            end
            
            local method = getnamecallmethod()
            local args = {...}
            
            -- Block Kick method
            if method == "Kick" and self == LocalPlayer then
                kickBlocked = kickBlocked + 1
                return nil
            end
            
            -- Block suspicious remote calls (both from us and anti-cheat)
            if method == "FireServer" or method == "InvokeServer" then
                namecallInHook = true
                local remoteName = ""
                pcall(function() remoteName = self.Name end)
                namecallInHook = false

                -- Block fall/broken-legs self-damage when enabled
                if _G.AntiBreakLegsEnabled and remoteName == "ForceSelfDamage" then
                    return nil
                end
                
                -- Block known anti-cheat/admin log remotes (blocks OUTGOING too)
                if blockedRemotes[remoteName] then
                    banBlocked = banBlocked + 1
                    return nil
                end
                
                -- Pattern-based admin log detection
                if isAdminLogRemote(remoteName) then
                    adminLogBlockCount = adminLogBlockCount + 1
                    return nil
                end
                
                -- Check for suspicious arguments (only when not from us)
                if not checkcaller() then
                    local isSuspicious, keyword = containsSuspiciousArg(args)
                    if isSuspicious then
                        return nil
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end) or function(self, ...)
            if namecallInHook then
                return oldNamecall(self, ...)
            end
            
            local method = getnamecallmethod()
            
            if method == "Kick" and self == LocalPlayer then
                kickBlocked = kickBlocked + 1
                return nil
            end
            
            return oldNamecall(self, ...)
        end)
    end)
end

-- ===== 4. METATABLE INDEX HOOK (PROPERTY CLOAKING) =====
-- Minimal hook - only hides GUI names from anti-cheat scans

local oldIndex
local indexInHook = false

if hookmetamethod and checkcaller then
    pcall(function()
        oldIndex = hookmetamethod(game, "__index", newcclosure and newcclosure(function(self, key)
            if indexInHook then
                return oldIndex(self, key)
            end
            
            if not checkcaller() then
                indexInHook = true
                if key == "Name" then
                    local success, name = pcall(function()
                        return oldIndex(self, "Name")
                    end)
                    if success and name == "RobloxSystemUI" then
                        indexInHook = false
                        return "RobloxGui"
                    end
                end
                indexInHook = false
            end
            
            return oldIndex(self, key)
        end) or function(self, key)
            if indexInHook then
                return oldIndex(self, key)
            end
            
            if not checkcaller() then
                indexInHook = true
                if key == "Name" then
                    local success, name = pcall(function()
                        return oldIndex(self, "Name")
                    end)
                    if success and name == "RobloxSystemUI" then
                        indexInHook = false
                        return "RobloxGui"
                    end
                end
                indexInHook = false
            end
            
            return oldIndex(self, key)
        end)
    end)
end

-- ===== 5. NEWINDEX HOOK (DETECT PROPERTY CHANGES) =====
-- Can intercept when anti-cheat tries to modify our properties
-- Also blocks CFrame teleports when noclip bypass is enabled

local oldNewIndex
local newIndexInHook = false

-- Global flag for noclip bypass (set by noclip toggle, checked by hook)
_G.NoclipBypassEnabled = false
-- Store last valid position for noclip (fallback restoration)
_G.NoclipLastValidPosition = nil

-- Parts to block CFrame changes on for noclip
local NOCLIP_BLOCKED_PARTS = {
    ["HumanoidRootPart"] = true,
    ["Torso"] = true,
    ["UpperTorso"] = true,
    ["LowerTorso"] = true,
    ["Head"] = true,
}

if hookmetamethod and checkcaller then
    pcall(function()
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure and newcclosure(function(self, key, value)
            if newIndexInHook then
                return oldNewIndex(self, key, value)
            end
            
            -- Noclip CFrame bypass - block server teleports when enabled
            -- This runs for ALL callers (including server) when noclip is on
            if _G.NoclipBypassEnabled then
                if key == "CFrame" or key == "Position" then
                    local selfName = ""
                    local selfClass = ""
                    pcall(function() selfName = self.Name end)
                    pcall(function() selfClass = self.ClassName end)
                    
                    -- Check if it's a character part we want to block
                    if NOCLIP_BLOCKED_PARTS[selfName] or selfClass == "BasePart" then
                        local char = LocalPlayer and LocalPlayer.Character
                        if char then
                            local isOurs = false
                            pcall(function() isOurs = self:IsDescendantOf(char) end)
                            if isOurs then
                                -- Only block if the caller is NOT us (i.e., server trying to teleport)
                                if not checkcaller() then
                                    -- Block the CFrame/Position change (server trying to teleport us back)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            if not checkcaller() then
                newIndexInHook = true
                
                -- Protect our character from forced resets
                local char = LocalPlayer.Character
                if char and self:IsDescendantOf(char) then
                    -- Block attempts to set WalkSpeed to 0 (anti-cheat punishment)
                    if key == "WalkSpeed" and value == 0 then
                        newIndexInHook = false
                        return nil
                    end
                    -- Block attempts to anchor our character
                    if key == "Anchored" and value == true then
                        newIndexInHook = false
                        return nil
                    end
                end
                
                newIndexInHook = false
            end
            
            return oldNewIndex(self, key, value)
        end) or function(self, key, value)
            -- Fallback: still support noclip bypass
            if _G.NoclipBypassEnabled then
                if key == "CFrame" or key == "Position" then
                    local selfName = ""
                    pcall(function() selfName = self.Name end)
                    if NOCLIP_BLOCKED_PARTS[selfName] then
                        local char = LocalPlayer and LocalPlayer.Character
                        if char then
                            local isOurs = false
                            pcall(function() isOurs = self:IsDescendantOf(char) end)
                            if isOurs then
                                return true
                            end
                        end
                    end
                end
            end
            return oldNewIndex(self, key, value)
        end)
    end)
end

-- ===== 6-8 REMOVED: Property emulators, connection cleaner, remote spy blocker =====
-- These were dead code (never populated), broken (debug.getinfo unavailable), 
-- and no-op (pass-through hooks) respectively. Removed for performance.

-- ===== 9. SAFE REMOTE WRAPPERS =====
-- Lightweight protected remote calls with rate limiting

do
    local lastCallTime = 0
    local callCount = 0
    local MAX_CALLS_PER_SECOND = 60
    
    local function checkRateLimit()
        local now = os.clock()
        if now - lastCallTime > 1 then
            lastCallTime = now
            callCount = 1
            return true
        end
        callCount = callCount + 1
        return callCount <= MAX_CALLS_PER_SECOND
    end
    
    local function safeFireServer(remote, ...)
        if not remote then return end
        if not checkRateLimit() then
            task.wait(0.02)
        end
        local ok, result = pcall(remote.FireServer, remote, ...)
        return result
    end
    
    local function safeInvokeServer(remote, ...)
        if not remote then return nil end
        if not checkRateLimit() then
            task.wait(0.02)
        end
        local ok, result = pcall(remote.InvokeServer, remote, ...)
        return ok and result or nil
    end
    
    _G.SafeFireServer = safeFireServer
    _G.SafeInvokeServer = safeInvokeServer
    _G.RemoteProtectionEnabled = true
end

-- ===== 10. ANTI-DETECTION STATUS =====
_G.AntiBan = true
_G.AntiBanVersion = "3.0"
_G.AntiBanStats = {
    getKickBlocked = function() return kickBlocked end,
    getBanBlocked = function() return banBlocked end,
    getAdminLogBlocked = function() return adminLogBlockCount end,
}

-- ===== 11. LIGHTWEIGHT BYPASS (one-shot, no loops) =====
-- Block Kick/BreakJoints on current char, disable known anti-cheat event connections once

-- Improved Character Bypass (Async & Low UNC Compatible)
local function applyCharBypass(char)
    if not char then return end
    
    -- Use task.spawn to prevent main thread blocking (No Lag)
    task.spawn(function()
        -- Method 1: AddCallHook (if supported by executor)
        pcall(function()
            if char.AddCallHook then
                char:AddCallHook("BreakJoints", function() return end)
            end
            if LocalPlayer.AddCallHook then
                LocalPlayer:AddCallHook("Kick", function() return task.wait(9e9) end)
            end
        end)

        -- Method 2: Namecall/Index Bypass (Already handled by global hooks, but we ensure char integrity)
        pcall(function()
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                -- Protect against common AC death-based detections
                hum.BreakJointsOnDeath = false
            end
        end)

        -- Method 3: Connection Disabling (UNC Check)
        -- We spread this out to avoid frame drops
        task.wait(0.1)
        pcall(function()
            local getconn = getconnections or get_signal_cons
            if getconn then
                local logService = game:GetService("LogService")
                local scriptContext = game:GetService("ScriptContext")
                
                for _, conn in next, getconn(logService.MessageOut) do
                    if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
                end
                
                task.wait(0.05) -- Tiny yield to keep FPS high
                
                for _, conn in next, getconn(scriptContext.Error) do
                    if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
                end
            end
        end)
    end)
end

-- Initialize Bypass
if LocalPlayer.Character then
    applyCharBypass(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Use task.defer for even smoother execution during character spawn
    task.defer(function()
        applyCharBypass(newChar)
    end)
end)


-- ================================================================
-- ANTI-DETECT SHIELD v3.0
-- Layer 1  : Hook Integrity Watcher (re-hook if AC stripped)
-- Layer 2  : FireServer Obfuscator (random jitter)
-- Layer 3  : Feature Event Shield (ProtectedHeartbeat etc.)
-- Layer 4  : SafeHitServer (rate limit + jitter for KillAura)
-- Layer 5  : SmoothAimPosition (lerp to prevent snap detection)
-- Layer 6  : SafeReloadDelay (random delay during reload)
-- Layer 7  : Identity Elevation
-- Layer 8  : ScriptContext/LogService re-disable loop
-- Layer 9  : getgc Closure Protection
-- Layer 10 : debug.getinfo Spoofer
-- Layer 11 : Anti-String Scan (obfuscate sensitive strings)
-- ================================================================

-- ── helpers ──────────────────────────────────────────────────────
local _check  = checkcaller     or function() return true end
local _close  = newcclosure     or function(f) return f end
local _getcon = getconnections  or get_signal_cons or function() return {} end
local _ident  = setidentity     or (syn and syn.set_thread_identity) or set_thread_identity or function() end
local _gethui = gethui          or function() return game:GetService("CoreGui") end

-- ── string obfuscation helper ─────────────────────────────────────
-- convert string to bytes and decode at runtime
-- prevents AC from finding plaintext in bytecode
local function _s(bytes)
    local t = {}
    for i = 1, #bytes do t[i] = string.char(bytes[i]) end
    return table.concat(t)
end

-- ================================================================
-- LAYER 11 : ANTI-STRING SCAN
-- obfuscate all sensitive strings in bypass block first
-- done first because other layers use these strings
-- ================================================================

-- encode function: convert string to byte array (used during dev)
-- local function enc(s) local t={} for i=1,#s do t[i]=string.byte(s,i) end return t end

-- strings AC scans for -> stored as byte arrays
-- format: _s({ byte1, byte2, ... })

-- remote names to block (blockedRemotes table)
local _sReportPlayer    = _s({82,101,112,111,114,116,80,108,97,121,101,114})
local _sBanPlayer       = _s({66,97,110,80,108,97,121,101,114})
local _sKickPlayer      = _s({75,105,99,107,80,108,97,121,101,114})
local _sLogExploit      = _s({76,111,103,69,120,112,108,111,105,116})
local _sDetectedCheat   = _s({68,101,116,101,99,116,101,100,67,104,101,97,116})
local _sSecViolation    = _s({83,101,99,117,114,105,116,121,86,105,111,108,97,116,105,111,110})
local _sACReport        = _s({65,110,116,105,99,104,101,97,116,82,101,112,111,114,116})
local _sFlagPlayer      = _s({70,108,97,103,80,108,97,121,101,114})
local _sCheatDetected   = _s({67,104,101,97,116,68,101,116,101,99,116,101,100})
local _sACFlag          = _s({65,110,116,105,67,104,101,97,116,70,108,97,103})
local _sExploitDetected = _s({69,120,112,108,111,105,116,68,101,116,101,99,116,101,100})
local _sHackReport      = _s({72,97,99,107,82,101,112,111,114,116})
local _sBanRequest      = _s({66,97,110,82,101,113,117,101,115,116})
local _sAutoban         = _s({65,117,116,111,66,97,110})
local _sServerKick      = _s({83,101,114,118,101,114,75,105,99,107})

-- admin log patterns
local _pAnticheat       = _s({97,110,116,105,99,104,101,97,116})
local _pCheatdetect     = _s({99,104,101,97,116,100,101,116,101,99,116})
local _pExploitlog      = _s({101,120,112,108,111,105,116,108,111,103})
local _pSecviol         = _s({115,101,99,117,114,105,116,121,118,105,111,108,97,116,105,111,110})
local _pHackdetect      = _s({104,97,99,107,100,101,116,101,99,116})
local _pCheatreport     = _s({99,104,101,97,116,114,101,112,111,114,116})
local _pExploitreport   = _s({101,120,112,108,111,105,116,114,101,112,111,114,116})
local _pBanrequest      = _s({98,97,110,114,101,113,117,101,115,116})
local _pKickrequest     = _s({107,105,99,107,114,101,113,117,101,115,116})
local _pFlagplayer      = _s({102,108,97,103,112,108,97,121,101,114})
local _pAutoban2        = _s({97,117,116,111,98,97,110})
local _pAntiexploit     = _s({97,110,116,105,101,120,112,108,111,105,116})

-- suspicious arg strings
local _aExploit  = _s({101,120,112,108,111,105,116})
local _aCheat    = _s({99,104,101,97,116})
local _aHack     = _s({104,97,99,107})
local _aAimbot   = _s({97,105,109,98,111,116})
local _aGodmode  = _s({103,111,100,109,111,100,101})
local _aInject   = _s({105,110,106,101,99,116})
local _aExecutor = _s({101,120,101,99,117,116,111,114})
local _aNoclip   = _s({110,111,99,108,105,112})
local _aSpeed    = _s({115,112,101,101,100,104,97,99,107})
local _aWall     = _s({119,97,108,108,104,97,99,107})
local _aTrigger  = _s({116,114,105,103,103,101,114,98,111,116})

-- rebuild blockedRemotes, adminLogPatterns, and suspiciousArgs
-- with obfuscated strings instead of plaintext
-- (these variables were defined previously in the original bypass block
--  we reassign here to replace plaintext with obfuscated version)

blockedRemotes = {
    [_sReportPlayer]    = true,
    [_sBanPlayer]       = true,
    [_sKickPlayer]      = true,
    [_sLogExploit]      = true,
    [_sDetectedCheat]   = true,
    [_sSecViolation]    = true,
    [_sACReport]        = true,
    [_sFlagPlayer]      = true,
    [_sCheatDetected]   = true,
    [_sACFlag]          = true,
    [_sExploitDetected] = true,
    [_sHackReport]      = true,
    [_sBanRequest]      = true,
    [_sAutoban]         = true,
    [_sServerKick]      = true,
}

adminLogPatterns = {
    _pAnticheat, _pCheatdetect, _pExploitlog, _pSecviol,
    _pHackdetect, _pCheatreport, _pExploitreport,
    _pBanrequest, _pKickrequest, _pFlagplayer,
    _pAutoban2, _pAntiexploit,
}

suspiciousArgs = {
    _aExploit, _aCheat, _aHack, _aAimbot,
    _aGodmode, _aInject, _aExecutor,
    _aNoclip, _aSpeed, _aWall, _aTrigger,
}

-- ================================================================
-- LAYER 8  : ScriptContext / LogService RE-DISABLE LOOP
-- original disabled only once at spawn
-- AC can re-connect anytime -> must check in loop
-- ================================================================
local function disableACConnections()
    pcall(function()
        local gc = _getcon
        -- LogService.MessageOut — AC reads log for detection
        for _, conn in next, gc(game:GetService("LogService").MessageOut) do
            pcall(function()
                if conn.Disable then conn:Disable()
                elseif conn.Disconnect then conn:Disconnect() end
            end)
        end
        -- ScriptContext.Error — AC traps our script errors
        for _, conn in next, gc(game:GetService("ScriptContext").Error) do
            pcall(function()
                if conn.Disable then conn:Disable()
                elseif conn.Disconnect then conn:Disconnect() end
            end)
        end
    end)
end

-- run immediately + loop every 20s
disableACConnections()
task.spawn(function()
    while true do
        task.wait(20 + math.random(0, 5))
        disableACConnections()
    end
end)

-- ================================================================
-- LAYER 9  : getgc CLOSURE PROTECTION
-- AC uses getgc() to scan heap for our script's closures/tables
-- -> wrap sensitive functions with new newcclosure every time
--   makes GC pointers change constantly, no pattern found
-- ================================================================
local function refreshClosures()
    pcall(function()
        -- re-wrap SafeFireServer with new closure
        if _G.SafeFireServer then
            local orig = _G.SafeFireServer
            _G.SafeFireServer = _close(function(remote, ...)
                if not remote then return end
                local d = math.random(2, 20) * 0.001
                if d > 0.004 then task.wait(d) end
                local a = {...}
                pcall(function() pcall(function() remote:FireServer(table.unpack(a)) end) end)
            end)
        end
        -- re-wrap SafeInvokeServer
        if _G.SafeInvokeServer then
            _G.SafeInvokeServer = _close(function(remote, ...)
                if not remote then return nil end
                local d = math.random(2, 20) * 0.001
                if d > 0.004 then task.wait(d) end
                local a = {...}
                local ok, r = pcall(function()
                    return pcall(function() return remote:InvokeServer(table.unpack(a)) end)
                end)
                return ok and r or nil
            end)
        end
    end)
end

-- refresh immediately + every 35s (jittered)
refreshClosures()
task.spawn(function()
    while true do
        task.wait(35 + math.random(0, 8))
        refreshClosures()
    end
end)

-- ================================================================
-- LAYER 10 : debug.getinfo SPOOFER
-- AC reads call stack via debug.getinfo to see
-- which script FireServer / InvokeServer was called from
-- -> hook debug.getinfo to return fake source when called from non-caller
-- ================================================================
pcall(function()
    if not debug or not debug.getinfo then return end
    local _origGetInfo = debug.getinfo
    local _infoHook = false

    -- fake source that looks like CoreScript
    local _fakeSources = {
        _s({61,82,111,98,108,111,120,80,108,97,121,101,114,83,99,114,105,112,116}),
        _s({61,67,111,114,101,83,99,114,105,112,116}),
        _s({61,82,111,98,108,111,120,71,117,105}),
        _s({61,83,116,97,114,116,101,114,80,108,97,121,101,114,83,99,114,105,112,116}),
    }

    local hookfn = hookfunction or replaceclosure or detour_function
    if not hookfn then return end

    hookfn(debug.getinfo, _close(function(threadOrLevel, what)
        if _infoHook then return _origGetInfo(threadOrLevel, what) end
        if not _check() then
            _infoHook = true
            local ok, info = pcall(_origGetInfo, threadOrLevel, what)
            _infoHook = false
            if ok and info and type(info) == "table" then
                -- spoof source and short_src to look like CoreScript
                local fake = _fakeSources[math.random(1, #_fakeSources)]
                if info.source then info.source = fake end
                if info.short_src then info.short_src = fake:sub(2) end
                if info.what then info.what = "C" end  -- show as C function
                return info
            end
            return ok and info or nil
        end
        return _origGetInfo(threadOrLevel, what)
    end))
end)

-- ================================================================
-- LAYER 1  : HOOK INTEGRITY WATCHER
-- re-elevate identity + rotate GUI names every 40s
-- prevents AC from stripping hook and killing bypass
-- ================================================================
local _hookWatcherRunning = false
local function startHookWatcher()
    if _hookWatcherRunning then return end
    _hookWatcherRunning = true
    task.spawn(function()
        while true do
            task.wait(40 + math.random(0, 10))
            -- Re-elevate identity
            pcall(function() _ident(8) end)
            -- Re-apply char protections
            pcall(function()
                local char = LocalPlayer and LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.BreakJointsOnDeath = false end
            end)
            -- Rotate GUI names
            pcall(function()
                if not _G.ProtectedGUIs then return end
                local names = {
                    "RobloxGui","CoreGui","SystemGui","PlayerListGui","TopBarApp",
                    "BackpackGui","HealthGui","SettingsHub","BubbleChat_Container",
                    "NotificationFrame","GameMenu_Handler","CoreScript_Internal",
                    "UIService_Manager","VRService_Overlay","EmoteMenu_Core",
                }
                for gui in pairs(_G.ProtectedGUIs) do
                    pcall(function()
                        if gui and gui.Parent then
                            local b = names[math.random(1,#names)]
                            gui.Name = b.."_"..math.random(10000,99999).."_"..string.format("%x",math.random(0,0xFFFF))
                        end
                    end)
                end
            end)
            -- re-disable AC connections again
            disableACConnections()
            -- refresh closures again
            refreshClosures()
        end
    end)
end
startHookWatcher()

-- ================================================================
-- LAYER 2  : FIRESERVER OBFUSCATOR
-- random micro-delay + double pcall for every remote call
-- ================================================================
do
    _G.SafeFireServer = _close(function(remote, ...)
        if not remote then return end
        local d = math.random(2, 25) * 0.001
        if d > 0.005 then task.wait(d) end
        local a = {...}
        pcall(function() pcall(function() remote:FireServer(table.unpack(a)) end) end)
    end)

    _G.SafeInvokeServer = _close(function(remote, ...)
        if not remote then return nil end
        local d = math.random(2, 25) * 0.001
        if d > 0.005 then task.wait(d) end
        local a = {...}
        local ok, r = pcall(function()
            return pcall(function() return remote:InvokeServer(table.unpack(a)) end)
        end)
        return ok and r or nil
    end)

    _G.RemoteProtectionEnabled = true
end

-- ================================================================
-- LAYER 3  : FEATURE EVENT SHIELD
-- Protected connectors for all features
-- has checkcaller guard + optional frame skip
-- ================================================================
_G.ProtectedHeartbeat = function(cb, skip)
    skip = skip or 0
    local f = 0
    return RunService.Heartbeat:Connect(_close(function(dt)
        if not _check() then return end
        if skip > 0 then
            f = f + 1
            if f < skip then return end
            f = 0
        end
        pcall(cb, dt)
    end))
end

_G.ProtectedRenderStepped = function(cb, skip)
    skip = skip or 0
    local f = 0
    return RunService.RenderStepped:Connect(_close(function(dt)
        if not _check() then return end
        if skip > 0 then
            f = f + 1
            if f < skip then return end
            f = 0
        end
        pcall(cb, dt)
    end))
end

_G.ProtectedStepped = function(cb, skip)
    skip = skip or 0
    local f = 0
    return RunService.Stepped:Connect(_close(function(t, dt)
        if not _check() then return end
        if skip > 0 then
            f = f + 1
            if f < skip then return end
            f = 0
        end
        pcall(cb, t, dt)
    end))
end

-- ================================================================
-- LAYER 4  : SafeHitServer
-- rate limit 12 hits/sec + jitter for KillAura / AutoShoot
-- ================================================================
do
    local _ht  = {}
    local MAX  = 12
    local WIN  = 1.0

    _G.SafeHitServer = function(remote, hitType, targetValue, ...)
        if not remote or not targetValue then return end
        local now = os.clock()
        local rid = tostring(remote)
        _ht[rid] = _ht[rid] or {}
        local t = _ht[rid]
        -- purge old timestamps
        local i = 1
        while i <= #t do
            if now - t[i] > WIN then table.remove(t, i)
            else i = i + 1 end
        end
        if #t >= MAX then return end
        t[#t+1] = now
        local jit = math.random(5, 30) * 0.001
        local a = {...}
        task.delay(jit, function()
            pcall(function()
                pcall(function() remote:FireServer(hitType, targetValue, table.unpack(a)) end)
            end)
        end)
    end
end

-- ================================================================
-- LAYER 5  : SmoothAimPosition
-- lerp 35% to prevent silent aim snap detection
-- ================================================================
do
    local _lp = nil
    _G.SmoothAimPosition = function(pos)
        if not pos then return pos end
        if not _lp then _lp = pos; return pos end
        if (_lp - pos).Magnitude > 40 then _lp = pos; return pos end
        _lp = _lp:Lerp(pos, 0.35)
        return _lp
    end
    _G.ResetAimSmooth = function() _lp = nil end
end

-- ================================================================
-- LAYER 6  : SafeReloadDelay
-- random delay during reload steps prevents spam pattern
-- ================================================================
_G.SafeReloadDelay = function(base, variance)
    return (base or 0.05) + (math.random() * (variance or 0.03))
end

-- ================================================================
-- LAYER 7  : IDENTITY ELEVATION
-- ================================================================
pcall(function() _ident(8) end)

-- ================================================================
-- END ANTI-DETECT SHIELD v3.0
-- ================================================================

end
-- ===== END STREAMLINED ANTI-CHEAT BYPASS =====

-- ===== PERFORMANCE OPTIMIZATION SYSTEM =====
-- Tracks feature activity and disables dormant features
do
    local DORMANT_TIMEOUT = 60
    local FRAME_SKIP_LIGHT = 2
    local FRAME_SKIP_HEAVY = 5
    
    _G.LowEndMode = false
    
    _G.LanderPerf = {
        -- Timestamps of last activity for each feature
        lastActivity = {},
        -- Whether each feature is currently active (not dormant)
        isActive = {},
        -- Frame counters for throttling
        frameCounters = {},
        -- Global frame counter
        globalFrame = 0,
        -- Low-end device mode (always enabled)
        lowEndMode = true,
        -- Multiplier for frame skipping (always use aggressive throttling)
        lowEndMultiplier = 3,
    }
    
    -- Toggle low-end mode
    function _G.LanderPerf.setLowEndMode(enabled)
        _G.LanderPerf.lowEndMode = enabled
        if enabled then
            _G.LanderPerf.lowEndMultiplier = 3 -- More aggressive throttling
        else
            _G.LanderPerf.lowEndMultiplier = 1
        end
    end
    
    -- Get effective skip count based on device mode
    function _G.LanderPerf.getSkipCount(baseSkip)
        if _G.LanderPerf.lowEndMode then
            return math.floor(baseSkip * _G.LanderPerf.lowEndMultiplier)
        end
        return baseSkip
    end
    
    -- Mark a feature as active (call when toggle is enabled or used)
    function _G.LanderPerf.markActive(featureName)
        _G.LanderPerf.lastActivity[featureName] = os.clock()
        _G.LanderPerf.isActive[featureName] = true
    end
    
    -- Check if a feature should run (returns false if dormant)
    function _G.LanderPerf.shouldRun(featureName)
        local lastTime = _G.LanderPerf.lastActivity[featureName]
        if not lastTime then return false end
        if os.clock() - lastTime > DORMANT_TIMEOUT then
            _G.LanderPerf.isActive[featureName] = false
            return false
        end
        return true
    end
    
    -- Throttle check - returns true if this frame should process
    function _G.LanderPerf.shouldProcess(featureName, skipCount)
        skipCount = _G.LanderPerf.getSkipCount(skipCount or FRAME_SKIP_LIGHT)
        _G.LanderPerf.frameCounters[featureName] = (_G.LanderPerf.frameCounters[featureName] or 0) + 1
        if _G.LanderPerf.frameCounters[featureName] >= skipCount then
            _G.LanderPerf.frameCounters[featureName] = 0
            return true
        end
        return false
    end
    
    -- Combined check: is active AND should process this frame
    function _G.LanderPerf.canProcess(featureName, skipCount)
        if not _G.LanderPerf.shouldRun(featureName) then return false end
        return _G.LanderPerf.shouldProcess(featureName, skipCount)
    end
    
    -- Disable a feature (mark as dormant)
    function _G.LanderPerf.disable(featureName)
        _G.LanderPerf.isActive[featureName] = false
        _G.LanderPerf.lastActivity[featureName] = nil
    end
    
    -- Constants for feature names (avoid typos)
    _G.LanderPerf.FEATURES = {
        ESP = "ESP",
        KILL_AURA = "KillAura",
        SILENT_AIM = "SilentAim",
        AUTO_SHOOT = "AutoShoot",
        AUTO_SAVE = "AutoSavePlayers",
        FOV_CIRCLE = "FovCircle",
        AIM_DOT = "AimDot",
        ANTI_GRAB = nil, -- removed (patched by game)
        SHOVE_AURA = "ShoveAura",
        AUTO_BLESS = "AutoBless",
        AUTO_PARRY = "AutoParry",
        FLY = "Fly",
        HEADLESS = "Headless",
        DRACULA = "Dracula",
        BOMBER_VIS = "BomberVis",
    }
    
    -- Periodic GC removed: Roblox handles GC natively; forced steps cause micro-stutters
    
end
-- ===== END PERFORMANCE OPTIMIZATION SYSTEM =====

--[[
    Guts & Blackpowder | Better🔥
    Made by anonymous
    Professional WindUI Version
]]--

-- // Shared services (for all sections)
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

local LocalPlayer = Players.LocalPlayer

do -- // Loader + UI + Dashboard
    local WindUI
    local windSuccess, windError = pcall(function()
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    
    if not windSuccess or not WindUI then
        warn("[Guts & Blackpowder | Better🔥] Failed to load WindUI: " .. tostring(windError or "WindUI returned nil"))
        return
    end
    
    WindUI:SetNotificationLower(true)


local LOGO_URL = "https://github.com/Cannifin/Image/blob/main/Screenshot_2026-03-15-18-39-03-82_f380df83a0cf994d27820a806b923e1f.jpg?raw=true"

-- Streamer Mode uses _G.StreamerMode set outside this script
-- Example: _G.StreamerMode = true before running this script
streamerModeEnabled = _G.StreamerMode == true

local Window = WindUI:CreateWindow({
    Title = "Lander Hub | Better🔥",
    Author = "by Home Lander",
    Folder = "GutsBlackpowderBetter/GutsBlackPowder",
    Transparent = true,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    Theme = "Dark",
    Icon = LOGO_URL,
    User = {
        Enabled = false,
        Anonymous = true,
    },
})

    -- Protect WindUI's ScreenGui from detection
    task.defer(function()
        task.wait(0.1) -- Wait for WindUI to create its GUI
        pcall(function()
            local stealthNames = {"RobloxGui", "CoreGui", "SystemGui", "PlayerListGui", "ChatWindow", "BackpackGui", "HealthGui", "TopBarApp", "SettingsHub", "InspectMenu"}
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, child in ipairs(playerGui:GetChildren()) do
                    if child:IsA("ScreenGui") then
                        -- Rename any WindUI or Lander-related GUIs to stealth names
                        local lowerName = child.Name:lower()
                        if lowerName:find("wind") or lowerName:find("Lander") or lowerName:find("hub") then
                            child.Name = stealthNames[math.random(1, #stealthNames)] .. "_" .. math.random(10000, 99999)
                        end
                    end
                end
            end
            -- Also check CoreGui if accessible
            pcall(function()
                local coreGui = game:GetService("CoreGui")
                for _, child in ipairs(coreGui:GetChildren()) do
                    if child:IsA("ScreenGui") then
                        local lowerName = child.Name:lower()
                        if lowerName:find("wind") or lowerName:find("Lander") or lowerName:find("hub") or lowerName:find("aimlock") then
                            child.Name = stealthNames[math.random(1, #stealthNames)] .. "_" .. math.random(10000, 99999)
                        end
                    end
                end
            end)
        end)
    end)

    -- Note: GUI protection is now handled automatically by the BYPASS ANTI-CHEAT system
    -- All new ScreenGuis are auto-protected when created

    Window:SetToggleKey(Enum.KeyCode.RightShift)

    local button = Window:EditOpenButton({
        Title = "Lander Hub | Better🔥",
        Icon = LOGO_URL,
        Size = UDim2.new(0, 140, 0, 40),
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 3,
        Draggable = true,
    })

    -- Rounded corners
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 10)
    uicorner.Parent = button

    -- Subtle background gradient for a premium look
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 28, 48)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 90, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 60)),
    }
    bgGradient.Rotation = 45
    bgGradient.Parent = button

    -- Stroke for contrast and slight glow effect
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 245, 220)
    stroke.Transparency = 0.25
    stroke.Parent = button

    -- Animated rotation to give subtle life to the control (deferred)
    task.defer(function()
        task.wait(2) -- Wait for UI to settle
        while true do
            local tween = TweenService:Create(bgGradient, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                Rotation = bgGradient.Rotation + 360
            })
            tween:Play()
            tween.Completed:Wait()
            bgGradient.Rotation = bgGradient.Rotation % 360
        end
    end)

    Window:SetIconSize(48)
    Window:Tag({
        Title = "Guts & BlackPowder",
        Color = Color3.fromHex("#A5D8FF")
    })

    local DashboardTab = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })

    DashboardTab:Select() -- Select Tab

    local DiscordSection = DashboardTab:Section({
        Title = "Community",
        Icon = "users",
        Opened = true
    })

    local InfoSection = DashboardTab:Section({
        Title = "Information",
        Icon = "info",
        Opened = true
    })

    InfoSection:Paragraph({
        Title = "Guts & Blackpowder | Better🔥 v1.0",
        Desc = "Guts & BlackPowder | Made by anonymous\nExecutor: "..(identifyexecutor and identifyexecutor() or "Unknown"),
    })

    InfoSection:Paragraph({
        Title = "Changelogs",
        Desc = "New updates — figure it out yourself.",
    })

-- Make sure this exists somewhere near the top of your script
local HttpService = game:GetService("HttpService")

-- Discord constants
local discordInvite = "https://discord.gg/YF2DNag2Cq"
local widgetUrl = "https://discord.com/api/guilds/1480053363302338610/widget.json"

-- Main Discord card
local DiscordCard = DiscordSection:Paragraph({
    Title = "Lander Hub | Better🔥",
    Desc  = "🟢 Loading...\n👥 Loading...",

    Image = "https://raw.githubusercontent.com/Cannifin/Image/refs/heads/main/Screenshot_2026-03-15-18-28-51-34_f380df83a0cf994d27820a806b923e1f.jpg",
    ImageSize = 48,

    Buttons = {
        {
            Title = "Copy Invite",
            Icon = "link",
            Callback = function()
                setclipboard(discordInvite)
                WindUI:Notify({
                    Title = "Copied!",
                    Content = "Discord invite link has been copied to your clipboard.",
                    Duration = 3,
                    Icon = "copy",
                })
            end
        }
    }
})

-- Live Discord stats updater (online + member count)
local function updateDiscordCard()
    local online = 0
    local members = 0

    -- Widget API → online count + approximate_member_count
    local ok, body = pcall(function()
        return game:HttpGet(widgetUrl)
    end)

    if ok and body then
        local okDecode, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if okDecode and type(data) == "table" then
            online = tonumber(data.presence_count) or 0
            -- Widget JSON includes member list (only online ones shown in widget)
            if type(data.members) == "table" then
                -- presence_count is more reliable for online
                online = tonumber(data.presence_count) or #data.members
            end
        end
    end

    -- Also try the invite API for approximate member count
    local ok2, body2 = pcall(function()
        return game:HttpGet("https://discord.com/api/v9/invites/YF2DNag2Cq?with_counts=true")
    end)
    if ok2 and body2 then
        local okDecode2, data2 = pcall(function()
            return HttpService:JSONDecode(body2)
        end)
        if okDecode2 and type(data2) == "table" and data2.guild then
            members = tonumber(data2.approximate_member_count) or members
            online  = tonumber(data2.approximate_presence_count) or online
        end
    end

    local line1 = string.format("🟢 %d Online", online)
    local line2 = string.format("👥 %d Members", members)

    DiscordCard:SetDesc(line1 .. "\n" .. line2)
end

task.defer(function()
    task.wait(3) -- Wait for game to load first
    while true do
        pcall(updateDiscordCard)
        task.wait(60)
    end
end)
end

-- ===== GLOBAL TOGGLE REGISTRY FOR KEYBINDS =====
_G.LanderToggles = _G.LanderToggles or {}

-- ===== 7 MAIN TABS =====
local CombatTab  = Window:Tab({ Title = "Combat",  Icon = "sword" })
local AutoTab    = Window:Tab({ Title = "Auto",    Icon = "zap" })
local ESPTab     = Window:Tab({ Title = "ESP",     Icon = "eye" })
local PlayerTab  = Window:Tab({ Title = "Player",  Icon = "user" })
local VisualTab  = Window:Tab({ Title = "Visual",  Icon = "sun" })
local EventTab   = Window:Tab({ Title = "Event",   Icon = "crosshair" })
local MiscTab    = Window:Tab({ Title = "Misc",    Icon = "wrench" })

-- ===== COMPATIBILITY ALIASES (old code references these) =====
local Main1Section   = CombatTab
local Esp1Section    = ESPTab
local Event1Section  = EventTab
local Others1Section = MiscTab

-- MainTab alias used in existing do-blocks
local MainTab = CombatTab

task.wait(0.1) -- Delay to prevent lag
do -- // Main Tab

local enabled = true

-- Modules (Bayonet / Melee override, safe non-blocking require)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:FindFirstChild("Modules") or nil

-- safe helper that returns status: "absent" | "failed" | "ok"
local function safeRequire(moduleInstance)
    if not moduleInstance then
        return "absent", "module not present"
    end
    local ok, res = pcall(function() return require(moduleInstance) end)
    if not ok then
        return "failed", res -- require attempted and errored
    end
    return "ok", res -- require succeeded
end

-- DEFAULT NO-OPS / STUBS so code doesn't error if modules missing
local function noop() end
local function noop_change(value) end

local changeBayonet = noop_change
local changeMelee = noop_change

-- DebugVisualizer stub (safe no-op interface)
local DebugVisualizerStub = {
    CastSphere = function(...) end,
    CastLine = function(...) end,
}

-- Track presence vs require-failure vs success
local FlintLockPresent, FlintLockRequireFailed, FlintLockSuccess, FlintLock = false, false, false, nil
local MeleeBasePresent, MeleeBaseRequireFailed, MeleeBaseSuccess, MeleeBase = false, false, false, nil

-- Attempt to find & require modules without yielding (don't lock on missing)
local weaponsFolder = Modules and Modules:FindFirstChild("Weapons")
local flintModInstance = weaponsFolder and weaponsFolder:FindFirstChild("Flintlock")
if flintModInstance then
    FlintLockPresent = true
    local status, res = safeRequire(flintModInstance)
    if status == "ok" then
        FlintLockSuccess = true
        FlintLock = res

        local originBayonet = FlintLock.BayonetHitCheck

        local v_u_1 = {}
        v_u_1.__index = v_u_1

        function v_u_1.BayonetHitCheck(p115, p116, p117, p118, p119)
            local v120 = workspace:Raycast(p116, p117, p118)
            if v120 then
                -- Support both m_Zombie and ZombieLike tagged entities
                local isZombie = v120.Instance.Parent.Name == "m_Zombie" or v120.Instance.Parent:HasTag("ZombieLike")
                if isZombie then
                    local v121 = p118.FilterDescendantsInstances
                    local v122 = v120.Instance
                    table.insert(v121, v122)
                    p118.FilterDescendantsInstances = v121
                    local v123 = v120.Instance.Parent:FindFirstChild("Orig")
                    if v123 then
                        -- Find head part (check direct children and nested models)
                        local Head = nil
                        for i, part in pairs(v120.Instance.Parent:GetDescendants()) do
                            if part.Name == "Head" and (part:IsA("BasePart")) then
                                Head = part
                                break
                            end
                        end
                        
                        if Head and v123.Value then
                            -- Head Hit Chance: random check before redirect
                            local shouldHitHead = HeadHitEnabled or
                                (HeadHitChanceEnabled and math.random(1, 100) <= HeadHitChance)
                            if not shouldHitHead then
                                -- Failed chance roll — use original hit position
                                _G.SafeFireServer(p115.remoteEvent, "Bayonet_HitZombie", v123.Value, v120.Position, v120.Instance.Name == "Head", v120.Instance.Name)
                                local v_u_124 = v123.Value
                                local v_u_125 = os.clock()
                                v_u_124:SetAttribute("WepHitID", os.clock())
                                v_u_124:SetAttribute("WepHitDirection", p117 * 10)
                                v_u_124:SetAttribute("WepHitPos", v120.Position)
                                task.delay(0.2, function()
                                    if v_u_124:GetAttribute("WepHitID") == v_u_125 then
                                        v_u_124:SetAttribute("WepHitDirection", nil)
                                        v_u_124:SetAttribute("WepHitPos", nil)
                                        v_u_124:SetAttribute("WepHitID", nil)
                                    end
                                end)
                                return 1
                            end
                            -- Passed chance roll or HeadLock ON — redirect to head
                            if shared.Gib ~= nil then
                                local zombieHum = v123.Value:FindFirstChild("Zombie")
                                if zombieHum then
                                    shared.Gib(v123.Value, "Head", Head.CFrame.Position, v120.Normal, true)
                                end
                            end
                            
                            _G.SafeFireServer(p115.remoteEvent, "Bayonet_HitZombie", v123.Value, Head.CFrame.Position, true, "Head")
                            local v_u_124 = v123.Value
                            local v_u_125 = os.clock()
                            v_u_124:SetAttribute("WepHitID", os.clock())
                            v_u_124:SetAttribute("WepHitDirection", p117 * 10)
                            v_u_124:SetAttribute("WepHitPos", Head.CFrame.Position) -- Use head position
                            task.delay(0.2, function()
                                if v_u_124:GetAttribute("WepHitID") == v_u_125 then
                                    v_u_124:SetAttribute("WepHitDirection", nil)
                                    v_u_124:SetAttribute("WepHitPos", nil)
                                    v_u_124:SetAttribute("WepHitID", nil)
                                end
                            end)
                        elseif v123.Value then
                            -- Fallback: Head not found, use original hit behavior
                            _G.SafeFireServer(p115.remoteEvent, "Bayonet_HitZombie", v123.Value, v120.Position, v120.Instance.Name == "Head", v120.Instance.Name)
                            local v_u_124 = v123.Value
                            local v_u_125 = os.clock()
                            v_u_124:SetAttribute("WepHitID", os.clock())
                            v_u_124:SetAttribute("WepHitDirection", p117 * 10)
                            v_u_124:SetAttribute("WepHitPos", v120.Position)
                            task.delay(0.2, function()
                                if v_u_124:GetAttribute("WepHitID") == v_u_125 then
                                    v_u_124:SetAttribute("WepHitDirection", nil)
                                    v_u_124:SetAttribute("WepHitPos", nil)
                                    v_u_124:SetAttribute("WepHitID", nil)
                                end
                            end)
                        end
                    end
                    return 1
                end
                local v126 = v120.Instance.Parent:FindFirstChild("DoorHit") or v120.Instance:FindFirstChild("BreakGlass")
                if v126 and not table.find(p119, v126) then
                    table.insert(p119, v126)
                    _G.SafeFireServer(p115.remoteEvent, "Bayonet_HitCon", v120.Instance, v120.Position, v120.Normal, v120.Material)
                    return 2
                end
                local v127 = v120.Instance.Parent:FindFirstChild("Humanoid") or v120.Instance.Parent.Parent:FindFirstChild("Humanoid")
                if v127 and not table.find(p119, v127) then
                    table.insert(p119, v127)
                    _G.SafeFireServer(p115.remoteEvent, "Bayonet_HitPlayer", v127, v120.Position)
                    return 2
                end
            end
            return 0
        end

        function changeBayonet(value)
            FlintLock.BayonetHitCheck = value and v_u_1.BayonetHitCheck or originBayonet
        end
    elseif status == "failed" then
        -- module present but require errored -> mark require-failed (will lock later)
        FlintLockRequireFailed = true
    else
        -- status == "absent", do nothing (wait)
        FlintLockPresent = false
    end
else
    -- module absent: do nothing (we wait)
    FlintLockPresent = false
end

-- Attempt MeleeBase detection + require similarly (non-blocking)
local meleeModInstance = (Modules and Modules:FindFirstChild("Weapons") and Modules.Weapons:FindFirstChild("MeleeBase")) or (Modules and Modules:FindFirstChild("MeleeBase"))
if meleeModInstance then
    MeleeBasePresent = true
    local status, res = safeRequire(meleeModInstance)
    if status == "ok" then
        MeleeBaseSuccess = true
        MeleeBase = res

        local originMelee = MeleeBase.MeleeHitCheck

        local u1 = {}
        u1.__index = u1

        local u8 = game:GetService("CollectionService")

        -- safe require for DebugVisualizer (non-blocking)
        local dbgMod = Modules and Modules:FindFirstChild("RbxUtil") and Modules.RbxUtil:FindFirstChild("DebugVisualizer")
        local dbgStatus, dbgRes = safeRequire(dbgMod)
        local u10 = (dbgStatus == "ok") and dbgRes or DebugVisualizerStub

        local v11 = game.Players.LocalPlayer:FindFirstChild("Options") or game.Players.LocalPlayer:WaitForChild("Options")
        local u14 = v11:FindFirstChild("Gore") or v11:WaitForChild("Gore")
        local u15 = v11:FindFirstChild("WeaponStains") or v11:WaitForChild("WeaponStains")
        local v5 = ReplicatedStorage:FindFirstChild("GameStates") and ReplicatedStorage.GameStates:FindFirstChild("Gameplay")
        local u7 = v5 and v5:FindFirstChild("PVP")

        function u1.MeleeHitCheck(p100, p101, p102, p103, p104, p105)
            local v106 = workspace:Raycast(p101, p102, p103)
            if v106 then
                -- Support both m_Zombie and ZombieLike tagged entities
                local isZombie = v106.Instance.Parent.Name == "m_Zombie" or v106.Instance.Parent:HasTag("ZombieLike")
                if isZombie then
                    local v107 = p103.FilterDescendantsInstances
                    local v108 = v106.Instance
                    table.insert(v107, v108)
                    p103.FilterDescendantsInstances = v107
                    local v109 = v106.Instance.Parent:FindFirstChild("Orig")
                    if v109 then
                        -- Find head part (check descendants for nested models)
                        local Head = nil
                        for i, part in pairs(v106.Instance.Parent:GetDescendants()) do
                            if part.Name == "Head" and (part:IsA("BasePart")) then
                                Head = part
                                break
                            end
                        end
                        
                        -- Gib effect - always target head when found
                        if p100.sharp and shared.Gib ~= nil then
                            if v109.Value then
                                local v110 = v109.Value:FindFirstChild("Zombie")
                                local v111 = not p100.Stats.HeadshotMulti and 2.3 or p100.Stats.HeadshotMulti
                                local gibPart = Head and "Head" or v106.Instance.Name
                                local gibPos = Head and Head.CFrame.Position or v106.Position
                                if v110 and v110.Health - p100.Stats.Damage * v111 <= 0 then
                                    shared.Gib(v109.Value, gibPart, gibPos, v106.Normal, true)
                                end
                            else
                                local gibPart = Head and "Head" or v106.Instance.Name
                                local gibPos = Head and Head.CFrame.Position or v106.Position
                                shared.Gib(v109.Value, gibPart, gibPos, v106.Normal, true)
                            end
                        end
                        if not p104[v109] or p104[v109] < (p100.Stats.MaxHits or 3) then
                            if p105 then
                                -- ThrustCharge also redirects to head
                                if Head and v109.Value then
                                    _G.SafeFireServer(p100.remoteEvent, "ThrustCharge", v109.Value, Head.CFrame.Position, v106.Normal)
                                else
                                    _G.SafeFireServer(p100.remoteEvent, "ThrustCharge", v109.Value, v106.Position, v106.Normal)
                                end
                            else
                                if Head and v109.Value then
                                    -- Head Hit Chance: random check before redirect
                                    local shouldHitHead = HeadHitEnabled or
                                        (HeadHitChanceEnabled and math.random(1, 100) <= HeadHitChance)
                                    if not shouldHitHead then
                                        -- Failed chance roll — use original hit position
                                        local u112 = v109.Value
                                        local v113 = v106.Position - p101
                                        if v113:Dot(v113) > 1 then v113 = v113.Unit end
                                        local v114 = v113 * 25
                                        _G.SafeFireServer(p100.remoteEvent, "HitZombie", u112, v106.Position, v106.Instance.Name == "Head", v114, v106.Instance.Name, v106.Normal)
                                        if not u112:GetAttribute("WepHitDirection") then
                                            local u115 = os.clock()
                                            u112:SetAttribute("WepHitID", os.clock())
                                            u112:SetAttribute("WepHitDirection", v114)
                                            u112:SetAttribute("WepHitPos", v106.Position)
                                            task.delay(0.2, function()
                                                if u112:GetAttribute("WepHitID") == u115 then
                                                    u112:SetAttribute("WepHitDirection", nil)
                                                    u112:SetAttribute("WepHitPos", nil)
                                                    u112:SetAttribute("WepHitID", nil)
                                                end
                                            end)
                                        end
                                        return 1
                                    end
                                    -- Passed chance roll — redirect to head
                                    local u112 = v109.Value
                                    local v113 = Head.CFrame.Position - p101
                                    if v113:Dot(v113) > 1 then
                                        v113 = v113.Unit
                                    end
                                    local v114 = v113 * 25
                                    _G.SafeFireServer(p100.remoteEvent, "HitZombie", u112, Head.CFrame.Position, true, v114, "Head", v106.Normal)
                                    if not u112:GetAttribute("WepHitDirection") then
                                        local u115 = os.clock()
                                        u112:SetAttribute("WepHitID", os.clock())
                                        u112:SetAttribute("WepHitDirection", v114)
                                        u112:SetAttribute("WepHitPos", Head.CFrame.Position) -- Use head position
                                        task.delay(0.2, function()
                                            if u112:GetAttribute("WepHitID") == u115 then
                                                u112:SetAttribute("WepHitDirection", nil)
                                                u112:SetAttribute("WepHitPos", nil)
                                                u112:SetAttribute("WepHitID", nil)
                                            end
                                        end)
                                    end
                                    pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                                    pcall(function() u10:CastSphere("PartPosition", CFrame.new(Head.CFrame.Position), Color3.fromRGB(255, 85, 0)) end)
                                    pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(0, 255, 0), p102.Magnitude / 1) end)
                                elseif v109.Value then
                                    -- Fallback: Head not found, use original hit location but still fire
                                    local u112 = v109.Value
                                    local v113 = v106.Position - p101
                                    if v113:Dot(v113) > 1 then
                                        v113 = v113.Unit
                                    end
                                    local v114 = v113 * 25
                                    _G.SafeFireServer(p100.remoteEvent, "HitZombie", u112, v106.Position, v106.Instance.Name == "Head", v114, v106.Instance.Name, v106.Normal)
                                    if not u112:GetAttribute("WepHitDirection") then
                                        local u115 = os.clock()
                                        u112:SetAttribute("WepHitID", os.clock())
                                        u112:SetAttribute("WepHitDirection", v114)
                                        u112:SetAttribute("WepHitPos", v106.Position)
                                        task.delay(0.2, function()
                                            if u112:GetAttribute("WepHitID") == u115 then
                                                u112:SetAttribute("WepHitDirection", nil)
                                                u112:SetAttribute("WepHitPos", nil)
                                                u112:SetAttribute("WepHitID", nil)
                                            end
                                        end)
                                    end
                                    pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                                    pcall(function() u10:CastSphere("PartPosition", CFrame.new(v106.Position), Color3.fromRGB(255, 85, 0)) end)
                                    pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(0, 255, 0), p102.Magnitude / 1) end)
                                end
                            end
                            if p104[v109] then
                                p104[v109] = p104[v109] + 1
                            else
                                table.insert(p104, v109)
                                p104[v109] = 1
                                if u14.Value and (u15.Value and p100.player:GetAttribute("Platform") ~= "Console") then
                                    local v116 = p100.bloodSaturation + 0.1
                                    p100.bloodSaturation = math.min(v116, 1)
                                end
                            end
                        end
                    end
                    return 1
                end
                if not p105 then
                    local v117 = v106.Instance.Parent:FindFirstChild("DoorHit") or v106.Instance:FindFirstChild("BreakGlass")
                    if v117 and not table.find(p104, v117) then
                        table.insert(p104, v117)
                        _G.SafeFireServer(p100.remoteEvent, "HitCon", v106.Instance)
                        pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                        pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(255, 255, 0), p102.Magnitude / 1) end)
                        return 2
                    end
                    local v118 = v106.Instance.Parent:FindFirstChild("Humanoid") or v106.Instance.Parent.Parent:FindFirstChild("Humanoid")
                    if v118 and not table.find(p104, v118) then
                        table.insert(p104, v118)
                        _G.SafeFireServer(p100.remoteEvent, "HitPlayer", v118, v106.Position)
                        pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                        pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(0, 255, 0), p102.Magnitude / 1) end)
                        return 2
                    end
                    if u7 and u7:GetAttribute("Active") == true then
                        local v119 = v106.Instance.Parent:FindFirstChild("BuildingHealth") or v106.Instance.Parent.Parent:FindFirstChild("BuildingHealth")
                        if v119 ~= nil and not table.find(p104, v119) then
                            table.insert(p104, v119)
                            local v120 = v119.Parent:FindFirstChild("Creator")
                            if v120 then
                                v120 = v120.Value
                            end
                            if v120 ~= nil and (v120.Neutral == false and (p100.player.Team ~= nil and (v120.Team ~= nil and p100.player.Team.Name == v120.Team.Name))) then
                                return 2
                            end
                            _G.SafeFireServer(p100.remoteEvent, "HitBuilding", v119.Parent)
                            pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                            pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(255, 255, 0), p102.Magnitude / 1) end)
                            return 2
                        end
                    end
                    if p100.Stats.BreaksDown and u8:HasTag(v106.Instance, "Breakable") then
                        local v121 = OverlapParams.new()
                        v121.FilterDescendantsInstances = p103.FilterDescendantsInstances
                        local v122 = workspace:GetPartBoundsInRadius(v106.Position, 0.1, v121)
                        local v123 = {}
                        for v124 = 1, #v122 do
                            if u8:HasTag(v122[v124], "Breakable") then
                                local v125 = v122[v124]
                                table.insert(v123, v125)
                            end
                        end
                        _G.SafeFireServer(p100.remoteEvent, "HitBreakable", v123, (v106.Position - p101).Unit)
                        pcall(function() u10:CastSphere("MeleeHitValid", CFrame.new(p101), Color3.fromRGB(0, 255, 0)) end)
                        pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(255, 255, 0), p102.Magnitude / 1) end)
                        return 2
                    end
                    pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(255, 0, 0), p102.Magnitude / 1) end)
                end
            else
                pcall(function() u10:CastLine("MeleeHit", CFrame.new(p101, p101 + p102) * CFrame.new(0, 0, -p102.Magnitude / 2), Color3.fromRGB(255, 0, 0), p102.Magnitude / 1) end)
            end
            return 0
        end

        function changeMelee(value)
            MeleeBase.MeleeHitCheck = value and u1.MeleeHitCheck or originMelee
        end
    elseif status == "failed" then
        MeleeBaseRequireFailed = true
    else
        MeleeBasePresent = false
    end
else
    MeleeBasePresent = false
end

-- ---------- Aiming Section (toggles for head hit) ----------
local AimingSection = MainTab:Section({
    Title = "Hit",
    Icon = "crosshair",
    Opened = false
})

HeadHitEnabled = false -- Global for keybind access
HeadHitChanceEnabled = false -- Head Hit Chance toggle
HeadHitChance = 50 -- % chance to hit head (1-100)

local function notifyErrorAndLock(toggle)
    -- notify user and lock the toggle (both wrapped so they won't error)
    pcall(function()
        if WindUI then
            WindUI:Notify({
                Title = "Hit — Error",
                Content = "Head Hit had an error and will be locked.",
                Duration = 4,
                Icon = "alert-circle",
            })
        end
    end)
    pcall(function()
        if toggle and toggle.Lock then toggle:Lock() end
    end)
end

local HeadHitToggle = AimingSection:Toggle({
    Title = "Head Lock",
    Flag = "Head_Lock",
    Desc = "Redirects all attacks to zombie heads.",
    Default = HeadHitEnabled,
    Callback = function(value)
        -- reflect UI intent immediately
        HeadHitEnabled = value

        -- If a require previously failed for any module, lock & notify (require-failure = module existed but require errored)
        if FlintLockRequireFailed or MeleeBaseRequireFailed then
            HeadHitEnabled = false
            pcall(function() changeBayonet(false) end)
            pcall(function() changeMelee(false) end)
            notifyErrorAndLock(HeadHitToggle)
            return
        end

        -- If user is enabling but no modules are present yet, allow it (we "wait")
        -- apply overrides only for modules that successfully required
        local ok, err = pcall(function()
            if FlintLockSuccess then changeBayonet(value) end
            if MeleeBaseSuccess then changeMelee(value) end
        end)

        if not ok then
            -- a runtime error happened while applying overrides -> lock
            HeadHitEnabled = false
            pcall(function()
                if FlintLockSuccess then changeBayonet(false) end
                if MeleeBaseSuccess then changeMelee(false) end
            end)
            notifyErrorAndLock(HeadHitToggle)
            return
        end

        -- success notify (safe)
        pcall(function()
            if WindUI then
                WindUI:Notify({
                    Title = "Hit",
                    Content = value and "Head Hit enabled" or "Head Hit disabled",
                    Duration = 2,
                    Icon = value and "crosshair" or "crosshair-off",
                })
            end
        end)
    end
})

-- Store toggle reference globally for keybind access
_G.LanderToggleElements = _G.LanderToggleElements or {}
_G.LanderToggleElements.HeadHit = HeadHitToggle

-- If any require previously failed, lock & notify immediately (module existed but require errored)
if FlintLockRequireFailed or MeleeBaseRequireFailed then
    notifyErrorAndLock(HeadHitToggle)
end

-- Register HeadHit toggle for keybind access
_G.LanderToggles.HeadHit = {
    element = HeadHitToggle,
    getState = function() return HeadHitEnabled end,
    setState = function(v) HeadHitEnabled = v end
}

    -- === Jump On Specific Animations (with WindUI Toggle) ===            
    -- === Target Animation IDs ===            
    local TARGET_ANIM_IDS = {            
        "rbxassetid://17406577733",            
        "rbxassetid://15669224658",            
        "rbxassetid://12591948314",            
        "rbxassetid://12333491302",            
    }
    
    -- Jump height setting (studs)
    AutoJumpHeight = 7.2 -- Default Roblox jump height is ~7.2 studs
    
    -- Jump cooldown setting (seconds)
    AutoJumpCooldown = 0 -- Default 0 = no cooldown
    local lastJumpTime = 0 -- Track last jump timestamp
            
    local TARGETS = {}            
    for _, v in ipairs(TARGET_ANIM_IDS) do            
        local id = tostring(v)            
        if id:match("^%d+$") then            
            id = "rbxassetid://" .. id            
        end            
        TARGETS[id] = true            
    end            
            
    -- === Jump logic ===            
    local humanoid, animator            
    local playedTracks = {}            
    local monitoring = false            
            
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
        
        -- Check cooldown
        local now = os.clock()
        if AutoJumpCooldown > 0 and (now - lastJumpTime) < AutoJumpCooldown then
            return -- Still on cooldown
        end
        lastJumpTime = now
  
        task.spawn(function()  
            pcall(function()  
                -- Wait until humanoid can jump again  
                local timeout = 1  
                local startTime = os.clock()  
  
                while os.clock() - startTime < timeout do  
                    local state = humanoid:GetState()  
                    if state == Enum.HumanoidStateType.Running  
                        or state == Enum.HumanoidStateType.Landed  
                        or state == Enum.HumanoidStateType.RunningNoPhysics  
                        or state == Enum.HumanoidStateType.Climbing then  
                        break  
                    end  
                    task.wait(0.05)  
                end  
  
                -- === Jump Height Simulation (Velocity-based) ===
                -- Physics formula: v = sqrt(2 * g * h) where g = workspace.Gravity, h = jump height
                local gravity = workspace.Gravity
                local jumpHeight = AutoJumpHeight or 3.5
                local jumpVelocity = math.sqrt(2 * gravity * jumpHeight)
                
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    -- Set humanoid state to jumping first
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    
                    -- Apply vertical velocity using AssemblyLinearVelocity
                    local currentVel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, jumpVelocity, currentVel.Z)
                end
            end)  
        end)  
    end  
            
    -- === Monitoring loop ===            
    local function startMonitoring()            
        if monitoring then return end            
        monitoring = true            
        task.spawn(function()            
            while monitoring do            
                if animator then            
                    local ok, tracks = pcall(function()            
                        return animator:GetPlayingAnimationTracks()            
                    end)            
                    if ok and tracks then            
                        for _, track in ipairs(tracks) do            
                            if trackIsTarget(track) and not playedTracks[track] then            
                                playedTracks[track] = true            
                                pcall(doJump)            
                                track.Stopped:Connect(function()            
                                    playedTracks[track] = nil            
                                end)            
                            end            
                        end            
                    end            
                end            
                task.wait(0.08)            
            end            
        end)            
    end            
            
    local function stopMonitoring()            
        monitoring = false            
        playedTracks = {}            
    end            
            
    -- === Character initialization ===  
    local function refreshCharacter(char)  
        -- Stop any existing monitoring first (fixes respawn bug)
        monitoring = false
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

    -- === Restore toggle state after respawn ===
    local function restoreAutoJump()
        local persisted = false
        pcall(function()
            persisted = LocalPlayer:GetAttribute("AutoJumpEnabled")
        end)
        if persisted then
            task.delay(0.3, startMonitoring) -- Slightly longer delay for stability
        end
    end
    restoreAutoJump()

    LocalPlayer.CharacterAdded:Connect(function(ch)  
        -- Wait for character to fully load  
        ch:WaitForChild("Humanoid", 5)  
        ch:WaitForChild("HumanoidRootPart", 5)  
        refreshCharacter(ch)  
        restoreAutoJump()
    end)  

    local LegitSection = MainTab:Section({            
        Title = "Jump When Stab Sabre",            
        Icon = "shield-check",            
        Opened = false            
    })            
            
    -- === WindUI Toggle Setup ===            
    local AutoJumpToggle = LegitSection:Toggle({            
        Title = "Auto Jump",            
        Flag = "Jump_When_Stab_Sabre",
        Desc = "Auto jump while thrusting.",            
        Default = false,            
        Callback = function(value)            
            pcall(function() LocalPlayer:SetAttribute("AutoJumpEnabled", value) end)
            if value then            
                startMonitoring()            
                WindUI:Notify({            
                    Title = "Jump On Swing",            
                    Content = "Auto Jump Enabled",            
                    Duration = 2,            
                    Icon = "activity",            
                })            
            else            
                stopMonitoring()            
                WindUI:Notify({            
                    Title = "Jump On Swing",            
                    Content = "Auto Jump Disabled",            
                    Duration = 2,            
                    Icon = "activity-off",            
                })            
            end            
        end            
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.AutoJump = AutoJumpToggle

    -- Jump Height Slider
    LegitSection:Slider({
        Title = "Jump Height",
        Flag = "Jump_Height",
        Desc = "Jump height.",
        Step = 0.1,
        Value = { Min = 1, Max = 10, Default = 1.9 },
        Callback = function(value)
            AutoJumpHeight = value
        end
    })
    
    -- Jump Cooldown Slider
    LegitSection:Slider({
        Title = "Jump Cooldown",
        Flag = "Jump_Cooldown",
        Desc = "Cooldown between jumps.",
        Step = 0.1,
        Value = { Min = 0, Max = 2, Default = 0 },
        Callback = function(value)
            AutoJumpCooldown = value
        end
    })

    -- Head Hit Chance Toggle
    local HeadHitChanceToggle = LegitSection:Toggle({
        Title = "Head Hit Chance",
        Flag = "Head_Hit_Chance",
        Desc = "Random chance to hit head (separate from Head Lock)",
        Default = false,
        Callback = function(value)
            HeadHitChanceEnabled = value
            pcall(function()
                if WindUI then
                    WindUI:Notify({
                        Title = "Head Hit Chance",
                        Content = value and ("Enabled — Chance: " .. HeadHitChance .. "%") or "Disabled",
                        Duration = 2,
                        Icon = value and "percent" or "x-circle",
                    })
                end
            end)
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.HeadHitChance = HeadHitChanceToggle

    -- Head Hit Chance Slider
    LegitSection:Slider({
        Title = "Head Hit Chance %",
        Flag = "Head_Hit_Chance_Value",
        Desc = "% chance to hit head per swing (1 = rarely, 100 = always)",
        Step = 1,
        Value = { Min = 1, Max = 100, Default = 50 },
        Callback = function(value)
            HeadHitChance = value
        end
    })

local HitboxSection = MainTab:Section({
        Title = "Hitbox",
        Icon = "box",
        Opened = false
    })

-- Hitbox Expander (robust, non-blocking, locks UI on error + notifies)
hitboxEnabled = false -- Global for keybind access
hitboxSize = 10

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- prefer non-blocking find; if missing, use nil and continue
local zombieFolder = Workspace:FindFirstChild("Zombies")
if not zombieFolder then
    warn("Bruh")
end

-- Helper to notify + lock UI widgets safely
local function notifyHitboxErrorAndLock(widgets)
    pcall(function()
        if WindUI then
            WindUI:Notify({
                Title = "Hitbox — Error",
                Content = "Hitbox had an error and will be locked.",
                Duration = 4,
                Icon = "alert-circle",
            })
        end
    end)
    -- lock all provided widgets (toggle + sliders)
    pcall(function()
        for _, w in ipairs(widgets or {}) do
            if w and type(w.Lock) == "function" then
                w:Lock()
            end
        end
    end)
end

-- safe create hitbox part
local function safeCreateHitbox(parent, name, size, attachPart)
    local ok, err = pcall(function()
        if not parent or not parent.Parent then return end
        local part = Instance.new("Part")
        -- Use stealth name for anti-detection
        part.Name = _G.getRandomStealthName and _G.getRandomStealthName() or (name .. "_" .. math.random(10000, 99999))
        part.Size = Vector3.new(size, size, size)
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
    if not zombie then return end
    if hitboxEnabled then
        -- remove old then create new; use pcall to catch errors
        local ok, err = pcall(function()
            removeHitboxes(zombie)
            task.wait(0.05)
            addOuterHitbox(zombie)
            addHeadHitbox(zombie)
        end)
        if not ok then
            return false, err
        end
    else
        removeHitboxes(zombie)
    end
    return true
end

local function setHitboxSize(newSize, widgetsToLock)
    hitboxSize = newSize
    if hitboxEnabled then
        local ok, err = pcall(function()
            -- Attempt on zombieFolder if exists
            if zombieFolder then
                for _, zombie in pairs(zombieFolder:GetChildren()) do
                    updateHitboxes(zombie)
                end
            end
            -- Camera fallback (some maps put m_Zombie under Camera)
            if Workspace:FindFirstChild("Camera") then
                for _, zombie in pairs(Workspace.Camera:GetChildren()) do
                    if zombie.Name == "m_Zombie" then
                        updateHitboxes(zombie)
                    end
                end
            end
        end)
        if not ok then
            warn("setHitboxSize encountered an error:", err)
            notifyHitboxErrorAndLock(widgetsToLock)
        end
    end
end

local function toggleHitboxExpander(enabled, widgetsToLock)
    hitboxEnabled = enabled

    local ok, err = pcall(function()
        if zombieFolder then
            for _, zombie in pairs(zombieFolder:GetChildren()) do
                updateHitboxes(zombie)
            end
        end
        if Workspace:FindFirstChild("Camera") then
            for _, zombie in pairs(Workspace.Camera:GetChildren()) do
                if zombie.Name == "m_Zombie" then
                    updateHitboxes(zombie)
                end
            end
        end
    end)

    if not ok then
        warn("toggleHitboxExpander encountered an error:", err)
        -- rollback logical state
        hitboxEnabled = false
        -- remove any partial hitboxes
        pcall(function()
            if zombieFolder then
                for _, z in pairs(zombieFolder:GetChildren()) do removeHitboxes(z) end
            end
        end)
        notifyHitboxErrorAndLock(widgetsToLock)
    end
end

-- auto-apply to new zombies (guards to ensure no yield)
if zombieFolder then
    zombieFolder.ChildAdded:Connect(function(zombie)
        if hitboxEnabled then
            task.wait(0.2)
            pcall(function() updateHitboxes(zombie) end)
        end
    end)
end

-- Camera fallback connection (non-blocking)
if Workspace:FindFirstChild("Camera") then
    Workspace.Camera.ChildAdded:Connect(function(zombie)
        if zombie.Name == "m_Zombie" and hitboxEnabled then
            task.wait(0.2)
            pcall(function() updateHitboxes(zombie) end)
        end
    end)
end

-- Keep references to UI widgets so we can lock them on errors
toggleWidgetRef = nil -- Global for keybind access
local sliderSizeWidgetRef
local sliderRangeWidgetRef

-- Create toggle (capture reference)
toggleWidgetRef = HitboxSection:Toggle({
    Title = "Hitbox Expander",
    Flag = "Expander",
    Desc = "Expands zombie hitboxes for easier hits.",
    Default = false,
    Callback = function(value)
        -- pass the UI widgets list so errors lock them
        toggleHitboxExpander(value, { toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
        pcall(function()
            if WindUI then
                WindUI:Notify({
                    Title = "Hitbox",
                    Content = value and "Hitbox Expander enabled" or "Hitbox Expander disabled",
                    Duration = 2,
                    Icon = value and "scan" or "scan-line",
                })
            end
        end)
    end
})
_G.LanderToggleElements = _G.LanderToggleElements or {}
_G.LanderToggleElements.HitboxExpander = toggleWidgetRef

-- Slider: Hitbox Size (capture reference)
sliderSizeWidgetRef = HitboxSection:Slider({
    Title = "Hitbox Zombie Size",
    Flag = "Zombie_Size",
    Step = 1,
    Value = {
        Min = 1,
        Max = 30,
        Default = hitboxSize,
    },
    Callback = function(value)
        -- pass widgets so setHitboxSize can lock them on error
        setHitboxSize(value, { toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
    end
})

-- Slider: Hitbox Range (capture reference)
sliderRangeWidgetRef = HitboxSection:Slider({
    Title = "Hitbox Zombie Range",
    Flag = "Zombie_Range",
    Step = 1,
    Value = {
        Min = 0,
        Max = 30,
        Default = MaxRange or 30,
    },
    Callback = function(value)
        -- just set MaxRange; if you need errors to lock, call notifyHitboxErrorAndLock
        local ok, err = pcall(function()
            MaxRange = value
        end)
        if not ok then
            warn("Setting MaxRange failed:", err)
            notifyHitboxErrorAndLock({ toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
        end
    end
})

-- If initial state is broken (e.g., Camera and Zombies missing), lock UI immediately and notify
local cameraExists = Workspace:FindFirstChild("Camera") ~= nil
if (not zombieFolder) and (not cameraExists) then
    warn("Hitbox Locked Due to an error.")
    notifyHitboxErrorAndLock({ toggleWidgetRef, sliderSizeWidgetRef, sliderRangeWidgetRef })
end
end -- end of Legit & Hitbox Section

task.wait(0.1) -- Delay to prevent lag
do -- // Shove Hitbox Section
-- ===== SHOVE HITBOX EXPANDER SECTION =====
-- Initialize global variables for Shove Hitbox Expander (so they exist before Classes section loads)
ShoveHitboxExpanderEnabled = false
ShoveHitboxExpanderRange = 20
ShoveHitboxExpanderTargets = 10
ShoveHitboxExpanderDelay = 0.03
ShoveHitboxAnimConnection = nil

local ShoveHitboxSection = MainTab:Section({ Title = "Shove Hitbox", Icon = "zap", Opened = false })

local ShoveHitboxToggle = ShoveHitboxSection:Toggle({
    Title = "Shove Hitbox",
    Flag = "Shove_Hitbox",
    Desc = "Expands the shove hitbox.",
    Default = false,
    Callback = function(v)
        ShoveHitboxExpanderEnabled = v
        -- Disconnect animation watcher when disabled to prevent any shove firing
        if not v and ShoveHitboxAnimConnection then
            pcall(function() ShoveHitboxAnimConnection:Disconnect() end)
            ShoveHitboxAnimConnection = nil
        elseif v then
            -- Re-attach animation watcher when enabled
            if _G.AttachShoveHitboxWatcher then
                pcall(_G.AttachShoveHitboxWatcher)
            end
        end
        WindUI:Notify({
            Title = "Shove Hitbox",
            Content = v and ("Shove Hitbox Expander Enabled") or "Shove Hitbox Expander Disabled",
            Duration = 2,
            Icon = v and "zap" or "x"
        })
    end
})
_G.LanderToggleElements = _G.LanderToggleElements or {}
_G.LanderToggleElements.ShoveHitbox = ShoveHitboxToggle

ShoveHitboxSection:Slider({
    Title = "Hit Range",
    Flag = "Hit_Range",
    Desc = "Shove reach distance.",
    Step = 1,
    Value = { Min = 1, Max = 15, Default = 15 },
    Callback = function(v)
        ShoveHitboxExpanderRange = v
    end
})

ShoveHitboxSection:Slider({
    Title = "Max Targets",
    Flag = "Max_Targets",
    Desc = "Zombies hit per shove.",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = 10 },
    Callback = function(v)
        ShoveHitboxExpanderTargets = v
    end
})

-- ===== AUTO PARRY SAPPER SECTION =====
-- Initialize global variable
AutoParrySapperMeleeEnabled = false

local AutoParrySapperToggle = ShoveHitboxSection:Toggle({
    Title = "Auto Parry Sapper",
    Flag = "Auto_Parry_Sapper",
    Desc = "Auto parry when a Zapper attacks.",
    Default = false,
    Callback = function(v)
        AutoParrySapperMeleeEnabled = v
        WindUI:Notify({
            Title = "Auto Parry Sapper",
            Content = v and "Auto Parry Enabled" or "Auto Parry Disabled",
            Duration = 2,
            Icon = v and "shield" or "shield-off"
        })
    end
})
_G.LanderToggleElements.AutoParrySapper = AutoParrySapperToggle

    -- Cleanup function  
    local function cleanup()  
        changeBayonet(false)  
        changeMelee(false)  
        AutoHeadEnabled = false  
        LastHitTime = {}  
        IsIgniter = {}  
        Remote = nil  
    end  
  
    _G.LanderHeadHitCleanup = cleanup
end -- end of Shove Hitbox Section

task.wait(0.1) -- Delay to prevent lag
do -- // Auto Gun Aim Section
-- Auto Universal Gun Aim — IMPROVED: multi-type selection, movement-based time-shots,
-- dynamic retargeting if obstructed/died, and preserves previous features (reload, wall checks, save players)
-- + FOV FEATURE + TARGET ESP (yellow chams)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
-- === CONFIG (core timings) ===
local LOOK_DURATION = 0.28
local MAX_TARGET_RANGE = 200
local FIRE_DELAY_AFTER_LOOK = 0.03
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

-- Silent Aim zombie type selection (must be declared here so loop can access it)
-- Note: These are intentionally not local so they can be accessed by the Gun Tab UI section
SilentAimZombieTypes = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SilentAimSelectedTypes = {} -- Array of selected zombie types for silent aim
SilentAimEnabledTypes = {} -- Per-type enabled state
for _, t in ipairs(SilentAimZombieTypes) do SilentAimEnabledTypes[t] = false end

-- Silent Aim FOV settings (must be declared here so loop can access it)
local SILENT_AIM_USE_FOV = false
local SILENT_AIM_SHOW_FOV = false
SILENT_AIM_MOBILE_FOV = false
local SILENT_AIM_FOV_SIZE = 50

-- Forward declaration for Silent Aim FOV check function (defined later in UI section)
local isWorldPosInSilentAimFov = function(worldPos)
    -- Stub that returns true (no FOV restriction) until the real function is defined
    if not SILENT_AIM_USE_FOV then return true end
    -- Basic screen-center FOV check as fallback
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local viewportSize = cam.ViewportSize
    local centerVec = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerVec).Magnitude
    local sizePx = (math.clamp(SILENT_AIM_FOV_SIZE, 10, 120) / 40) * 250
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
local activeConnections = {}
local characterAddedConn = nil
local reloadInProgress = setmetatable({}, { __mode = "k" })  -- Track which tools are currently reloading
-- Shooting type selection state (multi-select)
-- Note: These are intentionally not local so they can be accessed by the Gun Tab UI section
ShootTypeList = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SelectedShootTypes = {} -- array of strings selected in UI
EnabledShootTypes = {} -- toggled enabled per selected type (keeps parity with UI)
for _, t in ipairs(ShootTypeList) do EnabledShootTypes[t] = false end
local getPredictedAimPosition -- forward declaration
local getAimPosition -- forward declaration
local PartVelocityCache = setmetatable({}, { __mode = "k" })
local function getHistoricalVelocity(part)
    if not part or not part.Parent then return nil end
    local now = os.clock()
    local pos = part.Position
    local entry = PartVelocityCache[part]
    if entry then
        local dt = math.max(now - entry.time, EPS)
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
        PartVelocityCache[part] = {
            pos = pos,
            time = now,
            vel = Vector3.new(0, 0, 0),
            lastSpeed = 0,
            lastMoveTime = nil,
        }
    end
    return nil
end

local function hasRecentMovement(part)
    local entry = PartVelocityCache[part]
    if not entry or not entry.lastMoveTime then
        return false
    end
    return (os.clock() - entry.lastMoveTime) <= PREDICTION_STILLNESS_WINDOW
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
        local vel = root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
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
    if fovGui and fovGui.Parent then
        return fovGui, fovCircle
    end

    local pg
    if type(getPlayerGui) == "function" then
        pg = getPlayerGui()
    else
        pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    end

    fovGui = Instance.new("ScreenGui")
    fovGui.ResetOnSpawn = false
    if _G.protectGUI then _G.protectGUI(fovGui) else fovGui.Parent = pg end -- Use stealth protection

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundTransparency = 1 -- no fill
    circle.BorderSizePixel = 0
    circle.Parent = fovGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 0)
    stroke.Transparency = 0.2
    stroke.Parent = circle

    fovCircle = circle
    return fovGui, fovCircle
end

local function getFovScreenCenter()
    local cam = Workspace.CurrentCamera
    if not cam then
        return Vector2.new(0, 0)
    end

    local viewportSize = cam.ViewportSize

    -- If MOBILE FOV is on OR mouse is locked (ShiftLock / right-click lock),
    -- use the center of the screen
    if MOBILE_FOV or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end

    -- Otherwise, use the real mouse position, adjusted for GUI inset
    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()

    -- mousePos includes the top bar; ViewportPoint uses inset-removed coords.
    -- So we subtract inset to get into the same space as ViewportPoint.
    return mousePos - Vector2.new(inset.X, inset.Y)
end

local fovFrameCounter = 0
local FOV_UPDATE_INTERVAL = 2 -- Update every N frames for performance
local function ensureFovUpdateLoop()
    if fovUpdateConn then return end

    fovUpdateConn = RunService.RenderStepped:Connect(function()
        if not (USE_FOV and SHOW_FOV) then
            if fovGui then fovGui.Enabled = false end
            return
        end
        
        -- Throttle updates for performance
        fovFrameCounter = fovFrameCounter + 1
        if fovFrameCounter < FOV_UPDATE_INTERVAL then return end
        fovFrameCounter = 0

        local gui, circle = ensureFovGui()
        gui.Enabled = true

        local cam = Workspace.CurrentCamera
        if not cam then return end

        -- size in pixels (same mapping as before: 40° -> 250px)
        local clamped = math.clamp(FOV_SIZE_DEG, FOV_MIN_DEG, FOV_MAX_DEG)
        local sizePx = math.floor((clamped / 40) * 250)
        circle.Size = UDim2.new(0, sizePx, 0, sizePx)

        -- center position using unified helper (handles mobile + shiftlock + inset)
        local viewportSize = cam.ViewportSize
        local centerVec = getFovScreenCenter()

        local xScale = centerVec.X / viewportSize.X
        local yScale = centerVec.Y / viewportSize.Y

        circle.Position = UDim2.new(xScale, 0, yScale, 0)
    end)
end

function updateFovCircle() -- Global for keybind access
    if not (USE_FOV and SHOW_FOV) then
        if fovGui then fovGui.Enabled = false end
        return
    end
    -- make sure the render-stepped loop is running
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
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerVec).Magnitude

    local clamped = math.clamp(FOV_SIZE_DEG, FOV_MIN_DEG, FOV_MAX_DEG)
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

local TARGET_CHAMS_TRANSPARENCY = 0.4
local TARGET_CHAMS_COLOR = Color3.fromRGB(255, 220, 50) -- yellow
local AIM_DOT_COLOR = Color3.fromRGB(255, 0, 0) -- red dot
local AIM_DOT_SIZE = 12 -- pixels
local AIM_DOT_LERP_SPEED = 15 -- How fast the dot moves to target (higher = faster)

-- Get player head position as default dot position
local function getPlayerHeadPosition()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position + Vector3.new(0, 1, 0) -- Slightly above head
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        return hrp.Position + Vector3.new(0, 2, 0)
    end
    return nil
end

-- Create billboard aim dot
local function createAimDot()
    if activeAimDot and activeAimDot.Parent then return activeAimDot end
    
    local startPos = getPlayerHeadPosition() or Vector3.new(0, 100, 0)
    
    -- Create invisible anchor part
    local anchorPart = Instance.new("Part")
    -- Use stealth name for anti-detection
    anchorPart.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("Anchor_" .. math.random(10000, 99999))
    anchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
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
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = anchorPart
    
    -- Create circular dot frame
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
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
    stroke.Color = Color3.fromRGB(255, 255, 255)
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
    local low = (_G.LanderPerf and _G.LanderPerf.lowEndMode) or (_G.LowEndMode == true)
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
                if type(getPredictedAimPosition) == "function" then
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
            targetPos = getPlayerHeadPosition() or Vector3.new(0, 100, 0)
        end
        
        -- Initialize current position if needed
        if not activeAimDotCurrentPos then
            activeAimDotCurrentPos = activeAimDotPart.Position
        end
        
        -- Smoothly interpolate to target position
        local lerpAlpha = math.clamp(deltaTime * AIM_DOT_LERP_SPEED, 0, 1)
        activeAimDotCurrentPos = activeAimDotCurrentPos:Lerp(targetPos, lerpAlpha)
        
        -- Update anchor part position (billboard follows it)
        activeAimDotPart.Position = activeAimDotCurrentPos
    end)
end

-- PERFORMANCE FIX: Don't start aim dot loop immediately - only start when AIM_DOT_ENABLED is set
-- startAimDotUpdateLoop() will be called when the toggle is turned on
if AIM_DOT_ENABLED then
    startAimDotUpdateLoop()
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
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = math.clamp(TARGET_CHAMS_TRANSPARENCY, 0, 1)
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
    local now = os.clock()
    if now - lastReloadNotify < NOTIFY_COOLDOWN then return end
    lastReloadNotify = now
    pcall(function()
        if type(WindUI) == "table" and type(WindUI.Notify) == "function" then
            pcall(function()
                WindUI:Notify({ Title = "Auto Reload", Content = "A Round Has Been Reloaded.", Duration = 3, Icon = "refresh-cw" })
            end)
            return
        end
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = "Auto Reload"; Text = "A Round Has Been Reloaded."; Duration = 3; })
        end)
    end)
end
-- Helper: is this tool a gun?
local function isGun(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local animFolder = tool:FindFirstChild("Animations")
    if not animFolder then return false end
    if animFolder:FindFirstChild("Aim") then return true end
    if animFolder:FindFirstChild("Aiming") then return true end
    return false
end
-- Utility: build a base ignore list for raycasts (players and camera zombies)
local function buildBaseIgnore()
    local baseIgnore = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        local ch = pl.Character
        if ch and ch:IsA("Model") then table.insert(baseIgnore, ch) end
    end
    local camFolderInst = Workspace:FindFirstChild("Camera")
    if camFolderInst then
        for _, d in ipairs(camFolderInst:GetDescendants()) do
            if d and d:IsA("Model") and d.Name == "m_Zombie" then table.insert(baseIgnore, d) end
        end
    end
    return baseIgnore
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
-- NEW: stricter, whitelist-aware obstruction check.
-- Returns true => obstructed; false => not obstructed.
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
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local filter = {}
    if baseIgnore then
        for i = 1, #baseIgnore do filter[#filter + 1] = baseIgnore[i] end
    end
    -- always ignore the local player's character so we don't accidentally hit ourselves
    if LocalPlayer and LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    params.FilterDescendantsInstances = filter
    local maxIterations = 16
    local remainingDistance = dist
    local originPos = actualOrigin
    local dirUnit = dir.Unit
    local epsilon = 0.25
    -- PERF: cache player list once outside the iteration loop (was called inside, up to 16×7=112 times)
    local _playersList = Players:GetPlayers()
    for i = 1, maxIterations do
        local ok, result = pcall(function()
            return Workspace:Raycast(originPos, dirUnit * remainingDistance, params)
        end)
        -- If raycast failed or no hit -> clear line of sight
        if not ok or not result then
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
        for _, pl in ipairs(_playersList) do
            local ch = pl.Character
            if ch and hitInst:IsDescendantOf(ch) then nonBlocking = true; break end
        end
        if nonBlocking then
            -- add this instance to the filter and continue the ray
            table.insert(params.FilterDescendantsInstances, hitInst)
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

-- Helper: sample multiple positions around the aim part so we only fire when most of the part is visible.
local function getWallCheckSamplePositions(part, aimPosOverride)
    if not part or not part.Parent then return {} end
    local basePos = aimPosOverride or part.Position
    local cf = part.CFrame
    local size = part.Size or Vector3.new(1, 1, 1)
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
    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(0, yOff, 0),
        Vector3.new(0, -yOff, 0),
        Vector3.new(xOff, 0, 0),
        Vector3.new(-xOff, 0, 0),
        Vector3.new(0, 0, zOff),
        Vector3.new(0, 0, -zOff)
    }
    local samples = {}
    for _, offset in ipairs(offsets) do
        local worldOffset = cf:VectorToWorldSpace(offset)
        samples[#samples + 1] = basePos + worldOffset
    end
    return samples
end

local function hasClearShotOnPart(originPos, aimPart, targetModel, baseIgnore, aimPosOverride)
    if not CHECK_WALLS then return true end
    if not originPos or not aimPart or not aimPart.Parent then return false end
    local samples = getWallCheckSamplePositions(aimPart, aimPosOverride)
    if #samples == 0 then return false end
    local requiredClear = math.max(1, math.ceil(#samples * WALL_CHECK_REQUIRED_CLEAR_RATIO))
    local clearCount = 0
    for _, samplePos in ipairs(samples) do
        local obstructed = isObstructedBetweenIterative(originPos, samplePos, targetModel, baseIgnore)
        if not obstructed then
            clearCount = clearCount + 1
            if clearCount >= requiredClear then
                return true
            end
        end
    end
    return false
end
-- (Timing helper removed; prediction slider handles movement compensation)
-- Helper: check if a zombie model is moving
local function isZombieMoving(zombie)
    if not zombie or not zombie.Parent then return false end
    
    -- Try to get velocity from HumanoidRootPart or any BasePart
    local hrp = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso") or zombie:FindFirstChild("UpperTorso")
    if hrp and hrp:IsA("BasePart") then
        local vel = hrp.AssemblyLinearVelocity
        if vel and vel.Magnitude > 0.5 then -- Moving threshold
            return true
        end
    end
    
    -- Fallback: check any part's velocity
    for _, part in ipairs(zombie:GetDescendants()) do
        if part:IsA("BasePart") then
            local vel = part.AssemblyLinearVelocity
            if vel and vel.Magnitude > 0.5 then
                return true
            end
            break -- Only check one part for performance
        end
    end
    
    return false
end

-- Helper: get adornee/aim part from zombie model.
-- If moving: aim for Torso (larger target, better for prediction)
-- If stationary: aim for Head (more damage)
local function findBestAimPart(zombie)
    if not zombie or not zombie.Parent then return nil end
    
    -- Check if zombie is moving
    local moving = isZombieMoving(zombie)
    
    if moving then
        -- Moving target: prioritize Torso for better hit chance with prediction
        local torso = zombie:FindFirstChild("Torso")
            or zombie:FindFirstChild("UpperTorso")
            or zombie:FindFirstChild("HumanoidRootPart")
        if torso and torso:IsA("BasePart") then return torso end
        
        -- Fallback to head if no torso
        local head = zombie:FindFirstChild("Head", true)
        if head and head:IsA("BasePart") then return head end
    else
        -- Stationary target: prioritize Head for more damage
        local head = zombie:FindFirstChild("Head", true)
        if head and head:IsA("BasePart") then return head end
        
        -- Fallback to torso if no head
        local torso = zombie:FindFirstChild("Torso")
            or zombie:FindFirstChild("UpperTorso")
            or zombie:FindFirstChild("HumanoidRootPart")
        if torso and torso:IsA("BasePart") then return torso end
    end
    
    -- Special case: Bomber barrel (always valid target)
    local barrel = zombie:FindFirstChild("Barrel", true)
    if barrel and barrel:IsA("BasePart") then return barrel end
    
    -- Fallback: PrimaryPart or any BasePart
    if zombie.PrimaryPart and zombie.PrimaryPart:IsA("BasePart") then
        return zombie.PrimaryPart
    end
    for _, p in ipairs(zombie:GetDescendants()) do
        if p:IsA("BasePart") then
            return p
        end
    end
    return nil
end
getPredictedAimPosition = function(part)
    if not part or not part.Parent or not part:IsA("BasePart") then return nil end
    local position = part.Position
    local leadTime = tonumber(PREDICTION_DISTANCE) or 0
    if leadTime <= EPS then
        return position
    end
    local vel = part.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
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
        entry.lastMoveTime = os.clock()
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
-- Helper: resolve zombie type from real zombie models in workspace.Zombies.Agent or workspace.Zombies.Slim
-- PERFORMANCE: Cache zombie type lookups (weak keys so destroyed zombies get GC'd)
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
    
    -- Agent types: check Agent folder inside the zombie model for Type
    local agent = model:FindFirstChild("Agent")
    if agent then
        local typeValue = agent:FindFirstChild("Type")
        if typeValue and typeValue:IsA("StringValue") then
            local t = string.lower(typeValue.Value or "")
            local result = nil
            if t == "normal" then result = "Shambler"
            elseif t == "barrel" then result = "Bomber"
            elseif t == "fast" then result = "Runner"
            elseif t == "sapper" then result = "Zapper"
            elseif t == "igniter" then result = "Igniter"
            elseif t == "cuirassier" then result = "Cuirassier" end
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
            local lower = string.lower(t)
            local result = nil
            if lower == "normal" then result = "Shambler"
            elseif lower == "barrel" then result = "Bomber"
            elseif lower == "fast" then result = "Runner"
            elseif lower == "sapper" then result = "Zapper"
            elseif lower == "igniter" then result = "Igniter"
            elseif lower == "cuirassier" then result = "Cuirassier" end
            if result then
                ZombieTypeCache[model] = result
                return result
            end
        end
    end
    
    -- Fallback heuristics for detection (only runs once per zombie, result is cached)
    local result = "Shambler" -- default
    if model:FindFirstChild("Barrel", true) then result = "Bomber"
    elseif model:FindFirstChild("Whale Oil Lantern", true) then result = "Igniter"
    elseif model:FindFirstChild("Sword", true) then result = "Cuirassier"
    elseif model:FindFirstChild("Axe", true) and model:FindFirstChild("Head", true) then result = "Zapper"
    elseif model:FindFirstChild("Eye", true) and not model:FindFirstChild("Axe", true) then result = "Runner"
    end
    
    ZombieTypeCache[model] = result
    return result
end
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
    
    local bomberPart = bomberModel:FindFirstChild("HumanoidRootPart") or bomberModel:FindFirstChildWhichIsA("BasePart")
    if not bomberPart then return false end
    local bomberPos = bomberPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
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
    
    local bomberPart = bomberModel:FindFirstChild("HumanoidRootPart") or bomberModel:FindFirstChildWhichIsA("BasePart")
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
    
    if BOMBER_SAFE_TEAMMATES and isBomberNearTeammate(model, BOMBER_SAFE_RADIUS) then
        return true
    end
    
    if BOMBER_SAFE_SELF and isBomberNearSelf(model, BOMBER_SAFE_RADIUS) then
        return true
    end
    
    -- Check "Don't Shoot Near" whitelist - skip if any whitelisted player is near the bomber
    if #BomberSafetyWhitelist > 0 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local isWhitelisted = false
                for _, name in ipairs(BomberSafetyWhitelist) do
                    if player.Name == name or player.DisplayName == name then
                        isWhitelisted = true
                        break
                    end
                end
                if isWhitelisted then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bomberPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                            if bomberPart then
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
    end
    
    -- If SHOOT_BOMBER_NEAR_TEAMMATES is enabled, check whitelist or all teammates
    if SHOOT_BOMBER_NEAR_TEAMMATES then
        -- If whitelist has entries, only shoot if whitelisted player is near
        if #ShootBomberNearWhitelist > 0 then
            local whitelistedPlayerNear = false
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local isWhitelisted = false
                    for _, name in ipairs(ShootBomberNearWhitelist) do
                        if player.Name == name or player.DisplayName == name then
                            isWhitelisted = true
                            break
                        end
                    end
                    if isWhitelisted then
                        local char = player.Character
                        if char then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local bomberPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                                if bomberPart then
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

-- Helper: Create/update bomber radius visualization
-- PERFORMANCE FIX: Pre-allocate seenBombers table to avoid GC churn every 0.5s
local _seenBombersBuf = {}
local function updateBomberRadiusVisuals()
    if not BOMBER_VISUALIZE_RADIUS then return end
    
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then return end
    
    -- Reuse buffer instead of creating new table every call
    for k in pairs(_seenBombersBuf) do _seenBombersBuf[k] = nil end
    
    -- PERFORMANCE FIX: Use GetChildren on Agent/Slim specifically instead of GetDescendants on entire folder
    local function scanFolder(folder)
        if not folder then return end
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and GetZombieTypeFromModel(model) == "Bomber" then
                _seenBombersBuf[model] = true
            
                local bomberPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                if bomberPart then
                    -- Create or update visual
                    if not BomberRadiusVisuals[model] then
                        local circle = Instance.new("Part")
                        -- Use stealth name for anti-detection
                        circle.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("RadVis_" .. math.random(10000, 99999))
                        circle.Shape = Enum.PartType.Cylinder
                        circle.Size = Vector3.new(0.2, BOMBER_SAFE_RADIUS * 2, BOMBER_SAFE_RADIUS * 2) -- Thin flat cylinder
                        circle.Anchored = true
                        circle.CanCollide = false
                        circle.Transparency = 0 -- Fully opaque
                        circle.Material = Enum.Material.Neon
                        circle.Color = Color3.fromRGB(255, 100, 0) -- Default orange
                        circle.CFrame = CFrame.new(bomberPart.Position) * CFrame.Angles(0, 0, math.rad(90)) -- Rotate to be flat
                        circle.Parent = Workspace
                        BomberRadiusVisuals[model] = circle
                    end
                    
                    -- Get the bomber's foot position (ground level)
                    local bomberPos = bomberPart.Position
                    local footY = bomberPos.Y - 3 -- Approximate feet position (HRP is ~3 studs above ground)
                    
                    -- Update position - flat circle at feet level
                    BomberRadiusVisuals[model].CFrame = CFrame.new(bomberPos.X, footY, bomberPos.Z) * CFrame.Angles(0, 0, math.rad(90))
                    
                    -- Determine circle color based on who's inside the blast radius
                    local selfInside = false
                    local teammateInside = false
                    
                    -- Check if local player is inside
                    if BOMBER_SAFE_SELF then
                        local char = LocalPlayer.Character
                        if char then
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local dist = (hrp.Position - bomberPos).Magnitude
                                if dist <= BOMBER_SAFE_RADIUS then
                                    selfInside = true
                                end
                            end
                        end
                    end
                    
                    -- Check if any teammate is inside
                    if BOMBER_SAFE_TEAMMATES then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    local dist = (hrp.Position - bomberPos).Magnitude
                                    if dist <= BOMBER_SAFE_RADIUS then
                                        teammateInside = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Set color: Red if self inside (priority), Yellow if teammate inside, Orange otherwise
                    if selfInside then
                        BomberRadiusVisuals[model].Color = Color3.fromRGB(255, 0, 0) -- Red
                    elseif teammateInside then
                        BomberRadiusVisuals[model].Color = Color3.fromRGB(255, 255, 0) -- Yellow
                    else
                        BomberRadiusVisuals[model].Color = Color3.fromRGB(255, 100, 0) -- Default orange
                    end
                end
            end
        end
    end
    
    -- Scan Agent and Slim folders specifically (avoids GetDescendants on entire Zombies folder)
    scanFolder(zombiesFolder:FindFirstChild("Agent"))
    scanFolder(zombiesFolder:FindFirstChild("Slim"))
    
    -- Clean up visuals for bombers that no longer exist
    for model, visual in pairs(BomberRadiusVisuals) do
        if not _seenBombersBuf[model] or not model.Parent then
            pcall(function() visual:Destroy() end)
            BomberRadiusVisuals[model] = nil
        end
    end
end

-- Run bomber visualization loop (deferred to prevent load freeze)
task.defer(function()
    task.wait(2) -- Stagger start
    while true do
        -- PERFORMANCE: Only run if visualization is enabled
        if BOMBER_VISUALIZE_RADIUS then
            pcall(updateBomberRadiusVisuals)
            task.wait(0.5) -- Update at normal rate when active
        else
            -- PERFORMANCE: Sleep longer when disabled to reduce overhead
            task.wait(2)
        end
    end
end)

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

-- Get nearest zombie among selected types; returns aimPart, zombieModel, typeName
-- Scans workspace.Camera for visual models (for targeting) but can use real zombies for velocity
local function getNearestSelectedZombie(range, selectionList, useFovFlag, fovChecker)
    range = range or MAX_TARGET_RANGE
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
    local bestPart, bestDist, bestModel, bestType = nil, range + EPS, nil, nil
    
    -- build a selected types lookup
    local selection = selectionList or SelectedShootTypes
    local sel = {}
    for _, t in ipairs(selection or {}) do
        sel[t] = true
    end
    if not next(sel) then
        return nil, nil, nil
    end
    -- choose FOV config (defaults to auto-shoot FOV)
    local useFov = (useFovFlag ~= nil) and useFovFlag or USE_FOV
    local fovFunc = fovChecker or isWorldPosInFov
    
    -- Scan real zombies in workspace.Zombies using GetAttribute("Type") for accurate detection
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then
        return nil, nil, nil
    end
    
    -- Scan all descendants in Zombies folder (covers Agent, Slim, and any other subfolders)
    for _, model in ipairs(zombiesFolder:GetDescendants()) do
        if model:IsA("Model") then
            -- Skip zombies that are still spawning
            if isZombieSpawning(model) then
                -- Zombie is spawning, skip it
            else
                -- Use GetZombieTypeFromModel which checks GetAttribute("Type") first
                local matchedType = GetZombieTypeFromModel(model)
                
                -- Check if this zombie type is selected
                if matchedType and sel[matchedType] then
                    -- Check bomber safety before targeting
                    if shouldSkipBomberForSafety(model, matchedType) then
                        -- Skip this bomber - too close to teammate or self
                    else
                        local aimPart = findBestAimPart(model)
                        if aimPart and aimPart:IsA("BasePart") then
                            local aimPos = getAimPosition(aimPart)
                            local passedFovCheck = true
                            if useFov then
                                local okFov, inFov = pcall(function()
                                    return fovFunc(aimPos)
                                end)
                                if not okFov or not inFov then
                                    passedFovCheck = false
                                end
                            end
                            if passedFovCheck then
                                local okDist, d = pcall(function()
                                    return (aimPos - originPos).Magnitude
                                end)
                                if okDist and d and d <= range + EPS and d < bestDist then
                                    -- Wall check for real zombies too
                                    local okVis, hasClear = pcall(function()
                                        return hasClearShotOnPart(originPos, aimPart, model, baseIgnore)
                                    end)
                                    if okVis and hasClear then
                                        bestPart, bestDist, bestModel, bestType = aimPart, d, model, matchedType
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestPart, bestModel, bestType
end

-- Get nearest zombie Torso to a visible player that needs saving
-- RETURNS: zombieTorso, zombieModel, targetPlayer
-- Now scans workspace.Zombies.Agent and workspace.Zombies.Slim for real zombie models with proper velocity
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
    local bestZombieTorso, bestZombieModel, bestPlayer, bestDist = nil, nil, nil, range + EPS
    
    -- Helper to scan a zombie folder
    local function scanZombieFolder(folder)
        if not folder then return end
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                -- Skip zombies that are still spawning
                if isZombieSpawning(model) then
                    continue
                end
                local zombieTorso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
                if zombieTorso and zombieTorso:IsA("BasePart") then
                    local zombiePos = getAimPosition(zombieTorso, { skipPrediction = true })
                    -- Check against each grabbed player
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            -- Check whitelist: if whitelist has entries, only save whitelisted players
                            local shouldSavePlayer = true
                            if #AutoSaveWhitelist > 0 then
                                shouldSavePlayer = false
                                for _, name in ipairs(AutoSaveWhitelist) do
                                    if player.Name == name or player.DisplayName == name then
                                        shouldSavePlayer = true
                                        break
                                    end
                                end
                            end
                            if shouldSavePlayer then
                                local playerFolder = wsPlayersFolder:FindFirstChild(player.Name)
                                if playerFolder then
                                    local userStates = playerFolder:FindFirstChild("UserStates")
                                    if userStates then
                                        local grabbedVal = userStates:FindFirstChild("Grabbed")
                                        local pinVal = userStates:FindFirstChild("Pin")
                                        local grabbed = (grabbedVal and tonumber(grabbedVal.Value) or 0) ~= 0
                                        local pinnedVal = (pinVal and pinVal.Value) or ""
                                        local pinned = pinnedVal == "RunnerAttack" or pinnedVal == "RunnerClaw" or pinnedVal == "RunnerVomit"
                                        if grabbed or pinned then
                                            local character = player.Character
                                            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                                            if humanoid and humanoid.Health >= 1 then
                                                if character and character:IsA("Model") then
                                                    local playerRoot = character:FindFirstChild("HumanoidRootPart")
                                                    if playerRoot and playerRoot:IsA("BasePart") then
                                                        local hasClearToPlayer = hasClearShotOnPart(originPos, playerRoot, character, baseIgnore)
                                                        if hasClearToPlayer then
                                                            local okDist, d = pcall(function()
                                                                return (zombiePos - playerRoot.Position).Magnitude
                                                            end)
                                                            if okDist and d and d <= range + EPS and d < bestDist then
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
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Scan both Agent and Slim folders
    scanZombieFolder(zombiesFolder:FindFirstChild("Agent"))
    scanZombieFolder(zombiesFolder:FindFirstChild("Slim"))
    
    -- If no result from real zombies, fallback to Camera folder
    if not bestZombieTorso then
        local camFolder = Workspace:FindFirstChild("Camera")
        if camFolder then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local playerFolder = wsPlayersFolder:FindFirstChild(player.Name)
                    if playerFolder then
                        local userStates = playerFolder:FindFirstChild("UserStates")
                        if userStates then
                            local grabbedVal = userStates:FindFirstChild("Grabbed")
                            local pinVal = userStates:FindFirstChild("Pin")
                            local grabbed = (grabbedVal and tonumber(grabbedVal.Value) or 0) ~= 0
                            local pinnedVal = (pinVal and pinVal.Value) or ""
                            local pinned = pinnedVal == "RunnerAttack" or pinnedVal == "RunnerClaw" or pinnedVal == "RunnerVomit"
                            if grabbed or pinned then
                                local character = player.Character
                                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                                if humanoid and humanoid.Health >= 1 then
                                    if character and character:IsA("Model") then
                                        local playerRoot = character:FindFirstChild("HumanoidRootPart")
                                        if playerRoot and playerRoot:IsA("BasePart") then
                                            local hasClearToPlayer = hasClearShotOnPart(originPos, playerRoot, character, baseIgnore)
                                            if hasClearToPlayer then
                                                for _, model in ipairs(camFolder:GetChildren()) do
                                                    if model:IsA("Model") and model.Name == "m_Zombie" then
                                                        -- Skip zombies that are still spawning
                                                        if isZombieSpawning(model) then
                                                            continue
                                                        end
                                                        local zombieTorso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
                                                        if zombieTorso and zombieTorso:IsA("BasePart") then
                                                            local zombiePos = getAimPosition(zombieTorso, { skipPrediction = true })
                                                            local okDist, d = pcall(function()
                                                                return (zombiePos - playerRoot.Position).Magnitude
                                                            end)
                                                            if okDist and d and d <= range + EPS and d < bestDist then
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
    if not tool then return nil end
    local remote = tool:FindFirstChild("RemoteEvent")
    if remote then return remote end
    local wsPlayersFolder = Workspace:FindFirstChild("Players")
    if not wsPlayersFolder then return nil end
    local playerFolder = wsPlayersFolder:FindFirstChild(LocalPlayer.Name)
    if not playerFolder then return nil end
    local toolFolder = playerFolder:FindFirstChild(tool.Name)
    if not toolFolder then return nil end
    return toolFolder:FindFirstChild("RemoteEvent")
end

-- Special reload handlers for specific gun types
local function reloadNockGun(tool)
    -- Nock Gun: StartReload, then spam Reload until ShotsLoaded reaches 7 (only if under 7)
    if not tool then return end
    
    -- Prevent overlapping reloads for the same tool
    if reloadInProgress[tool] then return end
    reloadInProgress[tool] = true
    
    local shots = getShotsLoadedForTool(tool)
    if shots >= 7 then
        reloadInProgress[tool] = nil
        return
    end
    
    local remote = findRemoteForTool(tool) or tool:FindFirstChild("RemoteEvent")
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    
    -- Step 1: Fire StartReload
    pcall(function() _G.SafeFireServer(remote, "StartReload") end)
    task.wait(0.1)
    
    -- Step 2: Spam Reload until ShotsLoaded is 7
    local attempts = 0
    local maxAttempts = 50
    while attempts < maxAttempts do
        local currentShots = getShotsLoadedForTool(tool)
        if currentShots >= 7 then
            -- Unequip and re-equip when full
            pcall(function() tool.Parent = LocalPlayer.Backpack end)
            task.wait(0.02)
            pcall(function() tool.Parent = LocalPlayer.Character end)
            break
        end
        pcall(function() _G.SafeFireServer(remote, "Reload") end)
        task.wait(0.05)
        attempts = attempts + 1
    end
    
    reloadInProgress[tool] = nil
end

local function reloadDoubleBarrelPistol(tool)
    -- Double Barrel Pistol: spam Reload until ShotsLoaded reaches 2 (only if at 0)
    if not tool then return end
    
    -- Prevent overlapping reloads for the same tool
    if reloadInProgress[tool] then return end
    reloadInProgress[tool] = true
    
    local shots = getShotsLoadedForTool(tool)
    if shots ~= 0 then
        reloadInProgress[tool] = nil
        return
    end
    
    local remote = findRemoteForTool(tool) or tool:FindFirstChild("RemoteEvent")
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    
    local attempts = 0
    local maxAttempts = 50
    while attempts < maxAttempts do
        local currentShots = getShotsLoadedForTool(tool)
        if currentShots >= 2 then
            -- Unequip and re-equip when full
            reloadInProgress[tool] = nil  -- Clear flag before unequip/reequip
            pcall(function() tool.Parent = LocalPlayer.Backpack end)
            task.wait(0.02)
            pcall(function() tool.Parent = LocalPlayer.Character end)
            task.wait(0.1)  -- Wait for reequip to complete
            return
        end
        pcall(function() _G.SafeFireServer(remote, "Reload") end)
        task.wait(0.05)
        attempts = attempts + 1
    end
    
    reloadInProgress[tool] = nil
end

local function reloadHorseArtilleryPistol(tool)
    -- Horse Artillery Pistol: StartReload, then spam Reload until ShotsLoaded reaches 2 (only if at 0)
    if not tool then return end
    
    -- Prevent overlapping reloads for the same tool
    if reloadInProgress[tool] then return end
    reloadInProgress[tool] = true
    
    local shots = getShotsLoadedForTool(tool)
    if shots ~= 0 then
        reloadInProgress[tool] = nil
        return
    end
    
    local remote = findRemoteForTool(tool) or tool:FindFirstChild("RemoteEvent")
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    
    -- Step 1: Fire StartReload
    pcall(function() _G.SafeFireServer(remote, "StartReload") end)
    task.wait(0.1)

    -- Step 2: Spam Reload until ShotsLoaded is 2
    local attempts = 0
    local maxAttempts = 50
    while attempts < maxAttempts do
        local currentShots = getShotsLoadedForTool(tool)
        if currentShots >= 2 then
            -- Unequip and re-equip when full
            reloadInProgress[tool] = nil  -- Clear flag before unequip/reequip
            
            -- Verify tool still exists and is in character
            if tool and tool.Parent == LocalPlayer.Character then
                pcall(function() 
                    tool.Parent = LocalPlayer.Backpack
                end)
                task.wait(0.02)
                pcall(function() 
                    tool.Parent = LocalPlayer.Character
                end)
                task.wait(0.1)  -- Wait for reequip to complete
            end
            return
        end
        pcall(function() _G.SafeFireServer(remote, "Reload") end)
        task.wait(0.05)
        attempts = attempts + 1
    end
    
    reloadInProgress[tool] = nil
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
    
    local remote = findRemoteForTool(tool) or tool:FindFirstChild("RemoteEvent")
    if not remote then
        reloadInProgress[tool] = nil
        return
    end
    pcall(function() _G.SafeFireServer(remote, "Reload") end)
    
    -- When ShotsLoaded reaches 1, unequip and re-equip the gun
    task.wait(0.2)
    local shots = getShotsLoadedForTool(tool)
    if shots == 1 then
        quickUnequipReequip(tool)
    end
    
    reloadInProgress[tool] = nil
end
local function tryReloadTool(tool)
    if not tool then return end
    if not AUTO_RELOAD_ENABLED then return end
    if not isGun(tool) then return end
    local shots = getShotsLoadedForTool(tool)
    
    -- Determine if reload is needed based on gun type
    local shouldReload = false
    if tool.Name == "Nock Gun" then
        shouldReload = shots < 7
    elseif tool.Name == "Double Barrel Pistol" or tool.Name == "Horse Artillery Pistol" then
        shouldReload = shots == 0
    else
        shouldReload = shots == 0  -- Normal guns reload only when empty
    end
    
    if shouldReload then
        -- Check gun name and fire appropriate reload sequence
        if tool.Name == "Nock Gun" then
            task.spawn(reloadNockGun, tool)
        elseif tool.Name == "Double Barrel Pistol" then
            task.spawn(reloadDoubleBarrelPistol, tool)
        elseif tool.Name == "Horse Artillery Pistol" then
            task.spawn(reloadHorseArtilleryPistol, tool)
        else
            task.spawn(reloadNormalGun, tool)
        end
    end
end

-- Simulate reload animations locally when auto-reload fires.
-- Plays reload animations found in the tool's `Animations` folder (ReloadP1/ReloadP2/ReloadP3/Reload)
local function simulateReloadAnimations(tool, forcePlay)
    if not tool then return end
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
    if not animator then return end

    -- We'll search for specific animation names in several likely locations
    local function findAnimationByName(name)
        if not name then return nil end
        -- 1) tool.Animations
        local animFolder = tool:FindFirstChild("Animations")
        if animFolder then
            local a = animFolder:FindFirstChild(name)
            if a and a:IsA("Animation") then return a end
        end
        -- 2) tool.Model or ModelReference -> Animations
        local modelRef = tool:FindFirstChild("Model") or tool:FindFirstChild("ModelReference")
        if modelRef then
            local model = (modelRef.Value and modelRef.Value) or modelRef
            if model and model:IsA("Model") then
                local mf = model:FindFirstChild("Animations")
                if mf then
                    local a = mf:FindFirstChild(name)
                    if a and a:IsA("Animation") then return a end
                end
            end
        end
        -- 3) Workspace.Players.<LocalPlayer>.<ToolName>.Animations (decompiled-style path)
        local wsPlayers = Workspace:FindFirstChild("Players")
        if wsPlayers and LocalPlayer and LocalPlayer.Name then
            local playerFolder = wsPlayers:FindFirstChild(LocalPlayer.Name)
            if playerFolder then
                local toolFolder = playerFolder:FindFirstChild(tool.Name)
                if toolFolder then
                    local af = toolFolder:FindFirstChild("Animations")
                    if af then
                        local a = af:FindFirstChild(name)
                        if a and a:IsA("Animation") then return a end
                    end
                end
            end
        end
        -- 4) search descendants as a last resort
        for _, d in ipairs(tool:GetDescendants()) do
            if d.Name == name and d:IsA("Animation") then return d end
        end
        return nil
    end

    local order = {"HammerDownLoaded", "ReloadP1", "ReloadP2", "HammerPull"}
    local seq = {}
    for _, name in ipairs(order) do
        local anim = findAnimationByName(name)
        if anim then table.insert(seq, anim) end
    end
    -- nothing to play
    if #seq == 0 then return end

    -- Helper: try to find a cartridge part in the tool or its model
    local function findCartridgePart(tool)
        if not tool then return nil end
        if tool:FindFirstChild("Cartridge") and tool.Cartridge:IsA("BasePart") then
            return tool.Cartridge
        end
        local model = tool:FindFirstChild("Model") or tool:FindFirstChild("ModelReference")
        if model and model.Value and model.Value:IsA("Model") then
            local c = model.Value:FindFirstChild("Cartridge")
            if c and c:IsA("BasePart") then return c end
        elseif model and model:IsA("Model") then
            local c = model:FindFirstChild("Cartridge")
            if c and c:IsA("BasePart") then return c end
        end
        return nil
    end

    -- Play sequentially without blocking main thread, and respond to animation markers
    task.spawn(function()
        local rightPart = nil
        local char = LocalPlayer and LocalPlayer.Character
        if char then
            rightPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or char:FindFirstChild("RightUpperArm") or char:FindFirstChild("RightArm")
        end

        local handCart = nil
        local originalCartridge = findCartridgePart(tool)

        for _, anim in ipairs(seq) do
            local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok or not track then
                task.wait(0.02)
            else
                track.Priority = Enum.AnimationPriority.Action

                -- Connect common marker events if available
                local conns = {}
                local function safeConnect(mName, fn)
                    local succ, conn = pcall(function() return track:GetMarkerReachedSignal(mName):Connect(fn) end)
                    if succ and conn then table.insert(conns, conn) end
                end

                safeConnect("HandCart", function()
                    -- create a hand cart clone and weld to right arm
                    if handCart then return end
                    local cartSrc = originalCartridge
                    if not cartSrc then
                        -- try to find a Cartridge under tool model
                        cartSrc = tool:FindFirstChild("Cartridge") or (tool:FindFirstChild("Model") and tool.Model:FindFirstChild("Cartridge"))
                    end
                    if cartSrc and rightPart then
                        local ok2, cloned = pcall(function() return cartSrc:Clone() end)
                        if ok2 and cloned then
                            cloned.Parent = tool
                            cloned.Transparency = 0
                            local weld = Instance.new("Weld")
                            weld.Part0 = rightPart
                            weld.Part1 = cloned
                            weld.C0 = CFrame.new(0, -0.85, -0.4)
                            weld.Parent = cloned
                            handCart = cloned
                        end
                    end
                end)

                safeConnect("HandCartOff", function()
                    if handCart and handCart.Parent then
                        handCart:Destroy()
                        handCart = nil
                    end
                    if originalCartridge and originalCartridge:IsA("BasePart") then
                        pcall(function() originalCartridge.Transparency = 0 end)
                    end
                end)

                safeConnect("PourPowder", function()
                    if handCart then
                        local powder = handCart:FindFirstChild("Powder", true)
                        if powder and powder:IsA("ParticleEmitter") then
                            powder.Enabled = true
                            task.delay(0.3, function() pcall(function() powder.Enabled = false end) end)
                        end
                    else
                        -- try to find particle on tool
                        local powder = tool:FindFirstChild("Powder", true)
                        if powder and powder:IsA("ParticleEmitter") then
                            powder.Enabled = true
                            task.delay(0.3, function() pcall(function() powder.Enabled = false end) end)
                        end
                    end
                end)

                safeConnect("CartOff", function()
                    if originalCartridge and originalCartridge:IsA("BasePart") then
                        pcall(function() originalCartridge.Transparency = 1 end)
                    end
                end)

                safeConnect("RipCart", function()
                    if handCart then
                        local ripped = handCart:FindFirstChild("Ripped")
                        if ripped then
                            ripped.Transparency = 0
                            handCart.Transparency = 1
                        end
                    end
                end)

                safeConnect("CartridgeStart", function()
                    if originalCartridge and originalCartridge:IsA("BasePart") then
                        pcall(function()
                            if originalCartridge.Parent and originalCartridge.Parent:IsA("Model") then
                                -- try to nudge weld if present
                                for _, w in ipairs(originalCartridge:GetJoints()) do
                                    if w:IsA("Weld") then
                                        w.C1 = w.C1 * CFrame.new(0, -0.03, 0)
                                        break
                                    end
                                end
                            end
                        end)
                    end
                end)

                -- Play and wait
                track:Play(0.02, 1, 1)
                pcall(function() track.Stopped:Wait() end)

                -- cleanup connections
                for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
                task.wait(0.02)
            end
        end

        -- ensure handCart cleanup
        if handCart and handCart.Parent then
            pcall(function() handCart:Destroy() end)
            handCart = nil
        end
    end)
end
local function watchShotsForTool(tool)
    if not tool then return end
    if not isGun(tool) then return end
    if watchedTools[tool] then return end
    watchedTools[tool] = true
    local function attach(shotsObj, reloadRemote)
        if not shotsObj then return end
        local prevVal = (shotsObj.Value ~= nil) and shotsObj.Value or 0
        
        -- Initial check: reload if below threshold for this gun
        if AUTO_RELOAD_ENABLED then
            local shouldReload = false
            if tool.Name == "Nock Gun" then
                shouldReload = prevVal < 7
            elseif tool.Name == "Double Barrel Pistol" or tool.Name == "Horse Artillery Pistol" then
                shouldReload = prevVal == 0
            else
                shouldReload = prevVal == 0
            end
            
            if shouldReload and reloadRemote then
                if tool.Name == "Nock Gun" then
                    task.spawn(reloadNockGun, tool)
                elseif tool.Name == "Double Barrel Pistol" then
                    task.spawn(reloadDoubleBarrelPistol, tool)
                elseif tool.Name == "Horse Artillery Pistol" then
                    task.spawn(reloadHorseArtilleryPistol, tool)
                else
                    task.spawn(reloadNormalGun, tool)
                end
            end
        end
        
        local reloadDebounce = false
        local conn
        conn = shotsObj.Changed:Connect(function()
            local v = shotsObj.Value
            if AUTO_RELOAD_ENABLED and type(v) == "number" and type(prevVal) == "number" and v > prevVal then
                -- PERFORMANCE FIX: Cap notification spawns to prevent burst if value jumps significantly
                local notifyCount = math.min(v - prevVal, 3)
                for i = 1, notifyCount do task.spawn(notifyReload) end
            end
            
            -- Check if reload is needed based on gun type
            local shouldReload = false
            if tool.Name == "Nock Gun" then
                shouldReload = v < 7
            elseif tool.Name == "Double Barrel Pistol" or tool.Name == "Horse Artillery Pistol" then
                shouldReload = v == 0
            else
                shouldReload = v == 0
            end
            
            if shouldReload and reloadRemote and not reloadDebounce then
                reloadDebounce = true
                if AUTO_RELOAD_ENABLED then
                    -- Trigger reload with appropriate handler for this tool
                    if tool.Name == "Nock Gun" then
                        task.spawn(reloadNockGun, tool)
                    elseif tool.Name == "Double Barrel Pistol" then
                        task.spawn(reloadDoubleBarrelPistol, tool)
                    elseif tool.Name == "Horse Artillery Pistol" then
                        task.spawn(reloadHorseArtilleryPistol, tool)
                    else
                        task.spawn(reloadNormalGun, tool)
                    end
                end
                task.delay(1.2, function() reloadDebounce = false end)
            end
            prevVal = v
        end)
        tool.AncestryChanged:Connect(function(_, parent)
            if not parent and conn then conn:Disconnect() end
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
local function smoothLookAtDynamic(rootPart, getPosFunc, duration)
    if not rootPart or not getPosFunc then return end
    local start = os.clock()
    local startCFrame = rootPart.CFrame
    local ok, initTarget = pcall(getPosFunc)
    if not ok or not initTarget then return end
    
    -- Smoother ease-in-out quintic function for more natural rotation
    local function easeInOutQuint(t)
        if t < 0.5 then
            return 16 * t * t * t * t * t
        else
            local f = (2 * t) - 2
            return 0.5 * f * f * f * f * f + 1
        end
    end
    
    while os.clock() - start < duration do
        if not rootPart.Parent then return end
        local curPos = nil
        pcall(function() curPos = getPosFunc() end)
        if not curPos then curPos = initTarget end
        local desired = CFrame.new(rootPart.Position, Vector3.new(curPos.X, rootPart.Position.Y, curPos.Z))
        local t = math.clamp((os.clock() - start) / duration, 0, 1)
        -- Use smoother quintic easing for more natural rotation
        local smoothT = easeInOutQuint(t)
        local lerped = startCFrame:Lerp(desired, smoothT)
        local safeCFrame = CFrame.new(rootPart.Position, rootPart.Position + lerped.LookVector)
        pcall(function() rootPart.CFrame = safeCFrame end)
        RunService.RenderStepped:Wait()
    end
    local finalPos = nil
    pcall(function() finalPos = getPosFunc() end)
    if finalPos then pcall(function() rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + CFrame.new(rootPart.Position, Vector3.new(finalPos.X, rootPart.Position.Y, finalPos.Z)).LookVector) end) end
end
-- Cache for animations to avoid recreating them
-- Uses weak values so dead tracks get garbage collected
local animationCache = setmetatable({}, { __mode = "v" })
local animationCacheLastClean = 0
local function playAnimation(animId, animator)
    if not animId or not animator then return nil end
    local cacheKey = animId .. tostring(animator)
    
    -- Periodic cache cleanup (every 30 seconds)
    local now = os.clock()
    if now - animationCacheLastClean > 30 then
        animationCacheLastClean = now
        for key, track in pairs(animationCache) do
            if not track or not track.Parent then
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
    
    local ok, track = pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        return animator:LoadAnimation(anim)
    end)
    if not ok or not track then return nil end
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.02, 1, 1)
    animationCache[cacheKey] = track
    return track
end
-- aimThenShootGun — Uses animations (Aim, Aiming, Fire) + remote:FireServer("Fire") with silent aim hooks
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
    
    -- Calculate timing based on AUTO_SHOOT_DELAY
    local totalDelay = AUTO_SHOOT_DELAY or 0.5
    local rotationDuration = math.max(totalDelay * 0.7, 0.2)
    
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
            pcall(function() smoothLookAtDynamic(root, getPosFunc, rotationDuration) end)
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
        if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
        return
    end
    
    -- Final checks before firing
    if not currentTargetPart or not currentTargetPart.Parent then
        if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
        return
    end
    if not currentTargetModel or not currentTargetModel.Parent then
        if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
        return
    end
    
    local hum = currentTargetModel:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health and hum.Health < 1 then
        if trackB and trackB.IsPlaying then pcall(function() trackB:Stop(0.1) end) end
        autoShootActive = false
        autoShootCurrentTarget = nil
        autoShootCurrentModel = nil
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
            _G.SafeFireServer(remote, "Fire", modelRef, aimPos, t)
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

-- instantShootGun — Fires remote directly with silent aim (no animations for speed)
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
            _G.SafeFireServer(remote, "Fire", modelRef, aimPos, t)
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
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}
    watchedTools = setmetatable({}, { __mode = "k" })
    isAiming = false
end
-- MAIN LOOP — updated to use selected types rather than bombers only
local mainLoopRunning = false
local function startMainLoop()
    if mainLoopRunning then return end
    mainLoopRunning = true
    task.spawn(function()
        while mainLoopRunning do
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
                local baseIgnoreCache = nil
                local function targetHasClearLOS(customIgnore)
                if not CHECK_WALLS then return true end
                if not targetPart or not targetPart.Parent then return false end
                local originPos = getWallCheckOrigin()
                if not originPos then return true end
                if customIgnore then
                    baseIgnoreCache = customIgnore
                elseif not baseIgnoreCache then
                    baseIgnoreCache = buildBaseIgnore()
                end
                local ignoreList = customIgnore or baseIgnoreCache
                local ok, res = pcall(function()
                    return hasClearShotOnPart(originPos, targetPart, targetModel, ignoreList)
                end)
                return ok and res
                end
                -- smarter appear delay: poll during delay so we can abort quickly
                local appearDelay = (isPlayerTarget and INSTANT_SAVE_PLAYERS_ENABLED and 0.1)
                or (not isPlayerTarget and INSTANT_SHOOT_ENABLED and 0.1)
                or APPEAR_DELAY
                local startT = os.clock()
                local aborted = false
                local targetZombieType = GetZombieTypeFromModel and GetZombieTypeFromModel(targetModel) or nil
                while os.clock() - startT < appearDelay do
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
                    if not targetHasClearLOS() then
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
                    if not targetHasClearLOS(freshIgnore) then
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
                end
                end
            end
            end
            task.wait(CHECK_INTERVAL)
        end
    end)
end
-- Attach watchers for tools that might be on character when script loads (and watch Equip)
local function monitorCharacterTools(char)
    if not char then return end
    -- Clean up existing connections for this character
    cleanupConnections()
    -- Attach hand mortar watcher once per character (not per tool)
    pcall(function() attachHandMortarWatcher() end)
    -- Watch existing tools
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then
            -- Watch guns
            if isGun(c) then
                pcall(watchShotsForTool, c)
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
                pcall(watchShotsForTool, child)
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
    for i, conn in ipairs(activeConnections) do
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
startMainLoop()

-- ===== SILENT AIM HOOKS (ZOMBIE) =====
-- Silent Aim redirects user-initiated shots to the current target instead of auto-shooting
-- This hooks into the game's raycast and mouse systems to redirect bullets

-- Silent Aim target update loop (updates current target for redirection)
local silentAimUpdateConn = nil
local silentAimFrameCounter = 0
local SILENT_AIM_UPDATE_INTERVAL = 5 -- Update every N frames to reduce lag (increased from 3)
local function startSilentAimLoop()
    if silentAimUpdateConn then return end
    silentAimUpdateConn = RunService.Heartbeat:Connect(function()
        -- Throttle updates to every N frames for performance
        silentAimFrameCounter = silentAimFrameCounter + 1
        if silentAimFrameCounter < SILENT_AIM_UPDATE_INTERVAL then return end
        silentAimFrameCounter = 0
        
        local hasZombieSelection = SILENT_AIM_ENABLED and (SilentAimSelectedTypes and #SilentAimSelectedTypes > 0)
        -- Only update if any silent aim feature is enabled
        if not (hasZombieSelection or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED) then
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
        
        local targetPart, targetModel, isPlayerTarget, savedPlayer = nil, nil, false, nil
        
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
        
        -- Update visuals if target ESP is enabled
        if TARGET_ESP_ENABLED and targetPart and targetModel then
            pcall(function() updateActiveTargetVisuals(targetModel, targetPart) end)
        elseif TARGET_ESP_ENABLED then
            pcall(function() clearActiveTargetVisuals() end)
        end
        
        -- Auto Aim: Make character look at target if enabled
        if SILENT_AIM_AUTO_AIM and targetPart and targetPart.Parent then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local aimPos = targetPart.Position
                    local flatAimPos = Vector3.new(aimPos.X, hrp.Position.Y, aimPos.Z)
                    local lookDir = (flatAimPos - hrp.Position)
                    if lookDir.Magnitude > 0.1 then
                        hrp.CFrame = CFrame.new(hrp.Position, flatAimPos)
                    end
                end
            end)
        end
    end)
end
startSilentAimLoop()

-- ===== SILENT AIM HOOKS =====
-- Hook into game's raycast system for silent aim redirection
local silentAimOldNamecall = nil
local silentAimOldIndex = nil

-- Recursion guards to prevent C stack overflow
local inNamecallHook = false
local inIndexHook = false

local function setupSilentAimHooks()
    -- Only set up hooks if they don't exist yet
    if silentAimOldNamecall then return end
    
    -- Check if hookmetamethod exists (executor support)
    if type(hookmetamethod) ~= "function" then
        warn("hookmetamethod not available, Silent Aim will not work on this executor")
        return
    end
    
    local checkcaller = checkcaller or function() return false end
    local Mouse = LocalPlayer:GetMouse()
    
    -- Hook __namecall for Raycast redirection
    pcall(function()
        silentAimOldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            -- Prevent recursion
            if inNamecallHook then
                return silentAimOldNamecall(self, ...)
            end
            
            local method = getnamecallmethod()
            local args = {...}
            
            -- Only intercept Raycast on Workspace
            if method ~= "Raycast" or (self ~= Workspace and self.ClassName ~= "Workspace") then
                return silentAimOldNamecall(self, ...)
            end
            
            -- Skip if caller is this script
            if checkcaller() then
                return silentAimOldNamecall(self, ...)
            end
            
            -- Determine which target to use
            -- Priority: autoShoot > zombie silent aim
            local targetToUse = nil
            
            if autoShootActive and autoShootCurrentTarget then
                inNamecallHook = true
                local hasParent = autoShootCurrentTarget.Parent ~= nil
                inNamecallHook = false
                if hasParent then
                    targetToUse = autoShootCurrentTarget
                end
            elseif (SILENT_AIM_ENABLED or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED) and silentAimCurrentTarget then
                inNamecallHook = true
                local hasParent = silentAimCurrentTarget.Parent ~= nil
                inNamecallHook = false
                if hasParent then
                    targetToUse = silentAimCurrentTarget
                end
            end
            
            if targetToUse then
                inNamecallHook = true
                local origin = args[1]
                local aimPos = targetToUse.Position
                inNamecallHook = false
                
                local dir = (aimPos - origin)
                -- Redirect the ray towards the target with slight range compensation
                args[2] = dir.Unit * (dir.Magnitude + 10)
                
                return silentAimOldNamecall(self, unpack(args))
            end
            return silentAimOldNamecall(self, ...)
        end)
    end)
    
    -- Hook __index for Mouse.Hit and Mouse.Target redirection
    pcall(function()
        silentAimOldIndex = hookmetamethod(game, "__index", function(self, index)
            -- Prevent recursion
            if inIndexHook then
                return silentAimOldIndex(self, index)
            end
            
            -- Only intercept Mouse.Hit and Mouse.Target
            if self ~= Mouse or (index ~= "Hit" and index ~= "Target") then
                return silentAimOldIndex(self, index)
            end
            
            -- Skip if caller is this script
            if checkcaller() then
                return silentAimOldIndex(self, index)
            end
            
            -- Determine which target to use
            -- Priority: autoShoot > zombie silent aim
            local targetToUse = nil
            
            if autoShootActive and autoShootCurrentTarget then
                inIndexHook = true
                local hasParent = autoShootCurrentTarget.Parent ~= nil
                inIndexHook = false
                if hasParent then
                    targetToUse = autoShootCurrentTarget
                end
            elseif (SILENT_AIM_ENABLED or SILENT_AIM_SAVE_PLAYERS_ENABLED or SILENT_AIM_BOMBER_NEAR_ENABLED) and silentAimCurrentTarget then
                inIndexHook = true
                local hasParent = silentAimCurrentTarget.Parent ~= nil
                inIndexHook = false
                if hasParent then
                    targetToUse = silentAimCurrentTarget
                end
            end
            
            if targetToUse then
                inIndexHook = true
                local aimPos = targetToUse.Position
                local aimCFrame = targetToUse.CFrame
                inIndexHook = false
                
                return index == "Hit" and aimCFrame or targetToUse
            end
            return silentAimOldIndex(self, index)
        end)
    end)
end

-- Initialize hooks
setupSilentAimHooks()
end -- End Auto Gun Aim Logic scope

do -- Gun Tab UI Section scope
-- // Gun Tab UI Section (continues Auto Gun Aim Section scope)
-- UI — create GunTab and sections once, then add toggles
local GunTab = AutoTab:Section({ Title = "Auto Functions", Icon = "zap", Opened = false })
local GunModSection, AutoShootSection, SilentAimSection, SavePlayersSection, SafetyTrollingSection, TargetsSection

-- PERFORMANCE FIX: Flag to suppress notifications during UI initialization
local GunTab_InitComplete = false

-- Silent Aim FOV GUI elements (local to UI section)
local silentAimFovGui = nil
local silentAimFovCircle = nil
local silentAimFovUpdateConn = nil

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

-- Forward declarations for whitelist dropdown references (for mutual exclusion)
local DontShootNearWhitelistDropdown = nil
local ShootBomberNearWhitelistDropdown = nil
local ShootBomberNearTeammatesToggle = nil

-- Helper: Get available players excluding those in another whitelist
local function getAvailablePlayersExcluding(excludeList)
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isExcluded = false
            for _, excludedName in ipairs(excludeList or {}) do
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

-- Helper: Refresh dropdown values
-- PERFORMANCE FIX: Added guard to prevent infinite recursion from dropdown callbacks
local isRefreshingWhitelistDropdowns = false
local function refreshWhitelistDropdowns()
    -- Prevent infinite recursion - if we're already refreshing, don't re-enter
    if isRefreshingWhitelistDropdowns then return end
    isRefreshingWhitelistDropdowns = true
    
    pcall(function()
        if DontShootNearWhitelistDropdown and DontShootNearWhitelistDropdown.Refresh then
            local availableForDontShoot = getAvailablePlayersExcluding(ShootBomberNearWhitelist)
            table.insert(availableForDontShoot, 1, "None")
            DontShootNearWhitelistDropdown:Refresh(availableForDontShoot)
        end
    end)
    
    pcall(function()
        if ShootBomberNearWhitelistDropdown and ShootBomberNearWhitelistDropdown.Refresh then
            local availableForShootNear = getAvailablePlayersExcluding(BomberSafetyWhitelist)
            table.insert(availableForShootNear, 1, "None")
            ShootBomberNearWhitelistDropdown:Refresh(availableForShootNear)
        end
    end)
    
    isRefreshingWhitelistDropdowns = false
end

-- Helper: Lock/unlock toggle with notification
local function lockToggleWithNotify(toggle, title, reason)
    pcall(function()
        if WindUI then
            WindUI:Notify({
                Title = title,
                Content = reason,
                Duration = 3,
                Icon = "lock",
            })
        end
    end)
    pcall(function()
        if toggle and toggle.Lock then toggle:Lock() end
    end)
end

local function unlockToggle(toggle)
    pcall(function()
        if toggle and toggle.Unlock then toggle:Unlock() end
    end)
end

-- Silent Aim FOV functions
local function ensureSilentAimFovGui()
    if silentAimFovGui and silentAimFovGui.Parent then
        return silentAimFovGui, silentAimFovCircle
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    silentAimFovGui = Instance.new("ScreenGui")
    silentAimFovGui.ResetOnSpawn = false
    if _G.protectGUI then _G.protectGUI(silentAimFovGui) else silentAimFovGui.Parent = pg end -- Use stealth protection
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = silentAimFovGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Transparency = 0.2
    stroke.Parent = circle
    silentAimFovCircle = circle
    return silentAimFovGui, silentAimFovCircle
end

local function getSilentAimFovScreenCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2.new(0, 0) end
    local viewportSize = cam.ViewportSize
    if SILENT_AIM_MOBILE_FOV or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    return mousePos - Vector2.new(inset.X, inset.Y)
end

local silentAimFovFrameCounter = 0
local SILENT_AIM_FOV_UPDATE_INTERVAL = 2 -- Update every N frames
local function ensureSilentAimFovUpdateLoop()
    if silentAimFovUpdateConn then return end
    silentAimFovUpdateConn = RunService.RenderStepped:Connect(function()
        if not (SILENT_AIM_USE_FOV and SILENT_AIM_SHOW_FOV) then
            if silentAimFovGui then silentAimFovGui.Enabled = false end
            return
        end
        -- Throttle updates for performance
        silentAimFovFrameCounter = silentAimFovFrameCounter + 1
        if silentAimFovFrameCounter < SILENT_AIM_FOV_UPDATE_INTERVAL then return end
        silentAimFovFrameCounter = 0
        
        local gui, circle = ensureSilentAimFovGui()
        gui.Enabled = true
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local viewportSize = cam.ViewportSize
        local clamped = math.clamp(SILENT_AIM_FOV_SIZE, FOV_MIN_DEG, FOV_MAX_DEG)
        local sizePx = (clamped / 40) * 250
        circle.Size = UDim2.new(0, sizePx, 0, sizePx)
        local center = getSilentAimFovScreenCenter()
        local xScale = center.X / viewportSize.X
        local yScale = center.Y / viewportSize.Y
        circle.Position = UDim2.new(xScale, 0, yScale, 0)
    end)
end

local function updateSilentAimFovCircle()
    if not (SILENT_AIM_USE_FOV and SILENT_AIM_SHOW_FOV) then
        if silentAimFovGui then silentAimFovGui.Enabled = false end
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
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerVec).Magnitude
    local clamped = math.clamp(SILENT_AIM_FOV_SIZE, FOV_MIN_DEG, FOV_MAX_DEG)
    local sizePx = (clamped / 40) * 250
    local radius = sizePx / 2
    return dist <= radius
end

-- Auto Save FOV functions
local function ensureAutoSaveFovGui()
    if autoSaveFovGui and autoSaveFovGui.Parent then
        return autoSaveFovGui, autoSaveFovCircle
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    autoSaveFovGui = Instance.new("ScreenGui")
    autoSaveFovGui.ResetOnSpawn = false
    if _G.protectGUI then _G.protectGUI(autoSaveFovGui) else autoSaveFovGui.Parent = pg end -- Use stealth protection
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = autoSaveFovGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Transparency = 0.2
    stroke.Parent = circle
    autoSaveFovCircle = circle
    return autoSaveFovGui, autoSaveFovCircle
end

local function getAutoSaveFovScreenCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2.new(0, 0) end
    local viewportSize = cam.ViewportSize
    if AUTO_SAVE_MOBILE_FOV or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    end
    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    return mousePos - Vector2.new(inset.X, inset.Y)
end

local autoSaveFovFrameCounter = 0
local AUTO_SAVE_FOV_UPDATE_INTERVAL = 2 -- Update every N frames
local function ensureAutoSaveFovUpdateLoop()
    if autoSaveFovUpdateConn then return end
    autoSaveFovUpdateConn = RunService.RenderStepped:Connect(function()
        if not (AUTO_SAVE_USE_FOV and AUTO_SAVE_SHOW_FOV) then
            if autoSaveFovGui then autoSaveFovGui.Enabled = false end
            return
        end
        -- Throttle updates for performance
        autoSaveFovFrameCounter = autoSaveFovFrameCounter + 1
        if autoSaveFovFrameCounter < AUTO_SAVE_FOV_UPDATE_INTERVAL then return end
        autoSaveFovFrameCounter = 0
        
        local gui, circle = ensureAutoSaveFovGui()
        gui.Enabled = true
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local viewportSize = cam.ViewportSize
        local clamped = math.clamp(AUTO_SAVE_FOV_SIZE, FOV_MIN_DEG, FOV_MAX_DEG)
        local sizePx = (clamped / 40) * 250
        circle.Size = UDim2.new(0, sizePx, 0, sizePx)
        local center = getAutoSaveFovScreenCenter()
        local xScale = center.X / viewportSize.X
        local yScale = center.Y / viewportSize.Y
        circle.Position = UDim2.new(xScale, 0, yScale, 0)
    end)
end

local function updateAutoSaveFovCircle()
    if not (AUTO_SAVE_USE_FOV and AUTO_SAVE_SHOW_FOV) then
        if autoSaveFovGui then autoSaveFovGui.Enabled = false end
        return
    end
    ensureAutoSaveFovUpdateLoop()
end

local function isWorldPosInAutoSaveFov(worldPos)
    if not AUTO_SAVE_USE_FOV then return true end
    local cam = Workspace.CurrentCamera
    if not cam then return true end
    local viewportSize = cam.ViewportSize
    if not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then return true end
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return false end
    local centerVec = getAutoSaveFovScreenCenter()
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerVec).Magnitude
    local clamped = math.clamp(AUTO_SAVE_FOV_SIZE, FOV_MIN_DEG, FOV_MAX_DEG)
    local sizePx = (clamped / 40) * 250
    local radius = sizePx / 2
    return dist <= radius
end

do -- Gun Tab UI Section scope (always runs)
    do -- Auto Shoot Section scope
    GunModSection = AutoTab:Section({ Title = "Gun", Icon = "zap", Opened = false })
    AutoShootSection = AutoTab:Section({ Title = "Auto Shoot", Icon = "target", Opened = false })
    
    -- Multi-select dropdown for zombie types to auto-shoot
    local shootDropdown = AutoShootSection:Dropdown({
        Title = "Select Zombie Types To AutoShoot",
        Flag = "Gun",
        Desc = "Select zombie types to target.",
        Values = ShootTypeList,
        Value = {},
        Multi = true,
        Callback = function(selection)
            local newSelection = selection or {}
            SelectedShootTypes = {}
            for _, v in ipairs(newSelection) do table.insert(SelectedShootTypes, tostring(v)) end
            -- Keep EnabledShootTypes consistent: if some types were deselected, disable them
            for _, t in ipairs(ShootTypeList) do
                local found = false
                for _, s in ipairs(SelectedShootTypes) do if s == t then found = true; break end end
                if not found then EnabledShootTypes[t] = false end
            end
            if GunTab_InitComplete then
                pcall(function()
                    WindUI:Notify({
                        Title = "Shooting Selection",
                        Content = (#SelectedShootTypes > 0) and ("Selected: " .. table.concat(SelectedShootTypes, ", ")) or "No selection",
                        Icon = "target",
                        Duration = 1
                    })
                end)
            end
        end
    })
    -- Toggle: enables/disables auto-shoot for selected types
    local AutoShootToggle = AutoShootSection:Toggle({
        Title = "Auto Fire",
        Flag = "Auto_Fire",
        Desc = "Auto shoot selected zombie types.",
        Icon = "play",
        Value = USER_AUTO_SHOOT_TOGGLE,
        Callback = function(state)
            USER_AUTO_SHOOT_TOGGLE = state
            -- If disabled, clear per-type enabled flags
            if not state then
                for t, _ in pairs(EnabledShootTypes) do EnabledShootTypes[t] = false end
            else
                -- enable all selected types for simplicity
                for _, t in ipairs(SelectedShootTypes) do EnabledShootTypes[t] = true end
            end
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.AutoShoot = AutoShootToggle

    -- Keep "Instant Shoot" behavior but generalized: instant for any selected type
    local InstantShootToggle = AutoShootSection:Toggle({
        Title = "Instant Shoot",
        Flag = "Instant_Shoot",
        Desc = "Shoot instantly, no animations.",
        Icon = "zap",
        Value = INSTANT_SHOOT_ENABLED,
        Callback = function(state)
            INSTANT_SHOOT_ENABLED = state
            APPEAR_DELAY = (INSTANT_SHOOT_ENABLED and 0.1) or APPEAR_DELAY_DEFAULT
        end
    })
    _G.LanderToggleElements.InstantShoot = InstantShootToggle
    
    AutoShootSection:Slider({
        Title = "Auto Shoot Delay",
        Flag = "Auto_Shoot_Delay",
        Desc = "Time from aim to fire (seconds).",
        Step = 0.1,
        Value = { Min = 0.5, Max = 5, Default = AUTO_SHOOT_DELAY },
        Callback = function(val)
            AUTO_SHOOT_DELAY = math.clamp(tonumber(val) or 0.5, 0.3, 10)
        end
    })
    AutoShootSection:Slider({
        Title = "Base Prediction",
        Flag = "Base_Prediction",
        Desc = "Movement lead time (0.20 recommended).",
        Step = 0.2,
        Value = { Min = 0, Max = 1, Default = PREDICTION_DISTANCE },
        Callback = function(val)
            PREDICTION_DISTANCE = math.clamp(tonumber(val) or 0, 0, 50)
        end
    })
    AutoShootSection:Slider({
        Title = "Max Target Range",
        Flag = "Max_Target_Range",
        Desc = "Max detection range.",
        Step = 1,
        Value = { Min = 1, Max = 600, Default = MAX_TARGET_RANGE },
        Callback = function(val) MAX_TARGET_RANGE = val end
    })
    -- ===== AUTO SHOOT FOV UI =====
    local UseFovToggle = AutoShootSection:Toggle({
        Title = "Use Fov",
        Flag = "Max_Target_Range_1",
        Desc = "Only target within FOV.",
        Icon = "circle",
        Value = USE_FOV,
        Callback = function(state)
            USE_FOV = state
            updateFovCircle()
        end
    })
    _G.LanderToggleElements.UseFov = UseFovToggle

    AutoShootSection:Toggle({
        Title = "Mobile Fov",
        Flag = "Mobile_Fov",
        Desc = "Lock FOV to screen center.",
        Icon = "smartphone",
        Value = MOBILE_FOV,
        Callback = function(state)
            MOBILE_FOV = state
            updateFovCircle()
        end
    })
    local ShowFovToggle = AutoShootSection:Toggle({
        Title = "Show Fov",
        Flag = "Show_Fov",
        Desc = "Show FOV circle.",
        Icon = "eye",
        Value = SHOW_FOV,
        Callback = function(state)
            SHOW_FOV = state
            updateFovCircle()
        end
    })
    _G.LanderToggleElements.ShowFov = ShowFovToggle

    AutoShootSection:Slider({
        Title = "Fov Size",
        Flag = "Fov_Size",
        Desc = "FOV circle size.",
        Step = 1,
        Value = { Min = FOV_MIN_DEG, Max = FOV_MAX_DEG, Default = FOV_SIZE_DEG },
        Callback = function(val)
            FOV_SIZE_DEG = val
            updateFovCircle()
        end
    })
    local WallCheckToggle = AutoShootSection:Toggle({
        Title = "Wall Check (Raycast)",
        Flag = "Wall_Check_Raycast",
        Desc = "Ignore zombies behind walls.",
        Icon = "shield-off",
        Value = CHECK_WALLS,
        Callback = function(state) CHECK_WALLS = state end
    })
    _G.LanderToggleElements.WallCheck = WallCheckToggle

    local AutoReloadToggle = GunModSection:Toggle({ Title = "Auto Reload", Flag = "Wall_Check_Raycast_1", Desc = "Auto reload.", Icon = "refresh-cw", Value = AUTO_RELOAD_ENABLED, Callback = function(state) AUTO_RELOAD_ENABLED = state end })
    _G.LanderToggleElements.AutoReload = AutoReloadToggle
    end -- End Auto Shoot Section scope
    
    -- ===== SILENT AIM SECTION =====
    do -- Silent Aim Section scope
    SilentAimSection = AutoTab:Section({ Title = "Silent Shoot", Icon = "crosshair", Opened = false })
    
    local SilentAimToggle = SilentAimSection:Toggle({
        Title = "Silent Shoot",
        Flag = "Auto_Reload",
        Desc = "Master toggle for Silent Aim.",
        Icon = "power",
        Value = SILENT_AIM_ENABLED,
        Callback = function(state)
            SILENT_AIM_ENABLED = state
            WindUI:Notify({
                Title = "Silent Shoot",
                Content = state and "Silent Aim Enabled - Your shots will be redirected to targets" or "Silent Aim Disabled",
                Duration = 2,
                Icon = state and "crosshair" or "x"
            })
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.SilentAim = SilentAimToggle

    _G.LanderToggleElements.SilentAimAutoAim = SilentAimAutoAimToggle
    
    -- Silent Aim zombie type dropdown (separate from auto shoot)
    SilentAimSection:Dropdown({
        Title = "Select Zombie Types",
        Flag = "Select_Zombie_Types",
        Desc = "Select zombie types for Silent Aim.",
        Values = SilentAimZombieTypes,
        Value = {},
        Multi = true,
        Callback = function(selection)
            local newSelection = selection or {}
            SilentAimSelectedTypes = {}
            for _, v in ipairs(newSelection) do table.insert(SilentAimSelectedTypes, tostring(v)) end
            for _, t in ipairs(SilentAimZombieTypes) do
                local found = false
                for _, s in ipairs(SilentAimSelectedTypes) do if s == t then found = true; break end end
                if not found then SilentAimEnabledTypes[t] = false else SilentAimEnabledTypes[t] = true end
            end
            if GunTab_InitComplete then
                pcall(function()
                    WindUI:Notify({
                        Title = "Silent Aim Selection",
                        Content = (#SilentAimSelectedTypes > 0) and ("Selected: " .. table.concat(SilentAimSelectedTypes, ", ")) or "No selection",
                        Icon = "crosshair",
                        Duration = 1
                    })
                end)
            end
        end
    })
    
    -- Silent Aim FOV settings
    SilentAimSection:Toggle({
        Title = "Use Fov",
        Flag = "Use_Fov",
        Desc = "Silent Aim targets within FOV only.",
        Icon = "circle",
        Value = SILENT_AIM_USE_FOV,
        Callback = function(state)
            SILENT_AIM_USE_FOV = state
            updateSilentAimFovCircle()
        end
    })
    
    SilentAimSection:Toggle({
        Title = "Mobile Fov",
        Flag = "Mobile_Fov_1",
        Desc = "Lock FOV to screen center.",
        Icon = "smartphone",
        Value = SILENT_AIM_MOBILE_FOV,
        Callback = function(state)
            SILENT_AIM_MOBILE_FOV = state
            updateSilentAimFovCircle()
        end
    })
    
    SilentAimSection:Toggle({
        Title = "Show Fov",
        Flag = "Show_Fov_1",
        Desc = "Show Silent Aim FOV circle (cyan).",
        Icon = "eye",
        Value = SILENT_AIM_SHOW_FOV,
        Callback = function(state)
            SILENT_AIM_SHOW_FOV = state
            updateSilentAimFovCircle()
        end
    })
    
    SilentAimSection:Slider({
        Title = "Fov Size",
        Flag = "Fov_Size_1",
        Desc = "Silent Aim FOV circle size.",
        Step = 1,
        Value = { Min = FOV_MIN_DEG, Max = FOV_MAX_DEG, Default = SILENT_AIM_FOV_SIZE },
        Callback = function(val)
            SILENT_AIM_FOV_SIZE = val
            updateSilentAimFovCircle()
        end
    })
    
    SilentAimSection:Toggle({
        Title = "Silent Aim Save Players",
        Flag = "Silent_Aim_Save_Players",
        Desc = "Redirect shots to zombies grabbing players.",
        Icon = "shield",
        Value = SILENT_AIM_SAVE_PLAYERS_ENABLED,
        Callback = function(state)
            SILENT_AIM_SAVE_PLAYERS_ENABLED = state
            WindUI:Notify({
                Title = "Silent Aim Save Players",
                Content = state and "Shots will redirect to zombies grabbing players" or "Disabled",
                Duration = 2,
                Icon = state and "shield" or "x"
            })
        end
    })
    
    -- Silent Aim Save Players Whitelist
    local function getSilentAimSavePlayersNames()
        local names = {"All"}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end
    
    SilentAimSection:Dropdown({
        Title = "Save Players Whitelist",
        Flag = "Save_Whitelist",
        Desc = "Only save players in the list.",
        Values = getSilentAimSavePlayersNames(),
        Value = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            for _, name in ipairs(selection or {}) do
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
                    WindUI:Notify({
                        Title = "Silent Aim Save Whitelist",
                        Content = (#SilentAimSavePlayersWhitelist > 0) and ("Will only save: " .. table.concat(SilentAimSavePlayersWhitelist, ", ")) or "Will save all players",
                        Icon = "users",
                        Duration = 2
                    })
                end)
            end
        end
    })
    
    SilentAimSection:Toggle({
        Title = "Silent Aim Bomber Near Teammates",
        Flag = "Silent_Aim_Bomber_Near_Teammates",
        Desc = "Shoot Bombers only when near teammates.",
        Icon = "users",
        Value = SILENT_AIM_BOMBER_NEAR_ENABLED,
        Callback = function(state)
            SILENT_AIM_BOMBER_NEAR_ENABLED = state
            WindUI:Notify({
                Title = "Silent Aim Bomber",
                Content = state and "Will only target bombers near teammates" or "Normal bomber targeting",
                Duration = 2,
                Icon = state and "crosshair" or "x"
            })
        end
    })
    
    -- Silent Aim Bomber Near Whitelist
    local function getSilentAimBomberNearNames()
        local names = {"All"}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end
    
    SilentAimSection:Dropdown({
        Title = "Bomber Near Whitelist",
        Flag = "Bomber_Near_Whitelist",
        Desc = "Teammates used as Bomber shoot condition.",
        Values = getSilentAimBomberNearNames(),
        Value = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            for _, name in ipairs(selection or {}) do
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
                    WindUI:Notify({
                        Title = "Silent Aim Bomber Near",
                        Content = (#SilentAimBomberNearWhitelist > 0) and ("Will shoot bombers near: " .. table.concat(SilentAimBomberNearWhitelist, ", ")) or "Will shoot near any teammate",
                        Icon = "crosshair",
                        Duration = 2
                    })
                end)
            end
        end
    })
    end -- End Silent Aim Section scope

    -- ===== SAVE PLAYERS SECTION =====
    do -- Save Players Section scope
    SavePlayersSection = AutoTab:Section({ Title = "Save Player", Icon = "shield", Opened = false })
    local AutoSavePlayersToggle = SavePlayersSection:Toggle({
        Title = "Save Player",
        Flag = "Save_Player",
        Desc = "Shoot zombies grabbing players.",
        Icon = "shield",
        Value = AUTO_SAVE_PLAYERS_ENABLED,
        Callback = function(state) AUTO_SAVE_PLAYERS_ENABLED = state end
    })
    _G.LanderToggleElements.AutoSavePlayers = AutoSavePlayersToggle

    SavePlayersSection:Toggle({
        Title = "Instant Save Players",
        Flag = "Instant_Save_Players",
        Desc = "Shoot instantly, no animations.",
        Icon = "zap",
        Value = INSTANT_SAVE_PLAYERS_ENABLED,
        Callback = function(state) INSTANT_SAVE_PLAYERS_ENABLED = state end
    })
    SavePlayersSection:Slider({
        Title = "Save Player Delay",
        Flag = "Instant_Save_Players_1",
        Desc = "Delay before shooting (seconds).",
        Step = 0.1,
        Value = { Min = 0, Max = 5, Default = SAVE_PLAYER_DELAY },
        Callback = function(val) SAVE_PLAYER_DELAY = val end
    })
    SavePlayersSection:Slider({
        Title = "Max Save Players Range",
        Flag = "Save_Player_Delay",
        Desc = "Max save range.",
        Step = 1,
        Value = { Min = 50, Max = 600, Default = MAX_SAVE_PLAYERS_RANGE },
        Callback = function(val) MAX_SAVE_PLAYERS_RANGE = val end
    })
    
    -- Auto Save Players FOV settings
    SavePlayersSection:Toggle({
        Title = "Use Fov",
        Flag = "Use_Fov_1",
        Desc = "Save players within FOV only.",
        Icon = "circle",
        Value = AUTO_SAVE_USE_FOV,
        Callback = function(state)
            AUTO_SAVE_USE_FOV = state
            updateAutoSaveFovCircle()
        end
    })
    
    SavePlayersSection:Toggle({
        Title = "Mobile Fov",
        Flag = "Mobile_Fov_2",
        Desc = "Lock FOV to screen center.",
        Icon = "smartphone",
        Value = AUTO_SAVE_MOBILE_FOV,
        Callback = function(state)
            AUTO_SAVE_MOBILE_FOV = state
            updateAutoSaveFovCircle()
        end
    })
    
    SavePlayersSection:Toggle({
        Title = "Show Fov",
        Flag = "Show_Fov_2",
        Desc = "Show Auto Save FOV circle (green).",
        Icon = "eye",
        Value = AUTO_SAVE_SHOW_FOV,
        Callback = function(state)
            AUTO_SAVE_SHOW_FOV = state
            updateAutoSaveFovCircle()
        end
    })
    
    SavePlayersSection:Slider({
        Title = "Fov Size",
        Flag = "Fov_Size_2",
        Desc = "Auto Save FOV circle size.",
        Step = 1,
        Value = { Min = FOV_MIN_DEG, Max = FOV_MAX_DEG, Default = AUTO_SAVE_FOV_SIZE },
        Callback = function(val)
            AUTO_SAVE_FOV_SIZE = val
            updateAutoSaveFovCircle()
        end
    })
    
    -- Auto Save Whitelist Dropdown
    local function getAutoSavePlayerNames()
        local names = {"All"} -- Add All option first (default = save all)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end
    SavePlayersSection:Dropdown({
        Title = "Auto Save Whitelist",
        Flag = "Auto_Save_Whitelist",
        Desc = "Only save players in this list.",
        Values = getAutoSavePlayerNames(),
        Value = {"All"},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasAll = false
            for _, name in ipairs(selection or {}) do
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
                    WindUI:Notify({
                        Title = "Auto Save Whitelist",
                        Content = (#AutoSaveWhitelist > 0) and ("Will only save: " .. table.concat(AutoSaveWhitelist, ", ")) or "Will save all players",
                        Icon = "users",
                        Duration = 2
                    })
                end)
            end
        end
    })
    end -- End Save Players Section scope
    
    -- ===== SAFETY & TROLLING SECTION =====
    do -- Scoped block to reduce local register count
    SafetyTrollingSection = AutoTab:Section({ Title = "Help Teamate & Trolling", Icon = "shield-alert", Opened = false })
    
    -- Don't Shoot Bomber Near Teammates toggle
    local DontShootBomberNearTeammatesToggle = SafetyTrollingSection:Toggle({
        Title = "Don't Shoot Bomber Near Teammates",
        Flag = "Help_Teamate_Trolling",
        Desc = "Don't shoot Bombers if teammates are in radius.",
        Icon = "shield",
        Value = BOMBER_SAFE_TEAMMATES,
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
            WindUI:Notify({
                Title = "Bomber Safety",
                Content = state and "Won't shoot bombers near teammates" or "Disabled",
                Duration = 2,
                Icon = state and "shield" or "x"
            })
        end
    })
    
    -- Don't Shoot Near Teammates Whitelist (mutual exclusion with Shoot Near)
    DontShootNearWhitelistDropdown = SafetyTrollingSection:Dropdown({
        Title = "Don't Shoot Near Teammates Whitelist",
        Flag = "Don_t_Shoot_Near_Teammates_Whitelist",
        Desc = "Teammates to protect from Bomber shots.",
        Values = (function()
            local names = {"None"}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    table.insert(names, player.Name)
                end
            end
            return names
        end)(),
        Value = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            for _, name in ipairs(selection or {}) do
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
                    WindUI:Notify({
                        Title = "Don't Shoot Near Whitelist",
                        Content = (#BomberSafetyWhitelist > 0) and ("Protecting: " .. table.concat(BomberSafetyWhitelist, ", ")) or "No players whitelisted",
                        Icon = "shield",
                        Duration = 2
                    })
                end)
            end
        end
    })
    
    -- Shoot Bomber Near Teammates toggle
    ShootBomberNearTeammatesToggle = SafetyTrollingSection:Toggle({
        Title = "Shoot Bomber Near Teammates",
        Flag = "Shoot_Bomber_Near_Teammates",
        Desc = "Only shoot Bombers when teammates are in radius (troll).",
        Icon = "crosshair",
        Value = SHOOT_BOMBER_NEAR_TEAMMATES,
        Callback = function(state)
            SHOOT_BOMBER_NEAR_TEAMMATES = state
            WindUI:Notify({
                Title = "Bomber Targeting",
                Content = state and "Will ONLY shoot bombers near teammates" or "Normal bomber targeting",
                Duration = 2,
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
    ShootBomberNearWhitelistDropdown = SafetyTrollingSection:Dropdown({
        Title = "Shoot Bomber Near Teammates Whitelist",
        Flag = "Shoot_Bomber_Near_Teammates_Whitelist",
        Desc = "Targets for the troll feature.",
        Values = (function()
            local names = {"None"}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    table.insert(names, player.Name)
                end
            end
            return names
        end)(),
        Value = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            for _, name in ipairs(selection or {}) do
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
                    WindUI:Notify({
                        Title = "Shoot Near Whitelist",
                        Content = (#ShootBomberNearWhitelist > 0) and ("Will shoot bombers near: " .. table.concat(ShootBomberNearWhitelist, ", ")) or "Will shoot near any teammate",
                        Icon = "crosshair",
                        Duration = 2
                    })
                end)
            end
        end
    })
    
    -- Don't Shoot Bomber Near Me toggle
    SafetyTrollingSection:Toggle({
        Title = "Don't Shoot Bomber Near Me",
        Flag = "Don_t_Shoot_Bomber_Near_Me",
        Desc = "Don't shoot Bombers near yourself.",
        Icon = "user",
        Value = BOMBER_SAFE_SELF,
        Callback = function(state)
            BOMBER_SAFE_SELF = state
            WindUI:Notify({
                Title = "Bomber Safety",
                Content = state and "Won't shoot bombers near you" or "Disabled",
                Duration = 2,
                Icon = state and "shield" or "x"
            })
        end
    })
    
    -- Bomber Safety Radius slider
    SafetyTrollingSection:Slider({
        Title = "Bomber Safety Radius",
        Flag = "Bomber_Radius",
        Desc = "Bomber safety radius (studs).",
        Step = 1,
        Value = { Min = 5, Max = 30, Default = BOMBER_SAFE_RADIUS },
        Callback = function(val)
            BOMBER_SAFE_RADIUS = val
            -- Update any existing bomber visualizations to reflect new radius
            for model, visual in pairs(BomberRadiusVisuals) do
                if visual and visual.Parent then
                    visual.Size = Vector3.new(0.2, BOMBER_SAFE_RADIUS * 2, BOMBER_SAFE_RADIUS * 2)
                end
            end
        end
    })
    end -- End Safety & Trolling scoped block
    
    -- ===== TARGET SETTINGS SECTION =====
    do -- Scoped block to reduce local register count
    TargetsSection = AutoTab:Section({ Title = "Target Settings", Icon = "eye", Opened = false })
    
    TargetsSection:Toggle({
        Title = "Visualize Bomber Explosion Radius",
        Flag = "Target_Settings",
        Desc = "Show explosion radius circle around Bombers.",
        Icon = "circle",
        Value = BOMBER_VISUALIZE_RADIUS,
        Callback = function(state)
            BOMBER_VISUALIZE_RADIUS = state
            if not state then
                -- Clear all visuals when disabled
                for model, visual in pairs(BomberRadiusVisuals) do
                    pcall(function() visual:Destroy() end)
                end
                BomberRadiusVisuals = {}
            end
            WindUI:Notify({
                Title = "Bomber Visualization",
                Content = state and "Showing explosion radius" or "Hidden",
                Duration = 2,
                Icon = state and "eye" or "eye-off"
            })
        end
    })
    
    TargetsSection:Toggle({
        Title = "Target ESP",
        Flag = "Bomber_Visualization",
        Desc = "Highlight current target zombie.",
        Icon = "eye",
        Value = TARGET_ESP_ENABLED,
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
    
    TargetsSection:Toggle({
        Title = "Show Aim Position",
        Flag = "Show_Aim_Position",
        Desc = "Show red dot at aim position.",
        Icon = "target",
        Value = AIM_DOT_ENABLED,
        Callback = function(state)
            AIM_DOT_ENABLED = state
            if state then
                pcall(function() createAimDot() end)
                WindUI:Notify({
                    Title = "Aim Dot",
                    Content = "Aim position dot enabled",
                    Duration = 2,
                    Icon = "target"
                })
            else
                pcall(function() clearAimDot() end)
                WindUI:Notify({
                    Title = "Aim Dot", 
                    Content = "Aim position dot disabled",
                    Duration = 2,
                    Icon = "x"
                })
            end
        end
    })
    end -- End Target Settings scoped block
end

do -- Hand Mortar Feature scope (reduces local register count)
--- hand mortar feature (updated: supports two anims, 1s delay, first-person overlay)
-- Hand Mortar Timing Feature
local HAND_MORTAR_TIMING_ENABLED = false
local HAND_MORTAR_DURATION = 5 -- seconds, displayed with milliseconds

local HAND_MORTAR_ANIM_IDS = {
    ["rbxassetid://117522716162453"] = true,
    ["rbxassetid://83761082384320"] = true,
}
-- State for GUI and running timer
-- handMortarGui will be a table: { billboard = BillboardGui, screen = ScreenGui }
local handMortarGui = nil
local handMortarUpdateConn = nil
local handMortarCameraConn = nil
local handMortarEndTick = nil
local handMortarRunning = false
local handMortarAnimConn = nil -- AnimationPlayed connection
-- Ensure PlayerGui exists
local function getPlayerGui()
    return LocalPlayer:WaitForChild("PlayerGui")
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
    bg.StudsOffset = Vector3.new(2.2, 0, 0)
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
    plate.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    plate.BorderSizePixel = 0
    plate.Parent = frame
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(0, 10, 0, 36)
    barBg.Position = UDim2.new(0, 6, 0, 5)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = plate
    barBg.AnchorPoint = Vector2.new(0, 0)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    fill.AnchorPoint = Vector2.new(0, 1)
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
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.Parent = plate
    -- SCREEN (for first-person) — overlay in PlayerGui
    local screen = Instance.new("ScreenGui")
    screen.ResetOnSpawn = false
    if _G.protectGUI then _G.protectGUI(screen) else screen.Parent = playerGui end -- Use stealth protection
    local sFrame = Instance.new("Frame")
    sFrame.Name = "Plate"
    sFrame.Size = UDim2.new(0, 120, 0, 60)
    -- Position: right of screen center (adjust as needed)
    sFrame.Position = UDim2.new(0.55, 0, 0.45, 0)
    sFrame.AnchorPoint = Vector2.new(0, 0)
    sFrame.BackgroundTransparency = 0.25
    sFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    sFrame.BorderSizePixel = 0
    sFrame.Parent = screen
    local sBarBg = Instance.new("Frame")
    sBarBg.Name = "BarBg"
    sBarBg.Size = UDim2.new(0, 10, 0, 36)
    sBarBg.Position = UDim2.new(0, 6, 0, 12)
    sBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    sBarBg.BorderSizePixel = 0
    sBarBg.Parent = sFrame
    local sFill = Instance.new("Frame")
    sFill.Name = "Fill"
    sFill.Size = UDim2.new(1, 0, 1, 0)
    sFill.Position = UDim2.new(0, 0, 0, 0)
    sFill.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
    sFill.BorderSizePixel = 0
    sFill.Parent = sBarBg
    sFill.AnchorPoint = Vector2.new(0, 1)
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
    sTimer.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    sTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
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
    handMortarEndTick = os.clock() + duration
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
        local remaining = math.max(0, handMortarEndTick - os.clock())
        local ratio = remaining / duration
        ratio = math.clamp(ratio, 0, 1)
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
                        local ms = math.floor(remaining * 1000 + 0.5)
                        local sec = math.floor(ms / 1000)
                        local remMs = ms - sec * 1000
                        timerLabel.Text = string.format("%d.%03ds", sec, remMs)
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
                        local ms = math.floor(remaining * 1000 + 0.5)
                        local sec = math.floor(ms / 1000)
                        local remMs = ms - sec * 1000
                        sTimer.Text = string.format("%d.%03ds", sec, remMs)
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
-- NEW DETECTION: via animation played on the local Humanoid (supports both anims)
---------------------------------------------------------------------
local function attachHandMortarWatcher()
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
            -- Debug Trajectory: show raycast impact immediately when fuse animation plays
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
-- re-attach on character spawn + cleanup previous gui
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.1)
    if handMortarAnimConn then
        pcall(function() handMortarAnimConn:Disconnect() end)
        handMortarAnimConn = nil
    end
    attachHandMortarWatcher()
    destroyHandMortarGui()
end)
-- initial attach if character already loaded
pcall(function()
    attachHandMortarWatcher()
end)
-- UI: Misc section and toggle
do
    local MiscGunSection = AutoTab:Section({ Title = "Misc Gun", Icon = "settings", Opened = false })
    -- UI Toggle
    MiscGunSection:Toggle({
        Title = "Hand Mortar Timing",
        Flag = "Gun_1",
        Desc = "Show Mortar timer before explosion.",
        Icon = "clock",
        Value = HAND_MORTAR_TIMING_ENABLED,
        Callback = function(state)
            HAND_MORTAR_TIMING_ENABLED = state
            if not state then
                -- cleanup UI if disabled
                destroyHandMortarGui()
        end
        end
    })
end -- End MiscGun do-block
end -- End Hand Mortar Feature scope
-- End hand mortar feature

-- PERFORMANCE FIX: Mark Gun Tab initialization as complete to enable notifications
GunTab_InitComplete = true

end -- End Gun Tab UI Section scope

task.wait(0.1) -- Delay to prevent lag
do -- // ESP Tab
    local EspTab = ESPTab -- alias to main ESPTab

    -- PERFORMANCE FIX: Flag to suppress notifications during UI initialization
    local ESPTab_InitComplete = false

    local ESPSection = EspTab:Section({
        Title = "ESP & Zombie Alerts",
        Icon = "eye",
        Opened = false
    })

    local RunService = RunService or game:GetService("RunService")
    local CameraFolder = workspace:FindFirstChild("Camera")
    -- Use weak table so dead zombie references are auto-collected by GC
    local IdentifiedIgniters = setmetatable({}, { __mode = "k" })
    ESPConfigs = ESPConfigs or {
        Bomber = {
            color = Color3.fromRGB(255, 180, 60),
            label = "Barrel",
            match = function(model)
                if not model or not model:IsA("Model") then return false end
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Bomber" end
                return model:FindFirstChild("Barrel", true) ~= nil
            end,
        },
        Cuirassier = {
            color = Color3.fromRGB(0, 200, 255),
            label = "Cuirassier",
            match = function(model)
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Cuirassier" end
                return model:FindFirstChild("Sword", true) ~= nil
            end,
        },
        Runner = {
            color = Color3.fromRGB(255, 0, 0),
            label = "Runner",
            match = function(model)
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Runner" end
                return model:FindFirstChild("Eye") and not model:FindFirstChild("Axe") and model:FindFirstChild("Head")
            end,
        },
        Zapper = {
            color = Color3.fromRGB(0, 255, 0),
            label = "Zapper",
            match = function(model)
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Zapper" end
                return model:FindFirstChild("Axe") and model:FindFirstChild("Head")
            end,
        },
        Igniter = {
            color = Color3.fromRGB(255, 255, 0),
            label = "Igniter",
            match = function(model)
                if not model or not model:IsA("Model") then return false end
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Igniter" end
                if model:FindFirstChild("Whale Oil Lantern") then
                    IdentifiedIgniters[model] = true
                    return true
                end
                -- If lantern is gone, remove from identified igniters so it can become a shambler
                if IdentifiedIgniters[model] and not model:FindFirstChild("Whale Oil Lantern") then
                    IdentifiedIgniters[model] = nil
                    return false
                end
                return false
            end,
        },
        -- NEW: Shambler (normal)
        Shambler = {
            color = Color3.fromRGB(180, 180, 255),
            label = "Shambler",
            match = function(model)
                if not model or not model:IsA("Model") then return false end
                local zType = GetZombieTypeFromModel and GetZombieTypeFromModel(model)
                if zType then return zType == "Shambler" end
                -- must be the regular zombie model
                if model.Name ~= "m_Zombie" then return false end
                -- if it has any special markers, it's NOT a Shambler
                if model:FindFirstChild("Barrel", true) then return false end
                if model:FindFirstChild("Sword", true) then return false end
                if model:FindFirstChild("Eye", true) then return false end
                if model:FindFirstChild("Axe", true) then return false end
                if model:FindFirstChild("Whale Oil Lantern", true) then return false end
                -- passed all checks -> normal shambler
                return true
            end,
        },
    }

    local ESPData = {
        Bomber = setmetatable({}, { __mode = "k" }),
        Cuirassier = setmetatable({}, { __mode = "k" }),
        Runner = setmetatable({}, { __mode = "k" }),
        Zapper = setmetatable({}, { __mode = "k" }),
        Igniter = setmetatable({}, { __mode = "k" }),
        Shambler = setmetatable({}, { __mode = "k" }), -- added
    }

    -- Track zombies pending removal (grace period to prevent flicker from temporary parent loss)
    -- Use weak keys so dead zombie references are garbage collected
    local ESPPendingRemoval = setmetatable({}, { __mode = "k" }) -- [zombie] = os.clock() when marked for removal
    local ESP_REMOVAL_GRACE_PERIOD = 0.5 -- seconds to wait before actually removing

    local EnabledESPs = {
        Bomber = false,
        Cuirassier = false,
        Runner = false,
        Zapper = false,
        Igniter = false,
        Shambler = false, -- added
    }

    -- Hidden per-type visual mode (kept defaults from before; not exposed in UI)
    local ESPModes = {
        Bomber = "Both",
        Cuirassier = "Both",
        Runner = "Both",
        Zapper = "Both",
        Igniter = "Both",
        Shambler = "Both", -- added
    }

    -- Default: show billboards disabled
    local ShowBillboards = false
    local ChamsTransparency = 0.6
    local PerformanceMode = false
    local ChamsMaxDistance = 2000
    
    -- PERFORMANCE: Distance culling - don't create ESP for zombies too far away
    local ESP_CREATION_MAX_DISTANCE = 500 -- Only create ESP for zombies within this distance
    local ESP_VISIBLE_MAX_DISTANCE = 300 -- Distance at which ESP becomes visible
    local ESP_SCAN_BATCH_SIZE = 20 -- Max zombies to process per scan cycle

    local activeCount = 0
    local scanLoop
    local renderConn
    
    -- PERFORMANCE: Cache camera position
    local cachedCameraPos = Vector3.new(0, 0, 0)
    local lastCameraCacheTime = 0

    local function GetAdorneePart(model)
        if not model or not model:IsA("Model") then return nil end
        -- PERFORMANCE: Check common parts first without using FindFirstChild with recursive=true
        local head = model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
        -- PERFORMANCE: Use GetChildren instead of GetDescendants (much faster)
        local children = model:GetChildren()
        for _, p in ipairs(children) do
            if p:IsA("BasePart") and p.Name ~= "Whale Oil Lantern" then
                return p
            end
        end
        -- Fallback: check first-level folders only
        for _, child in ipairs(children) do
            if child:IsA("Folder") or child:IsA("Model") then
                for _, p in ipairs(child:GetChildren()) do
                    if p:IsA("BasePart") and p.Name ~= "Whale Oil Lantern" then
                        return p
                    end
                end
            end
        end
        return nil
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
    local offset = Vector3.new(0, 3, 0)

    -- Decide visuals independently:
    local wantHighlight = (mode == "Both" or mode == "Highlight Only") and (not PerformanceMode)
    local wantBillboard = (mode == "Both" or mode == "Billboard Only")
    -- In performance mode we always want a dot (unless the user explicitly picked "Billboard Only" and you
    -- want to change that behavior later). The user's request was: make it a dot with billboard in perf mode,
    -- except if billboard turned off — so dot is always created in PerformanceMode.
    local wantDot = (mode == "Dot Only") or PerformanceMode

    -- DOT (small billboard used as dot)
    if wantDot then
        local dotBb = Instance.new("BillboardGui")
        -- Use stealth name for anti-detection
        dotBb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("Dot_" .. math.random(10000, 99999))
        dotBb.Adornee = headPart
        dotBb.AlwaysOnTop = true
        dotBb.Size = UDim2.new(0, 8, 0, 8)
        dotBb.StudsOffset = Vector3.new(0, 0, 0)
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

    -- HIGHLIGHT (only when not in performance mode)
    if wantHighlight then
        local hl = Instance.new("Highlight")
        -- Use stealth name for anti-detection
        hl.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("HL_" .. math.random(10000, 99999))
        hl.Adornee = zombie
        hl.FillColor = config.color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = ChamsTransparency
        hl.OutlineTransparency = 0
        hl.Parent = zombie
        data.highlight = hl
    end

    -- BILLBOARD (create regardless of whether a dot exists; Enabled will be controlled in UpdateAllBillboards)
    if wantBillboard then
        local bb = Instance.new("BillboardGui")
        -- Use stealth name for anti-detection
        bb.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("BB_" .. math.random(10000, 99999))
        bb.Adornee = headPart
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Size = UDim2.new(0, 100, 0, 40)
        bb.StudsOffset = offset
        bb.MaxDistance = 1000
        bb.Enabled = ShowBillboards -- initial enabled state; UpdateAllBillboards will adjust per-distance
        bb.Parent = zombie
        data.billboard = bb

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 1
        frame.BorderColor3 = config.color
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        frame.Parent = bb
        data.frame = frame

        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = Vector2.new(0.5, 0)
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
        distLbl.AnchorPoint = Vector2.new(0.5, 1)
        distLbl.Position = UDim2.new(0.5, 0, 0.9, 0)
        distLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "0 studs"
        distLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        distLbl.TextScaled = true
        distLbl.Font = Enum.Font.Gotham
        distLbl.Parent = frame
        data.distLabel = distLbl
    end
    
    -- PROTECT ESP VISUALS from anti-cheat detection
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
        -- Destroy instances
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        if data.dot then pcall(function() data.dot:Destroy() end) end
        -- Clear all references in the data table to help GC
        data.highlight = nil
        data.billboard = nil
        data.dot = nil
        data.frame = nil
        data.label = nil
        data.distLabel = nil
        -- Remove from ESPData
        ESPData[espType][zombie] = nil
        -- Also clear pending removal tracker and IdentifiedIgniters
        if zombie then
            ESPPendingRemoval[zombie] = nil
            IdentifiedIgniters[zombie] = nil
        end
    end

    -- Collect zombies from new Agent/Slim folders, with Camera fallback for legacy setups
    -- PERFORMANCE FIX: Pre-allocated buffers to avoid table churn every scan cycle
    local _zombiesBuf = {}
    local _zombiesBufLen = 0
    local _zombieSetBuf = {}

    local function CollectZombies()
        -- PERFORMANCE: Reuse buffer instead of creating new table
        _zombiesBufLen = 0
        local zFolder = workspace:FindFirstChild("Zombies")
        if zFolder then
            local agent = zFolder:FindFirstChild("Agent")
            if agent then
                for _, z in ipairs(agent:GetChildren()) do
                    if z:IsA("Model") then
                        local hasCharacter = z:FindFirstChild("Character")
                        local nameStartsWithUnderscore = z.Name:sub(1, 1) == "_"
                        if not hasCharacter and not nameStartsWithUnderscore then
                            _zombiesBufLen = _zombiesBufLen + 1
                            _zombiesBuf[_zombiesBufLen] = z
                        end
                    end
                end
            end
            local slim = zFolder:FindFirstChild("Slim")
            if slim then
                for _, z in ipairs(slim:GetChildren()) do
                    if z:IsA("Model") then
                        local hasCharacter = z:FindFirstChild("Character")
                        local nameStartsWithUnderscore = z.Name:sub(1, 1) == "_"
                        if not hasCharacter and not nameStartsWithUnderscore then
                            _zombiesBufLen = _zombiesBufLen + 1
                            _zombiesBuf[_zombiesBufLen] = z
                        end
                    end
                end
            end
        end
        if _zombiesBufLen == 0 and CameraFolder then
            for _, z in ipairs(CameraFolder:GetChildren()) do
                if z:IsA("Model") then
                    _zombiesBufLen = _zombiesBufLen + 1
                    _zombiesBuf[_zombiesBufLen] = z
                end
            end
        end
        -- Trim stale tail entries
        for i = _zombiesBufLen + 1, #_zombiesBuf do _zombiesBuf[i] = nil end
        return _zombiesBuf, _zombiesBufLen
    end

    local function ScanAll()
        local zombies, zombieCount = CollectZombies()
        
        -- PERFORMANCE FIX: Reuse set buffer instead of creating new table
        for k in pairs(_zombieSetBuf) do _zombieSetBuf[k] = nil end
        for i = 1, zombieCount do
            _zombieSetBuf[zombies[i]] = true
        end
        
        -- PERFORMANCE: Get camera position for distance culling
        local cam = workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or Vector3.new(0, 0, 0)
        
        -- PERFORMANCE FIX: Global batch limit across ALL types (was per-type = 6x more)
        local globalCreated = 0
        
        for espType, enabled in pairs(EnabledESPs) do
            if enabled then
                -- Remove visuals for zombies that no longer exist
                for z in pairs(ESPData[espType]) do
                    if not _zombieSetBuf[z] then
                        RemoveVisual(espType, z)
                    end
                end
                
                -- Add visuals for new zombies that match this type
                for i = 1, zombieCount do
                    if globalCreated >= ESP_SCAN_BATCH_SIZE then break end -- PERFORMANCE: Global batch limit
                    local z = zombies[i]
                    
                    if z:IsA("Model") and not ESPData[espType][z] then
                        -- PERFORMANCE: Distance culling - skip zombies too far away
                        local zombiePart = z.PrimaryPart or z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Head")
                        if zombiePart then
                            local dist = (camPos - zombiePart.Position).Magnitude
                            if dist > ESP_CREATION_MAX_DISTANCE then continue end -- Skip distant zombies
                        end
                        
                        -- Check if zombie already has ESP from another type
                        local hasOtherESP = false
                        for otherType, otherData in pairs(ESPData) do
                            if otherType ~= espType and otherData[z] then
                                hasOtherESP = true
                                break
                            end
                        end
                        
                        if not hasOtherESP and ESPConfigs[espType].match(z) then
                            CreateVisual(espType, z)
                            globalCreated = globalCreated + 1
                        end
                    end
                end
            else
                -- ESP type disabled - clear all its visuals
                if next(ESPData[espType]) then
                    for z in pairs(ESPData[espType]) do
                        RemoveVisual(espType, z)
                    end
                    -- Reset to weak table to maintain GC behavior
                    ESPData[espType] = setmetatable({}, { __mode = "k" })
                end
            end
        end
    end

    local function UpdateAllTransparencies()
        for espType, dataTable in pairs(ESPData) do
            for _, data in pairs(dataTable) do
                if data.highlight then data.highlight.FillTransparency = ChamsTransparency end
            end
        end
    end

local function UpdateAllBillboards()
    local Camera = workspace.CurrentCamera
    if not Camera then return end

    local now = os.clock()
    local cameraPos = Camera.CFrame.Position

    for espType, dataTable in pairs(ESPData) do
        -- Skip if this ESP type is disabled
        if not EnabledESPs[espType] then continue end
        
        for zombie, data in pairs(dataTable) do
            -- Quick nil check without pcall for performance
            if not zombie or not zombie.Parent then
                -- zombie lost parent - use grace period to prevent flicker
                if not ESPPendingRemoval[zombie] then
                    ESPPendingRemoval[zombie] = now
                elseif (now - ESPPendingRemoval[zombie]) >= ESP_REMOVAL_GRACE_PERIOD then
                    -- grace period expired, actually remove
                    RemoveVisual(espType, zombie)
                    ESPPendingRemoval[zombie] = nil
                end
                -- hide visuals during grace period
                if data.highlight then data.highlight.Enabled = false end
                if data.dot then data.dot.Enabled = false end
                if data.billboard then data.billboard.Enabled = false end
                continue
            end
            
            -- zombie has parent again, clear pending removal if any
            if ESPPendingRemoval[zombie] then
                ESPPendingRemoval[zombie] = nil
            end
            
            -- Get adornee for distance calculation
            local adornee = (data.billboard and data.billboard.Adornee) or (data.dot and data.dot.Adornee)
            
            if not adornee or not adornee.Parent then
                local newPart = GetAdorneePart(zombie)
                if newPart then
                    if data.billboard then data.billboard.Adornee = newPart end
                    if data.dot then data.dot.Adornee = newPart end
                    adornee = newPart
                else
                    RemoveVisual(espType, zombie)
                    continue
                end
            end
            
            -- Calculate distance once
            local pos = adornee.Position
            local dist = (cameraPos - pos).Magnitude
            local maxDist = data.maxDistance or ChamsMaxDistance

            -- PERFORMANCE FIX: Early skip for zombies beyond visible range
            if dist > maxDist then
                if data.highlight then data.highlight.Enabled = false end
                if data.dot then data.dot.Enabled = false end
                if data.billboard then data.billboard.Enabled = false end
                continue
            end

            -- Precompute flags once
            local highlightAllowed = not PerformanceMode
            local dotAllowed = PerformanceMode

            -- HIGHLIGHT - simple enable/disable
            if data.highlight then
                data.highlight.Enabled = highlightAllowed and (dist <= maxDist)
            end

            -- DOT - simple enable/disable  
            if data.dot then
                data.dot.Enabled = dotAllowed and (dist <= maxDist)
            end

            -- BILLBOARD - only update if enabled
            if data.billboard then
                if not ShowBillboards then
                    data.billboard.Enabled = false
                else
                    local maxBillboardDist = PerformanceMode and 500 or 300
                    if dist < maxBillboardDist then
                        data.billboard.Enabled = true
                        -- PERFORMANCE FIX: Cache integer distance to avoid string GC pressure
                        if data.distLabel then
                            local flooredDist = math.floor(dist)
                            if data._lastDist ~= flooredDist then
                                data._lastDist = flooredDist
                                data.distLabel.Text = flooredDist .. " studs"
                            end
                        end
                    else
                        data.billboard.Enabled = false
                    end
                end
            end
        end
    end
end

    local function StartShared()
        activeCount = activeCount + 1
        if activeCount == 1 then
            ScanAll()
            scanLoop = task.spawn(function()
                local cleanupCounter = 0
                while activeCount > 0 do
                    ScanAll()
                    
                    -- Periodic cleanup every 10 scan cycles (~10 seconds)
                    cleanupCounter = cleanupCounter + 1
                    if cleanupCounter >= 10 then
                        cleanupCounter = 0
                        -- Clean up stale pending removal entries
                        local now = os.clock()
                        for zombie, timestamp in pairs(ESPPendingRemoval) do
                            if not zombie or not zombie.Parent then
                                if (now - timestamp) > 5 then -- 5 second hard timeout
                                    ESPPendingRemoval[zombie] = nil
                                end
                            else
                                -- Zombie has parent again, remove from pending
                                ESPPendingRemoval[zombie] = nil
                            end
                        end
                        -- Clean up IdentifiedIgniters for dead zombies
                        for zombie in pairs(IdentifiedIgniters) do
                            if not zombie or not zombie.Parent then
                                IdentifiedIgniters[zombie] = nil
                            end
                        end
                    end
                    
                    -- NOTE: manual collectgarbage removed – Luau's incremental GC handles
                    -- cleanup automatically; forcing a step here caused periodic lag spikes.
                    
                    task.wait(1.0) -- PERFORMANCE: Increased scan interval to 1 second
                end
            end)
            -- PERFORMANCE: Use Heartbeat with throttle; camera is cached once per interval
            local lastUpdate = 0
            local UPDATE_INTERVAL = 0.1 -- 10 FPS for ESP labels (was 0.2, smoother now)
            renderConn = RunService.Heartbeat:Connect(function()
                local now = os.clock()
                if now - lastUpdate < UPDATE_INTERVAL then return end
                lastUpdate = now
                
                -- Cache camera position once per throttled interval
                local cam = workspace.CurrentCamera
                if cam then
                    cachedCameraPos = cam.CFrame.Position
                    lastCameraCacheTime = now
                end
                
                UpdateAllBillboards()
            end)
        end
    end

    local function StopShared()
        activeCount = activeCount - 1
        if activeCount == 0 then
            if scanLoop then task.cancel(scanLoop) scanLoop = nil end
            if renderConn then renderConn:Disconnect() renderConn = nil end
            -- Clear pending removal table (already weak, but clear for good measure)
            for k in pairs(ESPPendingRemoval) do ESPPendingRemoval[k] = nil end
            -- Clear IdentifiedIgniters to free memory
            for k in pairs(IdentifiedIgniters) do IdentifiedIgniters[k] = nil end
            -- Clear any remaining ESP data entries, DESTROYING visuals first to prevent memory leak
            for espType in pairs(ESPData) do
                for zombie in pairs(ESPData[espType]) do
                    RemoveVisual(espType, zombie)
                end
                -- Reset to weak table to ensure GC works after clearing
                ESPData[espType] = setmetatable({}, { __mode = "k" })
            end
        end
    end

    local function TogglePerformanceMode(state)
        PerformanceMode = state
        -- PERFORMANCE FIX: Instead of recreating all visuals at once, do it gradually
        -- Just toggle visibility - visuals will be recreated on next scan cycle
        for espType in pairs(ESPConfigs) do
            for zombie, data in pairs(ESPData[espType]) do
                -- Toggle highlight/dot based on performance mode
                if data.highlight then
                    data.highlight.Enabled = not state
                end
                if data.dot then
                    data.dot.Enabled = state
                end
            end
        end
    end

    -- Cuirassier-specific state
    local LastChargeState = false
    local NotifyCuirassierCharge = false
    local CuirassierStateLoop

    local function IsCharging(state)
        state = tostring(state or ""):lower()
        return (state == "begincharge" or state == "charge")
    end

    local function UpdateCuirassierState()
        local zFolder = workspace:FindFirstChild("Zombies")
        if not zFolder then return end
        local slim = zFolder:FindFirstChild("Slim")
        if not slim then return end
        local stateVal = slim:FindFirstChild("State")
        if not stateVal or not stateVal:IsA("StringValue") then return end

        local charging = IsCharging(stateVal.Value)
        for _, data in pairs(ESPData.Cuirassier) do
            if data.label and (data.frame or true) then
                if charging then
                    data.label.Text = "Charging"
                    data.label.TextColor3 = Color3.fromRGB(255, 80, 80)
                    if data.frame then data.frame.BorderColor3 = Color3.fromRGB(255, 80, 80) end
                else
                    data.label.Text = "Cuirassier"
                    data.label.TextColor3 = ESPConfigs.Cuirassier.color
                    if data.frame then data.frame.BorderColor3 = ESPConfigs.Cuirassier.color end
                end
            end
        end
        if charging and NotifyCuirassierCharge and not LastChargeState then
            pcall(function()
                if WindUI and typeof(WindUI.Notify) == "function" then
                    WindUI:Notify({ Title = "Cuirassier Charge", Content = "A Cuirassier is Charging!", Icon = "bell", Duration = 3 })
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
                task.wait(0.5)
            end
        end)
    end

    local function StopCuirassierSpecific()
        if CuirassierStateLoop then task.cancel(CuirassierStateLoop) CuirassierStateLoop = nil end
        LastChargeState = false
    end

    local function ApplyColorToExisting(espType, color)
        local dataTable = ESPData[espType]
        if not dataTable then return end
        for zombie, data in pairs(dataTable) do
            pcall(function()
                if data.highlight then data.highlight.FillColor = color end
                if data.frame then data.frame.BorderColor3 = color end
                if data.label then data.label.TextColor3 = color end
                if data.dot then
                    for _, child in ipairs(data.dot:GetDescendants()) do
                        if child:IsA("Frame") then child.BackgroundColor3 = color end
                    end
                end
            end)
        end
    end

-- ===== Improved multi-select ESP dropdown + enable toggle =====
local EspList = { "Bomber", "Cuirassier", "Runner", "Zapper", "Igniter", "Shambler" }
SelectedESPs = SelectedESPs or {} -- list/table of selected types (global for config)
previousSelectedESPs = previousSelectedESPs or {} -- global for config
local espToggle -- forward ref
ESPData = ESPData or {}       -- make sure table exists
EnabledESPs = EnabledESPs or {} -- ensure exists

-- helper: remove all visuals safely for given type
local function RemoveAllVisualsForType(typeName)
    local t = ESPData[typeName]
    if not t then return end
    -- PERFORMANCE FIX: Batch destroy visuals and clear all references
    for zombieModel, data in pairs(t) do
        if data then
            if data.highlight then pcall(function() data.highlight:Destroy() end) end
            if data.billboard then pcall(function() data.billboard:Destroy() end) end
            if data.dot then pcall(function() data.dot:Destroy() end) end
            -- Clear references to help GC
            data.highlight = nil
            data.billboard = nil
            data.dot = nil
            data.frame = nil
            data.label = nil
            data.distLabel = nil
        end
        -- Clear from IdentifiedIgniters and pending removal
        if zombieModel then
            IdentifiedIgniters[zombieModel] = nil
            ESPPendingRemoval[zombieModel] = nil
        end
    end
    -- Reset to weak table to ensure GC works properly
    ESPData[typeName] = setmetatable({}, { __mode = "k" })
end

-- helper: check if any ESP type is currently enabled
local function AnyESPEnabled()
    for k, v in pairs(EnabledESPs) do
        if v then return true end
    end
    return false
end

local espDropdown = ESPSection:Dropdown({
    Title = "Select ESP Types",
    Flag = "Select_ESP_Types",
    Desc = "Select zombie types to show ESP.",
    Values = EspList,
    Value = {},            -- default empty
    Multi = true,
    Callback = function(selection)
        local newSelection = selection or {}
        -- normalize to array of strings
        local normalized = {}
        for _, v in ipairs(newSelection) do table.insert(normalized, tostring(v)) end

        -- build lookup sets
        local prevSet = {}
        for _, v in ipairs(previousSelectedESPs) do prevSet[tostring(v)] = true end
        local newSet = {}
        for _, v in ipairs(normalized) do newSet[tostring(v)] = true end

        -- 1) Handle removals: previously selected but not present now
        for _, removedKey in ipairs(previousSelectedESPs) do
            if not newSet[tostring(removedKey)] then
                -- Always remove any visuals and clear runtime state for this type
                RemoveAllVisualsForType(removedKey)
                EnabledESPs[removedKey] = false
                -- Cuirassier specific cleanup
                if removedKey == "Cuirassier" then
                    pcall(function() StopCuirassierSpecific() end)
                end
                -- if no types enabled now, stop shared routines
                if not AnyESPEnabled() then pcall(function() StopShared() end) end

                if ESPTab_InitComplete then
                    pcall(function()
                        WindUI:Notify({
                            Title = (removedKey .. " ESP"),
                            Content = (removedKey .. " ESP disabled (deselected)"),
                            Icon = "eye-off",
                            Duration = 1
                        })
                    end)
                end
            end
        end

        -- 2) Update SelectedESPs / previousSelectedESPs
        SelectedESPs = {}
        for _, v in ipairs(normalized) do table.insert(SelectedESPs, v) end

        previousSelectedESPs = {}
        for _, v in ipairs(SelectedESPs) do table.insert(previousSelectedESPs, v) end

        -- 3) Sync toggle UI: if nothing selected -> false, else true only if *all* selected are enabled
        if espToggle then
            local anySelected = (#SelectedESPs > 0)
            if not anySelected then
                pcall(function() espToggle:Select(false) end)
            else
                local allEnabled = true
                for _, key in ipairs(SelectedESPs) do
                    if not EnabledESPs[key] then
                        allEnabled = false
                        break
                    end
                end
                pcall(function() espToggle:Select(allEnabled) end)
            end
        end

        if ESPTab_InitComplete then
            pcall(function()
                WindUI:Notify({
                    Title = "ESP Selection",
                    Content = (#SelectedESPs > 0) and ("Selected: " .. table.concat(SelectedESPs, ", ")) or "No selection",
                    Icon = "eye",
                    Duration = 1
                })
            end)
        end
    end
})

-- Toggle: enables/disables all currently selected ESP types
espToggle = ESPSection:Toggle({
    Title = "Enable Selected ESP",
    Flag = "Enable_Selected_ESP",
    Desc = "Enable ESP for selected zombie type.",
    Default = false,
    Callback = function(state)
        -- ensure SelectedESPs is a table
        if not SelectedESPs or #SelectedESPs == 0 then
            pcall(function() WindUI:Notify({ Title = "ESP", Content = "No ESP types selected.", Icon = "alert-circle", Duration = 2 }) end)
            -- keep the toggle UI false if nothing selected
            pcall(function() espToggle:Select(false) end)
            return
        end

        for _, key in ipairs(SelectedESPs) do
            -- skip invalid keys (guard block instead of goto)
            if key then
                -- only act if the state actually changes for that key
                if EnabledESPs[key] ~= state then
                    EnabledESPs[key] = state

                    if state then
                        -- enabling this ESP type
                        ESPData[key] = ESPData[key] or {}
                        pcall(function() StartShared() end)
                        if key == "Cuirassier" then pcall(function() StartCuirassierSpecific() end) end
                        pcall(function()
                            WindUI:Notify({ Title = (key .. " ESP"), Content = (key .. " ESP enabled"), Icon = "eye", Duration = 1 })
                        end)
                    else
                        -- disabling this ESP type: remove visuals & clear data
                        pcall(function() RemoveAllVisualsForType(key) end)
                        EnabledESPs[key] = false
                        if key == "Cuirassier" then pcall(function() StopCuirassierSpecific() end) end
                        -- only stop shared if nothing else is enabled
                        if not AnyESPEnabled() then pcall(function() StopShared() end) end
                        pcall(function()
                            WindUI:Notify({ Title = (key .. " ESP"), Content = (key .. " ESP disabled"), Icon = "eye-off", Duration = 1 })
                        end)
                    end
                end
            end
        end
    end
})

    -- =========================
    -- ESP Colors (unchanged + new Shambler color)
    -- =========================
    local ColorsSection = EspTab:Section({ Title = "ESP Colors", Icon = "palette", Opened = false })
    ColorsSection:Colorpicker({ Title = "Barrel (Bomber)", Flag = "ESP_Colors", Desc = "Color for Bomber zombies.", Default = ESPConfigs.Bomber.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Bomber.color = color ApplyColorToExisting("Bomber", color) end })
    ColorsSection:Colorpicker({ Title = "Cuirassier", Flag = "ESP_Colors_1", Desc = "Color for Cuirassier zombies.", Default = ESPConfigs.Cuirassier.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Cuirassier.color = color ApplyColorToExisting("Cuirassier", color) end })
    ColorsSection:Colorpicker({ Title = "Runner", Flag = "ESP_Colors_2", Desc = "Color for Runner zombies.", Default = ESPConfigs.Runner.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Runner.color = color ApplyColorToExisting("Runner", color) end })
    ColorsSection:Colorpicker({ Title = "Zapper", Flag = "ESP_Colors_3", Desc = "Color for Zapper zombies.", Default = ESPConfigs.Zapper.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Zapper.color = color ApplyColorToExisting("Zapper", color) end })
    ColorsSection:Colorpicker({ Title = "Igniter", Flag = "ESP_Colors_4", Desc = "Color for Igniter zombies.", Default = ESPConfigs.Igniter.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Igniter.color = color ApplyColorToExisting("Igniter", color) end })
    ColorsSection:Colorpicker({ Title = "Shambler (Normal)", Flag = "ESP_Colors_5", Desc = "Color for normal Shambler zombies.", Default = ESPConfigs.Shambler.color, Transparency = 0, Locked = false, Callback = function(color) ESPConfigs.Shambler.color = color ApplyColorToExisting("Shambler", color) end })

    local SettingsSection = EspTab:Section({ Title = "Settings", Icon = "settings", Opened = false })
    SettingsSection:Toggle({ Title = "Show Billboard", Flag = "ESP_Colors_6", Desc = "Show billboards above zombies.", Default = false, Callback = function(state) ShowBillboards = state end })
    SettingsSection:Slider({ Title = "Chams Transparency", Flag = "ESP_Colors_7", Desc = "Chams transparency.", Value = { Min = 0, Max = 1, Default = 0.6 }, Step = 0.05, Callback = function(value) ChamsTransparency = math.clamp(tonumber(value) or 0.6, 0, 1) UpdateAllTransparencies() end })
    SettingsSection:Slider({
        Title = "Chams View Distance",
        Flag = "Runner",
        Desc = "Max ESP render distance (studs).",
        Value = { Min = 500, Max = 5000, Default = 2000 },
        Step = 100,
        Callback = function(value)
            ChamsMaxDistance = math.clamp(tonumber(value) or 2000, 500, 5000)
            for _, dataTable in pairs(ESPData) do
                for _, data in pairs(dataTable) do
                    data.maxDistance = ChamsMaxDistance
                    if data.dot then
                        data.dot.MaxDistance = ChamsMaxDistance
                    end
                end
            end
        end
    })
    SettingsSection:Toggle({ Title = "Performance", Flag = "Performance", Desc = "Performance mode (reduces chams to dots).", Default = false, Callback = function(state) TogglePerformanceMode(state) end })
    SettingsSection:Toggle({ Title = "Notify Cuirassier Charge", Flag = "Performance_1", Desc = "Notify when a Cuirassier charges.", Default = false, Callback = function(state) NotifyCuirassierCharge = state end })
    
    -- PERFORMANCE FIX: Mark ESP Tab initialization as complete
    ESPTab_InitComplete = true
end -- end of ESP Tab

task.wait(0.1) -- Delay to prevent lag
do -- // KillAura Tab
local KillAuraTab = CombatTab -- Kill Aura goes inside CombatTab

-- === Kill Aura + Hitbox Expander (Position-match Barrel Mapping) ===
-- Uses position matching to exclude camera barrel zombies from real zombie targeting

-- PERFORMANCE FIX: Flag to suppress notifications during UI initialization
local KillAuraTab_InitComplete = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Config
local DEBUG = false

-- Anti-Detection Settings (Balanced: fast but safe)
local KILLAURA_ANTICHEAT_BYPASS = true -- Enable anti-detection measures
local KILLAURA_MIN_DELAY = 0.028-- Minimum delay between attacks (25ms - fast but safe)
local KILLAURA_RANDOMIZE_DELAY = true -- Add random variation to timing
local KILLAURA_MAX_ATTACKS_PER_SECOND = 30 -- Maximum attacks per second (faster than do.lua)
local KILLAURA_SWING_TO_HIT_DELAY = 0.015 -- Delay between Swing and HitZombie (15ms - minimal)

-- State variables (Global for keybind access)
KillAuraEnabled = false
KillAuraRange = 10
KillAuraAttackSpeed = 0.1 -- Default attack speed (seconds)
KillAuraRandomness = 0 -- Random variation (0-1, percentage of attack speed)
KillAuraMode = "Fast" -- "Legit" (human-like) or "Fast" (0.5s interval)
KillAura_MaxRange = 30 -- Max range restored to 30 studs
KillAuraMultiTargets = 5
KillAuraAutoLook = false
KillAura_AutoEquipMelee = false
IgnoreSpawningZombies = true
KillAura_HitboxExpanderEnabled = false

-- Zombie type targeting (which types to kill) - global for config
-- Types: Shambler (Normal), Bomber (Barrel), Runner (Fast), Zapper (Sapper), Igniter, Cuirassier (Slim)
KillAura_SelectedZombieTypes = {
    ["Shambler"] = true,
    ["Bomber"] = false,
    ["Runner"] = true,
    ["Zapper"] = true,
    ["Igniter"] = true,
    ["Cuirassier"] = true
}

-- NEW: bayonet setting (global for config)
KillAura_EnableBayonet = false

-- ADDED: Store reference to Hitbox Expander toggle for programmatic control
local HitboxExpanderToggleElement = nil

-- Internal state
-- Use weak keys so destroyed remotes get garbage collected
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

local function KillAura_isPinnedOrGrabbed()
    local wsPlayers = Workspace:FindFirstChild("Players")
    if not wsPlayers then return false end
    local folder = wsPlayers:FindFirstChild(LocalPlayer and LocalPlayer.Name or "")
    if not folder then return false end
    local userStates = folder:FindFirstChild("UserStates")
    if not userStates then return false end

    local grabbedVal = userStates:FindFirstChild("Grabbed")
    local pinVal = userStates:FindFirstChild("Pin")

    local function valIndicatesTrue(v)
        if not v or v.Value == nil then return false end
        local val = v.Value
        if type(val) == "boolean" and val == true then return true end
        local n = tonumber(val)
        if n and n > 0 then return true end
        if tostring(val):lower() == "true" then return true end
        local vs = tostring(val)
        if vs == "RunnerAttack" or vs == "RunnerClaw" or vs == "RunnerVomit" then return true end
        return false
    end

    return valIndicatesTrue(grabbedVal) or valIndicatesTrue(pinVal)
end

-- Helper functions
local function KillAura_findHead(zombie)
    if not zombie or not zombie:IsA("Model") then return nil end
    return zombie:FindFirstChild("Head") or zombie:FindFirstChild("head") or 
           zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChildWhichIsA("BasePart")
end

local function KillAura_isSpawning(model)
    local agent = model:FindFirstChild("Agent")
    if not agent then return false end
    local state = agent:FindFirstChild("State")
    if not state or not state:IsA("StringValue") then return false end
    return state.Value == "Spawn"
end

local function KillAura_distSq(a, b)
    if not a or not b then return math.huge end
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return dx*dx + dy*dy + dz*dz
end

-- Anti-detection: Sliding-window rate limiter (smoother than per-second bucket)
-- Instead of math.floor(os.clock()) which lets all 30 attacks fire in a burst
-- at the start of each second, this spreads them evenly across the window.
local KILLAURA_WINDOW_START = os.clock()
local KILLAURA_WINDOW_COUNT = 0

local function KillAura_canAttack()
    if not KILLAURA_ANTICHEAT_BYPASS then return true end
    local now = os.clock()
    -- Slide the window: if >1s elapsed, reset
    if now - KILLAURA_WINDOW_START >= 1 then
        KILLAURA_WINDOW_START = now
        KILLAURA_WINDOW_COUNT = 0
    end
    return KILLAURA_WINDOW_COUNT < KILLAURA_MAX_ATTACKS_PER_SECOND
end

local function KillAura_registerAttack()
    KILLAURA_WINDOW_COUNT = KILLAURA_WINDOW_COUNT + 1
end

-- Anti-detection: Get randomized delay
local function KillAura_getRandomizedDelay(baseDelay)
    if KillAuraRandomness <= 0 then return baseDelay end
    -- Add random variation based on slider value
    local variation = baseDelay * KillAuraRandomness
    return baseDelay + (math.random() * variation * 2 - variation)
end

local function KillAura_fireSwing(remote)
    if not (remote and remote:IsA("RemoteEvent")) then return end
    pcall(function() _G.SafeFireServer(remote, "Swing", "Side") end)
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
    for r,_ in pairs(KillAura_remotes) do
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
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            for _, c in ipairs(tool:GetChildren()) do
                if KillAura_registerRemote(c) and not KillAura_primaryRemote then
                    KillAura_primaryRemote = c
                end
            end
        end
    end
    KillAura_lastRemoteScan = os.clock()
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

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    KillAura_ScanRemotesNow()
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then KillAura_DebouncedScan() end
    end)
    char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then KillAura_DebouncedScan() end
    end)
end)
if LocalPlayer.Character then KillAura_ScanRemotesNow() end

local function KillAura_isGun(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool:FindFirstChild("Ammo") or tool:FindFirstChild("ShotsLoaded") then return true end
    if tool:FindFirstChild("GunSettings") then return true end
    local cfg = tool:FindFirstChild("Configuration")
    if cfg and (cfg:FindFirstChild("Ammo") or cfg:FindFirstChild("ShotsLoaded")) then return true end
    return false
end

-- Helper: detect bayonet-usable tool (Musket) when enabled
local function KillAura_isBayonetTool(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    if not KillAura_EnableBayonet then return false end
    local name = string.lower(tool.Name)
    -- You can tighten this check if your game uses a different name
    return name == "musket" or string.find(name, "musket")
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
    for _, tool in ipairs(container:GetChildren()) do
        if KillAura_isMelee(tool) then
            return tool
        end
    end
    return nil
end

local function KillAura_getMeleeTool()
    local char = LocalPlayer.Character
    if not char then return nil end

    local equipped = KillAura_findMeleeToolIn(char)
    if equipped then return equipped end
    
    -- COORDINATION: If Shove Aura is enabled, check if a shove-compatible tool is equipped
    -- If so, we can use it for Kill Aura too (melee tools can shove)
    if ShoveAuraEnabled then
        local anyEquipped = char:FindFirstChildOfClass("Tool")
        if anyEquipped then
            -- Check if the equipped tool has a remote we can use
            local toolFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild(LocalPlayer.Name)
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
    if stored and KillAura_AutoEquipMelee then
        -- COORDINATION: Don't equip if Shove Aura recently fired (prevents fighting)
        local coord = _G.AuraCoordination
        if coord and ShoveAuraEnabled then
            local timeSinceShoveAura = os.clock() - (coord.shoveAuraLastFire or 0)
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
        range = math.max(range, attrRange)
    end

    local override = KillAura_weaponRangeOverrides[tool.Name]
    if override then
        range = math.max(range, override)
    end

    return range
end

local function KillAura_getRemoteForTool(tool)
    if tool then
        local remote = tool:FindFirstChild("RemoteEvent")
        if not remote then
            remote = tool:FindFirstChildWhichIsA("RemoteEvent")
        end
        if remote then
            KillAura_registerRemote(remote)
            KillAura_primaryRemote = remote
            return remote
        end
    end
    return KillAura_getPrimaryRemote()
end

-- Helper: Get zombie type from model
local function KillAura_getZombieType(model)
    if not (model and model:IsA("Model")) then return nil end
    
    -- Check Agent folder for Type attribute
    local agent = model:FindFirstChild("Agent")
    if agent then
        local typeValue = agent:FindFirstChild("Type")
        if typeValue and typeValue:IsA("StringValue") then
            local attrType = string.lower(typeValue.Value or "")
            if attrType == "normal" then return "Shambler" end
            if attrType == "barrel" then return "Bomber" end
            if attrType == "fast" then return "Runner" end
            if attrType == "sapper" then return "Zapper" end
            if attrType == "igniter" then return "Igniter" end
            if attrType == "cuirassier" then return "Cuirassier" end
        end
    end
    
    -- Fallback: check model attributes
    if typeof(model.GetAttribute) == "function" then
        local attrType = string.lower(tostring(model:GetAttribute("Type") or ""))
        if attrType == "normal" then return "Shambler" end
        if attrType == "barrel" then return "Bomber" end
        if attrType == "fast" then return "Runner" end
        if attrType == "sapper" then return "Zapper" end
        if attrType == "igniter" then return "Igniter" end
        if attrType == "cuirassier" then return "Cuirassier" end
    end
    
    -- Default to Shambler if no type found
    return "Shambler"
end

-- Helper: Get random part from Cuirassier for attack targeting
-- PERFORMANCE FIX: Use GetChildren() instead of GetDescendants() to avoid deep traversal every attack
local function KillAura_getRandomCuirassierPart(model)
    if not (model and model:IsA("Model")) then return nil end
    local parts = {}
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    if #parts == 0 then return nil end
    return parts[math.random(1, #parts)]
end

-- Helper: Get attack position (random part for Cuirassier, head for others)
local function KillAura_getAttackPosition(model, head)
    -- Validate inputs
    if not model or not model.Parent then return nil end
    if not head or not head.Parent then return nil end
    
    local zombieType = KillAura_getZombieType(model)
    if zombieType == "Cuirassier" then
        local randomPart = KillAura_getRandomCuirassierPart(model)
        if randomPart and randomPart.Parent then
            return randomPart.Position
        end
    end
    
    -- Ensure head still exists
    if head and head.Parent then
        return head.Position
    end
    return nil
end

local function KillAura_shouldSkipZombie(model)
    if not (model and model:IsA("Model")) then return true end
    if IgnoreSpawningZombies and KillAura_isSpawning(model) then return true end
    
    -- Get the zombie type and check if it's selected
    local zombieType = KillAura_getZombieType(model)
    if zombieType and not KillAura_SelectedZombieTypes[zombieType] then
        return true -- Skip this zombie type (not selected)
    end
    
    return false
end

-- Fast mode helper: fires remotes with SafeFireServer for anti-detection
local function KillAura_performFastAttack(meleeTool, primaryRemote, entry, isBayonet, hrpPos)
    -- Quick validation
    local model = entry.model
    local head = entry.head
    if not model or not model.Parent or not head or not head.Parent then return end
    
    -- Get attack position
    local attackPos = head.Position
    if not attackPos then return end
    
    -- Use SafeFireServer with realistic timing between actions
    -- PERF FIX: Wrapped in task.spawn so task.wait() does NOT stall the heartbeat thread
    local isAxe = meleeTool.Name == "Axe"
    
    task.spawn(function()
        pcall(function()
            if isAxe then
                _G.SafeFireServer(primaryRemote, "BraceBlock")
                task.wait(0.02)
                _G.SafeFireServer(primaryRemote, "StopBraceBlock")
                task.wait(0.02)
                _G.SafeFireServer(primaryRemote, "FeedbackStun", model, attackPos)
            end
            
            if isBayonet then
                _G.SafeFireServer(primaryRemote, "ThrustBayonet")
                task.wait(KILLAURA_SWING_TO_HIT_DELAY) -- Delay between thrust and hit
                if model and model.Parent then -- Re-validate
                    _G.SafeFireServer(primaryRemote, "Bayonet_HitZombie", model, attackPos, true)
                end
            else
                _G.SafeFireServer(primaryRemote, "Swing", "Thrust")
                task.wait(KILLAURA_SWING_TO_HIT_DELAY) -- Delay between swing and hit
                if model and model.Parent then -- Re-validate
                    _G.SafeFireServer(primaryRemote, "HitZombie", model, attackPos, true, Vector3.new(0, 15, 0), "Head", Vector3.new(0, 1, 0))
                end
            end
        end)
    end)
end

-- Cached zombies folder reference for speed
local KillAura_zombiesFolder = nil
local KillAura_lastZombieFolderCheck = 0

local function KillAura_getZombiesFolder()
    local now = os.clock()
    if now - KillAura_lastZombieFolderCheck > 2 then
        KillAura_zombiesFolder = Workspace:FindFirstChild("Zombies")
        KillAura_lastZombieFolderCheck = now
    end
    return KillAura_zombiesFolder
end

-- Pre-allocated targets table reused every tick to avoid GC pressure
local _killAuraTargetsBuf = {}
local _autoHeadTargetsBuf = {}

local function KillAura_performKillAura(hrp)
    if not KillAuraEnabled then return end

    local meleeTool = KillAura_getMeleeTool()
    if not meleeTool then return end

    local primaryRemote = KillAura_getRemoteForTool(meleeTool)
    if not primaryRemote then return end

    local isBayonet = KillAura_isBayonetTool(meleeTool)
    local hrpPos = hrp.Position
    local effectiveRange = KillAura_getWeaponRange(meleeTool)
    local rangeSq = effectiveRange * effectiveRange

    -- Use cached zombies folder
    local zombiesFolder = KillAura_getZombiesFolder()
    if not zombiesFolder then return end
    
    -- Reuse pre-allocated buffer (clear without creating new table)
    local targets = _killAuraTargetsBuf
    local targetCount = 0
    for i = #targets, 1, -1 do targets[i] = nil end

    local maxTargets = KillAuraMultiTargets or 5
    
    -- Use GetChildren on Zombies folder (faster than GetDescendants for direct children)
    for _, model in ipairs(zombiesFolder:GetChildren()) do
        if model:IsA("Model") then
            -- Inline skip check for speed (with nil safety)
            local shouldSkip = false
            if IgnoreSpawningZombies then
                local agent = model:FindFirstChild("Agent")
                if agent then
                    local state = agent:FindFirstChild("State")
                    if state and state:IsA("StringValue") and state.Value == "Spawn" then
                        shouldSkip = true
                    end
                end
            end
            
            if not shouldSkip then
                -- Check zombie type selection
                local zombieType = KillAura_getZombieType(model)
                if not zombieType or KillAura_SelectedZombieTypes[zombieType] then
                    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                    if head then
                        local headPos = head.Position
                        local dx, dy, dz = headPos.X - hrpPos.X, headPos.Y - hrpPos.Y, headPos.Z - hrpPos.Z
                        local d2 = dx*dx + dy*dy + dz*dz
                        if d2 <= rangeSq then
                            targetCount = targetCount + 1
                            targets[targetCount] = { model = model, head = head, d2 = d2 }
                            -- Early exit if we have enough targets
                            if targetCount >= maxTargets * 2 then break end
                        end
                    end
                end
            end
        end
    end

    if targetCount == 0 then return end
    
    -- Only sort if we have more targets than needed
    if targetCount > maxTargets then
        table.sort(targets, function(a, b) return a.d2 < b.d2 end)
    end

    local attackCount = math.min(maxTargets, targetCount)
    
    -- Batch attack all targets (rate-limited per target)
    for i = 1, attackCount do
        if not KillAura_canAttack() then break end
        local entry = targets[i]
        if entry then
            KillAura_registerAttack()
            KillAura_performFastAttack(meleeTool, primaryRemote, entry, isBayonet, hrpPos)
        end
    end
end

-- Separate Auto Look function that finds the nearest zombie independently
-- When flying: uses Fly's BodyGyro directly for seamless integration with pitch limit
-- When not flying: uses its own Y-axis BodyGyro
local KillAura_autoLookGyro = nil
KillAura_autoLookHasTarget = false -- Global: Track if we have a target (for fly to check)
local AUTO_LOOK_MAX_PITCH_DOWN = 60 -- Maximum degrees to look down (like fly limit)
local AUTO_LOOK_MAX_PITCH_UP = 45 -- Maximum degrees to look up
local autoLook_lastFlyState = false -- Track fly state to detect transitions
local autoLook_cachedHead = nil -- Cached nearest zombie head
local autoLook_cacheTime = 0
local AUTO_LOOK_CACHE_INTERVAL = 0.1 -- Re-scan zombies every 100ms (10fps) instead of every frame

local function KillAura_cleanupAutoLook()
    -- Mark no target
    KillAura_autoLookHasTarget = false
    
    -- Clean up our own gyro (only used when not flying)
    pcall(function()
        if KillAura_autoLookGyro then
            KillAura_autoLookGyro:Destroy()
            KillAura_autoLookGyro = nil
        end
    end)
    -- Also search and destroy any lingering gyros
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local gyro = hrp:FindFirstChild("LanderAutoLookGyro")
                if gyro then gyro:Destroy() end
            end
        end
    end)
    -- Note: Fly's BodyGyro is NOT touched here - fly loop handles its own gyro
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
                local gyro = hrp:FindFirstChild("LanderAutoLookGyro")
                if gyro then gyro:Destroy() end
            end
        end
    end)
end

local function KillAura_performAutoLook(hrp)
    -- If disabled, clean up everything and return
    if not KillAuraAutoLook then
        KillAura_cleanupAutoLook()
        autoLook_lastFlyState = FlyEnabled
        return
    end
    
    -- Detect fly state transition
    local flyStateChanged = (FlyEnabled ~= autoLook_lastFlyState)
    autoLook_lastFlyState = FlyEnabled
    
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
    local nearestDistSq = math.huge
    local maxRange = 50 -- Auto look range (independent of kill aura range)
    local maxRangeSq = maxRange * maxRange

    local now = os.clock()
    if now - autoLook_cacheTime >= AUTO_LOOK_CACHE_INTERVAL or not autoLook_cachedHead or not autoLook_cachedHead.Parent then
        autoLook_cacheTime = now
        -- Scan zombies only every 100ms
        for _, model in ipairs(zombiesFolder:GetChildren()) do
            if model:IsA("Model") then
                -- Filter by Kill Aura zombie types (only target selected types)
                local zombieType = KillAura_getZombieType(model)
                if zombieType and not KillAura_SelectedZombieTypes[zombieType] then
                    -- Skip this zombie - not in selected types
                else
                    local head = model:FindFirstChild("Head")
                    if head then
                        local headPos = head.Position
                        local dx, dy, dz = headPos.X - hrpPos.X, headPos.Y - hrpPos.Y, headPos.Z - hrpPos.Z
                        local d2 = dx*dx + dy*dy + dz*dz
                        if d2 < nearestDistSq and d2 <= maxRangeSq then
                            nearestDistSq = d2
                            nearestHead = head
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
        local targetPos = nearestHead.Position
        local direction = (targetPos - hrpPos)
        
        if direction.Magnitude > 0.1 then
            local targetCFrame
            
            -- Check if flying (FlyEnabled AND FlyBodyGyro exists)
            local isFlying = FlyEnabled and FlyBodyGyro and FlyBodyGyro.Parent
            
            if isFlying then
                -- FLYING: Look at actual target position with pitch limit
                -- Calculate pitch angle (angle from horizontal)
                local horizontalDist = math.sqrt(direction.X^2 + direction.Z^2)
                local verticalDist = direction.Y
                local pitchRad = math.atan2(-verticalDist, horizontalDist) -- Negative because down is negative Y
                local pitchDeg = math.deg(pitchRad)
                
                -- Clamp pitch to limits
                local clampedPitchDeg = math.clamp(pitchDeg, -AUTO_LOOK_MAX_PITCH_UP, AUTO_LOOK_MAX_PITCH_DOWN)
                local clampedPitchRad = math.rad(clampedPitchDeg)
                
                -- Calculate the look-at position with clamped pitch
                local horizontalDir = Vector3.new(direction.X, 0, direction.Z)
                if horizontalDir.Magnitude > 0.01 then
                    horizontalDir = horizontalDir.Unit
                else
                    horizontalDir = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
                    if horizontalDir.Magnitude > 0.01 then horizontalDir = horizontalDir.Unit else horizontalDir = Vector3.new(1, 0, 0) end
                end
                
                -- Create look-at point at clamped pitch angle
                local lookDist = 10 -- Arbitrary distance for look-at calculation
                local clampedY = -math.sin(clampedPitchRad) * lookDist
                local clampedHorizontal = math.cos(clampedPitchRad) * lookDist
                local lookAt = hrpPos + horizontalDir * clampedHorizontal + Vector3.new(0, clampedY, 0)
                
                targetCFrame = CFrame.lookAt(hrpPos, lookAt)
                
                -- Use Fly's BodyGyro directly
                KillAura_autoLookHasTarget = true
                FlyBodyGyro.CFrame = targetCFrame
                
                -- Destroy our own gyro if it exists (not needed when flying)
                if KillAura_autoLookGyro and KillAura_autoLookGyro.Parent then
                    KillAura_autoLookGyro:Destroy()
                    KillAura_autoLookGyro = nil
                end
            else
                -- NOT FLYING: Use our own Y-axis only BodyGyro (horizontal rotation only)
                local lookAt = Vector3.new(targetPos.X, hrpPos.Y, targetPos.Z)
                targetCFrame = CFrame.lookAt(hrpPos, lookAt)
                
                KillAura_autoLookHasTarget = true
                local autoLookGyro = hrp:FindFirstChild("LanderAutoLookGyro")
                
                if not autoLookGyro or not autoLookGyro.Parent then
                    -- Create new gyro for ground use
                    autoLookGyro = Instance.new("BodyGyro")
                    autoLookGyro.Name = "LanderAutoLookGyro"
                    autoLookGyro.P = 1000000 -- Very high P for instant rotation
                    autoLookGyro.D = 500 -- Low D to reduce oscillation
                    autoLookGyro.MaxTorque = Vector3.new(0, math.huge, 0) -- Y-axis only
                    autoLookGyro.Parent = hrp
                    KillAura_autoLookGyro = autoLookGyro
                end
                
                autoLookGyro.CFrame = targetCFrame
            end
        else
            -- Target too close, cleanup
            KillAura_cleanupAutoLook()
        end
    else
        -- No target
        KillAura_cleanupAutoLook()
    end
end

local function KillAura_performAutoHead(hrp)
    if not KillAura_HitboxExpanderEnabled then return end
    
    local meleeTool = KillAura_getMeleeTool()
    if not meleeTool then return end

    local primaryRemote = KillAura_getRemoteForTool(meleeTool)
    if not primaryRemote then return end

    local maxRangeSq = KillAura_MaxRange * KillAura_MaxRange
    local hrpPos = hrp.Position
    local isBayonet = KillAura_isBayonetTool(meleeTool)
    
    -- Reuse pre-allocated buffer to avoid GC pressure
    local targets = _autoHeadTargetsBuf
    for i = #targets, 1, -1 do targets[i] = nil end
    -- Parallel arrays to avoid creating a sub-table per zombie
    local targetModels = targets
    local targetHeads = _autoHeadTargetsBuf._heads or {}
    local targetDists = _autoHeadTargetsBuf._dists or {}
    _autoHeadTargetsBuf._heads = targetHeads
    _autoHeadTargetsBuf._dists = targetDists
    local targetCount = 0
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then return end
    
    for _, model in ipairs(zombiesFolder:GetChildren()) do
        if model:IsA("Model") and not KillAura_shouldSkipZombie(model) then
            local head = KillAura_findHead(model)
            if head then
                local d2 = KillAura_distSq(head.Position, hrpPos)
                if d2 <= maxRangeSq then
                    targetCount = targetCount + 1
                    targetModels[targetCount] = model
                    targetHeads[targetCount] = head
                    targetDists[targetCount] = d2
                end
            end
        end
    end
    -- Clear leftover slots
    for i = targetCount + 1, #targetModels do targetModels[i] = nil end
    
    if targetCount == 0 then return end

    -- Sort by distance using parallel arrays (insertion sort is fast for small N)
    for i = 2, targetCount do
        local md, hd, dd = targetModels[i], targetHeads[i], targetDists[i]
        local j = i - 1
        while j >= 1 and targetDists[j] > dd do
            targetModels[j+1] = targetModels[j]
            targetHeads[j+1] = targetHeads[j]
            targetDists[j+1] = targetDists[j]
            j = j - 1
        end
        targetModels[j+1] = md
        targetHeads[j+1] = hd
        targetDists[j+1] = dd
    end
    
    local maxTargets = KillAuraEnabled and math.min(KillAuraMultiTargets or 1, targetCount) or 1
    for i = 1, maxTargets do
        local model = targetModels[i]
        local head = targetHeads[i]
        if not model then break end
        
        -- Anti-detection: Rate limit and distance check
        if not KillAura_canAttack() then break end
        
        local attackPos = KillAura_getAttackPosition(model, head)
        
        -- Register this attack for rate limiting
        KillAura_registerAttack()
        
        if isBayonet then
            pcall(function()
                if not model or not model.Parent or not attackPos then return end
                _G.SafeFireServer(primaryRemote, "ThrustBayonet")
                _G.SafeFireServer(primaryRemote, "Bayonet_HitZombie", model, attackPos, true)
            end)
        else
            pcall(function()
                if not model or not model.Parent or not attackPos then return end
                _G.SafeFireServer(primaryRemote, "HitZombie", model, attackPos, true)
            end)
        end
    end
end

-- Heartbeat loop - continuous (deferred to prevent load freeze)
local KillAura_nextTick = 0
local killAuraHeartbeatConn = nil -- stored so it can be disconnected if needed

task.defer(function()
    task.wait(0.5) -- Stagger start
    killAuraHeartbeatConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- AUTO LOOK runs EVERY FRAME (not throttled by attack speed)
        -- Must run before any early returns to be responsive while flying
        if KillAuraAutoLook then
            KillAura_performAutoLook(hrp)
        end
        
        -- PERFORMANCE: Skip attack logic if both features are disabled
        if not KillAuraEnabled and not KillAura_HitboxExpanderEnabled then return end

        -- Pause attacks while grabbed/pinned (but Auto Look already ran above)
        if KillAura_isPinnedOrGrabbed() then return end

        local now = os.clock()
        
        -- COORDINATION: Check if Shove Aura just fired (avoid overlapping)
        local coord = _G.AuraCoordination
        if coord then
            local timeSinceShoveAura = now - (coord.shoveAuraLastFire or 0)
            -- If Shove Aura fired very recently and is enabled, tiny delay
            if ShoveAuraEnabled and timeSinceShoveAura < 0.02 then
                return -- Skip this frame, try next heartbeat
            end
        end
        
        -- Attack speed throttle
        if now < KillAura_nextTick then return end
        
        -- Calculate delay based on attack speed
        local baseDelay = KillAuraAttackSpeed
        
        -- ALWAYS add some randomness for anti-detection (looks more human)
        if KILLAURA_RANDOMIZE_DELAY then
            -- Add 10-30% random variation
            local variation = baseDelay * (0.1 + KillAuraRandomness * 0.2)
            baseDelay = baseDelay + (math.random() * variation * 2 - variation)
        end
        
        -- Ensure minimum delay for safety
        baseDelay = math.max(baseDelay, KILLAURA_MIN_DELAY)
        
        KillAura_nextTick = now + baseDelay

        -- Scan remotes periodically
        if now - KillAura_lastRemoteScan > 5 then KillAura_ScanRemotesNow() end

        -- COORDINATION: Mark when Kill Aura fires
        if coord then
            coord.killAuraLastFire = now
        end

        -- Execute attacks
        if KillAura_HitboxExpanderEnabled then
            KillAura_performAutoHead(hrp)
        end
        if KillAuraEnabled then
            KillAura_performKillAura(hrp)
        end
    end)
end)

-- UI Creation
-- Hitbox Expander Settings
local HitboxExpanderSection = KillAuraTab:Section({ Title = "Reach", Icon = "box", Opened = false })

-- Store toggle element reference and use helper function
local function SetHitboxExpanderState(enabled)
    KillAura_HitboxExpanderEnabled = enabled
    
    -- Update UI toggle state without triggering callback if framework supports it
    if HitboxExpanderToggleElement and HitboxExpanderToggleElement.SetValue then
        HitboxExpanderToggleElement:SetValue(enabled)
    end
    
    WindUI:Notify({
        Title = "Reach",
        Content = enabled and "Reach Enabled" or "Reach Disabled",
        Duration = 2,
        Icon = enabled and "scan" or "x"
    })
end

HitboxExpanderToggleElement = HitboxExpanderSection:Toggle({
    Title = "Reach",
    Flag = "Reach",
    Desc = "Extend attack range up to ~30 studs.",
    Default = false,
    Callback = function(v)
        KillAura_HitboxExpanderEnabled = v
        WindUI:Notify({
            Title = "Reach",
            Content = v and "Reach Enabled" or "Reach Disabled",
            Duration = 2,
            Icon = v and "scan" or "x"
        })
    end
})
_G.LanderToggleElements = _G.LanderToggleElements or {}
_G.LanderToggleElements.Reach = HitboxExpanderToggleElement

HitboxExpanderSection:Slider({
    Title = "Reach Range",
    Flag = "Reach_Range",
    Desc = "Reach distance.",
    Step = 1,
    Value = { Min = 5, Max = 30, Default = KillAura_MaxRange },
    Callback = function(v)
        KillAura_MaxRange = v
    end
})

-- Kill Aura Settings
local KillAuraSection = KillAuraTab:Section({ Title = "Kill Aura", Icon = "sword", Opened = false })

local KillAuraToggle = KillAuraSection:Toggle({
    Title = "Kill Aura",
    Flag = "Kill_Aura",
    Desc = "Auto attack zombies in range.",
    Default = false,
    Callback = function(v)
        KillAuraEnabled = v
        
        -- Auto-toggle Hitbox Expander to match Kill Aura state
        SetHitboxExpanderState(v)
        
        WindUI:Notify({
            Title = "Kill Aura",
            Content = v and "Kill Aura Enabled" or "Kill Aura Disabled",
            Duration = 2,
            Icon = v and "sword" or "x"
        })
    end
})
_G.LanderToggleElements.KillAura = KillAuraToggle

KillAuraSection:Slider({
    Title = "Kill Aura Range",
    Desc = "Range where Kill Aura starts attacking.",
    Flag = "Kill_Aura_Range",
    Step = 1,
    Value = { Min = 5, Max = 30, Default = KillAuraRange },
    Callback = function(v)
        KillAuraRange = v
    end
})

KillAuraSection:Slider({
    Title = "Attack Speed",
    Desc = "Attack delay (lower = faster).",
    Flag = "Attack_Speed",
    Step = 0.01,
    Value = { Min = 0.01, Max = 0.5, Default = KillAuraAttackSpeed },
    Callback = function(v)
        KillAuraAttackSpeed = v
    end
})

KillAuraSection:Slider({
    Title = "Randomness",
    Desc = "Random delay for natural timing.",
    Flag = "Randomness",
    Step = 0.05,
    Value = { Min = 0, Max = 1, Default = KillAuraRandomness },
    Callback = function(v)
        KillAuraRandomness = v
    end
})

KillAuraSection:Slider({
    Title = "Multi-Target",
    Desc = "Zombies per swing.",
    Flag = "Multi_Target",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = KillAuraMultiTargets },
    Callback = function(v)
        KillAuraMultiTargets = v
    end
})

local AutoEquipMeleeToggle = KillAuraSection:Toggle({
    Title = "Auto Equip Melee",
    Flag = "Auto_Equip_Melee",
    Desc = "Auto equip melee when Kill Aura is on.",
    Default = KillAura_AutoEquipMelee,
    Callback = function(v)
        KillAura_AutoEquipMelee = v
    end
})
_G.LanderToggleElements.AutoEquipMelee = AutoEquipMeleeToggle

KillAuraSection:Dropdown({
    Title = "Target Zombie Types",
    Flag = "Target_Zombie_Types",
    Desc = "Select zombie types to attack.",
    Multi = true,
    Values = {"Shambler", "Bomber", "Runner", "Zapper", "Igniter", "Cuirassier"},
    Default = {"Shambler", "Runner", "Zapper", "Igniter", "Cuirassier"},
    Callback = function(selected)
        -- Reset all to false
        for k, _ in pairs(KillAura_SelectedZombieTypes) do
            KillAura_SelectedZombieTypes[k] = false
        end
        -- Enable selected types
        if type(selected) == "table" then
            for _, typeName in ipairs(selected) do
                KillAura_SelectedZombieTypes[typeName] = true
            end
        end
        if KillAuraTab_InitComplete then
            local count = 0
            for _, v in pairs(KillAura_SelectedZombieTypes) do
                if v then count = count + 1 end
            end
            WindUI:Notify({
                Title = "Kill Aura",
                Content = "Targeting " .. count .. " zombie type(s)",
                Duration = 2,
                Icon = "target"
            })
        end
    end
})

-- NEW: Enable Bayonet Kill Aura setting
local BayonetKillAuraToggle = KillAuraSection:Toggle({
    Title = "Enable Bayonet Kill Aura",
    Flag = "Enable_Bayonet_Kill_Aura",
    Desc = "Kill Aura uses bayonet.",
    Default = KillAura_EnableBayonet,
    Callback = function(v)
        KillAura_EnableBayonet = v
        WindUI:Notify({
            Title = "Kill Aura",
            Content = v and "Bayonet Kill Aura Enabled" or "Bayonet Kill Aura Disabled",
            Duration = 2,
            Icon = v and "sword" or "x"
        })
    end
})
_G.LanderToggleElements.BayonetKillAura = BayonetKillAuraToggle

local AutoLookToggle = KillAuraSection:Toggle({
    Title = "Auto Look",
    Flag = "Auto_Look",
    Desc = "Auto face the nearest zombie.",
    Default = false,
    Callback = function(v)
        KillAuraAutoLook = v
        if not v then
            -- Immediately cleanup when disabled
            KillAura_cleanupAutoLook()
        end
        WindUI:Notify({
            Title = "Kill Aura",
            Content = v and "Auto Look ON" or "Auto Look OFF",
            Duration = 2,
            Icon = v and "eye" or "eye-off"
        })
    end
})
_G.LanderToggleElements.AutoLook = AutoLookToggle

-- PERFORMANCE FIX: Mark KillAura Tab initialization as complete
KillAuraTab_InitComplete = true

end -- end of KillAuraTab block

-- Define ClassesTab at outer scope so it's accessible to all sub-sections
local ClassesTab = PlayerTab -- Classes goes inside PlayerTab

task.wait(0.1) -- Delay to prevent lag
do -- // Classes Tab (Musician Section)
    local MusicianSection = ClassesTab:Section({
        Title = "Musician",
        Icon = "music-2",
        Opened = false
    })

    -- Auto Play (fife/drum/bagpipe) — simplified, no lag, always finds tools
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer

    -- start OFF by default; toggle controls everything
    local AutoInstrumentEnabled = false
    local autoplay = false

    -- configurable
    local playInterval = 2                -- seconds between Play attempts
    local accuracyCooldown = 0.5          -- seconds between UpdateAccuracy
    local defaultSong = "La Marseillaise" -- change this or wire a dropdown

    -- state & caches
    local guiCache = { fife = nil, drum = nil, bagpipe = nil }
    local connections = {}
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
        for _, tool in ipairs(char:GetChildren()) do
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
                bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        for _, tool in ipairs(tools) do
            local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Remote")
            if remote then
                pcall(function()
                    _G.SafeFireServer(remote, "UpdateAccuracy", 100)
                end)
                break
            end
        end
    end

    local function firePlay()
        if not autoplay then return end
        local tools = instrumentTools()
        for _, tool in ipairs(tools) do
            local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Remote")
            local soundSource = tool:FindFirstChild("Model")
                and tool.Model:FindFirstChild("Handle")
                and tool.Model.Handle:FindFirstChild("SoundSource")
            if remote and soundSource and not soundSource.IsPlaying then
                pcall(function()
                    _G.SafeFireServer(remote, "Play", currentSong)
                end)
                -- no task.wait here = no lag spike
                break
            end
        end
    end

    -- single heartbeat loop (no spawn/wait spam)
    local function startAutoplayHeartbeat()
        if connections.heartbeat then return end
        local playTimer = 0
        local accuracyTimer = 0
        local tintTimer = 0

        connections.heartbeat = RunService.Heartbeat:Connect(function(dt)
            if not autoplay then return end

            playTimer = playTimer - dt
            accuracyTimer = accuracyTimer - dt
            tintTimer = tintTimer - dt

            if playTimer <= 0 then
                playTimer = playInterval
                firePlay()
            end

            if accuracyTimer <= 0 then
                accuracyTimer = accuracyCooldown
                fireUpdateAccuracy()
            end

            if tintTimer <= 0 then
                tintTimer = 0.5
                tintInstrumentGui(true)
            end
        end)
    end

    local function stopAutoplayHeartbeat()
        safeDisconnect(connections.heartbeat)
        connections.heartbeat = nil
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
    local function setAutoplaySong(songName)
        if type(songName) == "string" and #songName > 0 then
            currentSong = songName
        end
    end

    local function setAutoInstrument(state)
        if state then
            startAutoplay()
        else
            stopAutoplay()
        end
    end

    -- UI: Toggle (starts OFF; user must enable)
    MusicianSection:Toggle({
        Title = "Auto Play Fife/Drum/Bagpipe",
        Flag = "Auto_Play_Fife_Drum_Bagpipe",
        Desc = "Auto play instruments.",
        Icon = "music-2",
        Value = AutoInstrumentEnabled,
        Callback = function(state)
            setAutoInstrument(state)
            WindUI:Notify({
                Title = "Auto Functions",
                Content = state and "Auto instrument ON" or "Auto instrument OFF",
                Duration = 2,
                Icon = state and "music-2" or "x"
            })
        end
    })
end -- end of Musician Section in Classes Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Medic Section in Classes Tab
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local MedicSection = ClassesTab:Section({
        Title = "Medic",
        Icon = "heart",
        Opened = false
    })

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
        if os.clock() - lastReq < HealCooldown then return end
        HealData[player] = os.clock()

        local localChar = LocalPlayer.Character
        if not localChar then return end
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        if not localHRP then return end

        local targetHRP = humanoid.Parent:FindFirstChild("HumanoidRootPart") or humanoid.Parent:FindFirstChild("Torso")
        if not targetHRP then return end

        if (localHRP.Position - targetHRP.Position).Magnitude > HealRange then return end

        local medSupplies = localChar:FindFirstChild("Medical Supplies")
        if not medSupplies then return end
        local remote = medSupplies:FindFirstChild("RemoteEvent")
        if not remote then return end

        pcall(function()
            _G.SafeFireServer(remote, "SendRequest", humanoid)
            local lastNotify = HealNotify[player] or 0
            if os.clock() - lastNotify >= HealCooldown then
                HealNotify[player] = os.clock()
                WindUI:Notify({
                    Title = "Auto Heal",
                    Content = "Requested heal for " .. player.Name,
                    Duration = 2,
                    Icon = "heart",
                })
            end
        end)
    end

    task.defer(function()
        task.wait(1.5) -- Stagger start
        while task.wait(0.35) do 
            if AutoRequestHealEnabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
                        if humanoid and humanoid.Health <= humanoid.MaxHealth * (HealThreshold / 100) then
                            pcall(function() RequestHeal(player, humanoid) end)
                        end
                    end
                end
            end
        end
    end)

    MedicSection:Toggle({
        Title = "Auto Request Heal Dying Players",
        Flag = "Auto_Request_Heal_Dying_Players",
        Desc = "Auto request heal for low HP players nearby.",
        Default = false,
        Callback = function(state)
            AutoRequestHealEnabled = state
            WindUI:Notify({
                Title = "Auto Heal",
                Content = state and "Auto Request Heal Enabled" or "Auto Request Heal Disabled",
                Duration = 2,
                Icon = state and "heart" or "x",
            })
        end
    })

    MedicSection:Slider({
        Title = "Heal Threshold (%)",
        Flag = "Auto_Heal",
        Desc = "HP % threshold for auto heal.",
        Step = 1,
        Value = {Min = 1, Max = 100, Default = HealThreshold},
        Callback = function(val)
            HealThreshold = val
        end
    })

    -- Auto Pick Up Supplies feature
    local AutoPickUpSuppliesEnabled = false
    
    local function IsMeterFull()
        -- Simple and direct approach: find the meter in workspace.Players.[PlayerName]
        local wsPlayers = Workspace:FindFirstChild("Players")
        if not wsPlayers then return false end -- Can't find players folder, try to pick up
        
        local playerFolder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        if not playerFolder then return false end -- Can't find our folder, try to pick up
        
        local meter = playerFolder:FindFirstChild("Meter")
        if not meter then return false end -- No meter found, try to pick up
        
        -- Get current value
        local currentValue = nil
        local ok1, _ = pcall(function()
            currentValue = meter.Value
        end)
        if not ok1 or currentValue == nil then return false end
        
        -- Get max value - try multiple ways
        local maxValue = nil
        
        -- Try 1: Attribute "Max" on meter
        pcall(function()
            maxValue = meter:GetAttribute("Max")
        end)
        
        -- Try 2: Attribute "Max" on player folder
        if maxValue == nil then
            pcall(function()
                maxValue = playerFolder:GetAttribute("Max")
            end)
        end
        
        -- Try 3: Look for MaxMeter or Max value in player folder
        if maxValue == nil then
            local maxMeter = playerFolder:FindFirstChild("MaxMeter") or playerFolder:FindFirstChild("Max")
            if maxMeter and maxMeter:IsA("ValueBase") then
                pcall(function()
                    maxValue = maxMeter.Value
                end)
            end
        end
        
        -- Try 4: Common max values for medic supplies (fallback)
        if maxValue == nil then
            -- If we can't find max, assume a common max of 6 for medic supplies
            -- This way if current < 6, we'll still try to pick up
            maxValue = 6
        end
        
        -- Safety check
        if maxValue == nil or maxValue <= 0 then return false end
        
        -- Return true ONLY if current >= max (meter is full)
        return currentValue >= maxValue
    end
    
    -- Cache for supply prompts to avoid searching all descendants every frame
    local cachedSupplyPrompts = {}
    local lastPromptCacheTime = 0
    local PROMPT_CACHE_DURATION = 2 -- Refresh cache every 2 seconds
    
    local function RefreshPromptCache()
        local now = os.clock()
        if now - lastPromptCacheTime < PROMPT_CACHE_DURATION then return end
        lastPromptCacheTime = now
        
        cachedSupplyPrompts = {}
        -- Search common locations for supply prompts
        local searchLocations = {
            Workspace:FindFirstChild("Supplies"),
            Workspace:FindFirstChild("SupplyBoxes"),
            Workspace:FindFirstChild("Interactables"),
            Workspace:FindFirstChild("Map"),
        }
        
        -- Add workspace itself as fallback but limit search
        local function searchIn(container)
            if not container then return end
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local name = obj.Name:lower()
                    if name:find("replenish") or name:find("supply") or obj.Name == "ReplenishPrompt" then
                        table.insert(cachedSupplyPrompts, obj)
                    end
                end
            end
        end
        
        for _, loc in ipairs(searchLocations) do
            searchIn(loc)
        end
        
        -- If no prompts found in common locations, do a limited workspace search
        if #cachedSupplyPrompts == 0 then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local name = obj.Name:lower()
                    if name:find("replenish") or name:find("supply") or obj.Name == "ReplenishPrompt" then
                        table.insert(cachedSupplyPrompts, obj)
                    end
                end
            end
        end
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
        
        for _, prompt in ipairs(cachedSupplyPrompts) do
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
    
    task.defer(function()
        task.wait(2) -- Stagger start
        while true do
            if AutoPickUpSuppliesEnabled then
                -- Always try to pick up - the game will naturally stop us if full
                -- The fireproximityprompt will fail silently if we can't pick up more
                FireReplenishPrompt()
                task.wait(0.25) -- Active: check every 0.25s
            else
                task.wait(2) -- PERFORMANCE: Sleep longer when disabled
            end
        end
    end)
    
    MedicSection:Toggle({
        Title = "Auto Pick Up Supplies",
        Flag = "Auto_Pick_Up_Supplies",
        Desc = "Auto pick up supplies.",
        Default = false,
        Callback = function(state)
            AutoPickUpSuppliesEnabled = state
            WindUI:Notify({
                Title = "Auto Pick Up Supplies",
                Content = state and "Auto Pickup Supplies Enabled" or "Auto Pickup Supplies Disabled",
                Duration = 2,
                Icon = state and "package" or "x",
            })
        end
    })
end -- end of Medic Section in Classes Tab

task.wait(0.1) -- Delay to prevent lag

-- Define SapperSection at outer scope so it's accessible to Anti-Grab section
local SapperSection = ClassesTab:Section({
    Title = "Sapper",
    Icon = "hammer",
    Opened = false
})

do -- // Sapper Section in Classes Tab
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    
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
        local now = os.clock()
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
        local now = os.clock()
        if cachedBuildableFolders and (now - cachedBuildableFoldersTime) < FOLDER_CACHE_TTL then
            return cachedBuildableFolders
        end
        
        local folders = {}
        local folderNames = {"Buildables", "Stakes", "Barricades", "Structures", "Buildings"}
        for _, name in ipairs(folderNames) do
            local folder = Workspace:FindFirstChild(name)
            if folder then folders[#folders + 1] = folder end
        end
        
        -- Check map-specific folders (Berezina, etc.) - only Modes sub-folders
        for _, mapFolder in ipairs(Workspace:GetChildren()) do
            if mapFolder:IsA("Folder") or mapFolder:IsA("Model") then
                local modes = mapFolder:FindFirstChild("Modes")
                if modes then folders[#folders + 1] = modes end
            end
        end
        
        cachedBuildableFolders = folders
        cachedBuildableFoldersTime = now
        return folders
    end
    
    -- OPTIMIZED: Inline health check to avoid function call overhead per instance
    -- Uses GetChildren on first level, then checks health values directly
    local function getNearbyBuildables()
        local char = LocalPlayer.Character
        if not char then return {} end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return {} end
        local rootPos = root.Position
        local rangeSq = AutoRepairRange * AutoRepairRange
        
        local buildables = {}
        local buildCount = 0
        local seen = {} -- Dedup by health object
        local MAX_REPAIRS_PER_CYCLE = 10 -- Cap repairs per cycle to avoid remote spam
        
        local folders = getBuildableFolders()
        
        for _, folder in ipairs(folders) do
            -- OPTIMIZED: Use GetChildren (1 level) instead of GetDescendants (recursive)
            -- Most buildable structures are direct children of these folders
            for _, inst in ipairs(folder:GetChildren()) do
                if buildCount >= MAX_REPAIRS_PER_CYCLE then break end
                
                -- Get position for distance check first (early exit if too far)
                local pos = nil
                if inst:IsA("BasePart") then
                    pos = inst.Position
                elseif inst:IsA("Model") then
                    local primary = inst.PrimaryPart
                    if not primary then primary = inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart") end
                    if primary then pos = primary.Position end
                end
                
                if pos then
                    local dx, dy, dz = pos.X - rootPos.X, pos.Y - rootPos.Y, pos.Z - rootPos.Z
                    local distSq = dx*dx + dy*dy + dz*dz
                    if distSq <= rangeSq then
                        -- Check health types in priority order
                        local healthObj = inst:FindFirstChild("BuildingHealth") 
                            or inst:FindFirstChild("ConstructHealth")
                        if not healthObj then
                            local h = inst:FindFirstChild("Health")
                            if h and h:IsA("NumberValue") then healthObj = h end
                        end
                        
                        if healthObj and not seen[healthObj] then
                            -- Quick repair check without pcall for speed
                            local needsRepair = true
                            local ok, _ = pcall(function()
                                local cur = healthObj.Value
                                local mx = healthObj:GetAttribute("MaxHealth") or healthObj:GetAttribute("Max") or 100
                                needsRepair = cur < mx
                            end)
                            if (not ok) or needsRepair then
                                seen[healthObj] = true
                                buildCount = buildCount + 1
                                buildables[buildCount] = healthObj
                            end
                        end
                    end
                end
                
                -- OPTIMIZED: Also check direct children of models (1 level deeper)
                if inst:IsA("Model") or inst:IsA("Folder") then
                    for _, sub in ipairs(inst:GetChildren()) do
                        if buildCount >= MAX_REPAIRS_PER_CYCLE then break end
                        
                        local subPos = nil
                        if sub:IsA("BasePart") then
                            subPos = sub.Position
                        elseif sub:IsA("Model") then
                            local p = sub.PrimaryPart or sub:FindFirstChildWhichIsA("BasePart")
                            if p then subPos = p.Position end
                        end
                        
                        if subPos then
                            local dx2, dy2, dz2 = subPos.X - rootPos.X, subPos.Y - rootPos.Y, subPos.Z - rootPos.Z
                            local distSq2 = dx2*dx2 + dy2*dy2 + dz2*dz2
                            if distSq2 <= rangeSq then
                                local healthObj2 = sub:FindFirstChild("BuildingHealth")
                                    or sub:FindFirstChild("ConstructHealth")
                                if not healthObj2 then
                                    local h2 = sub:FindFirstChild("Health")
                                    if h2 and h2:IsA("NumberValue") then healthObj2 = h2 end
                                end
                                
                                if healthObj2 and not seen[healthObj2] then
                                    local needsRepair2 = true
                                    local ok2, _ = pcall(function()
                                        local cur2 = healthObj2.Value
                                        local mx2 = healthObj2:GetAttribute("MaxHealth") or healthObj2:GetAttribute("Max") or 100
                                        needsRepair2 = cur2 < mx2
                                    end)
                                    if (not ok2) or needsRepair2 then
                                        seen[healthObj2] = true
                                        buildCount = buildCount + 1
                                        buildables[buildCount] = healthObj2
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if buildCount >= MAX_REPAIRS_PER_CYCLE then break end
        end
        
        return buildables
    end
    
    -- Build a rich list of nearby buildables with health data attached
    local function getRichBuildables()
        local char = LocalPlayer.Character
        if not char then return {} end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return {} end
        local rootPos = root.Position
        local rangeSq = AutoRepairRange * AutoRepairRange

        local results = {}
        local seen = {}

        local folders = getBuildableFolders()

        local function tryAdd(inst)
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
            if not healthObj or seen[healthObj] then return end
            seen[healthObj] = true

            local cur, max
            pcall(function()
                cur = healthObj.Value
                max = healthObj:GetAttribute("MaxHealth") or healthObj:GetAttribute("Max") or 100
            end)
            if not cur or not max or max == 0 then return end
            if cur >= max then return end -- fully repaired, skip

            results[#results + 1] = {
                obj = healthObj,
                cur = cur,
                max = max,
                ratio = cur / max,
                dist = math.sqrt(distSq)
            }
        end

        for _, folder in ipairs(folders) do
            for _, inst in ipairs(folder:GetChildren()) do
                tryAdd(inst)
                if inst:IsA("Model") or inst:IsA("Folder") then
                    for _, sub in ipairs(inst:GetChildren()) do
                        tryAdd(sub)
                    end
                end
            end
        end

        return results
    end

    -- Main repair function - single target based on mode
    local function doAutoRepair()
        if AutoRepairTargetMode == "None" then return end

        local hammerRemote = getHammerRemote()
        if not hammerRemote then return end

        local list = getRichBuildables()
        if #list == 0 then return end

        local target = nil

        if AutoRepairTargetMode == "Closest" then
            table.sort(list, function(a, b) return a.dist < b.dist end)
            target = list[1].obj

        elseif AutoRepairTargetMode == "LowestHealth" then
            table.sort(list, function(a, b)
                -- Sort by ratio first (lowest % HP), break ties by raw HP
                if a.ratio ~= b.ratio then return a.ratio < b.ratio end
                return a.cur < b.cur
            end)
            target = list[1].obj
        end

        if target then
            pcall(function()
                _G.SafeFireServer(hammerRemote, "Repair", target)
            end)
        end
    end
    
    local autoRepairTicker = 0
    
    SapperSection:Toggle({
        Title = "Auto Repair",
        Flag = "Auto_Repair",
        Desc = "Auto repair buildings.",
        Default = false,
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
                WindUI:Notify({
                    Title = "Auto Repair",
                    Content = "Auto Repair enabled",
                    Duration = 2,
                    Icon = "wrench",
                })
            else
                if AutoRepairConn then
                    AutoRepairConn:Disconnect()
                    AutoRepairConn = nil
                end
                WindUI:Notify({
                    Title = "Auto Repair",
                    Content = "Auto Repair disabled",
                    Duration = 2,
                    Icon = "x",
                })
            end
        end
    })

    SapperSection:Dropdown({
        Title = "Repair Target Mode",
        Flag = "Repair_Target_Mode",
        Desc = "Select a target.",
        Values = { "Closest Structure", "Lowest Health Structure" },
        Default = nil,
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
end -- end of Sapper Section in Classes Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Anti-Grab & Shove Aura Section in Classes Tab
-- Anti Grab (Sapper) + Improved Shove Aura (RETRY EQUIP UNTIL FREED)
-- Maintains earlier behavior but will keep equipping weapon/tool while pinned/grabbed.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace

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

-- Shove Hitbox Expander (detects shove animation and fires at extended range)
-- Using global variables so UI can access them
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
    if not toolName or not LocalPlayer then return nil end
    local char = LocalPlayer.Character
    if char then
        local t = char:FindFirstChild(toolName)
        if t and t:IsA("Tool") then return t end
    end
    local bp = GetBackpack()
    if bp then
        local t = bp:FindFirstChild(toolName)
        if t and t:IsA("Tool") then return t end
    end
    local wsPlayers = Workspace:FindFirstChild("Players")
    if wsPlayers then
        local folder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        if folder then
            local t = folder:FindFirstChild(toolName)
            if t and t:IsA("Tool") then return t end
        end
    end
    return nil
end

local function TryEquipToolInstance(tool)
    if not tool or not LocalPlayer then return false end
    if LocalPlayer.Character and tool.Parent == LocalPlayer.Character then return true end

    -- try humanoid:EquipTool
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local ok = pcall(function() humanoid:EquipTool(tool) end)
            if ok then
                for i=1,8 do
                    if tool.Parent == LocalPlayer.Character then return true end
                    safeWait(0.05)
                end
            end
        end
    end

    -- fallback parent
    if LocalPlayer.Character then
        local ok2 = pcall(function() tool.Parent = LocalPlayer.Character end)
        if ok2 then
            for i=1,8 do
                if tool.Parent == LocalPlayer.Character then return true end
                    safeWait(0.05)
            end
        end
    end

    -- Player:EquipTool if exists
    if LocalPlayer and LocalPlayer.EquipTool then
        local ok3 = pcall(function() LocalPlayer:EquipTool(tool) end)
        if ok3 then
            for i=1,8 do
                if tool.Parent == LocalPlayer.Character then return true end
                safeWait(0.05)
            end
        end
    end

    return false
end

local function TryEquipFromBackpack(timeout)
    timeout = tonumber(timeout) or 0.8
    local start = os.clock()
    while os.clock() - start < timeout do
        for _, name in ipairs(ToolNamesPriority) do
            local candidate = FindToolInstanceByName(name)
            if candidate and candidate:IsA("Tool") then
                if LocalPlayer.Character and candidate.Parent == LocalPlayer.Character then
                    return name
                end
                local ok = TryEquipToolInstance(candidate)
                if ok then
                    safeWait(0.06)
                    return name
                end
            end
        end
        safeWait(0.06)
    end
    return nil
end

local function GetToolRemoteByName(toolName)
    if not toolName then return nil end
    local char = LocalPlayer.Character
    local bp = GetBackpack()
    local tool = (char and char:FindFirstChild(toolName)) or (bp and bp:FindFirstChild(toolName))
    if tool and tool:FindFirstChild("RemoteEvent") then return tool.RemoteEvent end
    local wsPlayers = Workspace:FindFirstChild("Players")
    if wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name) then
        local folder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        local toolFolder = folder:FindFirstChild(toolName)
        if toolFolder and toolFolder:FindFirstChild("RemoteEvent") then return toolFolder.RemoteEvent end
    end
    return nil
end

-- PERFORMANCE FIX: Pre-allocated buffers to avoid GC pressure from table churn
local _targetZombiesBuf = {}
local _targetZombiesBufLen = 0

local function CollectZombiesForTargeting()
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then return _targetZombiesBuf, 0 end
    _targetZombiesBufLen = 0
    local function collect(folder)
        if not folder then return end
        for _, z in ipairs(folder:GetChildren()) do
            if z and z:IsA("Model") then
                _targetZombiesBufLen = _targetZombiesBufLen + 1
                _targetZombiesBuf[_targetZombiesBufLen] = z
            end
        end
    end
    local agent = zombiesFolder:FindFirstChild("Agent")
    local slim = zombiesFolder:FindFirstChild("Slim")
    collect(agent)
    collect(slim)
    if _targetZombiesBufLen == 0 then
        collect(zombiesFolder)
    end
    return _targetZombiesBuf, _targetZombiesBufLen
end

local function FindNearestAgentParts(pos, maxRange, n)
    if not pos then return {} end
    n = n or 1
    local list = {}
    local buf, bufLen = CollectZombiesForTargeting()
    for i = 1, bufLen do
        local z = buf[i]
        local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
        if part then
            local ok, d = pcall(function() return (part.Position - pos).Magnitude end)
            if ok and d and d <= (maxRange or math.huge) then
                table.insert(list, {part = part, dist = d, model = z})
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    local out = {}
    for i=1, math.min(n, #list) do
        table.insert(out, list[i].part)
    end
    return out
end

local function GetZombiesInComboRange(originPos, radius, maxTargets)
    if not originPos then return {} end
    radius = radius or ComboStunRange
    maxTargets = maxTargets or ComboStunMaxTargets
    local buf, bufLen = CollectZombiesForTargeting()
    local list = {}
    for i = 1, bufLen do
        local z = buf[i]
        local hrp = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
        if hrp then
            local d = (hrp.Position - originPos).Magnitude
            if d <= radius then
                table.insert(list, {model = z, part = hrp, dist = d})
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    local out = {}
    for i=1, math.min(maxTargets, #list) do
        table.insert(out, list[i])
    end
    return out
end

local function PerformGunStunCombo(remote, originPos)
    if not remote or not originPos then return end
    local targets = GetZombiesInComboRange(originPos, ComboStunRange, ComboStunMaxTargets)
    for i, entry in ipairs(targets) do
        if entry.model and entry.part then
            pcall(function() _G.SafeFireServer(remote, "FeedbackStun", entry.model, entry.part.Position) end)
            if i < #targets then safeWait(ComboStunDelay) end
        end
    end
end


-- Shove Aura: unchanged aside from using the same robust remote lookup and gun/melee behavior
local function RemoteFromToolInstance(tool)
    if not tool then return nil end
    if tool:FindFirstChild("RemoteEvent") then return tool.RemoteEvent end
    local wsPlayers = Workspace:FindFirstChild("Players")
    if wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name) then
        local folder = wsPlayers:FindFirstChild(LocalPlayer.Name)
        local t = folder:FindFirstChild(tool.Name)
        if t and t:FindFirstChild("RemoteEvent") then return t.RemoteEvent end
    end
    return nil
end

local function GetBestToolRemoteAndName()
    if ShovePreferEquipped and LocalPlayer.Character then
        local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if equipped then
            local r = RemoteFromToolInstance(equipped)
            if r then return r, equipped.Name end
        end
    end

    for _, name in ipairs(ToolNamesPriority) do
        local charTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name)
        if charTool then
            local r = RemoteFromToolInstance(charTool)
            if r then return r, name end
        end
        local back = GetBackpack()
        if back then
            local btool = back:FindFirstChild(name)
            if btool then
                local r = RemoteFromToolInstance(btool)
                if r then return r, name end
            end
        end
        local wsPlayers = Workspace:FindFirstChild("Players")
        if wsPlayers and wsPlayers:FindFirstChild(LocalPlayer.Name) then
            local folder = wsPlayers:FindFirstChild(LocalPlayer.Name)
            local ftool = folder:FindFirstChild(name)
            if ftool and ftool:FindFirstChild("RemoteEvent") then return ftool.RemoteEvent, name end
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
        pcall(function() _G.SafeFireServer(remote, "Shove") end)
        if hrp then PerformGunStunCombo(remote, hrp.Position) end
    else
        if not agentPart then return end
        pcall(function() _G.SafeFireServer(remote, "FeedbackStun", agentPart.Parent, agentPart.Position) end)
        pcall(function() _G.SafeFireServer(remote, "StopBraceBlock") end)
    end
end

-- ===== SHARED COORDINATION SYSTEM FOR KILL AURA + SHOVE AURA =====
-- Prevents both systems from fighting over tool equipping
-- Uses a shared state to coordinate their actions

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

-- Get remote with caching - NO EQUIPPING (use whatever is currently available)
-- When both auras are enabled, we don't fight over tools - we use what's equipped
local function ShoveAura_getRemote()
    local now = os.clock()
    
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

task.defer(function()
    task.wait(3.5) -- Stagger start
    while true do
        if ShoveAuraEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- COORDINATION: Check if Kill Aura just fired (avoid overlapping)
                local coord = _G.AuraCoordination
                local now = os.clock()
                local timeSinceKillAura = now - (coord.killAuraLastFire or 0)
                
                -- If Kill Aura fired very recently, add tiny offset to stagger attacks
                if KillAuraEnabled and timeSinceKillAura < 0.03 then
                    task.wait(0.02) -- Small stagger to prevent overlap
                end
                
                -- Use cached remote lookup (fast, non-blocking)
                local remote, rname = ShoveAura_getRemote()
                
                if remote then
                    local targets = FindNearestAgentParts(hrp.Position, ShoveAuraRange, ShoveTargets)
                    if #targets > 0 then
                        -- Mark when Shove Aura fires
                        coord.shoveAuraLastFire = os.clock()
                        
                        -- Fire shoves directly (no spawn needed - already non-blocking)
                        for _, part in ipairs(targets) do
                            FireShove(remote, part, rname)
                        end
                    end
                end
            end
            
            -- COORDINATION: Adaptive cooldown based on Kill Aura state
            if KillAuraEnabled then
                -- When Kill Aura is also active, use slightly longer cooldown to share time
                task.wait(math.max(ShoveAuraCooldown, 0.08))
            else
                -- Solo Shove Aura - use configured cooldown
                task.wait(ShoveAuraCooldown)
            end
        else
            -- Clear cache when disabled
            ShoveAura_cachedRemote = nil
            ShoveAura_cachedRemoteName = nil
            task.wait(1) -- PERFORMANCE: Sleep longer when disabled
        end
    end
end)

-- ===== SHOVE HITBOX EXPANDER - ANIMATION DETECTION =====
-- Detects when player performs a shove animation and fires shoves at extended range
-- Works exactly like Shove Aura but only triggers when you do a shove animation

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
    for i, part in ipairs(targets) do
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

local AttachShoveHitboxWatcher = _G.AttachShoveHitboxWatcher

-- Attach on character spawn (only if feature is enabled)
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.2)
    if ShoveHitboxExpanderEnabled then
        AttachShoveHitboxWatcher()
    end
end)

-- Initial attach if character already loaded (only if feature is enabled)
task.spawn(function()
    task.wait(0.5)
    if ShoveHitboxExpanderEnabled then
        AttachShoveHitboxWatcher()
    end
end)

-- Auto Parry Zapper: spam BraceBlock when a zapper is close (uses ESP detection)
local function FindNearestZapper(pos, maxRange)
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder or not pos then return nil end
    local nearest = nil
    local nearestDist = math.huge
    for _, z in ipairs(zombiesFolder:GetChildren()) do
        if z and z:IsA("Model") and isZombieOfType and isZombieOfType(z, "Zapper") then
            local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - pos).Magnitude
                if d <= (maxRange or math.huge) and d < nearestDist then
                    nearestDist = d
                    nearest = part
                end
            end
        end
    end
    return nearest, nearestDist
end

task.defer(function()
    task.wait(4) -- Stagger start
    while true do
        if AutoParrySapperEnabled then
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
                        pcall(function() _G.SafeFireServer(remote, "BraceBlock") end)
                    end
                end
            end
            task.wait(0.08) -- Active: fast parry response
        else
            task.wait(1) -- PERFORMANCE: Sleep longer when disabled
        end
    end
end)

-- Auto Parry Sapper (Melee only - Axe/Pickaxe): spam BraceBlock when any zombie is within 8 studs
local function FindNearestZombieForParry(pos, maxRange)
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder or not pos then return nil end
    local nearest = nil
    local nearestDist = math.huge
    
    -- Check in Agent folder (regular zombies)
    local agentFolder = zombiesFolder:FindFirstChild("Agent")
    if agentFolder then
        for _, z in ipairs(agentFolder:GetChildren()) do
            if z and z:IsA("Model") then
                local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
                if part then
                    local d = (part.Position - pos).Magnitude
                    if d <= (maxRange or math.huge) and d < nearestDist then
                        nearestDist = d
                        nearest = part
                    end
                end
            end
        end
    end
    
    -- Also check Slim folder (Cuirassiers)
    local slimFolder = zombiesFolder:FindFirstChild("Slim")
    if slimFolder then
        for _, z in ipairs(slimFolder:GetChildren()) do
            if z and z:IsA("Model") then
                local part = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChildWhichIsA("BasePart")
                if part then
                    local d = (part.Position - pos).Magnitude
                    if d <= (maxRange or math.huge) and d < nearestDist then
                        nearestDist = d
                        nearest = part
                    end
                end
            end
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

task.defer(function()
    task.wait(4.5) -- Stagger start
    while true do
        if AutoParrySapperMeleeEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hasMelee, meleeName = HasMeleeEquipped()
                if hasMelee then
                    local zombiePart, dist = FindNearestZombieForParry(hrp.Position, 8)
                    if zombiePart and dist and dist <= 8 then
                        local remote = GetMeleeRemote()
                        if remote then
                            pcall(function() _G.SafeFireServer(remote, "BraceBlock") end)
                        end
                    end
                end
            end
            task.wait(0.08) -- Active: fast parry response
        else
            task.wait(1) -- PERFORMANCE: Sleep longer when disabled
        end
    end
end)

_G.LanderToggleElements = _G.LanderToggleElements or {}

local ShoveAuraToggle = SapperSection:Toggle({
    Title = "Shove Aura",
    Flag = "Shove_Aura",
    Desc = "Auto shove nearby zombies.",
    Default = ShoveAuraEnabled,
    Callback = function(v)
        ShoveAuraEnabled = v
        pcall(function()
            if WindUI and WindUI.Notify then
                WindUI:Notify({
                    Title = "Shove Aura",
                    Content = (v and ("Enabled — range: "..tostring(ShoveAuraRange)) ) or "Disabled",
                    Duration = 2,
                    Icon = v and "zap" or "x",
                })
            end
        end)
    end
})
_G.LanderToggleElements.ShoveAura = ShoveAuraToggle

SapperSection:Slider({
    Title = "Shove Range",
    Flag = "Shove_Range",
    Desc = "Shove Aura range.",
    Step = 1,
    Value = {
        Min = 1,
        Max = 30,
        Default = ShoveAuraRange,
    },
    Callback = function(val)
        ShoveAuraRange = math.max(1, math.floor(tonumber(val) or 1))
        pcall(function()
            if WindUI and WindUI.Notify then
                WindUI:Notify({ Title = "Shove Range", Content = tostring(ShoveAuraRange).." studs", Duration = 1 })
            end
        end)
    end
})

SapperSection:Slider({
    Title = "Shove Targets",
    Flag = "Shove_Range_1",
    Desc = "Zombies per shove.",
    Step = 1,
    Value = {
        Min = 1,
        Max = 5,
        Default = ShoveTargets,
    },
    Callback = function(val)
        ShoveTargets = math.max(1, math.floor(tonumber(val) or 1))
    end
})

SapperSection:Slider({
    Title = "Shove Delay",
    Flag = "Shove_Delay",
    Desc = "Shove speed.",
    Step = 0.01,
    Value = {
        Min = 0.02,
        Max = 0.5,
        Default = ShoveAuraCooldown,
    },
    Callback = function(val)
        ShoveAuraCooldown = math.clamp(tonumber(val) or 0.1, 0.02, 0.5)
    end
})
end -- end of Anti-Grab & Shove Aura Section in Classes Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Chaplain Section in Classes Tab
-- ======= Chaplain Section (only acts when Blessing tool is equipped; silent on failures) =======
local ChaplainSection = ClassesTab:Section({
    Title = "Chaplain",
    Icon = "pray",
    Opened = false
})

local PlayersSvc = game:GetService("Players")
local LocalPlayer = PlayersSvc.LocalPlayer

local AutoBlessEnabled = false
local AutoMercyEnabled = false
local BlessThreshold = 50         -- numeric threshold
local BlessCooldown = 2           -- seconds between blessings to same player
local MercyCooldown = 2           -- seconds between mercy to same player
local BlessRange = 15             -- proximity requirement (studs)
local MercyRange = 15             -- proximity requirement for mercy (studs)
-- Use weak keys so data for players who left is garbage collected
local BlessData = setmetatable({}, { __mode = "k" })  -- per-player cooldown storage (keyed by UserId -> Player)
local MercyData = setmetatable({}, { __mode = "k" })  -- per-player cooldown storage for mercy

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
    for _, child in ipairs(localChar:GetChildren()) do
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
    for _, child in ipairs(localChar:GetChildren()) do
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
        _G.SafeFireServer(remote, "SendRequest", humanoid)
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
        _G.SafeFireServer(remote, "SendRequest", humanoid)
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

-- Main scan loop (silent on failures; only notifies on successful bless)
task.defer(function()
    task.wait(5) -- Stagger start
    while task.wait(0.35) do
        if AutoBlessEnabled then
            for _, player in ipairs(PlayersSvc:GetPlayers()) do
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
                            if os.clock() - last >= (tonumber(BlessCooldown) or 0) then
                                local success = false
                                pcall(function()
                                    success = FireBlessByPlayer_Silent(player)
                                end)
                                if success then
                                    BlessData[uid] = os.clock()
                                    WindUI:Notify({
                                        Title = "Auto Bless",
                                        Content = "Sent bless to " .. player.Name,
                                        Duration = 2,
                                        Icon = "pray"
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Mercy loop (only for players with 100% infection)
task.defer(function()
    task.wait(5) -- Stagger start
    while task.wait(0.35) do
        if AutoMercyEnabled then
            for _, player in ipairs(PlayersSvc:GetPlayers()) do
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
                            if os.clock() - last >= (tonumber(MercyCooldown) or 0) then
                                local success = false
                                pcall(function()
                                    success = FireMercyByPlayer_Silent(player)
                                end)
                                if success then
                                    MercyData[uid] = os.clock()
                                    WindUI:Notify({
                                        Title = "Auto Mercy",
                                        Content = "Sent mercy to " .. player.Name,
                                        Duration = 2,
                                        Icon = "heart"
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- UI Controls
ChaplainSection:Toggle({
    Title = "Auto Bless Infected Players",
    Flag = "Auto_Bless_Infected_Players",
    Desc = "Auto bless infected players.",
    Default = false,
    Callback = function(state)
        AutoBlessEnabled = state
        WindUI:Notify({
            Title = "Chaplain",
            Content = state and "Auto Bless Enabled" or "Auto Bless Disabled",
            Duration = 2,
            Icon = state and "pray" or "x"
        })
    end
})

ChaplainSection:Toggle({
    Title = "Auto Mercy Fully Infected",
    Flag = "Chaplain",
    Desc = "Auto mercy players at 100% infection.",
    Default = false,
    Callback = function(state)
        AutoMercyEnabled = state
        WindUI:Notify({
            Title = "Chaplain",
            Content = state and "Auto Mercy Enabled" or "Auto Mercy Disabled",
            Duration = 2,
            Icon = state and "heart" or "x"
        })
    end
})

ChaplainSection:Slider({
    Title = "Infected Threshold",
    Flag = "Chaplain_1",
    Desc = "Infection % to trigger bless (skips 100%).",
    Step = 1,
    Value = {Min = 0, Max = 99, Default = BlessThreshold},
    Callback = function(val)
        BlessThreshold = tonumber(val) or 0
    end
})
-- ======= END Chaplain Section =======
end -- end of Chaplain Section in Classes Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Dracula (New) — auto melee remote scanner + robust ESP (Dracula + Silver)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer

    -- ===== SETTINGS (defaults) =====
    local DEBUG = false
    local DraculaLoopInterval = 0.1

    HitDraculaEnabled   = HitDraculaEnabled or false
    DraculaSpamCount    = DraculaSpamCount or 5
    DraculaRange        = DraculaRange or 15
    DraculaHitSpacing   = DraculaHitSpacing or 0.01  -- default as requested
    DraculaEspEnabled   = DraculaEspEnabled or false
    SilverEspEnabled    = SilverEspEnabled or false

    -- ===== INTERNALS =====
    -- Use weak keys so destroyed remotes get garbage collected
    local draculaRemotes = setmetatable({}, { __mode = "k" })  -- [RemoteEvent] = true
    local lastDraculaRemoteScan = 0

    local draculaHighlight = nil
    -- Use weak keys so destroyed models get garbage collected
    local silverVisuals = setmetatable({}, { __mode = "k" })  -- [Model] = {Highlight = hl, Billboard = bb, Text = txt}

    local ESP_HIGHLIGHT_SUPPORTED = true
    local ESP_GUI_PARENT = CoreGui    -- will fallback to PlayerGui if CoreGui blocked

    -- ===== HELPERS =====
    local function safePcall(fn, ...)
        local ok, a, b, c = pcall(fn, ...)
        return ok, a, b, c
    end

    local function getDracula()
        local trans = Workspace:FindFirstChild("Transylvania")
        if not trans then return nil end
        local modes = trans:FindFirstChild("Modes")
        if not modes then return nil end
        local boss = modes:FindFirstChild("Boss")
        if not boss then return nil end
        return boss:FindFirstChild("Dracula")
    end

    local function getSilverFolder()
        local trans = Workspace:FindFirstChild("Transylvania")
        if not trans then return nil end
        local modes = trans:FindFirstChild("Modes")
        if not modes then return nil end
        local boss = modes:FindFirstChild("Boss")
        if not boss then return nil end
        return boss:FindFirstChild("SilverTrinkets")
    end

    -- Try to determine a usable GUI parent for ESP (CoreGui preferred, fallback to PlayerGui)
    do
        local ok = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = CoreGui
            test:Destroy()
        end)
        if not ok then
            -- fallback to PlayerGui if possible
            local playerGui = (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
            if playerGui then
                ESP_GUI_PARENT = playerGui
            else
                -- attempt to wait for PlayerGui (if allowed)
                local s, r = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 2) end)
                if s and r then ESP_GUI_PARENT = r else ESP_HIGHLIGHT_SUPPORTED = false end
        end
        end
    end

    -- ===== Remote scanning (auto, continuous) =====
    local function ScanDraculaRemotes()
        table.clear(draculaRemotes)
        local char = LocalPlayer and LocalPlayer.Character
        if not char then return end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then
                for _, ch in ipairs(obj:GetChildren()) do
                    if ch and ch:IsA("RemoteEvent") then
                        draculaRemotes[ch] = true
                    end
                end
            end
        end
        lastDraculaRemoteScan = os.clock()
        if DEBUG then
            local c = 0
            for _ in pairs(draculaRemotes) do c = c + 1 end
            print("[Dracula] remotes scanned:", c)
        end
    end

    -- Debounce remote scanning to prevent lag when spamming equip/unequip
    local Dracula_scanDebounce = false
    local function Dracula_DebouncedScan()
        if Dracula_scanDebounce then return end
        Dracula_scanDebounce = true
        task.delay(0.15, function()
            Dracula_scanDebounce = false
            ScanDraculaRemotes()
        end)
    end
    
    -- initial scan + hooks
    if LocalPlayer.Character then ScanDraculaRemotes() end
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        ScanDraculaRemotes()
        char.ChildAdded:Connect(function(c)
            if c and c:IsA("Tool") then Dracula_DebouncedScan() end
        end)
        char.ChildRemoved:Connect(function(c)
            if c and c:IsA("Tool") then Dracula_DebouncedScan() end
        end)
    end)

    -- background auto-scan (always on, deferred)
    task.defer(function()
        task.wait(5.5) -- Stagger start
        while true do
            -- PERFORMANCE: Only scan when Dracula features are enabled
            if HitDraculaEnabled or DraculaEspEnabled then
                ScanDraculaRemotes()
                task.wait(2) -- Active: scan every 2s
            else
                task.wait(5) -- PERFORMANCE: Sleep longer when disabled
            end
        end
    end)

    -- ===== Remote action helpers =====
    local function fireSwingRemote(remote)
        if not (remote and remote:IsA("RemoteEvent")) then return end
        pcall(function() _G.SafeFireServer(remote, "Swing", "Side") end)
    end

    local function fireHitAtDracula(remote, dracModel)
        if not (remote and dracModel) then return end
        local ok, pivot = pcall(function() return dracModel:GetPivot().Position end)
        if not ok or not pivot then return end

        local offset = Vector3.new(
            (math.random() - 0.5) * 6,
            (math.random() - 0.5) * 4,
            (math.random() - 0.5) * 6
        )
        local hitPos = pivot + offset

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hrpPos = (hrp and hrp.Position) or pivot
        local delta = hitPos - hrpPos
        local ok2, dir = pcall(function() return delta.Unit end)
        if not ok2 or not dir then return end
        local normal = -dir
        local velocity = dir * 25

        pcall(function()
            _G.SafeFireServer(remote, "HitZombie", dracModel, hitPos, false, velocity, "Collision", normal)
        end)
    end

    -- ===== ESP helpers =====
    local function safeCreateHighlight(parent, adornee, fillColor, outlineColor, fillTransparency)
        if not ESP_HIGHLIGHT_SUPPORTED then return nil, "not_supported" end
        local ok, hl = pcall(function()
            local h = Instance.new("Highlight")
            -- Use stealth name for anti-detection
            h.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("HL_" .. math.random(10000, 99999))
            h.Adornee = adornee
            if fillColor then h.FillColor = fillColor end
            if outlineColor then h.OutlineColor = outlineColor end
            if fillTransparency then h.FillTransparency = fillTransparency end
            h.Parent = parent
            return h
        end)
        if not ok then
            ESP_HIGHLIGHT_SUPPORTED = false
            return nil, "create_failed"
        end
        return hl
    end

    local function safeCreateBillboard(parent, adornee)
        local ok, bb = pcall(function()
            local b = Instance.new("BillboardGui")
            -- Use stealth name for anti-detection
            b.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BB_" .. math.random(10000, 99999))
            b.Adornee = adornee
            b.Size = UDim2.new(0, 200, 0, 40)
            b.StudsOffset = Vector3.new(0, 3, 0)
            b.AlwaysOnTop = true
            b.Parent = parent
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = Color3.new(1, 1, 1)
            txt.TextStrokeTransparency = 0
            txt.Font = Enum.Font.GothamBold
            txt.TextScaled = true
            txt.Parent = b
            return b, txt
        end)
        if not ok then return nil, nil, "create_failed" end
        return bb, bb:FindFirstChildOfClass("TextLabel")
    end

    -- update Dracula Highlight state
    local function updateDraculaESP()
        local drac = getDracula()
        if not DraculaEspEnabled or not drac then
            if draculaHighlight then
                pcall(function() draculaHighlight:Destroy() end)
                draculaHighlight = nil
            end
            return
        end

        if draculaHighlight then return end

        -- create highlight (use previously chosen parent)
        local parent = ESP_GUI_PARENT
        local hl, err = safeCreateHighlight(parent, drac, Color3.fromRGB(255,0,0), Color3.fromRGB(255,255,255), 0.6)
        if not hl then
            -- highlight creation failed — disable Dracula ESP to avoid spamming errors
            DraculaEspEnabled = false
            if DEBUG then warn("[Dracula] Highlight failed:", err) end
            return
        end
        draculaHighlight = hl
    end

    -- clear all silver visuals
    local function clearSilverESP()
        for model, data in pairs(silverVisuals) do
            pcall(function()
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
            end)
            silverVisuals[model] = nil
        end
    end

    -- update Silver ESP (robust: re-resolves folder, auto-assigns PrimaryPart, GUI parent fallback)
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

        -- choose GUI parent dynamically in case CoreGui got blocked after script start
        local parent = ESP_GUI_PARENT
        if not parent or not parent.Parent then
            -- try fallback
            parent = LocalPlayer:FindFirstChild("PlayerGui") or parent
        end

        for _, trinket in ipairs(silverFolderNow:GetChildren()) do
            if not trinket:IsA("Model") then continue end

            -- ensure PrimaryPart exists (auto-assign first BasePart)
            if not trinket.PrimaryPart then
                local bp = trinket:FindFirstChildWhichIsA("BasePart")
                if bp then
                    pcall(function() trinket.PrimaryPart = bp end)
                else
                    -- can't display without a part
                    continue
                end
            end

            if not silverVisuals[trinket] then
                -- attempt to create highlight & billboard; if fails, disable Silver ESP
                local okHl, hl = pcall(function()
                    return safeCreateHighlight(parent, trinket, Color3.fromRGB(200,200,255), Color3.fromRGB(255,255,255), 0.5)
                end)
                if not okHl or not hl then
                    -- highlight not supported — try to fallback to only billboard
                    local okBB, bb, txt = pcall(function() return safeCreateBillboard(parent, trinket.PrimaryPart) end)
                    if okBB and bb and txt then
                        silverVisuals[trinket] = { Highlight = nil, Billboard = bb, Text = txt }
                    else
                        -- GUI creation failing; disable Silver ESP to avoid errors
                        SilverEspEnabled = false
                        clearSilverESP()
                        if DEBUG then warn("[SilverESP] Creation failed; disabling Silver ESP") end
                        return
                    end
                else
                    -- create billboard too
                    local bb, txt = safeCreateBillboard(parent, trinket.PrimaryPart)
                    silverVisuals[trinket] = { Highlight = hl, Billboard = bb, Text = txt }
                end
            end
        end

        -- update distances and cleanup removed trinkets
        for model, data in pairs(silverVisuals) do
            if not model.Parent or not model.PrimaryPart then
                pcall(function()
                    if data.Highlight then data.Highlight:Destroy() end
                    if data.Billboard then data.Billboard:Destroy() end
                end)
                silverVisuals[model] = nil
            else
                if hrpPos and data.Text then
                    local dist = (hrpPos - model.PrimaryPart.Position).Magnitude
                    data.Text.Text = string.format("Silver: %.1f", dist)
                end
            end
        end
    end

    -- background updater for Silver ESP (lightweight, deferred)
    task.defer(function()
        task.wait(6) -- Stagger start
        while true do
            if SilverEspEnabled then
                pcall(updateSilverESP)
                task.wait(0.25) -- Active: update every 0.25s
            else
                task.wait(2) -- PERFORMANCE: Sleep longer when disabled
            end
        end
    end)

    -- ===== Dracula attack loop (with loop-id cancellation) =====
    local currentDraculaLoopId = 0

    task.defer(function()
        task.wait(6.5) -- Stagger start
        while true do
            if not HitDraculaEnabled and not DraculaEspEnabled then
                -- PERFORMANCE: Sleep longer when both Dracula features disabled
                task.wait(2)
                continue
            end
            
            task.wait(DraculaLoopInterval)
            if not HitDraculaEnabled then
                -- keep ESP in sync (only if ESP enabled)
                if DraculaEspEnabled then pcall(updateDraculaESP) end
                continue
            end

            -- new tick: increment loop id to cancel previous spawned tasks
            currentDraculaLoopId = currentDraculaLoopId + 1
            local loopId = currentDraculaLoopId

            local drac = getDracula()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not (drac and hrp) then
                pcall(updateDraculaESP)
                continue
            end

            -- distance check (safe)
            local ok, pivot = pcall(function() return drac:GetPivot().Position end)
            if not ok or not pivot then
                pcall(updateDraculaESP)
                continue
            end
            local dist = (pivot - hrp.Position).Magnitude
            if dist > DraculaRange then
                pcall(updateDraculaESP)
                continue
            end

            -- ensure remotes are fresh
            if os.clock() - lastDraculaRemoteScan > 1 then ScanDraculaRemotes() end

            -- update ESP
            pcall(updateDraculaESP)

            -- 1) Swing spam: spawn cancellable tasks
            local spam = math.clamp(math.floor(DraculaSpamCount or 1), 1, 25)
            for remote in pairs(draculaRemotes) do
                if remote then
                    task.spawn(function()
                        for i = 1, spam do
                            if not HitDraculaEnabled or loopId ~= currentDraculaLoopId then break end
                            fireSwingRemote(remote)
                            task.wait(0.01)
                        end
                    end)
                    -- 2) Hit packets burst (also cancellable inside)
                    task.spawn(function()
                        for i = 1, 3 do
                            if not HitDraculaEnabled or loopId ~= currentDraculaLoopId then break end
                            fireHitAtDracula(remote, drac)
                            task.wait(DraculaHitSpacing)
                        end
                    end)
                end
            end
        end
    end)

    -- ===== UI =====
    local DraculaTab = EventTab -- Dracula goes inside EventTab
    local HitSection = DraculaTab:Section({ Title = "Hit Dracula", Icon = "flame", Opened = false })

    HitSection:Toggle({
        Title = "Hit Dracula",
        Flag = "Hit_Dracula",
        Desc = "Auto attack Dracula with melee.",
        Default = HitDraculaEnabled,
        Callback = function(v)
            HitDraculaEnabled = v
            if not v then
                -- cancel any running tasks
                currentDraculaLoopId = currentDraculaLoopId + 1
            end
            WindUI:Notify({
                Title = "Dracula",
                Content = v and "Hit Dracula Enabled" or "Hit Dracula Disabled",
                Duration = 2,
                Icon = v and "flame" or "x",
            })
            pcall(updateDraculaESP)
        end
    })

    HitSection:Slider({
        Title = "Swing Spam Count",
        Flag = "Swing_Spam_Count",
        Desc = "Swings per tick (1-25).",
        Step = 1,
        Value = { Min = 1, Max = 25, Default = DraculaSpamCount },
        Callback = function(v) DraculaSpamCount = math.clamp(math.floor(v), 1, 25) end
    })

    HitSection:Slider({
        Title = "Dracula Range",
        Flag = "Swing_Spam_Count_1",
        Desc = "Attack distance (1-25 studs).",
        Step = 1,
        Value = { Min = 1, Max = 25, Default = DraculaRange },
        Callback = function(v) DraculaRange = math.clamp(v, 1, 25) end
    })

    local EspSection = DraculaTab:Section({ Title = "ESP", Icon = "eye", Opened = false })

    EspSection:Toggle({
        Title = "Dracula ESP",
        Flag = "ESP",
        Desc = "Highlight Dracula.",
        Default = DraculaEspEnabled,
        Callback = function(v)
            DraculaEspEnabled = v
            if not v and draculaHighlight then
                pcall(function() draculaHighlight:Destroy() end)
                draculaHighlight = nil
            end
            WindUI:Notify({
                Title = "Dracula ESP",
                Content = v and "Enabled" or "Disabled",
                Duration = 2,
                Icon = v and "eye" or "x",
            })
            pcall(updateDraculaESP)
        end
    })

    EspSection:Toggle({
        Title = "Silver ESP",
        Flag = "Silver_ESP",
        Desc = "Highlight Silver Trinkets and show distance.",
        Default = SilverEspEnabled,
        Callback = function(v)
            -- If highlight/GUIs unsupported, we auto-disable and notify
            if v and not ESP_HIGHLIGHT_SUPPORTED then
                WindUI:Notify({
                    Title = "Silver ESP",
                    Content = "ESP features not supported by executor — disabled.",
                    Duration = 3,
                    Icon = "x",
                })
                SilverEspEnabled = false
                return
            end

            SilverEspEnabled = v
            if not v then clearSilverESP() end
            WindUI:Notify({
                Title = "Silver ESP",
                Content = v and "Enabled" or "Disabled",
                Duration = 2,
                Icon = v and "eye" or "x",
            })
        end
    })
end

task.wait(0.1) -- Delay to prevent lag
do -- // Players Tab
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local PlayersTab = ESPTab -- Players ESP goes inside ESPTab

    local PlayerESPSection = PlayersTab:Section({
        Title = "Player ESP",
        Icon = "user-check",
        Opened = false
    })

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
    local BILLBOARD_MAX_DISTANCE = 150 -- Roblox's native MaxDistance
    -- moved further down so the billboard sits clearly below the player
    local HEALTH_BILLBOARD_OFFSET = Vector3.new(0, -6.5, 0)
    local STUDS_SMOOTH_ALPHA = 0.22

    -- Make the whole billboard smaller per request
    local BILLBOARD_BASE_SIZE = Vector2.new(120, 52)
    local BILLBOARD_ENABLE_DISTANCE = 300 -- Max distance to render billboard
    local BILLBOARD_MIN_SCALE = 0.5
    local BILLBOARD_MAX_SCALE = 1.5
    
    -- Fade animation configuration
    local FADE_DISTANCE_BUFFER = 10 -- Studs for smooth fade transition

    local function RemovePlayerESP(player)
        local data = PlayerESPData[player]
        if not data then return end
        pcall(function()
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
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
            highlight.FillColor = Color3.fromRGB(0, 255, 0)
            highlight.FillTransparency = ChamsFillTransparency
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        end

        local billboard = nil
        local espFrame = nil -- Declare outside to ensure it's in scope
        local nameLabel = nil
        local distanceLabel = nil
        local statusBg = nil
        local statusLabel = nil
        
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
            billboard.Parent = char

            espFrame = Instance.new("Frame")
            -- Use randomized name for anti-detection
            espFrame.Name = "Frame_" .. math.random(10000, 99999)
            espFrame.Size = UDim2.new(1, 0, 1, 0)
            espFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            espFrame.BackgroundTransparency = PerformanceModeEnabled and 1 or 0.6
            espFrame.BorderSizePixel = 0
            espFrame.Parent = billboard

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 8)
            uiCorner.Parent = espFrame

            -- Status background (semi-transparent rounded box) - used for center MERCY or full-cover grabbed
            statusBg = Instance.new("Frame")
            -- Use randomized name
            statusBg.Name = "Frame_" .. math.random(10000, 99999)
            statusBg.Size = UDim2.new(0.9, 0, 0.36, 0)
            statusBg.Position = UDim2.new(0.05, 0, 0.32, 0) -- centered vertically by default
            statusBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            statusLabel.TextStrokeTransparency = 0.3
            statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextWrapped = true
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.Parent = espFrame

            -- Health BAR (outer frame + inner fill + centered label)
            local healthOuter = Instance.new("Frame")
            healthOuter.Name = "HealthOuter"
            healthOuter.Size = UDim2.new(0.9, 0, 0.16, 0) -- relative to billboard
            healthOuter.Position = UDim2.new(0.05, 0, 0.40, 0)
            healthOuter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            healthOuter.BorderSizePixel = 0
            healthOuter.Parent = espFrame

            local healthOuterCorner = Instance.new("UICorner")
            healthOuterCorner.CornerRadius = UDim.new(0, 6)
            healthOuterCorner.Parent = healthOuter

            local healthInner = Instance.new("Frame")
            healthInner.Name = "HealthInner"
            healthInner.Size = UDim2.new(0, 0, 1, 0) -- will be set per-health percent
            healthInner.Position = UDim2.new(0, 0, 0, 0)
            healthInner.BorderSizePixel = 0
            healthInner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            healthInner.Parent = healthOuter

            local healthInnerCorner = Instance.new("UICorner")
            healthInnerCorner.CornerRadius = UDim.new(0, 6)
            healthInnerCorner.Parent = healthInner

            local healthLabelInside = Instance.new("TextLabel")
            healthLabelInside.Name = "HealthLabelInside"
            healthLabelInside.Text = "100/100"
            healthLabelInside.Size = UDim2.new(1, 0, 1, 0)
            healthLabelInside.Position = UDim2.new(0, 0, 0, 0)
            healthLabelInside.BackgroundTransparency = 1
            healthLabelInside.TextColor3 = Color3.fromRGB(255, 255, 255)
            healthLabelInside.TextStrokeTransparency = 0.6
            healthLabelInside.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            healthLabelInside.TextSize = 12
            healthLabelInside.Font = Enum.Font.SourceSansBold
            healthLabelInside.TextWrapped = false
            healthLabelInside.TextXAlignment = Enum.TextXAlignment.Center
            healthLabelInside.TextYAlignment = Enum.TextYAlignment.Center
            healthLabelInside.Parent = healthOuter

            -- Infection BAR (outer + inner + label)
            local infectOuter = Instance.new("Frame")
            infectOuter.Name = "InfectOuter"
            infectOuter.Size = UDim2.new(0.9, 0, 0.16, 0)
            infectOuter.Position = UDim2.new(0.05, 0, 0.60, 0)
            infectOuter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            infectOuter.BorderSizePixel = 0
            infectOuter.Parent = espFrame

            local infectOuterCorner = Instance.new("UICorner")
            infectOuterCorner.CornerRadius = UDim.new(0, 6)
            infectOuterCorner.Parent = infectOuter

            local infectInner = Instance.new("Frame")
            infectInner.Name = "InfectInner"
            infectInner.Size = UDim2.new(0, 0, 1, 0) -- will be set by infection percent
            infectInner.Position = UDim2.new(0, 0, 0, 0)
            infectInner.BorderSizePixel = 0
            infectInner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            infectInner.Parent = infectOuter

            local infectInnerCorner = Instance.new("UICorner")
            infectInnerCorner.CornerRadius = UDim.new(0, 6)
            infectInnerCorner.Parent = infectInner

            local infectLabelInside = Instance.new("TextLabel")
            infectLabelInside.Name = "InfectLabelInside"
            infectLabelInside.Text = "0/100"
            infectLabelInside.Size = UDim2.new(1, 0, 1, 0)
            infectLabelInside.Position = UDim2.new(0, 0, 0, 0)
            infectLabelInside.BackgroundTransparency = 1
            infectLabelInside.TextColor3 = Color3.fromRGB(255, 255, 255)
            infectLabelInside.TextStrokeTransparency = 0.6
            infectLabelInside.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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
            distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.SourceSans
            distanceLabel.TextWrapped = true
            distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
            distanceLabel.Parent = espFrame

            -- Parent other objects to allow easy retrieval
        end

        PlayerESPData[player] = {
            Char = char,
            Humanoid = hum,
            Head = head,
            Highlight = highlight,
            Billboard = billboard,
            ESPFrame = espFrame,
            NameLabel = nameLabel,
            -- bars & labels (may be nil if billboard disabled)
            HealthOuter = espFrame and espFrame:FindFirstChild("HealthOuter") or nil,
            HealthInner = espFrame and espFrame:FindFirstChild("HealthOuter") and espFrame.HealthOuter:FindFirstChild("HealthInner") or nil,
            HealthLabelInside = espFrame and espFrame:FindFirstChild("HealthOuter") and espFrame.HealthOuter:FindFirstChild("HealthLabelInside") or nil,
            InfectOuter = espFrame and espFrame:FindFirstChild("InfectOuter") or nil,
            InfectInner = espFrame and espFrame:FindFirstChild("InfectOuter") and espFrame.InfectOuter:FindFirstChild("InfectInner") or nil,
            InfectLabelInside = espFrame and espFrame:FindFirstChild("InfectOuter") and espFrame.InfectOuter:FindFirstChild("InfectLabelInside") or nil,
            DistanceLabel = distanceLabel,
            StatusBg = statusBg,
            StatusLabel = statusLabel,
            NotifState = nil,
            LastNotify = 0,
            CurrentStudsOffset = HEALTH_BILLBOARD_OFFSET,
            DesiredStudsOffset = HEALTH_BILLBOARD_OFFSET
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

    -- Pre-built Color3 constants – avoids allocating new Color3 objects every update tick
    local C3_BLACK          = Color3.fromRGB(0, 0, 0)
    local C3_WHITE          = Color3.fromRGB(255, 255, 255)
    local C3_MERCY_HI       = Color3.fromRGB(120, 0, 120)
    local C3_MERCY_LO       = Color3.fromRGB(80, 0, 80)
    local C3_MERCY_FILL_HI  = Color3.fromRGB(180, 0, 180)
    local C3_MERCY_FILL_LO  = Color3.fromRGB(110, 0, 110)
    local C3_MERCY_OUTLINE  = Color3.fromRGB(255, 200, 255)
    local C3_GRAB_HI        = Color3.fromRGB(200, 30, 30)
    local C3_GRAB_LO        = Color3.fromRGB(120, 10, 10)
    local C3_GRAB_FILL_HI   = Color3.fromRGB(255, 0, 0)
    local C3_GRAB_FILL_LO   = Color3.fromRGB(200, 0, 0)
    local C3_GRAB_OUTLINE   = Color3.fromRGB(255, 100, 100)

    -- Per-player health-gradient cache: skip Color3.fromRGB when pct hasn't changed enough
    local playerHealthPctCache = setmetatable({}, { __mode = "k" })

    local function UpdateESPLoop()
        if not (ChamsESPEnabled or BillboardESPEnabled) then return end
        local localChar = LocalPlayer and LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        -- PERFORMANCE: Cache workspace.Players reference once per update cycle
        local wPlayers = Workspace:FindFirstChild("Players")
        -- PERFORMANCE: Compute os.clock() once for pulse animations
        local now = os.clock()

        for _, player in ipairs(Players:GetPlayers()) do
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

                if BillboardESPEnabled and (not data.Billboard or not data.Billboard.Parent) then
                    CreatePlayerESP(player)
                    data = PlayerESPData[player]
                    if not data then continue end
                end

                local hum = data.Humanoid
                if not hum then continue end
                -- pcall safety: Humanoid may be destroyed between checks
                local okH, health, max, percent
                okH, health, max = pcall(function()
                    local h = hum.Health
                    local m = hum.MaxHealth
                    return h, m
                end)
                if not okH then continue end
                max = (max and max > 0) and max or 1
                percent = math.clamp(health / max, 0, 1)

                -- Check grabbed/pinned/infected
                local grabbed = false
                local pinned = false
                local infectionLevel = 0
                if wPlayers then
                    local playerFolder = wPlayers:FindFirstChild(player.Name)
                    if playerFolder then
                        local userStates = playerFolder:FindFirstChild("UserStates")
                        if userStates then
                            local grabbedVal = userStates:FindFirstChild("Grabbed")
                            grabbed = (grabbedVal and tonumber(grabbedVal.Value) or 0) ~= 0
                            local pinVal = userStates:FindFirstChild("Pin")
                            pinned = tostring(pinVal and pinVal.Value or "None") ~= "None"
                            local infectedVal = userStates:FindFirstChild("Infected")
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
                        local fadeStart = math.max(BillboardShowDistance - FADE_DISTANCE_BUFFER, 0)
                        
                        if dist <= fadeStart then
                            fadeFactor = 0 -- Fully faded/transparent
                        else
                            -- Smooth fade from 0 to 1
                            fadeFactor = math.clamp((dist - fadeStart) / (BillboardShowDistance - fadeStart), 0, 1)
                        end
                    end
                end

                ----------------------------------------------------------------
                -- Background vs Bars transparency
                ----------------------------------------------------------------

                -- Determine base transparency just for the main background frame
                local frameTransparency
                do
                    local isGrabbedPinned = grabbed or pinned
                    local shouldBeRed = isGrabbedPinned or infectionLevel >= 70
                    -- if PerformanceModeEnabled => hide only the background frame
                    local baseTransparency = PerformanceModeEnabled and 1 or (shouldBeRed and 0.4 or 0.6)
                    frameTransparency = baseTransparency + (1 - fadeFactor) * 0.5
                end

                -- Apply transparency ONLY to the main background + status box
                if data.ESPFrame then
                    data.ESPFrame.BackgroundTransparency = frameTransparency
                end

                if data.StatusBg then
                    -- status box can stay a bit more solid than the frame
                    data.StatusBg.BackgroundTransparency = math.clamp(
                        (PerformanceModeEnabled and 0.7 or 0.45) + (1 - fadeFactor) * 0.3,
                        0, 1
                    )
                end

                -- === Bars have their own transparency, independent from PerformanceModeEnabled ===
                -- Health bar
                if data.HealthOuter then
                    local healthOuterBase = 0.3         -- solid-ish background for the bar
                    local healthOuterTransp = healthOuterBase + (1 - fadeFactor) * 0.4
                    data.HealthOuter.BackgroundTransparency = math.clamp(healthOuterTransp, 0, 1)
                end
                if data.HealthInner then
                    local healthInnerBase = 0           -- keep fill solid, only a little fade
                    local healthInnerTransp = healthInnerBase + (1 - fadeFactor) * 0.25
                    data.HealthInner.BackgroundTransparency = math.clamp(healthInnerTransp, 0, 1)
                end
                if data.HealthLabelInside then
                    data.HealthLabelInside.TextTransparency = 1 - fadeFactor
                end

                -- Infection bar
                if data.InfectOuter then
                    local infectOuterBase = 0.3
                    local infectOuterTransp = infectOuterBase + (1 - fadeFactor) * 0.4
                    data.InfectOuter.BackgroundTransparency = math.clamp(infectOuterTransp, 0, 1)
                end
                if data.InfectInner then
                    local infectInnerBase = 0
                    local infectInnerTransp = infectInnerBase + (1 - fadeFactor) * 0.25
                    data.InfectInner.BackgroundTransparency = math.clamp(infectInnerTransp, 0, 1)
                end
                if data.InfectLabelInside then
                    data.InfectLabelInside.TextTransparency = 1 - fadeFactor
                end

                ----------------------------------------------------------------
                -- Enhanced grabbed/pinned visuals when monitor is enabled + mercy
                ----------------------------------------------------------------

                local isGrabbedPinned = grabbed or pinned
                local isMercy = infectionLevel >= 100

                -- If infection reached 100 -> show MERCY (centered; infection bar remains visible)
                if isMercy and data.StatusLabel then
                    -- position the status box centered (smaller, so infection bar shows)
                    if data.StatusBg then
                        data.StatusBg.Size = UDim2.new(0.9, 0, 0.36, 0)
                        data.StatusBg.Position = UDim2.new(0.05, 0, 0.30, 0)
                        data.StatusBg.Visible = true
                        -- purple-ish background for mercy (pre-built constants)
                        data.StatusBg.BackgroundColor3 = math.sin(now * 6) > 0 and C3_MERCY_HI or C3_MERCY_LO
                    end

                    data.StatusLabel.Text = "MERCY"
                    data.StatusLabel.Visible = true
                    data.StatusLabel.TextSize = 16

                    -- hide name and health bar, but DO NOT hide infection bar
                    if data.NameLabel then data.NameLabel.Visible = false end
                    if data.HealthOuter then data.HealthOuter.Visible = false end
                    if data.InfectOuter then data.InfectOuter.Visible = ShowInfectionBarEnabled end
                    if data.DistanceLabel then data.DistanceLabel.Visible = true end

                    -- ensure health inner is reset
                    if data.HealthInner then data.HealthInner.Size = UDim2.new(0,0,1,0) end
                    -- set infection inner to full or according to infectionLevel
                    if data.InfectInner then
                        local infectPercent = math.clamp(infectionLevel / 100, 0, 1)
                        data.InfectInner.Size = UDim2.new(infectPercent, 0, 1, 0)
                    end

                    -- change chams color to purple pulse when mercy (pre-built constants)
                    if ChamsESPEnabled and data.Highlight then
                        local pulse = math.sin(now * 6)
                        data.Highlight.FillColor = pulse > 0 and C3_MERCY_FILL_HI or C3_MERCY_FILL_LO
                        data.Highlight.FillTransparency = math.clamp(
                            ChamsFillTransparency + 0.2 * math.abs(math.sin(now * 8)),
                            0, 1
                        )
                        data.Highlight.OutlineColor = C3_MERCY_OUTLINE
                    end

                elseif NotifyGrabbedPinnedEnabled and isGrabbedPinned then
                    -- grabbed/pinned: full-cover status (hide both bars)
                    if data.StatusBg then
                        data.StatusBg.Size = UDim2.new(1, 0, 1, 0)
                        data.StatusBg.Position = UDim2.new(0, 0, 0, 0)
                        data.StatusBg.Visible = true
                        -- red pulsing background for grabbed/pinned (pre-built constants)
                        data.StatusBg.BackgroundColor3 = math.sin(now * 10) > 0 and C3_GRAB_HI or C3_GRAB_LO
                    end

                    if data.StatusLabel then
                        data.StatusLabel.Text = grabbed and "GRABBED!" or "PINNED!"
                        data.StatusLabel.Visible = true
                        data.StatusLabel.TextSize = 18
                    end

                    if data.NameLabel then data.NameLabel.Visible = false end
                    if data.HealthOuter then data.HealthOuter.Visible = false end
                    if data.InfectOuter then data.InfectOuter.Visible = false end
                    if data.DistanceLabel then data.DistanceLabel.Visible = false end

                    -- ensure inner fills are reset
                    if data.HealthInner then data.HealthInner.Size = UDim2.new(0,0,1,0) end
                    if data.InfectInner then data.InfectInner.Size = UDim2.new(0,0,1,0) end

                    -- Change chams color to flashing red (pre-built constants)
                    if ChamsESPEnabled and data.Highlight then
                        local pulse = math.sin(now * 10)
                        data.Highlight.FillColor = pulse > 0 and C3_GRAB_FILL_HI or C3_GRAB_FILL_LO
                        data.Highlight.FillTransparency = math.clamp(
                            ChamsFillTransparency + 0.2 * math.abs(math.sin(now * 8)),
                            0, 1
                        )
                        data.Highlight.OutlineColor = C3_GRAB_OUTLINE
                    end
                else
                    -- Restore normal view
                    if data.StatusBg then data.StatusBg.Visible = false end
                    if data.StatusLabel then data.StatusLabel.Visible = false end
                    if data.NameLabel then data.NameLabel.Visible = true end
                    if data.HealthOuter then data.HealthOuter.Visible = ShowHealthBarEnabled end
                    if data.InfectOuter then data.InfectOuter.Visible = ShowInfectionBarEnabled end
                    if data.DistanceLabel then data.DistanceLabel.Visible = true end
                    
                    -- ESPFrame BackgroundColor3 is always black – no need to reset it every frame

                    -- Restore normal chams (skip gradient write if health hasn't moved >1%)
                    if ChamsESPEnabled and data.Highlight then
                        local cachedPct = playerHealthPctCache[player] or -1
                        if math.abs(percent - cachedPct) >= 0.01 then
                            playerHealthPctCache[player] = percent
                            local r = math.floor(255 * (1 - percent))
                            local g = math.floor(255 * percent)
                            local healthColor = Color3.fromRGB(r, g, 0)
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
                end  -- ✅ this is the missing one (closes isMercy / elseif / else)

                -- Billboard updates
                if BillboardESPEnabled and data.Billboard then
                    -- Set enabled based on render distance only
                    data.Billboard.Enabled = shouldRender
                    
                    if shouldRender then
                        -- Scale calculation with improved text sizing
                        local scale = 1
                        if dist and dist < BILLBOARD_ENABLE_DISTANCE then
                            scale = math.clamp(30 / math.max(dist, 1), BILLBOARD_MIN_SCALE, BILLBOARD_MAX_SCALE)
                        end

                        -- Apply size with scale
                        local w = math.floor(BILLBOARD_BASE_SIZE.X * scale)
                        local h = math.floor(BILLBOARD_BASE_SIZE.Y * scale)
                        data.Billboard.Size = UDim2.new(0, w, 0, h)

                        -- Better text scaling that scales ALL elements proportionally
                        local baseTextSize = math.floor(12 * scale)
                        local nameTextSize = math.floor(14 * scale)
                        local statusSize = math.floor(16 * scale)
                        local minSize = 8
                        
                        if data.StatusLabel and data.StatusLabel.Visible then
                            data.StatusLabel.TextSize = math.max(statusSize, minSize)
                        end
                        if data.NameLabel then
                            data.NameLabel.TextSize = math.max(nameTextSize, minSize)
                        end
                        if data.DistanceLabel then
                            data.DistanceLabel.TextSize = math.max(baseTextSize, minSize)
                        end

                        -- Update text values
                        if data.NameLabel then
                            data.NameLabel.Text = player.Name
                            -- apply fade to name text too
                            data.NameLabel.TextTransparency = 1 - fadeFactor
                            data.NameLabel.TextStrokeTransparency = 0.5 + (1 - fadeFactor) * 0.5
                        end

                        -- Health bar update (hide when grabbed/pinned or mercy)
                        if data.HealthOuter and data.HealthInner and ShowHealthBarEnabled and (not isGrabbedPinned) and (not isMercy) then
                            local healthPercent = percent
                            data.HealthInner.Size = UDim2.new(healthPercent, 0, 1, 0)
                            -- Only recompute gradient color if health changed enough
                            local cachedPct2 = (playerHealthPctCache[player] or -1)
                            if math.abs(healthPercent - cachedPct2) >= 0.01 then
                                local healthR = math.floor(255 * (1 - healthPercent))
                                local healthG = math.floor(255 * healthPercent)
                                data.HealthInner.BackgroundColor3 = Color3.fromRGB(healthR, healthG, 0)
                                -- Note: playerHealthPctCache is updated in the chams block above;
                                -- if chams are off we still need to update it here.
                                if not (ChamsESPEnabled and data.Highlight) then
                                    playerHealthPctCache[player] = healthPercent
                                end
                            end
                            if data.HealthLabelInside then
                                data.HealthLabelInside.Text = math.floor(health) .. "/" .. math.floor(max)
                                data.HealthLabelInside.TextSize = math.max(baseTextSize - 2, 8)
                                data.HealthLabelInside.TextTransparency = 1 - fadeFactor
                            end
                            data.HealthOuter.Visible = true
                        elseif data.HealthOuter then
                            data.HealthOuter.Visible = false
                            if data.HealthInner then data.HealthInner.Size = UDim2.new(0,0,1,0) end
                        end

                        -- Infection bar update (hide only when grabbed/pinned; show during mercy)
                        if data.InfectOuter and data.InfectInner and ShowInfectionBarEnabled and (not isGrabbedPinned) then
                            local infectPercent = math.clamp((infectionLevel or 0) / 100, 0, 1)
                            data.InfectInner.Size = UDim2.new(infectPercent, 0, 1, 0)
                            -- Only recompute if infection changed meaningfully
                            local cachedInfect = data._lastInfectPct or -1
                            if math.abs(infectPercent - cachedInfect) >= 0.01 then
                                data._lastInfectPct = infectPercent
                                local infectR = math.floor(255 * infectPercent)
                                local infectG = math.floor(255 * (1 - infectPercent))
                                data.InfectInner.BackgroundColor3 = Color3.fromRGB(infectR, infectG, 0)
                            end
                            if data.InfectLabelInside then
                                data.InfectLabelInside.Text = math.floor(infectionLevel) .. "/100"
                                data.InfectLabelInside.TextSize = math.max(baseTextSize - 2, 8)
                                data.InfectLabelInside.TextTransparency = 1 - fadeFactor
                            end
                            data.InfectOuter.Visible = true
                        elseif data.InfectOuter then
                            data.InfectOuter.Visible = false
                            if data.InfectInner then data.InfectInner.Size = UDim2.new(0,0,1,0) end
                        end

                        if data.DistanceLabel and data.DistanceLabel.Visible then
                            -- PERF: Only rebuild string when distance changes by ≥1 stud
                            local flooredDist = math.floor(dist or 0)
                            if flooredDist ~= (data._lastDist or -1) then
                                data._lastDist = flooredDist
                                data.DistanceLabel.Text = flooredDist .. " studs"
                            end
                            data.DistanceLabel.TextTransparency = 1 - fadeFactor
                            data.DistanceLabel.TextStrokeTransparency = 0.5 + (1 - fadeFactor) * 0.5
                        end
                    end

                    -- Apply fade to status label as well
                    if data.StatusLabel and data.StatusLabel.Visible then
                        data.StatusLabel.TextTransparency = 1 - fadeFactor
                        data.StatusLabel.TextStrokeTransparency = 0.5 + (1 - fadeFactor) * 0.5
                    end

                    -- Studs offset smoothing (we move below the head)
                    data.DesiredStudsOffset = grabbed and Vector3.new(0, -2, 0) or HEALTH_BILLBOARD_OFFSET
                    data.CurrentStudsOffset = data.CurrentStudsOffset:Lerp(data.DesiredStudsOffset, STUDS_SMOOTH_ALPHA)
                    data.Billboard.StudsOffset = data.CurrentStudsOffset
                end

                -- Low health notifications
                if NotifyLowHealthEnabled then
                    if health <= 0 then
                        if data.NotifState ~= "dead" then
                            data.NotifState = "dead"
                            WindUI:Notify({
                                Title = "Player Died",
                                Content = player.Name .. " has Died!",
                                Duration = 3,
                                Icon = "skull",
                            })
                        end
                    elseif percent < 0.25 then
                        if data.NotifState ~= "dying" and os.clock() - data.LastNotify > 3 then
                            data.NotifState = "dying"
                            data.LastNotify = os.clock()
                            WindUI:Notify({
                                Title = "Player Dying",
                                Content = player.Name .. " is Dying!",
                                Duration = 3,
                                Icon = "heart",
                            })
                        end
                    elseif percent < 0.45 then
                        if data.NotifState ~= "low" and os.clock() - data.LastNotify > 3 then
                            data.NotifState = "low"
                            data.LastNotify = os.clock()
                            WindUI:Notify({
                                Title = "Player Low Health",
                                Content = player.Name .. " has Low Health!",
                                Duration = 3,
                                Icon = "activity",
                            })
                        end
                    else
                        data.NotifState = nil
                    end
                end
            end
        end
    end

    -- PERFORMANCE: Throttle Player ESP updates
    local playerESPLastUpdate = 0
    local PLAYER_ESP_UPDATE_INTERVAL = 0.25 -- Update every 0.25 seconds (was 0.15)
    local playerESPHeartbeatConn = nil -- stored so it can be disconnected if needed
    
    task.defer(function()
        task.wait(1) -- Stagger start
        playerESPHeartbeatConn = RunService.Heartbeat:Connect(function()
            -- PERFORMANCE: Throttle updates
            local now = os.clock()
            if now - playerESPLastUpdate < PLAYER_ESP_UPDATE_INTERVAL then return end
            playerESPLastUpdate = now
            
            UpdateESPLoop()
        end)
    end)

    Players.PlayerRemoving:Connect(RemovePlayerESP)
    Players.PlayerAdded:Connect(function(p)
        task.wait(0.4)
        if ChamsESPEnabled or BillboardESPEnabled then 
            task.wait()
            CreatePlayerESP(p) 
        end
    end)

    PlayerESPSection:Toggle({
        Title = "Players Chams ESP",
        Flag = "Chams_ESP",
        Desc = "Show chams ESP on players.",
        Default = false,
        Callback = function(state)
            ChamsESPEnabled = state
            if state then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        task.wait()
                        CreatePlayerESP(pl)
                    end
                end
                WindUI:Notify({
                    Title = "Player ESP",
                    Content = "Player Chams ESP enabled",
                    Duration = 2,
                    Icon = "eye",
                })
            else
                for p in pairs(PlayerESPData) do
                    local data = PlayerESPData[p]
                    if data and data.Highlight then 
                        data.Highlight:Destroy() 
                        data.Highlight = nil
                    end
                end
                WindUI:Notify({
                    Title = "Player ESP",
                    Content = "Player Chams ESP disabled",
                    Duration = 2,
                    Icon = "eye-off",
                })
            end
        end
    })

    PlayerESPSection:Toggle({
        Title = "Players Billboard ESP",
        Flag = "Billboard_ESP",
        Desc = "Show billboard text above players.",
        Default = false,
        Callback = function(state)
            BillboardESPEnabled = state
            if state then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        task.wait()
                        CreatePlayerESP(pl)
                    end
                end
                -- ensure bars respect current settings
                for _, data in pairs(PlayerESPData) do
                    if data and data.HealthOuter then
                        data.HealthOuter.Visible = ShowHealthBarEnabled and data.Billboard and data.Billboard.Enabled
                    end
                    if data and data.InfectOuter then
                        data.InfectOuter.Visible = ShowInfectionBarEnabled and data.Billboard and data.Billboard.Enabled
                    end
                end
                WindUI:Notify({
                    Title = "Player ESP",
                    Content = "Player Billboard ESP enabled",
                    Duration = 2,
                    Icon = "eye",
                })
            else
                for p in pairs(PlayerESPData) do
                    local data = PlayerESPData[p]
                    if data and data.Billboard then 
                        data.Billboard:Destroy() 
                        data.Billboard = nil
                        data.NameLabel = nil
                        -- destroy bar refs if present
                        if data.HealthOuter then 
                            pcall(function() data.HealthOuter:Destroy() end)
                        end
                        if data.InfectOuter then 
                            pcall(function() data.InfectOuter:Destroy() end)
                        end
                        data.HealthOuter = nil
                        data.HealthInner = nil
                        data.HealthLabelInside = nil
                        data.InfectOuter = nil
                        data.InfectInner = nil
                        data.InfectLabelInside = nil
                        data.DistanceLabel = nil
                        data.StatusLabel = nil
                        data.ESPFrame = nil
                    end
                end
                WindUI:Notify({
                    Title = "Player ESP",
                    Content = "Player Billboard ESP disabled",
                    Duration = 2,
                    Icon = "eye-off",
                })
            end
        end
    })

    -- ===== SELF ESP SECTION =====
    local SelfESPSection = PlayersTab:Section({
        Title = "Self ESP",
        Icon = "user",
        Opened = false
    })
    
    local SelfESPEnabled = false
    local SelfBillboardEnabled = false
    local SelfNoBillboardBg = false
    local SelfHealthBarESPEnabled = false
    local SelfInfectionBarESPEnabled = false
    local selfESPData = {}
    
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
            hl.FillColor = Color3.fromRGB(0, 200, 255) -- Cyan for self
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
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
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.LightInfluence = 0
            bb.MaxDistance = 150
            bb.Parent = head
            selfESPData.Billboard = bb

            local espFrame = Instance.new("Frame")
            espFrame.Name = "Frame_" .. math.random(10000, 99999)
            espFrame.Size = UDim2.new(1, 0, 1, 0)
            espFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
            nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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
            youLabel.TextColor3 = Color3.fromRGB(180, 255, 255)
            youLabel.TextStrokeTransparency = 0.5
            youLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            youLabel.TextSize = 13
            youLabel.Font = Enum.Font.SourceSans
            youLabel.TextWrapped = true
            youLabel.TextXAlignment = Enum.TextXAlignment.Center
            youLabel.Parent = espFrame

            -- ── Health Bar row (inside billboard) ──
            local hpRowY = 40  -- pixels from top of frame
            local healthOuter = Instance.new("Frame")
            healthOuter.Name = "HealthOuter"
            healthOuter.Size = UDim2.new(0, 144, 0, 15)
            healthOuter.Position = UDim2.new(0, 8, 0, hpRowY)
            healthOuter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            healthOuter.BorderSizePixel = 0
            healthOuter.Visible = SelfHealthBarESPEnabled
            healthOuter.Parent = espFrame
            Instance.new("UICorner", healthOuter).CornerRadius = UDim.new(0, 5)
            selfESPData.HealthOuter = healthOuter

            local healthInner = Instance.new("Frame")
            healthInner.Name = "HealthInner"
            healthInner.Size = UDim2.new(1, 0, 1, 0)
            healthInner.BorderSizePixel = 0
            healthInner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            healthInner.Parent = healthOuter
            Instance.new("UICorner", healthInner).CornerRadius = UDim.new(0, 5)
            selfESPData.HealthInner = healthInner

            local healthLabel = Instance.new("TextLabel")
            healthLabel.Name = "HealthLabelInside"
            healthLabel.Text = "100/100"
            healthLabel.Size = UDim2.new(1, 0, 1, 0)
            healthLabel.BackgroundTransparency = 1
            healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            healthLabel.TextStrokeTransparency = 0.6
            healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            healthLabel.TextSize = 11
            healthLabel.Font = Enum.Font.SourceSansBold
            healthLabel.TextWrapped = false
            healthLabel.TextXAlignment = Enum.TextXAlignment.Center
            healthLabel.TextYAlignment = Enum.TextYAlignment.Center
            healthLabel.Parent = healthOuter
            selfESPData.HealthLabel = healthLabel

            -- ── Infection Bar row (inside billboard, below health bar) ──
            local infRowY = hpRowY + (SelfHealthBarESPEnabled and 18 or 0)
            local infOuter = Instance.new("Frame")
            infOuter.Name = "InfectionOuter"
            infOuter.Size = UDim2.new(0, 144, 0, 15)
            infOuter.Position = UDim2.new(0, 8, 0, infRowY)
            infOuter.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            infOuter.BorderSizePixel = 0
            infOuter.Visible = SelfInfectionBarESPEnabled
            infOuter.Parent = espFrame
            Instance.new("UICorner", infOuter).CornerRadius = UDim.new(0, 5)
            selfESPData.InfectionOuter = infOuter

            local infInner = Instance.new("Frame")
            infInner.Name = "InfInner"
            infInner.Size = UDim2.new(0, 0, 1, 0)
            infInner.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
            infInner.BorderSizePixel = 0
            infInner.Parent = infOuter
            Instance.new("UICorner", infInner).CornerRadius = UDim.new(0, 5)
            selfESPData.InfectionInner = infInner

            local infLabel = Instance.new("TextLabel")
            infLabel.Name = "InfLabel"
            infLabel.Size = UDim2.new(1, 0, 1, 0)
            infLabel.BackgroundTransparency = 1
            infLabel.Text = "0%"
            infLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
            infLabel.TextStrokeTransparency = 0.5
            infLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            infLabel.TextSize = 10
            infLabel.Font = Enum.Font.SourceSansBold
            infLabel.TextXAlignment = Enum.TextXAlignment.Center
            infLabel.TextYAlignment = Enum.TextYAlignment.Center
            infLabel.Parent = infOuter
            selfESPData.InfectionLabel = infLabel

            pcall(function()
                if _G.protectESP then _G.protectESP(bb) end
            end)
        end
    end  -- end of CreateSelfESP

    -- Update self health display (event-driven: no polling loop, no redundant writes)
    local selfHealthConn = nil
    local selfLastHealthPct = -1 -- cached to skip redundant Color3/Size writes

    local COLOR_GREEN  = Color3.fromRGB(0, 255, 0)
    local COLOR_YELLOW = Color3.fromRGB(255, 255, 0)
    local COLOR_RED    = Color3.fromRGB(255, 0, 0)
    local COLOR_WHITE  = Color3.fromRGB(255, 255, 255)

    local function UpdateSelfHealth(hum)
        if not SelfBillboardEnabled then return end
        if not selfESPData.HealthLabel then return end
        local health    = math.floor(hum.Health)
        local maxHealth = math.floor(hum.MaxHealth)
        local pct       = math.clamp(hum.Health / math.max(maxHealth, 1), 0, 1)
        if math.abs(pct - selfLastHealthPct) < 0.005 then return end
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
    local COLOR_INFECT_LOW    = Color3.fromRGB(0, 220, 80)
    local COLOR_INFECT_MID    = Color3.fromRGB(200, 100, 255)
    local COLOR_INFECT_HIGH   = Color3.fromRGB(255, 30, 30)

    local function UpdateSelfInfection()
        if not SelfInfectionBarESPEnabled then return end
        if not selfESPData.InfectionInner or not selfESPData.InfectionLabel then return end

        local rawVal = nil
        pcall(function()
            local wsPlayers = Workspace:FindFirstChild("Players")
            if wsPlayers then
                local wsP = wsPlayers:FindFirstChild(LocalPlayer.Name)
                if wsP and wsP:FindFirstChild("UserStates") then
                    local inf = wsP.UserStates:FindFirstChild("Infected")
                    if inf then rawVal = inf.Value end
                end
            end
            if rawVal == nil and LocalPlayer:FindFirstChild("UserStates") then
                local inf = LocalPlayer.UserStates:FindFirstChild("Infected")
                if inf then rawVal = inf.Value end
            end
            if rawVal == nil and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("UserStates") then
                local inf = LocalPlayer.Character.UserStates:FindFirstChild("Infected")
                if inf then rawVal = inf.Value end
            end
        end)

        local numeric = 0
        if type(rawVal) == "number" then
            numeric = rawVal
        elseif type(rawVal) == "string" then
            numeric = tonumber(rawVal) or 0
        elseif type(rawVal) == "boolean" then
            numeric = rawVal and 100 or 0
        end
        numeric = math.clamp(numeric, 0, 100)
        local pct = numeric / 100

        if math.abs(pct - selfLastInfectionPct) < 0.005 then return end
        selfLastInfectionPct = pct

        selfESPData.InfectionInner.Size = UDim2.new(pct, 0, 1, 0)
        if pct <= 0.5 then
            selfESPData.InfectionInner.BackgroundColor3 = COLOR_INFECT_LOW:Lerp(COLOR_INFECT_MID, pct * 2)
        else
            selfESPData.InfectionInner.BackgroundColor3 = COLOR_INFECT_MID:Lerp(COLOR_INFECT_HIGH, (pct - 0.5) * 2)
        end
        selfESPData.InfectionLabel.Text = "" .. math.floor(numeric) .. "%"
        selfESPData.InfectionLabel.TextColor3 = pct < 0.5 and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 200, 255)
    end

    -- Lightweight polling loop for infection (event-free since Infected may replicate differently)
    task.spawn(function()
        while task.wait(0.5) do
            if SelfInfectionBarESPEnabled then
                pcall(UpdateSelfInfection)
            end
        end
    end)

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
    LocalPlayer.CharacterAdded:Connect(function(char)
        selfLastHealthPct = -1
        -- wait for Humanoid to exist before binding
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then BindSelfHealthEvents() end
    end)
    
    SelfESPSection:Toggle({
        Title = "Self Highlight ESP",
        Flag = "Highlight_ESP",
        Desc = "Highlight yourself in cyan.",
        Default = false,
        Callback = function(state)
            SelfESPEnabled = state
            if state then
                CreateSelfESP()
                WindUI:Notify({
                    Title = "Self ESP",
                    Content = "Self Highlight enabled",
                    Duration = 2,
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
    
    SelfESPSection:Toggle({
        Title = "Self Billboard ESP",
        Flag = "Billboard_ESP_1",
        Desc = "Show self billboard with name and HP.",
        Default = false,
        Callback = function(state)
            SelfBillboardEnabled = state
            if state then
                CreateSelfESP()
                WindUI:Notify({
                    Title = "Self ESP",
                    Content = "Self Billboard enabled",
                    Duration = 2,
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

    SelfESPSection:Toggle({
        Title = "No Billboard Background",
        Flag = "No_Billboard_Background",
        Desc = "Remove background from self billboard.",
        Default = false,
        Callback = function(state)
            SelfNoBillboardBg = state
            if selfESPData.ESPFrame then
                selfESPData.ESPFrame.BackgroundTransparency = state and 1 or 0.6
            end
        end
    })
    
    -- Recreate visuals on respawn (health event binding handled above)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to fully load
        selfLastInfectionPct = -1
        if SelfESPEnabled or SelfBillboardEnabled or SelfHealthBarESPEnabled or SelfInfectionBarESPEnabled then
            CreateSelfESP()
        end
    end)
    
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

    SelfESPSection:Toggle({
        Title = "Health Bar ESP",
        Flag = "Health_Bar_ESP",
        Desc = "Show HP bar in self billboard.",
        Default = false,
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
                -- Billboard not built yet — create it
                CreateSelfESP()
            end
        end
    })

    SelfESPSection:Toggle({
        Title = "Infection Bar ESP",
        Flag = "Infection_Bar_ESP",
        Desc = "Show infection level in self billboard.",
        Default = false,
        Callback = function(state)
            SelfInfectionBarESPEnabled = state
            selfLastInfectionPct = -1
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

    -- ===== END SELF ESP SECTION =====

    -- Settings section (renamed from Grabbed & Pinned)
    local SettingsSection = PlayersTab:Section({
        Title = "Settings",
        Icon = "settings",
        Opened = false
    })

    SettingsSection:Toggle({
        Title = "Notify Grabbed and Pinned Players",
        Flag = "Settings",
        Desc = "Notify when a player is grabbed or pinned.",
        Default = false,
        Callback = function(state)
            NotifyGrabbedPinnedEnabled = state
            WindUI:Notify({
                Title = "Grabbed/Pinned Monitor",
                Content = "Grabbed/Pinned monitor " .. (state and "ON" or "OFF"),
                Duration = 2,
                Icon = state and "eye" or "eye-off",
            })
        end
    })

    SettingsSection:Toggle({
        Title = "Show Health Bar",
        Flag = "Grabbed_Pinned_Monitor",
        Desc = "Show HP bar on billboard.",
        Default = false,
        Callback = function(state)
            ShowHealthBarEnabled = state
            WindUI:Notify({
                Title = "Health Bar",
                Content = state and "Health bar ON" or "Health bar OFF",
                Duration = 2,
                Icon = state and "heart" or "heart-off",
            })
            -- update existing billboards immediately
            for _, data in pairs(PlayerESPData) do
                if data and data.HealthOuter then
                    data.HealthOuter.Visible = state and data.Billboard and data.Billboard.Enabled and (not data.StatusLabel or not data.StatusLabel.Visible)
                end
            end
        end
    })

    SettingsSection:Toggle({
        Title = "Show Infection Bar",
        Flag = "Show_Infection_Bar",
        Desc = "Show infection bar on billboard.",
        Default = false,
        Callback = function(state)
            ShowInfectionBarEnabled = state
            WindUI:Notify({
                Title = "Infection Bar",
                Content = state and "Infection bar ON" or "Infection bar OFF",
                Duration = 2,
                Icon = state and "thermometer" or "thermometer-off",
            })
            for _, data in pairs(PlayerESPData) do
                if data and data.InfectOuter then
                    data.InfectOuter.Visible = state and data.Billboard and data.Billboard.Enabled and (not data.StatusLabel or not data.StatusLabel.Visible)
                end
            end
        end
    })

    SettingsSection:Toggle({
        Title = "Notify Low Health Players",
        Flag = "Notify_Low_Health_Players",
        Desc = "Notify when players are low/dying.",
        Default = false,
        Callback = function(state)
            NotifyLowHealthEnabled = state
            WindUI:Notify({
                Title = "Low Health Notify",
                Content = state and "Low health notifications ON" or "Low health notifications OFF",
                Duration = 2,
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
    
    SettingsSection:Toggle({
        Title = "Team ESP",
        Flag = "Team_ESP",
        Desc = "Color by team, overrides HP-based color.",
        Default = false,
        Callback = function(state)
            TeamESPEnabled = state
            _G._PlayerESP_TeamESPEnabled = state
            WindUI:Notify({
                Title = "Team ESP",
                Content = state and "Team colors ON" or "Team colors OFF",
                Duration = 2,
                Icon = state and "users" or "users",
            })
            -- Update existing highlights immediately
            if ChamsESPEnabled then
                for player, data in pairs(PlayerESPData) do
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
    SettingsSection:Toggle({
        Title = "No billboard Background",
        Flag = "No_billboard_Background",
        Desc = "Remove billboard background.",
        Default = true,
        Callback = function(state)
            PerformanceModeEnabled = state
            -- Update existing billboards immediately (only touch backgrounds, not bars)
            for _, data in pairs(PlayerESPData) do
                if data.ESPFrame then
                    data.ESPFrame.BackgroundTransparency = state and 1 or 0.6
                end
                if data.StatusBg then
                    data.StatusBg.BackgroundTransparency = state and 0.7 or 0.45
                end
            end
            WindUI:Notify({
                Title = "Billboard",
                Content = state and "Billboard Background hidden" or "Billboard Background shown.",
                Duration = 2,
                Icon = state and "zap" or "zap-off",
            })
        end
    })

    -- Billboard Distance Slider
    SettingsSection:Slider({
        Title = "Billboard Showing Distance",
        Flag = "Billboard_Showing_Distance",
        Desc = "Hide billboard below this distance.",
        Step = 1,
        Value = {
            Min = 5,
            Max = 50,
            Default = 5,
        },
        Callback = function(value)
            -- Clamp value to avoid edge cases
            BillboardShowDistance = math.clamp(value, 0, 100)
        end
    })

    -- Player Chams Transparency Slider
    SettingsSection:Slider({
        Title = "Chams Transparency",
        Flag = "Chams_Transparency",
        Desc = "Player chams transparency.",
        Step = 0.05,
        Value = {
            Min = 0,
            Max = 1,
            Default = 0.45,
        },
        Callback = function(value)
            local transparency = math.clamp(value, 0, 1)
            ChamsFillTransparency = transparency  -- <-- update global

            -- Update existing player highlights
            for _, data in pairs(PlayerESPData) do
                if data.Highlight then
                    data.Highlight.FillTransparency = transparency
                end
            end
        end
    })

    SettingsSection:Toggle({
        Title = "Notify Low Health Players",
        Flag = "Notify_Low_Health_Players_1",
        Desc = "Notify when players are low/dying.",
        Default = false,
        Callback = function(state)
            NotifyLowHealthEnabled = state
            WindUI:Notify({
                Title = "Low Health Notify",
                Content = state and "Low health notifications ON" or "Low health notifications OFF",
                Duration = 2,
                Icon = state and "bell" or "bell-off",
            })
        end
    })
end -- end of Players Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Headless Horseman Tab
    -- // Headless Tab (rewritten)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local HeadlessTab = EventTab -- Headless Horseman goes inside EventTab

    -- Headless Section
    local HeadlessSection = HeadlessTab:Section({
        Title = "Headless Horseman Features",
        Icon = "skull",
        Opened = false
    })

    -- State
    local HeadlessESPEnabled = false
    local HeadlessAimlockEnabled = false
    local AimlockActive = false
    local manualPing = 90
    local aimButtonSize = 90
    local aimKeybind = Enum.KeyCode.B
    local AimGui, AimButton, AimButtonInner = nil, nil, nil

    local AimBtnDragging = false
    local PotentialDrag = false
    local DragInput = nil
    local DragStartPos = nil
    local BtnTargetPos = nil
    local InputStartTick = 0

    local AimConns = {}         -- connections to be cleaned (aim-related)
    local ActiveTweens = {}
    -- Use weak keys so destroyed models get garbage collected
    local highlightInstances = setmetatable({}, { __mode = "k" }) -- model -> Highlight
    local aimbotConnection = nil
    local inputConn = nil
    local lastBossFound = os.clock()
    local bossTimeout = 10 -- seconds
    local ListeningForBind = false

    -- separate ESP heartbeat connection so it isn't accidentally disconnected
    local espHeartbeatConn = nil

    -- Helpers
    local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

    local function viewportSize()
        local cam = Workspace.CurrentCamera
        if cam and cam.ViewportSize ~= Vector2.zero then
            return cam.ViewportSize
        end
        return Vector2.new(1280, 720)
    end

    local function ensureOnScreen(positionUDim2, sizePx)
        local vs = viewportSize()
        local x = positionUDim2.X.Offset
        local y = positionUDim2.Y.Offset
        local maxX = math.max(0, vs.X - sizePx)
        local maxY = math.max(0, vs.Y - sizePx)
        x = clamp(x, 0, maxX)
        y = clamp(y, 0, maxY)
        return UDim2.new(0, math.floor(x), 0, math.floor(y))
    end

    local function cancelTweens()
        for _, tween in pairs(ActiveTweens) do
            if tween then
                pcall(function() tween:Cancel() end)
            end
        end
        ActiveTweens = {}
    end

    local function safeDestroy(obj)
        pcall(function() if obj then obj:Destroy() end end)
    end

    -- Robust finder for the HeadlessHorseman model / hitbox
    -- PERF: GetDescendants() on Workspace is very expensive (~3-10ms per call).
    --       Results are cached for HEADLESS_CHECK_INTERVAL so it never runs per-frame.
    local function findHeadlessBossModel()
        local rootNames = {"Sleepy Hollow", "SleepyHollow", "Sleepy_Hollow"}
        for _, rn in ipairs(rootNames) do
            local root = Workspace:FindFirstChild(rn)
            if root then
                local modes = root:FindFirstChild("Modes") or root:FindFirstChild("modes")
                if modes then
                    local bossFolder = modes:FindFirstChild("Boss") or modes:FindFirstChild("boss")
                    if bossFolder then
                        local hh = bossFolder:FindFirstChild("HeadlessHorsemanBoss") or bossFolder:FindFirstChild("HeadlessHorseman")
                        if hh then return hh end
                    end
                    local hh2 = modes:FindFirstChild("HeadlessHorsemanBoss") or modes:FindFirstChild("HeadlessHorseman")
                    if hh2 then return hh2 end
                end
                local hh3 = root:FindFirstChild("HeadlessHorsemanBoss") or root:FindFirstChild("HeadlessHorseman")
                if hh3 then return hh3 end
            end
        end

        -- PERF: GetDescendants is only reached as a last resort; it is guarded by the
        --       0.5-second HEADLESS_CHECK_INTERVAL cache in the Heartbeat, so it will
        --       never be called more than ~2×/sec even in the worst case.
        local zombiesFolder = Workspace:FindFirstChild("Zombies")
        local searchRoot = zombiesFolder or Workspace
        for _, desc in ipairs(searchRoot:GetDescendants()) do
            if desc:IsA("Model") and desc:FindFirstChild("ZOMBIE_HITBOX") then
                return desc
            end
        end

        local top = Workspace:FindFirstChild("HeadlessHorsemanBoss") or Workspace:FindFirstChild("HeadlessHorseman")
        if top then return top end
        return nil
    end

    -- Heartbeat: manage ESP highlights (keeps reference to camera updated)
    local headlessLastCheck = 0
    local headlessCachedModel = nil
    local HEADLESS_CHECK_INTERVAL = 0.5 -- Only search for boss every 0.5 seconds instead of every frame
    task.defer(function()
        task.wait(1.5) -- Stagger start
        espHeartbeatConn = RunService.Heartbeat:Connect(function()
            -- PERFORMANCE FIX: Early return if feature is disabled
            if not HeadlessESPEnabled then
                -- Only cleanup if there are highlights to remove
                if next(highlightInstances) then
                    for model, h in pairs(highlightInstances) do
                        safeDestroy(h)
                        highlightInstances[model] = nil
                    end
                end
                headlessCachedModel = nil
                return
            end
            
            Camera = Workspace.CurrentCamera or Camera

            -- clear any invalid highlights
            for model, h in pairs(highlightInstances) do
                if not model or not model.Parent or (h and not h.Parent) then
                    safeDestroy(h)
                    highlightInstances[model] = nil
                end
            end

            -- PERFORMANCE FIX: Only search for boss model every 0.5 seconds instead of every frame
            local now = os.clock()
            if now - headlessLastCheck > HEADLESS_CHECK_INTERVAL or not headlessCachedModel or not headlessCachedModel.Parent then
                headlessLastCheck = now
                headlessCachedModel = findHeadlessBossModel()
            end
            
            local hhModel = headlessCachedModel
            if not hhModel then
                for model, h in pairs(highlightInstances) do
                    safeDestroy(h)
                    highlightInstances[model] = nil
                end
                return
            end

            -- create highlight for this model if missing
            if not highlightInstances[hhModel] then
                local h = Instance.new("Highlight")
                -- Use stealth name for anti-detection
                h.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("HL_" .. math.random(10000, 99999))
                h.FillColor = Color3.fromRGB(255, 100, 100)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                -- Parent the Highlight to the model (model must be descendant of workspace)
                -- this works across model replacements because we key by object reference
                h.Parent = hhModel
                highlightInstances[hhModel] = h
            end
        end)
    end)

    -- safe helper to locate hitbox part (ZOMBIE_HITBOX)
    local function getHeadlessHitbox()
        local model = findHeadlessBossModel()
        if not model then return nil end
        local hh = model:FindFirstChild("HeadlessHorseman") or model
        if hh and hh:FindFirstChild("ZOMBIE_HITBOX") then
            return hh:FindFirstChild("ZOMBIE_HITBOX")
        end
        if model:FindFirstChild("ZOMBIE_HITBOX") then
            return model:FindFirstChild("ZOMBIE_HITBOX")
        end
        -- fallback: search children
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") and child.Name == "ZOMBIE_HITBOX" then
                return child
            end
        end
        return nil
    end

    -- start aimbot (predict + smooth)
    local function startAimbot()
        if aimbotConnection then
            pcall(function() aimbotConnection:Disconnect() end)
            aimbotConnection = nil
        end

        aimbotConnection = RunService.RenderStepped:Connect(function(delta)
            if not AimlockActive or not HeadlessAimlockEnabled then return end
            Camera = Workspace.CurrentCamera or Camera

            local ok, targetPart = pcall(getHeadlessHitbox)
            if not ok or not targetPart or not targetPart:IsA("BasePart") then
                if os.clock() - lastBossFound > bossTimeout then
                    setButtonActive(false)
                    if WindUI then
                        WindUI:Notify({
                            Title = "Aimlock",
                            Content = "Headless Horseman not found, aimlock disabled.",
                            Duration = 3,
                            Icon = "x"
                        })
                    end
                end
                return
            end

            if not targetPart.Parent then return end
            lastBossFound = os.clock()

            local predicted = targetPart.Position + (targetPart.Velocity * (manualPing / 1000))

            local cameraPos = Camera.CFrame.Position
            local direction = predicted - cameraPos
            local dist = direction.Magnitude
            if dist == 0 then return end
            if dist > 2000 then return end

            local targetCFrame = CFrame.new(cameraPos, cameraPos + direction.Unit)
            local lerpAlpha = clamp(delta * 10, 0, 1)
            pcall(function() Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lerpAlpha) end)
        end)

        table.insert(AimConns, aimbotConnection)
    end

    local function stopAimbot()
        if aimbotConnection then
            pcall(function() aimbotConnection:Disconnect() end)
            aimbotConnection = nil
        end
    end

    -- setButtonActive toggles aim state and updates visuals
    function setButtonActive(active)
        AimlockActive = active
        cancelTweens()

        if AimButton and AimButtonInner then
            if active then
                local tween1 = TweenService:Create(AimButton, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {BackgroundColor3 = Color3.fromRGB(60, 200, 100)})
                local tween2 = TweenService:Create(AimButtonInner, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {BackgroundColor3 = Color3.fromRGB(40, 180, 80)})
                pcall(function() tween1:Play(); tween2:Play() end)
                table.insert(ActiveTweens, tween1); table.insert(ActiveTweens, tween2)
                AimButton.Text = "🔒"
            else
                local tween1 = TweenService:Create(AimButton, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
                local tween2 = TweenService:Create(AimButtonInner, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
                pcall(function() tween1:Play(); tween2:Play() end)
                table.insert(ActiveTweens, tween1); table.insert(ActiveTweens, tween2)
                AimButton.Text = "🎯"
            end
        end

        if active then startAimbot() else stopAimbot() end
    end

    -- Create Aimlock Button (robust + mobile friendly, smooth dragging)
    local function createAimlockButton()
        if AimGui and AimGui.Parent then return AimGui end

        -- cleanup any old UI named AimlockGUI
        local core = game:GetService("CoreGui")
        for _, child in ipairs(core:GetChildren()) do
            if child.Name == "AimlockGUI" then
                safeDestroy(child)
            end
        end

        -- Only disconnect aim-related connections (AimConns). espHeartbeatConn is NOT in AimConns,
        -- so the ESP heartbeat won't be disconnected here anymore.
        for _, c in pairs(AimConns) do
            pcall(function() c:Disconnect() end)
        end
        AimConns = {}

        AimGui = Instance.new("ScreenGui")
        AimGui.ResetOnSpawn = false
        AimGui.IgnoreGuiInset = true
        -- Use full stealth protection
        if _G.protectGUI then
            _G.protectGUI(AimGui)
        else
            -- Fallback: Try CoreGui first, then PlayerGui
            pcall(function()
                if gethui then
                    AimGui.Parent = gethui()
                else
                    AimGui.Parent = core
                end
            end)
            -- Use stealth name
            AimGui.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("TopBarApp_" .. math.random(10000, 99999))
        end

        local container = Instance.new("Frame")
        -- Use randomized name for child elements too
        container.Name = "Frame_" .. math.random(10000, 99999)
        container.Size = UDim2.new(0, aimButtonSize, 0, aimButtonSize)
        container.Position = UDim2.new(0.5, -aimButtonSize/2, 0.8, -aimButtonSize/2)
        container.BackgroundTransparency = 1
        container.Parent = AimGui

        AimButton = Instance.new("TextButton")
        -- Use randomized name
        AimButton.Name = "Button_" .. math.random(10000, 99999)
        AimButton.Size = UDim2.new(1, 0, 1, 0)
        AimButton.Position = UDim2.new(0, 0, 0, 0)
        AimButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        AimButton.Text = "🎯"
        AimButton.Font = Enum.Font.Roboto
        AimButton.TextSize = math.clamp(aimButtonSize * 0.5, 20, 50)
        AimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        AimButton.AutoButtonColor = false
        AimButton.BorderSizePixel = 0
        AimButton.Parent = container
        AimButton.ZIndex = 10

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 150))
        })
        gradient.Rotation = 45
        gradient.Parent = AimButton

        local shadow = Instance.new("UIStroke")
        shadow.Color = Color3.fromRGB(0, 0, 0)
        shadow.Thickness = 3
        shadow.Transparency = 0.3
        shadow.Parent = AimButton

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = AimButton

        AimButtonInner = Instance.new("Frame")
        -- Use randomized name
        AimButtonInner.Name = "Frame_" .. math.random(10000, 99999)
        AimButtonInner.Size = UDim2.new(1, -10, 1, -10)
        AimButtonInner.Position = UDim2.new(0, 5, 0, 5)
        AimButtonInner.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        AimButtonInner.BorderSizePixel = 0
        AimButtonInner.Parent = AimButton
        AimButtonInner.ZIndex = 9

        local innerGradient = Instance.new("UIGradient")
        innerGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 180))
        })
        innerGradient.Rotation = 45
        innerGradient.Parent = AimButtonInner

        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(0, 10)
        innerCorner.Parent = AimButtonInner

        container.Position = ensureOnScreen(container.Position, aimButtonSize)

        -- Dragging: small threshold to distinguish tap vs drag, smooth position lerp
        local DRAG_THRESHOLD = 6 -- pixels
        local HOLD_TIME = 0.12    -- seconds before movement counts more reliably

        local function onInputChanged(input)
            if not DragInput or input ~= DragInput then return end
            if not DragStartPos or not BtnTargetPos then return end

            local inputPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = inputPos - DragStartPos

            -- decide whether this is a drag
            if not AimBtnDragging and PotentialDrag and delta.Magnitude > DRAG_THRESHOLD and (os.clock() - InputStartTick) > HOLD_TIME then
                AimBtnDragging = true
            end

            if AimBtnDragging then
                local newX = BtnTargetPos.X.Offset + delta.X
                local newY = BtnTargetPos.Y.Offset + delta.Y
                local targetUD = ensureOnScreen(UDim2.new(0, newX, 0, newY), aimButtonSize)
                -- smooth movement using UDim2:Lerp (less jittery than creating many tweens)
                local curr = container.Position
                local lerped = curr:Lerp(targetUD, 0.35)
                container.Position = lerped
            end
        end

        local function onInputEnded(input)
            if input ~= DragInput then return end

            if AimBtnDragging then
                -- finalize drag: snap to on-screen and animate inner back
                AimBtnDragging = false
                DragInput = nil
                DragStartPos = nil
                BtnTargetPos = nil
                PotentialDrag = false

                local snapped = ensureOnScreen(container.Position, aimButtonSize)
                local tween = TweenService:Create(container, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = snapped})
                pcall(function() tween:Play() end)
                table.insert(ActiveTweens, tween)

                local innerTween = TweenService:Create(AimButtonInner, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {Size = UDim2.new(1, -10, 1, -10)})
                pcall(function() innerTween:Play() end)
                table.insert(ActiveTweens, innerTween)
                return
            end

            -- otherwise it's a tap (short press w/o moving) -> toggle
            DragInput = nil
            DragStartPos = nil
            BtnTargetPos = nil
            PotentialDrag = false

            setButtonActive(not AimlockActive)
            if WindUI then
                WindUI:Notify({
                    Title = "Aimlock",
                    Content = AimlockActive and "Aimlock Engaged" or "Aimlock Released",
                    Duration = 2,
                    Icon = AimlockActive and "target" or "x"
                })
            end
        end

        local beginConn = AimButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if DragInput then return end
                DragInput = input
                DragStartPos = Vector2.new(input.Position.X, input.Position.Y)
                BtnTargetPos = container.Position
                InputStartTick = os.clock()
                PotentialDrag = true

                local shrink = TweenService:Create(AimButtonInner, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {Size = UDim2.new(1, -14, 1, -14)})
                pcall(function() shrink:Play() end)
                table.insert(ActiveTweens, shrink)
            end
        end)
        table.insert(AimConns, beginConn)

        local inputChangedConn = UserInputService.InputChanged:Connect(onInputChanged)
        table.insert(AimConns, inputChangedConn)

        local inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)
        table.insert(AimConns, inputEndedConn)

        local viewportConn = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not AimBtnDragging and container and container.Parent then
                container.Position = ensureOnScreen(container.Position, aimButtonSize)
            end
        end)
        table.insert(AimConns, viewportConn)

        local function updateButtonSize(sizePx)
            aimButtonSize = clamp(tonumber(sizePx) or aimButtonSize, 40, 200)
            if container and AimButton then
                container.Size = UDim2.new(0, aimButtonSize, 0, aimButtonSize)
                AimButton.Size = UDim2.new(1, 0, 1, 0)
                AimButtonInner.Size = UDim2.new(1, -10, 1, -10)
                AimButton.TextSize = math.clamp(aimButtonSize * 0.5, 20, 50)
                container.Position = ensureOnScreen(container.Position, aimButtonSize)
            end
        end

        AimGui._updateSize = updateButtonSize
        return AimGui
    end

    local function destroyAimlockButton()
        cancelTweens()
        stopAimbot()

        for _, c in pairs(AimConns) do
            pcall(function() c:Disconnect() end)
        end
        AimConns = {}

        if AimGui and AimGui.Parent then
            safeDestroy(AimGui)
        end
        AimGui = nil
        AimButton = nil
        AimButtonInner = nil
        ListeningForBind = false
        AimlockActive = false
        DragInput = nil
        AimBtnDragging = false
        PotentialDrag = false
    end

    -- Keybind Input (WindUI)
    local keybindInput = nil
    if WindUI then
        keybindInput = HeadlessSection:Input({
            Flag = "Aimlock_Keybind",
            Title = "Aimlock Keybind",
            Desc = "Press a key to set the aimlock keybind.",
            Placeholder = aimKeybind and aimKeybind.Name or "(Touch)",
            Callback = function()
                if ListeningForBind then return end
                ListeningForBind = true
                keybindInput:SetValue("Press a key...")
                local captureConn
                captureConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe or not ListeningForBind then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode then
                        aimKeybind = inp.KeyCode
                        keybindInput:SetValue(aimKeybind.Name)
                    elseif inp.UserInputType == Enum.UserInputType.Touch then
                        aimKeybind = nil
                        keybindInput:SetValue("(Touch)")
                    end
                    ListeningForBind = false
                    pcall(function() captureConn:Disconnect() end)
                end)
                table.insert(AimConns, captureConn)
            end
        })
    end

    -- Keybind handler (works even if GUI not created)
    inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not HeadlessAimlockEnabled then return end
        if aimKeybind and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == aimKeybind then
            setButtonActive(not AimlockActive)
        end
    end)
    table.insert(AimConns, inputConn)

    -- WindUI Integration (Toggles + Sliders)
    if WindUI then
        
        -- Headless Aimbot (ported from Chaos Hub - separate UI + BossFinder loop)
        local _aimbotEnabled = false
        local _aimbotInternalToggle = false
        local _aimbotPrediction = 0.1
        local _aimbotBoss = nil
        local _aimbotBossFinderThread = nil
        local _aimbotRenderConn = nil

        -- Create separate ScreenGui (draggable)
        local _aimGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("HorsemanLockOn_Lander")
        if not _aimGui then
            _aimGui = Instance.new("ScreenGui")
            _aimGui.Name = "HorsemanLockOn_Lander"
            _aimGui.ResetOnSpawn = false
            if _G.protectGUI then _G.protectGUI(_aimGui) else _aimGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        end

        if not _aimGui:FindFirstChild("MainFrame") then
            local f = Instance.new("Frame")
            f.Name = "MainFrame"
            f.Parent = _aimGui
            f.Size = UDim2.new(0, 220, 0, 130)
            f.Position = UDim2.new(0, 50, 0, 150)
            f.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            f.BackgroundTransparency = 0.2
            f.Active = true
            f.Draggable = true
            f.Visible = false
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

            local title = Instance.new("TextLabel")
            title.Parent = f
            title.Size = UDim2.new(1, 0, 0, 32)
            title.Position = UDim2.new(0, 0, 0, 0)
            title.Text = "🎯 Headless Lock-On"
            title.BackgroundTransparency = 1
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextScaled = true
            title.Font = Enum.Font.GothamBold

            local btn = Instance.new("TextButton")
            btn.Name = "Toggle"
            btn.Parent = f
            btn.Size = UDim2.new(0, 90, 0, 32)
            btn.Position = UDim2.new(0, 10, 0, 42)
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.GothamBold
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            local predBox = Instance.new("TextBox")
            predBox.Name = "Prediction"
            predBox.Parent = f
            predBox.Size = UDim2.new(0, 200, 0, 32)
            predBox.Position = UDim2.new(0, 10, 0, 84)
            predBox.Text = "0.1"
            predBox.PlaceholderText = "Prediction (seconds)"
            predBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            predBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            predBox.ClearTextOnFocus = false
            predBox.TextScaled = true
            Instance.new("UICorner", predBox).CornerRadius = UDim.new(0, 8)
        end

        local _f = _aimGui.MainFrame
        local _btn = _f.Toggle
        local _predBox = _f.Prediction

        _btn.MouseButton1Click:Connect(function()
            _aimbotInternalToggle = not _aimbotInternalToggle
            _btn.Text = _aimbotInternalToggle and "ON" or "OFF"
            _btn.BackgroundColor3 = _aimbotInternalToggle and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(40, 40, 40)
        end)

        _predBox.FocusLost:Connect(function()
            local n = tonumber(_predBox.Text)
            if n then _aimbotPrediction = n end
        end)

        local function _startBossFinder()
            if _aimbotBossFinderThread then pcall(task.cancel, _aimbotBossFinderThread) end
            _aimbotBossFinderThread = task.spawn(function()
                while _aimbotEnabled do
                    task.wait(2)
                    if _aimbotInternalToggle then
                        local s = workspace:FindFirstChild("Sleepy Hollow")
                        local m = s and s:FindFirstChild("Modes")
                        local w = m and m:FindFirstChild("Boss")
                        local k = w and w:FindFirstChild("HeadlessHorsemanBoss")
                        _aimbotBoss = k and k:FindFirstChild("HeadlessHorseman")
                    else
                        _aimbotBoss = nil
                    end
                end
                _aimbotBoss = nil
            end)
        end

        local function _startRender()
            if _aimbotRenderConn then _aimbotRenderConn:Disconnect() end
            _aimbotRenderConn = RunService.RenderStepped:Connect(function()
                if not (_aimbotEnabled and _aimbotInternalToggle and _aimbotBoss and _aimbotBoss.Parent) then return end
                local torso = _aimbotBoss:FindFirstChild("Torso") or _aimbotBoss:FindFirstChild("UpperTorso")
                if torso then
                    local cam = workspace.CurrentCamera
                    local predicted = torso.Position + torso.AssemblyLinearVelocity * _aimbotPrediction
                    cam.CFrame = CFrame.new(cam.CFrame.Position, predicted)
                end
            end)
        end

        local function _toggleAimbot(enabled)
            _aimbotEnabled = enabled
            _f.Visible = enabled
            if enabled then
                _startBossFinder()
                _startRender()
            else
                _aimbotInternalToggle = false
                _btn.Text = "OFF"
                _btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                _aimbotBoss = nil
                if _aimbotBossFinderThread then pcall(task.cancel, _aimbotBossFinderThread); _aimbotBossFinderThread = nil end
                if _aimbotRenderConn then _aimbotRenderConn:Disconnect(); _aimbotRenderConn = nil end
            end
        end

        HeadlessSection:Toggle({
            Title = "Headless Aimbot",
            Flag = "Headless_Aimbot_Custom",
            Desc = "Open separate UI for Lock-On Headless Horseman (draggable)",
            Default = false,
            Callback = function(state)
                _toggleAimbot(state)
                WindUI:Notify({
                    Title = "Headless Aimbot",
                    Content = state and "Enabled — press ON in UI to lock" or "Disabled",
                    Duration = 3,
                    Icon = state and "target" or "x",
                })
            end
        })

        HeadlessSection:Slider({
            Title = "Headless Prediction",
            Flag = "Headless_Prediction_Custom",
            Desc = "Adjust prediction to match your ping",
            Step = 0.01,
            Value = {Min = 0, Max = 1, Default = 0.1},
            Callback = function(val)
                _aimbotPrediction = val
                _predBox.Text = tostring(val)
            end
        })

        HeadlessSection:Toggle({
            Title = "Headless Horseman ESP",
            Flag = "Horseman_ESP",
            Desc = "Highlight the Headless Horseman boss.",
            Default = false,
            Callback = function(state)
                HeadlessESPEnabled = state
                WindUI:Notify({
                    Title = "Headless ESP",
                    Content = state and "Headless Horseman ESP Enabled" or "Headless Horseman ESP Disabled",
                    Duration = 2,
                    Icon = state and "eye" or "eye-off",
                })
            end
        })

        HeadlessSection:Toggle({
            Title = "Headless Aimbot",
            Flag = "ESP_1",
            Desc = "Aimlock onto the Headless Horseman.",
            Default = false,
            Callback = function(state)
                HeadlessAimlockEnabled = state

                -- make sure no stale aimbot is running
                setButtonActive(false)

                if state then
                    createAimlockButton()
                    WindUI:Notify({
                        Title = "Headless Aimlock",
                        Content = "Aimlock Enabled",
                        Duration = 3,
                        Icon = "target",
                    })
                else
                    destroyAimlockButton()
                    WindUI:Notify({
                        Title = "Headless Aimlock",
                        Content = "Aimlock Disabled",
                        Duration = 2,
                        Icon = "x",
                    })
                end
            end
        })

        HeadlessSection:Slider({
            Title = "Prediction (Ping in ms)",
            Flag = "Prediction_Ping_in_ms",
            Desc = "Adjust aimlock prediction for ping.",
            Step = 1,
            Value = {Min = 30, Max = 300, Default = manualPing},
            Callback = function(val)
                manualPing = val
            end
        })

        HeadlessSection:Slider({
            Title = "Aim Button Size",
            Flag = "Aim_Button_Size",
            Desc = "On-screen aimlock button size.",
            Step = 1,
            Value = {Min = 40, Max = 200, Default = aimButtonSize},
            Callback = function(val)
                aimButtonSize = val
                if AimGui and AimGui._updateSize then
                    AimGui._updateSize(val)
                end
            end
        })
    end

    -- Auto-disable on death
    local function handleDeath()
        if AimlockActive then
            setButtonActive(false)
            if WindUI then
                WindUI:Notify({
                    Title = "Aimlock",
                    Content = "Aimlock Disabled On Death.",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end
    end

    -- Hook into character if present
    local currentChar = LocalPlayer and LocalPlayer.Character
    if currentChar then
        local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
        if currentHum then
            currentHum.Died:Connect(handleDeath)
            local camera = Workspace.CurrentCamera
            if camera then
                camera.CameraSubject = currentHum
            end
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        local newHum = newChar:WaitForChild("Humanoid", 10)
        if not newHum then return end
        newHum.Died:Connect(handleDeath)

        task.wait(0.1)
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraSubject = newHum
            camera.CameraType = Enum.CameraType.Custom
        end
    end)

    -- Cleanup entrypoint
    local function cleanup()
        destroyAimlockButton()
        stopAimbot()

        -- disconnect aim-related connections
        for _, c in pairs(AimConns) do
            pcall(function() c:Disconnect() end)
        end
        AimConns = {}

        if espHeartbeatConn then
            pcall(function() espHeartbeatConn:Disconnect() end)
            espHeartbeatConn = nil
        end

        if inputConn then
            pcall(function() inputConn:Disconnect() end)
            inputConn = nil
        end

        for model, h in pairs(highlightInstances) do
            safeDestroy(h)
            highlightInstances[model] = nil
        end
    end

    _G.LanderHeadlessAimlockCleanup = cleanup
end -- end of Headless Horseman Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Configs & Theme Tab
    -- ====== WindUI Built-in Config System ======
    -- Uses WindUI's Flag-based auto-save/load system
    -- All UI elements with Flag="..." are automatically saved
    
    local skibiTab = MiscTab -- Profiles goes inside MiscTab

-- ===== WindUI Built-in Config System =====
-- Uses WindUI's ConfigManager which handles file operations internally
-- All UI elements with Flag="..." are automatically saved/loaded

local ConfigManager = Window.ConfigManager
local ConfigSection = skibiTab:Section({
    Title = "Configs",
    Icon = "file-plus",
    Opened = true
})

local profileName = "default"
local selectedProfile = nil
local ConfigDropdown = nil
local overwriteExisting = true

local function notify(title, content, icon, dur)
    if WindUI then
        pcall(function() WindUI:Notify({ Title = title or "Config", Content = content or "", Icon = icon or "save", Duration = dur or 2 }) end)
    end
end

local function GetAllConfigsSafe()
    local ok, list = pcall(function() return ConfigManager:AllConfigs() end)
    if not ok or type(list) ~= "table" then return {} end
    local out = {}
    for _, v in ipairs(list) do table.insert(out, tostring(v)) end
    return out
end

local function RefreshConfigsDropdown()
    local list = GetAllConfigsSafe()
    if selectedProfile and not table.find(list, selectedProfile) then selectedProfile = nil end

    if ConfigDropdown then
        pcall(function()
            if ConfigDropdown.SetValues then ConfigDropdown:SetValues(list); return end
            if ConfigDropdown.SetOptions then ConfigDropdown:SetOptions(list); return end
            if ConfigDropdown.Update then ConfigDropdown:Update(list); return end
            if ConfigDropdown.Refresh then ConfigDropdown:Refresh(list); return end
            ConfigDropdown.Values = list
            ConfigDropdown.Value = selectedProfile or list[1] or nil
        end)
    end
end

-- textbox for entering profile name
ConfigSection:Input({
    Title = "Profile Name",
    Desc = "Config name.",
    Placeholder = "default",
    Callback = function(val)
        if val and tostring(val):match("%S") then
            profileName = tostring(val)
        end
    end
})

-- Save button
ConfigSection:Button({
    Title = "Save Profile",
    Desc = "Save current settings.",
    Callback = function()
        local name = tostring(profileName or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then notify("Config", "Enter a profile name first", "alert-circle", 2); return end

        local existing = GetAllConfigsSafe()
        local exists = table.find(existing, name) ~= nil

        if exists and not overwriteExisting then
            notify("Config", ("Profile '%s' already exists. Enable Overwrite to replace it."):format(name), "alert-circle", 2)
            return
        end

        -- Create config object
        local ok, cfg = pcall(function() return ConfigManager:CreateConfig(name) end)
        if not ok or not cfg then notify("Config", "Failed to create config object", "x", 2); return end

        -- If exists and we want to overwrite, delete first then recreate
        if exists and overwriteExisting then
            pcall(function() cfg:Delete() end)
            local ok2, cfg2 = pcall(function() return ConfigManager:CreateConfig(name) end)
            if ok2 and cfg2 then cfg = cfg2 end
        end

        local suc = pcall(function() cfg:Save() end)
        if suc then
            notify("Config", ("Saved '%s' ✓"):format(name), "check", 2)
            selectedProfile = name
            RefreshConfigsDropdown()
        else
            notify("Config", ("Failed to save '%s'"):format(name), "x", 2)
        end
    end
})

-- Dropdown for selecting profiles
ConfigDropdown = ConfigSection:Dropdown({
    Title = "Saved Profiles",
    Desc = "Select a saved config.",
    Values = GetAllConfigsSafe(),
    Value = GetAllConfigsSafe()[1] or "",
    Callback = function(option)
        selectedProfile = option
    end
})

-- Load button
ConfigSection:Button({
    Title = "Load Selected",
    Desc = "Load selected config.",
    Callback = function()
        if not selectedProfile or tostring(selectedProfile) == "" then 
            notify("Config", "Select a profile first", "alert-circle", 2)
            return 
        end
        
        local ok, cfg = pcall(function() return ConfigManager:CreateConfig(selectedProfile) end)
        if not ok or not cfg then notify("Config", "Failed to create config object", "x", 2); return end
        
        local suc = pcall(function() cfg:Load() end)
        if suc then
            notify("Config", ("Loaded '%s' ✓"):format(selectedProfile), "download", 2)
            RefreshConfigsDropdown()
        else
            notify("Config", ("Failed to load '%s'"):format(selectedProfile), "x", 2)
        end
    end
})

-- Delete button
ConfigSection:Button({
    Title = "Delete Selected",
    Desc = "Delete selected config.",
    Callback = function()
        if not selectedProfile or tostring(selectedProfile) == "" then 
            notify("Config", "Select a profile first", "alert-circle", 2)
            return 
        end
        
        local ok, cfg = pcall(function() return ConfigManager:CreateConfig(selectedProfile) end)
        if not ok or not cfg then notify("Config", "Failed to create config object", "x", 2); return end
        
        local suc = pcall(function() cfg:Delete() end)
        if suc then
            notify("Config", ("Deleted '%s'"):format(selectedProfile), "trash", 2)
            selectedProfile = nil
            RefreshConfigsDropdown()
        else
            notify("Config", ("Failed to delete '%s'"):format(selectedProfile), "x", 2)
        end
    end
})

-- Refresh button
ConfigSection:Button({
    Title = "Refresh List",
    Desc = "Refresh config list.",
    Callback = function()
        RefreshConfigsDropdown()
        notify("Config", "Refreshed list", "refresh-cw", 1.3)
    end
})

-- Overwrite toggle
ConfigSection:Toggle({
    Title = "Overwrite Existing",
    Desc = "Allow overwriting configs with the same name.",
    Value = overwriteExisting,
    Callback = function(val)
        overwriteExisting = val
    end
})

-- Initial population
RefreshConfigsDropdown()

-- === Fixed Theme Tab (use this in place of the previous snippet) ===
local ThemeTab = VisualTab -- Theme goes inside VisualTab

local ThemeSection = ThemeTab:Section({
    Title = "Themes",
    Icon  = "paintbrush",
    Opened = true,
})

-- Normalize a single theme entry -> string
local function NormalizeThemeEntry(e)
    if type(e) == "string" then return e end
    if type(e) == "table" then
        if e.Name and type(e.Name) == "string" then return e.Name end
        if e.name and type(e.name) == "string" then return e.name end
        if e.Title and type(e.Title) == "string" then return e.Title end
        -- fallback to tostring
        return tostring(e)
    end
    return tostring(e)
end

-- Normalize a list (returns array of strings)
local function NormalizeList(list)
    local out = {}
    if not list then return out end
    -- handle dictionary (pairs) vs array (ipairs)
    local seen = {}
    for k, v in pairs(list) do
        local s = NormalizeThemeEntry(v)
        if s and s ~= "" and not seen[s] then
            table.insert(out, s)
            seen[s] = true
        end
    end
    table.sort(out)
    return out
end

-- gather theme names (defensive)
local function GetAvailableThemes()
    local raw = {}
    pcall(function()
        if WindUI and type(WindUI) == "table" then
            -- WindUI.Themes might be a map name->table
            if type(WindUI.Themes) == "table" then
                for name, _ in pairs(WindUI.Themes) do table.insert(raw, name) end
            end
            -- WindUI.GetThemes() might return list of names or tables
            if type(WindUI.GetThemes) == "function" then
                local ok, res = pcall(WindUI.GetThemes)
                if ok and res then
                    if type(res) == "table" then
                        for _, v in ipairs(res) do table.insert(raw, v) end
                        -- also check pairs in case it's a map
                        for k, v in pairs(res) do
                            if tonumber(k) == nil then table.insert(raw, k) end
                        end
                    end
                end
            end
        end
        -- Window-level fallback
        if Window and type(Window.Themes) == "table" then
            for name, _ in pairs(Window.Themes) do table.insert(raw, name) end
        end
    end)
    return NormalizeList(raw)
end

local function GetCurrentThemeName()
    local cur = nil
    pcall(function()
        cur = (Window and Window.Theme) or (WindUI and WindUI.Theme) or (WindUI and WindUI.CurrentTheme)
    end)
    if type(cur) == "table" then
        return NormalizeThemeEntry(cur)
    end
    if cur == nil or cur == "" then
        return nil
    end
    return tostring(cur)
end

-- create/dropdown reference
local ThemeDropdown

local function SafeSetDropdownValues(dropdown, vals)
    if not dropdown then return end
    local normalized = NormalizeList(vals)
    pcall(function()
        if dropdown.SetValues and type(dropdown.SetValues) == "function" then
            dropdown:SetValues(normalized)
            return
        end
        if dropdown.SetOptions and type(dropdown.SetOptions) == "function" then
            dropdown:SetOptions(normalized)
            return
        end
        -- fallback: directly assign
        dropdown.Values = normalized
    end)
end

local function SafeSetDropdownValue(dropdown, val)
    if not dropdown then return end
    local s = NormalizeThemeEntry(val)
    pcall(function()
        if dropdown.SetValue and type(dropdown.SetValue) == "function" then
            dropdown:SetValue(s)
            return
        end
        if dropdown.Set and type(dropdown.Set) == "function" then
            dropdown:Set(s)
            return
        end
        -- fallback
        dropdown.Value = s
    end)
end

-- Create dropdown (initial)
local themes = GetAvailableThemes()
local initial = GetCurrentThemeName() or (themes[1] or "Default")

ThemeDropdown = ThemeSection:Dropdown({
    Title = "Available Themes",
    Flag = "Available_Themes",
    Desc  = "Select a UI theme",
    Values = themes,
    Value  = red,
    Callback = function(selection)
        if not selection then return end
        -- normalize selection (could be table/string)
        local sel = NormalizeThemeEntry(selection)
        local ok, err = pcall(function()
            if WindUI and type(WindUI.SetTheme) == "function" then
                WindUI:SetTheme(sel)
            elseif Window and type(Window.SetTheme) == "function" then
                Window:SetTheme(sel)
            else
                error("No SetTheme function found on WindUI/Window")
            end
        end)
        if ok then
            pcall(function() if WindUI and WindUI.Notify then WindUI:Notify({ Title = "Theme", Content = ("Theme set to %s"):format(sel), Duration = 2, Icon = "sun" }) end end)
            -- reflect change on dropdown
            SafeSetDropdownValue(ThemeDropdown, sel)
        else
            pcall(function() if WindUI and WindUI.Notify then WindUI:Notify({ Title = "Theme", Content = ("Failed to set theme: %s"):format(tostring(err)), Duration = 4, Icon = "alert-triangle" }) end end)
        end
    end
})

-- small refresh button
ThemeSection:Button({
    Title = "Refresh Themes",
    Desc  = "Scan for more themes.",
    Callback = function()
        local newThemes = GetAvailableThemes()
        SafeSetDropdownValues(ThemeDropdown, newThemes)
        local cur = GetCurrentThemeName()
        if cur then SafeSetDropdownValue(ThemeDropdown, cur) end
        pcall(function() if WindUI and WindUI.Notify then WindUI:Notify({ Title = "Theme", Content = "Theme list refreshed", Duration = 1.5, Icon = "refresh-cw" }) end end)
    end
})

-- sync dropdown value on load (best-effort)
task.delay(0.05, function()
    local cur = GetCurrentThemeName()
    if cur then
        SafeSetDropdownValue(ThemeDropdown, cur)
    end
end)

end -- end of Configs & Theme Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Misc Tab (forceful WalkSpeed loop, looped Fullbright & NoFog, removed JumpPower/Heal/Reset)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    -- MiscTab is already declared as the main tab

    -- Sections
    local ServerModifiersSection = MiscTab:Section({
        Title = "Server Modifiers",
        Icon = "shield",
        Opened = false,
    })

    local MovementSection = PlayerTab:Section({ Title = "Movement", Icon = "user", Opened = false })
    local VisualSection   = VisualTab:Section({ Title = "Visual", Icon = "eye", Opened = false })
    local ServerSection   = MiscTab:Section({ Title = "Server Utilities", Icon = "server", Opened = false })

    -- === ANIMATIONS SECTION ===
    local AnimationsSection = MiscTab:Section({ Title = "Animations", Icon = "play", Opened = false })
    
    do -- Animations scope
        local allAnimations = {}
        local animationDropdown = nil
        local animSearchQuery = ""
        local scanStatusParagraph = nil
        local hasInitialScan = false -- PERFORMANCE: Lazy load - don't scan until user interacts
        
        -- Global seen IDs to prevent duplicates across scans
        local globalSeenIds = {}
        
        -- Normalize animation ID for comparison (extract numeric ID)
        local function normalizeAnimIdForScan(id)
            if not id then return nil end
            local numId = tostring(id):match("(%d+)")
            return numId
        end
        
        -- Scan all animations in the game (PERFORMANCE: chunked processing to prevent freezing)
        local function scanAllAnimations()
            local anims = {}
            local seen = {}
            local processedCount = 0
            local CHUNK_SIZE = 200 -- Process 200 instances per frame to prevent freezing
            
            -- Helper to add animation if not seen
            local function addAnim(name, id)
                if not id or id == "" then return end
                local normId = normalizeAnimIdForScan(id)
                if normId and not seen[normId] then
                    seen[normId] = true
                    table.insert(anims, {name = name or "Unknown", id = id, normId = normId})
                end
            end
            
            -- Helper to scan a container with chunking
            local function scanContainer(container)
                pcall(function()
                    local descendants = container:GetDescendants()
                    for i, desc in ipairs(descendants) do
                        pcall(function()
                            if desc:IsA("Animation") and desc.AnimationId and desc.AnimationId ~= "" then
                                addAnim(desc.Name, desc.AnimationId)
                            end
                            -- Check Animator for playing animations
                            if desc:IsA("Animator") then
                                pcall(function()
                                    for _, track in ipairs(desc:GetPlayingAnimationTracks()) do
                                        if track.Animation then
                                            addAnim(track.Animation.Name or "Playing", track.Animation.AnimationId)
                                        end
                                    end
                                end)
                            end
                        end)
                        
                        -- Yield every CHUNK_SIZE instances to prevent freezing
                        processedCount = processedCount + 1
                        if processedCount % CHUNK_SIZE == 0 then
                            task.wait()
                        end
                    end
                end)
            end
            
            -- Scan Workspace (includes all players, models, everything)
            scanContainer(workspace)
            
            -- Scan ReplicatedStorage
            pcall(function() scanContainer(game:GetService("ReplicatedStorage")) end)
            
            -- Scan ReplicatedFirst
            pcall(function() scanContainer(game:GetService("ReplicatedFirst")) end)
            
            -- Scan StarterPlayer
            pcall(function() scanContainer(game:GetService("StarterPlayer")) end)
            
            -- Scan StarterGui
            pcall(function() scanContainer(game:GetService("StarterGui")) end)
            
            -- Scan StarterPack
            pcall(function() scanContainer(game:GetService("StarterPack")) end)
            
            -- Scan Lighting
            pcall(function() scanContainer(game:GetService("Lighting")) end)
            
            -- Scan all player backpacks
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    pcall(function()
                        if player.Backpack then
                            scanContainer(player.Backpack)
                        end
                    end)
                end
            end)
            
            -- Sort alphabetically
            table.sort(anims, function(a, b) return a.name:lower() < b.name:lower() end)
            
            globalSeenIds = seen
            return anims
        end
        
        -- Filter animations based on search query (case-insensitive)
        local function filterAnimations(query)
            if not query or query == "" then
                return allAnimations
            end
            local filtered = {}
            local lowerQuery = query:lower()
            for _, anim in ipairs(allAnimations) do
                if anim.name:lower():find(lowerQuery, 1, true) or anim.id:lower():find(lowerQuery, 1, true) then
                    table.insert(filtered, anim)
                end
            end
            return filtered
        end
        
        -- Get dropdown values from animations
        local function getAnimDropdownValues(anims)
            local values = {}
            for _, anim in ipairs(anims) do
                local shortId = anim.normId and (" [" .. anim.normId:sub(1, 8) .. "]") or ""
                table.insert(values, anim.name .. shortId)
            end
            if #values == 0 then
                table.insert(values, "No animations found")
            end
            return values
        end
        
        -- Lookup table: display name -> animation data
        local animNameToData = {}
        local function updateAnimLookup(anims)
            animNameToData = {}
            for _, anim in ipairs(anims) do
                local shortId = anim.normId and (" [" .. anim.normId:sub(1, 8) .. "]") or ""
                local displayName = anim.name .. shortId
                animNameToData[displayName] = anim
            end
        end
        
        -- PERFORMANCE: Lazy load - don't scan on script load, wait for user interaction
        -- allAnimations starts empty, user must click "Scan Animations" to populate
        
        -- Track playing animation tracks for stopping
        local playingTracks = {}
        
        -- Scan status paragraph
        scanStatusParagraph = AnimationsSection:Paragraph({
            Title = "Animation Count",
            Desc = "Click Scan first to load animations."
        })
        
        -- Rescan button (now the primary way to load animations)
        AnimationsSection:Button({
            Title = "Scan Animations",
            Desc = "Scan game for animations (runs in background).",
            Callback = function()
                -- Show scanning notification
                WindUI:Notify({
                    Title = "Animations",
                    Content = "Scanning animations in background...",
                    Duration = 2,
                    Icon = "loader"
                })
                
                -- Update status to show scanning
                if scanStatusParagraph then
                    pcall(function()
                        scanStatusParagraph:SetDesc("Scanning... please wait")
                    end)
                end
                
                -- Run scan in background thread
                task.spawn(function()
                    allAnimations = scanAllAnimations()
                    updateAnimLookup(allAnimations)
                    hasInitialScan = true
                    
                    -- Update status
                    if scanStatusParagraph then
                        pcall(function()
                            scanStatusParagraph:SetDesc("Found " .. #allAnimations .. " animations")
                        end)
                    end
                    
                    -- Update dropdown with new values
                    if animationDropdown then
                        pcall(function()
                            local values = getAnimDropdownValues(filterAnimations(animSearchQuery))
                            if animationDropdown.SetValues then
                                animationDropdown:SetValues(values)
                            elseif animationDropdown.Refresh then
                                animationDropdown:Refresh(values)
                            end
                        end)
                    end
                    
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "Found " .. #allAnimations .. " unique animations!",
                        Duration = 3,
                        Icon = "check"
                    })
                end) -- end task.spawn
            end
        })
        
        -- Search input
        AnimationsSection:Input({
            Title = "Search Animations",
            Desc = "Filter animations by name or ID.",
            Placeholder = "Type to search...",
            Callback = function(text)
                animSearchQuery = text
                local filtered = filterAnimations(text)
                if animationDropdown then
                    pcall(function()
                        -- Try multiple methods to update dropdown
                        if animationDropdown.SetValues then
                            animationDropdown:SetValues(getAnimDropdownValues(filtered))
                        elseif animationDropdown.Refresh then
                            animationDropdown:Refresh(getAnimDropdownValues(filtered))
                        elseif animationDropdown.UpdateValues then
                            animationDropdown:UpdateValues(getAnimDropdownValues(filtered))
                        end
                    end)
                end
            end
        })
        
        -- Selected animation storage
        local selectedAnimId = nil
        local selectedAnimName = nil
        local loopAnimationEnabled = false
        local loopAnimationTrack = nil
        local loopAnimationConnection = nil
        
        -- Animation details paragraph reference
        local animDetailsParagraph = nil
        
        -- Helper: Get animation duration (requires loading it temporarily)
        local function getAnimationDuration(animId)
            local duration = "Unknown"
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then return end
                
                local anim = Instance.new("Animation")
                anim.AnimationId = animId
                local track = animator:LoadAnimation(anim)
                duration = string.format("%.2fs", track.Length)
                track:Destroy()
                anim:Destroy()
            end)
            return duration
        end
        
        -- Helper: Update animation details paragraph
        local function updateAnimDetails()
            if animDetailsParagraph then
                if selectedAnimName and selectedAnimId then
                    local duration = getAnimationDuration(selectedAnimId)
                    animDetailsParagraph:SetDesc(selectedAnimName .. "\n" .. selectedAnimId .. "\nDuration: " .. duration)
                else
                    animDetailsParagraph:SetDesc("No animation selected")
                end
            end
        end
        
        -- Animation dropdown (starts empty - user must scan first)
        animationDropdown = AnimationsSection:Dropdown({
            Title = "Select Animation",
            Desc = "Choose an animation.",
            Flag = "Select_Animation",
            Multi = false,
            Values = {"Click 'Scan Animations' to load"},
            Callback = function(selected)
                if selected and selected ~= "No animations found" and selected ~= "Click 'Scan Animations' to load" then
                    -- Get animation data from lookup table
                    local animData = animNameToData[selected]
                    if animData then
                        selectedAnimId = animData.id
                        selectedAnimName = animData.name
                        updateAnimDetails()
                    end
                end
            end
        })
        
        -- Animation details paragraph with Copy ID button
        animDetailsParagraph = AnimationsSection:Paragraph({
            Title = "Selected Animation",
            Desc = "No animation selected."
        })
        
        -- Copy ID button
        AnimationsSection:Button({
            Title = "Copy Animation ID",
            Desc = "Copy selected animation ID.",
            Callback = function()
                if selectedAnimId then
                    pcall(function()
                        if setclipboard then
                            setclipboard(selectedAnimId)
                        elseif toclipboard then
                            toclipboard(selectedAnimId)
                        end
                    end)
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "Copied ID to clipboard!",
                        Duration = 2,
                        Icon = "copy"
                    })
                else
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "No animation selected!",
                        Duration = 2,
                        Icon = "alert-circle"
                    })
                end
            end
        })
        
        -- Loop Animation toggle
        AnimationsSection:Toggle({
            Title = "Loop Animation",
            Desc = "Loop selected animation.",
            Default = false,
            Callback = function(state)
                loopAnimationEnabled = state
                if state then
                    if not selectedAnimId then
                        WindUI:Notify({
                            Title = "Animations",
                            Content = "No animation selected!",
                            Duration = 2,
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
                        anim.AnimationId = selectedAnimId
                        loopAnimationTrack = animator:LoadAnimation(anim)
                        loopAnimationTrack.Looped = true
                        loopAnimationTrack:Play()
                        table.insert(playingTracks, loopAnimationTrack)
                        anim:Destroy()
                        
                        WindUI:Notify({
                            Title = "Animations",
                            Content = "Looping animation!",
                            Duration = 2,
                            Icon = "repeat"
                        })
                    end)
                else
                    -- Stop the looping animation
                    if loopAnimationTrack then
                        pcall(function()
                            loopAnimationTrack:Stop()
                        end)
                        loopAnimationTrack = nil
                    end
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "Stopped looping animation!",
                        Duration = 2,
                        Icon = "square"
                    })
                end
            end
        })
        
        -- Play animation button
        AnimationsSection:Button({
            Title = "Play Animation",
            Desc = "Play animation on your character.",
            Callback = function()
                if not selectedAnimId then
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "No animation selected!",
                        Duration = 2,
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
                    anim.AnimationId = selectedAnimId
                    local track = animator:LoadAnimation(anim)
                    track:Play()
                    table.insert(playingTracks, track)
                    anim:Destroy()
                    
                    WindUI:Notify({
                        Title = "Animations",
                        Content = "Playing animation!",
                        Duration = 2,
                        Icon = "play"
                    })
                end)
            end
        })
        
        -- Stop animation button
        AnimationsSection:Button({
            Title = "Stop All Animations",
            Desc = "Stop all animations.",
            Callback = function()
                pcall(function()
                    -- Stop tracked animations
                    for _, track in ipairs(playingTracks) do
                        pcall(function()
                            if track and track.Stop then
                                track:Stop()
                            end
                        end)
                    end
                    playingTracks = {}
                    
                    -- Also stop all animations on humanoid
                    local char = LocalPlayer.Character
                    if char then
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local animator = humanoid:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                    pcall(function() track:Stop() end)
                                end
                            end
                        end
                    end
                end)
                
                WindUI:Notify({
                    Title = "Animations",
                    Content = "Stopped all animations!",
                    Duration = 2,
                    Icon = "square"
                })
            end
        })
    end -- End Animations scope

    -- === CUSTOM ANIMATION ID SECTION ===
    local CustomAnimSection = MiscTab:Section({ Title = "Custom Animation ID", Icon = "link", Opened = false })
    
    do -- Custom Animation scope
        local customAnimId = ""
        local customLoopEnabled = false
        local customAnimTrack = nil
        local customPlayingTracks = {}
        
        -- Input for custom animation ID
        CustomAnimSection:Input({
            Title = "Animation ID",
            Desc = "Enter a custom animation ID.",
            Placeholder = "rbxassetid://...",
            Callback = function(text)
                customAnimId = text
            end
        })
        
        -- Loop toggle for custom animation
        CustomAnimSection:Toggle({
            Title = "Loop Animation",
            Desc = "Loop custom animation.",
            Default = false,
            Callback = function(state)
                customLoopEnabled = state
                if state then
                    if not customAnimId or customAnimId == "" then
                        WindUI:Notify({
                            Title = "Custom Animation",
                            Content = "No animation ID entered!",
                            Duration = 2,
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
                        anim:Destroy()
                        
                        WindUI:Notify({
                            Title = "Custom Animation",
                            Content = "Looping animation!",
                            Duration = 2,
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
                    WindUI:Notify({
                        Title = "Custom Animation",
                        Content = "Stopped looping animation!",
                        Duration = 2,
                        Icon = "square"
                    })
                end
            end
        })
        
        -- Play custom animation button
        CustomAnimSection:Button({
            Title = "Play Animation",
            Desc = "Play custom animation once.",
            Callback = function()
                if not customAnimId or customAnimId == "" then
                    WindUI:Notify({
                        Title = "Custom Animation",
                        Content = "No animation ID entered!",
                        Duration = 2,
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
                    anim:Destroy()
                    
                    WindUI:Notify({
                        Title = "Custom Animation",
                        Content = "Playing animation!",
                        Duration = 2,
                        Icon = "play"
                    })
                end)
            end
        })
        
        -- Stop custom animation button
        CustomAnimSection:Button({
            Title = "Stop Animation",
            Desc = "Stop all custom animations.",
            Callback = function()
                pcall(function()
                    -- Stop tracked custom animations
                    for _, track in ipairs(customPlayingTracks) do
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
                
                WindUI:Notify({
                    Title = "Custom Animation",
                    Content = "Stopped animations!",
                    Duration = 2,
                    Icon = "square"
                })
            end
        })
    end -- End Custom Animation scope

    -- === ANIMATION PRESETS SECTION ===
    local AnimPresetSection = MiscTab:Section({ Title = "Animation Presets", Icon = "film", Opened = false })
    
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
        
        -- Helper function to stop all preset animations
        local function stopAllPresets()
            for name, tracks in pairs(presetPlayingTracks) do
                for _, track in ipairs(tracks) do
                    pcall(function() track:Stop() end)
                end
            end
            presetPlayingTracks = {}
            for name, conn in pairs(presetLoopConnections) do
                pcall(function() 
                    if type(conn) == "thread" then
                        task.cancel(conn)
                    elseif conn.Disconnect then
                        conn:Disconnect()
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
        
        -- Helper function to play idle/walk animation preset
        local function playIdleWalkPreset(name, idleId, walkId, priority, walkSpeed)
            local animator, humanoid = getAnimator()
            if not animator then return end
            
            stopAllPresets()
            presetActiveStates[name] = true
            presetPlayingTracks[name] = {}
            
            -- Create idle animation
            local idleAnim = Instance.new("Animation")
            idleAnim.AnimationId = "rbxassetid://" .. idleId
            local idleTrack = animator:LoadAnimation(idleAnim)
            idleTrack.Priority = priority or Enum.AnimationPriority.Action3
            idleTrack.Looped = true
            table.insert(presetPlayingTracks[name], idleTrack)
            
            -- Create walk animation
            local walkAnim = Instance.new("Animation")
            walkAnim.AnimationId = "rbxassetid://" .. walkId
            local walkTrack = animator:LoadAnimation(walkAnim)
            walkTrack.Priority = priority or Enum.AnimationPriority.Action3
            walkTrack.Looped = true
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
            
            WindUI:Notify({ Title = "Animation Preset", Content = name .. " activated!", Duration = 2, Icon = "play" })
        end
        
        -- Helper function to play one-shot animation
        local function playOneShotPreset(name, animId, duration)
            local animator, humanoid = getAnimator()
            if not animator then return end
            
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. animId
            local track = animator:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action4
            track:Play()
            
            if not presetPlayingTracks[name] then presetPlayingTracks[name] = {} end
            table.insert(presetPlayingTracks[name], track)
            
            if duration then
                task.delay(duration, function()
                    pcall(function() track:Stop() end)
                end)
            end
            
            WindUI:Notify({ Title = "Animation Preset", Content = name .. " playing!", Duration = 2, Icon = "play" })
        end
        
        -- Helper function to play looping one-shot animation
        local function playLoopingPreset(name, animId, interval)
            local animator, humanoid = getAnimator()
            if not animator then return end
            
            stopAllPresets()
            presetActiveStates[name] = true
            presetPlayingTracks[name] = {}
            
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. animId
            local track = animator:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action4
            table.insert(presetPlayingTracks[name], track)
            
            presetLoopConnections[name] = task.spawn(function()
                while presetActiveStates[name] do
                    track:Play()
                    task.wait(interval or track.Length or 1)
                end
            end)
            
            WindUI:Notify({ Title = "Animation Preset", Content = name .. " activated!", Duration = 2, Icon = "play" })
        end
        
        -- Stop All Presets Button
        AnimPresetSection:Button({
            Title = "Stop All Presets",
            Desc = "Stop all presets and restore normal state.",
            Callback = function()
                stopAllPresets()
                WindUI:Notify({ Title = "Animation Preset", Content = "All presets stopped!", Duration = 2, Icon = "square" })
            end
        })
        
        -- ===== ZOMBIE ANIMATIONS =====
        AnimPresetSection:Paragraph({ Title = "━━━ Zombie Animations ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Zapper",
            Desc = "Zapper animation with effect.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                stopAllPresets()
                presetActiveStates["Zapper"] = true
                presetPlayingTracks["Zapper"] = {}
                
                -- Effect animation
                local effectAnim = Instance.new("Animation")
                effectAnim.AnimationId = "rbxassetid://12638401607"
                local effectTrack = animator:LoadAnimation(effectAnim)
                effectTrack.Priority = Enum.AnimationPriority.Action3
                effectTrack.Looped = true
                effectTrack:Play()
                table.insert(presetPlayingTracks["Zapper"], effectTrack)
                
                playIdleWalkPreset("Zapper", "12333488814", "12333490576", Enum.AnimationPriority.Action2, nil)
            end
        })
        
        AnimPresetSection:Button({
            Title = "Zapper Animation",
            Desc = "Standard Zapper animation.",
            Callback = function() playIdleWalkPreset("Zapper", "14498563473", "14498289874", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Zapper Effect",
            Desc = "Play Zapper special effect once.",
            Callback = function() playOneShotPreset("Zapper Effect", "14499470197", nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Shambler Animation",
            Desc = "Shambler idle/walk animation.",
            Callback = function() playIdleWalkPreset("Shambler", "12333488814", "14463730540", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Old Shambler",
            Desc = "Old Shambler animation.",
            Callback = function() playIdleWalkPreset("Old Shambler", "12333488814", "12333490857", Enum.AnimationPriority.Idle, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Shambler Eating",
            Desc = "Shambler eating animation (10 sec).",
            Callback = function() playOneShotPreset("Shambler Eating", "18339432914", 10) end
        })
        
        AnimPresetSection:Button({
            Title = "Lantern",
            Desc = "Lantern zombie animation.",
            Callback = function() playIdleWalkPreset("Lantern", "14678879479", "14678880308", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Cuirassier Animation",
            Desc = "Cuirassier animation.",
            Callback = function() playIdleWalkPreset("Cuirassier", "87579228279296", "102081698785465", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Cuirassier Alt",
            Desc = "Alternate Cuirassier animation.",
            Callback = function() playIdleWalkPreset("Cuirassier Alt", "82800474630427", "118210337289087", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Headless zombie",
            Desc = "Headless zombie animation.",
            Callback = function() playIdleWalkPreset("Headless zombie", "107080941320600", "74764025513892", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Crawler",
            Desc = "Crawling zombie animation.",
            Callback = function() playIdleWalkPreset("Crawler", "13726632691", "13726634549", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Bomber Animation",
            Desc = "Bomber self-destruct animation.",
            Callback = function() playIdleWalkPreset("Bomber Animation", "13211198049", "13211207597", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Default",
            Desc = "Default zombie animation.",
            Callback = function() playIdleWalkPreset("Default", "180435571", "180426354", Enum.AnimationPriority.Idle, nil) end
        })
        
        -- ===== CHARACTER ANIMATIONS =====
        AnimPresetSection:Paragraph({ Title = "━━━ Character Animations ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Boxer",
            Desc = "Boxing animation (click to punch).",
            Callback = function() playIdleWalkPreset("Boxer", "124381258015151", "127477273497271", Enum.AnimationPriority.Action3, 17) end
        })
        
        AnimPresetSection:Button({
            Title = "Dracula",
            Desc = "Dracula animation.",
            Callback = function() playIdleWalkPreset("Dracula", "14970033333", "15486477524", Enum.AnimationPriority.Action3, 16) end
        })
        
        AnimPresetSection:Button({
            Title = "Impaled walk",
            Desc = "Impaled slow walk animation.",
            Callback = function() playIdleWalkPreset("Impaled walk", "111210841378590", "139186204185685", Enum.AnimationPriority.Action3, 5) end
        })
        
        AnimPresetSection:Button({
            Title = "Red Eyes",
            Desc = "Red eyes animation with speed boost (35).",
            Callback = function() playIdleWalkPreset("Red Eyes", "12581784105", "12581785298", Enum.AnimationPriority.Action3, 35) end
        })
        
        AnimPresetSection:Button({
            Title = "Napoleon Hands Behind",
            Desc = "Napoleon hands-behind-back pose.",
            Callback = function() playIdleWalkPreset("Napoleon", "103557875332543", "103557875332543", Enum.AnimationPriority.Action4, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Freezing/Cold",
            Desc = "Cold shivering animation.",
            Callback = function() playIdleWalkPreset("Cold", "16863977222", "16876434500", Enum.AnimationPriority.Action3, nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Low Health",
            Desc = "Injured/low health animation.",
            Callback = function() playIdleWalkPreset("Low Health", "14970034680", "15530089342", Enum.AnimationPriority.Idle, nil) end
        })
        
        -- ===== COMBAT ANIMATIONS =====
        AnimPresetSection:Paragraph({ Title = "━━━ Combat Animations ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Musket Charge",
            Desc = "Musket charge animation (speed 24).",
            Callback = function() playIdleWalkPreset("Musket Charge", "14292935158", "14292937831", Enum.AnimationPriority.Action3, 24) end
        })
        
        AnimPresetSection:Button({
            Title = "Greatsword Charge",
            Desc = "Greatsword charge animation (speed 24).",
            Callback = function() playIdleWalkPreset("Greatsword Charge", "14284611111", "17406602570", Enum.AnimationPriority.Action3, 24) end
        })
        
        AnimPresetSection:Button({
            Title = "Bayonet Charge",
            Desc = "Bayonet charge animation (speed 24).",
            Callback = function() playIdleWalkPreset("Bayonet Charge", "14284611111", "14284623849", Enum.AnimationPriority.Idle, 24) end
        })
        
        AnimPresetSection:Button({
            Title = "Fake Bayonet",
            Desc = "Fake bayonet stance (click to stab).",
            Callback = function() playIdleWalkPreset("Fake Bayonet", "12333492041", "12333492041", Enum.AnimationPriority.Action3, 17) end
        })
        
        AnimPresetSection:Button({
            Title = "Gun Spin",
            Desc = "Spinning gun trick (looping).",
            Callback = function() playLoopingPreset("Gun Spin", "15827239870", 0.73) end
        })
        
        AnimPresetSection:Button({
            Title = "Elbow Strike",
            Desc = "Elbow strike combo (looping).",
            Callback = function() playLoopingPreset("Elbow Strike", "15345113937", 0.6) end
        })
        
        AnimPresetSection:Button({
            Title = "Skibidi Fast Slash Ahhh",
            Desc = "Super fast slash with spin.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                local char = LocalPlayer.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end
                
                stopAllPresets()
                presetActiveStates["Skibidi Fast Slash Ahhh"] = true
                presetPlayingTracks["Skibidi Fast Slash Ahhh"] = {}
                
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://12591938344"
                local track = animator:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action4
                table.insert(presetPlayingTracks["Skibidi Fast Slash Ahhh"], track)
                
                local rotationSpeed = 1440
                
                presetLoopConnections["Skibidi Fast Slash Ahhh"] = task.spawn(function()
                    while presetActiveStates["Skibidi Fast Slash Ahhh"] do
                        track:Play()
                        local deltaTime = task.wait(0.1)
                        if rootPart then
                            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(rotationSpeed * 0.1), 0)
                        end
                    end
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Skibidi Fast Slash Ahhh activated!", Duration = 2, Icon = "play" })
            end
        })
        
        -- ===== SPECIAL ANIMATIONS =====
        AnimPresetSection:Paragraph({ Title = "━━━ Special Animations ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Play Dead",
            Desc = "Play dead/faint animation.",
            Callback = function() playOneShotPreset("Play Dead", "89945348540089", nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Sad Dance",
            Desc = "Sad dance animation (20 sec).",
            Callback = function() playOneShotPreset("Sad Dance", "14860627011", 20) end
        })
        
        AnimPresetSection:Button({
            Title = "Flying",
            Desc = "Flying pose animation (looping).",
            Callback = function() playLoopingPreset("Flying", "110087359963835", nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Headless Horseman",
            Desc = "Headless Horseman animation with music (speed 38).",
            Callback = function()
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
        
        AnimPresetSection:Button({
            Title = "Eating Long Stick",
            Desc = "Eating animation (gagging sounds).",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                presetActiveStates["Eating"] = true
                presetPlayingTracks["Eating"] = {}
                
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://16863982325"
                local track = animator:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action4
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
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Eating activated!", Duration = 2, Icon = "play" })
            end
        })
        
        AnimPresetSection:Button({
            Title = "Cross Use",
            Desc = "Cross animation.",
            Callback = function() playOneShotPreset("Cross Use", "15210536563", nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Zombie Breaking The Door",
            Desc = "Zombie breaking door animation.",
            Callback = function() playOneShotPreset("Door Breach", "15593727441", nil) end
        })
        
        AnimPresetSection:Button({
            Title = "Crawford",
            Desc = "Crawford special animation.",
            Callback = function() playOneShotPreset("Crawford", "77859967130018", nil) end
        })
        
        -- ===== INJURY ANIMATIONS =====
        AnimPresetSection:Paragraph({ Title = "━━━ Injury Animations ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Cuirassier Stabbed",
            Desc = "Stabbed by Cuirassier animation.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                presetActiveStates["CuirassierStabbed"] = true
                presetPlayingTracks["CuirassierStabbed"] = {}
                humanoid.WalkSpeed = 0
                
                local anim1 = Instance.new("Animation")
                anim1.AnimationId = "rbxassetid://121955221153387"
                local track1 = animator:LoadAnimation(anim1)
                track1.Priority = Enum.AnimationPriority.Action4
                table.insert(presetPlayingTracks["CuirassierStabbed"], track1)
                track1:Play()
                
                track1.Stopped:Connect(function()
                    -- Check if preset was stopped manually
                    if not presetActiveStates["CuirassierStabbed"] then
                        humanoid.WalkSpeed = 16
                        return
                    end
                    
                    local anim2 = Instance.new("Animation")
                    anim2.AnimationId = "rbxassetid://111210841378590"
                    local track2 = animator:LoadAnimation(anim2)
                    track2.Priority = Enum.AnimationPriority.Action4
                    track2.Looped = true
                    table.insert(presetPlayingTracks["CuirassierStabbed"], track2)
                    track2:Play()
                    
                    track2.Stopped:Connect(function()
                        if presetActiveStates["CuirassierStabbed"] then
                            presetActiveStates["CuirassierStabbed"] = nil
                            presetPlayingTracks["CuirassierStabbed"] = nil
                        end
                        humanoid.WalkSpeed = 16
                    end)
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Stabbed animation playing!", Duration = 2, Icon = "play" })
            end
        })
        
        AnimPresetSection:Button({
            Title = "Breaking Bones",
            Desc = "Bone breaking animation.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                humanoid.WalkSpeed = 0
                
                local anim1 = Instance.new("Animation")
                anim1.AnimationId = "rbxassetid://12333490324"
                local track1 = animator:LoadAnimation(anim1)
                track1.Priority = Enum.AnimationPriority.Action4
                track1:Play()
                
                track1.Stopped:Connect(function()
                    local anim2 = Instance.new("Animation")
                    anim2.AnimationId = "rbxassetid://12333489072"
                    local track2 = animator:LoadAnimation(anim2)
                    track2.Priority = Enum.AnimationPriority.Action4
                    track2:Play()
                    task.delay(3, function()
                        humanoid.WalkSpeed = 16
                    end)
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Fracture animation playing!", Duration = 2, Icon = "play" })
            end
        })
        
        -- ===== CINEMATIC SEQUENCES =====
        AnimPresetSection:Paragraph({ Title = "━━━ Cinematic Sequences ━━━", Desc = "" })
        
        AnimPresetSection:Button({
            Title = "Blücher",
            Desc = "Blücher cinematic sequence.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                presetActiveStates["Blucher"] = true
                
                -- Stop all current animations
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
                
                local animIds = {"15603033178", "16168689655", "15680560478", "15688743558", "15637342030"}
                local tracks = {}
                
                for i, id in ipairs(animIds) do
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://" .. id
                    tracks[i] = animator:LoadAnimation(anim)
                    tracks[i].Priority = Enum.AnimationPriority.Action4
                end
                
                task.spawn(function()
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
                    
                    presetActiveStates["Blucher"] = false
                    WindUI:Notify({ Title = "Animation Preset", Content = "Blücher sequence complete!", Duration = 2, Icon = "check" })
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Blücher sequence started!", Duration = 2, Icon = "play" })
            end
        })
        
        AnimPresetSection:Button({
            Title = "idk",
            Desc = "Officer cinematic sequence.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                presetActiveStates["Adjutant"] = true
                
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
                
                local animIds = {"15603037116", "15622136729", "15688841016", "15637317651"}
                local tracks = {}
                
                for i, id in ipairs(animIds) do
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://" .. id
                    tracks[i] = animator:LoadAnimation(anim)
                    tracks[i].Priority = Enum.AnimationPriority.Action4
                end
                
                task.spawn(function()
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
                    
                    presetActiveStates["Adjutant"] = false
                    WindUI:Notify({ Title = "Animation Preset", Content = "idk sequence complete!", Duration = 2, Icon = "check" })
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "idk sequence started!", Duration = 2, Icon = "play" })
            end
        })
        
        AnimPresetSection:Button({
            Title = "Barry",
            Desc = "Barry getting bitten cinematic.",
            Callback = function()
                local animator, humanoid = getAnimator()
                if not animator then return end
                
                stopAllPresets()
                presetActiveStates["Barry"] = true
                
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
                
                local animIds = {"14284371664", "14284387207", "14284382730", "14304936421"}
                local tracks = {}
                
                for i, id in ipairs(animIds) do
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://" .. id
                    tracks[i] = animator:LoadAnimation(anim)
                    tracks[i].Priority = Enum.AnimationPriority.Action4
                end
                
                task.spawn(function()
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
                    
                    presetActiveStates["Barry"] = false
                    WindUI:Notify({ Title = "Animation Preset", Content = "Barry sequence complete!", Duration = 2, Icon = "check" })
                end)
                
                WindUI:Notify({ Title = "Animation Preset", Content = "Barry sequence started!", Duration = 2, Icon = "play" })
            end
        })
        
    end -- End Animation Presets scope

    -- === OLD GUARD TEMPORARY SECTION ===
    local OldGuardSection = MiscTab:Section({ Title = "Old Guard Temporary", Icon = "shield", Opened = false })
    
    do -- Old Guard scope
        local ChangeClassEvent = game:GetService("ReplicatedStorage").Events.Regiment.ChangeClass
        
        OldGuardSection:Button({
            Title = "Seaman",
            Desc = "Switch to Seaman (French Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Seaman", 5, "French", "Infantry")
                end)
                WindUI:Notify({
                    Title = "Old Guard",
                    Content = "Changed to Seaman!",
                    Duration = 2,
                    Icon = "anchor"
                })
            end
        })
        
        OldGuardSection:Button({
            Title = "Officer",
            Desc = "Switch to Officer (French Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Officer", 5, "French", "Infantry")
                end)
                WindUI:Notify({
                    Title = "Old Guard",
                    Content = "Changed to Officer!",
                    Duration = 2,
                    Icon = "star"
                })
            end
        })
        
        OldGuardSection:Button({
            Title = "Musician",
            Desc = "Switch to Musician (French Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Musician", 5, "French", "Infantry")
                end)
                WindUI:Notify({
                    Title = "Old Guard",
                    Content = "Changed to Musician!",
                    Duration = 2,
                    Icon = "music"
                })
            end
        })
        
        OldGuardSection:Button({
            Title = "LineInfantry",
            Desc = "Switch to Line Infantry (French).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "LineInfantry", 5, "French", "Infantry")
                end)
                WindUI:Notify({
                    Title = "Old Guard",
                    Content = "Changed to Line Infantry!",
                    Duration = 2,
                    Icon = "users"
                })
            end
        })
        
        OldGuardSection:Button({
            Title = "Sapper",
            Desc = "Switch to Sapper (French Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Sapper", 5, "French", "Infantry")
                end)
                WindUI:Notify({
                    Title = "Old Guard",
                    Content = "Changed to Sapper!",
                    Duration = 2,
                    Icon = "hammer"
                })
            end
        })
    end -- End Old Guard scope

    -- === COLDSTREAM TEMPORARY SECTION (British) ===
    local ColdStreamSection = MiscTab:Section({ Title = "Temporary ColdStream (British)", Icon = "flag", Opened = false })
    
    do -- ColdStream scope
        local ChangeClassEvent = game:GetService("ReplicatedStorage").Events.Regiment.ChangeClass
        
        ColdStreamSection:Button({
            Title = "Seaman",
            Desc = "Switch to Seaman (British Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Seaman", 4, "British", "Infantry")
                end)
                WindUI:Notify({
                    Title = "ColdStream",
                    Content = "Changed to Seaman!",
                    Duration = 2,
                    Icon = "anchor"
                })
            end
        })
        
        ColdStreamSection:Button({
            Title = "Officer",
            Desc = "Switch to Officer (British Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Officer", 4, "British", "Infantry")
                end)
                WindUI:Notify({
                    Title = "ColdStream",
                    Content = "Changed to Officer!",
                    Duration = 2,
                    Icon = "star"
                })
            end
        })
        
        ColdStreamSection:Button({
            Title = "Musician",
            Desc = "Switch to Musician (British Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Musician", 4, "British", "Infantry")
                end)
                WindUI:Notify({
                    Title = "ColdStream",
                    Content = "Changed to Musician!",
                    Duration = 2,
                    Icon = "music"
                })
            end
        })
        
        ColdStreamSection:Button({
            Title = "LineInfantry",
            Desc = "Switch to Line Infantry (British).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "LineInfantry", 4, "British", "Infantry")
                end)
                WindUI:Notify({
                    Title = "ColdStream",
                    Content = "Changed to Line Infantry!",
                    Duration = 2,
                    Icon = "users"
                })
            end
        })
        
        ColdStreamSection:Button({
            Title = "Sapper",
            Desc = "Switch to Sapper (British Infantry).",
            Callback = function()
                pcall(function()
                    _G.SafeFireServer(ChangeClassEvent, "Sapper", 4, "British", "Infantry")
                end)
                WindUI:Notify({
                    Title = "ColdStream",
                    Content = "Changed to Sapper!",
                    Duration = 2,
                    Icon = "hammer"
                })
            end
        })
    end -- End ColdStream scope

    -- === WalkSpeed forcing ===
    desiredWalkSpeed = 16 -- Global for keybind access
    walkLoopEnabled = false -- Global for keybind access
    local heartbeatConn = nil
    -- Use weak keys so entries for destroyed humanoids are garbage collected
    local humPropConns = setmetatable({}, { __mode = "k" }) -- [Humanoid] = connection

    local function safeSetWalk(hum, speed)
        if not (hum and hum.Parent) then return end
        pcall(function()
            hum.WalkSpeed = speed
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
        for hum, conn in pairs(humPropConns) do
            pcall(function() conn:Disconnect() end)
        end
        humPropConns = setmetatable({}, { __mode = "k" })
    end

    function startWalkForceLoop() -- Global for keybind access
        if heartbeatConn then heartbeatConn:Disconnect() end
        -- PERF: Throttle to every 0.5s instead of every frame.
        -- GetPropertyChangedSignal already handles instant reactive resets.
        local _walkForceLastCheck = 0
        heartbeatConn = RunService.Heartbeat:Connect(function()
            if not walkLoopEnabled then return end
            local now = os.clock()
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
        LocalPlayer.CharacterAdded:Connect(function(char)
            -- wait briefly for humanoid to exist
            task.wait(0.15)
            if walkLoopEnabled then
                attachToCharacter(char)
                startWalkForceLoop()
            end
        end)
    end

    -- Movement UI: slider max 35 (does NOT immediately apply - waits for toggle)
    MovementSection:Slider({
        Title = "WalkSpeed",
        Flag = "WalkSpeed",
        Desc = "Set walk speed value.",
        Step = 1,
        Value = { Min = 16, Max = 35, Default = desiredWalkSpeed },
        Callback = function(v)
            desiredWalkSpeed = math.clamp(tonumber(v) or desiredWalkSpeed, 16, 35)
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

    local ApplyWalkSpeedToggle = MovementSection:Toggle({
        Title = "WalkSpeed Freeze",
        Flag = "WalkSpeed_Freeze",
        Desc = "Force walk speed.",
        Default = false,
        Callback = function(state)
            walkLoopEnabled = state
            if state then
                -- attach to current character, start heartbeat enforcement
                if LocalPlayer and LocalPlayer.Character then attachToCharacter(LocalPlayer.Character) end
                startWalkForceLoop()
                WindUI:Notify({ Title = "Movement", Content = "WalkSpeed enabled.", Duration = 2, Icon = "check" })
            else
                stopWalkForceLoop()
                WindUI:Notify({ Title = "Movement", Content = "WalkSpeed disabled.", Duration = 2, Icon = "x" })
            end
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.ApplyWalkSpeed = ApplyWalkSpeedToggle

-- ===== FLY FEATURE (Freecam with Soul Clone) =====
-- Freecam fly with transparent soul clone that looks where camera is looking
do
    -- State variables
    local freecamEnabled = false
    local flySpeed = 50
    local soulTransparency = 0.6
    local soulHoverPosition = Vector3.new()
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
    local moveDir = Vector3.new()
    
    -- Connections
    local flyRenderConn = nil
    local flyHeartbeatConn = nil
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
        if not camera then moveDir = Vector3.new(); return end
        
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)
        
        local direction = Vector3.new()
        
        if keysHeld.W then direction = direction + forward end
        if keysHeld.S then direction = direction - forward end
        if keysHeld.A then direction = direction - right end
        if keysHeld.D then direction = direction + right end
        if keysHeld.Space then direction = direction + up end
        if keysHeld.Shift then direction = direction - up end
        
        if direction.Magnitude > 0.1 then
            moveDir = direction.Unit * flySpeed
        else
            moveDir = Vector3.new()
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
        soulModel.Size = Vector3.new(4, 4, 4)
        soulModel.Position = position
        soulModel.Anchored = true
        soulModel.CanCollide = false
        soulModel.Material = Enum.Material.Neon
        soulModel.Color = Color3.fromRGB(50, 150, 255)
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
            WindUI:Notify({ Title = "Loop Teleport", Content = "Select a position from dropdown first!", Duration = 3, Icon = "alert-circle" })
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
            rootPart.CFrame = CFrame.new(position) * currentRot
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
        rootPart.AssemblyLinearVelocity = Vector3.new()
        rootPart.AssemblyAngularVelocity = Vector3.new()
        
        -- Create invisible camera subject for freecam
        soulCameraSubject = Instance.new("Part")
        -- Use randomized name for anti-detection
        soulCameraSubject.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("Part_" .. math.random(10000, 99999))
        soulCameraSubject.Size = Vector3.new(1, 1, 1)
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
        
        return true
    end
    
    -- Stop freecam mode
    local function stopFreecam()
        freecamEnabled = false
        
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
        for k in pairs(keysHeld) do keysHeld[k] = false end
        moveDir = Vector3.new()
    end
    
    -- Refresh dropdown with saved positions
    local function refreshDropdown()
        if TeleportDropdown then
            local names = {}
            for _, p in ipairs(savedPositions) do
                table.insert(names, p.name)
            end
            pcall(function() TeleportDropdown:Refresh(names) end)
        end
    end
    
    -- Save current position (saves soul position)
    local function saveCurrentPosition()
        if not freecamEnabled then
            WindUI:Notify({ Title = "Save Position", Content = "Enable Freecam first to scout and save positions!", Duration = 3, Icon = "alert-circle" })
            return
        end
        
        local pos = soulHoverPosition
        local name = "Pos " .. (#savedPositions + 1)
        table.insert(savedPositions, { name = name, position = pos })
        
        WindUI:Notify({ 
            Title = "Position Saved", 
            Content = string.format("%s: (%.0f, %.0f, %.0f)", name, pos.X, pos.Y, pos.Z), 
            Duration = 3, 
            Icon = "map-pin" 
        })
        
        -- Refresh dropdown
        refreshDropdown()
    end
    
    -- Main update loops
    local function setupFlyLoops()
        if flyRenderConn then flyRenderConn:Disconnect() end
        if flyHeartbeatConn then flyHeartbeatConn:Disconnect() end
        
        -- RenderStepped for smooth visual updates
        flyRenderConn = RunService.RenderStepped:Connect(function()
            -- Always recalculate movement direction based on current camera
            if freecamEnabled then
                updateMoveDir()
                updateSoulModel()
            end
        end)
        
        -- Heartbeat for physics updates
        flyHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
            if not freecamEnabled or not soulCameraSubject then return end
            
            pcall(function()
                -- Move the camera subject (freecam)
                if moveDir.Magnitude > idleThreshold then
                    soulCameraSubject.CFrame = soulCameraSubject.CFrame + moveDir * dt
                    soulHoverPosition = soulCameraSubject.Position
                else
                    soulCameraSubject.CFrame = CFrame.new(soulHoverPosition) * soulCameraSubject.CFrame.Rotation
                end
            end)
        end)
    end
    
    -- Setup input handlers
    local function setupFlyInput()
        if flyInputBeganConn then flyInputBeganConn:Disconnect() end
        if flyInputEndedConn then flyInputEndedConn:Disconnect() end
        
        -- Mobile thumbstick tracking
        local thumbstickMoveDir = Vector3.new()
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
                return Vector3.new()
            end)
            return success and moveVector or Vector3.new()
        end
        
        -- Update movement direction including mobile input
        local originalUpdateMoveDir = updateMoveDir
        updateMoveDir = function()
            local camera = workspace.CurrentCamera
            if not camera then moveDir = Vector3.new(); return end
            
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local up = Vector3.new(0, 1, 0)
            
            local direction = Vector3.new()
            
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
                    -- Convert thumbstick input to camera-relative movement
                    -- mobileMove.X = left/right, mobileMove.Z = forward/back
                    direction = direction + (right * mobileMove.X)
                    direction = direction + (forward * -mobileMove.Z) -- Negative because Z is inverted
                end
            end
            
            if direction.Magnitude > 0.1 then
                moveDir = direction.Unit * flySpeed
            else
                moveDir = Vector3.new()
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
                -- Check if this is the jump button area (usually bottom right)
                -- We'll use a simpler approach - any touch that triggers Jump action
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
            table.insert(_G.FreecamMobileConns or {}, jumpConn)
            _G.FreecamMobileConns = _G.FreecamMobileConns or {}
            table.insert(_G.FreecamMobileConns, jumpConn)
        end
    end
    
    -- Initialize
    setupFlyLoops()
    setupFlyInput()
    
    -- Clean up on character respawn
    LocalPlayer.CharacterAdded:Connect(function()
        if freecamEnabled then
            stopFreecam()
            pcall(function() if FreecamToggle then FreecamToggle:SetValue(false) end end)
        end
        stopTeleportLoop()
        pcall(function() if LoopTeleportToggle then LoopTeleportToggle:SetValue(false) end end)
    end)
    
    -- ===== UI ELEMENTS =====
    
    -- Freecam Toggle
    FreecamToggle = MovementSection:Toggle({
        Title = "Freecam Fly",
        Flag = "Freecam_Fly",
        Desc = "Fly with Freecam to save positions.",
        Default = false,
        Callback = function(state)
            if state then
                local success = startFreecam()
                if success then
                    WindUI:Notify({ Title = "Freecam", Content = "Flying.", Duration = 4, Icon = "ghost" })
                else
                    WindUI:Notify({ Title = "Freecam", Content = "Failed", Duration = 3, Icon = "x" })
                    pcall(function() FreecamToggle:SetValue(false) end)
                end
            else
                stopFreecam()
                WindUI:Notify({ Title = "Freecam", Content = "Freecam disabled", Duration = 2, Icon = "x" })
            end
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.Freecam = FreecamToggle
    
    -- Fly Speed Slider
    MovementSection:Slider({
        Title = "Fly Speed",
        Flag = "Freecam",
        Desc = "Freecam fly speed.",
        Step = 1,
        Value = {
            Min = 10,
            Max = 200,
            Default = 25,
        },
        Callback = function(value)
            flySpeed = value
        end
    })
    
    -- Save Position Button
    MovementSection:Button({
        Title = "Save Position",
        Desc = "Save current position (requires Freecam).",
        Callback = function()
            saveCurrentPosition()
        end
    })
    
    -- Select Position Dropdown (just selects, doesn't teleport)
    TeleportDropdown = MovementSection:Dropdown({
        Title = "Select Position",
        Flag = "Save_Position",
        Desc = "Select a saved position.",
        Values = {},
        Multi = false,
        Callback = function(selected)
            if not selected or type(selected) ~= "string" or selected == "" then 
                selectedPositionIndex = nil
                return 
            end
            
            for i, posData in ipairs(savedPositions) do
                if posData.name == selected then
                    selectedPositionIndex = i
                    WindUI:Notify({ Title = "Selected", Content = posData.name .. " selected for teleport", Duration = 2, Icon = "check" })
                    break
                end
            end
        end
    })
    
    -- Loop Teleport Toggle
    LoopTeleportToggle = MovementSection:Toggle({
        Title = "Loop Teleport",
        Flag = "Selected",
        Desc = "Loop teleport to selected position.",
        Default = false,
        Callback = function(state)
            if state then
                -- Exit freecam if active
                if freecamEnabled then
                    stopFreecam()
                    pcall(function() FreecamToggle:SetValue(false) end)
                end
                
                local success = startTeleportLoop()
                if success then
                    WindUI:Notify({ Title = "Loop Teleport", Content = "Looping to " .. savedPositions[selectedPositionIndex].name, Duration = 3, Icon = "repeat" })
                else
                    pcall(function() LoopTeleportToggle:SetValue(false) end)
                end
            else
                stopTeleportLoop()
                WindUI:Notify({ Title = "Loop Teleport", Content = "Loop stopped", Duration = 2, Icon = "x" })
            end
        end
    })
    _G.LanderToggleElements.LoopTeleport = LoopTeleportToggle
    
    -- Clear Saved Positions Button
    MovementSection:Button({
        Title = "Clear All Saved Positions",
        Desc = "Delete all saved positions.",
        Callback = function()
            stopTeleportLoop()
            pcall(function() LoopTeleportToggle:SetValue(false) end)
            savedPositions = {}
            selectedPositionIndex = nil
            
            -- Clear dropdown
            refreshDropdown()
            
            WindUI:Notify({ Title = "Cleared", Content = "All saved positions deleted", Duration = 2, Icon = "trash-2" })
        end
    })

    -- === SHARED MUSIC SYSTEM VARIABLES (used by both Presets and Background Music sections) ===
    local currentMusicSound = nil
    local musicEnabled = false
    local musicVolume = 0.5
    local scannedAudioList = {}
    local musicDropdown = nil
    local musicSearchQuery = ""
    local audioNameToData = {}
    local selectedAudioData = nil

    local function getMusicSound()
        if not currentMusicSound or not currentMusicSound.Parent then
            currentMusicSound = Instance.new("Sound")
            currentMusicSound.Name = "BackgroundMusic_Lander"
            currentMusicSound.Parent = game:GetService("SoundService")
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
    for _, preset in ipairs(MUSIC_PRESETS) do
        table.insert(presetDropdownValues, preset.name)
        presetNameToData[preset.name] = preset
    end

    local selectedPreset = nil
    local MusicPresetsSection = MiscTab:Section({ Title = "Music Presets", Icon = "disc", Opened = false })

    MusicPresetsSection:Dropdown({
        Title = "Select Preset",
        Desc = "Choose a preset track.",
        Flag = "Music_Presets",
        Multi = false,
        Values = presetDropdownValues,
        Callback = function(selected)
            if selected and presetNameToData[selected] then
                selectedPreset = presetNameToData[selected]
            end
        end
    })

    MusicPresetsSection:Button({
        Title = "▶️ Play Preset",
        Desc = "Play selected track.",
        Callback = function()
            if selectedPreset then
                pcall(function()
                    local sound = getMusicSound()
                    sound.SoundId = "rbxassetid://" .. selectedPreset.id
                    sound.Volume = musicVolume
                    sound:Play()
                    selectedAudioData = {name = selectedPreset.name, id = tonumber(selectedPreset.id)}
                    musicEnabled = true
                    WindUI:Notify({Title = "Music Presets", Content = "Playing: " .. selectedPreset.name, Duration = 3, Icon = "music"})
                end)
            else
                WindUI:Notify({Title = "Music Presets", Content = "Select a preset first!", Duration = 3, Icon = "alert-circle"})
            end
        end
    })

    MusicPresetsSection:Button({
        Title = "⏹️ Stop All Music",
        Desc = "Stop all sounds in the game.",
        Callback = function()
            pcall(function()
                if currentMusicSound and currentMusicSound.Parent then
                    currentMusicSound:Stop()
                end
                musicEnabled = false
                selectedAudioData = nil
                selectedPreset = nil
                local function stopAllSounds(parent)
                    for _, child in ipairs(parent:GetDescendants()) do
                        if child:IsA("Sound") then
                            pcall(function() child:Stop() end)
                        end
                    end
                end
                stopAllSounds(game:GetService("Workspace"))
                stopAllSounds(game:GetService("SoundService"))
            end)
            WindUI:Notify({Title = "Music Presets", Content = "All music stopped!", Duration = 3, Icon = "volume-x"})
        end
    })

    -- === BACKGROUND MUSIC SYSTEM (Game Audio Scanner) ===
    local BackgroundMusicSection = MiscTab:Section({ Title = "Background Music", Icon = "music", Opened = false })
    
    -- Function to extract audio ID
    local function extractAudioId(soundIdString)
        if not soundIdString or soundIdString == "" then return nil end
        local id = string.match(soundIdString, "rbxassetid://(%d+)")
        if id then return tonumber(id) end
        id = string.match(soundIdString, "^(%d+)$")
        if id then return tonumber(id) end
        return nil
    end
    
    -- Get dropdown values
    local function getMusicDropdownValues(audioList)
        local values = {}
        audioNameToData = {}
        for i, audio in ipairs(audioList) do
            local displayName = audio.name .. " (ID: " .. audio.id .. ")"
            table.insert(values, displayName)
            audioNameToData[displayName] = audio
        end
        if #values == 0 then
            values = {"No audio found"}
        end
        return values
    end
    
    -- Filter audio
    local function filterAudio(query)
        if not query or query == "" then return scannedAudioList end
        local filtered = {}
        local lowerQuery = string.lower(query)
        for _, audio in ipairs(scannedAudioList) do
            local lowerName = string.lower(audio.name)
            local idStr = tostring(audio.id)
            if string.find(lowerName, lowerQuery, 1, true) or string.find(idStr, query, 1, true) then
                table.insert(filtered, audio)
            end
        end
        return filtered
    end
    
    -- Scan for audio
    local function scanGameAudio()
        scannedAudioList = {}
        local foundSounds = {}
        pcall(function()
            for _, sound in pairs(workspace:GetDescendants()) do
                if sound:IsA("Sound") and sound.SoundId ~= "" then
                    local audioId = extractAudioId(sound.SoundId)
                    if audioId and not foundSounds[audioId] then
                        foundSounds[audioId] = true
                        table.insert(scannedAudioList, {name = sound.Name, id = audioId, location = sound:GetFullName()})
                    end
                end
            end
            for _, sound in pairs(game:GetService("SoundService"):GetDescendants()) do
                if sound:IsA("Sound") and sound.SoundId ~= "" then
                    local audioId = extractAudioId(sound.SoundId)
                    if audioId and not foundSounds[audioId] then
                        foundSounds[audioId] = true
                        table.insert(scannedAudioList, {name = sound.Name, id = audioId, location = sound:GetFullName()})
                    end
                end
            end
            pcall(function()
                for _, sound in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if sound:IsA("Sound") and sound.SoundId ~= "" then
                        local audioId = extractAudioId(sound.SoundId)
                        if audioId and not foundSounds[audioId] then
                            foundSounds[audioId] = true
                            table.insert(scannedAudioList, {name = sound.Name, id = audioId, location = sound:GetFullName()})
                        end
                    end
                end
            end)
        end)
        return #scannedAudioList
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
            WindUI:Notify({Title = "Background Music", Content = "Playing: " .. audioData.name, Duration = 2, Icon = "music"})
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
    
    -- Info
    BackgroundMusicSection:Paragraph({
        Title = "How to Use",
        Desc = "Click Scan first to load audio."
    })
    
    -- Scan button
    BackgroundMusicSection:Button({
        Title = "Scan Game Audio",
        Desc = "Scan game audio (runs in background).",
        Callback = function()
            WindUI:Notify({Title = "Background Music", Content = "Scanning...", Duration = 2, Icon = "search"})
            task.spawn(function()
                local count = scanGameAudio()
                if musicDropdown then
                    pcall(function()
                        local values = getMusicDropdownValues(filterAudio(musicSearchQuery))
                        if musicDropdown.SetValues then
                            musicDropdown:SetValues(values)
                        elseif musicDropdown.Refresh then
                            musicDropdown:Refresh(values)
                        end
                    end)
                end
                WindUI:Notify({Title = "Background Music", Content = "Found " .. count .. " audio files!", Duration = 3, Icon = "check"})
            end)
        end
    })
    
    -- Search
    BackgroundMusicSection:Input({
        Title = "Search Audio",
        Desc = "Filter audio by name or ID.",
        Placeholder = "Type to search...",
        Callback = function(text)
            musicSearchQuery = text
            local filtered = filterAudio(text)
            if musicDropdown then
                pcall(function()
                    if musicDropdown.SetValues then
                        musicDropdown:SetValues(getMusicDropdownValues(filtered))
                    elseif musicDropdown.Refresh then
                        musicDropdown:Refresh(getMusicDropdownValues(filtered))
                    end
                end)
            end
        end
    })
    
    -- Dropdown
    musicDropdown = BackgroundMusicSection:Dropdown({
        Title = "Select Audio",
        Desc = "Choose audio to play.",
        Flag = "Select_Audio",
        Multi = false,
        Values = {"Click 'Scan Game Audio' to load"},
        Callback = function(selected)
            if selected and selected ~= "No audio found" and selected ~= "Click 'Scan Game Audio' to load" then
                local audioData = audioNameToData[selected]
                if audioData then
                    selectedAudioData = audioData
                    if musicEnabled then
                        playMusic(audioData)
                    else
                        WindUI:Notify({Title = "Background Music", Content = "Selected: " .. audioData.name, Duration = 2, Icon = "music"})
                    end
                end
            end
        end
    })
    
    -- Selected audio info
    BackgroundMusicSection:Paragraph({
        Title = "Selected Audio",
        Desc = "No audio selected."
    })

    -- Custom ID input
    local customAudioId = ""

    BackgroundMusicSection:Paragraph({
        Title = "Custom Audio ID",
        Desc = "Enter a Roblox audio asset ID."
    })

    BackgroundMusicSection:Input({
        Title = "Audio ID",
        Desc = "Paste audio ID (numbers only).",
        Placeholder = "e.g. 1836635087",
        Callback = function(text)
            customAudioId = text:match("^%s*(.-)%s*$") -- trim whitespace
        end
    })

    BackgroundMusicSection:Button({
        Title = "▶️ Play Custom ID",
        Desc = "Play the entered audio ID.",
        Callback = function()
            local id = customAudioId:match("rbxassetid://(%d+)") or customAudioId:match("^(%d+)$")
            if id and id ~= "" then
                pcall(function()
                    local sound = getMusicSound()
                    sound.SoundId = "rbxassetid://" .. id
                    sound.Volume = musicVolume
                    sound:Play()
                    selectedAudioData = {name = "Custom ID: " .. id, id = tonumber(id)}
                    musicEnabled = true
                    WindUI:Notify({Title = "Background Music", Content = "Playing Custom ID: " .. id, Duration = 3, Icon = "music"})
                end)
            else
                WindUI:Notify({Title = "Background Music", Content = "Enter a valid audio ID first!", Duration = 3, Icon = "alert-circle"})
            end
        end
    })

    -- Enable toggle
    BackgroundMusicSection:Toggle({
        Title = "Enable Background Music",
        Flag = "Background_Music",
        Desc = "Play selected background music.",
        Default = false,
        Callback = function(state)
            musicEnabled = state
            if state then
                if #scannedAudioList == 0 then
                    WindUI:Notify({Title = "Background Music", Content = "Please scan first!", Duration = 3, Icon = "alert-circle"})
                    return
                end
                if selectedAudioData then
                    playMusic(selectedAudioData)
                end
            else
                stopMusic()
                WindUI:Notify({Title = "Background Music", Content = "Stopped", Duration = 2, Icon = "music"})
            end
        end
    })
    
    -- Volume
    BackgroundMusicSection:Slider({
        Title = "Volume",
        Flag = "Background_Music_1",
        Desc = "Adjust volume (0-100%).",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 50 },
        Callback = function(value)
            updateVolume(value / 100)
        end
    })
    
    -- Pause/Resume
    BackgroundMusicSection:Button({
        Title = "⏸️ Pause",
        Desc = "Pause music.",
        Callback = function()
            if currentMusicSound and currentMusicSound.Parent then
                currentMusicSound:Pause()
                WindUI:Notify({Title = "Background Music", Content = "Paused", Duration = 2, Icon = "pause"})
            end
        end
    })
    
    BackgroundMusicSection:Button({
        Title = "▶️ Resume",
        Desc = "Resume music.",
        Callback = function()
            if currentMusicSound and currentMusicSound.Parent then
                currentMusicSound:Resume()
                WindUI:Notify({Title = "Background Music", Content = "Resumed", Duration = 2, Icon = "play"})
            end
        end
    })

    BackgroundMusicSection:Button({
        Title = "📋 Copy Audio ID",
        Desc = "Copy current audio ID.",
        Callback = function()
            if selectedAudioData and selectedAudioData.id then
                setclipboard(tostring(selectedAudioData.id))
                WindUI:Notify({Title = "Background Music", Content = "Copied ID: " .. tostring(selectedAudioData.id), Duration = 3, Icon = "clipboard"})
            elseif currentMusicSound and currentMusicSound.Parent and currentMusicSound.SoundId ~= "" then
                local id = extractAudioId(currentMusicSound.SoundId)
                if id then
                    setclipboard(tostring(id))
                    WindUI:Notify({Title = "Background Music", Content = "Copied ID: " .. tostring(id), Duration = 3, Icon = "clipboard"})
                else
                    WindUI:Notify({Title = "Background Music", Content = "No audio ID found!", Duration = 3, Icon = "alert-circle"})
                end
            else
                WindUI:Notify({Title = "Background Music", Content = "No audio selected!", Duration = 3, Icon = "alert-circle"})
            end
        end
    })

    -- Cleanup
    game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
        cleanupMusic()
    end)
end
-- ===== END FLY FEATURE =====

-- Auto Remove Horses (Performance boost)
AutoRemoveHorsesEnabled = false -- Global for keybind access
local autoRemoveConn = nil
local removeTicker = 0

local function removeHorsesOnce()
    -- Saint Petersburg: workspace["Saint Petersburg"].Modes.Holdout.HorseCarriage.Horses
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

    -- Westminster: workspace.Westminster.Modes.Objective.SecondWagon.Wagon.Horses
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

local AutoRemoveHorsesToggle = VisualSection:Toggle({
    Title = "Auto Remove Horses (Performance boost)",
    Flag = "Auto_Remove_Horses_Performance_boost",
    Desc = "Remove horses to reduce lag (Westminster).",
    Default = false,
    Callback = function(state)
        AutoRemoveHorsesEnabled = state
        if state then
            -- immediate attempt
            pcall(removeHorsesOnce)

            -- connect heartbeat to keep removing (runs roughly once/second)
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
                if WindUI and WindUI.Notify then
                    WindUI:Notify({ Title = "Visual", Content = "Auto Remove Horses enabled", Duration = 2, Icon = "trash" })
                end
            end)
        else
            -- disable
            if autoRemoveConn then
                pcall(function() autoRemoveConn:Disconnect() end)
                autoRemoveConn = nil
            end
            pcall(function()
                if WindUI and WindUI.Notify then
                    WindUI:Notify({ Title = "Visual", Content = "Auto Remove Horses disabled", Duration = 2, Icon = "trash-off" })
                end
            end)
        end
    end
})
_G.LanderToggleElements = _G.LanderToggleElements or {}
_G.LanderToggleElements.AutoRemoveHorses = AutoRemoveHorsesToggle

-- === Simplified Visuals: Fullbright & NoFog (IMPROVED & OPTIMIZED) ===
local Lighting = game:GetService("Lighting")

local fullbrightEnabled = false
local noFogEnabled = false

-- Save originals for restoration with better error handling
local originalLighting = {}
local atmosphereBackup = {} -- Store removed atmospheres for restoration

-- Initialize original values with error handling
local function saveOriginalLighting()
    local success, err = pcall(function()
        originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
    end)
    if not success then
        warn("[Visual Fix] Failed to save original lighting:", err)
    end
end

saveOriginalLighting()

-- IMPROVED: Fullbright now works independently from NoFog
local function applyFullbright()
    local success, err = pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        -- Only set FogEnd if NoFog is NOT enabled (independent control)
        if not noFogEnabled then
            Lighting.FogEnd = 100000
        end
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    if not success then
        warn("[Visual Fix] Fullbright apply failed:", err)
        WindUI:Notify({ Title = "Visual Error", Content = "Fullbright failed to apply", Duration = 3, Icon = "alert-triangle" })
    end
end

local function restoreFullbright()
    local success, err = pcall(function()
        Lighting.Brightness = originalLighting.Brightness or 1
        Lighting.ClockTime = originalLighting.ClockTime or 14
        -- Only restore FogEnd if NoFog is NOT enabled (independent control)
        if not noFogEnabled then
            Lighting.FogEnd = originalLighting.FogEnd or 100000
        end
        Lighting.GlobalShadows = originalLighting.GlobalShadows ~= nil and originalLighting.GlobalShadows or true
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(127, 127, 127)
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
        for _, v in pairs(Lighting:GetDescendants()) do
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
        WindUI:Notify({ Title = "Visual Error", Content = "NoFog failed to apply", Duration = 3, Icon = "alert-triangle" })
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
        for _, backup in ipairs(atmosphereBackup) do
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

-- CONTINUOUS NOFOG MONITOR (handles map resets)
local noFogMonitorConn = nil
local lastMapCheck = 0
local MAP_CHECK_INTERVAL = 15 -- Check every 15 seconds for map changes

local function startNoFogMonitor()
    if noFogMonitorConn then return end
    
    lastMapCheck = os.clock()
    
    -- Spawn monitoring loop
    task.spawn(function()
        while noFogEnabled do
            task.wait(1) -- Check every second
            
            if not noFogEnabled then break end
            
            local currentTime = os.clock()
            
            -- Check if fog has been reset by the game
            local fogWasReset = false
            pcall(function()
                if Lighting.FogEnd < 50000 then -- Game reset fog
                    fogWasReset = true
                end
            end)
            
            -- If fog was reset, wait 15 seconds then reapply
            if fogWasReset and (currentTime - lastMapCheck) >= MAP_CHECK_INTERVAL then
                lastMapCheck = currentTime
                
                -- Wait for map to fully load
                task.wait(15)
                
                -- Reapply NoFog if still enabled
                if noFogEnabled then
                    pcall(function()
                        warn("[Visual Fix] Map detected - reapplying NoFog after 15s delay")
                        applyNoFog()
                        WindUI:Notify({ 
                            Title = "Visual", 
                            Content = "NoFog reapplied (map change detected)", 
                            Duration = 3, 
                            Icon = "refresh-cw" 
                        })
                    end)
                end
            elseif fogWasReset then
                -- Fog was reset but cooldown not passed, just reapply immediately
                pcall(function()
                    Lighting.FogEnd = 100000
                    Lighting.FogStart = 0
                end)
            end
        end
    end)
end

local function stopNoFogMonitor()
    noFogMonitorConn = nil
end

-- UI toggles with improved error handling
VisualSection:Toggle({
    Title = "Fullbright",
    Flag = "Fullbright",
    Desc = "Enable fullbright lighting.",
    Default = false,
    Callback = function(state)
        local success, err = pcall(function()
            fullbrightEnabled = state
            if state then
                applyFullbright()
                WindUI:Notify({ Title = "Visual", Content = "Fullbright enabled.", Duration = 2, Icon = "sun" })
            else
                restoreFullbright()
                WindUI:Notify({ Title = "Visual", Content = "Fullbright disabled.", Duration = 2, Icon = "moon" })
            end
        end)
        
        if not success then
            warn("[Visual Fix] Fullbright toggle error:", err)
            WindUI:Notify({ 
                Title = "Visual Error", 
                Content = "Fullbright toggle failed: " .. tostring(err), 
                Duration = 4, 
                Icon = "alert-triangle" 
            })
        end
    end
})

VisualSection:Toggle({
    Title = "No Fog",
    Flag = "No_Fog",
    Desc = "Remove fog and atmosphere effects.",
    Default = false,
    Callback = function(state)
        local success, err = pcall(function()
            noFogEnabled = state
            if state then
                applyNoFog()
                startNoFogMonitor() -- Start monitoring for map changes
                WindUI:Notify({ Title = "Visual", Content = "NoFog enabled with auto-reapply.", Duration = 2, Icon = "cloud-off" })
            else
                stopNoFogMonitor() -- Stop monitoring
                restoreNoFog()
                WindUI:Notify({ Title = "Visual", Content = "NoFog disabled.", Duration = 2, Icon = "cloud" })
            end
        end)
        
        if not success then
            warn("[Visual Fix] NoFog toggle error:", err)
            WindUI:Notify({ 
                Title = "Visual Error", 
                Content = "NoFog toggle failed: " .. tostring(err), 
                Duration = 4, 
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
local function startFOVLock()
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
    
    -- Also force every frame as backup
    local _fovLockFrame = 0
    fovLockConnection = RunService.RenderStepped:Connect(function()
        if not fovChangerEnabled then return end
        _fovLockFrame = _fovLockFrame + 1
        if _fovLockFrame < 10 then return end -- check every ~0.17s; property hook handles instant fixes
        _fovLockFrame = 0
        forceFOV()
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

-- Re-apply FOV on respawn (camera gets recreated)
LocalPlayer.CharacterAdded:Connect(function()
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

VisualSection:Toggle({
    Title = "FOV Changer",
    Flag = "FOV_Changer",
    Desc = "Change camera FOV.",
    Default = false,
    Callback = function(state)
        fovChangerEnabled = state
        if state then
            applyFOV(currentFOV)
            startFOVLock() -- Lock FOV so nothing can change it
            WindUI:Notify({ Title = "Visual", Content = "FOV Changer enabled (" .. currentFOV .. ") - Locked", Duration = 2, Icon = "eye" })
        else
            stopFOVLock()
            restoreFOV()
            WindUI:Notify({ Title = "Visual", Content = "FOV Changer disabled.", Duration = 2, Icon = "eye-off" })
        end
    end
})

VisualSection:Slider({
    Title = "FOV Value",
    Flag = "Visual",
    Desc = "FOV value (default: 70).",
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(value)
        currentFOV = value
        if fovChangerEnabled then
            applyFOV(value)
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

VisualSection:Toggle({
    Title = "Infinite Zoom",
    Flag = "Infinite_Zoom",
    Desc = "Remove camera zoom limits.",
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
            WindUI:Notify({ Title = "Visual", Content = "Infinite Zoom enabled.", Duration = 2, Icon = "zoom-in" })
        else
            if zoomConnection then zoomConnection:Disconnect() zoomConnection = nil end
            restoreZoom()
            WindUI:Notify({ Title = "Visual", Content = "Infinite Zoom disabled.", Duration = 2, Icon = "zoom-out" })
        end
    end
})

-- ===== FPS BOOSTER =====
local fpsBoosterEnabled = false
local fpsBoosterConnection = nil

local function applyFPSBoost()
    pcall(function()
        -- Single-pass: handle textures, meshes, materials, particles, beams, and sky together
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
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

        -- Strip lighting effects
        local Lighting = game:GetService("Lighting")
        for _, effect in ipairs(Lighting:GetChildren()) do
            pcall(function()
                if effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
                or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect")
                or effect:IsA("DepthOfFieldEffect") then
                    effect:Destroy()
                end
            end)
        end

        -- Flatten lighting
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        end)
    end)
end

VisualSection:Toggle({
    Title = "FPS Booster",
    Flag = "FPS_Booster",
    Desc = "Remove textures, lighting & particles for max FPS.",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        fpsBoosterEnabled = state
        if state then
            applyFPSBoost()
            -- Reapply every time a new map/descendants are added
            -- Batch queue: collect objects added in a burst and process them together
            -- This prevents hundreds of sequential pcalls during map loads
            local _fpsBatch = {}
            local _fpsBatchPending = false
            local function _processFPSBatch()
                _fpsBatchPending = false
                for i = 1, #_fpsBatch do
                    local obj = _fpsBatch[i]
                    _fpsBatch[i] = nil
                    if not fpsBoosterEnabled then break end
                    pcall(function()
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
            end
            fpsBoosterConnection = Workspace.DescendantAdded:Connect(function(obj)
                if not fpsBoosterEnabled then return end
                _fpsBatch[#_fpsBatch + 1] = obj
                if not _fpsBatchPending then
                    _fpsBatchPending = true
                    task.defer(_processFPSBatch) -- process whole batch next frame
                end
            end)
            WindUI:Notify({
                Title = "FPS Booster",
                Content = "Textures demolished. Reapplies on map change.",
                Duration = 3,
                Icon = "zap"
            })
        else
            if fpsBoosterConnection then
                fpsBoosterConnection:Disconnect()
                fpsBoosterConnection = nil
            end
            WindUI:Notify({
                Title = "FPS Booster",
                Content = "FPS Booster disabled.",
                Duration = 2,
                Icon = "zap-off"
            })
        end
    end
})

-- ===== STREAMER MODE =====
-- Anonymizes all player names including your own for privacy while streaming
-- streamerModeEnabled and streamerModeIconDisabled are declared globally near Window creation
local originalNames = {} -- Store original names: {player = originalName}
local streamerModeConnections = {}
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
    -- Generate consistent anonymous name per player (so it doesn't keep changing)
    if not originalNames[player] then
        originalNames[player] = {
            original = player.DisplayName or player.Name,
            anonymous = generateRandomName()
        }
    end
    return originalNames[player].anonymous
end

local function applyStreamerModeToPlayer(player)
    if not streamerModeEnabled then return end
    if not player or not player.Character then return end
    
    local anonymousName = getAnonymousName(player)
    
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
        for _, gui in ipairs(char:GetDescendants()) do
            if gui:IsA("BillboardGui") then
                for _, label in ipairs(gui:GetDescendants()) do
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
    
    local data = originalNames[player]
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
    for _, player in ipairs(Players:GetPlayers()) do
        applyStreamerModeToPlayer(player)
    end
end

local function restoreAllPlayerNames()
    for _, player in ipairs(Players:GetPlayers()) do
        restorePlayerName(player)
    end
    originalNames = {}
end

local function setupStreamerModeConnections()
    -- Clean up existing connections
    for _, conn in ipairs(streamerModeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    streamerModeConnections = {}
    
    if not streamerModeEnabled then return end
    
    -- Apply to new players
    table.insert(streamerModeConnections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyStreamerModeToPlayer(player)
        end)
    end))
    
    -- Re-apply when characters respawn
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(streamerModeConnections, player.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyStreamerModeToPlayer(player)
        end))
    end
    
    -- Periodic refresh to catch any reset names - PERF: increased to 10s (was 2s)
    -- CharacterAdded hooks above handle respawns already; this is just a safety net
    local _streamerLastRefresh = 0
    table.insert(streamerModeConnections, RunService.Heartbeat:Connect(function()
        if not streamerModeEnabled then return end
        local now = os.clock()
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
        WindUI:Notify({
            Title = "Streamer Mode",
            Content = "Enabled - All player names are anonymous",
            Duration = 3,
            Icon = "eye-off"
        })
    end)
end

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
                _G.SafeFireServer(forceSelfDamage, 0)
            end)
        end
    end

    local NoFallDamageToggle = MovementSection:Toggle({
        Title = "No Fall Damage",
        Flag = "No_Fall_Damage",
        Desc = "No fall damage.",
        Default = false,
        Callback = function(state)
            noFallDamageEnabled = state

            if state then
                -- (Re)start the loop
                if noFallDamageThread then
                    pcall(task.cancel, noFallDamageThread)
                end

                noFallDamageThread = task.spawn(noFallDamageLoop)

                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "No Fall Damage enabled.",
                    Duration = 2,
                    Icon = "shield-check",
                })
            else
                -- Stop the loop
                if noFallDamageThread then
                    pcall(task.cancel, noFallDamageThread)
                    noFallDamageThread = nil
                end

                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "No Fall Damage disabled.",
                    Duration = 2,
                    Icon = "shield-off",
                })
            end
        end
    })
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.NoFallDamage = NoFallDamageToggle

    -- === Anti Break Legs ===
    local antiBreakLegsEnabled = false
    local antiBreakLegsConn = nil
    local antiBreakLegsHeartbeatConn = nil
    local ANTI_BREAK_LEGS_FALL_SPEED = -18 -- Fall speed threshold to activate climbing state

    local function disconnectAntiBreakLegs()
        if antiBreakLegsConn then
            pcall(function() antiBreakLegsConn:Disconnect() end)
            antiBreakLegsConn = nil
        end
        if antiBreakLegsHeartbeatConn then
            pcall(function() antiBreakLegsHeartbeatConn:Disconnect() end)
            antiBreakLegsHeartbeatConn = nil
        end
    end

    local function startAntiBreakLegs()
        disconnectAntiBreakLegs()

        -- Cache UserStates reference (avoid FindFirstChild every frame)
        local _cachedUserStates = LocalPlayer:FindFirstChild("UserStates")
        local _cachedBrokenLegsRS = _cachedUserStates and _cachedUserStates:FindFirstChild("BrokenLegs")
        local _userStatesRefreshTimer = 0

        -- Main loop - clear broken legs and apply climbing state when falling
        antiBreakLegsConn = RunService.RenderStepped:Connect(function()
            if not antiBreakLegsEnabled then return end

            local char = LocalPlayer and LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end

            -- Refresh cached UserStates every 2 seconds (not every frame)
            local now = os.clock()
            if not _cachedBrokenLegsRS or (now - _userStatesRefreshTimer > 2) then
                _userStatesRefreshTimer = now
                _cachedUserStates = LocalPlayer:FindFirstChild("UserStates")
                _cachedBrokenLegsRS = _cachedUserStates and _cachedUserStates:FindFirstChild("BrokenLegs")
            end

            -- Always clear broken legs state every frame
            if _cachedBrokenLegsRS then
                _cachedBrokenLegsRS.Value = false
            end

            -- Check if we're airborne (not touching ground)
            local floorMaterial = hum.FloorMaterial
            local isAirborne = floorMaterial == Enum.Material.Air

            -- If falling and airborne, continuously set climbing state
            local yVel = root.Velocity.Y
            if isAirborne and yVel < ANTI_BREAK_LEGS_FALL_SPEED then
                hum:ChangeState(Enum.HumanoidStateType.Climbing)
            end
        end)

        -- PERF: Removed redundant Heartbeat connection. RenderStepped already clears BrokenLegs every frame.
    end

    local AntiBreakLegsToggle = MovementSection:Toggle({
        Title = "Anti Break Legs",
        Flag = "Anti_Break_Legs",
        Desc = "Prevent broken legs.",
        Default = false,
        Callback = function(state)
            antiBreakLegsEnabled = state
            _G.AntiBreakLegsEnabled = state

            if state then
                startAntiBreakLegs()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Anti Break Legs enabled.",
                    Duration = 2,
                    Icon = "activity"
                })
            else
                disconnectAntiBreakLegs()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Anti Break Legs disabled.",
                    Duration = 2,
                    Icon = "activity"
                })
            end
        end
    })
    _G.LanderToggleElements.AntiBreakLegs = AntiBreakLegsToggle

    -- === Invisible ===
    local invisibleEnabled = false
    local invisibleThread = nil

    local function startInvisible()
        invisibleThread = task.spawn(function()
            -- Disable replicator to hide character from server
            pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "false") end)
            task.wait(2)
            -- Re-enable replicator after 2 seconds
            pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "true") end)
        end)
    end

    local function stopInvisible()
        if invisibleThread then
            pcall(task.cancel, invisibleThread)
            invisibleThread = nil
        end
        -- Reset replicator back to normal
        pcall(function() setfflag("NextGenReplicatorEnabledWrite4", "true") end)
    end

    local InvisibleToggle = MovementSection:Toggle({
        Title = "Invisible",
        Flag = "Invisible",
        Desc = "Temporarily hide your character from other players.",
        Icon = "eye-off",
        Default = false,
        Callback = function(state)
            invisibleEnabled = state
            if state then
                startInvisible()
                WindUI:Notify({
                    Title = "Movement",
                    Content = "Invisible enabled.",
                    Duration = 2,
                    Icon = "eye-off",
                })
            else
                stopInvisible()
                WindUI:Notify({
                    Title = "Movement",
                    Content = "Invisible disabled.",
                    Duration = 2,
                    Icon = "eye",
                })
            end
        end
    })
    _G.LanderToggleElements.Invisible = InvisibleToggle

    -- === Killbrick Protection ===
    local killbrickEnabled = false
    local killbrickConnection = nil
    local function toggleKillbrick(enabled)
        killbrickEnabled = enabled
        if killbrickConnection then
            killbrickConnection:Disconnect()
            killbrickConnection = nil
        end
        if enabled then
            killbrickConnection = RunService.Heartbeat:Connect(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                local parts = workspace:GetPartBoundsInRadius(LocalPlayer.Character.HumanoidRootPart.Position, 10)
                for _, part in ipairs(parts) do
                    part.CanTouch = false
                end
            end)
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if killbrickEnabled then
            toggleKillbrick(true)
        end
    end)

    ServerModifiersSection:Toggle({
        Title = "Killbrick Protection",
        Flag = "Killbrick_Protection",
        Desc = "Protect player from killbricks within 10 studs radius",
        Default = false,
        Callback = function(state)
            toggleKillbrick(state)
            WindUI:Notify({
                Title = "Server Modifiers",
                Content = state and "Killbrick Protection enabled" or "Killbrick Protection disabled",
                Duration = 2,
                Icon = state and "shield-check" or "shield-off",
            })
        end
    })

    -- === Baguette Purchase ===
    ServerModifiersSection:Button({
        Title = "Get Baguette",
        Desc = "Purchase Baguette from the server.",
        Callback = function()
            pcall(function()
                local args = {
                    [1] = "Baguette"
                }
                _G.SafeFireServer(game:GetService("ReplicatedStorage").Events.Customize.PurchaseEvent, unpack(args))
            end)
            WindUI:Notify({
                Title = "Server Modifiers",
                Content = "Baguette purchase requested!",
                Duration = 2,
                Icon = "cookie"
            })
        end
    })

    -- === Voivode Purchase ===
    ServerModifiersSection:Button({
        Title = "Get Voivode",
        Desc = "Purchase Voivode from the server.",
        Callback = function()
            pcall(function()
                _G.SafeFireServer(game:GetService("ReplicatedStorage").Events.Customize.PurchaseEvent, "Voivode")
            end)
            WindUI:Notify({
                Title = "Server Modifiers",
                Content = "Voivode purchase requested!",
                Duration = 2,
                Icon = "crown"
            })
        end
    })

    -- === Iron Stake Purchase ===
    ServerModifiersSection:Button({
        Title = "Get Iron Stake",
        Desc = "Purchase Iron Stake from the server.",
        Callback = function()
            pcall(function()
                _G.SafeFireServer(game:GetService("ReplicatedStorage").Events.Customize.PurchaseEvent, "Iron Stake")
            end)
            WindUI:Notify({
                Title = "Server Modifiers",
                Content = "Iron Stake purchase requested!",
                Duration = 2,
                Icon = "swords"
            })
        end
    })

    -- === Fly (Climbing-based smooth flight) ===
    FlyEnabled = false -- Global for keybind access
    FlySpeed = 25 -- Default fly speed
    local flyBodyVelocity = nil
    FlyBodyGyro = nil -- Global so Auto Look can detect flying
    local flyConnection = nil
    local flyAnimConnection = nil -- Connection to stop climb animations
    local flyStateConnection = nil -- Connection to enforce climbing state
    local flyMobileGui = nil -- Mobile UI for up/down buttons
    local flyLastMoveTime = 0 -- Track when player last moved (for anti-AFK)
    flyMobileUp = false -- Is mobile up button held (global for noclip access)
    flyMobileDown = false -- Is mobile down button held (global for noclip access)
    local flyAntiAfkRunning = false -- Anti-AFK loop flag
    local flyAntiAfkResetting = false -- True during anti-AFK state reset

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
        upBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        upBtn.BackgroundTransparency = 0.3
        upBtn.Text = "▲"
        upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        upBtn.TextSize = 32
        upBtn.Font = Enum.Font.GothamBold
        upBtn.Parent = container
        
        local upCorner = Instance.new("UICorner")
        upCorner.CornerRadius = UDim.new(0, 12)
        upCorner.Parent = upBtn
        
        local upStroke = Instance.new("UIStroke")
        upStroke.Color = Color3.fromRGB(255, 255, 255)
        upStroke.Thickness = 2
        upStroke.Transparency = 0.5
        upStroke.Parent = upBtn
        
        -- Down button
        local downBtn = Instance.new("TextButton")
        -- Use randomized name
        downBtn.Name = "Button_" .. math.random(10000, 99999)
        downBtn.Size = UDim2.new(1, 0, 0, 65)
        downBtn.Position = UDim2.new(0, 0, 0, 85)
        downBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
        downBtn.BackgroundTransparency = 0.3
        downBtn.Text = "▼"
        downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        downBtn.TextSize = 32
        downBtn.Font = Enum.Font.GothamBold
        downBtn.Parent = container
        
        local downCorner = Instance.new("UICorner")
        downCorner.CornerRadius = UDim.new(0, 12)
        downCorner.Parent = downBtn
        
        local downStroke = Instance.new("UIStroke")
        downStroke.Color = Color3.fromRGB(255, 255, 255)
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

    local function startFly()
        local char = LocalPlayer and LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end
        
        
        -- Use Climbing state to bypass anti-cheat
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
        end)
        
        -- Create BodyVelocity for smooth movement
        flyBodyVelocity = Instance.new("BodyVelocity")
        -- Use randomized name for anti-detection
        flyBodyVelocity.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BV_" .. math.random(10000, 99999))
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = hrp
        
        -- Create BodyGyro for full 3D rotation following camera
        FlyBodyGyro = Instance.new("BodyGyro")
        -- Use randomized name
        FlyBodyGyro.Name = _G.getRandomInstanceName and _G.getRandomInstanceName() or ("BG_" .. math.random(10000, 99999))
        FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyGyro.P = 50000
        FlyBodyGyro.D = 1000
        FlyBodyGyro.Parent = hrp
        
        -- Enforce climbing state when it changes (except for dead/ragdoll/physics)
        -- This is the key anti-AFK mechanism - always force back to climbing immediately
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
        
        -- Stop climbing and falling animations when they play (so character looks still)
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            flyAnimConnection = animator.AnimationPlayed:Connect(function(track)
                if not FlyEnabled then return end
                local name = track.Name:lower()
                local animId = ""
                pcall(function() animId = track.Animation and track.Animation.AnimationId or "" end)
                animId = animId:lower()
                -- Stop climbing and falling animations
                if name:find("climb") or animId:find("climb") or name:find("fall") or animId:find("fall") then
                    pcall(function() track:Stop(0) end)
                end
            end)
            -- Stop any currently playing climb or fall animations
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                local name = track.Name:lower()
                local animId = ""
                pcall(function() animId = track.Animation and track.Animation.AnimationId or "" end)
                animId = animId:lower()
                if name:find("climb") or animId:find("climb") or name:find("fall") or animId:find("fall") then
                    pcall(function() track:Stop(0) end)
                end
            end
        end
        
        -- Main fly loop
        -- Frame counter for aggressive state refresh
        local flyFrameCounter = 0
        local FLY_STATE_REFRESH_INTERVAL = 30 -- Force refresh every 30 frames (~0.5 sec at 60fps)
        
        flyConnection = RunService.RenderStepped:Connect(function()
            if not FlyEnabled then return end

            local char = LocalPlayer and LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local camera = Workspace.CurrentCamera

            if not hrp or not humanoid or not camera then return end

            -- Aggressively battle the game's ladder detection
            -- Force climbing state every frame if not in it, and periodically refresh to reset game's timer
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
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Check if we're on mobile/touch device
            local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
            
            if isMobile then
                -- Mobile: Use humanoid MoveDirection for horizontal movement (from joystick)
                local humMoveDir = humanoid.MoveDirection
                if humMoveDir.Magnitude > 0.1 then
                    -- Project move direction onto camera's horizontal plane
                    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                    local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit
                    
                    -- Get forward/back and left/right components from humanoid move direction
                    local forwardAmount = humMoveDir:Dot(flatLook)
                    local rightAmount = humMoveDir:Dot(flatRight)
                    
                    -- Apply to full 3D camera vectors for proper pitch following
                    moveDirection = moveDirection + lookVector * forwardAmount
                    moveDirection = moveDirection + rightVector * rightAmount
                end
                
                -- Mobile up/down buttons
                if flyMobileUp then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if flyMobileDown then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
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
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
            end
            
            -- Normalize and apply speed
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * FlySpeed
                -- Update last move time for anti-AFK (player is actively moving)
                flyLastMoveTime = os.clock()
            end
            
            -- Apply smooth velocity with lerp
            if flyBodyVelocity and flyBodyVelocity.Parent then
                local currentVel = flyBodyVelocity.Velocity
                flyBodyVelocity.Velocity = currentVel:Lerp(moveDirection, 0.2)
            end
            
            -- Apply gyro to follow camera
            -- Skip if Auto Look has a target (it controls the gyro directly)
            if FlyBodyGyro and FlyBodyGyro.Parent then
                if not (KillAuraAutoLook and KillAura_autoLookHasTarget) then
                    -- Normal fly behavior: follow camera
                    FlyBodyGyro.CFrame = camCF
                end
                -- If Auto Look has target, it sets CFrame in KillAura_performAutoLook
            end
        end)
    end

    local function stopFly()
        -- Stop anti-AFK loop
        flyAntiAfkRunning = false
        flyAntiAfkResetting = false
        
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
        
        -- Remove BodyVelocity
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        
        -- Remove BodyGyro
        if FlyBodyGyro then
            FlyBodyGyro:Destroy()
            FlyBodyGyro = nil
        end
        
        -- Clean up Auto Look BodyGyro if it exists (since fly is stopping)
        local char = LocalPlayer and LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local autoLookGyro = hrp:FindFirstChild("LanderAutoLookGyro")
                if autoLookGyro then
                    autoLookGyro:Destroy()
                end
            end
        end
        
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
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if FlyEnabled then
            task.wait(0.5)
            startFly()
        end
    end)

    local FlyToggle = MovementSection:Toggle({
        Title = "Fly",
        Flag = "Fly",
        Desc = "Fly without being detected.",
        Default = false,
        Callback = function(state)
            FlyEnabled = state
            
            if state then
                startFly()
                -- Unlock Noclip toggle when Fly is enabled
                if _G.LanderToggleElements and _G.LanderToggleElements.NoclipBypass then
                    pcall(function() _G.LanderToggleElements.NoclipBypass:Unlock() end)
                end
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Fly enabled.",
                    Duration = 3,
                    Icon = "plane",
                })
            else
                stopFly()
                -- Force stop noclip directly (don't just set toggle - call the function)
                if _G.LanderStopNoclip then
                    pcall(_G.LanderStopNoclip)
                end
                -- Also update the toggle UI to reflect disabled state
                if _G.LanderToggleElements and _G.LanderToggleElements.NoclipBypass then
                    pcall(function()
                        _G.LanderToggleElements.NoclipBypass:Set(false)
                        _G.LanderToggleElements.NoclipBypass:Lock()
                    end)
                end
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Fly disabled.",
                    Duration = 2,
                    Icon = "plane-landing",
                })
            end
        end
    })
    
    -- Register Fly toggle for mobile button and keybinds
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.Fly = FlyToggle

    -- === Visual Noclip Bypass v3 (CFrame Fly Method) ===
    -- Based on cframefly method: anchor Head, move via CFrame (client-only)
    -- Server doesn't see movement until we teleport on exit
    
    local NoclipEnabled = false
    _G.LanderNoclipEnabled = false -- Global reference for keybinds
    local noclipCFlyConn = nil
    local noclipTeleportConn = nil
    local noclipCollisionConn = nil
    
    -- State
    -- noclipSpeed removed: now uses FlySpeed variable directly
    local lastNoclipPosition = nil -- Where we are visually (client)
    local serverNoclipPosition = nil -- Where server thinks we are
    local isLoopTeleporting = false
    local teleportEndTime = 0
    local headWasAnchored = false
    
    -- New: Wall detection state
    local isInsideWall = false
    local wallEntryTime = 0 -- When we entered the wall
    local WALL_COOLDOWN = 1 -- 1 second cooldown before teleporting after entering wall
    local clearFrameCount = 0 -- Consecutive frames where we're clearly outside
    local CLEAR_FRAMES_NEEDED = 5 -- Need to be clearly outside for 5 consecutive frames
    
    -- All parts for collision disable
    local NOCLIP_PARTS = {
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
    local NOCLIP_DIRECTIONS_18 = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
        Vector3.new(1, 0, 1).Unit, Vector3.new(1, 0, -1).Unit,
        Vector3.new(-1, 0, 1).Unit, Vector3.new(-1, 0, -1).Unit,
        Vector3.new(1, 1, 0).Unit, Vector3.new(-1, 1, 0).Unit,
        Vector3.new(0, 1, 1).Unit, Vector3.new(0, 1, -1).Unit,
        Vector3.new(1, -1, 0).Unit, Vector3.new(-1, -1, 0).Unit,
        Vector3.new(0, -1, 1).Unit, Vector3.new(0, -1, -1).Unit,
    }
    
    local function setupNoclipRayParams()
        local now = os.clock()
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
        for _, plr in ipairs(Players:GetPlayers()) do
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
    
    -- Check if position is inside/touching a collision wall or ceiling
    -- Simple and aggressive: if ANY ray hits something close, we're "in" a wall
    local function isInWall(pos)
        -- Rebuild params only when needed (throttled), not every frame
        setupNoclipRayParams()
        
        -- Use pre-built constant directions table (not rebuilt each call)
        for _, dir in ipairs(NOCLIP_DIRECTIONS_18) do
            local result = workspace:Raycast(pos, dir * 2, noclipRayParams)
            if result and result.Instance and result.Instance.CanCollide then
                return true
            end
        end
        
        return false
    end
    
    -- More strict check: are we CLEARLY outside? (no walls nearby at all)
    -- This is VERY conservative to avoid teleporting while still inside
    local function isClearlyOutside(pos)
        -- Reuse already-cached params (setupNoclipRayParams was just called in isInWall)
        if not noclipRayParams then setupNoclipRayParams() end
        
        -- Use pre-built constant directions table
        for _, dir in ipairs(NOCLIP_DIRECTIONS_18) do
            local result = workspace:Raycast(pos, dir * 4, noclipRayParams)
            if result and result.Instance and result.Instance.CanCollide then
                return false -- Still near something solid
            end
        end
        
        return true -- No walls nearby in any direction, clearly outside
    end
    
    -- Check if position would be underground
    local function isUnderground(pos)
        if not noclipRayParams then setupNoclipRayParams() end
        
        local char = LocalPlayer.Character
        noclipRayParams.FilterDescendantsInstances = char and {char} or {}
        
        -- Raycast down to find the floor
        local floorCheck = workspace:Raycast(pos, Vector3.new(0, -500, 0), noclipRayParams)
        
        if floorCheck and floorCheck.Instance then
            -- Check if the floor is Terrain (ground)
            if floorCheck.Instance:IsA("Terrain") then
                -- We're below terrain level if floor is above us
                return floorCheck.Distance < 0.1 or pos.Y < floorCheck.Position.Y
            end
        end
        
        -- Also check: raycast up - if we hit terrain above us, we're underground
        local ceilingCheck = workspace:Raycast(pos, Vector3.new(0, 500, 0), noclipRayParams)
        if ceilingCheck and ceilingCheck.Instance and ceilingCheck.Instance:IsA("Terrain") then
            return true -- Terrain above us means underground
        end
        
        return false
    end
    
    -- Loop teleport to position
    local function noclipLoopTP(targetPos, duration)
        isLoopTeleporting = true
        teleportEndTime = os.clock() + (duration or 1)
        
        if noclipTeleportConn then
            noclipTeleportConn:Disconnect()
        end
        
        noclipTeleportConn = RunService.Heartbeat:Connect(function()
            if not isLoopTeleporting or os.clock() > teleportEndTime then
                isLoopTeleporting = false
                if noclipTeleportConn then
                    noclipTeleportConn:Disconnect()
                    noclipTeleportConn = nil
                end
                return
            end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rot = hrp.CFrame - hrp.CFrame.Position
                hrp.CFrame = CFrame.new(targetPos) * rot
            end
        end)
    end
    
    local function stopNoclipLoopTP()
        isLoopTeleporting = false
        if noclipTeleportConn then
            noclipTeleportConn:Disconnect()
            noclipTeleportConn = nil
        end
    end
    
    -- Enter CFrame fly mode (when going into a wall)
    local function enterCFrameMode()
        if headWasAnchored then return end -- Already in CFrame mode
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if not head or not humanoid or not hrp then return end
        
        -- Store server position before entering wall
        serverNoclipPosition = hrp.Position
        lastNoclipPosition = hrp.Position
        
        -- Enable CFrame fly mode
        humanoid.PlatformStand = true
        head.Anchored = true
        headWasAnchored = true
        
        isInsideWall = true
        wallEntryTime = os.clock()
    end
    
    -- Exit CFrame fly mode (when leaving a wall)
    local function exitCFrameMode()
        if not headWasAnchored then return end -- Not in CFrame mode
        
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
        
        headWasAnchored = false
        isInsideWall = false
        
        -- Teleport to current visual position
        if lastNoclipPosition then
            noclipLoopTP(lastNoclipPosition, 1)
        end
    end
    
    local function startNoclip()
        if noclipCFlyConn then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if not head or not humanoid or not hrp then return end
        
        _G.NoclipBypassEnabled = true
        setupNoclipRayParams()
        
        -- Initialize positions (don't enter CFrame mode yet)
        serverNoclipPosition = hrp.Position
        lastNoclipPosition = hrp.Position
        isInsideWall = false
        headWasAnchored = false
        
        -- Main loop - monitor wall entry/exit and handle CFrame movement when inside wall
        -- Use RenderStepped for faster detection (runs before frame renders)
        -- PERF: Throttle wall raycasts to every 3 frames (was every frame = 18-36 raycasts/frame)
        local _noclipWallCheckFrame = 0
        local _noclipLastInWall = false
        noclipCFlyConn = RunService.RenderStepped:Connect(function(deltaTime)
            -- SAFETY: Don't run if noclip is disabled OR if fly is disabled
            if not NoclipEnabled then return end
            if not FlyEnabled then
                -- Fly was disabled but noclip is still on - force stop noclip
                stopNoclip()
                return
            end
            
            local character = LocalPlayer.Character
            if not character then return end
            
            local hum = character:FindFirstChildOfClass("Humanoid")
            local headPart = character:FindFirstChild("Head")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not hum or not headPart or not rootPart then return end
            
            -- Get current position
            local currentPos = headWasAnchored and headPart.Position or rootPart.Position
            
            -- PERF: Only run expensive wall raycasts every 3 frames
            _noclipWallCheckFrame = _noclipWallCheckFrame + 1
            local inWall = _noclipLastInWall -- reuse last result by default
            if _noclipWallCheckFrame >= 3 then
                _noclipWallCheckFrame = 0
                inWall = isInWall(currentPos)
                _noclipLastInWall = inWall
            end
            
            if inWall and not isInsideWall then
                -- Just entered a wall - start CFrame mode
                clearFrameCount = 0 -- Reset clear counter
                enterCFrameMode()
            elseif isInsideWall then
                -- We're in CFrame mode - check if cooldown passed before checking wall exit
                local timeInWall = os.clock() - wallEntryTime
                if timeInWall >= WALL_COOLDOWN then
                    -- Cooldown passed, NOW we can check if we CLEARLY left the wall
                    -- Use stricter check - must have NO walls nearby to exit
                    if isClearlyOutside(currentPos) then
                        -- We're clearly outside - increment counter
                        clearFrameCount = clearFrameCount + 1
                        if clearFrameCount >= CLEAR_FRAMES_NEEDED then
                            -- Been clearly outside for multiple frames, safe to exit
                            exitCFrameMode()
                            clearFrameCount = 0
                        end
                    else
                        -- Still near a wall, reset counter
                        clearFrameCount = 0
                    end
                end
                -- If cooldown not passed OR still near walls, stay in CFrame mode
            end
            
            -- If in CFrame mode (inside wall), handle movement
            if headWasAnchored then
                -- Keep anchored and platform stand
                if not headPart.Anchored then headPart.Anchored = true end
                if not hum.PlatformStand then hum.PlatformStand = true end
                
                -- Get movement from humanoid MoveDirection
                local moveDirection = hum.MoveDirection * (FlySpeed * deltaTime)
                
                -- Check keyboard for vertical movement
                local verticalMove = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    verticalMove = FlySpeed * deltaTime
                elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    verticalMove = -FlySpeed * deltaTime
                end
                
                -- Mobile up/down buttons
                if flyMobileUp then
                    verticalMove = FlySpeed * deltaTime
                elseif flyMobileDown then
                    verticalMove = -FlySpeed * deltaTime
                end
                
                local headCFrame = headPart.CFrame
                local camera = workspace.CurrentCamera
                local cameraCFrame = camera.CFrame
                
                -- Calculate camera offset relative to head
                local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
                cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
                
                local cameraPosition = cameraCFrame.Position
                local headPosition = headCFrame.Position
                
                -- Convert movement to camera-relative
                local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
                
                -- Add vertical movement
                objectSpaceVelocity = objectSpaceVelocity + Vector3.new(0, verticalMove, 0)
                
                -- Calculate new position
                local newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)
                
                -- Prevent going underground
                if isUnderground(newPos) then
                    -- Block downward movement, only allow horizontal and upward
                    if objectSpaceVelocity.Y < 0 then
                        objectSpaceVelocity = Vector3.new(objectSpaceVelocity.X, 0, objectSpaceVelocity.Z)
                    end
                    -- Recalculate position
                    newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)
                    
                    -- If still underground, don't move at all
                    if isUnderground(newPos) then
                        newPos = headPosition
                    end
                end
                
                -- Move head via CFrame (client-only visual movement)
                headPart.CFrame = CFrame.new(newPos) * (cameraCFrame - cameraPosition)
                
                -- Update last position
                lastNoclipPosition = headPart.Position
            else
                -- Not in CFrame mode, just track position
                lastNoclipPosition = rootPart.Position
                serverNoclipPosition = rootPart.Position
            end
            
            _G.NoclipLastValidPosition = serverNoclipPosition
        end)
        
        -- Collision disable loop (with fly check for safety)
        -- Cache character part and accessory references (rebuilt only on character change)
        local _noclipCollisionChar = nil
        local _noclipCollisionParts = {}
        local function _rebuildNoclipCollisionCache(char)
            _noclipCollisionChar = char
            _noclipCollisionParts = {}
            for _, partName in ipairs(NOCLIP_PARTS) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    table.insert(_noclipCollisionParts, part)
                end
            end
            for _, child in ipairs(char:GetChildren()) do
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
                _G.LanderNoclipEnabled = false
                return
            end
            
            local character = LocalPlayer.Character
            if not character then return end

            -- Rebuild cache if character changed
            if character ~= _noclipCollisionChar then
                _rebuildNoclipCollisionCache(character)
            end
            
            -- Disable collision on all cached parts (no GetChildren call per frame)
            -- PERF: Removed pcall wrapper - parts are validated from cache
            for _, part in ipairs(_noclipCollisionParts) do
                if part.Parent then
                    part.CanCollide = false
                end
            end
        end)
    end

    -- Make stopNoclip global so fly toggle can call it directly
    local function stopNoclip()
        NoclipEnabled = false
        _G.LanderNoclipEnabled = false
        _G.NoclipBypassEnabled = false
        _G.NoclipLastValidPosition = nil
        
        -- Get final position before cleanup
        local finalPos = lastNoclipPosition
        local wasInCFrameMode = headWasAnchored
        
        -- Clean up connections
        if noclipCFlyConn then
            noclipCFlyConn:Disconnect()
            noclipCFlyConn = nil
        end
        
        if noclipCollisionConn then
            noclipCollisionConn:Disconnect()
            noclipCollisionConn = nil
        end
        
        -- Restore character state
        local char = LocalPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if head and headWasAnchored then
                head.Anchored = false
            end
            
            if humanoid then
                humanoid.PlatformStand = false
            end
            
            -- Restore collision on all parts
            for _, partName in ipairs(NOCLIP_PARTS) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
        
        headWasAnchored = false
        isInsideWall = false
        
        -- If we were in CFrame mode, teleport to final position
        if wasInCFrameMode and finalPos then
            noclipLoopTP(finalPos, 1)
        end
        
        -- Reset state
        lastNoclipPosition = nil
        serverNoclipPosition = nil
    end
    
    -- Expose globally so fly toggle can call it
    _G.LanderStopNoclip = stopNoclip

    -- Re-setup on respawn
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        stopNoclipLoopTP()
        lastNoclipPosition = nil
        serverNoclipPosition = nil
        headWasAnchored = false
        isInsideWall = false
        
        if NoclipEnabled then
            task.wait(0.3)
            startNoclip()
        end
    end)

    local NoclipToggle = MovementSection:Toggle({
        Title = "Fly Noclip Bypass",
        Flag = "Fly_Noclip_Bypass",
        Desc = "Fly through walls.",
        Default = false,
        Locked = true,
        Callback = function(state)
            NoclipEnabled = state
            _G.LanderNoclipEnabled = state -- Update global reference for keybinds
            
            if state then
                startNoclip()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Noclip enabled - walk into walls freely!",
                    Duration = 3,
                    Icon = "ghost",
                })
            else
                stopNoclip()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Noclip disabled.",
                    Duration = 2,
                    Icon = "ghost",
                })
            end
        end
    })
    _G.LanderToggleElements.NoclipBypass = NoclipToggle

    local FlyMobileButtonsEnabled = false
    MovementSection:Toggle({
        Title = "Fly Mobile Buttons",
        Flag = "Fly_Mobile_Buttons",
        Desc = "Show fly controls on screen (mobile).",
        Default = false,
        Callback = function(state)
            FlyMobileButtonsEnabled = state
            if state then
                createFlyMobileUI()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Mobile fly buttons enabled.",
                    Duration = 2,
                    Icon = "smartphone",
                })
            else
                destroyFlyMobileUI()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Mobile fly buttons disabled.",
                    Duration = 2,
                    Icon = "smartphone",
                })
            end
        end
    })

    MovementSection:Slider({
        Title = "Fly Speed",
        Flag = "Fly_Speed",
        Desc = "Flight speed.",
        Step = 1,
        Value = { Min = 10, Max = 35, Default = 25 },
        Callback = function(v)
            FlySpeed = tonumber(v) or 25
        end
    })

    -- === WALK NOCLIP (Independent from Fly) ===
    local WalkNoclipEnabled = false
    _G.LanderWalkNoclipEnabled = false
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
        local now = os.clock()
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
        
        for _, plr in ipairs(Players:GetPlayers()) do
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
        for _, dir in ipairs(NOCLIP_DIRECTIONS_18) do
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
        for _, dir in ipairs(NOCLIP_DIRECTIONS_18) do
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
        
        local floorCheck = workspace:Raycast(pos, Vector3.new(0, -500, 0), walkNoclipRayParams)
        
        if floorCheck and floorCheck.Instance then
            if floorCheck.Instance:IsA("Terrain") then
                return floorCheck.Distance < 0.1 or pos.Y < floorCheck.Position.Y
            end
        end
        
        local ceilingCheck = workspace:Raycast(pos, Vector3.new(0, 500, 0), walkNoclipRayParams)
        if ceilingCheck and ceilingCheck.Instance and ceilingCheck.Instance:IsA("Terrain") then
            return true
        end
        
        return false
    end
    
    -- Loop teleport to position (bypass mechanic from Fly Noclip)
    local function walkNoclipLoopTP(targetPos, duration)
        walkIsLoopTeleporting = true
        walkTeleportEndTime = os.clock() + (duration or 1)
        
        if walkNoclipTeleportConn then
            walkNoclipTeleportConn:Disconnect()
        end
        
        walkNoclipTeleportConn = RunService.Heartbeat:Connect(function()
            if not walkIsLoopTeleporting or os.clock() > walkTeleportEndTime then
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
                hrp.CFrame = CFrame.new(targetPos) * rot
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
        walkWallEntryTime = os.clock()
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
        
        -- Main loop - monitor wall entry/exit and handle CFrame movement (BYPASS MECHANIC from Fly Noclip)
        -- PERF: Throttle wall raycasts to every 3 frames
        local _walkWallCheckFrame = 0
        local _walkLastInWall = false
        walkNoclipConn = RunService.RenderStepped:Connect(function(deltaTime)
            if not WalkNoclipEnabled then return end
            
            local character = LocalPlayer.Character
            if not character then return end
            
            local hum = character:FindFirstChildOfClass("Humanoid")
            local headPart = character:FindFirstChild("Head")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not hum or not headPart or not rootPart then return end
            
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
                local timeInWall = os.clock() - walkWallEntryTime
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
                local moveDirection = hum.MoveDirection * (walkNoclipSpeed * deltaTime)
                
                -- Vertical movement (E = up, Q = down) - SAME AS FLY NOCLIP
                local verticalMove = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    verticalMove = walkNoclipSpeed * deltaTime
                elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    verticalMove = -walkNoclipSpeed * deltaTime
                end
                
                local headCFrame = headPart.CFrame
                local camera = workspace.CurrentCamera
                local cameraCFrame = camera.CFrame
                
                -- Calculate camera offset
                local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
                cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
                
                local cameraPosition = cameraCFrame.Position
                local headPosition = headCFrame.Position
                
                -- Convert movement to camera-relative (FULL 3D like Fly Noclip)
                local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
                objectSpaceVelocity = objectSpaceVelocity + Vector3.new(0, verticalMove, 0)
                
                -- Calculate new position (full 3D movement)
                local newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)
                
                -- Prevent underground (safety check)
                if isWalkUnderground(newPos) then
                    if objectSpaceVelocity.Y < 0 then
                        objectSpaceVelocity = Vector3.new(objectSpaceVelocity.X, 0, objectSpaceVelocity.Z)
                    end
                    newPos = headPosition + (cameraCFrame - cameraPosition):VectorToWorldSpace(objectSpaceVelocity)
                    
                    if isWalkUnderground(newPos) then
                        newPos = headPosition
                    end
                end
                
                -- Move head via CFrame (bypass mechanic - client-only movement)
                headPart.CFrame = CFrame.new(newPos) * (cameraCFrame - cameraPosition)
                
                -- Update last position
                walkLastPosition = headPart.Position
            else
                -- Not in CFrame mode, just track position
                walkLastPosition = rootPart.Position
                walkServerPosition = rootPart.Position
            end
            
            _G.WalkNoclipLastValidPosition = walkServerPosition
        end)
        
        -- Collision disable loop (bypass mechanic)
        -- Cache character parts to avoid GetChildren every Stepped frame
        local _walkNoclipCollisionChar = nil
        local _walkNoclipCollisionParts = {}
        local function _rebuildWalkNoclipCollisionCache(char)
            _walkNoclipCollisionChar = char
            _walkNoclipCollisionParts = {}
            for _, partName in ipairs(NOCLIP_PARTS) do
                local part = char:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    table.insert(_walkNoclipCollisionParts, part)
                end
            end
            for _, child in ipairs(char:GetChildren()) do
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
            
            -- Disable collision on all cached parts (no GetChildren call per frame)
            -- PERF: Removed pcall wrapper - parts are validated from cache
            for _, part in ipairs(_walkNoclipCollisionParts) do
                if part.Parent then
                    part.CanCollide = false
                end
            end
        end)
    end
    
    local function stopWalkNoclip()
        WalkNoclipEnabled = false
        _G.LanderWalkNoclipEnabled = false
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
            for _, partName in ipairs(NOCLIP_PARTS) do
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
    
    _G.LanderStopWalkNoclip = stopWalkNoclip
    
    -- Re-setup on respawn (bypass mechanic)
    LocalPlayer.CharacterAdded:Connect(function(newChar)
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
    local WalkNoclipToggle = MovementSection:Toggle({
        Title = "Walk Noclip Bypass",
        Flag = "Walk_Noclip_Bypass",
        Desc = "Fly through walls (no Fly required, unstable).",
        Default = false,
        Callback = function(state)
            WalkNoclipEnabled = state
            _G.LanderWalkNoclipEnabled = state
            
            if state then
                startWalkNoclip()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Walk Noclip enabled - fly through walls freely!",
                    Duration = 3,
                    Icon = "move",
                })
            else
                stopWalkNoclip()
                WindUI:Notify({
                    Title = "Server Modifiers",
                    Content = "Walk Noclip disabled.",
                    Duration = 2,
                    Icon = "move",
                })
            end
        end
    })
    _G.LanderToggleElements.WalkNoclipBypass = WalkNoclipToggle
    
    -- Walk Noclip Speed (controls movement speed in all directions)
    MovementSection:Slider({
        Title = "Walk Noclip Speed",
        Flag = "Walk_Noclip_Speed",
        Desc = "Speed while flying through walls.",
        Step = 1,
        Value = { Min = 8, Max = 35, Default = 16 },
        Callback = function(v)
            walkNoclipSpeed = tonumber(v) or 16
        end
    })

    -- === Server utilities ===
    ServerSection:Button({
        Title = "Rejoin Server",
        Desc = "Leave and rejoin the same server.",
        Callback = function()
            WindUI:Notify({ Title = "Server", Content = "Rejoining server...", Duration = 3, Icon = "refresh-cw" })
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
    })

    ServerSection:Button({
        Title = "Server Hop",
        Desc = "Hop to a different server.",
        Callback = function()
            WindUI:Notify({ Title = "Server", Content = "Finding new server...", Duration = 3, Icon = "server" })
            local servers = {}
            local success, result = pcall(function()
                return game:HttpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
            end)
            if success and result and type(result) == "string" then
                local ok, data = pcall(function() return HttpService:JSONDecode(result) end)
                if ok and data and data.data then
                    for _, v in pairs(data.data) do
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(servers, v.id) end
                    end
                end
            end
            if #servers > 0 then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1,#servers)], LocalPlayer) end)
            else
                WindUI:Notify({ Title = "Error", Content = "No available servers found.", Duration = 5, Icon = "server-crash" })
            end
        end
    })

    -- end block
end -- end of Misc Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Maps Hacks Tab
    local MapsHacksTab = EventTab -- Maps Hacks goes inside EventTab
    
    local BerezinaSection = MapsHacksTab:Section({
        Title = "Berezina",
        Icon = "hammer",
        Opened = false
    })
    
    -- ===== BEREZINA MAP FEATURES =====
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    
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
        local now = os.clock()
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
        
        local nearest, dist = nil, math.huge
        
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
            _G.SafeFireServer(hammerRemote, "Repair", target)
        end)
    end
    
    local autoRepairBridgeTicker = 0
    local AutoRepairBridgeToggle = BerezinaSection:Toggle({
        Title = "Auto Repair Bridge",
        Flag = "Auto_Repair_Bridge",
        Desc = "Auto repair the bridge.",
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
                WindUI:Notify({
                    Title = "Auto Repair Bridge",
                    Content = "Enabled",
                    Duration = 3,
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
    _G.LanderToggleElements = _G.LanderToggleElements or {}
    _G.LanderToggleElements.AutoRepairBridge = AutoRepairBridgeToggle
    
    -- Auto Grab Log (finds nearest log)
    local autoGrabLogEnabled = false
    local autoGrabLogThread = nil
    local AUTO_GRAB_LOG_MAX_DISTANCE = 7 -- Only fire if within 7 studs
    
    -- Helper: Find nearest log interact remote (returns remote and distance)
    local function findNearestLogInteract()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
        local root = char.HumanoidRootPart
        
        local holdout = Workspace:FindFirstChild("Berezina")
            and Workspace.Berezina:FindFirstChild("Modes")
            and Workspace.Berezina.Modes:FindFirstChild("Holdout")
        
        if not holdout then return nil, math.huge end
        
        local nearest, nearestDist = nil, math.huge
        
        -- Search for all Log folders in Holdout
        for _, child in pairs(holdout:GetChildren()) do
            if child.Name == "Log" or child.Name:find("Log") then
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
    
    local AutoGrabLogToggle = BerezinaSection:Toggle({
        Title = "Auto Grab Log",
        Flag = "Auto_Grab_Log",
        Desc = "Auto grab the nearest log.",
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
                                _G.SafeFireServer(logInteract)
                            end
                        end)
                        task.wait(0.05) -- Faster loop for quicker pickup
                    end
                end)
                WindUI:Notify({
                    Title = "Auto Grab Log",
                    Content = "Enabled - Grabs nearest log.",
                    Duration = 3,
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
    _G.LanderToggleElements.AutoGrabLog = AutoGrabLogToggle
    
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
        
        local now = os.clock()
        
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
                -- FIXED: Use targeted search instead of GetDescendants (which creates huge tables)
                -- Look in known locations for PlaceLogProximityPrompt
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
        local nearest, nearestDist = nil, math.huge
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
    
    local AutoPlaceLogToggle = BerezinaSection:Toggle({
        Title = "Auto Place Log",
        Flag = "Auto_Place_Log",
        Desc = "Auto place logs on the bridge.",
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
                WindUI:Notify({
                    Title = "Auto Place Log",
                    Content = "Enabled - Places on nearest spot.",
                    Duration = 3,
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
    _G.LanderToggleElements.AutoPlaceLog = AutoPlaceLogToggle
    
    -- Character respawn cleanup
    LocalPlayer.CharacterAdded:Connect(function()
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
    
    -- ===== END BEREZINA FEATURES =====
    
    -- ===== VARDOHUS FORTRESS MAP FEATURES =====
    local VardohusSection = MapsHacksTab:Section({
        Title = "Vardohus Fortress",
        Icon = "crosshair",
        Opened = false
    })
    
    -- OPTIMIZATION: Use same pattern as zombie ESP
    -- ESP Data storage with WEAK TABLES for automatic garbage collection
    local roundshotESPData = setmetatable({}, { __mode = "k" }) -- Weak keys - auto GC
    local swabESPData = setmetatable({}, { __mode = "k" }) -- Weak keys - auto GC
    local vardohusUpdateConn = nil
    local vardohusScanLoop = nil -- single shared scan loop (not per-toggle)
    
    -- Track items pending removal (grace period to prevent flicker like zombie ESP)
    local ESPPendingRemoval = setmetatable({}, { __mode = "k" }) -- [item] = os.clock() when marked
    local ESP_REMOVAL_GRACE_PERIOD = 0.5 -- Same as zombie ESP
    
    -- Performance constants (copied from zombie ESP pattern)
    local VARDOHUS_MAX_DISTANCE = 250 -- Reduced to 250 studs for better performance
    local VARDOHUS_CREATION_MAX_DISTANCE = 250 -- Create ESP within 250 studs
    local VARDOHUS_SCAN_BATCH_SIZE = 20 -- Same as zombie ESP batch size
    local ChamsTransparency = 0.5
    
    -- Camera caching (same as zombie ESP)
    local cachedCameraPos = Vector3.new(0, 0, 0)
    local lastCameraCacheTime = 0
    local CAMERA_CACHE_INTERVAL = 0.2 -- Update camera cache every 0.2 seconds (these are static items)
    
    -- Colors
    local ROUNDSHOT_COLOR = Color3.fromRGB(255, 100, 100) -- Red for 12 lb. Roundshots
    local SWAB_COLOR = Color3.fromRGB(255, 255, 0) -- Yellow for swab
    
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
        for _, p in ipairs(children) do
            if p:IsA("BasePart") then
                return p
            end
        end
        -- Fallback: check first-level folders only
        for _, child in ipairs(children) do
            if child:IsA("Folder") or child:IsA("Model") then
                for _, p in ipairs(child:GetChildren()) do
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
        
        -- PERFORMANCE: Removed per-create orphan cleanup (was iterating children every time)
        -- Orphan cleanup only happens on toggle-off via clearESPData/nukeAllVardohusESPVisuals
        
        local data = {}
        espData[item] = data
        data.maxDistance = VARDOHUS_MAX_DISTANCE
        local offset = Vector3.new(0, 3, 0)
        
        -- CREATE HIGHLIGHT (same as zombie ESP)
        local hl = Instance.new("Highlight")
        hl.Name = _G.getRandomStealthName and _G.getRandomStealthName() or ("HL_" .. math.random(10000, 99999))
        hl.Adornee = item
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
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
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 1
        frame.BorderColor3 = color
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        frame.Parent = bb
        
        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = Vector2.new(0.5, 0)
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
        distLbl.AnchorPoint = Vector2.new(0.5, 1)
        distLbl.Position = UDim2.new(0.5, 0, 0.9, 0)
        distLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "0 studs"
        distLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
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
        for _, item in ipairs(toRemove) do
            removeVardohusESP(item, espData)
        end
    end
    
    -- Collect Vardohus items (same pattern as zombie ESP CollectZombies)
    -- PERFORMANCE: Results are cached to avoid expensive GetDescendants() every scan
    local function CollectVardohusItems(forceRefresh)
        -- Cache Vardohus reference
        if not cachedVardohusRef or not cachedVardohusRef.Parent then
            cachedVardohusRef = Workspace:FindFirstChild("Vardohus Fortress")
        end
        if not cachedVardohusRef then return {}, {} end
        
        local now = os.clock()
        -- Return cached results if still fresh (items are static, no need to rescan often)
        if not forceRefresh and (now - lastItemCollectTime) < ITEM_COLLECT_INTERVAL then
            return cachedRoundshots, cachedSwabs
        end
        lastItemCollectTime = now
        
        local roundshots = {}
        local swabs = {}
        
        -- Collect all descendants once (expensive operation, cached for ITEM_COLLECT_INTERVAL)
        local descendants = cachedVardohusRef:GetDescendants()
        for _, obj in ipairs(descendants) do
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
        local now = os.clock()
        
        -- Throttle scanning (same as zombie ESP)
        if now - lastVardohusScan < VARDOHUS_SCAN_INTERVAL then
            return
        end
        lastVardohusScan = now
        
        local roundshots, swabs = CollectVardohusItems()
        
        -- Update camera cache (same as zombie ESP)
        if now - lastCameraCacheTime >= CAMERA_CACHE_INTERVAL then
            local cam = workspace.CurrentCamera
            cachedCameraPos = cam and cam.CFrame.Position or Vector3.new(0, 0, 0)
            lastCameraCacheTime = now
        end
        
        -- Build item sets for fast lookups (same pattern as zombie ESP)
        local roundshotSet = {}
        for _, r in ipairs(roundshots) do
            roundshotSet[r] = true
        end
        local swabSet = {}
        for _, s in ipairs(swabs) do
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
            for _, item in ipairs(toRemove) do
                removeVardohusESP(item, roundshotESPData)
            end
            
            -- Add ESP for new items (with batch limiting like zombie ESP)
            local created = 0
            for _, item in ipairs(roundshots) do
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
            for _, item in ipairs(toRemove) do
                removeVardohusESP(item, swabESPData)
            end
            
            local created = 0
            for _, item in ipairs(swabs) do
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
    
    -- Update ESP visuals at capped rate
    -- PERFORMANCE: Uses Heartbeat instead of RenderStepped (doesn't need frame sync)
    local _vardohusLastUpdate = 0
    local VARDOHUS_UPDATE_INTERVAL = 0.25 -- 4fps is plenty for static item ESP (was 0.1)
    local function UpdateAllVardohus()
        local now = os.clock()
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
                    -- ESP disabled – destroy immediately, don't just hide
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
                                data.distLabel.Text = math.floor(dist) .. " studs"
                            end
                        end
                    end
                end
            end
            -- Remove dead / disabled items safely after iteration
            for _, item in ipairs(toRemove) do
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
    local function forceDisableESP(espData)
        local toRemove = {}
        for item in pairs(espData) do
            table.insert(toRemove, item)
        end
        for _, item in ipairs(toRemove) do
            local data = espData[item]
            if data then
                if data.highlight then pcall(function() data.highlight.Enabled = false end) end
                if data.billboard then pcall(function() data.billboard.Enabled = false end) end
                if data.highlight then pcall(function() data.highlight.Parent = nil end) end
                if data.billboard then pcall(function() data.billboard.Parent = nil end) end
                if data.highlight then pcall(function() data.highlight:Destroy() end) end
                if data.billboard then pcall(function() data.billboard:Destroy() end) end
                data.highlight = nil
                data.billboard = nil
            end
            espData[item] = nil
        end
    end
    
    -- Brute-force scan Vardohus Fortress and remove ALL orphaned ESP visuals from items
    local function nukeAllVardohusESPVisuals()
        pcall(function()
            local fortress = Workspace:FindFirstChild("Vardohus Fortress")
            if not fortress then return end
            for _, desc in ipairs(fortress:GetDescendants()) do
                if desc:IsA("Model") then
                    local name = desc.Name:lower()
                    if name:find("12 lb") or name:find("roundshot") or name:find("swab") then
                        for _, child in ipairs(desc:GetChildren()) do
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
    local RoundshotESPToggle = VardohusSection:Toggle({
        Title = "12 lb. Roundshots ESP",
        Flag = "12_lb_Roundshots_ESP",
        Desc = "Red ESP for 12 lb. Roundshots (cannon ammo).",
        Icon = "box",
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
                
                WindUI:Notify({
                    Title = "12 lb. Roundshots ESP",
                    Content = "Enabled - Red markers show ammunition.",
                    Duration = 3,
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
    _G.LanderToggleElements.RoundshotESP = RoundshotESPToggle
    
    -- Swab ESP Toggle
    local SwabESPToggle = VardohusSection:Toggle({
        Title = "Swab ESP (Yellow)",
        Flag = "Swab_ESP_Yellow",
        Desc = "Yellow ESP for Swab items.",
        Icon = "droplet",
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
                
                WindUI:Notify({
                    Title = "Swab ESP",
                    Content = "Enabled - Yellow markers show swabs.",
                    Duration = 3,
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
    _G.LanderToggleElements.SwabESP = SwabESPToggle
    
    -- Cleanup on respawn
    LocalPlayer.CharacterAdded:Connect(function()
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
    
    -- ===== END VARDOHUS FORTRESS FEATURES =====
    
    -- ===== SAINT PETERSBURG MAP FEATURES =====
    local SaintPetersburgSection = MapsHacksTab:Section({
        Title = "Saint Petersburg",
        Icon = "shopping-cart",
        Opened = false
    })

    local STPETE_ITEMS = {
        "LampLighter",
        "GrenadeBox",
        "BandageBox",
        "CanisterShot",
        "Roundshot",
    }

    local selectedSupply = "LampLighter"

    SaintPetersburgSection:Dropdown({
        Title = "Supply Item",
        Flag = "Supply_Item",
        Desc = "Select item to buy from Hobo's Shop.",
        Values = STPETE_ITEMS,
        Value = "LampLighter",
        Multi = false,
        Callback = function(selection)
            selectedSupply = tostring(selection or "LampLighter")
        end
    })

    SaintPetersburgSection:Button({
        Title = "Buy Supply",
        Desc = "Purchase selected item.",
        Icon = "shopping-cart",
        Callback = function()
            if not selectedSupply or selectedSupply == "" then
                WindUI:Notify({
                    Title = "Saint Petersburg",
                    Content = "Select an item first!",
                    Duration = 2,
                    Icon = "alert-circle"
                })
                return
            end
            local success, err = pcall(function()
                local Event = game:GetService("ReplicatedStorage").Remotes.HoldoutOrderShopEvent
                Event:FireServer("BuySupply", selectedSupply)
            end)
            if success then
                WindUI:Notify({
                    Title = "Saint Petersburg",
                    Content = "Purchased: " .. selectedSupply,
                    Duration = 2,
                    Icon = "check"
                })
            else
                WindUI:Notify({
                    Title = "Saint Petersburg",
                    Content = "Purchase failed — wrong map?",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end
    })

    -- ===== END SAINT PETERSBURG FEATURES =====
end

task.wait(0.1) -- Delay to prevent lag
do -- // PVP Tab
    local PVPTab = CombatTab -- PVP goes inside CombatTab
    
    local PVPSection = PVPTab:Section({
        Title = "PVP Combat",
        Icon = "crosshair",
        Opened = true
    })
    
    -- ===== PVP FEATURES =====
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    -- Shared PVP Settings (used by both Melee and Bayonet)
    local PVP_RANGE = 15
    local PVP_DELAY = 0.05
    local PVP_MULTI_TARGET = 3
    
    -- PVP Kill Aura (Melee)
    local pvpMeleeEnabled = false
    local pvpMeleeConn = nil

    local function getMeleeWeapon()
        local char = LocalPlayer.Character
        if not char then return nil end

        -- Check equipped
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("MeleeBase") then
                return tool
            end
        end

        -- Check backpack
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("MeleeBase") then
                return tool
            end
        end

        return nil
    end
    
    local function getPlayerDistance(target)
        local char = LocalPlayer.Character
        if not char or not target or not target:FindFirstChild("HumanoidRootPart") then
            return math.huge
        end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return math.huge end
        return (target.HumanoidRootPart.Position - myRoot.Position).Magnitude
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
            if weapon.Parent ~= char then
                weapon.Parent = char
                task.wait(0.1)
            end
            
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
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
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
        local rCount = math.min(tCount, maxTargets)
        for i = 1, rCount do
            _pvpResultBuf[i] = _pvpTargetsBuf[i]
        end
        return _pvpResultBuf
    end
    
    local pvpMeleeLastAttack = 0
    local function pvpMeleeUpdate()
        if not pvpMeleeEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Delay check
        if os.clock() - pvpMeleeLastAttack < PVP_DELAY then return end
        pvpMeleeLastAttack = os.clock()
        
        local targets = getNearbyEnemyPlayers(PVP_RANGE, PVP_MULTI_TARGET)
        for _, targetPlayer in ipairs(targets) do
            attackPlayerMelee(targetPlayer)
        end
    end
    
    local PVPMeleeToggle = PVPSection:Toggle({
        Title = "PVP Kill Aura",
        Flag = "Kill_Aura_1",
        Desc = "Auto melee attack nearby enemy players.",
        Default = false,
        Callback = function(state)
            pvpMeleeEnabled = state
            if state then
                if pvpMeleeConn then pvpMeleeConn:Disconnect() end
                pvpMeleeConn = RunService.Heartbeat:Connect(pvpMeleeUpdate)
                WindUI:Notify({
                    Title = "PVP Kill Aura",
                    Content = "Enabled PVP Kill Aura.",
                    Duration = 3,
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
    _G.LanderToggleElements.PVPMelee = PVPMeleeToggle
    
    -- PVP Kill Aura (Bayonet)
    local pvpBayonetEnabled = false
    local pvpBayonetConn = nil
    
    local function getMusket()
        local char = LocalPlayer.Character
        if not char then return nil end
        
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "Musket" then
                return tool
            end
        end
        
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
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
        
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Delay check
        if os.clock() - pvpBayonetLastAttack < PVP_DELAY then return end
        pvpBayonetLastAttack = os.clock()
        
        local targets = getNearbyEnemyPlayers(PVP_RANGE, PVP_MULTI_TARGET)
        for _, targetPlayer in ipairs(targets) do
            attackPlayerBayonet(targetPlayer)
        end
    end
    
    local PVPBayonetToggle = PVPSection:Toggle({
        Title = "PVP Kill Aura Bayonet",
        Flag = "Kill_Aura_Bayonet",
        Desc = "Auto bayonet attack nearby enemy players.",
        Default = false,
        Callback = function(state)
            pvpBayonetEnabled = state
            if state then
                if pvpBayonetConn then pvpBayonetConn:Disconnect() end
                pvpBayonetConn = RunService.Heartbeat:Connect(pvpBayonetUpdate)
                WindUI:Notify({
                    Title = "PVP Kill Aura Bayonet",
                    Content = "Enabled PVP Kill Aura Bayonet.",
                    Duration = 3,
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
    _G.LanderToggleElements.PVPBayonet = PVPBayonetToggle
    
    -- Shared PVP Settings Sliders
    PVPSection:Slider({
        Title = "PVP Range",
        Desc = "Attack range for Melee and Bayonet Kill Aura.",
        Flag = "Range",
        Step = 1,
        Value = { Min = 5, Max = 30, Default = PVP_RANGE },
        Callback = function(value)
            PVP_RANGE = value
        end
    })
    
    PVPSection:Slider({
        Title = "PVP Delay",
        Desc = "Delay between attacks.",
        Flag = "Delay",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = PVP_DELAY },
        Callback = function(value)
            PVP_DELAY = value
        end
    })
    
    PVPSection:Slider({
        Title = "PVP Multi-Target",
        Desc = "Players hit per swing.",
        Flag = "Multi_Target_1",
        Step = 1,
        Value = { Min = 1, Max = 10, Default = PVP_MULTI_TARGET },
        Callback = function(value)
            PVP_MULTI_TARGET = value
        end
    })
    
    -- ===== PVP WHITELIST SYSTEM =====
    -- Shared whitelist for all PVP features (Kill Aura, Bayonet, Teleport, Silent Aim)
    local PVP_Whitelist = {} -- Array of player names to NOT attack
    local PVP_WhitelistDropdown = nil
    local isPVPWhitelistRefreshing = false
    
    -- Helper: Check if player is whitelisted
    local function isPVPWhitelisted(playerName)
        for _, name in ipairs(PVP_Whitelist) do
            if name == playerName then return true end
        end
        return false
    end
    
    -- Helper: Get list of enemy players for dropdown (not same team)
    local function getPVPWhitelistPlayers()
        local names = {"None"}
        for _, player in ipairs(Players:GetPlayers()) do
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
            if PVP_WhitelistDropdown and PVP_WhitelistDropdown.Refresh then
                PVP_WhitelistDropdown:Refresh(getPVPWhitelistPlayers())
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
        for i, name in ipairs(PVP_Whitelist) do
            if name == player.Name then
                table.remove(PVP_Whitelist, i)
                break
            end
        end
        task.delay(0.1, refreshPVPWhitelistDropdown)
    end)
    
    -- PVP Whitelist Dropdown
    PVP_WhitelistDropdown = PVPSection:Dropdown({
        Title = "PVP Whitelist",
        Flag = "Whitelist",
        Desc = "Players who won't be attacked.",
        Values = getPVPWhitelistPlayers(),
        Value = {},
        Multi = true,
        Callback = function(selection)
            local filtered = {}
            local hasNone = false
            for _, name in ipairs(selection or {}) do
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
        local targets = {}
        local char = LocalPlayer.Character
        if not char then return targets end
        local myRoot = char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return targets end
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                -- Skip whitelisted players
                if isPVPWhitelisted(targetPlayer.Name) then continue end
                
                local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and not isSameTeam(targetPlayer) then
                    local dist = (targetRoot.Position - myRoot.Position).Magnitude
                    if dist <= range then
                        table.insert(targets, {player = targetPlayer, dist = dist})
                    end
                end
            end
        end
        
        -- Sort by distance (closest first)
        table.sort(targets, function(a, b) return a.dist < b.dist end)
        
        -- Return up to maxTargets
        local result = {}
        for i = 1, math.min(#targets, maxTargets) do
            table.insert(result, targets[i].player)
        end
        return result
    end
    
    -- Override the original function to use filtered version
    getNearbyEnemyPlayers = getNearbyEnemyPlayersFiltered
    
    -- God Mode Teleport Section
    local GodModeSection = PVPTab:Section({
        Title = "Tp",
        Icon = "zap",
        Opened = false
    })
    
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
    
    -- Updated to respect whitelist
    -- Pre-allocated buffer for getValidPVPTargets
    local _validPVPTargetsBuf = {}

    local function getValidPVPTargets()
        -- Clear without allocating new table
        for i = #_validPVPTargetsBuf, 1, -1 do _validPVPTargetsBuf[i] = nil end
        local count = 0
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
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
        local now = os.clock()
        if now - _godLastTargetScan >= 0.5 then
            _godLastTargetScan = now
            _godCachedTargets = getValidPVPTargets()
        end
        local targets = _godCachedTargets
        if #targets == 0 then
            return
        end
        
        if os.clock() - lastTargetSwitch >= GOD_COOLDOWN then
            currentGodTarget = targets[math.random(1, #targets)]
            lastTargetSwitch = os.clock()
            floatOffset = 0
        end
        
        if currentGodTarget and currentGodTarget.Character then
            local targetRoot = currentGodTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                floatOffset = math.sin(os.clock() * GOD_FLOAT_SPEED) * GOD_FLOAT_HEIGHT
                
                local backVector = targetRoot.CFrame.LookVector * -GOD_SAFE_DISTANCE
                local floatVector = Vector3.new(0, floatOffset, 0)
                myRoot.CFrame = CFrame.new(
                    targetRoot.Position + backVector + floatVector,
                    targetRoot.Position + floatVector
                )
            end
        end
    end
    
    local GodTeleportToggle = GodModeSection:Toggle({
        Title = "Orbit Teleport",
        Flag = "Orbit_Teleport",
        Desc = "Orbit random enemy players.",
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
                WindUI:Notify({
                    Title = "Orbit Teleport",
                    Content = "Enabled - Orbiting around enemies.",
                    Duration = 3,
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
    _G.LanderToggleElements.GodTeleport = GodTeleportToggle
    
    -- Character respawn cleanup - PVP Kill Auras use Heartbeat connections, no cleanup needed
    -- They automatically handle dead/missing characters gracefully
    
    -- ===== END PVP FEATURES =====
end

task.wait(0.1) -- Delay to prevent lag
do -- // Keybinds and UI Tab
    local KeybindsTab = MiscTab -- Keybinds goes inside MiscTab

    -- Mobile Button UI System
    local MobileButtons = {}
    local MobileButtonSettings = {
        Transparency = 0.1,
        Size = 52
    }
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    
    -- Color palette (clean, professional)
    local Colors = {
        Background = Color3.fromRGB(22, 22, 26),
        Surface = Color3.fromRGB(32, 32, 38),
        SurfaceLight = Color3.fromRGB(45, 45, 52),
        Primary = Color3.fromRGB(229, 57, 53), -- #E53935
        PrimaryDark = Color3.fromRGB(198, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(140, 140, 150),
        Border = Color3.fromRGB(55, 55, 62),
        Success = Color3.fromRGB(76, 175, 80),
    }
    
    local function createMobileButton(name, toggleKey, getStateFunc)
        if MobileButtons[name] then
            pcall(function() MobileButtons[name].Frame:Destroy() end)
            MobileButtons[name] = nil
        end
        
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        
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
        blur.Parent = game:GetService("Lighting")
        
        -- Dark overlay
        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
        
        local function updateStateIndicator()
            local state = getStateFunc and getStateFunc() or false
            local targetColor = state and Colors.Success or Colors.Primary
            local targetText = state and "ON" or "OFF"
            TweenService:Create(stateBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(buttonStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Color = targetColor}):Play()
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
            local targetPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            TweenService:Create(button, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos
            }):Play()
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
        
        -- Input handlers
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if settingsOpen then return end
                dragging = true
                dragStart = input.Position
                startPos = button.Position
                holdStart = os.clock()
                isHolding = true
                
                TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(0, MobileButtonSettings.Size * 0.94, 0, MobileButtonSettings.Size * 0.94)
                }):Play()
                
                task.spawn(function()
                    while isHolding and os.clock() - holdStart < 0.5 do
                        task.wait(0.02)
                    end
                    if isHolding and os.clock() - holdStart >= 0.5 and not settingsOpen then
                        isHolding = false
                        dragging = false
                        TweenService:Create(buttonStroke, TweenInfo.new(0.08), {Thickness = 3}):Play()
                        task.delay(0.08, function()
                            TweenService:Create(buttonStroke, TweenInfo.new(0.08), {Thickness = 2}):Play()
                        end)
                        openSettings()
                    end
                end)
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 8 then
                    isHolding = false
                end
                updateDrag(input)
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, MobileButtonSettings.Size, 0, MobileButtonSettings.Size)
                }):Play()
                
                if isHolding and not settingsOpen and os.clock() - holdStart < 0.5 then
                    local toggle = _G.LanderToggleElements and _G.LanderToggleElements[toggleKey]
                    if toggle and toggle.Set then
                        local currentState = getStateFunc and getStateFunc() or false
                        toggle:Set(not currentState)
                    end
                    task.delay(0.1, updateStateIndicator)
                end
                dragging = false
                isHolding = false
            end
        end)
        
        overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                closeSettings()
            end
        end)
        
        applyBtn.MouseButton1Click:Connect(closeSettings)
        applyBtn.TouchTap:Connect(closeSettings)
        
        -- Button hover/press effects
        applyBtn.MouseEnter:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.PrimaryDark}):Play()
        end)
        applyBtn.MouseLeave:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Primary}):Play()
        end)
        applyBtn.MouseButton1Down:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(170, 35, 35)}):Play()
        end)
        applyBtn.MouseButton1Up:Connect(function()
            TweenService:Create(applyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Primary}):Play()
        end)
        
        -- Input focus effects
        transpInput.Focused:Connect(function()
            TweenService:Create(transpInputStroke, TweenInfo.new(0.1), {Color = Colors.Primary}):Play()
        end)
        transpInput.FocusLost:Connect(function()
            TweenService:Create(transpInputStroke, TweenInfo.new(0.1), {Color = Colors.Border}):Play()
            local val = tonumber(transpInput.Text)
            if val and val >= 0 and val <= 1 then
                MobileButtonSettings.Transparency = val
                updateButtonAppearance()
            else
                transpInput.Text = tostring(MobileButtonSettings.Transparency)
            end
        end)
        
        sizeInput.Focused:Connect(function()
            TweenService:Create(sizeInputStroke, TweenInfo.new(0.1), {Color = Colors.Primary}):Play()
        end)
        sizeInput.FocusLost:Connect(function()
            TweenService:Create(sizeInputStroke, TweenInfo.new(0.1), {Color = Colors.Border}):Play()
            local val = tonumber(sizeInput.Text)
            if val and val >= 30 and val <= 100 then
                MobileButtonSettings.Size = val
                updateButtonAppearance()
            else
                sizeInput.Text = tostring(MobileButtonSettings.Size)
            end
        end)
        
        -- Update state periodically
        task.spawn(function()
            while button and button.Parent do
                updateStateIndicator()
                task.wait(0.5)
            end
        end)
        
        updateStateIndicator()
        
        MobileButtons[name] = {
            Frame = screenGui,
            Blur = blur,
            Update = updateStateIndicator
        }
        
        return MobileButtons[name]
    end
    
    local function destroyMobileButton(name)
        if MobileButtons[name] then
            pcall(function()
                if MobileButtons[name].Blur then
                    MobileButtons[name].Blur:Destroy()
                end
                MobileButtons[name].Frame:Destroy()
            end)
            MobileButtons[name] = nil
        end
    end

    local KeybindsSection = KeybindsTab:Section({ Title = "Toggle Keybinds", Icon = "key", Opened = true })

    KeybindsSection:Paragraph({
        Title = "How to use",
        Desc = "Click a keybind button then press your key. Mobile: tap the toggle to set a button. Hold to view settings."
    })

    -- Head Hit Keybind
    KeybindsSection:Keybind({
        Title = "Head Lock",
        Flag = "Toggle_Keybinds",
        Desc = "Toggle Head Hit.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.HeadHit
                if toggle then
                    toggle:Set(not HeadHitEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Head Hit Button UI",
        Flag = "Head_Hit_Button_UI",
        Desc = "Mobile button for Head Hit.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Head Hit", "HeadHit", function() return HeadHitEnabled end)
            else
                destroyMobileButton("Head Hit")
            end
        end
    })

    -- Auto Jump Keybind
    KeybindsSection:Keybind({
        Title = "Auto Jump",
        Flag = "Auto_Jump",
        Desc = "Toggle Auto Jump.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoJump
                if toggle then
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local currentState = LocalPlayer:GetAttribute("AutoJumpEnabled") or false
                    toggle:Set(not currentState)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Jump Button UI",
        Flag = "Auto_Jump_Button_UI",
        Desc = "Mobile button for Auto Jump.",
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

    -- Hitbox Expander Keybind
    KeybindsSection:Keybind({
        Title = "Hitbox Expander",
        Flag = "Expander_1",
        Desc = "Toggle Hitbox Expander.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.HitboxExpander
                if toggle then
                    toggle:Set(not hitboxEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Hitbox Expander Button UI",
        Flag = "Expander_Button_UI",
        Desc = "Mobile button for Hitbox Expander.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Hitbox", "HitboxExpander", function() return hitboxEnabled end)
            else
                destroyMobileButton("Hitbox")
            end
        end
    })

    -- Shove Hitbox Expander Keybind
    KeybindsSection:Keybind({
        Title = "Shove Hitbox",
        Flag = "Shove_Hitbox_1",
        Desc = "Toggle Shove Hitbox.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.ShoveHitbox
                if toggle then
                    toggle:Set(not ShoveHitboxExpanderEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Shove Hitbox Button UI",
        Flag = "Shove_Button_UI",
        Desc = "Mobile button for Shove Hitbox.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Shove HB", "ShoveHitbox", function() return ShoveHitboxExpanderEnabled end)
            else
                destroyMobileButton("Shove HB")
            end
        end
    })

    -- Auto Parry Sapper Keybind
    KeybindsSection:Keybind({
        Title = "Auto Parry Sapper",
        Flag = "Auto_Parry_Sapper_1",
        Desc = "Toggle Auto Parry Sapper.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoParrySapper
                if toggle then
                    toggle:Set(not AutoParrySapperMeleeEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Parry Sapper Button UI",
        Flag = "Auto_Parry_Sapper_Button_UI",
        Desc = "Mobile button for Auto Parry Sapper.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Parry", "AutoParrySapper", function() return AutoParrySapperMeleeEnabled end)
            else
                destroyMobileButton("Parry")
            end
        end
    })

    -- Enable Auto Shoot Keybind
    KeybindsSection:Keybind({
        Title = "Auto Shoot",
        Flag = "Auto_Shoot",
        Desc = "Toggle Auto Shoot.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoShoot
                if toggle then
                    toggle:Set(not USER_AUTO_SHOOT_TOGGLE)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Shoot Button UI",
        Flag = "Auto_Shoot_Button_UI",
        Desc = "Mobile button for Auto Shoot.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Shoot", "AutoShoot", function() return USER_AUTO_SHOOT_TOGGLE end)
            else
                destroyMobileButton("Shoot")
            end
        end
    })

    -- Instant Shoot Keybind
    KeybindsSection:Keybind({
        Title = "Instant Shoot",
        Flag = "Instant_Shoot_1",
        Desc = "Toggle Instant Shoot.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.InstantShoot
                if toggle then
                    toggle:Set(not INSTANT_SHOOT_ENABLED)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Instant Shoot Button UI",
        Flag = "Instant_Shoot_Button_UI",
        Desc = "Mobile button for Instant Shoot.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Instant", "InstantShoot", function() return INSTANT_SHOOT_ENABLED end)
            else
                destroyMobileButton("Instant")
            end
        end
    })

    -- Use FOV Keybind
    KeybindsSection:Keybind({
        Title = "Use FOV",
        Flag = "Use_FOV",
        Desc = "Toggle Use FOV.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.UseFov
                if toggle then
                    toggle:Set(not USE_FOV)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Use FOV Button UI",
        Flag = "Use_FOV_Button_UI",
        Desc = "Mobile button for Use FOV.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("FOV", "UseFov", function() return USE_FOV end)
            else
                destroyMobileButton("FOV")
            end
        end
    })

    -- Show FOV Keybind
    KeybindsSection:Keybind({
        Title = "Show FOV",
        Flag = "Show_FOV",
        Desc = "Toggle Show FOV.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.ShowFov
                if toggle then
                    toggle:Set(not SHOW_FOV)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Show FOV Button UI",
        Flag = "Show_FOV_Button_UI",
        Desc = "Mobile button for Show FOV.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("ShowFOV", "ShowFov", function() return SHOW_FOV end)
            else
                destroyMobileButton("ShowFOV")
            end
        end
    })

    -- Wall Check Keybind
    KeybindsSection:Keybind({
        Title = "Wall Check",
        Flag = "Wall_Check",
        Desc = "Toggle Wall Check.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.WallCheck
                if toggle then
                    toggle:Set(not CHECK_WALLS)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Wall Check Button UI",
        Flag = "Wall_Check_Button_UI",
        Desc = "Mobile button for Wall Check.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Wall", "WallCheck", function() return CHECK_WALLS end)
            else
                destroyMobileButton("Wall")
            end
        end
    })

    -- Auto Reload Keybind
    KeybindsSection:Keybind({
        Title = "Auto Reload",
        Flag = "Auto_Reload_1",
        Desc = "Toggle Auto Reload.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoReload
                if toggle then
                    toggle:Set(not AUTO_RELOAD_ENABLED)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Reload Button UI",
        Flag = "Auto_Reload_Button_UI",
        Desc = "Mobile button for Auto Reload.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Reload", "AutoReload", function() return AUTO_RELOAD_ENABLED end)
            else
                destroyMobileButton("Reload")
            end
        end
    })

    -- Auto Save Players Keybind
    KeybindsSection:Keybind({
        Title = "Save Player",
        Flag = "Save_Player_1",
        Desc = "Toggle Auto Save Players.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoSavePlayers
                if toggle then
                    toggle:Set(not AUTO_SAVE_PLAYERS_ENABLED)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Save Players Button UI",
        Flag = "Auto_Save_Button_UI",
        Desc = "Mobile button for Auto Save Players.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Save", "AutoSavePlayers", function() return AUTO_SAVE_PLAYERS_ENABLED end)
            else
                destroyMobileButton("Save")
            end
        end
    })

    -- Kill Aura Keybind
    KeybindsSection:Keybind({
        Title = "Kill Aura",
        Flag = "Kill_Aura_2",
        Desc = "Toggle Kill Aura.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.KillAura
                if toggle then
                    toggle:Set(not KillAuraEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Kill Aura Button UI",
        Flag = "Kill_Aura_Button_UI",
        Desc = "Mobile button for Kill Aura.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("KillAura", "KillAura", function() return KillAuraEnabled end)
            else
                destroyMobileButton("KillAura")
            end
        end
    })

    -- Reach Keybind
    KeybindsSection:Keybind({
        Title = "Reach",
        Flag = "Reach_1",
        Desc = "Toggle Reach.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.Reach
                if toggle then
                    toggle:Set(not KillAura_HitboxExpanderEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Reach Button UI",
        Flag = "Reach_Button_UI",
        Desc = "Mobile button for Reach.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Reach", "Reach", function() return KillAura_HitboxExpanderEnabled end)
            else
                destroyMobileButton("Reach")
            end
        end
    })

    -- Auto Equip Melee Keybind
    KeybindsSection:Keybind({
        Title = "Auto Equip Melee",
        Flag = "Auto_Equip_Melee_1",
        Desc = "Toggle Auto Equip Melee.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoEquipMelee
                if toggle then
                    toggle:Set(not KillAura_AutoEquipMelee)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Equip Melee Button UI",
        Flag = "Auto_Equip_Melee_Button_UI",
        Desc = "Mobile button for Auto Equip Melee.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Equip", "AutoEquipMelee", function() return KillAura_AutoEquipMelee end)
            else
                destroyMobileButton("Equip")
            end
        end
    })

    -- Bayonet Kill Aura Keybind
    KeybindsSection:Keybind({
        Title = "Bayonet Kill Aura",
        Flag = "Bayonet_Kill_Aura",
        Desc = "Toggle Bayonet Kill Aura.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.BayonetKillAura
                if toggle then
                    toggle:Set(not KillAura_EnableBayonet)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Bayonet Kill Aura Button UI",
        Flag = "Bayonet_Kill_Aura_Button_UI",
        Desc = "Mobile button for Bayonet Kill Aura.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Bayonet", "BayonetKillAura", function() return KillAura_EnableBayonet end)
            else
                destroyMobileButton("Bayonet")
            end
        end
    })

    -- Auto Look Keybind
    KeybindsSection:Keybind({
        Title = "Auto Look",
        Flag = "Auto_Look_1",
        Desc = "Toggle Auto Look.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoLook
                if toggle then
                    toggle:Set(not KillAuraAutoLook)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Look Button UI",
        Flag = "Auto_Look_Button_UI",
        Desc = "Mobile button for Auto Look.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Look", "AutoLook", function() return KillAuraAutoLook end)
            else
                destroyMobileButton("Look")
            end
        end
    })

    -- Shove Aura Keybind
    KeybindsSection:Keybind({
        Title = "Shove Aura",
        Flag = "Shove_Aura_1",
        Desc = "Toggle Shove Aura.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.ShoveAura
                if toggle then
                    toggle:Set(not ShoveAuraEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Shove Aura Button UI",
        Flag = "Shove_Aura_Button_UI",
        Desc = "Mobile button for Shove Aura.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Shove", "ShoveAura", function() return ShoveAuraEnabled end)
            else
                destroyMobileButton("Shove")
            end
        end
    })

    -- Apply WalkSpeed Keybind
    KeybindsSection:Keybind({
        Title = "WalkSpeed Freeze",
        Flag = "WalkSpeed_Freeze_1",
        Desc = "Toggle Apply WalkSpeed.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.ApplyWalkSpeed
                if toggle then
                    toggle:Set(not walkLoopEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Apply WalkSpeed Button UI",
        Flag = "Apply_WalkSpeed_Button_UI",
        Desc = "Mobile button for WalkSpeed.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Speed", "ApplyWalkSpeed", function() return walkLoopEnabled end)
            else
                destroyMobileButton("Speed")
            end
        end
    })

    -- Auto Remove Horses Keybind
    KeybindsSection:Keybind({
        Title = "Auto Remove Horses",
        Flag = "Auto_Remove_Horses",
        Desc = "Toggle Auto Remove Horses.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.AutoRemoveHorses
                if toggle then
                    toggle:Set(not AutoRemoveHorsesEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Auto Remove Horses Button UI",
        Flag = "Auto_Remove_Horses_Button_UI",
        Desc = "Mobile button for Remove Horses.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Horses", "AutoRemoveHorses", function() return AutoRemoveHorsesEnabled end)
            else
                destroyMobileButton("Horses")
            end
        end
    })

    -- No Fall Damage Keybind
    KeybindsSection:Keybind({
        Title = "No Fall Damage",
        Flag = "No_Fall_Damage_1",
        Desc = "Toggle No Fall Damage.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.NoFallDamage
                if toggle then
                    toggle:Set(not noFallDamageEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "No Fall Damage Button UI",
        Flag = "No_Fall_Damage_Button_UI",
        Desc = "Mobile button for No Fall Damage.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("NoFall", "NoFallDamage", function() return noFallDamageEnabled end)
            else
                destroyMobileButton("NoFall")
            end
        end
    })

    -- Fly Keybind
    KeybindsSection:Keybind({
        Title = "Fly",
        Flag = "Fly_1",
        Desc = "Toggle Fly.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.Fly
                if toggle then
                    toggle:Set(not FlyEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Fly Button UI",
        Flag = "Fly_Button_UI",
        Desc = "Mobile button for Fly.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Fly", "Fly", function() return FlyEnabled end)
            else
                destroyMobileButton("Fly")
            end
        end
    })
    
    -- Noclip Keybind
    KeybindsSection:Keybind({
        Title = "Noclip",
        Flag = "Noclip",
        Desc = "Toggle Noclip (requires Fly enabled).",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.NoclipBypass
                if toggle then
                    local currentState = _G.LanderNoclipEnabled or false
                    toggle:Set(not currentState)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Noclip Button UI",
        Flag = "Noclip_Button_UI",
        Desc = "Mobile button for Noclip.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Noclip", "NoclipBypass", function() return _G.LanderNoclipEnabled or false end)
            else
                destroyMobileButton("Noclip")
            end
        end
    })

    -- Invisible Keybind
    KeybindsSection:Keybind({
        Title = "Invisible",
        Flag = "Invisible_1",
        Desc = "Toggle Invisible.",
        Value = "",
        Callback = function()
            pcall(function()
                local toggle = _G.LanderToggleElements and _G.LanderToggleElements.Invisible
                if toggle then
                    toggle:Set(not invisibleEnabled)
                end
            end)
        end
    })
    KeybindsSection:Toggle({
        Title = "Invisible Button UI",
        Flag = "Invisible_Button_UI",
        Desc = "Mobile button for Invisible.",
        Default = false,
        Callback = function(v)
            if v then
                createMobileButton("Invisible", "Invisible", function() return invisibleEnabled or false end)
            else
                destroyMobileButton("Invisible")
            end
        end
    })

end -- end of Keybinds Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Feedback Tab
    local FeedbackTab = MiscTab -- Feedback goes inside MiscTab

    local FeedbackSection = FeedbackTab:Section({ Title = "Send Your Feedback", Icon = "send", Opened = false })

    FeedbackSection:Paragraph({
        Title = "Why Feedback Matters",
        Desc = "Submit feedback, bugs or suggestions.",
    })
    
    local webhookUrl = "https://discord.com/api/webhooks/1480054305263456367/ZwGNtD5KFnLh6xYeIf6H3FD1NKgrLQzxGoLzlsX9qxCCgfM5ZisnE7OZMu9UAXQU0aIe"
    local feedbackText = ""

    FeedbackSection:Input({
        Title = "Feedback Message",
        Desc = "Type your message here.",
        Value = "",
        Type = "Textarea",
        Placeholder = "Write your feedback...",
        Callback = function(value)
            feedbackText = value
        end
    })

    FeedbackSection:Button({
        Title = "Submit Feedback",
        Desc = "Send directly to the developer.",
        Callback = function()
            if feedbackText == "" then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Feedback cannot be empty.",
                    Duration = 2,
                    Icon = "alert-triangle",
                })
                return
            end

            local success, gameInfo = pcall(function()
                return MarketplaceService:GetProductInfo(game.PlaceId)
            end)

            if not success then
                gameInfo = {Name = "Unknown Game"}
            end

            local data = {
                ["username"] = "Guts & Blackpowder | Better🔥 Feedback",
                ["embeds"] = {{
                    ["title"] = "New Feedback Received",
                    ["description"] = string.format("**Feedback Message:**\n```\n%s\n```", feedbackText:sub(1, 2000)),
                    ["color"] = 0xFF3030,
                    ["fields"] = {
                        {["name"] = "User Info", ["value"] = string.format("**Display Name:** %s\n**Username:** %s", LocalPlayer.DisplayName, LocalPlayer.Name), ["inline"] = true},
                        {["name"] = "Technical", ["value"] = string.format("**Executor:** %s\n**Region:** %s", (identifyexecutor and identifyexecutor() or "Unknown"), LocalPlayer.LocaleId), ["inline"] = true},
                        {["name"] = "Game Info", ["value"] = string.format("**Game:** %s\n**Place ID:** %d\n**Server ID:** %s", gameInfo.Name, game.PlaceId, game.JobId), ["inline"] = false},
                    },
                    ["footer"] = {
                        ["text"] = "Guts & Blackpowder | Better🔥 Feedback System â€¢ "..os.date("%Y-%m-%d %H:%M:%S UTC")
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
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
                    WindUI:Notify({
                        Title = "Success",
                        Content = "Your feedback has been submitted successfully!",
                        Duration = 3,
                        Icon = "check",
                    })
                    feedbackText = ""
                else
                    WindUI:Notify({
                        Title = "Error",
                        Content = "Failed to send feedback: "..tostring(err),
                        Duration = 5,
                        Icon = "alert-triangle",
                    })
                end
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Your exploit does not support HTTP requests.",
                    Duration = 3,
                    Icon = "wifi-off",
                })
            end
        end
    })
end -- end of Feedback Tab

task.wait(0.1) -- Delay to prevent lag
do -- // Final task.spawn and connects
    print("Guts & Blackpowder | Better🔥 v1.0 successfully loaded!")
    print("Made by Home Lander")
end -- end of Final block
end
