state("wolf2")
{
    string255 LevelName : 0x952884, 0x4;
    int loading : "gamex86.dll", 0x875C6C;            //1 when loading, 0 when gameplay
    int inCutsceneState : "binkw32.dll", 0x25438;     //1 when Playing Movie, 0 when gameplay
    int inMissionCompletedScreen : "gamex86.dll", 0x875E8C, 0x268;
    string34 CutsceneName : 0x950E7C;
    //float IGT : 0xAF7380, 0x100, 0x36C;
}

startup
{
    settings.Add("splits", true, "Using splits");
    settings.SetToolTip("splits", "Disable if you don't use splits and only want automatic start, stop and reset");

    settings.Add("splitHubs", true, "Split hub travel", "splits");
    settings.SetToolTip("splitHubs", "Disable if you only use splits when completing a level");

    settings.Add("midMapSplit", false, "Mid level splits", "splits");
    settings.SetToolTip("midMapSplit", "Disable if you don't have mid level splits. i.e. Castle -> Castle Top");
}

init
{
    vars.hubMaps = new [] {"/game/mtw/mtw.mpk", "/game/mte/mte.mpk", "/game/downtown/downtown.mpk", "/game/downtown/downtown_west.mpk"};
}

start
{
    if (current.CutsceneName == "osa_1000_blocking_vo_russian.bik" && current.inCutsceneState == 1)
    {
        return true;
    }
    else if (current.LevelName == "/game/trainyard/trainyard.mpk" && current.inCutsceneState == 1)
    {
        return true;
    }
}

split
{
    //after completed mission
    if (current.LevelName != old.LevelName)
    {
        return true;
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
    if (current.LevelName == "/game/mtw/mtw.mpk" && old.LevelName == "/game/tavern/tavern.mpk")
    {
        return true;
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
        return true;

    if (settings["midMapSplit"] && !(enteringHub || leavingHub))
        return true;
}

isLoading
{
    return current.loading == 1 || current.inCutsceneState == 1 || current.inMissionCompletedScreen == 1;
}

/*
gameTime
{
    return TimeSpan.FromMilliseconds(current.IGT);
}
*/

reset
{
    if (current.LevelName == "/game/menu/menu.mpk")
    {
        return true;
    }
}

exit
{
    timer.IsGameTimePaused = true;
}