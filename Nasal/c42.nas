var F_Switch = props.globals.getNode("controls/fuel/switch-position",1);
var FDM=0;
var hmHobbs  =  aircraft.timer.new("instrumentation/hobbs-meter/time", 60); 
var rpmN     = props.globals.getNode("engines/engine[0]/rpm", 1);
var time = 0;
var dt = 0;
var last_time = 0;

var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);

var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

 #============================ Tyre Smoke ===================================
 aircraft.tyresmoke_system.new(0, 1, 2);
 #============================ Rain ===================================
 aircraft.rain.init();
 var rain = func {
	 aircraft.rain.update();
	 settimer(rain, 0);
 }
 # == fire it up ===
 rain();
 # end

setlistener("/sim/signals/fdm-initialized", func {
    F_Switch.setIntValue(-1);
    setprop("consumables/fuel/tank[0]/selected",1);
#    setprop("consumables/fuel/tank[1]/selected",1);
    setup_start();
    FDM=1;
    update();
});

setlistener("/sim/signals/reinit", func(rset) {
    if(rset.getValue()==0){
    setup_start();
    }
},1,0); 


controls.startEngine = func(v = 1) {
    foreach(var e; controls.engines)
        if(e.selected.getValue()){
            var power = props.globals.getNode("systems/electrical/volts").getValue();
            if(power > 8.0 ){
               e.controls.getNode("starter").setBoolValue(v);
            }
            else {
               e.controls.getNode("starter").setBoolValue(0);
            }
        }
} 

controls.stepMagnetos = func(change) {
    foreach(var e; controls.engines) {
        if(e.selected.getValue()) {
            var starter = 0;
            if (change) {
                var mag = e.controls.getNode("magnetos", 1);
                var setting = mag.getValue() + change;
                if(setting > 3){
                   starter = 1;
                   setting = 3;
                }
                mag.setIntValue(setting);
            }
            setprop("controls/engines/engine/starter-switch", starter);
            controls.startEngine(starter);
        }
    }
} 

setlistener("controls/electric/circuitbreaker/cb_0_1", func(cb01) {
    if (cb01.getBoolValue()) {
	    setprop("instrumentation/marker-beacon/power-btn",0);
    } else {
	    setprop("instrumentation/marker-beacon/power-btn",1);
    }
});

setlistener("controls/electric/circuitbreaker/cb_0_6", func(cb06) {
    if (cb06.getBoolValue()) {
	    setprop("/sim/view/dynamic/enabled",0);
    } else {
	    setprop("/sim/view/dynamic/enabled",1);
    }
});

var doLight = func {
	var factor     = getprop("systems/electrical/outputs/landing-lights-norm");
	var factorT    = getprop("systems/electrical/outputs/taxi-lights-norm");
	var factorAGL  = 0.0;
	var factorAGLT = 0.0;
	var agl = getprop("position/altitude-agl-ft");
	var aglFactor = 16/(agl*agl);
	if (factor){
		factorAGL = factor;
		if (agl > 4) { 
			factorAGL = factor * aglFactor;
		}
	}
	if (factorT){
		factorAGLT = factor;
		if (agl > 4) { 
			factorAGLT = factorT * aglFactor;
		}
	}
	props.globals.getNode("sim/models/materials/LandingLight/factorAGL", 1).setValue(factorAGL);
	props.globals.getNode("sim/models/materials/LandingLight/factorAGL-T", 1).setValue(factorAGLT);
}

var oil_pressure = func{
    if(getprop("engines/engine/oil-pressure-psi") < 10){
      props.globals.getNode("controls/engines/engine[0]/master-caution",1).setBoolValue(1);
    }else{
      props.globals.getNode("controls/engines/engine[0]/master-caution",1).setBoolValue(0);
    }
}

var fuel_pressure = func{
	var pressure = 0;
	if ( ! getprop("engines/engine/out-of-fuel")){
		if (rpmN.getValue() > 500) { pressure=1; }
		if (getprop("systems/electrical/outputs/fuel-pump") > 10) { pressure=1; }
	}
	props.globals.getNode("engines/engine/fuel-pressure",1).setBoolValue(pressure);
}

#
#  STARTUP FUNCTION
#
var setup_start = func{
	props.globals.getNode("systems/electrical/outputs/fuel-pump",1).setValue(0.0);
	props.globals.getNode("engines/engine/fuel-pressure",1).setDoubleValue(0);
	props.globals.getNode("instrumentation/kx155a/commvol-norm", 1).setDoubleValue(0.0);
	props.globals.getNode("instrumentation/kx155a/navvol-norm", 1).setDoubleValue(0.0);
	props.globals.getNode("sim/models/materials/LandingLight/factorAGL",1).setDoubleValue(0.0); 
#	startFuel();
}

# ==================== Radio Frequency Display =========================

radiodisplay = func(radio) {
	var selected=getprop("/instrumentation/"~radio~"/frequencies/selected-mhz");
	var formatted=sprintf("%.02f",selected);

	var digit1=substr(formatted,0,1);
	var digit2=substr(formatted,1,1);
	var digit3=substr(formatted,2,1);
	var digit4=substr(formatted,4,1);
	var digit5=substr(formatted,5,1);

	setprop("instrumentation/"~radio~"/selected/digit1",digit1);
	setprop("instrumentation/"~radio~"/selected/digit2",digit2);
	setprop("instrumentation/"~radio~"/selected/digit3",digit3);
	setprop("instrumentation/"~radio~"/selected/digit4",digit4);
	setprop("instrumentation/"~radio~"/selected/digit5",digit5);

	var standby=getprop("/instrumentation/"~radio~"/frequencies/standby-mhz");
	var formatted=sprintf("%.02f",standby);

	digit1=substr(formatted,0,1);
	digit2=substr(formatted,1,1);
	digit3=substr(formatted,2,1);
	digit4=substr(formatted,4,1);
	digit5=substr(formatted,5,1);
	
	setprop("instrumentation/"~radio~"/standby/digit1",digit1);
	setprop("instrumentation/"~radio~"/standby/digit2",digit2);
	setprop("instrumentation/"~radio~"/standby/digit3",digit3);
	setprop("instrumentation/"~radio~"/standby/digit4",digit4);
	setprop("instrumentation/"~radio~"/standby/digit5",digit5);

} 


calcDigits = func( v, prop, ndigit ) {
    v = int( v );
    for( var i = 0; i < ndigit ; i=i+1 ) {
        v2 = int( v / 10 );
        r = v - v2 * 10;
        setprop( prop~i, r );
        v = v2;
    }
}

var calcHoursMeter = func (dt){
  if( rpmN.getValue() > 100.0 ) {
    hmHobbs.start();
  } else {
    hmHobbs.stop();
  }
  calcDigits( int(getprop("instrumentation/hobbs-meter/time") / 360), "instrumentation/hobbs-meter/digits", 5);
}

var isILS=func(freq) {
  if(freq < 108.1) return 0;
  if(freq > 111.95) return 0;
  var bar=int((freq+0.001)*10)-int(freq)*10;
#print("int((freq+0.001)*10)=", int((freq+0.001)*10));
  return(bits.test(bar,0));
}


var update = func {
	time = getprop("/sim/time/elapsed-sec");
	dt = time - last_time;
	last_time = time;

	oil_pressure();
#    fuel_pressure();
#	doFuel();
	radiodisplay("comm[0]");
	radiodisplay("nav[1]");
	calcHoursMeter( dt );
	doLight();
	settimer(update,0);
}


#/engines/engine/
#       bool  running = false
#     double  rpm = 0
#     double  mp-osi = 25.7305231334419
#     double  oil-pressure-psi = 17.8623525141355
#     double  oil-temperature-degf = 56.3910618982242
#     double  cht-degf = 31.6251680229857
#     double  thrust_lb = -0
#     double  fuel-flow-gph = 0
#       bool  cranking = false
#     double  egt-degf = 37.7643843034079
#     double  fuel-flow_pph = 0
#       bool  starter = false
#     double  fuel-consumed-lbs = 0
#       bool  out-of-fuel = false
#     double  oil-temp-norm = 0
#     double  amp-v = 0







