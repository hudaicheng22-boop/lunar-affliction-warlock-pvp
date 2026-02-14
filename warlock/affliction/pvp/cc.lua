local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Crowd Control
-- Revised per PvP Guide: Fear Epoch + Control Chain philosophy
-- ============================================================
-- Key concepts from guide:
--   1. Fear Epoch: When healer dispels UA → 8s CD → spam fear DPS
--   2. Shadowfury = "startup switch" for ALL control chains
--   3. 3 consecutive fears = 12+ second group suppression
--   4. UA protection: ALWAYS have UA on target before fearing
--   5. Howl of Terror CD reduces by 1s per melee hit received
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- SHADOWFURY — Control Chain Initiator
-- Guide: "Zero windup, instant, no cast bar — the startup 
-- switch for all control chains"
-- ============================================================

--- Shadowfury on CC target — PROACTIVE chain starter
--- Guide: "First lock down healer to ensure safe team engage"
spells.Shadowfury:Callback("initiate", function(spell)
    if not util.should() then return end
    if not settings.warlock_shadowfury_cc then return end
    if not spells.Shadowfury.known then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end

    if not ccTarget.ccable({ dr = "STUN" }) then return end

    -- Don't overlap: only if target is NOT currently CC'd
    if ccTarget.cc then return end

    -- Proactive: initiate chain when we have pressure set up
    -- (DOTs on team, ready to capitalize)
    return spell:SmartAoE(ccTarget, { radius = 8 })
        and lunar.alert("Chain Start: " .. ccTarget.name .. "!", spell.id)
end)

--- Shadowfury counter-initiate — interrupt enemy control chains
--- Guide: "Can preemptively break enemy chains (e.g. Mage+Druid combos)"
spells.Shadowfury:Callback("counter", function(spell)
    if not util.should() then return end
    if not spells.Shadowfury.known then return end

    -- Stun enemy casting CC on us or ally
    local enemy = lunar.enemies.find(function(e)
        if not e.casting then return end
        if not e.player then return end
        if e.distance > 30 then return end
        if not e.ccable({ dr = "STUN" }) then return end

        -- Is casting CC at us or our ally?
        local castTarget = e.castTarget
        if castTarget.exists and castTarget.friend then
            return true
        end
        return false
    end)

    if not enemy then return end

    return spell:SmartAoE(enemy, { radius = 8 })
        and lunar.alert("Counter SF: " .. enemy.name .. "!", spell.id)
end)

--- Shadowfury peel — stun melee off yourself
spells.Shadowfury:Callback("peel", function(spell)
    if not util.should() then return end
    if not settings.warlock_shadowfury_peel then return end
    if not spells.Shadowfury.known then return end

    if not util.underMeleePressure() then return end
    if player.hp > 60 then return end  -- Only when under real pressure

    local meleeEnemy = lunar.enemies.find(function(e)
        if not e.meleeRange then return end
        if not e.player then return end
        if not e.ccable({ dr = "STUN" }) then return end
        return true
    end)

    if not meleeEnemy then return end

    return spell:SmartAoE(meleeEnemy, { radius = 8 })
        and lunar.alert("Peel SF!", spell.id)
end)

-- ============================================================
-- FEAR — Core CC + Fear Epoch System
-- Guide: "Fear in MoP transcends traditional CC — high damage
-- threshold means DOTs won't break it"
-- ============================================================

--- Fear CC target (healer) — PROTECTED by UA
--- Guide: "Always keep someone in Fear covered by UA"
spells.Fear:Callback("cc_target", function(spell)
    if not util.should() then return end
    if not settings.warlock_fear_cc_target then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end
    if ccTarget.cc then return end

    if not ccTarget.ccable({ dr = "FEAR", effect = "magic" }) then return end

    -- CRITICAL: Only fear if target has UA (dispel = 4s silence)
    -- Guide: "UA protection makes Fear undispellable in practice"
    if not util.hasUAProtection(ccTarget) then return end

    return spell:Cast(ccTarget, {
        debug = "CC " .. ccTarget.name,
    }) and lunar.alert("Fear " .. ccTarget.name .. "!", spell.id)
end)

--- Fear Epoch: Spam fear on DPS while healer dispel is on CD
--- Guide: "When healer dispels UA → 8s CD → Fear Epoch begins
--- → cycle Fear on DPS while DOTs burn them alive"
spells.Fear:Callback("fear_epoch", function(spell)
    if not util.should() then return end
    if not settings.warlock_fear_dps then return end

    -- Only enter Fear Epoch when healer dispel is on CD
    if not util.isFearEpoch() then return end

    -- Find best DPS to fear (prefers targets with our DOTs)
    local fearTarget = util.findBestFearDPS(spell)
    if not fearTarget then return end

    return spell:Cast(fearTarget, {
        debug = "FEAR EPOCH: " .. fearTarget.name .. " (dispel CD: " ..
                string.format("%.1f", util.healerDispelCDRemains()) .. "s)",
    }) and lunar.alert("Fear Epoch: " .. fearTarget.name .. "!", spell.id)
end)

--- Regular fear on DPS — outside Fear Epoch, still fear when profitable
spells.Fear:Callback("dps", function(spell)
    if not util.should() then return end
    if not settings.warlock_fear_dps then return end

    -- Skip if Fear Epoch is active (handled by fear_epoch callback)
    if util.isFearEpoch() then return end

    local fearTarget = util.findBestFearDPS(spell)
    if not fearTarget then return end

    -- Outside epoch, only fear targets with UA protection
    if not util.hasUAProtection(fearTarget) then return end

    return spell:Cast(fearTarget, {
        debug = "Fear DPS: " .. fearTarget.name,
    })
end)

-- ============================================================
-- HOWL OF TERROR — AoE Instant Fear
-- Guide: "40s base CD, reduced by 1s per melee hit received
-- → far higher uptime vs melee than theoretical"
-- ============================================================

spells.HowlOfTerror:Callback("peel", function(spell)
    if not util.should() then return end
    if not settings.warlock_howl_of_terror then return end

    local minEnemies = settings.warlock_howl_min_enemies or 1

    local count = lunar.enemies.around(player, 10, function(e)
        if not e.player then return end
        if e.cc then return end
        if not e.ccable({ dr = "FEAR", effect = "magic" }) then return end
        return true
    end)

    if count < minEnemies then return end

    return spell:Cast(nil, { category = "cc" })
        and lunar.alert("Howl!", spell.id)
end)

--- Howl of Terror offensive — AoE fear for multi-target pressure
spells.HowlOfTerror:Callback("offensive", function(spell)
    if not util.should() then return end
    if not settings.warlock_howl_of_terror then return end

    -- Use offensively when 2+ fearable enemies in range during Fear Epoch
    if not util.isFearEpoch() then return end

    local count = lunar.enemies.around(player, 10, function(e)
        if not e.player then return end
        if e.cc then return end
        if not e.ccable({ dr = "FEAR", effect = "magic" }) then return end
        return true
    end)

    if count < 2 then return end

    return spell:Cast(nil, { category = "cc" })
        and lunar.alert("Offensive Howl!", spell.id)
end)

-- ============================================================
-- MORTAL COIL — Horror (separate DR from Fear in MoP)
-- ============================================================

spells.MortalCoil:Callback("cc_target", function(spell)
    if not util.should() then return end
    if not spells.MortalCoil.known then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end
    if ccTarget.cc and ccTarget.ccRemains > 1 then return end

    if not ccTarget.ccable({ dr = "HORROR", effect = "magic" }) then return end

    return spell:Cast(ccTarget, { category = "cc" })
        and lunar.alert("Coil " .. ccTarget.name .. "!", spell.id)
end)

spells.MortalCoil:Callback("peel", function(spell)
    if not util.should() then return end
    if not spells.MortalCoil.known then return end
    if player.hp > 70 then return end

    local meleeEnemy = lunar.enemies.find(function(e)
        if not e.meleeRange then return end
        if not e.player then return end
        if not e.ccable({ dr = "HORROR", effect = "magic" }) then return end
        return true
    end)

    if not meleeEnemy then return end

    return spell:Cast(meleeEnemy, { category = "cc" })
        and lunar.alert("Peel Coil!", spell.id)
end)

-- ============================================================
-- BLOOD HORROR — Passive fear when hit by melee
-- ============================================================

spells.BloodHorror:Callback("activate", function(spell)
    if not util.should() then return end
    if not spells.BloodHorror.known then return end
    if player.buff(auras.BLOOD_HORROR) then return end

    if not util.underMeleePressure() then return end

    return spell:Cast()
end)

-- ============================================================
-- CURSE OF EXHAUSTION — Kiting tool
-- Guide: "Slowing curse for space management"
-- ============================================================

spells.CurseOfExhaustion:Callback("kite", function(spell)
    if not util.should() then return end

    local enemy = lunar.enemies.find(function(e)
        if not e.player then return end
        if not e.melee then return end
        if e.distance > 15 then return end
        if e.slowed then return end
        if e.cc then return end
        if e.debuff(auras.CURSE_OF_EXHAUSTION) then return end
        if e.debuff(auras.CURSE_OF_ELEMENTS) then return end
        return spell:Castable(e)
    end)

    if not enemy then return end
    return spell:Cast(enemy)
end)
