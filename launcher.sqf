/* launcher.sqf - Use a vehicle to launch other vehicles or objects across the map!
1. Add to init.sqf:		[] execVM "launcher.sqf";
2. Create vehicle in the editor named "Sochor" on the Empty side/faction, preferably armored and tracked with a turret (for example the mobile artillery Sochor tank)
3. Create vehicle in the editor named "Plutonium" on the Empty side/faction, preferably an emptied-out ammo box/crate
4. Define which playable units can have access to the launcher in the array on line 9; use the names you gave them in the in-game editor
Watch the tutorial on usage here: https://www.youtube.com/watch?v=-ZZ7Vm_qLpU
*/

commanders_str = [ "a1", "b1", "cmd", "c1", "c2", "c3", "c4", "r1", "r2", "d1" ];
is_cmd = ( vehicleVarName player ) in commanders_str;

count_nukes = 0;
publicVariable "count_nukes";

geiger_time = true;

plutonium spawn {
	sleep 300;
	while { geiger_time } do {
		if ( random ( player distance _this ) < 5 ) then {
			playSound "ReadoutClick"; 
		};
		sleep 0.01;
	};
};

//Plutonium task checker
[] spawn {
	waitUntil {
		sleep 3;
		_check_dis = Sochor distance plutonium;
		_close_nuff = _check_dis < 300;
		if ( _close_nuff ) then {
			//[ "fifthtask", "succeeded" ] call FHQ_TT_setTaskState;
			nuke_locked = false;
			publicVariable "nuke_locked";
			geiger_time = false;
			publicVariable "geiger_time";
		};
	};
	"end_mission" call CBA_fnc_globalEvent;
};

dirty_nuke = {
	_nuke = _this select 0;

	//Set variables because of scope
	_pos_center = 0;
	_pos_x = 0;
	_pos_y = 0;
	_pos_z = 0;
	
	waitUntil {
		_pos_center = getPos _nuke;
		_pos_x = _pos_center select 0;
		_pos_y = _pos_center select 1;
		_pos_z = _pos_center select 2;
		
		_pos_z < 4
	};
	
	deleteVehicle _nuke;
	
	_center = [ _pos_x, _pos_y, 0 ];
	
	"Bo_GBU12_LGB" createVehicle _center;
	
	_radius = 100;
	_quantity = 9;
	
	_steps = _quantity - 1;
	_slices = 360 / _quantity;
	
	for "_j" from 0 to _steps step 1 do {
		_direction = _j * _slices;
		_bomb_pos = [ _center, _radius, _direction ] call BIS_fnc_relPos;
		"Bo_GBU12_LGB" createVehicle _bomb_pos;
	};
};

types_array = [
	"Land_Pod_Heli_Transport_04_covered_F",
	"O_Static_Designator_02_F",
	"Land_Pod_Heli_Transport_04_fuel_F" //nuke
];

set_array = [
	[ [ 0, 1, 2.5 ], [ 0, 3, -0.25 ] ],
	[ [ 0, 0.11, -1.25 ], [ 0, 2.75, 3.65 ] ],
	[ [ 0, 1, 2.5 ], [ 0, 3, -0.25 ] ]
];

//Killzone_kid's parachute script: http://killzonekid.com/arma-scripting-tutorials-epic-armour-drop/
if (!isDedicated) then {
    KK_fnc_FX = {
        private "_veh";
        _veh = _this select 0;
        _vel = _this select 1;
        for "_i" from 1 to 100 do {
            drop [
                ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 7, 48],
                "",
                "Billboard",
                0, 
                1 + random 0.5,
                [0, -2, 1.5],
                [-20 + random 40, -20 + random 40, -15 + _vel],
                1,
                0.05,
                0.04,
                0, 
                [0.5, 10 + random 20],
                [
                    [0,0,0,1],
                    [0,0,0,0.3],
                    [1,1,1,0.1],
                    [1,1,1,0.03],
                    [1,1,1,0.01],
                    [1,1,1,0.003],
                    [1,1,1,0.001],
                    [1,1,1,0]
                ],
                [1],
                0.1,
                0.1,
                "",
                "",
                _veh,
                random 360,
                true,
                0.1
            ];
        };
    };
    "#FX" addPublicVariableEventHandler {_this select 1 spawn KK_fnc_FX};
};
if (isServer) then {
    KK_fnc_paraDrop = {
        private ["_class","_para","_paras","_p","_veh","_vel","_time"];
        _class = format [
            "%1_parachute_02_F", 
            toString [(toArray faction _this) select 0]
        ];
        _para = createVehicle [_class, [0,0,0], [], 0, "FLY"];
        _para setDir getDir _this;
        _para setPos getPos _this;
        _paras =  [_para];
		
		_type_of = typeOf _this;
		switch ( _type_of ) do {
			case "Land_Pod_Heli_Transport_04_covered_F" : { _this attachTo [_para, [0,0,0]]; };
			case "O_Static_Designator_02_F" : { _this attachTo [_para, [0,1,2.5]]; };
			case "Land_Pod_Heli_Transport_04_fuel_F" : { _this attachTo [_para, [0,0,0]]; };
		};
        
        {
            _p = createVehicle [_class, [0,0,0], [], 0, "FLY"];
            _paras set [count _paras, _p];
            _p attachTo [_para, [0,0,0]];
            _p setVectorUp _x;
        } count [
            [0.5,0.4,0.6],[-0.5,0.4,0.6],[0.5,-0.4,0.6],[-0.5,-0.4,0.6]
        ];
        0 = [ _this, _paras, _type_of ] spawn {
            _veh = _this select 0;
			_type_of = _this select 2;
			
			switch ( _type_of ) do {
				case "Land_Pod_Heli_Transport_04_covered_F" : { sleep 10; }; //waitUntil {getPos _veh select 2 < 4};
				case "O_Static_Designator_02_F" : { sleep 10; }; //waitUntil {getPos _veh select 2 < 15};
				case "Land_Pod_Heli_Transport_04_fuel_F" : { sleep 1; [_veh] spawn dirty_nuke; };
			};
			
            _vel = velocity _veh;
            detach _veh;
            _veh setVelocity _vel;
            missionNamespace setVariable ["#FX", [_veh, _vel select 2]];
            publicVariable "#FX";
            playSound3D [
                "a3\sounds_f\weapons\Flare_Gun\flaregun_1_shoot.wss",
                _veh
            ];
            {
                detach _x;
                _x disableCollisionWith _veh;   
            } count (_this select 1);
            _time = time + 60;
            waitUntil {time > _time};
            {
                if (!isNull _x) then {deleteVehicle _x};
            } count (_this select 1);
        };
    };
};

if ( isServer ) then {
	_launcherinfo = createMarker [ "launcherstuff", [ 10000, 19500, 0 ] ];
	_launcherinfo setMarkerShape "ICON";
	_launcherinfo setMarkerType "hd_dot";
	_launcherinfo setMarkerColor "ColorOPFOR";
	_launcherinfo setMarkerText "# = Nth launched vehicle, PDT = Parachute deployment time, HAT = Height above terrain (at time of parachute deployment)";
	
	_launcherinfo2 = createMarker [ "launcherstuff2", [ 10000, 19000, 0 ] ];
	_launcherinfo2 setMarkerShape "ICON";
	_launcherinfo2 setMarkerType "hd_dot";
	_launcherinfo2 setMarkerColor "ColorOPFOR";
	_launcherinfo2 setMarkerText "A = Azimuth (degrees), E = Launcher turret elevation (degrees), BP = Boost power (percent), LL = Launch length (seconds)";
	
	clearWeaponCargoGlobal sochor;
	clearMagazineCargoGlobal sochor;
	clearItemCargoGlobal sochor;
};

enableEngineArtillery false;

launching = false;
launcher_locked = true;
nuke_locked = true;
launch_count = 0;
launch_power = 50;
launch_length = 10;

/* [ "jip_unlock", {
	// if ( is_cmd ) then { hintSilent "Twenty minutes elapsed. Launcher has been automatically unlocked for JIP players."; };
	launcher_locked = false;
	publicVariable "launcher_locked";
} ] call CBA_fnc_addEventHandler; */

//Ensure players don't get killed in transit, and hand over control of the launch to the server
[ "launch_go", {
	_veh = _this select 0;
	_sdv = _this select 1;
	_velocity = _this select 2;
	_launchpower = _this select 3;
	_launchlength = _this select 4;
	_azi = _this select 5;
	_elevation = _this select 6;
	
	_veh setVelocity _velocity;

	[ "crew_survive", [ _veh ] ] call CBA_fnc_globalEvent;
	
	if ( isServer ) then {
		[ _veh, _launchpower, _launchlength, _azi, _elevation, _sdv ] spawn {
			launch_count = launch_count + 1;
			_veh = _this select 0;
			_launchpower = _this select 1;
			_launchlength = _this select 2;
			_azi = _this select 3;
			_elevation = _this select 4;
			_sdv = _this select 5;
			
			_elevation = _elevation - 0.15; //Correction because it's slightly off from displayed elevation inside the sochor. Averaged several attempts for approximation.

			sleep _launchlength;

			_marker_name = "launch_" + str launch_count;
			_markerstr = createMarker [ _marker_name, position _veh ];
			_markerstr setMarkerShape "ICON";
			_markerstr setMarkerType "hd_dot";
			_markerstr setMarkerColor "ColorOPFOR";

			_time24 = [ daytime, "HH:MM:SS" ] call BIS_fnc_timeToString;
			_height = getPosATL _veh select 2;
			
			_markerstr setMarkerText "#" + str launch_count + ", PDT:" + _time24 + ", HAT:" + str _height + " // A:" + str _azi + ", E:" + str _elevation + ", BP:" + str _launchpower + ", LL:" + str _launchlength;
			
			_grid_pos = mapGridPosition position _veh;
			
			_name_briefing = "Launch #" + str launch_count;
			_text_briefing = "Launch # " + str launch_count + ", <br/>Grid Coordinates: " + _grid_pos + ", <br/>Parachute Deployment Time: " + _time24 + ", <br/>Height Above Terrain: " + str _height + ", <br/>Azimuth: " + str _azi + ", <br/>Elevation: " + str _elevation + ", <br/>Boost Power: " + str _launchpower + ", <br/>Launch Length: " + str _launchlength;

			[ east, { true }, [ "Launcher", _name_briefing, _text_briefing ] ] call FHQ_TT_addBriefing;
			
			_veh call KK_fnc_paraDrop;
			
			_sdv spawn {
				_low_enough = false;
				_sdv = _this;
				waitUntil {
					sleep 0.5;
					_height = getPosATL _sdv select 2;
					_is_low = _height < 4;
					if ( _is_low ) then {
						_low_enough = true;
						sleep 1;
						deleteVehicle _sdv;
					};
					_low_enough
				};
			};
			
			sleep 300;
			
			deleteMarker _markerstr;
		};
	};
} ] call CBA_fnc_addEventHandler;

if ( is_cmd ) then { launcher_locked = false; };

//Allow only commander in the sochor, unless it's unlocked.
sochor addEventHandler [ "GetIn", {
	_unit = _this select 2;
	_is_cmd = _unit == cmd;
	if ( _is_cmd ) exitWith {};
	
	_get_out = launcher_locked;
	if ( _get_out ) then {
		_unit action [ "Eject", vehicle _unit ];
	};
} ];

prep_launcher = {
	_launcher = _this select 0;
	launch_artist = _this select 1;
	_type_bought = _this select 3 select 0;
	
	_is_bikes = _type_bought == "C_Quadbike_01_F";
	_is_transport = _type_bought == "Land_Pod_Heli_Transport_04_covered_F";
	_is_designator = _type_bought == "O_Static_Designator_02_F";
	_is_bomb = _type_bought == "Land_Pod_Heli_Transport_04_fuel_F";

	if ( launcher_locked ) exitWith {
		hintSilent "You are not authorized to use the launcher controls. Ask a commander to initiate launch or to unlock it for you.";
		playSound "FD_CP_Not_Clear_F";
	};
	
	if ( _is_bomb && { nuke_locked } ) exitWith {
		_msg = "Not enough weapons-grade plutonium available for dirty bomb.";
		hintSilent _msg;
		playSound "FD_CP_Not_Clear_F";
	};
	
	_too_many_nukes = count_nukes > 1;
	if ( _is_bomb && { _too_many_nukes } ) exitWith {
		_msg = "We used up all the weapons-grade plutonium.";
		hintSilent _msg;
		playSound "FD_CP_Not_Clear_F";
	};
	
	if ( _is_designator && { isNil "uav_array" } ) exitWith {
		_msg = "No UAV Operator present in mission. Cannot launch remote designator.";
		hintSilent _msg;
		playSound "FD_CP_Not_Clear_F";
	};

	if ( launching ) exitWith {
		_msg = "Launcher not clear! Try again after pod is launched. Current pod is controlled by " + name launch_artist + ".";
		hintSilent _msg;
		playSound "FD_CP_Not_Clear_F";
	};
	
	if !( is_cmd ) exitWith {
		playSound "FD_CP_Not_Clear_F";
		hintSilent "You are not authorized to purchase anything, silly goy!"
	};
	
	launching = true;
	publicVariable "launching";
	
	publicVariable "launch_artist";
	
	_veh = createVehicle [ "I_SDV_01_F", [ 0, 0, 0 ], [], 0, "CAN COLLIDE" ];
	_veh animate ["door_1_1",0];
	_veh animate ["door_1_2",0];
	_veh animate ["door_2_1",0];
	_veh animate ["door_2_2",0];
	
	_pod = 0;
	
	if ( _is_bikes ) then {
		_pod = createVehicle [ _type_bought, [ 0, 2.5, 0 ], [], 0, "CAN COLLIDE" ];
		//_pod lock true;
	};
	
	if ( _is_transport ) then {
		_pod = createVehicle [ _type_bought, [ 0, 2.5, 0 ], [], 0, "CAN COLLIDE" ];
	};
	
	if ( _is_designator ) then {
		_pod_array = [ [ 0, 2.5, 0 ], 0, _type_bought, RESISTANCE ] call BIS_fnc_spawnVehicle;
		_pod = _pod_array select 0;
	};
	
	if ( _is_bomb ) then {
		count_nukes = count_nukes + 1;
		publicVariable "count_nukes";
		_pod = createVehicle [ _type_bought, [ 0, 2.5, 0 ], [], 0, "CAN COLLIDE" ];
	};
	
	_veh allowDamage false;
	_pod allowDamage false;
	_veh lock true;
	
	if ( _is_bikes ) then { _pod spawn { sleep 0.1; [ _this, [ "white", 1 ], [] ] call BIS_fnc_initVehicle; }; };
	if ( _is_transport || _is_bomb ) then { _pod spawn { sleep 0.1; [ _this, [ "black", 1 ], [] ] call BIS_fnc_initVehicle; }; };
	if ( _is_designator ) then { uav connectTerminalToUAV _pod };
	
	_cl_red = "Chemlight_red" createVehicle ( getPos _veh );
	_cl_red attachTo [ _veh, [ 0, 0, -1 ] ];
	
	_array_index = types_array find _type_bought;
	_set_here = set_array select _array_index select 0;
	_set_there = set_array select _array_index select 1;
	
	//Thanks PabstMirror
	_gunGunBeg = getText ( configfile >> "CfgVehicles" >> ( typeOf _launcher ) >> "Turrets" >> "MainTurret" >> "gunBeg" );
	_pod attachTo [ _launcher, _set_there, _gunGunBeg ];
	_veh attachTo [ _pod, _set_here ];
	
	{
		clearWeaponCargoGlobal _x;
		clearMagazineCargoGlobal _x;
		clearItemCargoGlobal _x;
		clearBackpackCargoGlobal _x;
	} forEach [ _pod, _veh ];
	
	[ _launcher, _pod ] spawn {
		_launcher = _this select 0;
		_pod = _this select 1;
	
		_loop_done = false;
		waitUntil {
			sleep 0.01;
			if ( isNull attachedTo _pod ) exitWith {};
			
			_gunGunBeg = getText ( configfile >> "CfgVehicles" >> ( typeOf _launcher ) >> "Turrets" >> "MainTurret" >> "gunBeg" );
			_gunGunEnd = getText ( configfile >> "CfgVehicles" >> ( typeOf _launcher ) >> "Turrets" >> "MainTurret" >> "gunEnd" );
			_posBeg = _launcher selectionPosition _gunGunBeg;
			_posEnd = _launcher selectionPosition _gunGunEnd;
			_dirVector = [ _posEnd, _posBeg ] call BIS_fnc_vectorFromXToY;
			_dir = ( _dirVector select 0 ) atan2 ( _dirVector select 1 );
			_upVector = [0, ( _dirVector select 2 ), 1 * ( ( ( cos _dir ) * ( _dirVector select 1 ) ) + ( ( sin _dir ) * ( _dirVector select 0 ) ) ) ];
			_pod setVectorDirAndUp [ _dirVector, _upVector ];
		
			if  ( !launching ) then { _loop_done = true; };
			_loop_done
		};
	};

	playSound3D [ "a3\sounds_f\sfx\doors\ServoRamp\ServoRampSound_1.wss", Sochor ];
	
	[ _pod, _cl_red, _veh ] spawn {
		_pod = _this select 0;
		_cl_red = _this select 1;
		_veh = _this select 2;
		sleep 3;
		//player moveInCargo _pod;
		player addAction [ "<t color='#00FF00'>INITIATE LAUNCH SEQUENCE</t>", { call launch_now; } ];
		player setVariable [ "this_pod", _pod, false ];
		player setVariable [ "this_cl_red", _cl_red, false ];
		player setVariable [ "this_sdv", _veh, false ];
	};
};

launch_higher = {
	if ( launcher_locked ) exitWith {
		hintSilent "You are not authorized to use the launcher controls. Ask your commander to initiate launch or to unlock it for you.";
		playSound "FD_CP_Not_Clear_F";
	};
	_too_high = launch_power > 95;
	if ( _too_high ) exitWith {
		hintSilent format [ "Booster power at %1 percent.", launch_power ];
		playSound "FD_CP_Not_Clear_F";
	};
	launch_power = launch_power + 5;
	hintSilent format [ "Booster power increased to %1 percent.", launch_power ];
	playSound "FD_Finish_F";
};

launch_lower = {
	if ( launcher_locked ) exitWith {
		hintSilent "You are not authorized to use the launcher controls. Ask your commander to initiate launch or to unlock it for you.";
		playSound "FD_CP_Not_Clear_F";
	};
	_too_low = launch_power < 5;
	if ( _too_low ) exitWith {
		hintSilent format [ "Booster power at %1 percent.", launch_power ];
		playSound "FD_CP_Not_Clear_F";
	};
	launch_power = launch_power - 5;
	hintSilent format [ "Booster power decreased to %1 percent.", launch_power ];
	playSound "FD_Finish_F";
};

length_higher = {
	if ( launcher_locked ) exitWith {
		hintSilent "You are not authorized to use the launcher controls. Ask your commander to initiate launch or to unlock it for you.";
		playSound "FD_CP_Not_Clear_F";
	};
	_too_high = launch_length > 19;
	if ( _too_high ) exitWith {
		hintSilent format [ "Flight time at %1 seconds.", launch_length ];
		playSound "FD_CP_Not_Clear_F";
	};
	launch_length = launch_length + 1;
	hintSilent format [ "Flight time increased to %1 seconds.", launch_length ];
	playSound "FD_Finish_F";
};

length_lower = {
	if ( launcher_locked ) exitWith {
		hintSilent "You are not authorized to use the launcher controls. Ask your commander to initiate launch or to unlock it for you.";
		playSound "FD_CP_Not_Clear_F";
	};
	_too_low = launch_length < 6;
	if ( _too_low ) exitWith {
		hintSilent format [ "Flight time at %1 seconds.", launch_length ];
		playSound "FD_CP_Not_Clear_F";
	};
	launch_length = launch_length - 1;
	hintSilent format [ "Flight time decreased to %1 seconds.", launch_length ];
	playSound "FD_Finish_F";
};

launch_now = {
	_this_action = _this select 2;
	player removeAction _this_action;
	
	_cl_red = player getVariable "this_cl_red";
	_veh = player getVariable "this_pod";
	_sdv = player getVariable "this_sdv";
	[ _cl_red, _veh, _sdv ] spawn {
		playSound3D [ "a3\sounds_f\sfx\alarm_OPFOR.wss", Sochor ];
		sleep 1;
		playSound3D [ "a3\sounds_f\sfx\alarm_OPFOR.wss", Sochor ];
		sleep 1;
		playSound3D [ "a3\sounds_f\sfx\alarm_OPFOR.wss", Sochor ];
		sleep 1;
		playSound3D [ "a3\sounds_f\sfx\alarm_OPFOR.wss", Sochor ];
		sleep 1;
		
		_cl_red = _this select 0;
		_veh = _this select 1;
		_sdv = _this select 2;
		
		[ "say_song", [ _veh ] ] call CBA_fnc_globalEvent;
		
		_cl_yellow = "Chemlight_yellow" createVehicle ( getPos _veh );
		_cl_yellow attachTo [ _veh, [ 0, 0, -0.5 ] ];
		sleep 4;
		
		deleteVehicle _cl_red;
		sleep 1;
		
		playSound3D [ "a3\sounds_f\sfx\siren.wss", Sochor ];
		_cl_green = "Chemlight_green" createVehicle ( getPos _veh );
		_cl_green attachTo [ _veh, [ 0, 0, -0.5 ] ];
		sleep 1.5;
		playSound3D [ "a3\sounds_f\sfx\siren.wss", Sochor ];
		sleep 1.5;
		
		deleteVehicle _cl_yellow;
		sleep 2;
		
		deleteVehicle _cl_green;
		launching = false;
		publicVariable "launching";
		
		_strobe = "B_IRStrobe" createVehicle ( getPos _veh );
		_strobe attachTo [ _veh, [ 0, 0, 1 ] ];

		playSound3D [ "a3\sounds_f\sfx\explosion3.wss", Sochor ];
		
		detach _veh;
		_randoms = random 10;
		_randoms = _randoms - 5;
		_dirVector = vectorDir _veh;
		_azi = getDir _veh;
		_elevation = asin ( sochor weaponDirection "mortar_155mm_amos" select 2 );
		_vector_x = _dirVector select 0;
		_vector_y = _dirVector select 1;
		_real_power = 200 + ( launch_power * 4 );
		_velocity = [ ( ( _vector_x * _real_power ) + _randoms ), ( ( _vector_y * _real_power ) + _randoms ), 100 ];

		[ "launch_go", [ _veh, _sdv, _velocity, launch_power, launch_length, _azi, _elevation ] ] call CBA_fnc_globalEvent;

		sleep 0.5;
		playSound3D [ "a3\sounds_f\ambient\thunder\thunder_01.wss", Sochor ];
	};
};

launcher_unlock = {
	launcher_locked = false;
	publicVariable "launcher_locked";
	hintSilent "Launcher has been unlocked.";
	playSound "FD_Finish_F";
};

launcher_lock = {
	launcher_locked = true;
	publicVariable "launcher_locked";
	hintSilent "Launcher has been locked.";
	if ( is_cmd ) then { launcher_locked = false; };
	playSound "FD_Finish_F";
};

sochor addAction [ "<t color='#669900'>INCREASE BOOSTER POWER</t>", { call launch_higher; }, [], 1.5, false, false ];
sochor addAction [ "<t color='#993366'>DECREASE BOOSTER POWER</t>", { call launch_lower; }, [], 1.5, false, false ];
sochor addAction [ "<t color='#853385'>INCREASE FLIGHT TIME</t>", { call length_higher; }, [], 1.5, false, false ];
sochor addAction [ "<t color='#996600'>DECREASE FLIGHT TIME</t>", { call length_lower; }, [], 1.5, false, false ];

sochor addAction [ "<t color='#990000'>PREPARE LAUNCH: Transport Pod</t>", { call prep_launcher; }, [ "Land_Pod_Heli_Transport_04_covered_F" ] ];
sochor addAction [ "<t color='#990000'>PREPARE LAUNCH: Remote Laser Designator</t>", { call prep_launcher; }, [ "O_Static_Designator_02_F" ] ];
sochor addAction [ "<t color='#990000'>PREPARE LAUNCH: Tactical Nuke</t>", { call prep_launcher; }, [ "Land_Pod_Heli_Transport_04_fuel_F" ] ];

if ( is_cmd ) then {
	lock_action = sochor addAction [ "<t color='#CC00CC'>LOCK LAUNCHER</t>", { call launcher_lock; } ];
	unlock_action = sochor addAction [ "<t color='#FFFF00'>UNLOCK LAUNCHER</t>", { call launcher_unlock; } ];
};

//Automatically unlock launcher after 20 minutes.
/* if ( isServer ) then {
	[] spawn {
		sleep 1200;
		"jip_unlock" call CBA_fnc_globalEvent;
	};
}; */
