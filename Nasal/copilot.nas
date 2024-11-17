var start = func(){
timer_search.start();
}

var stop = func(){
timer_search.stop();
}



var search = func(cs){

# cs is the input callsign to search for. 
# ex if i wanted to search for the id of callsign uapilot
# i would call copilot.search("uapilot");


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
        track(tracked);

    }

 else if(mp1 == cs)
    {
        print("I see someone! On mp1");
        var tracked = 1;
        track(tracked);

    }

       else if(mp2 == cs)
    {
        print("I see someone! On mp2");
        var tracked = 2;
track(tracked);

    }

       else if(mp3 == cs)
    {
        print("I see someone! On mp3");
        var tracked = 3;
track(tracked);

    }

       else if(mp4 == cs)
    {
        print("I see someone!"); # lol too much work to make it say mp4~18 
        var tracked = 4;
track(tracked);

    }

       else if(mp5 == cs)
    {
        print("I see someone!");
        var tracked = 5;
track(tracked);

    }

       else if(mp6 == cs)
    {
        print("I see someone!");
        var tracked = 6;
track(tracked);

    }

       else if(mp7 == cs)
    {
        print("I see someone!");
        var tracked = 7;
track(tracked);

    }

       else if(mp8 == cs)
    {
        print("I see someone!");
        var tracked = 8;
track(tracked);

    }

       else if(mp9 == cs)
    {
        print("I see someone!");
        var tracked = 9;
track(tracked);

    }

       else if(mp10 == cs)
    {
        print("I see someone!");
        var tracked = 10;
track(tracked);

    }

       else if(mp11 == cs)
    {
        print("I see someone!");
        var tracked = 11;
track(tracked);

    }

       else if(mp12 == cs)
    {
        print("I see someone!");
        var tracked = 12;
track(tracked);

    }

       else if(mp13 == cs)
    {
        print("I see someone!");
        var tracked = 13;
track(tracked);

    }

       else if(mp14 == cs)
    {
        print("I see someone!");
        var tracked = 14;
track(tracked);

    }

       else if(mp15 == cs)
    {
        print("I see someone!");
        var tracked = 15;
track(tracked);

    }

       else if(mp16 == cs)
    {
        print("I see someone!");
        var tracked = 16;
track(tracked);

    }

       else if(mp17 == cs)
    {
        print("I see someone!");
        var tracked = 17;
track(tracked);

    }

       else if(mp18 == cs)
    {
        print("I see someone!");
        var tracked = 18;
track(tracked);

    }




else {
  print("Callsign dose not exist. or there are more than 18 multi players!");


   }
}


var track = func(mpid){

    print(mpid);
    print(getprop("ai/models/multiplayer[" ~ mpid ~ "]/callsign")); # We found our threat

    setprop("/autopilot/settings/heading-bug-deg",getprop("/ai/models/multiplayer[" ~ mpid ~ "]/radar/bearing-deg"));
    # If attack = 1. call attack(mpid); else dont attack
    if (getprop("controls/AI/attack") == 1){
        # Where attacking
        Attack(mpid);
    }
}




var radarsearch = func(){
         radar.next_Target_Index();
         setprop("controls/AI/rdrcallsign", radar.tgts_list[radar.Target_Index].Callsign.getValue());
}




var Attack = func(mpid){
    print("Attack armed");


    # This depends on the missiles we are using. If where 10 degress +- away from dead center of the bandit, shoot.
    var bandithdg = getprop("/orientation/heading-deg");
    var bandithdg1 = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/radar/bearing-deg") - 8;  # Set this if you want to the UAV to shoot different
    var bandithdg2 = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/radar/bearing-deg") + 8;
    #print(getprop("ai/models/multiplayer[" ~ mpid ~ "]/callsign")); # We found our threat

    if(bandithdg < bandithdg1) {
        print("Attack Complies 1/2");
        if(bandithdg < bandithdg2){
            print("Attack Complies 2/2");

        # Where in the heading window of our selected target
        # Lets spam radar change target until the radar target = The target we want dead
         
         radar_timer.start(); # Rapidly scan the radar for our threat
          var rdrtgt = getprop("controls/AI/rdrcallsign");
         if (rdrtgt == getprop("controls/AI/TGTCALLSIGN")) {
            # Hell yeah! we found him! Lets kill him!
            shoot(mpid);
            radar_timer.stop()
            }


        }

    } else{
        print("Bandit Not withen Heading");

        

        # How to get the next locked radar target: radar.tgts_list[radar.Target_Index].Callsign.getValue()
    }
}


var shoot = func(mpid){
          # We found our target lets fire a missile depending on range

                setprop("/sim/multiplay/chat", "UAV Fireing Missile");

                var range = getprop("/ai/models/multiplayer[" ~ mpid ~ "]/radar/range-nm");
                if (range > 5){
                setprop("/controls/armament/selected-weapon", "Aim-120");
                } else {
                setprop("/controls/armament/selected-weapon", "Aim-9x");
               }
                m2000_load.SelectNextPylon();
              #  f22.fire(0,0); # Open the bay doors of the currently selected weapon
                var pylon = getprop("/controls/armament/missile/current-pylon");
                m2000_load.dropMissile(pylon);
                print("Should fire Missile");
                setprop("controls/AI/attack", 0); # One missile at a time
                setprop("controls/AI/rdrcallsign","None");
           

}











timer_search = maketimer(1, search);

radar_timer = maketimer(0.00001, radarsearch);


