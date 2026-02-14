local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - Interrupt & Totem Stomping
-- ============================================================

local spells = project.warlock.spells
local auras = project.warlock.auras
local settings = project.settings
local util = project.warlock.util
local player = lunar.player
local target = lunar.target

-- ============================================================
-- PvP Interrupt - Observer Optical Blast / Command Demon
-- ============================================================

local function shouldPvpInterrupt(interrupt, spell)
    if interrupt.ccOnly then return end

    local enemy = interrupt.enemy

    -- Check if the interrupt type is enabled in settings
    if settings.general_kick and not settings.general_kick[interrupt.type] then
        return
    end

    if not spell:Castable(enemy) then return end

    return true
end

--- Optical Blast (Observer pet interrupt) - 40 yard range
spells.OpticalBlast:Callback("pvp_interrupt", function(spell)
    if not util.should() then return end

    local pvpInterrupts = lunar.PvpInterrupts()
    if not pvpInterrupts then return end

    local bestInterrupt
    for _, interrupt in ipairs(pvpInterrupts) do
        if shouldPvpInterrupt(interrupt, spell) then
            bestInterrupt = interrupt
            break
        end
    end

    if not bestInterrupt then return end

    -- Interrupt at the end of cast for maximum disruption
    local enemy = bestInterrupt.enemy
    if enemy.casting and enemy.castRemains > lunar.buffer + 0.1 then
        return
    end

    local castPct = enemy.castPct
    if castPct == 0 then
        castPct = enemy.channelPct
    end

    return spell:Cast(enemy, {
        debug = bestInterrupt.spellName .. " | pct: " .. castPct
    }) and lunar.alert("Interrupt " .. bestInterrupt.spellName .. "!", spell.id)
end)

--- Command Demon (fallback if not using Observer / Grimoire of Supremacy)
spells.CommandDemon:Callback("pvp_interrupt", function(spell)
    if not util.should() then return end
    -- Skip if Observer Optical Blast is available (Grimoire of Supremacy)
    if spells.OpticalBlast.known then return end

    local pvpInterrupts = lunar.PvpInterrupts()
    if not pvpInterrupts then return end

    local bestInterrupt
    for _, interrupt in ipairs(pvpInterrupts) do
        if shouldPvpInterrupt(interrupt, spell) then
            bestInterrupt = interrupt
            break
        end
    end

    if not bestInterrupt then return end

    local enemy = bestInterrupt.enemy
    if enemy.casting and enemy.castRemains > lunar.buffer + 0.1 then
        return
    end

    local castPct = enemy.castPct
    if castPct == 0 then
        castPct = enemy.channelPct
    end

    return spell:Cast(enemy, {
        debug = bestInterrupt.spellName .. " | pct: " .. castPct
    }) and lunar.alert("Interrupt " .. bestInterrupt.spellName .. "!", spell.id)
end)

-- ============================================================
-- Totem Stomping
-- ============================================================

-- High-priority totems to target with DoTs
local priorityTotemIDs = {
    [59190] = true,  -- Grounding Totem
    [8170]  = true,  -- Tremor Totem
}

--- Fel Flame: Stomp low-health totems instantly
spells.FelFlame:Callback("stomp", function(spell)
    if not util.should() then return end
    if not settings.misc_stomp_totems then return end

    local totem = lunar.Stomp(spell, { below = 2500 })
    if not totem then return end

    return spell:Cast(totem) and lunar.alert("Stomp " .. totem.name .. "!", spell.id)
end)

--- Corruption: DoT high-priority totems (Grounding, Tremor)
spells.Corruption:Callback("stomp_dot", function(spell)
    if not util.should() then return end
    if not settings.misc_stomp_totems then return end

    local totem = lunar.Stomp(spell, { totemIDs = priorityTotemIDs })
    if not totem then return end

    -- Don't re-apply if already has our Corruption
    if totem.debuff(spell.id, player) then return end

    return spell:Cast(totem) and lunar.alert("Stomp " .. totem.name .. "!", spell.id)
end)
