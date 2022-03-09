#pragma semicolon 1
#pragma newdecls required

#define CMD_MAX_LEN	255

#include <sourcemod>
#include <CCommandBlocker>

ConVar g_cv_BanLength = null;

ArrayList g_aCommands = null;

public Plugin myinfo =
{
	name = "Command Blocker",
	author = "pRED*, maxime1907",
	description = "Lets you block or ban commands",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	g_cv_BanLength = CreateConVar("sm_commandblocker_ban_length", "5", "Length of the ban in minutes", FCVAR_NOTIFY, true, 0.0, true, 518400.0);

	RegAdminCmd("sm_commandblocker_reloadcfg", Command_ReloadConfig, ADMFLAG_GENERIC, "Reload blocked commands configs");

	RegAdminCmd("sm_commandblocker_block", Command_Block, ADMFLAG_ROOT, "Block users that attempt to use this command");
	RegAdminCmd("sm_commandblocker_kick", Command_Kick, ADMFLAG_ROOT, "Kick users that attempt to use this command");
	RegAdminCmd("sm_commandblocker_ban", Command_Ban, ADMFLAG_ROOT, "Ban users that attempt to use this command");

	AutoExecConfig(true);
}

public void OnPluginEnd()
{
	Cleanup();
}

public void OnConfigsExecuted()
{
	LoadConfig("configs/commandblocker.cfg");
	ParseCommands();
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

	RegisterCommandBlock(sCommand, eBlockType_Block);

	ReplyToCommand(client, "[SM] Block command successfully registered");

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

	RegisterCommandBlock(sCommand, eBlockType_Kick);

	ReplyToCommand(client, "[SM] Kick command successfully registered");

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

	RegisterCommandBlock(sCommand, eBlockType_Ban);

	ReplyToCommand(client, "[SM] Ban command successfully registered");

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

stock void ParseCommands()
{
	for (int i = 0; i < g_aCommands.Length; i++)
	{
		CCommandBlocker commandBlocker = g_aCommands.Get(i);

		char sCommand[CMD_MAX_LEN];
		commandBlocker.GetCommand(sCommand, sizeof(sCommand));

		RegisterCommandBlock(sCommand, view_as<eBlockType>(commandBlocker.iBlockType));
		LogMessage("Command \"%s\" successfully registered with blocktype %d", sCommand, commandBlocker.iBlockType);
	}
}

stock void RegisterCommandBlock(const char[] sCommand, const eBlockType blockType)
{
	switch (blockType)
	{
		case (eBlockType_Block):
		{
			RegConsoleCmd(sCommand, Command_Blocked);
		}
		case (eBlockType_Kick):
		{
			RegConsoleCmd(sCommand, Command_Kicked);
		}
		case (eBlockType_Ban):
		{
			RegConsoleCmd(sCommand, Command_Banned);
		}
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
		CCommandBlocker	commandBlocker = new CCommandBlocker();

		char sCommand[CMD_MAX_LEN];
		commandBlocker.GetCommand(sCommand, sizeof(sCommand));

		kvConfig.GetString("command", sCommand, sizeof(sCommand), "");
		commandBlocker.SetCommand(sCommand);

		commandBlocker.iBlockType = view_as<eBlockType>(kvConfig.GetNum("blocktype", eBlockType_Block));

		if (sCommand[0] != '\0')
			g_aCommands.Push(commandBlocker);
	}
	while(kvConfig.GotoNextKey(false));

	delete kvConfig;
}

public Action Command_Blocked(int client, int args)
{
	char sCommand[CMD_MAX_LEN];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	LogMessage("%L attempted to use banned command: %s", client, sCommand);
	return Plugin_Handled;
}

public Action Command_Kicked(int client, int args)
{
	char sCommand[CMD_MAX_LEN];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	ServerCommand("sm_kick #%i \"Attempting to use banned command: %s\"", GetClientUserId(client), sCommand);
	return Plugin_Handled;
}

public Action Command_Banned(int client, int args)
{
	char sCommand[CMD_MAX_LEN];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	ServerCommand("sm_ban #%i %d \"Attempting to use banned command: %s\"", GetClientUserId(client), g_cv_BanLength.IntValue, sCommand);
	return Plugin_Handled;
}
