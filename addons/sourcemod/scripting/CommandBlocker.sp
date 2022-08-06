#pragma semicolon 1
#pragma newdecls required

#define CMD_MAX_LEN	255

#include <sourcemod>
#include <CCommandBlocker>

ConVar g_cv_BanLength = null;
ConVar g_cv_BlockLog = null;
ConVar g_cv_Reason;

ArrayList g_aCommands = null;


public Plugin myinfo =
{
	name = "Command Blocker",
	author = "pRED*, maxime1907",
	description = "Lets you block or ban commands",
	version = "1.3",
	url = ""
};

public void OnPluginStart()
{
	g_cv_BanLength = CreateConVar("sm_commandblocker_ban_length", "5", "Length of the ban in minutes", FCVAR_NOTIFY, true, 0.0, true, 518400.0);
	g_cv_BlockLog = CreateConVar("sm_commandblocker_block_log", "1", "Log blocked command attempts", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cv_Reason = CreateConVar("sm_commandblocker_ban_reason_hidden", "0", "Replace the command used by his index [0 = No | 1 = Yes]", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegAdminCmd("sm_commandblocker_reloadcfg", Command_ReloadConfig, ADMFLAG_GENERIC, "Reload blocked commands configs");

	RegAdminCmd("sm_commandblocker_block", Command_Block, ADMFLAG_ROOT, "Block users that attempt to use this command");
	RegAdminCmd("sm_commandblocker_kick", Command_Kick, ADMFLAG_ROOT, "Kick users that attempt to use this command");
	RegAdminCmd("sm_commandblocker_ban", Command_Ban, ADMFLAG_ROOT, "Ban users that attempt to use this command");

	AddCommandListener(Command_OnAny, "");

	AutoExecConfig(true);
}

public void OnPluginEnd()
{
	Cleanup();
}

public void OnConfigsExecuted()
{
	LoadConfig("configs/commandblocker.cfg");
}

public Action Command_OnAny(int client, const char[] command, int argc)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	char sCommand[CMD_MAX_LEN];
	GetCmdArg(0, sCommand, sizeof(sCommand));

	for (int i = 0; i < g_aCommands.Length; i++)
	{
		CCommandBlocker commandBlocker = g_aCommands.Get(i);
		char sCommandBlocked[CMD_MAX_LEN];
		commandBlocker.GetCommand(sCommandBlocked, sizeof(sCommandBlocked));

		if (StrEqual(sCommand, sCommandBlocked))
		{
			return ExecuteCommandBlock(client, sCommandBlocked, view_as<eBlockType>(commandBlocker.iBlockType));
		}
	}

	return Plugin_Continue;
}

public Action Command_ReloadConfig(int client, int argc)
{
	OnConfigsExecuted();

	ReplyToCommand(client, "[SM] CommandBlocker configs reloaded.");
	return Plugin_Handled;
}

public Action Command_Block(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_commandblocker_block <command>");
		return Plugin_Handled;
	}

	char sCommand[CMD_MAX_LEN];
	GetCmdArg(1, sCommand, sizeof(sCommand));

	AddCommandBlock(sCommand, eBlockType_Block);

	ReplyToCommand(client, "[SM] Block command successfully added");

	return Plugin_Handled;
}

public Action Command_Kick(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_commandblocker_kick <command>");
		return Plugin_Handled;
	}

	char sCommand[CMD_MAX_LEN];
	GetCmdArg(1, sCommand, sizeof(sCommand));

	AddCommandBlock(sCommand, eBlockType_Kick);

	ReplyToCommand(client, "[SM] Kick command successfully added");

	return Plugin_Handled;
}

public Action Command_Ban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_commandblocker_ban <command>");
		return Plugin_Handled;
	}

	char sCommand[CMD_MAX_LEN];
	GetCmdArg(1, sCommand, sizeof(sCommand));

	AddCommandBlock(sCommand, eBlockType_Ban);

	ReplyToCommand(client, "[SM] Ban command successfully added");

	return Plugin_Handled;
}

stock void Cleanup()
{
	if (g_aCommands != null)
	{
		for (int i = 0; i < g_aCommands.Length; i++)
		{
			CCommandBlocker commandBlocker = g_aCommands.Get(i);
			delete commandBlocker;
		}
		delete g_aCommands;
		g_aCommands = null;
	}
}

stock void LoadConfig(const char[] sConfigFilePath)
{
	Cleanup();

	g_aCommands = new ArrayList();

	char sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "%s", sConfigFilePath);

	if (!FileExists(sConfigFile))
	{
		LogError("Missing config file %s", sConfigFile);
		return;
	}

	KeyValues kvConfig = new KeyValues("CommandBlocker");

	if (!kvConfig.ImportFromFile(sConfigFile))
	{
		delete kvConfig;
		return;
	}
	kvConfig.Rewind();

	if (!kvConfig.GotoFirstSubKey(false))
	{
		delete kvConfig;
		return;
	}

	do
	{
		char sCommand[CMD_MAX_LEN];
		kvConfig.GetString("command", sCommand, sizeof(sCommand), "");

		eBlockType blockType = view_as<eBlockType>(kvConfig.GetNum("blocktype", eBlockType_Block));

		AddCommandBlock(sCommand, blockType);

		LogMessage("Command \"%s\" successfully added with blocktype %d", sCommand, blockType);
	}
	while(kvConfig.GotoNextKey(false));

	delete kvConfig;
}

stock Action ExecuteCommandBlock(int client, const char[] sCommand, const eBlockType blockType)
{
	char sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "%s", "configs/commandblocker.cfg");
	
	KeyValues kvConfig = new KeyValues("CommandBlocker");
	kvConfig.ImportFromFile(sConfigFile);
	
	char sCommandIndexNum[32];
	
	if(!kvConfig.GotoFirstSubKey())
		return Plugin_Handled;
		
	else
	{
		do
		{
			char sCommandIndex[32], sCommandName[64];
			kvConfig.GetSectionName(sCommandIndex, 32);
			kvConfig.GetString("command", sCommandName, 64);
			
			if(StrEqual(sCommand, sCommandName, false))
				Format(sCommandIndexNum, 32, "%s", sCommandIndex);
		}
		while(kvConfig.GotoNextKey());
	}
	
	delete kvConfig;
	
	switch (blockType)
	{
		case (eBlockType_Block):
		{
			if (g_cv_BlockLog.BoolValue)
				LogAction(-1, -1, "%L attempted to use banned command: %s", client, sCommand);
		}
		case (eBlockType_Kick):
		{
			if (g_cv_BlockLog.BoolValue)
				LogAction(-1, -1, "%L was kicked for attempted to use banned command: %s", client, sCommand);
			if (g_cv_Reason.IntValue != 1)
				ServerCommand("sm_kick #%i \"Attempting to use banned command: %s\"", GetClientUserId(client), sCommand);
			else
				ServerCommand("sm_kick #%i \"Attempting to use banned command: #%s\"", GetClientUserId(client), sCommandIndexNum);
		}
		case (eBlockType_Ban):
		{
			if (g_cv_BlockLog.BoolValue)
				LogAction(-1, -1, "%L was banned %d minutes for attempted to use banned command: %s", client, g_cv_BanLength.IntValue, sCommand);
			if (g_cv_Reason.IntValue != 1)
				ServerCommand("sm_ban #%i %d \"Attempting to use banned command: %s\"", GetClientUserId(client), g_cv_BanLength.IntValue, sCommand);
			else
				ServerCommand("sm_ban #%i %d \"Attempting to use banned command: #%s\"", GetClientUserId(client), g_cv_BanLength.IntValue, sCommandIndexNum);
		}
	}
	return Plugin_Handled;
}

stock void AddCommandBlock(const char[] sCommand, const eBlockType blockType)
{
	if (sCommand[0] == '\0')
		return;

	if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)
	{
		RegConsoleCmd(sCommand, Command_Dummy);
	}

	CCommandBlocker commandBlocker = new CCommandBlocker();
	commandBlocker.SetCommand(sCommand);
	commandBlocker.iBlockType = blockType;
	g_aCommands.Push(commandBlocker);
}

public Action Command_Dummy(int client, int args)
{
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}