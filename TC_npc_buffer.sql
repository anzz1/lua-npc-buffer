-- --------------------------------------------------------------------------------------
--    BUFFER NPC - 601016
-- --------------------------------------------------------------------------------------
SET
@Entry           := 601016,
@TriggerEntry    := 601017,
-- Alliance Version
-- @Model        := 4309, -- Human Male Tuxedo
-- @Name         := "Bruce Buffer",
-- @Title        := "Ph.D.",
-- Horde Version
@Model           := 14612, -- Tauren Warmaster
@Name            := "Buffmaster Hasselhoof",
@Title           := "",
@Icon            := "Speak",
@GossipMenu      := 0,
@MinLevel        := 80,
@MaxLevel        := 80,
@Faction         := 35,
@NPCFlag         := 1,
@Scale           := 1.0,
@Rank            := 0,
@Type            := 7,
@TypeFlags       := 0,
@FlagsExtra      := 2,
@AIName          := "PassiveAI",
@HealthMod       := 4,
@Script          := "";

-- NPC
DELETE FROM world.creature_template WHERE entry = @Entry;
INSERT INTO world.creature_template (entry, modelid1, name, subname, IconName, gossip_menu_id, minlevel, maxlevel, faction, npcflag, scale, rank, unit_class, unit_flags, unit_flags2, type, type_flags, flags_extra, AiName, MovementType, HealthModifier, ScriptName) VALUES
(@Entry, @Model, @Name, @Title, @Icon, @GossipMenu, @MinLevel, @MaxLevel, @Faction, @NPCFlag, @Scale, @Rank, 1, 768, 2048, @Type, @TypeFlags, @FlagsExtra, @AIName, 0, @HealthMod, @Script);

-- NPC EQUIPPED
DELETE FROM world.creature_equip_template WHERE CreatureID=@Entry AND ID=1;
INSERT INTO world.creature_equip_template (CreatureID, ID, ItemID1, ItemID2, ItemID3) VALUES (@Entry, 1, 1906, 14824, 0); -- War Axe(14824), Torch (1906)

-- TRIGGER NPC
DELETE FROM world.creature_template WHERE entry = @TriggerEntry;
INSERT INTO world.creature_template (entry, modelid1, modelid2, name, subname, IconName, gossip_menu_id, minlevel, maxlevel, faction, npcflag, scale, rank, unit_class, unit_flags, unit_flags2, type, type_flags, flags_extra, AiName, MovementType, ScriptName) VALUES
(@TriggerEntry, 169, 16925, "BufferNPC Trigger", "", "", 0, 60, 60, 35, 0, 1, 0, 1, 33555200, 2048, 10, 0, 192, "", 0, "");
