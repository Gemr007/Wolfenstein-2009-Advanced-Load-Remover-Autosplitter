state("wolf2")
{
    string255 map : 0x952884, 0x4;
    bool loading : "gamex86.dll", 0x875C6C;
    bool playingMovie : "binkw32.dll", 0x25438;
    bool missionComplete : "gamex86.dll", 0x875E8C, 0x268;
    float X_cord : 0x715538;
    float Y_cord : 0x71553C;
    float Z_cord : 0x715540;
}

startup
{
    settings.Add("splits", true, "Using splits");
    settings.SetToolTip("splits", "Disable if you don't use splits and only want automatic start, stop and reset");

    settings.Add("splitHubs", true, "Split hub travel", "splits");
    settings.SetToolTip("splitHubs", "Disable if you only use splits when completing a level");

    settings.Add("midMapSplit", true, "Mid level splits", "splits");
    settings.SetToolTip("midMapSplit", "Disable if you don't have mid level splits. i.e. Castle -> Castle Top");

    settings.Add("info", false, "Informations");
    settings.Add("cords", false, "Show X Y Z coordinates", "info");

    
    vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
		var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
		var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
		if (textSetting == null)
		{
		var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
		var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
		timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

		textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
		textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
		}

		if (textSetting != null)
		textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
	});

    if (timer.CurrentTimingMethod == TimingMethod.RealTime) // stolen from dude simulator 3, basically asks the runner to set their livesplit to game time
        {        
        var timingMessage = MessageBox.Show (
               "This game uses Time without Loads (Game Time) as the main timing method.\n"+
                "LiveSplit is currently set to show Real Time (RTA).\n"+
                "Would you like to set the timing method to Game Time? This will make verification easier",
                "LiveSplit | Wolfenstein",
               MessageBoxButtons.YesNo,MessageBoxIcon.Question
            );
        
            if (timingMessage == DialogResult.Yes)
            {
                timer.CurrentTimingMethod = TimingMethod.GameTime;
            }
        }

}

update
{
    if (settings["cords"])
    {
        vars.SetTextComponent("X", (current.X_cord).ToString());
        vars.SetTextComponent("Y", (current.Y_cord).ToString());
        vars.SetTextComponent("Z", (current.Z_cord).ToString());
    }
}


init
{
    vars.startTime = 0;
    vars.menuName = "/game/menu/menu.mpk";
    vars.tavernName = "/game/tavern/tavern.mpk";
    vars.zeppelinName = "/game/zeppelin/zeppelin.mpk";
    vars.blackSunName = "/game/blacksun/blacksun.mpk";
    vars.hubMaps = new [] {"/game/mtw/mtw.mpk", "/game/mte/mte.mpk", "/game/downtown/downtown.mpk", "/game/downtown/downtown_west.mpk"};
}

start
{
    if (current.map == "/game/trainyard/trainyard.mpk" && current.playingMovie)
    {
        vars.startTime = 0;
        return true;
    }
}
/*
reset
{
    // don't reset during intro cutscene
    if (old.map == vars.menuName)
        return false;

    return current.map == vars.menuName;
}
*/
split
{
    // split when timing ends
    if (current.map == vars.blackSunName && current.missionComplete)
        return true;

    if (!settings["splits"])
        return false;

    // dossier split
    if (current.map == old.map)
        return current.missionComplete && !old.missionComplete;

    // don't split on tavern
    if (current.map == vars.tavernName || old.map == vars.tavernName)
        return false;

    // don't split on main menu
    if (current.map == vars.menuName || old.map == vars.menuName)
        return false;

    // zeppelin and blacksun are special since there's no hub between level ends
    if (current.map == vars.zeppelinName || current.map == vars.blackSunName)
        return false;

    bool enteringHub = false;
    bool leavingHub = false;
    foreach (string hubMap in vars.hubMaps)
    {
        if (!enteringHub && current.map == hubMap)
            enteringHub = true;

        if (!leavingHub && old.map == hubMap)
            leavingHub = true;
    }

    if (settings["splitHubs"] && leavingHub)
        return true;

    if (settings["midMapSplit"] && !(enteringHub || leavingHub))
        return true;
}

isLoading
{
    return current.loading || current.missionComplete || current.playingMovie;
}

exit
{
    timer.IsGameTimePaused = true;
}