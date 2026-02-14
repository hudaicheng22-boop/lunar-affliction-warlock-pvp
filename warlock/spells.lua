local unlocker, lunar, project = ...

-- Spell IDs from sim-config.json
-- 980 Agony, 172 Corruption, 30108 UA, 48181 Haunt
-- 1120 Drain Soul, 103103 Malefic Grasp, 1454 Life Tap
-- 86121 Soul Swap, 86213 Soul Swap Exhale, 74434 Soulburn
-- 113860 Dark Soul, 18540 Doomguard, 1490 Curse of Elements

local spells = project.warlock.spells

lunar.Populate({
    Agony = lunar.Spell(980, { damage = "magic", effect = "magic", category = "attack" }),
    Corruption = lunar.Spell(172, { damage = "magic", effect = "magic", category = "attack" }),
    UnstableAffliction = lunar.Spell(30108, { damage = "magic", effect = "magic", category = "attack" }),
    Haunt = lunar.Spell(48181, { damage = "magic", category = "attack" }),
    MaleficGrasp = lunar.Spell(103103, { damage = "magic", category = "attack", channel = true, stupidChannel = true }),
    DrainSoul = lunar.Spell(1120, { damage = "magic", category = "attack", channel = true, stupidChannel = true }),
    SoulSwap = lunar.Spell(86121, { effect = "magic", category = "attack" }),
    SoulSwapExhale = lunar.Spell(86213, { effect = "magic", category = "attack" }),
    Soulburn = lunar.Spell(74434, { beneficial = true, ignoreGCD = true, category = "offensive" }),
    DarkSoulMisery = lunar.Spell(113860, { beneficial = true, ignoreGCD = true, ignoreCasting = true, ignoreChanneling = true, category = "offensive" }),
    SummonDoomguard = lunar.Spell(18540, { beneficial = true, category = "offensive" }),
    CurseOfTheElements = lunar.Spell(1490, { effect = "magic", category = "attack" }),
    LifeTap = lunar.Spell(1454, { category = "default" }),
    SummonFelhunter = lunar.Spell(691, { beneficial = true, category = "summon" }),
    FelFlame = lunar.Spell(77799, { damage = "magic", ignoreMoving = true, category = "attack" }),
}, spells, getfenv(1))
