#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Command Blocker",
	author = "pRED*",
	description = "Lets you block or ban commands",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_commandblocker_version", PLUGIN_VERSION, "Command Blocker Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegServerCmd("sm_blockcommand", Cmd_Block, "Adds the cheat flag to a command");
	RegServerCmd("sm_bancommand", Cmd_Ban, "Bans users that attempt to use this command");

	AutoExecConfig(true);
}

public Action Cmd_Block(int args)
{
	if (args < 1)
	{
		ReplyToCommand(0, "Usage: sm_blockcommand <command>");
		return Plugin_Handled;
	}
	
	char command[100];
	GetCmdArg(1, command, sizeof(command));
	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags|FCVAR_CHEAT);
	
	ReplyToCommand(0, "Command successfully blocked");
	
	return Plugin_Handled;
}

public Action Cmd_Ban(int args)
{
	if (args < 1)
	{
		ReplyToCommand(0, "Usage: sm_blockcommand <command>");
		return Plugin_Handled;
	}
	
	char command[100];
	GetCmdArg(1, command, sizeof(command));
	
	RegConsoleCmd(command, Cmd_Banned);
	
	ReplyToCommand(0, "Command successfully banned");
	
	return Plugin_Handled;
}

public Action Cmd_Banned(int client, int args)
{
	char command[100];
	GetCmdArg(0, command, sizeof(command));
	ServerCommand("sm_ban #%i 0 \"Attempting to use banned command: %s\"", GetClientUserId(client), command);
	return Plugin_Handled;
}
