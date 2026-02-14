local unlocker, lunar, project = ...

-- Sim priorityList translation - only from sim-config.json
local spells = project.warlock.spells
local player = lunar.player
local target = lunar.target

local AGONY, CORRUPTION, UA, HAUNT = 980, 172, 30108, 48181
local DARK_SOUL, SOULBURN_BUFF, SS_INHALE = 113860, 74434, 86211
local LIGHTWEAVE = 126734

local function shards() return player.soulShards or 0 end
local function hasDS() return player.buff(DARK_SOUL) ~= false end
local function hasSB() return player.buff(SOULBURN_BUFF) ~= false end
local function hasInhale() return player.buff(SS_INHALE) ~= false end

local function allDots(u)
    return u.debuff(AGONY, player) and u.debuff(CORRUPTION, player) and u.debuff(UA, player)
end

local function noDots(u)
    return not u.debuff(AGONY, player) and not u.debuff(CORRUPTION, player) and not u.debuff(UA, player)
end

local function hasProc()
    if player.buff(LIGHTWEAVE) then return true end
    for _, id in ipairs({138963,138786,138898,139133,137590}) do
        if player.buff(id) then return true end
    end
    return false
end

local function enemyCount()
    local n = 0
    lunar.enemies.loop(function() n = n + 1 end)
    return n
end

local function findExhale()
    return lunar.enemies.find(function(e)
        if e.isUnit(target) then return end
        if e.debuff(AGONY, player) then return end
        return true
    end)
end

local gcd = function() return spells.LifeTap.gcd or 1.5 end

-- Dark Soul
spells.DarkSoulMisery:Callback("burst", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasProc() then return spell:Cast() end
    if target.hp < 25 then return spell:Cast() end
end)

-- Doomguard
spells.SummonDoomguard:Callback("burst", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.hp < 20 then return spell:Cast() end
    if hasDS() then return spell:Cast() end
    if hasProc() and target.hp < 25 then return spell:Cast() end
end)

-- SBSS
spells.Soulburn:Callback("sbss", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasSB() then return end
    if shards() < 1 then return end
    if spells.SoulSwap.cd > 0 then return end
    if noDots(target) then return spell:Cast() end
    if hasDS() and not hasInhale() then return spell:Cast() end
end)

spells.SoulSwap:Callback("sbss_apply", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if not hasSB() then return end
    return spell:Cast(target)
end)

-- Agony (sim: <= GCD or not active)
spells.Agony:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local r = target.debuffRemains(AGONY, player) or 0
    if target.debuff(AGONY, player) and r > gcd() then return end
    return spell:Cast(target)
end)

-- Corruption (sim: multi <3s/<6sDS, single when not active)
spells.Corruption:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local r = target.debuffRemains(CORRUPTION, player) or 0
    local act = target.debuff(CORRUPTION, player)
    local n = enemyCount()
    if n > 1 then
        if not act then return spell:Cast(target) end
        if hasDS() and r < 6 then return spell:Cast(target) end
        if r < 3 then return spell:Cast(target) end
    else
        if not act then return spell:Cast(target) end
    end
end)

-- UA (sim: not active or <= 3s or DS+LW snapshot)
spells.UnstableAffliction:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasInhale() then return end
    local r = target.debuffRemains(UA, player) or 0
    if not target.debuff(UA, player) then return spell:Cast(target) end
    if r <= 3 then return spell:Cast(target) end
    if hasDS() and player.buff(LIGHTWEAVE) and (player.buffRemains(LIGHTWEAVE) or 99) < 3 and r < 11 then return spell:Cast(target) end
end)

-- Drain Soul shard gen (sim: 0 shards, all dots, buff window)
spells.DrainSoul:Callback("shard_gen", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy or player.channeling then return end
    if shards() >= 3 or not allDots(target) then return end
    if not hasDS() and not hasProc() then return end
    if (player.manaPct or 100) <= 15 then return end
    return spell:Cast(target)
end)

-- Haunt
spells.Haunt:Callback("maintain", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if shards() < 1 then return end
    if spells.Haunt.flying then return end
    local r = target.debuffRemains(HAUNT, player) or 0
    if r >= (spell.castTime or 1.5) + 2 then return end
    return spell:Cast(target)
end)

-- Soul Swap Inhale (multi)
spells.SoulSwap:Callback("inhale", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if hasSB() or hasInhale() then return end
    if enemyCount() <= 1 then return end
    if not allDots(target) then return end
    local need = false
    lunar.enemies.loop(function(e) if not e.debuff(AGONY, player) then need = true end end)
    if not need then return end
    return spell:Cast(target)
end)

-- Soul Swap Exhale
spells.SoulSwapExhale:Callback("exhale", function(spell)
    if player.dead or player.mounted then return end
    if not hasInhale() then return end
    local t = findExhale()
    if not t then return end
    return spell:Cast(t)
end)

-- Life Tap
spells.LifeTap:Callback("mana", function(spell)
    if player.dead or player.mounted then return end
    if (player.manaPct or 100) > 15 then return end
    if (player.hp or 100) < 40 then return end
    return spell:Cast()
end)

-- Drain Soul execute
spells.DrainSoul:Callback("execute", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if target.hp >= 20 then return end
    if player.channeling then return end
    return spell:Cast(target)
end)

-- Malefic Grasp filler
spells.MaleficGrasp:Callback("filler", function(spell)
    if player.dead or player.mounted then return end
    if not target.enemy then return end
    if player.channeling then return end
    return spell:Cast(target)
end)

spells.LifeTap:Callback("filler", function(spell)
    if player.dead or player.mounted then return end
    if player.channeling then return end
    return spell:Cast()
end)

-- Pet (sim classOptions summon Felhunter)
spells.Soulburn:Callback("summon_pet", function(spell)
    if player.dead or player.mounted then return end
    if not player.combat then return end
    if hasSB() or shards() < 1 then return end
    local pet = lunar.pet
    if pet.exists and not pet.dead then return end
    return spell:Cast()
end)

spells.SummonFelhunter:Callback("auto_summon", function(spell)
    if player.dead or player.mounted then return end
    local pet = lunar.pet
    if pet.exists and not pet.dead then return end
    if player.combat and not hasSB() then return end
    return spell:Cast()
end)
