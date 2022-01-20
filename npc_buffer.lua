------------------------------------------------------------------------------------------------
-- BUFFER NPC
------------------------------------------------------------------------------------------------

local EnableModule = 1
local AnnounceModule = 1      -- Announce module on player login ?
local UnitEntry = 601016      -- NPC ID
local TriggerEntry = 601017   -- Trigger NPC ID
local BuffCureRes = 1         -- Cure Resurrection Sickness
local BuffCommand = 2         -- .buff and .buff target commands - 0:disable 1:enable 2:gm only

-----------------------------------------------------------------------------------------------
-- END CONFIG
------------------------------------------------------------------------------------------------

if (EnableModule ~= 1) then return end

require ("ObjectVariables")
local FILE_NAME = string.match(debug.getinfo(1,'S').source, "[^/\\]*.lua$")
local EMOTE_ONESHOT_FLEX = 23
local LANG_UNIVERSAL = 0
local CLASS_HUNTER = 3
local CLASS_MAGE = 8
local CLASS_WARLOCK = 9

-- id.minlevel.spellid.isgrpspell
local BUFFS = {
    [1] = {
        [1] = {1459, false},    -- Arcane Intellect (Rank 1)
        [4] = {1460, false},    -- Arcane Intellect (Rank 2)
        [18] = {1461, false},   -- Arcane Intellect (Rank 3)
        [32] = {10156, false},  -- Arcane Intellect (Rank 4)
        [46] = {23028, true},   -- Arcane Brilliance (Rank 1)
        [60] = {27127, true},   -- Arcane Brilliance (Rank 2)
        [70] = {43002, true},   -- Arcane Brilliance (Rank 3)
    },
    [2] = {
        [1] = {5232, false},    -- Mark of the Wild (Rank 2)
        [10] = {6756, false},   -- Mark of the Wild (Rank 3)
        [20] = {5234, false},   -- Mark of the Wild (Rank 4)
        [30] = {8907, false},   -- Mark of the Wild (Rank 5)
        [40] = {21849, true},   -- Gift of the Wild (Rank 1)
        [50] = {21850, true},   -- Gift of the Wild (Rank 2)
        [60] = {26991, true},   -- Gift of the Wild (Rank 3)
        [70] = {48470, true},   -- Gift of the Wild (Rank 4)
    },
    [3] = {
        [20] = {976, false},    -- Shadow Protection (Rank 1)
        [32] = {10957, false},  -- Shadow Protection (Rank 2)
        [46] = {27683, true},   -- Prayer of Shadow Protection (Rank 1)
        [58] = {39374, true},   -- Prayer of Shadow Protection (Rank 2)
        [66] = {48170, true},   -- Prayer of Shadow Protection (Rank 3)
    },
    [4] = {
        [1] = {1243, false},    -- Power Word: Fortitude (Rank 1)
        [2] = {1244, false},    -- Power Word: Fortitude (Rank 2)
        [14] = {1245, false},   -- Power Word: Fortitude (Rank 3)
        [26] = {2791, false},   -- Power Word: Fortitude (Rank 4)
        [38] = {21562, true},   -- Prayer of Fortitude (Rank 1)
        [50] = {21564, true},   -- Prayer of Fortitude (Rank 2)
        [60] = {25392, true},   -- Prayer of Fortitude (Rank 3)
        [70] = {48162, true},   -- Prayer of Fortitude (Rank 4)
    },
    [5] = {
        [20] = {14752, false},  -- Divine Spirit (Rank 1)
        [30] = {14818, false},  -- Divine Spirit (Rank 2)
        [40] = {14819, false},  -- Divine Spirit (Rank 3)
        [50] = {27681, true},   -- Prayer of Spirit (Rank 1)
        [60] = {32999, true},   -- Prayer of Spirit (Rank 2)
        [70] = {48074, true},   -- Prayer of Spirit (Rank 3)
    },
}

-- id.minlevel.spellid
local PALADIN_BUFFS = {
    [1] = {
        [4] = {19742, false},   -- Blessing of Wisdom (Rank 1)
        [14] = {19850, false},  -- Blessing of Wisdom (Rank 2)
        [24] = {19852, false},  -- Blessing of Wisdom (Rank 3)
        [34] = {19853, false},  -- Blessing of Wisdom (Rank 4)
        [44] = {25894, true},  -- Greater Blessing of Wisdom (Rank 1)
        [50] = {25918, true},   -- Greater Blessing of Wisdom (Rank 2)
        [55] = {27143, true},   -- Greater Blessing of Wisdom (Rank 3)
        [61] = {48937, true},   -- Greater Blessing of Wisdom (Rank 4)
        [67] = {48938, true},   -- Greater Blessing of Wisdom (Rank 5)
    },
    [2] = {
        [1] = {19740, false},   -- Blessing of Might (Rank 1)
        [2] = {19834, false},   -- Blessing of Might (Rank 2)
        [12] = {19835, false},  -- Blessing of Might (Rank 3)
        [22] = {19836, false},  -- Blessing of Might (Rank 4)
        [32] = {19837, true},  -- Greater Blessing of Might (Rank 1)
        [42] = {25782, true},   -- Greater Blessing of Might (Rank 2)
        [50] = {25916, true},   -- Greater Blessing of Might (Rank 3)
        [60] = {27141, true},   -- Greater Blessing of Might (Rank 4)
        [63] = {48933, true},   -- Greater Blessing of Might (Rank 5)
        [69] = {48934, true},   -- Greater Blessing of Might (Rank 5)
    },
    [3] = {
        [10] = {20217, false},  -- Blessing of Kings
        [50] = {25898, true},   -- Greater Blessing of Kings
    },
    [4] = {
        [20] = {20911, false},  -- Blessing of Sanctuary
        [50] = {25899, true},   -- Greater Blessing of Sanctuary
    },
}

local function getBestSpells(tbl, lvl)
    local h1, h2 = 0,0
    local s1, s2
    for k,v in pairs(tbl) do
        if (lvl >= k) then
            if (v[2]) then
                if (k > h2) then
                    h2 = k
                    s2 = v[1]
                end
            else
                if (k > h1) then
                    h1 = k
                    s1 = v[1]
                end
            end
        end
    end
    return s1,s2
end

local function getPet(player)
    local petguid = player:GetPetGUID()
    if (petguid) then
        local wo_tbl = player:GetNearObjects(40, 8, 0, 2, 0) -- RANGE:40, TYPEMASK_UNIT:8, FRIENDLY:2
        for _,obj in ipairs(wo_tbl) do
            if (obj:GetGUID() == petguid) then
                return obj:ToUnit()
            end
        end
    end
    return nil
end

local function SetDefaultOrientationEvent(_, _, _, creature)
    local o = creature:GetData("o")
    if (not o) then
        PrintError("["..FILE_NAME.."] ERROR: No default orientation found.")
    else
        creature:SetFacing(o)
    end
end

local function triggerError(source,unit)
    PrintError("["..FILE_NAME.."] ERROR: Could not spawn a trigger with ID "..TriggerEntry)
    if (source:GetTypeId() == 3) then
        source:SendUnitYell("OH NO!", LANG_UNIVERSAL)
    end
    if (unit:GetTypeId() == 4) then
        unit:SendBroadcastMessage("[|cff4CFF00BufferNPC|r]|cffff2020 Something went wrong.")
    end
end

local function buffUnit(source, unit)
    local level = unit:GetLevel()

    for i = 1, 3 do
        local trigger = source:SpawnCreature(TriggerEntry, source:GetX(), source:GetY(), source:GetZ(), 0, 3, 1)
        if (not trigger) then
            triggerError(source,unit)
            return
        end
        local s1, s2 = getBestSpells(PALADIN_BUFFS[i], level)
        if (s1) then
            source:CastCustomSpell(unit, s1, true, nil, nil, nil, nil, trigger:GetGUID())
        end
        if (s2) then
            trigger:AddAura(s2, unit)
        end
        trigger:DespawnOrUnsummon()
    end

    do
        local s1, s2 = getBestSpells(PALADIN_BUFFS[4], level)
        if (s1) then
            source:CastSpell(unit, s1, true)
        end
        if (s2) then
            source:AddAura(s2, unit)
        end
    end

    for _, v in ipairs(BUFFS) do
        local s1, s2 = getBestSpells(v, level)
        if (s1) then
            source:CastSpell(unit, s1, true)
        end
        if (s2) then
            source:AddAura(s2, unit)
        end
    end
end

local function doBuff(source, player)
    local isCommand = (source:GetTypeId() == 4)
    
    local timestamp = player:GetData("_npc_buffer_cd")
    if (timestamp and GetTimeDiff(timestamp) < 1000) then
        if (isCommand) then
            player:SendBroadcastMessage("[|cff4CFF00BufferNPC|r] Cooldown 1 seconds ...")
        end
        return
    end
    player:SetData("_npc_buffer_cd", GetCurrTime())

    if (BuffCureRes==1 and player:HasAura(15007)) then
        player:RemoveAura(15007)
        if (not isCommand) then
            source:SendUnitWhisper(string.format("The aura of death has been lifted from you %s. Watch yourself out there!", player:GetName()), LANG_UNIVERSAL, player)
        end
    end

    buffUnit(source,player)

    local class = player:GetClass()
    if (class == CLASS_HUNTER or class == CLASS_MAGE or class == CLASS_WARLOCK) then
        local pet = getPet(player)
        if (pet) then
            buffUnit(source,pet)
            if (not isCommand) then
                source:CastSpell(player, 48443, true)  -- Regrowth (Rank 12)
                source:CastSpell(player, 48441, true)  -- Rejuvenation (Rank 15)
            end
        end
    end

    if (not isCommand) then
        source:CastSpell(player, 48443, true)  -- Regrowth (Rank 12)
        source:CastSpell(player, 48441, true)  -- Rejuvenation (Rank 15)
    end
end

local function OnGossipHello(event, player, creature)
    local level = player:GetLevel()
    local o = creature:GetData("o")
    if (not o) then
        creature:SetData("o", creature:GetO())
    end
    creature:RemoveEvents()
    creature:RegisterEvent(SetDefaultOrientationEvent, 5000)
    
    creature:SetFacingToObject(player)
    
    doBuff(creature, player)

    --creature:PerformEmote(EMOTE_ONESHOT_FLEX)

    return true
end

local function buffCmd(event, player, cmd)
    local _cmd = cmd:lower()
    if (_cmd == "buff") then
        if (BuffCommand == 1 or player:GetGMRank() >= 1) then
            doBuff(player,player)
        end
        return false
    elseif (_cmd == "buff target") then
        if (BuffCommand == 1 or player:GetGMRank() >= 1) then
            local target = player:GetSelection()
            if (target and target:GetTypeId() == 4) then
                doBuff(player,target)
            else
                player:SendBroadcastMessage("[|cff4CFF00BufferNPC|r] Invalid target.")
            end
        end
        return false
    elseif (_cmd == "buff group" or _cmd == "buff grp") then
        if (BuffCommand == 1 or player:GetGMRank() >= 1) then
            local grp = player:GetGroup()
            if (grp) then
                for _, p in ipairs(grp:GetMembers()) do
                    doBuff(player,p)
                end
            else
                doBuff(player,player)
            end
        end
        return false
    end
end

local function moduleAnnounce(event, player)
    player:SendBroadcastMessage("This server is running the |cff4CFF00BufferNPC|r module.")
end

RegisterCreatureGossipEvent(UnitEntry, 1, OnGossipHello) -- GOSSIP_EVENT_ON_HELLO

if (AnnounceModule==1) then
    RegisterPlayerEvent(3, moduleAnnounce)   -- PLAYER_EVENT_ON_LOGIN
end
if (BuffCommand == 1 or BuffCommand == 2) then
    RegisterPlayerEvent(42, buffCmd)
end

PrintInfo("["..FILE_NAME.."] BufferNPC module loaded. NPC ID: "..UnitEntry)
