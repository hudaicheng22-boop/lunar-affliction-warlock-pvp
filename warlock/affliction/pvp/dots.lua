local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock - Sim-style PvE Rotation (from scratch)
-- Spell IDs confirmed from sim-config.json
-- ============================================================
--   980  = Agony
--   172  = Corruption
--   30108 = Unstable Affliction
--   48181 = Haunt
--   103103 = Malefic Grasp
--   1120  = Drain Soul
--   1490  = Curse of the Elements
--   77799 = Fel Flame
--   1454  = Life Tap
-- ============================================================

local spells = project.warlock.spells
local player = lunar.player
local target = lunar.target

-- ============================================================
-- Unstable Affliction: refresh at <= 3s or apply if missing
-- ============================================================
spells.UnstableAffliction:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    local remains = target.debuffRemains(30108, player)
    if remains > 3 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Agony: refresh at <= 2s or apply if missing
-- (sim uses GCD threshold ~1.5s, we use 2s for safety)
-- ============================================================
spells.Agony:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    local remains = target.debuffRemains(980, player)
    if remains > 2 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Corruption: refresh at <= 3s or apply if missing
-- ============================================================
spells.Corruption:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    local remains = target.debuffRemains(172, player)
    if remains > 3 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Curse of the Elements: apply once if not present
-- ============================================================
spells.CurseOfTheElements:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.debuff(1490) then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Haunt: maintain debuff (requires 1 soul shard)
-- Uses (player.soulShards or 0) for nil safety
-- ============================================================
spells.Haunt:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if (player.soulShards or 0) < 1 then return end
    local remains = target.debuffRemains(48181, player)
    if remains > 1 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Drain Soul: execute phase (target < 20% HP)
-- Replaces Malefic Grasp as filler in execute
-- ============================================================
spells.DrainSoul:Callback("execute", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.hp >= 20 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Malefic Grasp: single-target filler channel
-- stupidChannel = true allows dots to interrupt when needed
-- ============================================================
spells.MaleficGrasp:Callback("filler", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Fel Flame: instant cast while moving
-- ============================================================
spells.FelFlame:Callback("moving", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if not player.moving then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Life Tap: mana management (sim: use at <= 15% mana)
-- ============================================================
spells.LifeTap:Callback("mana", function(spell)
    if player.dead or player.mounted then return end
    if player.manaPct > 15 then return end
    if player.hp < 40 then return end
    return spell:Cast()
end)
