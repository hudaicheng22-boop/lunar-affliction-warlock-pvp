local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock - Sim APL Actor (Faithful Translation)
-- Priority order matches sim-config.json priorityList exactly
-- ============================================================

local spells = project.warlock.spells

local actor = lunar.Actor:New({
    spec = 1,           -- Affliction
    class = "warlock"
})

actor:Init(function()
    -- Pre-sim: Pet auto-summon (necessary for gameplay)
    spells.Soulburn("summon_pet")
    spells.SummonFelhunter("auto_summon")

    -- Sim Priority 2: Dark Soul: Misery
    spells.DarkSoulMisery("burst")

    -- Sim Priority 3: Summon Doomguard
    spells.SummonDoomguard("burst")

    -- Sim Priority 7: Lifeblood (Herbalism)
    spells.Lifeblood("use")

    -- Sim Priority 9: SBSS (Soulburn + Soul Swap)
    spells.Soulburn("sbss")
    spells.SoulSwap("sbss_apply")

    -- Sim Priority 10-11: Drain Soul shard gen
    spells.DrainSoul("shard_gen")

    -- Sim Priority 12: Agony
    spells.Agony("maintain")

    -- Sim Priority 13: Corruption
    spells.Corruption("maintain")

    -- Sim Priority 14: Unstable Affliction
    spells.UnstableAffliction("maintain")

    -- Sim Priority 14b: UA multi-target
    spells.UnstableAffliction("multi")

    -- Sim Priority 16: Drain Soul for Haunt shards
    spells.DrainSoul("haunt_shards")

    -- Sim Priority 17: Haunt
    spells.Haunt("maintain")

    -- Sim Priority 19: Soul Swap Inhale
    spells.SoulSwap("inhale")

    -- Sim Priority 20: Soul Swap Exhale urgent
    spells.SoulSwapExhale("exhale_urgent")

    -- Sim Priority 21: Soul Swap Exhale spread
    spells.SoulSwapExhale("exhale_spread")

    -- Sim Priority 22: Life Tap (mana)
    spells.LifeTap("mana")

    -- Sim Priority 28: Drain Soul execute
    spells.DrainSoul("execute")

    -- Sim Priority 30: Malefic Grasp filler
    spells.MaleficGrasp("filler")

    -- Sim Priority 31: Life Tap absolute filler
    spells.LifeTap("filler")
end)
