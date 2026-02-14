local unlocker, lunar, project = ...

-- ============================================================
-- Affliction Warlock PvP - GUI Configuration
-- ============================================================

project.gui, project.settings, project.cmd = lunar.UI:New("Affliction")

local gui = project.gui
local settings = project.settings

-- ============================================================
-- General Tab
-- ============================================================
local general = gui:Group("General")

local cc = general:Tab("CC & Interrupt")

cc:Text({ text = "Interrupt Settings", header = true })

cc:Dropdown({
    var = "general_kick",
    multi = true,
    tooltip = "Configure which types of enemy spells should be interrupted.\n\n" ..
            lunar.colors.pink .. "CC:|r " .. lunar.colors.white .. "Crowd control spells (Polymorph, Fear, Cyclone, etc.)\n" ..
            lunar.colors.red .. "Damage:|r " .. lunar.colors.white .. "High damage spells (Chaos Bolt, Greater Pyroblast, etc.)\n" ..
            lunar.colors.green .. "Heal:|r " .. lunar.colors.white .. "Healing spells (Flash Heal, Regrowth, Healing Wave, etc.)\n" ..
            lunar.colors.yellow .. "Beneficial:|r " .. lunar.colors.white .. "Beneficial spells (Mass Dispel, Divine Hymn, etc.)\n" ..
            lunar.colors.orange .. "Offensive:|r " .. lunar.colors.white .. "Offensive cooldowns (Convoke, Void Torrent, etc.)",
    options = {
        { label = "Crowd Control", value = "cc" },
        { label = "Damage Spells", value = "damage" },
        { label = "Healing Spells", value = "heal" },
        { label = "Beneficial Spells", value = "beneficial" },
        { label = "Offensive Cooldowns", value = "offensive" },
    },
    default = { "cc", "damage", "heal", "beneficial", "offensive" },
    placeholder = "Select spell categories to interrupt",
    header = "Interrupt Categories",
})

cc:Separator()

cc:Text({ text = "CC Target", header = true })

cc:Dropdown({
    var = "general_cc_target",
    default = "auto",
    options = {
        { label = lunar.colors.white .. "Auto", value = "auto", tooltip = "Chooses smartly between healer and focus." },
        { label = lunar.colors.white .. "Healer", value = "healer", tooltip = "Main CC target will be only healer, ignoring focus completely." },
        { label = lunar.colors.white .. "Focus", value = "focus", tooltip = "Main CC target will be focus." },
    },
    placeholder = lunar.colors.white .. "Select main CC target",
    header = lunar.colors.white .. "Main CC Target",
})

-- ============================================================
-- Offense Tab
-- ============================================================
local offense = gui:Group("Offense")

local dots = offense:Tab("DoTs")

dots:Text({ text = "DoT Pressure Settings", header = true })

dots:Checkbox({
    text = "Multi-DoT Enemies",
    var = "warlock_multi_dot",
    default = true,
    tooltip = "Spread DoTs to multiple targets for pressure."
})

dots:Slider({
    text = "Max DoT Targets",
    var = "warlock_max_dot_targets",
    min = 1,
    max = 5,
    default = 3,
    tooltip = "Maximum number of targets to maintain DoTs on."
})

dots:Separator()

dots:Text({ text = "Snapshot Settings", header = true })

dots:Checkbox({
    text = "Auto Snapshot (Dark Soul + Procs)",
    var = "warlock_auto_snapshot",
    default = true,
    tooltip = "Automatically use Soulburn + Soul Swap to snapshot DoTs\nwhen Dark Soul: Misery and trinket procs are active."
})

dots:Checkbox({
    text = "Curse of the Elements",
    var = "warlock_curse_of_elements",
    default = true,
    tooltip = "Maintain Curse of the Elements on all targets."
})

local burst = offense:Tab("Burst")

burst:Text({ text = "Dark Soul: Misery", header = true })

burst:Dropdown({
    var = "warlock_dark_soul_mode",
    default = "with_procs",
    options = {
        { label = lunar.colors.white .. "With Procs", value = "with_procs", tooltip = "Use Dark Soul when trinket/tailoring procs are active for maximum snapshot." },
        { label = lunar.colors.white .. "On Cooldown", value = "on_cd", tooltip = "Use Dark Soul on cooldown." },
        { label = lunar.colors.white .. "Manual", value = "manual", tooltip = "Never auto-use Dark Soul." },
    },
    placeholder = lunar.colors.white .. "Dark Soul Usage",
    header = lunar.colors.white .. "Dark Soul Mode",
})

-- ============================================================
-- CC Tab
-- ============================================================
local ccGroup = gui:Group("Control")

local fear = ccGroup:Tab("Fear")

fear:Text({ text = "Fear Settings", header = true })

fear:Checkbox({
    text = "Auto Fear DPS Targets",
    var = "warlock_fear_dps",
    default = true,
    tooltip = "Automatically Fear enemy DPS when safe to do so."
})

fear:Checkbox({
    text = "Fear CC Target (Healer)",
    var = "warlock_fear_cc_target",
    default = true,
    tooltip = "Use Fear on the CC target (usually healer)."
})

fear:Separator()

fear:Text({ text = "Howl of Terror", header = true })

fear:Checkbox({
    text = "Auto Howl of Terror",
    var = "warlock_howl_of_terror",
    default = true,
    tooltip = "Automatically use Howl of Terror when melee are in range."
})

fear:Slider({
    text = "Howl - Min Enemies in Range",
    var = "warlock_howl_min_enemies",
    min = 1,
    max = 3,
    default = 1,
    tooltip = "Minimum number of enemies in range to use Howl of Terror."
})

local stun = ccGroup:Tab("Stun")

stun:Text({ text = "Shadowfury", header = true })

stun:Checkbox({
    text = "Shadowfury on CC Target",
    var = "warlock_shadowfury_cc",
    default = true,
    tooltip = "Use Shadowfury to stun the CC target (healer) for control chains."
})

stun:Checkbox({
    text = "Shadowfury Peel (Self Defense)",
    var = "warlock_shadowfury_peel",
    default = true,
    tooltip = "Use Shadowfury to peel melee off yourself."
})

-- ============================================================
-- Defensive Tab
-- ============================================================
local defense = gui:Group("Defensive")

local survival = defense:Tab("Survival")

survival:Text({ text = "Health Thresholds", header = true })

survival:Slider({
    text = "Dark Regeneration HP",
    var = "warlock_dark_regen_hp",
    min = 0,
    max = 100,
    default = 50,
    valueType = "%",
    tooltip = "Use Dark Regeneration at this health percentage."
})

survival:Slider({
    text = "Healthstone HP",
    var = "warlock_healthstone_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Use Healthstone at this health percentage."
})

survival:Slider({
    text = "Unbound Will HP",
    var = "warlock_unbound_will_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Use Unbound Will to break CC at this health percentage."
})

survival:Separator()

survival:Text({ text = "Drain Life", header = true })

survival:Checkbox({
    text = "Auto Drain Life",
    var = "warlock_drain_life",
    default = true,
    tooltip = "Use Drain Life when low health and no better options."
})

survival:Slider({
    text = "Drain Life HP",
    var = "warlock_drain_life_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Start Drain Life at this health percentage."
})

-- ============================================================
-- Misc Tab
-- ============================================================
local misc = gui:Group("Misc")

local totems = misc:Tab("Totems")

totems:Text({ text = "Totem Stomping", header = true })

totems:Checkbox({
    text = "Stomp Totems",
    var = "misc_stomp_totems",
    default = true,
})

totems:Checkbox({
    text = "Stomp Totems in Battlegrounds",
    var = "misc_stomp_totems_bg",
    default = true,
})

totems:Slider({
    text = "Totem Stomp Uptime Delay",
    var = "misc_stomp_uptime_delay",
    min = 0.4,
    max = 1.6,
    step = 0.1,
    default = 0.6,
    tooltip = "Minimum time a totem must be up before stomping it.\nDefault: 0.6s"
})

local pet = misc:Tab("Pet")

pet:Text({ text = "Pet Management", header = true })

pet:Checkbox({
    text = "Auto Health Funnel",
    var = "warlock_health_funnel",
    default = true,
    tooltip = "Automatically heal your pet with Health Funnel."
})

pet:Slider({
    text = "Health Funnel Pet HP",
    var = "warlock_health_funnel_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Heal pet when it drops below this health percentage."
})
