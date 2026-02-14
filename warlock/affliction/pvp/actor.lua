local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock - Sim-style PvE Actor (from scratch)
-- Minimum viable rotation for stable dummy output
-- ============================================================

local spells = project.warlock.spells

local actor = lunar.Actor:New({
    spec = 1,           -- Affliction
    class = "warlock"
})

actor:Init(function()
    -- Sim single-target priority:
    -- 1. Maintain DoTs (UA > Agony > Corruption)
    -- 2. Curse of the Elements
    -- 3. Haunt (if soul shards available)
    -- 4. Drain Soul (execute phase < 20%)
    -- 5. Malefic Grasp (filler channel)
    -- 6. Fel Flame (if moving)
    -- 7. Life Tap (if OOM)

    spells.UnstableAffliction("maintain")
    spells.Agony("maintain")
    spells.Corruption("maintain")
    spells.CurseOfTheElements("maintain")
    spells.Haunt("maintain")
    spells.DrainSoul("execute")
    spells.MaleficGrasp("filler")
    spells.FelFlame("moving")
    spells.LifeTap("mana")
end)
