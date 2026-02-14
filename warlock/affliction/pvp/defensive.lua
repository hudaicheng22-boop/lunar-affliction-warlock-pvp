local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Defensive & Survival
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- Dark Regeneration (T1 Talent) - Emergency heal + HoT boost
-- ============================================================

spells.DarkRegeneration:Callback("emergency", function(spell)
    if not util.should() then return end

    local threshold = settings.warlock_dark_regen_hp or 50
    if player.hp > threshold then return end

    return spell:Cast() and lunar.alert("Dark Regen!", spell.id)
end)

-- ============================================================
-- Sacrificial Pact - Pet HP shield
-- ============================================================

spells.SacrificialPact:Callback("emergency", function(spell)
    if not util.should() then return end
    if not spells.SacrificialPact.known then return end

    -- Use when taking heavy damage
    if player.hp > 50 then return end

    -- Need pet alive for this
    local pet = lunar.pet
    if not pet.exists or pet.dead then return end
    if pet.hp < 30 then return end -- Don't sacrifice pet if it's also low

    return spell:Cast() and lunar.alert("Sac Pact!", spell.id)
end)

-- ============================================================
-- Unbound Will (T4 Talent) - CC break
-- ============================================================

spells.UnboundWill:Callback("break_cc", function(spell)
    if not util.should() then return end
    if not spells.UnboundWill.known then return end

    local threshold = settings.warlock_unbound_will_hp or 40

    -- Only break CC when low health
    if player.hp > threshold then return end

    -- Must be CC'd to use
    if not player.cc then return end

    return spell:Cast() and lunar.alert("Unbound Will!", spell.id)
end)

-- ============================================================
-- Demonic Circle: Teleport - Repositioning
-- ============================================================

spells.DemonicCircleTeleport:Callback("escape", function(spell)
    if not util.should() then return end

    -- Teleport when under heavy melee pressure
    local attackers = player.attackers()
    if attackers.melee == 0 then return end

    -- Only when taking significant damage
    if player.hp > 60 then return end

    -- Don't teleport if we're already safe
    if attackers.melee == 0 then return end

    return spell:Cast() and lunar.alert("Teleport!", spell.id)
end)

-- ============================================================
-- Drain Life - Emergency self-heal
-- ============================================================

spells.DrainLife:Callback("heal", function(spell)
    if not util.should() then return end
    if not settings.warlock_drain_life then return end
    if not target.enemy then return end

    local threshold = settings.warlock_drain_life_hp or 40
    if player.hp > threshold then return end

    -- Don't drain life if we have better things to do
    -- Only use when our DoTs are maintained
    if not util.hasAllDots(target) then return end

    return spell:Cast(target, { category = "heal" })
end)

-- ============================================================
-- Health Funnel - Pet healing
-- ============================================================

spells.HealthFunnel:Callback("pet", function(spell)
    if not util.should() then return end
    if not settings.warlock_health_funnel then return end

    local pet = lunar.pet
    if not pet.exists or pet.dead then return end

    local threshold = settings.warlock_health_funnel_hp or 40
    if pet.hp > threshold then return end

    -- Don't heal pet if we're low ourselves
    if player.hp < 50 then return end

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
-- Life Tap - Mana management
-- ============================================================

spells.LifeTap:Callback("mana", function(spell)
    if not util.should() then return end

    -- Only Life Tap when mana is low
    if player.manaPct > 30 then return end

    -- Don't Life Tap when health is too low
    if player.hp < 40 then return end

    return spell:Cast()
end)
