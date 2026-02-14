local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Crowd Control (Fear / Stun / Horror)
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- Fear - Core CC ability
-- ============================================================

--- Fear the CC target (usually healer) - highest CC priority
spells.Fear:Callback("cc_target", function(spell)
    if not util.should() then return end
    if not settings.warlock_fear_cc_target then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end

    -- Don't fear if already CC'd
    if ccTarget.cc then return end

    -- Check DR and immunities
    if not ccTarget.ccable({ dr = "FEAR", effect = "magic" }) then return end

    -- Protect Fear with UA: only fear if target has UA (dispel = 4s silence)
    if not ccTarget.debuff(auras.UNSTABLE_AFFLICTION, player) then return end

    return spell:Cast(ccTarget, {
        debug = "CC " .. ccTarget.name,
        category = "cc"
    }) and lunar.alert("Fear " .. ccTarget.name .. "!", spell.id)
end)

--- Fear enemy DPS - pressure while healer dispel is on CD
spells.Fear:Callback("dps", function(spell)
    if not util.should() then return end
    if not settings.warlock_fear_dps then return end

    local enemy = lunar.enemies.find(function(e)
        -- Skip CC target (handled by cc_target callback)
        local ccTarget = lunar.ccTarget
        if ccTarget and ccTarget.exists and e.isUnit(ccTarget) then return end

        -- Must be a player, not pet
        if not e.player then return end
        if e.cc then return end

        -- Check DR
        if not e.ccable({ dr = "FEAR", effect = "magic" }) then return end

        -- Must be castable
        if not spell:Castable(e) then return end

        -- Prefer targets with our DoTs ticking (maximize pressure during fear)
        if e.debuff(auras.AGONY, player) then return true end
        if e.debuff(auras.CORRUPTION, player) then return true end

        return true
    end)

    if not enemy then return end

    return spell:Cast(enemy, {
        debug = "Fear DPS " .. enemy.name,
        category = "cc"
    })
end)

-- ============================================================
-- Howl of Terror - AoE Fear (instant, 10 yard range)
-- ============================================================

spells.HowlOfTerror:Callback("peel", function(spell)
    if not util.should() then return end
    if not settings.warlock_howl_of_terror then return end

    local minEnemies = settings.warlock_howl_min_enemies or 1

    -- Count melee enemies in Howl range (10 yards)
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

-- ============================================================
-- Shadowfury - AoE Stun (instant, ground targeted)
-- ============================================================

--- Shadowfury on CC target - control chain anchor
spells.Shadowfury:Callback("cc_target", function(spell)
    if not util.should() then return end
    if not settings.warlock_shadowfury_cc then return end
    if not spells.Shadowfury.known then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end

    -- Check stun DR
    if not ccTarget.ccable({ dr = "STUN" }) then return end

    -- Don't overlap with existing CC
    if ccTarget.cc and ccTarget.ccRemains > 1 then return end

    return spell:SmartAoE(ccTarget, { radius = 8 })
        and lunar.alert("Shadowfury " .. ccTarget.name .. "!", spell.id)
end)

--- Shadowfury peel - stun melee attacking you
spells.Shadowfury:Callback("peel", function(spell)
    if not util.should() then return end
    if not settings.warlock_shadowfury_peel then return end
    if not spells.Shadowfury.known then return end

    -- Only peel when under pressure
    local attackers = player.attackers()
    if attackers.melee == 0 then return end

    -- Find closest melee attacker
    local meleeEnemy = lunar.enemies.find(function(e)
        if not e.meleeRange then return end
        if not e.player then return end
        if not e.ccable({ dr = "STUN" }) then return end
        return true
    end)

    if not meleeEnemy then return end

    return spell:SmartAoE(meleeEnemy, { radius = 8 })
        and lunar.alert("Peel Shadowfury!", spell.id)
end)

-- ============================================================
-- Mortal Coil - Horror + Heal (instant)
-- ============================================================

spells.MortalCoil:Callback("cc_target", function(spell)
    if not util.should() then return end
    if not spells.MortalCoil.known then return end

    local ccTarget = lunar.ccTarget
    if not ccTarget or not ccTarget.exists then return end
    if not ccTarget.enemy then return end

    -- Check horror DR (separate from fear in MoP)
    if not ccTarget.ccable({ dr = "HORROR", effect = "magic" }) then return end

    -- Don't overlap with existing CC
    if ccTarget.cc and ccTarget.ccRemains > 1 then return end

    return spell:Cast(ccTarget, { category = "cc" })
        and lunar.alert("Coil " .. ccTarget.name .. "!", spell.id)
end)

spells.MortalCoil:Callback("peel", function(spell)
    if not util.should() then return end
    if not spells.MortalCoil.known then return end

    -- Peel melee off yourself
    local meleeEnemy = lunar.enemies.find(function(e)
        if not e.meleeRange then return end
        if not e.player then return end
        if not e.ccable({ dr = "HORROR", effect = "magic" }) then return end
        return true
    end)

    if not meleeEnemy then return end

    -- Only when we're taking pressure
    if player.hp > 70 then return end

    return spell:Cast(meleeEnemy, { category = "cc" })
        and lunar.alert("Peel Coil!", spell.id)
end)

-- ============================================================
-- Blood Horror - Passive fear proc when hit by melee
-- ============================================================

spells.BloodHorror:Callback("activate", function(spell)
    if not util.should() then return end
    if not spells.BloodHorror.known then return end

    -- Activate Blood Horror when melee are on us
    if player.buff(auras.BLOOD_HORROR) then return end

    local attackers = player.attackers()
    if attackers.melee == 0 then return end

    return spell:Cast()
end)

-- ============================================================
-- Curse of Exhaustion - Slow for kiting
-- ============================================================

spells.CurseOfExhaustion:Callback("kite", function(spell)
    if not util.should() then return end

    -- Slow melee who are chasing us
    local enemy = lunar.enemies.find(function(e)
        if not e.player then return end
        if not e.melee then return end
        if e.distance > 15 then return end
        if e.slowed then return end
        if e.cc then return end
        if e.debuff(auras.CURSE_OF_EXHAUSTION) then return end
        if e.debuff(auras.CURSE_OF_ELEMENTS) then return end -- Can only have 1 curse
        return spell:Castable(e)
    end)

    if not enemy then return end

    return spell:Cast(enemy)
end)
