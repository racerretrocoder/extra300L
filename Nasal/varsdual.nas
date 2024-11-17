#############################################################################
##
##  Nasal for dual control of the DO-X over the multiplayer network.
##
##  Stolen and modify by Marc Kraus (info(at)marc-kraus.de) from
##  Copyright (C) 2008 - 2010  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later
##
###############################################################################

# This file is only used to connect to them



# Renaming (almost :)
var DCT = dual_control_tools;
######################################################################
# Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/extra300L/Models/extra300L-model.xml";
var copilot_type = "Aircraft/extra300L/Models/extra300L-copilot.xml";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");
######################################################################
# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.

var pilotaileron   = "sim/multiplay/generic/float[5]";  # in dox-set.xml
var copilotaileron = "sim/multiplay/generic/float[0]";  # in dox-copilot-set.xml  copilot aileron movment

var pilotelevator  = "sim/multiplay/generic/float[6]";  # in dox-set.xml
var copilotelevator = "sim/multiplay/generic/float[1]";  # in dox-copilot-set.xml copilot elevato movment

var pilotrudder  = "sim/multiplay/generic/float[9]";  # in dox-set.xml
var copilotrudder = "sim/multiplay/generic/float[2]";  # in dox-copilot-set.xml copilot elevato movment

var pilotthrot = "sim/multiplay/generic/float[8]";  # in dox-set.xml
var copilotthrot = "sim/multiplay/generic/float[3]";  # in dox-copilot-set.xml copilot elevato movment

var copilot_rdf_power_on = "sim/multiplay/generic/int[0]";        # in dox-copilot-set.xml
var copilot_select_vor_or_ndb = "sim/multiplay/generic/int[1]";   # in dox-copilot-set.xml
var copilot_adf_selected = "sim/multiplay/generic/int[2]";        # in dox-copilot-set.xml
var copilot_nav_selected = "sim/multiplay/generic/float[1]";      # in dox-copilot-set.xml
var pilot_rdf_power_on = "/instrumentation/rdf/power-on";
var pilot_select_vor_or_ndb = "/instrumentation/rdf/frequency-select-knob";  # in dox-set.xml
var pilot_adf_selected = "/instrumentation/adf/frequencies/selected-khz";    # in dox-set.xml
var pilot_nav_selected = "/instrumentation/nav/frequencies/selected-mhz";    # in dox-set.xml

var pilot_set_anchor = "sim/multiplay/generic/int[12]";  # in dox-set.xml
var copilot_see_anchor = "/controls/anchor";        # in dox-copilot-set.xml

var pilot_afn2_makeron = "sim/multiplay/generic/int[13]";          # in dox-set.xml
var pilot_afn2_heading_corr = "sim/multiplay/generic/float[4]";    # in dox-set.xml
var pilot_afn2_distance = "sim/multiplay/generic/float[5]";        # in dox-set.xml

var copilot_afn2_makeron = "/instrumentation/afn2/markeron";                 # in dox-copilot-set.xml
var copilot_afn2_heading_corr = "/instrumentation/afn2/heading-correction";  # in dox-copilot-set.xml
var copilot_afn2_distance = "/instrumentation/afn2/distance";                # in dox-copilot-set.xml

var pilot_vertical_speed = "sim/multiplay/generic/float[6]";       # in dox-set.xml
var pilot_turn_slip_skid = "sim/multiplay/generic/float[7]";       # in dox-set.xml
var pilot_turn_rate = "sim/multiplay/generic/float[8]";            # in dox-set.xml
var copilot_vertical_speed = "/instrumentation/vertical-speed-indicator/indicated-speed-fpm"; # default in copilot
var copilot_turn_slip_skid = "/instrumentation/slip-skid-ball/indicated-slip-skid";           # default in copilot
var copilot_turn_rate = "/instrumentation/turn-indicator/indicated-turn-rate";                # default in copilot

var pilot_magnetic_compass = "sim/multiplay/generic/float[9]";          # in dox-set.xml
var pilot_throttle_right = "sim/multiplay/generic/float[10]";           # in dox-set.xml
var pilot_throttle_left = "sim/multiplay/generic/float[11]";            # in dox-set.xml
var copilot_magnetic_compass = "/instrumentation/magnetic-compass/indicated-heading-deg";   # default in copilot
var copilot_throttle_right = "/controls/engines/throttle-pilot-right";                      # in dox-copilot-set.xml
var copilot_throttle_left = "/controls/engines/throttle-pilot-left";                        # in dox-copilot-set.xml

######################################################################
# Slow state properties for replication.

var fcs = "fdm/yasim/fcs";
###############################################################################
# Pilot MP property mappings and specific copilot connect/disconnect actions.
var l_dual_control         = "/fdm/yasim/fcs/dual-control/enabled";


######################################################################
# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
    # Make sure dual-control is activated in the FDM FCS.
    settimer(func { setprop(l_dual_control, 1); }, 1);

    print("Open door and welcome the Copilot!");

    return 
        [
         ######################################################################
         # Process local properties for MP.
         ######################################################################
         # push local parameter in the float[]/int[] or whatever for MP


         ######################################################################
         # Process properties to send.
         ######################################################################
         # rotation-deg from copilot to the Pilot float
         DCT.Translator.new
         (copilot.getNode(copilotaileron),
          props.globals.getNode(pilotaileron, 1)),

         DCT.Translator.new
         (copilot.getNode(copilotelevator),
          props.globals.getNode(pilotelevator, 1)),

         DCT.Translator.new
         (copilot.getNode(copilotrudder),
          props.globals.getNode(pilotrudder, 1)),

         DCT.Translator.new
         (copilot.getNode(copilotthrot),
          props.globals.getNode(pilotthrot, 1)),

        ];
}

######################################################################
var pilot_disconnect_copilot = func {
    setprop(l_dual_control, 0);
    print("Say Good Bye to Copilot!");
}

######################################################################
# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {

    # Map (some) properties needed to (e.g.) animate the MP/AI model.
    copilot_alias_aimodel(pilot);
    print(pilot);
    print("Copilot on board!");

    return
        [
         ######################################################################
         # Process received properties.
         ######################################################################
         ##################################################
         # Map airspeed for airspeed indicator. This is cheating!
         DCT.Translator.new
         (pilot.getNode("velocities/true-airspeed-kt"),
          props.globals.getNode("/instrumentation/" ~
                                "airspeed-indicator/indicated-speed-kt", 1)),

         ######################################################################
         # Process properties to send.

         # Map engine RPMs to the appropriate properties / NOTE: only 10 engines are supported on flightgear
         DCT.Translator.new
         (pilot.getNode("engines/engine[0]/rpm"),
          props.globals.getNode("engines/engine[0]/rpm", 1),1),
     
         ######################################################################
        ];
}

######################################################################
var copilot_disconnect_pilot = func {
    settimer(func { setprop(l_dual_control, 0); }, 1);
    print("Copilot from board!");
}

######################################################################
# More property aliases to animate the MP/AI model for the copilot.
#  Contains all 1:1 mappings that are not provided by other modules
#  (e.g. instruments).

var copilot_alias_aimodel = func(pilot) {
    # Whatever we need for animate the MP/AI model

    # so we can see the copilot in the copilot aircraft
    setprop(l_dual_control, 1); # set in copilots "fdm/yasim/fcs/dual-control/enabled"

}