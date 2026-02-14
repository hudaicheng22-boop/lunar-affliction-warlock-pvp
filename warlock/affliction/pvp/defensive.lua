local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Defensive & Survival
-- Revised per PvP Guide: "Survival through space management"
-- ============================================================
-- Guide philosophy: "Survival doesn't come from tanking damage,
-- but from space management: Demonic Circle (LoS behind pillar),
-- Demonic Gateway (45s CD, displacement fraud), Curse of
-- Exhaustion (kiting slow), Soul Link (damage transfer to pet)
-- = 4-dimensional defense network"
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- Dark Regeneration (T1 Talent)
-- ============================================================

spells.DarkRegeneration:Callback("emergency", function(spell)
    if not util.should() then return end

    local threshold = settings.warlock_dark_regen_hp or 50
    if player.hp > threshold then return end

    return spell:Cast() and lunar.alert("Dark Regen!", spell.id)
end)

-- ============================================================
-- Sacrificial Pact — Pet HP → Shield
-- Guide: "Soul Link makes pet HP = your survival threshold"
-- ============================================================

spells.SacrificialPact:Callback("emergency", function(spell)
    if not util.should() then return end
    if not spells.SacrificialPact.known then return end
    if player.hp > 50 then return end

    local pet = lunar.pet
    if not pet.exists or pet.dead then return end
    if pet.hp < 30 then return end

    return spell:Cast() and lunar.alert("Sac Pact!", spell.id)
end)

-- ============================================================
-- Unbound Will (T4 Talent) — CC break
-- ============================================================

spells.UnboundWill:Callback("break_cc", function(spell)
    if not util.should() then return end
    if not spells.UnboundWill.known then return end

    local threshold = settings.warlock_unbound_will_hp or 40
    if player.hp > threshold then return end
    if not player.cc then return end

    return spell:Cast() and lunar.alert("Unbound Will!", spell.id)
end)

-- ============================================================
-- Demonic Circle: Teleport
-- Guide: "Portal behind pillar = physical barrier AND strategic
-- denial of enemy team's space usage. Forces melee to abandon
-- charges, interrupts ranged casts, delays healer support."
-- ============================================================

spells.DemonicCircleTeleport:Callback("escape", function(spell)
    if not util.should() then return end

    -- Teleport when under heavy melee pressure AND low HP
    local attackers = player.attackers()
    if attackers.melee == 0 then return end
    if player.hp > 55 then return end

    return spell:Cast() and lunar.alert("Teleport!", spell.id)
end)

--- Teleport to break casts targeting us
spells.DemonicCircleTeleport:Callback("los_break", function(spell)
    if not util.should() then return end

    -- Teleport to break enemy casts when they're targeting us
    local incomingCC = player.incoming()
    if not incomingCC.cc then return end
    if incomingCC.castRemains > 1 then return end  -- Almost landing

    return spell:Cast() and lunar.alert("LoS Teleport!", spell.id)
end)

-- ============================================================
-- Drain Life — Emergency self-heal
-- Guide: "Only when DoTs are maintained and no better options"
-- ============================================================

spells.DrainLife:Callback("heal", function(spell)
    if not util.should() then return end
    if not settings.warlock_drain_life then return end
    if not target.enemy then return end

    local threshold = settings.warlock_drain_life_hp or 40
    if player.hp > threshold then return end

    -- Only drain life when our DOTs are up (don't waste GCDs)
    if not util.hasAllDots(target) then return end

    return spell:Cast(target, { category = "heal" })
end)

-- ============================================================
-- Health Funnel — Pet Healing
-- Guide: "Pet management is the 'second skill rotation'.
-- Ignoring pet survivability = abandoning 50% of your
-- strategic depth and survival redundancy."
-- ============================================================

spells.HealthFunnel:Callback("pet", function(spell)
    if not util.should() then return end
    if not settings.warlock_health_funnel then return end

    local pet = lunar.pet
    if not pet.exists or pet.dead then return end

    local threshold = settings.warlock_health_funnel_hp or 40
    if pet.hp > threshold then return end

    -- Don't heal pet if we're dangerously low ourselves
    if player.hp < 40 then return end

    -- Don't heal pet if we're under heavy CC pressure
    if player.cc then return end

    return spell:Cast()
end)

-- ============================================================
-- Healthstone
-- ============================================================

local Healthstone = lunar.Item(5512)

Healthstone:Callback("emergency", function(item)
    if not util.should() then return end

    local threshold = settings.warlock_healthstone_hp or 40
    if player.hp > threshold then return end

    return item:Use()
end)

project.warlock.items.Healthstone = Healthstone

-- ============================================================
-- Life Tap — Mana Management
-- ============================================================

spells.LifeTap:Callback("mana", function(spell)
    if not util.should() then return end
    if player.manaPct > 15 then return end  -- Sim: <= 15%
    if player.hp < 40 then return end

    return spell:Cast()
end)
