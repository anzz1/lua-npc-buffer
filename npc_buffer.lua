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

-- TODO: a table of buffs for lvls <80 , buff target can be 10 lvl below the spell lvl

if (EnableModule ~= 1) then return end

require ("ObjectVariables")
local FILE_NAME = string.match(debug.getinfo(1,'S').source, "[^/\\]*.lua$")
local EMOTE_ONESHOT_FLEX = 23
local LANG_UNIVERSAL = 0

local function SetDefaultOrientationEvent(_, _, _, creature)
    local o = creature:GetData("o")
    if (not o) then
        PrintError("["..FILE_NAME.."] ERROR: No default orientation found.")
    else
        creature:SetFacing(o)
    end
end

local function triggerError(source,player)
    PrintError("["..FILE_NAME.."] ERROR: Could not spawn a trigger with ID "..TriggerEntry)
    if (source:GetTypeId() == 3) then
        source:SendUnitYell("OH NO!", LANG_UNIVERSAL)
    end
    player:SendBroadcastMessage("[|cff4CFF00BufferNPC|r]|cffff2020 Something went wrong.")
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

    local trigger1 = source:SpawnCreature(TriggerEntry, source:GetX(), source:GetY(), source:GetZ(), 0, 3, 1)
    if (not trigger1) then
        triggerError(source,player)
        return
    end
    source:CastCustomSpell(player, 48938, true, nil, nil, nil, nil, trigger1:GetGUID())  -- Greater Blessing of Wisdom (Rank 5)
    trigger1:DespawnOrUnsummon()
    
    local trigger2 = source:SpawnCreature(TriggerEntry, source:GetX(), source:GetY(), source:GetZ(), 0, 3, 1)
    if (not trigger2) then
        triggerError(source,player)
        return
    end
    source:CastCustomSpell(player, 48934, true, nil, nil, nil, nil, trigger2:GetGUID())  -- Greater Blessing of Might (Rank 5)
    trigger2:DespawnOrUnsummon()
    
    local trigger3 = source:SpawnCreature(TriggerEntry, source:GetX(), source:GetY(), source:GetZ(), 0, 3, 1)
    if (not trigger3) then
        triggerError(source,player)
        return
    end
    source:CastCustomSpell(player, 25899, true, nil, nil, nil, nil, trigger3:GetGUID())  -- Greater Blessing of Sanctuary
    trigger3:DespawnOrUnsummon()

    source:CastSpell(player, 25898, true)       -- Greater Blessing of Kings  
    source:CastSpell(player, 42995, true)       -- Arcane Intellect (Rank 7)
    source:CastSpell(player, 48469, true)       -- Mark of the Wild (Rank 9)
    source:CastSpell(player, 48169, true)       -- Shadow Protection (Rank 5)
    source:CastSpell(player, 48161, true)       -- Power Word: Fortitude (Rank 8)
    source:CastSpell(player, 48073, true)       -- Divine Spirit (Rank 6)
    
    if (not isCommand) then
        source:CastSpell(player, 48443, true)       -- Regrowth (Rank 12)
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
