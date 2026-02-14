local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Utility Functions
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local player = lunar.player

-- Shared utility namespace
project.warlock.util = {}
local util = project.warlock.util

-- ============================================================
-- General Checks
-- ============================================================

--- Should the rotation be active
function util.should()
    if not player.combat then return end
    if player.dead then return end
    if player.ghost then return end
    if player.mounted then return end
    return true
end

--- Should we stop current cast to do something else
function util.shouldStopCasting()
    -- Don't interrupt important channels
    if player.channeling then
        local channelID = player.channelID
        -- Don't stop Drain Soul (execute filler)
        if channelID == 1120 then return false end
        -- Don't stop Drain Life if we're low
        if channelID == 689 and player.hp < 30 then return false end
    end
    return true
end

-- ============================================================
-- Snapshot Detection
-- ============================================================

--- Check if we have a strong snapshot window active
--- (Dark Soul + any proc = ideal snapshot moment)
function util.hasSnapshotWindow()
    if player.buff(auras.DARK_SOUL_MISERY) then
        return true
    end
    return false
end

--- Check if any significant proc is active (trinket / tailoring / herbalism)
function util.hasProc()
    if player.buff(auras.LIGHTWEAVE) then return true end
    if player.buff(auras.TRINKET_PROC) then return true end
    if player.buff(auras.LIFEBLOOD) then return true end
    return false
end

--- Check if we're in the ideal snapshot window (Dark Soul + proc)
function util.hasIdealSnapshot()
    return util.hasSnapshotWindow() and util.hasProc()
end

-- ============================================================
-- Soulburn + Soul Swap Helpers
-- ============================================================

--- Check if Soulburn is currently active as a buff
function util.hasSoulburn()
    return player.buff(auras.SOULBURN) ~= false
end

--- Check if we have enough soul shards for Soulburn + Soul Swap
function util.canSoulburnSwap()
    return player.soulShards >= 1 and spells.Soulburn.cd == 0 and spells.SoulSwap.cd == 0
end

--- Check if Soul Swap Exhale is ready (DoTs have been inhaled)
function util.hasSoulSwapExhale()
    return player.buff(auras.SOUL_SWAP_EXHALE) ~= false
end

-- ============================================================
-- DoT Tracking Helpers
-- ============================================================

--- Check if a target has all 3 core DoTs from us
function util.hasAllDots(unit)
    if not unit.debuff(auras.AGONY, player) then return false end
    if not unit.debuff(auras.CORRUPTION, player) then return false end
    if not unit.debuff(auras.UNSTABLE_AFFLICTION, player) then return false end
    return true
end

--- Get the lowest DoT remaining time on a target
function util.lowestDotRemains(unit)
    local agony = unit.debuffRemains(auras.AGONY, player)
    local corr = unit.debuffRemains(auras.CORRUPTION, player)
    local ua = unit.debuffRemains(auras.UNSTABLE_AFFLICTION, player)
    return math.min(agony, corr, ua)
end

--- Count how many targets have our DoTs
function util.dotTargetCount()
    local count = 0
    lunar.enemies.loop(function(enemy)
        if enemy.debuff(auras.AGONY, player) or enemy.debuff(auras.CORRUPTION, player) then
            count = count + 1
        end
    end)
    return count
end

-- ============================================================
-- Target Selection
-- ============================================================

--- Find the best target that needs DoTs
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
