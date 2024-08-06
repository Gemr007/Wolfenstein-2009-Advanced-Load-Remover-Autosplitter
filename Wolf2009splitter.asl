/*
Autosplitter & Load remover for Wolfenstein(2009)
By: M_E_T_A_L_I_S_T___S_P_1_D
Version: 2.0
Functions: 
1.Auto Start
2.Auto Split
3.Auto Reset
4.Load Remover (removes loadings, cutscenes, mission completed screen time, time in Journal)
*/
state("wolf2")
{
    int loading : "gamex86.dll", 0x875C6C;            //1 when loading, 0 when gameplay
    int inCutsceneState : "binkw32.dll", 0x25438;     //1 when Playing Movie, 0 when gameplay
    int inMissionCompletedScreen : "gamex86.dll", 0x875E8C, 0x268;  //1 when mission completed screen, 0 when gameplay
    string34 CutsceneName : 0x950E7C;
    string255 LevelName : 0x952884, 0x4;
    float IGT : 0x956154;
    int Gold : "gamex86.dll", 0x8B024C;
    int Intel : "gamex86.dll", 0x8B154C;
    int money : "gamex86.dll", 0x739EA4;
    int Tomes : "gamex86.dll", 0x8B284C;
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
    settings.Add("gold", false, "Show Number of Collected Gold", "info");
    settings.Add("intel", false, "Show Number of Collected Intel", "info");
    settings.Add("ToP", false, "Show Number of Collected Tomes of Power", "info");
    settings.Add("igt", false, "Show IGT", "info");
    settings.Add("money", false, "Show Money", "info");
    settings.Add("debug", false, "Debug", "info");
    settings.SetToolTip("debug", "It shows current map name and current loading value");


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
    if (settings["intel"])
    {
        vars.SetTextComponent("Collected Intel :", (current.Intel).ToString());
    }

    if (settings["gold"])
    {
        vars.SetTextComponent("Collected Gold :", (current.Gold).ToString());
    }

    if (settings["ToP"])
    {
        vars.SetTextComponent("Collected Tomes :", (current.Tomes).ToString());
    }

    if (settings["igt"])
    {
        vars.SetTextComponent("IGT :", (TimeSpan.FromSeconds(current.IGT)).ToString());
    }

    if (settings["money"])
    {
        vars.SetTextComponent("Money :", (current.money).ToString());
    }

    if (settings["debug"])
    {
        vars.SetTextComponent("Map :", (current.LevelName).ToString());
        vars.SetTextComponent("Loading :", (current.loading).ToString());
        vars.SetTextComponent("Mission Completed? (1=yes 0=no)", (current.inMissionCompletedScreen).ToString());
        vars.SetTextComponent("Video is Playing? (1=yes 0=no)", (current.inCutsceneState).ToString());
    }
}

init
{
    vars.hubMaps = new [] {"/game/mtw/mtw.mpk", "/game/mte/mte.mpk", "/game/downtown/downtown.mpk", "/game/downtown/downtown_west.mpk"};
}

start
{
    if (current.LevelName == "/game/trainyard/trainyard.mpk" && current.inCutsceneState == 1)
    {
        return true;
    }
}

split
{
    //after completed mission
    if (current.LevelName == old.LevelName)
    {
        return current.inMissionCompletedScreen == 1 && old.inMissionCompletedScreen == 0;
    }
    //final split
    if (current.CutsceneName == "sun_9000_storyboard.bik" && current.inCutsceneState == 1)
    {
        return true;
    }
    //split from zeppelin to black sun
    if (current.LevelName == "/game/blacksun/blacksun.mpk" && old.LevelName == "/game/zeppelin/zeppelin.mpk")
    {
        return true;
    }
    //tavern split, because it hasn't mission completed screen
    if (current.LevelName == "/game/tavern/tavern.mpk" || old.LevelName == "/game/tavern/tavern.mpk")
    {
        return false;
    }
    //Don't split on main menu
    if (current.LevelName == "/game/menu/menu.mpk" || old.LevelName == "/game/menu/menu.mpk")
    {
        return false;
    }

    bool enteringHub = false;
    bool leavingHub = false;
    foreach (string hubMap in vars.hubMaps)
    {
        if (!enteringHub && current.LevelName == hubMap)
            enteringHub = true;

        if (!leavingHub && old.LevelName == hubMap)
            leavingHub = true;
    }

    if (settings["splitHubs"] && leavingHub) 
    {
        return true;
    }

    if (settings["midMapSplit"] && !(enteringHub || leavingHub))
    {
        return true;
    }
}

isLoading
{
    return current.loading == 1 || current.inCutsceneState == 1 || current.inMissionCompletedScreen == 1;
}

reset
{
    if (old.LevelName == "/game/menu/menu.mpk")
    {
        return false;
    }

    return current.LevelName == "/game/menu/menu.mpk";
}

exit
{
    timer.IsGameTimePaused = true;
}