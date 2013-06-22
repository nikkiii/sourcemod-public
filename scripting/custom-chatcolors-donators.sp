#pragma semicolon 1

#include <sourcemod>
#include <donator>
#include <ccc>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name = "[CCC] Donator Tags",
	author = "Nikki",
	description = "Adds Donator Tags to Custom Chat Colors via Simple Donator Interface",
	version = PLUGIN_VERSION
};

new Handle:g_hCvarTag;
new Handle:g_hCvarTagColor;
new Handle:g_hCvarNameColor;
new Handle:g_hCvarChatColor;

new g_aPlayerHasTag[MAXPLAYERS + 1] = {false, ...};

new String:g_sTag[32];

new g_iTagColor = COLOR_GREEN;
new bool:g_bTagColorAlpha = false;

new g_iNameColor = COLOR_TEAM;
new bool:g_bNameColorAlpha = false;

new g_iTextColor = COLOR_NONE;
new bool:g_bTextColorAlpha = false;

new bool:g_bLateLoad = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	g_bLateLoad = late;
}

public OnPluginStart() {
	new Handle:version = CreateConVar("sm_donator_tagversion", PLUGIN_VERSION, "Custom Chat Colors - Donator tags", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	SetConVarString(version, PLUGIN_VERSION);
	
	g_hCvarTag = CreateConVar("sm_donator_tag", "[Donator]", "Donator tag (Space automatically appended to end)");
	g_hCvarTagColor = CreateConVar("sm_donator_tagcolor", "-2", "Donator tag color - None: -1, Green: -2, Olive: -3, Team: -4");
	g_hCvarNameColor = CreateConVar("sm_donator_namecolor", "-4", "Donator name color - None: -1, Green: -2, Olive: -3, Team: -4");
	g_hCvarChatColor = CreateConVar("sm_donator_chatcolor", "-1", "Donator chat color - None: -1, Green: -2, Olive: -3, Team: -4");
	
	HookConVarChange(g_hCvarTag, CvarChanged);
	HookConVarChange(g_hCvarTagColor, CvarChanged);
	HookConVarChange(g_hCvarNameColor, CvarChanged);
	HookConVarChange(g_hCvarChatColor, CvarChanged);
	
	AutoExecConfig(true, "ccc-donators");
	
	RefreshTagInfo();
	
	if(g_bLateLoad) {
		RefreshAllPlayers();
	}
}

public OnPluginEnd() {
	// Reset all tags before we close
	for(new i = 1; i < MaxClients; i++) {
		if(g_aPlayerHasTag[i]) {
			if(IsClientConnected(i) && IsClientInGame(i)) {
				CCC_ResetTag(i);
				CCC_ResetColor(i, CCC_TagColor);
				CCC_ResetColor(i, CCC_NameColor);
				CCC_ResetColor(i, CCC_ChatColor);
			}
		}
	}
}

public OnAllPluginsLoaded() {
	if(!LibraryExists("ccc")) {
		SetFailState("Custom Chat Colors is not installed. Please visit https://forums.alliedmods.net/showthread.php?t=186695 and install it.");
	}
}

public OnDonatorsChanged() {
	RefreshAllPlayers();
}

public OnClientDisconnect(client) {
	g_aPlayerHasTag[client] = false;
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_hCvarTag)
		RefreshTag();
	else if(convar == g_hCvarTagColor)
		RefreshTagColor();
	else if(convar == g_hCvarNameColor)
		RefreshNameColor();
	else if(convar == g_hCvarChatColor)
		RefreshChatColor();
}

public Action:CCC_OnUserConfigPreLoaded(client) {
	CreateTimer(1.0, Timer_CheckDonatorStatus, GetClientUserId(client));
	return Plugin_Continue;
}

public Action:Timer_CheckDonatorStatus(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);
	if(client < 1 || client > MaxClients || !IsClientInGame(client)) {
		return;
	}
	CheckTag(client);
}

RefreshAllPlayers() {
	for(new i = 1; i < MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i)) {
			CheckTag(i);
		}
	}
}

CheckTag(client) {
	// Ignore if they aren't a donator
	if(!IsPlayerDonator(client)) {
		return;
	}
	
	// Get current information to make sure we aren't overwriting another tag, this is called once per client in case we reload custom-chatcolors
	if(!g_aPlayerHasTag[client]) {
		decl String:tag[10];
		CCC_GetTag(client, tag, sizeof(tag));
		if(strlen(tag) > 0) {
			return;
		}
		
		// Check if they already have a color
		if(!IsDefaultColor(client, CCC_TagColor) || !IsDefaultColor(client, CCC_NameColor) || !IsDefaultColor(client, CCC_ChatColor)) {
			return;
		}
	}
	
	// Set custom colors
	CCC_SetTag(client, g_sTag);
	
	if(g_iTagColor != COLOR_NONE)
		CCC_SetColor(client, CCC_TagColor, g_iTagColor, g_bTagColorAlpha);
	
	if(g_iNameColor != COLOR_TEAM)
		CCC_SetColor(client, CCC_NameColor, g_iNameColor, g_bNameColorAlpha);
		
	if(g_iTextColor != COLOR_NONE)
		CCC_SetColor(client, CCC_ChatColor, g_iTextColor, g_bTextColorAlpha);
	
	g_aPlayerHasTag[client] = true;
}

IsDefaultColor(client, CCC_ColorType:type) {
	new iColor = CCC_GetColor(client, type);
	switch(type) {
		case CCC_TagColor: {
			return iColor == COLOR_NONE;
		}
		case CCC_NameColor: {
			return iColor == COLOR_TEAM;
		}
		case CCC_ChatColor: {
			return iColor == COLOR_NONE;
		}
	}
	return true;
}

RefreshTagInfo() {
	RefreshTag();
	RefreshTagColor();
	RefreshNameColor();
	RefreshChatColor();
}

RefreshTag() {
	GetConVarString(g_hCvarTag, g_sTag, sizeof(g_sTag));
	StrCat(g_sTag, sizeof(g_sTag), " ");
}

RefreshTagColor() {
	decl String:sTagColor[16];
	GetConVarString(g_hCvarTagColor, sTagColor, sizeof(sTagColor));
	
	ParseColor(sTagColor, g_iTagColor, g_bTagColorAlpha);
}

RefreshNameColor() {
	decl String:sNameColor[16];
	GetConVarString(g_hCvarNameColor, sNameColor, sizeof(sNameColor));
	
	ParseColor(sNameColor, g_iNameColor, g_bNameColorAlpha);
}

RefreshChatColor() {
	decl String:sChatColor[16];
	GetConVarString(g_hCvarChatColor, sChatColor, sizeof(sChatColor));
	
	ParseColor(sChatColor, g_iTextColor, g_bTextColorAlpha);
}

ParseColor(const String:color[], &iTagColor, &bool:bTagColorAlpha) {
	new colorLen = strlen(color);

	bTagColorAlpha = strlen(color) == 8;
	if(StrEqual(color, "G") || StrEqual(color, "O") || StrEqual(color, "T")) {
		switch(color[0]) {
			case 'G': {
				iTagColor = COLOR_GREEN;
			}
			case 'O': {
				iTagColor = COLOR_OLIVE;
			}
			case 'T': {
				iTagColor = COLOR_TEAM;
			}
			default: {
				iTagColor = COLOR_NONE;
			}
		}
	} else if(colorLen == 6 || colorLen == 8) {
		iTagColor = StringToInt(color, 16);
	}
}