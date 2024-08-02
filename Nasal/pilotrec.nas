


var myFunc = func(){

    var remote = getprop("/sim/remote/pilot-callsign");
    var mp1 = getprop("/ai/models/multiplayer/callsign");
    var mp2 = getprop("/ai/models/multiplayer[1]/callsign");
    var mp3 = getprop("/ai/models/multiplayer[2]/callsign");
    var mp4 = getprop("/ai/models/multiplayer[3]/callsign");
    var mp5 = getprop("/ai/models/multiplayer[4]/callsign");
    var mp6 = getprop("/ai/models/multiplayer[5]/callsign");
    var mp7 = getprop("/ai/models/multiplayer[6]/callsign");
    var mp8 = getprop("/ai/models/multiplayer[7]/callsign");
    var mp9 = getprop("/ai/models/multiplayer[8]/callsign");
    var mp10 = getprop("/ai/models/multiplayer[9]/callsign");
    var mp11 = getprop("/ai/models/multiplayer[10]/callsign");
    var mp12 = getprop("/ai/models/multiplayer[11]/callsign");
    setprop("/sim/controls/DC/mp1", mp1)
    setprop("/sim/controls/DC/mp2", mp2)
    setprop("/sim/controls/DC/mp3", mp3)
    setprop("/sim/controls/DC/mp4", mp4)
    setprop("/sim/controls/DC/mp5", mp5)
    setprop("/sim/controls/DC/mp6", mp6)
    setprop("/sim/controls/DC/mp7", mp7)
    setprop("/sim/controls/DC/mp8", mp8)
    setprop("/sim/controls/DC/mp9", mp9)
    setprop("/sim/controls/DC/mp10", mp10)

}