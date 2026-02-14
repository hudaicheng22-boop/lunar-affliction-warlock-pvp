local unlocker, lunar, project = ...

-- Sim priorityList order
local spells = project.warlock.spells

local actor = lunar.Actor:New({ spec = 1, class = "warlock" })

actor:Init(function()
    spells.Soulburn("summon_pet")
    spells.SummonFelhunter("auto_summon")
    spells.DarkSoulMisery("burst")
    spells.SummonDoomguard("burst")
    spells.Soulburn("sbss")
    spells.SoulSwap("sbss_apply")
    spells.DrainSoul("shard_gen")
    spells.Agony("maintain")
    spells.Corruption("maintain")
    spells.UnstableAffliction("maintain")
    spells.Haunt("maintain")
    spells.SoulSwap("inhale")
    spells.SoulSwapExhale("exhale")
    spells.LifeTap("mana")
    spells.DrainSoul("execute")
    spells.MaleficGrasp("filler")
    spells.LifeTap("filler")
end)
