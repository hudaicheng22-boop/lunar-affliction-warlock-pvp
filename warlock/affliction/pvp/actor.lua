local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Actor (Main Priority System)
-- ============================================================
-- PvP Guide Philosophy:
--   "The Affliction Warlock is a Time Debt Designer.
--    Every mechanic forces opponents to bear excess decision
--    costs in limited time. Healers must weigh 8s dispel CD;
--    DPS must abandon output during Fear; melee must burn gap
--    closers to cross portals. This systematic time squeeze
--    causes enemy coordination to decay invisibly — control
--    chains break, healing overflows, focus fire fails."
--
-- Core Targets:
--   1. Multi-target DOT pressure (ideal: 3 targets)
--   2. Dispel counterplay → Fear Epoch on DPS
--   3. Control chain → kill window creation
--   4. Space management → survival = sustained pressure
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target
local items = project.warlock.items

local actor = lunar.Actor:New({
    spec = 1,           -- Affliction
    class = "warlock"
})

actor:Init(function()

    -- Stable Sim mode:
    -- Focus on dummy throughput first (single-target priority).
    -- PvP control chain is intentionally disabled for stability.

    -- Pet auto-summon (requested feature)
    spells.Soulburn("summon_pet")
    spells.SummonFelhunter("auto_summon")

    -- Essential survivability only
    spells.UnendingResolve("damage_reduction")
    spells.DarkRegeneration("emergency")
    spells.SacrificialPact("emergency")
    items.Healthstone("emergency")

    -- Sim cooldown windows
    spells.DarkSoulMisery("burst")
    spells.SummonDoomguard("burst")

    -- Soulburn + Soul Swap snapshot/refresh
    spells.Soulburn("refresh_snapshot")
    spells.SoulSwap("soulburn_apply")
    spells.Soulburn("snapshot")
    spells.SoulSwap("soulburn_apply")
    spells.Soulburn("initial")
    spells.SoulSwap("soulburn_apply")
    spells.SoulSwap("inhale")
    spells.SoulSwap("exhale")

    -- Core damage engine (sim-like ST order)
    spells.UnstableAffliction("maintain")
    spells.Agony("maintain")
    spells.Corruption("maintain")
    spells.CurseOfTheElements("maintain")
    spells.Haunt("snapshot")
    spells.Haunt("maintain")
    spells.DrainSoul("shard_gen")
    spells.DrainSoul("execute")
    spells.MaleficGrasp("filler")
    spells.FelFlame("moving")

    -- Mana
    spells.LifeTap("mana")
end)
