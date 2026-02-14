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

    -- ========================================================
    -- TIER 0: SURVIVAL (off-GCD, don't die)
    -- Guide: "Being alive IS the prerequisite for pressure"
    -- ========================================================
    spells.UnboundWill("break_cc")
    spells.DarkRegeneration("emergency")
    spells.SacrificialPact("emergency")
    items.Healthstone("emergency")
    spells.DemonicCircleTeleport("los_break")       -- Break incoming CC via LoS

    -- ========================================================
    -- TIER 1: INTERRUPTS (off-GCD)
    -- ========================================================
    spells.OpticalBlast("pvp_interrupt")
    spells.CommandDemon("pvp_interrupt")

    -- ========================================================
    -- TIER 2: CONTROL CHAINS
    -- Guide: "Shadowfury = startup switch for ALL chains"
    -- ========================================================

    -- 2a: Shadowfury initiates — proactive chain start on healer
    spells.Shadowfury("initiate")

    -- 2b: Shadowfury counter — break enemy CC chains
    spells.Shadowfury("counter")

    -- 2c: Fear CC target (healer) — UA-protected
    spells.Fear("cc_target")

    -- 2d: Fear Epoch — spam fear DPS when healer dispel on CD
    spells.Fear("fear_epoch")

    -- 2e: Howl of Terror offensive — AoE fear during Fear Epoch
    spells.HowlOfTerror("offensive")

    -- 2f: Mortal Coil on CC target (horror DR, separate from fear)
    spells.MortalCoil("cc_target")

    -- 2g: Regular fear on DPS (outside epoch, with UA)
    spells.Fear("dps")

    -- 2h: Peel abilities (self-defense)
    spells.HowlOfTerror("peel")
    spells.Shadowfury("peel")
    spells.MortalCoil("peel")
    spells.BloodHorror("activate")

    -- 2i: Teleport escape under melee pressure
    spells.DemonicCircleTeleport("escape")

    -- ========================================================
    -- TIER 3: BURST COOLDOWNS
    -- Guide: "Timing > Frequency"
    -- ========================================================
    spells.DarkSoulMisery("with_procs")
    spells.SummonDoomguard("burst")

    -- ========================================================
    -- TIER 4: SNAPSHOT (Soulburn + Soul Swap)
    -- Guide: "Soul Swap is a time anchor — it doesn't create
    -- damage, it locks damage potential in optimal windows"
    -- ========================================================

    -- 4a: Refresh snapshot before Dark Soul expires
    spells.Soulburn("refresh_snapshot")
    spells.SoulSwap("soulburn_apply")

    -- 4b: Snapshot with Dark Soul active
    spells.Soulburn("snapshot")
    spells.SoulSwap("soulburn_apply")

    -- 4c: Inhale snapshotted DOTs
    spells.SoulSwap("inhale")

    -- 4d: Exhale to spread
    spells.SoulSwap("exhale")

    -- ========================================================
    -- TIER 5: INITIAL DOT APPLICATION
    -- ========================================================
    spells.Soulburn("initial")
    spells.SoulSwap("soulburn_apply")

    -- ========================================================
    -- TIER 6: DOT MAINTENANCE (current target)
    -- Guide Priority: UA (highest) > Agony > Corruption
    -- "UA = dispel protection, must be seamless"
    -- ========================================================
    spells.UnstableAffliction("maintain")   -- HIGHEST: dispel protection
    spells.Agony("maintain")                -- Stacking damage
    spells.Corruption("maintain")           -- Shard generation

    -- ========================================================
    -- TIER 7: CURSES
    -- ========================================================
    spells.CurseOfTheElements("maintain")
    spells.CurseOfExhaustion("kite")

    -- ========================================================
    -- TIER 8: HAUNT (+35% damage amplifier)
    -- ========================================================
    spells.Haunt("snapshot")
    spells.Haunt("maintain")

    -- ========================================================
    -- TIER 9: TOTEM STOMPING
    -- Guide: "Grounding Totem and Tremor Totem are priority"
    -- ========================================================
    spells.Corruption("stomp_dot")
    spells.FelFlame("stomp")

    -- ========================================================
    -- TIER 10: DOT SPREAD (multi-target pressure)
    -- Guide: "Ideal 3 targets with stacked DOTs"
    -- ========================================================
    spells.UnstableAffliction("spread")     -- UA first for dispel protection
    spells.Agony("spread")
    spells.Corruption("spread")
    spells.CurseOfTheElements("spread")

    -- ========================================================
    -- TIER 11: ENEMY PET DOTS
    -- Guide: "DOTs on enemy pets (Water Elemental, Ghoul,
    -- Hunter pets) weakens enemy overall effectiveness"
    -- ========================================================
    spells.Corruption("pet_dot")

    -- ========================================================
    -- TIER 12: PET & SELF MAINTENANCE
    -- Guide: "Pet management is the second skill rotation"
    -- ========================================================
    spells.HealthFunnel("pet")
    spells.DrainLife("heal")

    -- ========================================================
    -- TIER 13: SHARD GENERATION & FILLER
    -- ========================================================
    spells.DrainSoul("shard_gen")
    spells.DrainSoul("execute")
    spells.MaleficGrasp("filler")
    spells.FelFlame("moving")

    -- ========================================================
    -- TIER 14: MANA MANAGEMENT
    -- ========================================================
    spells.LifeTap("mana")
end)
