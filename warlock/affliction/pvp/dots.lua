local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - DoT Management & Snapshot System
-- Revised per PvP Guide: "Timing > Frequency" philosophy
-- ============================================================
-- DOT Priority (PvP):
--   1. UA (highest - dispel protection, must be seamless)
--   2. Agony (anti-dispel core, stacking damage)
--   3. Corruption (shard generation, must maintain)
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
-- Modes:
--   "auto_burst" : Intelligent auto-detection + manual toggle
--   "with_procs" : Only when trinket/tailoring procs are active
--   "on_cd"      : Use on cooldown
--   "manual"     : Never auto-use
-- ============================================================

spells.DarkSoulMisery:Callback("burst", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    -- Sim-like usage for stable dummy output:
    -- use with procs/all dots, or on execute/end-of-fight windows.
    if not util.hasProc() and not util.hasAllDots(target) and target.hp > 20 then
        return
    end
    return spell:Cast() and lunar.alert("Dark Soul!", spell.id)
end)

-- ============================================================
-- Doomguard (DPS Cooldown)
-- ============================================================

spells.SummonDoomguard:Callback("burst", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    -- Sim-like windows:
    -- 1) Dark Soul active
    -- 2) Execute phase
    -- 3) Proc window
    if not util.hasSnapshotWindow() and target.hp > 25 and not util.hasProc() then return end
    return spell:Cast() and lunar.alert("Doomguard!", spell.id)
end)

-- ============================================================
-- Soulburn + Soul Swap System
-- Guide: "Soul Swap is a time anchor, not a copy tool"
-- ============================================================

--- Soulburn for instant pet re-summon in combat
spells.Soulburn:Callback("summon_pet", function(spell)
    if player.dead or player.ghost or player.mounted then return end
    if not player.combat then return end  -- Don't waste soulburn out of combat
    if not settings.warlock_auto_summon_pet then return end
    if util.hasSoulburn() then return end  -- Already have soulburn buff
    if player.soulShards < 1 then return end

    local pet = lunar.pet
    if pet.exists and not pet.dead then return end  -- Pet is alive

    return spell:Cast()
end)

--- Soulburn for initial DOT application (no DOTs on target)
spells.Soulburn:Callback("initial", function(spell)
    if not util.should() then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end
    if not target.enemy then return end

    if util.hasAllDots(target) then return end

    return spell:Cast()
end)

--- Soulburn for snapshot (Dark Soul + procs active)
spells.Soulburn:Callback("snapshot", function(spell)
    if not util.should() then return end
    if not settings.warlock_auto_snapshot then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end

    if not util.hasSnapshotWindow() then return end

    return spell:Cast()
end)

--- Soulburn to refresh before Dark Soul expires
spells.Soulburn:Callback("refresh_snapshot", function(spell)
    if not util.should() then return end
    if not settings.warlock_auto_snapshot then return end
    if util.hasSoulburn() then return end
    if not util.canSoulburnSwap() then return end
    if not target.enemy then return end

    local dsRemains = player.buffRemains(auras.DARK_SOUL_MISERY)
    if dsRemains <= 0 or dsRemains > 3 then return end
    if not util.hasAllDots(target) then return end

    return spell:Cast()
end)

--- Soul Swap: Apply DOTs instantly (Soulburn active)
spells.SoulSwap:Callback("soulburn_apply", function(spell)
    if not util.should() then return end
    if not util.hasSoulburn() then return end
    if not target.enemy then return end

    return spell:Cast(target, { debug = "SB+SS Apply" })
        and lunar.alert("SB+SS!", spell.id)
end)

--- Soul Swap Inhale: Copy snapshotted DOTs
spells.SoulSwap:Callback("inhale", function(spell)
    if not util.should() then return end
    if util.hasSoulburn() then return end
    if util.hasSoulSwapInhale() then return end
    if not target.enemy then return end

    if not util.hasAllDots(target) then return end
    if not util.hasSnapshotWindow() then return end

    return spell:Cast(target, { debug = "Inhale" })
end)

--- Soul Swap Exhale: Spread to other targets
spells.SoulSwap:Callback("exhale", function(spell)
    if not util.should() then return end
    if not util.hasSoulSwapInhale() then return end
    if not settings.warlock_multi_dot then return end

    local maxTargets = settings.warlock_max_dot_targets or 3
    if util.dotTargetCount() >= maxTargets then return end

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
-- Individual DOT Maintenance
-- Guide Priority: UA (highest) > Agony > Corruption
-- ============================================================

--- Unstable Affliction - HIGHEST PRIORITY
--- Guide: "Must be maintained seamlessly; dispel = 4s silence"
--- This is the core of dispel protection for Fear chains
spells.UnstableAffliction:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if util.hasSoulSwapInhale() then return end

    local remains = target.debuffRemains(auras.UNSTABLE_AFFLICTION, player)
    local threshold = 3
    -- Snapshot: refresh earlier when Dark Soul + Lightweave active
    if util.hasSnapshotWindow() and player.buff(auras.LIGHTWEAVE) then
        if player.buffRemains(auras.LIGHTWEAVE) < 3 then
            threshold = 11
        end
    end
    if remains > threshold then return end

    return spell:Cast(target)
end)

--- Agony - Anti-dispel core, stacking damage
--- Sim logic: refresh at <= GCD remaining
spells.Agony:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if util.hasSoulSwapInhale() then return end

    local remains = target.debuffRemains(auras.AGONY, player)
    if remains > lunar.gcd then return end

    return spell:Cast(target)
end)

--- Corruption - Shard generation, must maintain
--- Sim logic: refresh < 3s, or < 6s during Dark Soul
spells.Corruption:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if util.hasSoulSwapInhale() then return end

    local remains = target.debuffRemains(auras.CORRUPTION, player)
    local threshold = 3
    if util.hasSnapshotWindow() then threshold = 6 end
    if remains > threshold then return end

    return spell:Cast(target)
end)

-- ============================================================
-- Multi-DoT Spread (Manual)
-- Guide: "Ideal 3 targets with stacked DOTs"
-- ============================================================

--- UA spread - ensures dispel protection on multiple targets
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

-- ============================================================
-- DOT Enemy Pets
-- Guide: "Applying DOTs to enemy key pets (Water Elemental, 
-- Ghoul, Hunter pets) weakens enemy overall combat effectiveness"
-- ============================================================

spells.Corruption:Callback("pet_dot", function(spell)
    if not util.should() then return end
    if not settings.warlock_multi_dot then return end

    local pet = util.findEnemyPetToDot()
    if not pet then return end
    if not spell:Castable(pet) then return end

    return spell:Cast(pet, { debug = "Pet DoT: " .. pet.name })
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
-- Haunt (+35% damage amplifier)
-- ============================================================

spells.Haunt:Callback("maintain", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if player.soulShards < 1 then return end

    local remains = target.debuffRemains(auras.HAUNT, player)
    if remains > 1 then return end

    return spell:Cast(target)
end)

spells.Haunt:Callback("snapshot", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if player.soulShards < 2 then return end

    if not util.hasSnapshotWindow() then return end

    return spell:Cast(target, { debug = "Snapshot Haunt" })
end)

-- ============================================================
-- Drain Soul: Shard Generation & Execute
-- ============================================================

spells.DrainSoul:Callback("shard_gen", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if player.soulShards >= 3 then return end

    if not util.hasSnapshotWindow() then return end
    if util.canSoulburnSwap() then return end -- Already have shards
    if not util.hasAllDots(target) then return end

    return spell:Cast(target, { debug = "Shard gen for SBSS" })
end)

spells.DrainSoul:Callback("execute", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if target.hp >= 20 then return end

    return spell:Cast(target)
end)

-- ============================================================
-- Filler: Malefic Grasp / Fel Flame
-- ============================================================

spells.MaleficGrasp:Callback("filler", function(spell)
    if not util.should() then return end
    if not target.enemy then return end

    return spell:Cast(target)
end)

spells.FelFlame:Callback("moving", function(spell)
    if not util.should() then return end
    if not target.enemy then return end
    if not player.moving then return end

    return spell:Cast(target)
end)
