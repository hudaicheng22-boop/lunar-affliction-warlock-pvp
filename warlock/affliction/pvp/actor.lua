local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Actor (Main Priority System)
-- ============================================================
-- Philosophy: Slow rot, layered pressure, total control.
-- Not burst — sustained pressure that crushes over time.
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target
local items = project.warlock.items

-- Create the actor: Affliction Warlock (class 9, spec 1)
local actor = lunar.Actor:New({
    spec = 1,           -- Affliction
    class = "warlock"
})

-- ============================================================
-- Main Priority System
-- ============================================================
-- Order matters: first successful cast wins the tick.
--
-- Priority hierarchy (PvP Affliction):
--   1. Survival (don't die)
--   2. Interrupts & stomps (deny enemy actions)
--   3. CC control chains (fear/stun healer, fear DPS)
--   4. Burst cooldown (Dark Soul with procs)
--   5. Snapshot DoTs (Soulburn + Soul Swap)
--   6. Maintain DoTs on current target
--   7. Spread DoTs to off-targets
--   8. Curses
--   9. Haunt maintenance
--  10. Filler (Malefic Grasp / Drain Soul / Fel Flame)
--  11. Life Tap (mana)
-- ============================================================

actor:Init(function()

    -- ========================================================
    -- TIER 0: Emergency Survival (off-GCD where possible)
    -- ========================================================
    spells.UnboundWill("break_cc")
    spells.DarkRegeneration("emergency")
    spells.SacrificialPact("emergency")
    items.Healthstone("emergency")

    -- ========================================================
    -- TIER 1: Interrupts (off-GCD, highest non-survival priority)
    -- ========================================================
    spells.OpticalBlast("pvp_interrupt")
    spells.CommandDemon("pvp_interrupt")

    -- ========================================================
    -- TIER 2: CC Control Chains
    -- ========================================================
    -- Shadowfury on CC target (instant stun, control chain anchor)
    spells.Shadowfury("cc_target")

    -- Fear CC target (healer) — protected by UA dispel silence
    spells.Fear("cc_target")

    -- Mortal Coil on CC target (horror DR, separate from fear)
    spells.MortalCoil("cc_target")

    -- Howl of Terror (AoE instant fear for peeling)
    spells.HowlOfTerror("peel")

    -- Fear enemy DPS (pressure while healer dispel on CD)
    spells.Fear("dps")

    -- Peel abilities
    spells.Shadowfury("peel")
    spells.MortalCoil("peel")
    spells.BloodHorror("activate")

    -- ========================================================
    -- TIER 3: Burst Cooldowns
    -- ========================================================
    spells.DarkSoulMisery("with_procs")
    spells.SummonDoomguard("burst")

    -- ========================================================
    -- TIER 4: Snapshot System (Soulburn + Soul Swap)
    -- ========================================================
    -- Refresh snapshot before Dark Soul expires
    spells.Soulburn("refresh_snapshot")
    spells.SoulSwap("soulburn_apply")

    -- Snapshot with Dark Soul active
    spells.Soulburn("snapshot")
    spells.SoulSwap("soulburn_apply")

    -- Inhale snapshotted DoTs from current target
    spells.SoulSwap("inhale")

    -- Exhale to spread snapshotted DoTs to other targets
    spells.SoulSwap("exhale")

    -- ========================================================
    -- TIER 5: Initial DoT Application (no DoTs on target)
    -- ========================================================
    spells.Soulburn("initial")
    spells.SoulSwap("soulburn_apply")

    -- ========================================================
    -- TIER 6: DoT Maintenance on Current Target
    -- ========================================================
    spells.Agony("maintain")
    spells.UnstableAffliction("maintain")
    spells.Corruption("maintain")

    -- ========================================================
    -- TIER 7: Curses
    -- ========================================================
    spells.CurseOfTheElements("maintain")
    spells.CurseOfExhaustion("kite")

    -- ========================================================
    -- TIER 8: Haunt
    -- ========================================================
    spells.Haunt("snapshot")    -- Priority: use during snapshot window
    spells.Haunt("maintain")    -- Otherwise: keep it up for +35%

    -- ========================================================
    -- TIER 9: Totem Stomping
    -- ========================================================
    spells.Corruption("stomp_dot")  -- DoT priority totems (Grounding, Tremor)
    spells.FelFlame("stomp")        -- Kill low-health totems

    -- ========================================================
    -- TIER 10: DoT Spread (Multi-target pressure)
    -- ========================================================
    spells.Agony("spread")
    spells.Corruption("spread")
    spells.UnstableAffliction("spread")
    spells.CurseOfTheElements("spread")

    -- ========================================================
    -- TIER 11: Pet & Self Maintenance
    -- ========================================================
    spells.HealthFunnel("pet")
    spells.DrainLife("heal")

    -- ========================================================
    -- TIER 12: Shard Generation & Filler
    -- ========================================================
    spells.DrainSoul("shard_gen")   -- Generate shards for SBSS during snapshot window
    spells.DrainSoul("execute")     -- Execute (target < 20%)
    spells.MaleficGrasp("filler")   -- Standard filler
    spells.FelFlame("moving")       -- Moving filler

    -- ========================================================
    -- TIER 13: Mana Management
    -- ========================================================
    spells.LifeTap("mana")

    -- ========================================================
    -- TIER 14: Teleport (lowest priority, escape when needed)
    -- ========================================================
    spells.DemonicCircleTeleport("escape")
end)
