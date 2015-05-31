private ["_spawnLocations","_spawnLocation","_spawnPos","_grp","_ret","_heli","_heliGrp","_score"];
if (currentSideMission != "none") exitWith {systemChat "Sidemission has already been chosen!"};

[{
	titleCut ["","BLACK IN", 0];
	currentSideMission = "baseDef";
	publicVariable "currentSideMission";
	attackingUnits = 100;
	currentSideMissionStatus = "ip";
	publicVariable "currentSideMissionStatus";
	if (isServer) then {
		attackingUnits = 0;
	//server
		_spawnLocations = [(targetLocations select 0), (targetLocations select 1)];


		for "_i" from 1 to 4 do {
			_spawnLocation = _spawnLocations call BIS_fnc_selectRandom;
			_spawnPos = [position _spawnLocation, 10, 300, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			_grp = [_spawnPos, EAST, (configFile >> "CfgGroups" >> "EAST" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam")] call EVO_fnc_spawnGroup;
			if (HCconnected) then {
				{
					handle = [_x] call EVO_fnc_sendToHC;
				} forEach units _grp;
			};
			{

				_x AddMPEventHandler ["mpkilled", {
					attackingUnits = attackingUnits - 1;
					publicVariable "attackingUnits";
				}];
				attackingUnits = attackingUnits + 1;
			}  forEach units _grp;
			handle = [_grp, getPos spawnBuilding] call BIS_fnc_taskAttack;
		};
		for "_i" from 1 to 2 do {
			_spawnPos = [getPos server, 10, 500, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			_grp = [_spawnPos, EAST, (configFile >> "CfgGroups" >> "EAST" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad_Weapons")] call EVO_fnc_spawnGroup;
			if (HCconnected) then {
				{
					handle = [_x] call EVO_fnc_sendToHC;
				} forEach units _grp;
			};
			{

				_x AddMPEventHandler ["mpkilled", {
					attackingUnits = attackingUnits - 1;
				}];
				attackingUnits = attackingUnits + 1;
			}  forEach units _grp;
			publicVariable "attackingUnits";
			   _spawnPos = [getPos server, 10, 500, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			   _ret = [_spawnPos, (floor (random 360)), "O_Heli_Light_02_unarmed_F", EAST] call EVO_fnc_spawnvehicle;
			   _heli = _ret select 0;
			   _heliGrp = _ret select 2;
			   if (HCconnected) then {
				{
					handle = [_x] call EVO_fnc_sendToHC;
				} forEach units _heliGrp;
			};
			   {
			   		_x assignAsCargo _heli;
			   		_x moveInCargo _heli;
			   } forEach units _grp;
			   //_heli doMove (getPos spawnBuilding);
			   _wp = _heliGrp addWaypoint [getPos spawnBuilding, 0];
			   _heli flyInHeight 150;
			   waitUntil {(_heli distance (getPos spawnBuilding)) < 500};
			   sleep random 10;
			   handle = [_heli] call EVO_fnc_paradrop;
			   sleep 5;
			   //_heli doMove (getPos server);
			   _wp = _heliGrp addWaypoint [getPos server, 0];
			   handle = [_heli] spawn {
			   	_heli = _this select 0;
			   	waitUntil {(_heli distance server) < 1000};
			   	{
			   		deleteVehicle _x;
			   	} forEach units group driver _heli;
			   	deleteVehicle _heli;
			};
			handle = [_grp, getPos spawnBuilding] call BIS_fnc_taskAttack;
		};

		handle = [] spawn {
			waitUntil {attackingUnits < 2};
			sleep (random 15);
			currentSideMission = "none";
			publicVariable "currentSideMission";
			currentSideMissionStatus = "success";
			publicVariable "currentSideMissionStatus";
			[baseDefTask, "Succeeded", false] call bis_fnc_taskSetState;
			handle = [] spawn EVO_fnc_buildSideMissionArray;
		};
		_tskDisplayName = format ["Defend NATO Staging Base"];
		baseDefTask = format ["baseDefTask_%1", floor(random(1000))];
		[WEST, [baseDefTask], [_tskDisplayName, _tskDisplayName, ""], (getPos spawnBuilding), 1, 2, true] call BIS_fnc_taskCreate;
	};
	if (!isDedicated) then {
		//client
		"counter" setMarkerAlpha 1;
		"counter_1" setMarkerAlpha 1;
		CROSSROADS sideChat "All units be advised, we have OPFOR units closing in on the staging base! All available assets move to engage!";
		["TaskAssigned",["","Defend NATO Staging Base"]] call BIS_fnc_showNotification;
		handle = [] spawn {
			waitUntil {currentSideMissionStatus != "ip"};
			if (player distance spawnBuilding < 1000) then {
				playsound "goodjob";
				_score = player getVariable "EVO_score";
				_score = _score + 10;
				player setVariable ["EVO_score", _score, true];
				["PointsAdded",["BLUFOR completed a sidemission.", 10]] call BIS_fnc_showNotification;
			};
			sleep (random 15);
			CROSSROADS sideChat "The OPFOR counter attack has been defeated. Get back out there!";
			["TaskSucceeded",["","OPFOR Counterattack Defeated"]] call BIS_fnc_showNotification;
			currentSideMission = "none";
			publicVariable "currentSideMission";
			"counter" setMarkerAlpha 0;
			"counter_1" setMarkerAlpha 0;
		};
	};
},"BIS_fnc_spawn",true,true] call BIS_fnc_MP;