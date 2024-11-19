var start = func(){
timer_search.start();
}

var stop = func(){
timer_search.stop();
}





var search = func(){

if (getprop("/sim/remote/dialog/b")){


var cs = getprop("/sim/remote/callsign");

# cs is the input callsign to search for. 
# ex if i wanted to search for the id of callsign uapilot
# i would call pilot.search("uapilot");


 var mp0 = getprop("/ai/models/multiplayer[0]/callsign");
 var mp1 = getprop("/ai/models/multiplayer[1]/callsign");
 var mp2 = getprop("/ai/models/multiplayer[2]/callsign");
 var mp3 = getprop("/ai/models/multiplayer[3]/callsign");
 var mp4 = getprop("/ai/models/multiplayer[4]/callsign");
 var mp5 = getprop("/ai/models/multiplayer[5]/callsign");
 var mp6 = getprop("/ai/models/multiplayer[6]/callsign");
 var mp7 = getprop("/ai/models/multiplayer[7]/callsign");
 var mp8 = getprop("/ai/models/multiplayer[8]/callsign");
 var mp9 = getprop("/ai/models/multiplayer[9]/callsign");
var mp10 = getprop("/ai/models/multiplayer[10]/callsign");
var mp11 = getprop("/ai/models/multiplayer[11]/callsign");
var mp12 = getprop("/ai/models/multiplayer[12]/callsign");
var mp13 = getprop("/ai/models/multiplayer[13]/callsign");
var mp14 = getprop("/ai/models/multiplayer[14]/callsign");
var mp15 = getprop("/ai/models/multiplayer[15]/callsign");
var mp16 = getprop("/ai/models/multiplayer[16]/callsign");
var mp17 = getprop("/ai/models/multiplayer[17]/callsign");
var mp18 = getprop("/ai/models/multiplayer[18]/callsign");
var tracked = 0;

    if(mp0 == cs) 
    {
        print("I see someone! on mp0");
        var tracked = 0;
        mpstick(tracked);

    }

 else if(mp1 == cs)
    {
        print("I see someone! On mp1");
        var tracked = 1;
        mpstick(tracked);

    }

       else if(mp2 == cs)
    {
        print("I see someone! On mp2");
        var tracked = 2;
        mpstick(tracked);

    }

       else if(mp3 == cs)
    {
        print("I see someone! On mp3");
        var tracked = 3;
mpstick(tracked);

    }

       else if(mp4 == cs)
    {
        print("I see someone!"); # lol too much work to make it say mp4~18 
        var tracked = 4;
mpstick(tracked);

    }

       else if(mp5 == cs)
    {
        print("I see someone!");
        var tracked = 5;
mpstick(tracked);

    }

       else if(mp6 == cs)
    {
        print("I see someone!");
        var tracked = 6;
mpstick(tracked);

    }

       else if(mp7 == cs)
    {
        print("I see someone!");
        var tracked = 7;
mpstick(tracked);

    }

       else if(mp8 == cs)
    {
        print("I see someone!");
        var tracked = 8;
mpstick(tracked);

    }

       else if(mp9 == cs)
    {
        print("I see someone!");
        var tracked = 9;
mpstick(tracked);

    }

       else if(mp10 == cs)
    {
        print("I see someone!");
        var tracked = 10;
mpstick(tracked);

    }

       else if(mp11 == cs)
    {
        print("I see someone!");
        var tracked = 11;
mpstick(tracked);

    }

       else if(mp12 == cs)
    {
        print("I see someone!");
        var tracked = 12;
mpstick(tracked);

    }

       else if(mp13 == cs)
    {
        print("I see someone!");
        var tracked = 13;
mpstick(tracked);

    }

       else if(mp14 == cs)
    {
        print("I see someone!");
        var tracked = 14;
mpstick(tracked);

    }

       else if(mp15 == cs)
    {
        print("I see someone!");
        var tracked = 15;
mpstick(tracked);

    }

       else if(mp16 == cs)
    {
        print("I see someone!");
        var tracked = 16;
mpstick(tracked);

    }

       else if(mp17 == cs)
    {
        print("I see someone!");
        var tracked = 17;
mpstick(tracked);

    }

       else if(mp18 == cs)
    {
        print("I see someone!");
        var tracked = 18;
mpstick(tracked);

    }




else {
  print("Callsign dose not exist. or there are more than 18 multi players!");


   }

}


}


var mpstick2 = func(mpid){

    print(mpid);
    print(getprop("ai/models/multiplayer[" ~ mpid ~ "]/callsign")); # We found our threat
    var state = getprop("/sim/controls/copilot-mode");
    print(state);
    if (state == 1){
    mpstick(mpid);
    }
}




var mpstick = func(mpid){

mpid = mpid - 1;

# Copilot can control the plane

var ail = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/sim/multiplay/generic/float[4]");
var elev = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/sim/multiplay/generic/float[3]");
var rud = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/sim/multiplay/generic/float[5]");
var throt = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/sim/multiplay/generic/float[6]");
print(ail);


    setprop("/controls/flight/aileron", ail);
    setprop("/controls/flight/elevator", elev);
    setprop("/controls/flight/rudder", rud);
    setprop("/controls/engines/throttle-all", throt);
}


timer_search = maketimer(0.01, search);

