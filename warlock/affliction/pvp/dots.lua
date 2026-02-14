local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - DoT Management & Snapshot System
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- Dark Soul: Misery (Burst Cooldown)
-- ============================================================

spells.DarkSoulMisery:Callback("with_procs", function(spell)
    if not util.should() then return end
    if settings.warlock_dark_soul_mode == "manual" then return end

    -- "with_procs" mode: only use when a proc is active
    if settings.warlock_dark_soul_mode == "with_procs" then
        if not util.hasProc() then return end
    end

    return spell:Cast() and lunar.alert("Dark Soul!", spell.id)
end)

-- ============================================================
-- Soulburn + Soul Swap: Instant DoT Application & Snapshot
-- ============================================================

--- Soulburn activation (prepares for Soul Swap)
spells.Soulburn:Callback("snapshot", function(spell)
    if not util.should() then return end
    if not settings.warlock_auto_snapshot then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end

    -- Only Soulburn for snapshot when we have strong buffs
    if not util.hasSnapshotWindow() then return end

    return spell:Cast()
end)

spells.Soulburn:Callback("initial", function(spell)
    if not util.should() then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end
    if not target.enemy then return end

    -- Initial DoT application: no DoTs on target yet
    if util.hasAllDots(target) then return end

    return spell:Cast()
end)

--- Soul Swap: Apply DoTs instantly (when Soulburn is active)
spells.SoulSwap:Callback("soulburn_apply", function(spell)
    if not util.should() then return end
    if not util.hasSoulburn() then return end
    if not target.enemy then return end

    return spell:Cast(target, { debug = "SB+SS Apply" })
        and lunar.alert("SB+SS!", spell.id)
end)

--- Soul Swap Inhale: Copy DoTs from current target
spells.SoulSwap:Callback("inhale", function(spell)
    if not util.should() then return end
    if util.hasSoulburn() then return end
    if util.hasSoulSwapExhale() then return end
    if not target.enemy then return end

    -- Only inhale if target has strong snapshotted DoTs
    if not util.hasAllDots(target) then return end
    if not util.hasSnapshotWindow() then return end

    return spell:Cast(target, { debug = "Inhale" })
end)

--- Soul Swap Exhale: Spread snapshotted DoTs to other targets
spells.SoulSwap:Callback("exhale", function(spell)
    if not util.should() then return end
    if not util.hasSoulSwapExhale() then return end
    if not settings.warlock_multi_dot then return end

    local maxTargets = settings.warlock_max_dot_targets or 3
    if util.dotTargetCount() >= maxTargets then return end

    -- Find an enemy without our DoTs
    local spreadTarget = lunar.enemies.find(function(enemy)
        if enemy.cc or enemy.bcc then return end
        if enemy.isUnit(target) then return end
        if util.hasAllDots(enemy) then return end
        return spell:Castable(enemy)
    end)

    if not spreadTarget then return end

    return spell:Cast(spreadTarget, { debug = "Exhale -> " .. spreadTarget.name })
        and lunar.alert("Spread " .. spreadTarget.name .. "!", spell.id)
end)

-- ============================================================
-- Soulburn + Soul Swap: Refresh snapshot before Dark Soul expires
-- ============================================================

spells.Soulburn:Callback("refresh_snapshot", function(spell)
    if not util.should() then return end
    if not settings.warlock_auto_snapshot then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end
    if not target.enemy then return end

    -- Refresh when Dark Soul is about to expire (last 3 seconds)
    local dsRemains = player.buffRemains(auras.DARK_SOUL_MISERY)
    if dsRemains <= 0 or dsRemains > 3 then return end

    -- Only if target already has DoTs (we're refreshing, not applying)
    if not util.hasAllDots(target) then return end

    return spell:Cast() and lunar.debug.offensive("Refresh snapshot (DS expiring)")
end)

-- ============================================================
-- Individual DoT Maintenance (manual fallback)
-- ============================================================

--- Agony - Highest priority, must never fall off
spells.Agony:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end

    local remains = target.debuffRemains(auras.AGONY, player)
    -- Pandemic: refresh when < 30% of duration remaining (~7.2s for 24s Agony)
    if remains > 5.4 then return end

    return spell:Cast(target)
end)

--- Corruption - Must maintain for Soul Shard generation
spells.Corruption:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end

    local remains = target.debuffRemains(auras.CORRUPTION, player)
    if remains > 4.2 then return end

    return spell:Cast(target)
end)

--- Unstable Affliction - Core damage + dispel protection
spells.UnstableAffliction:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end

    local remains = target.debuffRemains(auras.UNSTABLE_AFFLICTION, player)
    if remains > 4.2 then return end

    return spell:Cast(target)
end)

-- ============================================================
-- Multi-DoT Spread (manual, without Soul Swap)
-- ============================================================

spells.Agony:Callback("spread", function(spell)
    if not util.should() then return end
    if not settings.warlock_multi_dot then return end

    local maxTargets = settings.warlock_max_dot_targets or 3
    if util.dotTargetCount() >= maxTargets then return end

    local enemy = lunar.enemies.find(function(e)
        if e.cc or e.bcc then return end
        if e.isUnit(target) then return end
        if e.debuff(auras.AGONY, player) then return end
        return spell:Castable(e)
    end)

    if not enemy then return end
    return spell:Cast(enemy)
end)

spells.Corruption:Callback("spread", function(spell)
    if not util.should() then return end
    if not settings.warlock_multi_dot then return end

    local maxTargets = settings.warlock_max_dot_targets or 3
    if util.dotTargetCount() >= maxTargets then return end

    local enemy = lunar.enemies.find(function(e)
        if e.cc or e.bcc then return end
        if e.isUnit(target) then return end
        if e.debuff(auras.CORRUPTION, player) then return end
        return spell:Castable(e)
    end)

    if not enemy then return end
    return spell:Cast(enemy)
end)

spells.UnstableAffliction:Callback("spread", function(spell)
    if not util.should() then return end
    if not settings.warlock_multi_dot then return end

    local maxTargets = settings.warlock_max_dot_targets or 3
    if util.dotTargetCount() >= maxTargets then return end

    local enemy = lunar.enemies.find(function(e)
        if e.cc or e.bcc then return end
        if e.isUnit(target) then return end
        if e.debuff(auras.UNSTABLE_AFFLICTION, player) then return end
        return spell:Castable(e)
    end)

    if not enemy then return end
    return spell:Cast(enemy)
end)

-- ============================================================
-- Curse of the Elements
-- ============================================================

spells.CurseOfTheElements:Callback("maintain", function(spell)
    if not util.should() then return end
    if not settings.warlock_curse_of_elements then return end
    if not target.enemy then return end

    if target.debuff(auras.CURSE_OF_ELEMENTS) then return end

    return spell:Cast(target)
end)

spells.CurseOfTheElements:Callback("spread", function(spell)
    if not util.should() then return end
    if not settings.warlock_curse_of_elements then return end

    local enemy = lunar.enemies.find(function(e)
        if e.isUnit(target) then return end
        if e.debuff(auras.CURSE_OF_ELEMENTS) then return end
        return spell:Castable(e)
    end)

    if not enemy then return end
    return spell:Cast(enemy)
end)

-- ============================================================
-- Haunt
-- ============================================================

spells.Haunt:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if player.soulShards < 1 then return end

    -- Keep Haunt up for +35% damage
    local remains = target.debuffRemains(auras.HAUNT, player)
    if remains > 1 then return end

    return spell:Cast(target)
end)

spells.Haunt:Callback("snapshot", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if player.soulShards < 2 then return end -- Keep 1 shard reserve

    -- Use Haunt during snapshot windows for maximum value
    if not util.hasSnapshotWindow() then return end

    return spell:Cast(target, { debug = "Snapshot Haunt" })
end)

-- ============================================================
-- Filler: Malefic Grasp / Drain Soul
-- ============================================================

--- Drain Soul (execute filler < 20% HP)
spells.DrainSoul:Callback("execute", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if target.hpliteral >= 20 then return end

    return spell:Cast(target)
end)

--- Malefic Grasp (standard filler)
spells.MaleficGrasp:Callback("filler", function(spell)
    if not util.should() then return end
    if not target.enemy then return end

    return spell:Cast(target)
end)

--- Fel Flame (instant, while moving)
spells.FelFlame:Callback("moving", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if not player.moving then return end

    return spell:Cast(target)
end)
