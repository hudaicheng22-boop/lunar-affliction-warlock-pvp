local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock - Sim APL Faithful Translation
-- Source: sim-config.json priorityList + valueVariables
-- ============================================================

local spells = project.warlock.spells
local player = lunar.player
local target = lunar.target

-- Spell IDs (from sim)
local AGONY           = 980
local CORRUPTION      = 172
local UA              = 30108
local HAUNT           = 48181
local DRAIN_SOUL      = 1120
local MG              = 103103
local LIFE_TAP        = 1454
local DARK_SOUL       = 113860
local SOULBURN_BUFF   = 74434
local SS_INHALE_BUFF  = 86211
local LIGHTWEAVE      = 126734
local LIFEBLOOD_BUFF  = 74497
local TRINKET_PROCS   = {138963, 138786, 138898, 139133, 137590}

-- ============================================================
-- Sim Variables (translated to functions)
-- ============================================================

-- all-dots-active
local function allDotsActive(unit)
    return unit.debuff(AGONY, player)
       and unit.debuff(CORRUPTION, player)
       and unit.debuff(UA, player)
end

-- no-dots-active
local function noDotsActive(unit)
    return not unit.debuff(AGONY, player)
       and not unit.debuff(CORRUPTION, player)
       and not unit.debuff(UA, player)
end

-- dots-min-time
local function dotsMinTime(unit)
    return math.min(
        unit.debuffRemains(AGONY, player) or 0,
        unit.debuffRemains(UA, player) or 0,
        unit.debuffRemains(CORRUPTION, player) or 0
    )
end

local function shards()
    return player.soulShards or 0
end

local function hasDarkSoul()
    return player.buff(DARK_SOUL) ~= false
end

local function hasSoulburn()
    return player.buff(SOULBURN_BUFF) ~= false
end

local function hasInhale()
    return player.buff(SS_INHALE_BUFF) ~= false
end

local function hasAnyTrinketProc()
    for _, id in ipairs(TRINKET_PROCS) do
        if player.buff(id) then return true end
    end
    if player.buff(LIGHTWEAVE) then return true end
    return false
end

local function enemyCount()
    local count = 0
    lunar.enemies.loop(function() count = count + 1 end)
    return count
end

-- should-swap: targets > 1 AND not all targets have Agony
local function shouldSwap()
    if enemyCount() <= 1 then return false end
    local allHave = true
    lunar.enemies.loop(function(e)
        if not e.debuff(AGONY, player) then allHave = false end
    end)
    return not allHave
end

-- Find exhale target (enemy without our Agony)
local function findExhaleTarget()
    return lunar.enemies.find(function(e)
        if e.isUnit(target) then return end
        if not e.debuff(AGONY, player) then return true end
    end)
end

-- GCD duration (sim: spellGcdHastedDuration of LifeTap)
local function gcdDuration()
    return spells.LifeTap.gcd or 1.5
end

-- ============================================================
-- Sim Priority 2: Dark Soul: Misery (113860)
-- should-dark-soul: trinket proc active, or execute
-- ============================================================
spells.DarkSoulMisery:Callback("burst", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasAnyTrinketProc() then return spell:Cast() end
    if target.hp < 25 then return spell:Cast() end
end)

-- ============================================================
-- Sim Priority 3: Summon Doomguard (18540)
-- execute < 20%, or Dark Soul active, or trinkets + execute25
-- ============================================================
spells.SummonDoomguard:Callback("burst", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.hp < 20 then return spell:Cast() end
    if hasDarkSoul() then return spell:Cast() end
    if hasAnyTrinketProc() and target.hp < 25 then return spell:Cast() end
end)

-- ============================================================
-- Sim Priority 7: Lifeblood (74497) - Herbalism
-- Use during Dark Soul window
-- ============================================================
spells.Lifeblood:Callback("use", function(spell)
    if player.dead or player.mounted then return end
    if hasDarkSoul() then return spell:Cast() end
end)

-- ============================================================
-- Sim Priority 9: SBSS (Soulburn + Soul Swap)
-- should-sbss: no dots on target, or Dark Soul snapshot window
-- ============================================================
spells.Soulburn:Callback("sbss", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasSoulburn() then return end
    if shards() < 1 then return end
    if spells.SoulSwap.cd > 0 then return end
    -- Sim: SBSS when no dots active
    if noDotsActive(target) then return spell:Cast() end
    -- Sim: SBSS during Dark Soul for snapshot
    if hasDarkSoul() and not hasInhale() then return spell:Cast() end
end)

spells.SoulSwap:Callback("sbss_apply", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if not hasSoulburn() then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 10-11: Drain Soul shard generation
-- During buff windows when shards needed
-- ============================================================
spells.DrainSoul:Callback("shard_gen", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if player.channeling then return end
    if shards() >= 3 then return end
    if not allDotsActive(target) then return end
    if not hasDarkSoul() and not hasAnyTrinketProc() then return end
    if player.manaPct <= 15 then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 12: Agony (980)
-- Refresh at <= GCD or not active, AND no inhale buff
-- ============================================================
spells.Agony:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local remains = target.debuffRemains(AGONY, player) or 0
    local active = target.debuff(AGONY, player)
    if active and remains > gcdDuration() then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 13: Corruption (172)
-- Multi (targets>1): refresh < 3s, or < 6s during DS
-- Single: only when not active
-- ============================================================
spells.Corruption:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local remains = target.debuffRemains(CORRUPTION, player) or 0
    local active = target.debuff(CORRUPTION, player)
    local targets = enemyCount()
    if targets > 1 then
        if not active then return spell:Cast(target) end
        if hasDarkSoul() and remains < 6 then return spell:Cast(target) end
        if remains < 3 then return spell:Cast(target) end
    else
        if not active then return spell:Cast(target) end
    end
end)

-- ============================================================
-- Sim Priority 14: Unstable Affliction (30108)
-- Not active, or <= 3s, or snapshot refresh (DS+Lightweave)
-- ============================================================
spells.UnstableAffliction:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local remains = target.debuffRemains(UA, player) or 0
    local active = target.debuff(UA, player)
    if not active then return spell:Cast(target) end
    if remains <= 3 then return spell:Cast(target) end
    -- Sim snapshot: DS active + Lightweave < 3s + UA < 11s + Lightweave active
    if hasDarkSoul() and player.buff(LIGHTWEAVE) then
        if (player.buffRemains(LIGHTWEAVE) or 0) < 3 and remains < 11 then
            return spell:Cast(target)
        end
    end
end)

-- ============================================================
-- Sim Priority 14b (hidden): UA multi-target
-- UA < 3s on other enemies, targets > 1
-- ============================================================
spells.UnstableAffliction:Callback("multi", function(spell)
    if player.dead or player.mounted then return end
    if hasInhale() then return end
    if enemyCount() <= 1 then return end
    local enemy = lunar.enemies.find(function(e)
        if e.isUnit(target) then return end
        local r = e.debuffRemains(UA, player) or 0
        if r < 3 then return spell:Castable(e) end
    end)
    if not enemy then return end
    return spell:Cast(enemy)
end)

-- ============================================================
-- Sim Priority 16: Drain Soul for Haunt shards
-- Haunt < 1s AND shards == 0 AND Haunt not flying
-- ============================================================
spells.DrainSoul:Callback("haunt_shards", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if player.channeling then return end
    if shards() > 0 then return end
    if shouldSwap() then return end
    local hauntRemains = target.debuffRemains(HAUNT, player) or 0
    if hauntRemains >= 1 then return end
    if spells.Haunt.flying then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 17: Haunt (48181)
-- remains < castTime + travelTime + 2s
-- ============================================================
spells.Haunt:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if shards() < 1 then return end
    if spells.Haunt.flying then return end
    local remains = target.debuffRemains(HAUNT, player) or 0
    local threshold = (spell.castTime or 1.5) + 2
    if remains >= threshold then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 19: Soul Swap Inhale (multi-target)
-- should-swap AND all dots on current target
-- ============================================================
spells.SoulSwap:Callback("inhale", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasSoulburn() then return end
    if hasInhale() then return end
    if not shouldSwap() then return end
    if not allDotsActive(target) then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 20: Soul Swap Exhale urgent
-- Inhale active AND buffs about to end (< 2s)
-- ============================================================
spells.SoulSwapExhale:Callback("exhale_urgent", function(spell)
    if player.dead or player.mounted then return end
    if not hasInhale() then return end
    if shards() < 1 then return end
    local urgent = false
    if hasDarkSoul() and (player.buffRemains(DARK_SOUL) or 99) < 2 then urgent = true end
    for _, id in ipairs(TRINKET_PROCS) do
        if player.buff(id) and (player.buffRemains(id) or 99) < 2 then urgent = true end
    end
    if not urgent then return end
    local exhaleTarget = findExhaleTarget()
    if not exhaleTarget then return end
    return spell:Cast(exhaleTarget)
end)

-- ============================================================
-- Sim Priority 21: Soul Swap Exhale spread
-- Not all targets have Agony
-- ============================================================
spells.SoulSwapExhale:Callback("exhale_spread", function(spell)
    if player.dead or player.mounted then return end
    if not hasInhale() then return end
    local exhaleTarget = findExhaleTarget()
    if not exhaleTarget then return end
    return spell:Cast(exhaleTarget)
end)

-- ============================================================
-- Sim Priority 22: Life Tap (mana <= 15%)
-- ============================================================
spells.LifeTap:Callback("mana", function(spell)
    if player.dead or player.mounted then return end
    if player.manaPct > 15 then return end
    if player.hp < 40 then return end
    return spell:Cast()
end)

-- ============================================================
-- Sim Priority 28: Drain Soul execute (target < 20%)
-- ============================================================
spells.DrainSoul:Callback("execute", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.hp >= 20 then return end
    if player.channeling then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 30: Malefic Grasp filler
-- ============================================================
spells.MaleficGrasp:Callback("filler", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if player.channeling then return end
    return spell:Cast(target)
end)

-- ============================================================
-- Sim Priority 31: Life Tap absolute filler
-- ============================================================
spells.LifeTap:Callback("filler", function(spell)
    if player.dead or player.mounted then return end
    if player.channeling then return end
    return spell:Cast()
end)

-- ============================================================
-- Pet auto-summon (not in sim, but practically necessary)
-- ============================================================
spells.Soulburn:Callback("summon_pet", function(spell)
    if player.dead or player.mounted then return end
    if not player.combat then return end
    if hasSoulburn() then return end
    if shards() < 1 then return end
    local pet = lunar.pet
    if pet.exists and not pet.dead then return end
    return spell:Cast()
end)

spells.SummonFelhunter:Callback("auto_summon", function(spell)
    if player.dead or player.mounted then return end
    local pet = lunar.pet
    if pet.exists and not pet.dead then return end
    if player.combat and not hasSoulburn() then return end
    return spell:Cast()
end)
