local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Utility Functions
-- Revised per PvP Guide: "Time Debt Designer" philosophy
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local player = lunar.player

project.warlock.util = {}
local util = project.warlock.util

-- ============================================================
-- General Checks
-- ============================================================

function util.should()
    if player.dead then return end
    if player.ghost then return end
    if player.mounted then return end
    -- Allow actions in combat OR when targeting an enemy (for pulling dummies/opening)
    if not player.combat and not lunar.target.enemy then return end
    return true
end

function util.shouldStopCasting()
    if player.channeling then
        local channelID = player.channelID
        if channelID == 1120 then return false end -- Drain Soul
        if channelID == 689 and player.hp < 30 then return false end -- Drain Life emergency
    end
    return true
end

-- ============================================================
-- Snapshot Detection
-- ============================================================

function util.hasSnapshotWindow()
    return player.buff(auras.DARK_SOUL_MISERY) ~= false
end

function util.hasProc()
    if player.buff(auras.LIGHTWEAVE) then return true end
    if player.buff(auras.TRINKET_PROC) then return true end
    if player.buff(auras.LIFEBLOOD) then return true end
    if player.buff(auras.TRINKET_138963) then return true end
    if player.buff(auras.TRINKET_138786) then return true end
    if player.buff(auras.TRINKET_138898) then return true end
    if player.buff(auras.TRINKET_139133) then return true end
    if player.buff(auras.TRINKET_137590) then return true end
    return false
end

function util.hasIdealSnapshot()
    return util.hasSnapshotWindow() and util.hasProc()
end

-- ============================================================
-- Soulburn + Soul Swap Helpers
-- ============================================================

function util.hasSoulburn()
    return player.buff(auras.SOULBURN) ~= false
end

function util.canSoulburnSwap()
    return player.soulShards >= 1 and spells.Soulburn.cd == 0 and spells.SoulSwap.cd == 0
end

function util.hasSoulSwapInhale()
    return player.buff(auras.SOUL_SWAP_INHALE) ~= false
end

-- ============================================================
-- DoT Tracking
-- ============================================================

function util.hasAllDots(unit)
    if not unit.debuff(auras.AGONY, player) then return false end
    if not unit.debuff(auras.CORRUPTION, player) then return false end
    if not unit.debuff(auras.UNSTABLE_AFFLICTION, player) then return false end
    return true
end

function util.lowestDotRemains(unit)
    local agony = unit.debuffRemains(auras.AGONY, player)
    local corr = unit.debuffRemains(auras.CORRUPTION, player)
    local ua = unit.debuffRemains(auras.UNSTABLE_AFFLICTION, player)
    return math.min(agony, corr, ua)
end

function util.dotTargetCount()
    local count = 0
    lunar.enemies.loop(function(enemy)
        if enemy.debuff(auras.AGONY, player) or enemy.debuff(auras.CORRUPTION, player) then
            count = count + 1
        end
    end)
    return count
end

--- Check if target has UA (dispel protection for Fear)
function util.hasUAProtection(unit)
    return unit.debuff(auras.UNSTABLE_AFFLICTION, player) ~= false
end

-- ============================================================
-- Healer Dispel Tracking (Fear Epoch Detection)
-- Guide: "When healer dispels UA → 8s dispel CD → Fear Epoch begins"
-- ============================================================

local lastHealerDispelTime = 0
local DISPEL_CD = 8  -- MoP healer dispel CD is 8 seconds

--- Call this when healer dispels (detected via combat log or aura removal)
function util.onHealerDispel()
    lastHealerDispelTime = lunar.time
end

--- Is the healer's dispel on cooldown? (Fear Epoch active)
function util.isHealerDispelOnCD()
    return (lunar.time - lastHealerDispelTime) < DISPEL_CD
end

--- Time remaining on healer dispel CD
function util.healerDispelCDRemains()
    local remains = DISPEL_CD - (lunar.time - lastHealerDispelTime)
    if remains < 0 then return 0 end
    return remains
end

--- Is it Fear Epoch? (healer dispel on CD = safe to spam fear on DPS)
function util.isFearEpoch()
    return util.isHealerDispelOnCD()
end

-- Track dispels via combat log
lunar.onEvent(function(info, event, source, dest)
    if event == "SPELL_DISPEL" then
        local spellID = select(15, unpack(info))
        -- If our UA was dispelled, healer just used their 8s CD
        if spellID == auras.UNSTABLE_AFFLICTION then
            if source and source.enemy and source.healer then
                util.onHealerDispel()
            end
        end
    end
end)

-- ============================================================
-- Fear Chain Tracking
-- Guide: "3 consecutive fears = 12+ seconds of group suppression"
-- ============================================================

--- Count enemies currently feared by us
function util.fearedEnemyCount()
    local count = 0
    lunar.enemies.loop(function(enemy)
        if enemy.feared then
            count = count + 1
        end
    end)
    return count
end

--- Find best DPS target to fear (prefers targets with our DOTs ticking)
function util.findBestFearDPS(spell)
    return lunar.enemies.score(function(enemy)
        if not enemy.player then return -1 end
        if enemy.cc then return -1 end
        if enemy.healer then return -1 end  -- Healer handled separately
        if not enemy.ccable({ dr = "FEAR", effect = "magic" }) then return -1 end
        if not spell:Castable(enemy) then return -1 end

        local score = 0

        -- Strongly prefer targets with our DoTs (DOT damage during fear = max value)
        if enemy.debuff(auras.AGONY, player) then score = score + 40 end
        if enemy.debuff(auras.CORRUPTION, player) then score = score + 30 end
        if enemy.debuff(auras.UNSTABLE_AFFLICTION, player) then score = score + 30 end

        -- Prefer targets in Fear Epoch (healer can't save them)
        if util.isFearEpoch() then score = score + 50 end

        -- Prefer targets already taking damage (lower HP)
        score = score + (100 - enemy.hp) * 0.3

        -- Prefer targets with UA protection (dispel = silence)
        if util.hasUAProtection(enemy) then score = score + 20 end

        return score
    end)
end

-- ============================================================
-- Target Selection
-- ============================================================

function util.findDotTarget(spell)
    return lunar.enemies.find(function(enemy)
        if enemy.cc then return end
        if enemy.bcc then return end
        if not spell:Castable(enemy) then return end
        if not enemy.debuff(auras.AGONY, player) then return true end
        if not enemy.debuff(auras.CORRUPTION, player) then return true end
        if not enemy.debuff(auras.UNSTABLE_AFFLICTION, player) then return true end
        return false
    end)
end

--- Find enemy pets to DoT (Water Elemental, Ghoul, Hunter pets)
--- Guide: "Applying DOTs to enemy key pets is a hidden win condition"
function util.findEnemyPetToDot()
    return lunar.enemyPets.find(function(pet)
        if pet.dead then return end
        if pet.hp < 10 then return end  -- About to die anyway
        if pet.debuff(auras.CORRUPTION, player) then return end  -- Already dotted
        if pet.distance > 40 then return end
        return true
    end)
end

-- ============================================================
-- Burst Mode System
-- Guide: "Timing > Frequency — the perfect burst destroys;
-- a wasted burst gives opponents 2 minutes of confidence"
-- ============================================================
-- Burst mode triggers the full damage sequence:
--   1. Dark Soul: Misery (immediate)
--   2. Soulburn + Soul Swap snapshot
--   3. Summon Doomguard
--   4. Aggressive Haunt stacking
--   5. Auto-expires when Dark Soul fades (~20s)
-- ============================================================

local burstActive = false
local burstStartTime = 0
local BURST_WINDOW = 22  -- Dark Soul duration (20s) + buffer

--- Toggle burst mode on/off (for keybind/command)
function util.toggleBurst()
    if burstActive then
        burstActive = false
        lunar.alert("Burst OFF")
    else
        burstActive = true
        burstStartTime = lunar.time
        lunar.alert("BURST ON!", auras.DARK_SOUL_MISERY)
    end
end

--- Activate burst mode programmatically (for auto-detection)
function util.activateBurst()
    if burstActive then return end
    burstActive = true
    burstStartTime = lunar.time
    lunar.alert("AUTO BURST!", auras.DARK_SOUL_MISERY)
end

--- Deactivate burst mode
function util.deactivateBurst()
    if not burstActive then return end
    burstActive = false
end

--- Is burst mode currently active?
function util.isBurstMode()
    if not burstActive then return false end
    -- Auto-expire after burst window
    if (lunar.time - burstStartTime) > BURST_WINDOW then
        burstActive = false
        return false
    end
    return true
end

--- Remaining time in burst mode
function util.burstRemains()
    if not burstActive then return 0 end
    local remains = BURST_WINDOW - (lunar.time - burstStartTime)
    if remains < 0 then return 0 end
    return remains
end

--- Should we auto-trigger burst? (intelligent detection)
--- Returns true when conditions are ideal for maximum damage
function util.shouldAutoBurst()
    if burstActive then return false end  -- Already bursting
    if spells.DarkSoulMisery.cd > 0 then return false end  -- Dark Soul on CD

    local t = lunar.target
    if not t.enemy then return false end

    -- Must have DOTs up for burst to multiply existing damage
    if not util.hasAllDots(t) then return false end

    -- Trigger conditions (any one is enough to burst):

    -- 1. Proc is active → Dark Soul + proc = maximum snapshot
    if util.hasProc() then return true end

    -- 2. Target low HP → finish with burst
    if t.hp < 35 then return true end

    -- 3. Fear Epoch → healer can't dispel, maximum pressure window
    if util.isFearEpoch() then return true end

    return false
end

-- Register burst toggle command (/affliction burst)
if project.cmd then
    project.cmd:New(function(msg)
        if msg == "burst" then
            util.toggleBurst()
            return true
        end
    end)
end

-- ============================================================
-- Melee Pressure Detection
-- ============================================================

--- Count melee attackers on player
function util.meleeAttackerCount()
    local count = 0
    lunar.enemies.loop(function(enemy)
        if enemy.meleeRange and enemy.player then
            count = count + 1
        end
    end)
    return count
end

--- Are we under melee pressure?
function util.underMeleePressure()
    return util.meleeAttackerCount() >= 1
end
