local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock - Spell Definitions
-- ============================================================

local spells = project.warlock.spells

lunar.Populate({

    -- ========================================================
    -- Core DoTs
    -- ========================================================
    Agony = lunar.Spell(980, {
        damage = "magic",
        effect = "magic",
        category = "attack",
    }),

    Corruption = lunar.Spell(172, {
        damage = "magic",
        effect = "magic",
        category = "attack",
    }),

    UnstableAffliction = lunar.Spell(30108, {
        damage = "magic",
        effect = "magic",
        category = "attack",
    }),

    -- ========================================================
    -- Core Abilities
    -- ========================================================
    Haunt = lunar.Spell(48181, {
        damage = "magic",
        category = "attack",
    }),

    MaleficGrasp = lunar.Spell(103103, {
        damage = "magic",
        category = "attack",
    }),

    DrainSoul = lunar.Spell(1120, {
        damage = "magic",
        category = "attack",
        channel = true,
        stupidChannel = true,
    }),

    DrainLife = lunar.Spell(689, {
        damage = "magic",
        heal = true,
        channel = true,
        stupidChannel = true,
        category = "heal",
    }),

    FelFlame = lunar.Spell(77799, {
        damage = "magic",
        ignoreMoving = true,
        category = "attack",
    }),

    -- ========================================================
    -- Soul Swap System
    -- ========================================================
    SoulSwap = lunar.Spell(86121, {
        effect = "magic",
        category = "attack",
    }),

    Soulburn = lunar.Spell(74434, {
        beneficial = true,
        ignoreGCD = true,
        category = "offensive",
    }),

    -- ========================================================
    -- Curses
    -- ========================================================
    CurseOfTheElements = lunar.Spell(1490, {
        effect = "magic",
        category = "attack",
    }),

    CurseOfExhaustion = lunar.Spell(18223, {
        effect = "magic",
        slow = true,
        category = "attack",
    }),

    -- ========================================================
    -- Cooldowns
    -- ========================================================
    DarkSoulMisery = lunar.Spell(113860, {
        beneficial = true,
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        category = "offensive",
    }),

    -- ========================================================
    -- Crowd Control
    -- ========================================================
    Fear = lunar.Spell(5782, {
        cc = "fear",
        effect = "magic",
        category = "cc",
    }),

    HowlOfTerror = lunar.Spell(5484, {
        cc = "fear",
        effect = "magic",
        targeted = false,
        range = 10,
        category = "cc",
    }),

    Shadowfury = lunar.Spell(30283, {
        cc = "stun",
        radius = 8,
        category = "cc",
    }),

    MortalCoil = lunar.Spell(6789, {
        cc = "horror",
        effect = "magic",
        category = "cc",
    }),

    -- ========================================================
    -- Defensive
    -- ========================================================
    DarkRegeneration = lunar.Spell(108359, {
        beneficial = true,
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        category = "defensive",
    }),

    UnendingResolve = lunar.Spell(104773, {
        beneficial = true,
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        ignoreStuns = true,
        category = "defensive",
    }),

    SacrificialPact = lunar.Spell(108416, {
        beneficial = true,
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        category = "defensive",
    }),

    UnboundWill = lunar.Spell(108482, {
        beneficial = true,
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        ignoreControl = true,
        category = "defensive",
    }),

    BloodHorror = lunar.Spell(111397, {
        beneficial = true,
        ignoreGCD = true,
        category = "defensive",
    }),

    -- ========================================================
    -- Utility
    -- ========================================================
    SoulLink = lunar.Spell(108415, {
        beneficial = true,
    }),

    HealthFunnel = lunar.Spell(755, {
        heal = true,
        channel = true,
    }),

    LifeTap = lunar.Spell(1454, {
        ignoreGCD = false,
        category = "default",
    }),

    DemonicCircleTeleport = lunar.Spell(48020, {
        ignoreGCD = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        ignoreControl = false,
        category = "defensive",
    }),

    BurningRush = lunar.Spell(111400, {
        beneficial = true,
    }),

    -- ========================================================
    -- Summons / Cooldowns
    -- ========================================================
    SummonDoomguard = lunar.Spell(18540, {
        beneficial = true,
        category = "offensive",
    }),

    -- ========================================================
    -- Pet Abilities (Observer)
    -- ========================================================
    OpticalBlast = lunar.Spell(115781, {
        interrupt = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        ignoreGCD = true,
        pet = true,
        category = "cc",
    }),

    CloneMagic = lunar.Spell(115284, {
        beneficial = true,
        pet = true,
        ignoreGCD = true,
    }),

    CommandDemon = lunar.Spell(119898, {
        interrupt = true,
        ignoreCasting = true,
        ignoreChanneling = true,
        ignoreGCD = true,
        category = "cc",
    }),

}, spells, getfenv(1))

-- ========================================================
-- Buff / Debuff / Proc ID Constants
-- ========================================================
project.warlock.auras = {
    -- Buffs (on player)
    DARK_SOUL_MISERY     = 113860,
    SOULBURN             = 74434,
    SOUL_SWAP_INHALE     = 86211,   -- DoTs have been inhaled (stored)
    SOUL_SWAP_EXHALE     = 86213,   -- Exhale action spell
    LIGHTWEAVE           = 126734,  -- Tailoring proc (confirmed by sims)
    TRINKET_PROC         = 126706,  -- Malevolent Gladiator's Insignia: +1287 Int, 20s
    LIFEBLOOD            = 74497,   -- Herbalism: +2880 Haste, 20s
    BLOOD_HORROR         = 111397,
    BURNING_RUSH         = 111400,
    SOUL_LINK            = 108415,
    DARK_REGENERATION    = 108359,

    -- Trinket procs (from sims - various tier trinkets)
    TRINKET_138963       = 138963,
    TRINKET_138786       = 138786,
    TRINKET_138898       = 138898,
    TRINKET_139133       = 139133,
    TRINKET_137590       = 137590,

    -- Debuffs (on target)
    AGONY                = 980,
    CORRUPTION           = 172,
    UNSTABLE_AFFLICTION  = 30108,
    HAUNT                = 48181,
    CURSE_OF_ELEMENTS    = 1490,
    CURSE_OF_EXHAUSTION  = 18223,
    FEAR                 = 5782,
    HOWL_OF_TERROR       = 5484,
}
