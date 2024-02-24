# LZ Design Front Electric Sustainer FCU by Benedikt Wolf based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var FCU_main = nil;
var FCU_msg = nil;
var FCU_shutdown = nil;
var FCU_start = nil;
var FCU_display = nil;

var hp_kw = 0.7457;

var state = 0;
var FCU_volts = props.globals.getNode("/systems/electrical/outputs/fcu", 1);

var eng_rpm = props.globals.getNode("engines/engine[0]/rpm", 1);
var eng_pwr = props.globals.getNode("fdm/jsbsim/propulsion/engine[0]/power-hp", 1);

var batt_volts = props.globals.getNode("/systems/FES/volts", 1);
var batt_amps = props.globals.getNode("/systems/FES/amps", 1);

var throttle = props.globals.getNode("/systems/FES/throttle-int", 1);

var temp_motor = props.globals.getNode("/systems/FES/temperature/motor-degc", 1);
var temp_controller = props.globals.getNode("/systems/FES/temperature/controller-degc", 1);
var temp_battery1 = props.globals.getNode("/systems/FES/temperature/battery-degc[0]", 1);
var temp_battery2 = props.globals.getNode("/systems/FES/temperature/battery-degc[1]", 1);

var power_switch = props.globals.getNode("/systems/FES/power-switch", 1);

var canopy_switch = props.globals.getNode("/glider/canopy-norm", 1);
var canopy_inhib = props.globals.initNode("/systems/FES/canopy-inhibit", 0, "BOOL");

var voltage_inhib = props.globals.initNode("/systems/FES/voltage-inhibit", 0, "BOOL");

var charge = 0.0;

var instrument_dir = "Aircraft/extra300L/Models/Interior/Panel2/Instruments/FCU/";

var alarm_sound = [
	props.globals.initNode("/instrumentation/FCU/alarm[0]", 0, "BOOL"),
	props.globals.initNode("/instrumentation/FCU/alarm[1]", 0, "BOOL"),
	props.globals.initNode("/instrumentation/FCU/alarm[2]", 0, "BOOL"),
];

var lights = {
	ok:	[
		props.globals.initNode("/instrumentation/FCU/lights/ok-green", 0, "BOOL"),
		props.globals.initNode("/instrumentation/FCU/lights/ok-red", 0, "BOOL"),
		],
	error:	[
		props.globals.initNode("/instrumentation/FCU/lights/error-green", 0, "BOOL"),
		props.globals.initNode("/instrumentation/FCU/lights/error-red", 0, "BOOL"),
		],
	alarm:	[
		props.globals.initNode("/instrumentation/FCU/lights/alarm-green", 0, "BOOL"),
		props.globals.initNode("/instrumentation/FCU/lights/alarm-red", 0, "BOOL"),
		],
};

var blink_on = 0;
var light_red_blink = func {
	if( !blink_on ){
		blink_on = 1;
		lights.alarm[1].setBoolValue(1);
	} elsif( blink_on ){
		blink_on = 0;
		lights.alarm[1].setBoolValue(0);
	}
}
var light_red_blinking = maketimer( 0.1, light_red_blink );
light_red_blinking.simulatedTime = 1;

var message = {	
	new: func( condition, level, prio, text, req_action = -1, action_label = "" ){
		var m = { parents: [ message ] };
		m.condition = condition;
		m.active = 0;
		m.level = level;	# 0 = red warning, 1 = yellow warning, 2 = information (red), 3 = information (grey), 4 = information (green)
		m.prio = prio;
		m.text = text;
		m.req_action = req_action;	# -1 = none, 0 = reduce power, 1 = stop fes motor
		m.action_label = action_label;
		m.ack = 0;
		return m;
	},
};

var temp_batt = [ ];
var rpm = nil;

var messages = [
	message.new( func{ return temp_controller.getDoubleValue() > 90 }, 0, 4, "Contr. Ext. High > 90°C", 1, "press knob to dismiss" ),
	
	message.new( func{ return temp_controller.getDoubleValue() > 70 and temp_controller.getDoubleValue() <= 90 }, 1, 8, "Controller High > 70°C", 0, "press knob to dismiss" ),
	
	message.new( func{ return temp_motor.getDoubleValue() > 90 }, 0, 3, "Motor Ext. High > 90°C", 1, "press knob to dismiss" ),
	
	message.new( func{ return temp_motor.getDoubleValue() > 70 and temp_motor.getDoubleValue() <= 90  }, 1, 7, "Motor High > 70°C", 0, "press knob to dismiss" ),
	
	message.new( func{ return ventilation_warn }, 1, 15, "Warning,\nCheck ventilation!", -1, "press knob to dismiss" ),
	
	message.new( func{ return ( temp_batt[0] < 5 or temp_batt[1] < 5 ) }, 1, 1, "Battery Low < 5°C, \nDo not self-launch!", -1, "press knob to dismiss" ),
	
	message.new( func{ return math.abs( temp_batt[0] - temp_batt[1] ) > 3 and math.abs( temp_batt[0] - temp_batt[1] ) <= 6  }, 1, 6, "Battery temp. diff. > 3°C", 0, "press knob to dismiss" ),
	
	message.new( func{ return math.abs( temp_batt[0] - temp_batt[1] ) > 6 }, 0, 2, "Battery temp. diff. > 6°C", 1, "press knob to dismiss" ),
	
	message.new( func{ return ( temp_batt[0] > 45 or temp_batt[1] > 45 ) and temp_batt[0] <= 55 and temp_batt[1] <= 55 }, 1, 5, "Battery High > 45°C", 0, "press knob to dismiss" ),
	
	message.new( func{ return ( temp_batt[0] > 55 or temp_batt[1] > 55 ) }, 0, 1, "Batt. Ext. High > 55°C", 1, "press knob to dismiss" ),
	
	message.new( func{ return temp_batt[0] > 75 or temp_batt[1] > 75 }, 0, 0, "Batt. Critical > 75°C, \nLand immediately!", -1, "press knob to dismiss" ),
	
	message.new( func{ return voltage_warn == 1 }, 1, 30, "Low Voltage", 0, "press knob to dismiss"),
	
	message.new( func{ return voltage_warn == 2 }, 0, 20, "Critical Voltage", 1, "press knob to dismiss"),
	
	message.new( func{ return FCU_volts.getDoubleValue() < 11 }, 0, 21, "Low 12 V\npower supply", -1, "press knob to dismiss"),
	
	message.new( func{ return throttle.getDoubleValue() > 0.05 and !power_switch.getBoolValue() }, 1, 31, "Warning,\nCheck Power switch!", -1, "press knob to dismiss"),
	
	message.new( func{ return canopy_warn == 1 }, 1, 32, "Warning\nCHECK CANOPY!", -1, "push to proceed!" ),
	
	message.new( func{ return canopy_warn >= 3 }, 0, 22, "Warning\nCanopy is\nstill open!", -1, "push to proceed!" ),
];

var push_knob = func( i ){
	if( i ){
		if( voltage_warn == 3 or voltage_warn == 5 ){
			voltage_warn = 4;
			shutdown_timer_loop.stop();
			shutdown_remain = 30;
			voltage_inhib.setBoolValue( 0 );
		}
		if( canopy_warn > 0 or messages[14].active ){
			throttle.setDoubleValue( 0.0 );
		}
		if( canopy_warn == 1 ){
			canopy_warn = 2;
		}
		if( canopy_warn == 3 ){
			canopy_warn = 4;
			canopy_inhib.setBoolValue( 0 );
		}
		if( max_prio_index != nil and messages[ max_prio_index ] != nil ){
			messages[ max_prio_index ].ack = 1;
			FCU_msg.update();
		}
	}
}

var canopy_warn = 0;	# 0 = off, 1 = yellow, 2 = yellow ack, 3 = red, 4 = override
var voltage_warn = 0;	# 0 = off, 1 = low (<95), 2 = critical (<90), 3 = countdown (starts 30 sec after level 2), 4 = override, 5 = motor shut down
var ventilation_warn = 0;	# 0 = off, 1 = on

var last_motor_temp = -9999;

var shutdown_remain = 30;

var shutdown_timer = func{
	if( batt_volts.getDoubleValue() < 90 ){
		if( eng_pwr.getDoubleValue() > 0.1 ){
			if( shutdown_remain <= 0 ){
				shutdown_remain = 0;
				voltage_inhib.setBoolValue( 1 );
				voltage_warn = 5;
				FCU_shutdown.update();
			} else {
				shutdown_remain -= 1;
				FCU_shutdown.update();
			}
		} else {
			voltage_warn = 5;
			shutdown_remain = 30;
			shutdown_timer_loop.stop();
		}
	} else {
		voltage_warn = 0;
		shutdown_remain = 30;
		shutdown_timer_loop.stop();
	}
}

var shutdown_timer_loop = maketimer( 1.0, shutdown_timer );
shutdown_timer_loop.simulatedTime = 1;
	

var update_messages = func{
	if( state != 2 ) return;
	
	temp_batt = [
		temp_battery1.getDoubleValue(),
		temp_battery2.getDoubleValue(),
	];
	rpm = eng_rpm.getDoubleValue();
	
	var cnp_sw = canopy_switch.getDoubleValue();
	if( cnp_sw > 0.1 and throttle.getDoubleValue() > 0.0 and canopy_warn == 0 ){
		canopy_warn = 1;
		canopy_inhib.setBoolValue( 1 );
	} elsif( cnp_sw > 0.1 and throttle.getDoubleValue() > 0.0 and canopy_warn == 2 ){
		canopy_warn = 3;
		canopy_inhib.setBoolValue( 1 );
	}
	if( cnp_sw <= 0.1 and canopy_warn > 0 ){
		canopy_warn = 0;
		canopy_inhib.setBoolValue( 0 );
	}
	
	var battery_volts = batt_volts.getDoubleValue();
	if( voltage_warn >= 2 and battery_volts >= 90 ){
		if( battery_volts >= 95 ){
			voltage_warn = 0;
		} else {
			voltage_warn = 1;
		}
	}
	if( battery_volts < 90 and voltage_warn < 2 ){
		voltage_warn = 2;
		shutdown_remain = 30;
		shutdown_timer_loop.start();
		settimer( func{ if( voltage_warn == 2 and batt_volts.getDoubleValue() < 90 and eng_pwr.getDoubleValue() > 0 ) voltage_warn = 3; }, 30 );
	} elsif( battery_volts < 95 and voltage_warn < 1 ){
		voltage_warn = 1;
	}
	if( voltage_warn == 3 and battery_volts < 90 and shutdown_remain < 0 ){
		shutdown_timer_loop.start();
	}
	
	var motor_temp = temp_motor.getDoubleValue();
	if( last_motor_temp > -9990 ){
		var motor_temp_diff = ( motor_temp - last_motor_temp ) * 10; # degC/kelvin per second
		ventilation_warn = ( ( motor_temp_diff > 1.0 and ventilation_warn ) or ( motor_temp_diff > 1.5 ) );
	}
	last_motor_temp = motor_temp;
	
	var redraw = 0;
	var led = 0;	# 0 = off, 1 = blink red, 2 = steady red
	var alarm = 0;	# 0 = off, 1 = once (info message), 2 = three beeps (yellow messages), 3 = steady (red messages)
	foreach( var el; messages ){
		if( el.condition != nil ){
			if( !el.ack and el.condition() and !el.active ){
				el.active = 1;
				if( el.level == 1 and led == 0 ){
					led = 1;
				}
				if( el.level == 2 and alarm < 1 ){
					alarm = 1;
				}
				if( el.level == 1 and alarm < 2 ){
					alarm = 2;
				}
				if( el.level == 0 and alarm < 3 ){
					alarm = 3;
				}
				redraw = 1;
			}elsif( !el.condition() and ( el.active or el.ack ) ){
				el.active = 0;
				el.ack = 0;
				redraw = 1;
			}elsif( el.condition() and el.active and el.ack ){
				el.active = 0;
				redraw = 1;
			}
			if( el.condition() and el.level == 0 ){
				led = 2;
			}
		}
	}
	
	if( redraw ){
		FCU_msg.update();
		if( led == 0 ){
			light_red_blinking.stop();
			lights.alarm[1].setBoolValue( 0 );
		} elsif( led == 1 ){
			light_red_blinking.start();
		} elsif( led == 2 ){
			light_red_blinking.stop();
			lights.alarm[1].setBoolValue( 1 );
		}
		if( alarm == 0 ){
			alarm_sound[0].setBoolValue( 0 );
			alarm_sound[1].setBoolValue( 0 );
			alarm_sound[2].setBoolValue( 0 );
		}elsif( alarm == 1 ){
			alarm_sound[0].setBoolValue( 1 );
			alarm_sound[1].setBoolValue( 0 );
			alarm_sound[2].setBoolValue( 0 );
		}elsif( alarm == 2 ){
			alarm_sound[0].setBoolValue( 0 );
			alarm_sound[1].setBoolValue( 1 );
			alarm_sound[2].setBoolValue( 0 );
		}elsif( alarm == 3 ){
			alarm_sound[0].setBoolValue( 0 );
			alarm_sound[1].setBoolValue( 0 );
			alarm_sound[2].setBoolValue( 1 );
		}
	}
}

var msg_updater = maketimer( 0.1, update_messages );
msg_updater.simulatedTime = 1;

var show_message_page = 0;

var canvas_FCU_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Bold.ttf";
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		var svg_keys = me.getKeys();
		foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if( state == 2 ){
			FCU_start.page.hide();
			if( voltage_warn == 3 ){
				FCU_main.page.hide();
				FCU_msg.page.hide();
				FCU_shutdown.page.show();
			} elsif( show_message_page ){
				FCU_main.page.hide();
				FCU_msg.page.show();
				FCU_shutdown.page.hide();
			} else {
				FCU_msg.page.hide();
				FCU_shutdown.page.hide();
				FCU_main.page.show();
				FCU_main.update();
			}
		} elsif( state == 1 ){
			FCU_main.page.hide();
			FCU_msg.page.hide();
			FCU_shutdown.page.hide();
			FCU_start.page.show();
		} else {
			FCU_main.page.hide();
			FCU_msg.page.hide();
			FCU_shutdown.page.hide();
			FCU_start.page.hide();
		}
	},
};

var ctrl_flag = -1;	# 0 = off, 1 = on
var throttle_bar_state = -1; # 0 = normal, 1 = blinking
var throttle_bar_blink = -1; # 0 = off, 1 = on
	
	
var canvas_FCU_main = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_FCU_main , canvas_FCU_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["rpm.100","pwr.digits","battery.volts","battery.amps","throttle.bar","battery.1","battery.2","battery.3","battery.4","battery.5","battery.6","battery.7","battery.8","battery.9","battery.10","temp.motor","temp.controller","temp.battery1","temp.battery2","controller.flag","canopy_powersupply.flag"];
	},
	update: func() {
		me["rpm.100"].setText(sprintf("%02d", math.round(math.floor(eng_rpm.getValue()/100))));
		
		var power = eng_pwr.getValue()*hp_kw;
		if(power > 1){
			me["pwr.digits"].setText(sprintf("%2d", math.round(power)));
		}else{
			me["pwr.digits"].setText("--");
		}
		
		var bv = batt_volts.getValue();
		if(bv != nil){
			me["battery.volts"].setText(sprintf("%3d", math.round(bv))~"V");
		}else{
			me["battery.volts"].setText("---V");
		}
		var ba = batt_amps.getValue();
		if(ba != nil and ba > 0){
			me["battery.amps"].setText(sprintf("%3d", math.round(ba))~"A");
		}else{
			me["battery.amps"].setText("---A");
		}
		
		var throttle = throttle.getDoubleValue();
		if( throttle >= 0.0 ){
			me["throttle.bar"].setTranslation( - ( 1 - throttle ) * 292, 0 );
			if( throttle_bar_state != 0 ){
				me["throttle.bar"].show();
				me["throttle.bar"].setColorFill( 1, 1, 1 );
				throttle_bar_state = 0;
			}
		} else {
			# braking: blinking throttle
			if( throttle_bar_blink != 1 ){
				me["throttle.bar"].show();
				throttle_bar_blink = 1;
			} else {
				me["throttle.bar"].hide();
				throttle_bar_blink = 0;
			}
			
			if( throttle_bar_state != 1 ){
				me["throttle.bar"].setColorFill( 1, 0, 0 );
				me["throttle.bar"].setTranslation( 0, 0 );
				throttle_bar_state = 1;
			}
		}
		
		charge = minilak.batteries[0].charge;
		
		if(charge > 0.9){
			me["battery.10"].show();
		}else{
			me["battery.10"].hide();
		}
		if(charge > 0.8){
			me["battery.9"].show();
		}else{
			me["battery.9"].hide();
		}
		if(charge > 0.7){
			me["battery.8"].show();
		}else{
			me["battery.8"].hide();
		}
		if(charge > 0.6){
			me["battery.7"].show();
		}else{
			me["battery.7"].hide();
		}
		if(charge > 0.5){
			me["battery.6"].show();
		}else{
			me["battery.6"].hide();
		}
		if(charge > 0.4){
			me["battery.5"].show();
		}else{
			me["battery.5"].hide();
		}
		if(charge > 0.3){
			me["battery.4"].show();
		}else{
			me["battery.4"].hide();
		}
		if(charge > 0.2){
			me["battery.3"].show();
		}else{
			me["battery.3"].hide();
		}
		if(charge > 0.1){
			me["battery.2"].show();
		}else{
			me["battery.2"].hide();
		}
		if(charge > 0.0){
			me["battery.1"].show();
		}else{
			me["battery.1"].hide();
		}
		
		
		me["temp.motor"].setText(sprintf("%2d", math.round(temp_motor.getValue()))~"°C");
		if( ctrl_flag == 1 ){
			me["temp.controller"].setText(sprintf("%2d", math.round(temp_controller.getValue()))~"°C");
		} else {
			me["temp.controller"].setText("---° C");
		}
		me["temp.battery1"].setText(sprintf("%2d", math.round(temp_battery1.getValue()))~"°C");
		me["temp.battery2"].setText(sprintf("%2d", math.round(temp_battery2.getValue()))~"°C");
		
	
		if( power_switch.getBoolValue() and ctrl_flag != 1 ){
			me["controller.flag"].setText("CONTROLLER READY");
			me["controller.flag"].setColor(0,1,0);
			lights.ok[0].setBoolValue( 1 );
			lights.ok[1].setBoolValue( 0 );
			ctrl_flag = 1;
		}elsif( !power_switch.getBoolValue() and ctrl_flag != 0 ){
			me["controller.flag"].setText("NO DATA FROM CONTROLLER");
			me["controller.flag"].setColor(1,1,1);
			lights.ok[0].setBoolValue( 0 );
			lights.ok[1].setBoolValue( 0 );
			ctrl_flag = 0;
		}
		
		if( canopy_switch.getDoubleValue() > 0.1 ){
			me["canopy_powersupply.flag"].setText("CANOPY");
			me["canopy_powersupply.flag"].setColor(1,0,0);
		} else {
			me["canopy_powersupply.flag"].setText( sprintf("%3.1fV", FCU_volts.getDoubleValue() ) );
			me["canopy_powersupply.flag"].setColor(1,1,1);
		}
	}	
};

var max_prio_index = nil;

var canvas_FCU_msg = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_FCU_msg , canvas_FCU_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [ "title_background", "title", "text", "action_label" ];
	},
	update: func() {
		# Look for the highest priority message
		var max_prio = 99;
		var rpm = eng_rpm.getDoubleValue();
		
		max_prio_index = nil;
		forindex( var i; messages ){
			if( messages[ i ].active and messages[ i ].prio < max_prio ){
				max_prio = messages[ i ].prio;
				max_prio_index = i;
			}
		}
		
		if( max_prio_index != nil ){
			show_message_page = 1;
			if( messages[ max_prio_index ].level == 0 ){
				me["title_background"].setColorFill( 255, 191, 0 );
				me["title"].setColorFill( 255, 255, 255 );
			} else {
				me["title_background"].setColorFill( 255, 255, 0 );
				me["title"].setColorFill( 0, 0, 0 );
			}
			me["title"].setText( "Warning" );
			if( messages[ max_prio_index ].req_action == 0 and eng_pwr.getDoubleValue() * hp_kw > 8 ){
				me["text"].setText( messages[ max_prio_index ].text ~"\nReduce power!" );
			} elsif( messages[ max_prio_index ].req_action == 1 and rpm > 50 ){
				me["text"].setText( messages[ max_prio_index ].text ~"\nStop FES motor!" );
			} else {
				me["text"].setText( messages[ max_prio_index ].text );
			}
			me["action_label"].setText( messages[ max_prio_index ].action_label );
		} else {
			show_message_page = 0;
		}
	}
	
};

# Automatic Shutdown when voltage < 90V for > 30 seconds
var canvas_FCU_shutdown = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_FCU_shutdown , canvas_FCU_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [ "remaining_time" ];
	},
	update: func() {
		me["remaining_time"].setText( sprintf("in %2d sec", shutdown_remain ) );
	}
	
};

var canvas_FCU_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_FCU_start , canvas_FCU_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	}
	
};

var light_test = func( x = 0 ){
	if( x == 0 ){
		lights.ok[0].setBoolValue( 0 );
		lights.error[0].setBoolValue( 0 );
		lights.alarm[0].setBoolValue( 0 );
		lights.ok[1].setBoolValue( 1 );
		lights.error[1].setBoolValue( 1 );
		lights.alarm[1].setBoolValue( 1 );
		settimer( func{ light_test( 1 ); }, 1 );
	} elsif( x == 1 ){
		lights.ok[0].setBoolValue( 1 );
		lights.error[0].setBoolValue( 1 );
		lights.alarm[0].setBoolValue( 1 );
		lights.ok[1].setBoolValue( 0 );
		lights.error[1].setBoolValue( 0 );
		lights.alarm[1].setBoolValue( 0 );
		settimer( func{ light_test( 2 ); }, 1 );
	} else {
		lights.ok[0].setBoolValue( 0 );
		lights.error[0].setBoolValue( 0 );
		lights.alarm[0].setBoolValue( 0 );
		lights.ok[1].setBoolValue( 0 );
		lights.error[1].setBoolValue( 0 );
		lights.alarm[1].setBoolValue( 0 );
	}
}
		


var check_state = func () {
	if ( state == 0 ){
		if ( FCU_volts.getDoubleValue() >= 9.0 ) {
			state = 1;
			light_test();
			settimer( func() { state = 2; }, 2);
		}
	} else {
		if ( FCU_volts.getDoubleValue() < 9.0 ){
			state = 0;
		}
	}
}

setlistener(FCU_volts, func{ check_state(); } );


var ls = setlistener("sim/signals/fdm-initialized", func {
	FCU_display = canvas.new({
		"name": "FCU",
		"size": [320, 240],
		"view": [320, 240],
		"mipmapping": 1
	});
	FCU_display.addPlacement({"node": "FCU.display"});


	FCU_main  = canvas_FCU_main.new( FCU_display.createGroup(), instrument_dir~"FCU.main.svg");
	FCU_msg   = canvas_FCU_msg.new(  FCU_display.createGroup(), instrument_dir~"FCU.message.svg");
	FCU_start = canvas_FCU_start.new(FCU_display.createGroup(), instrument_dir~"FCU.start.svg");
	FCU_shutdown = canvas_FCU_shutdown.new(FCU_display.createGroup(), instrument_dir~"FCU.shutdown.svg");

	msg_updater.start();

	var base_update = maketimer( 0.2, func {canvas_FCU_base.update();});
	base_update.start();
	removelistener(ls);
});
