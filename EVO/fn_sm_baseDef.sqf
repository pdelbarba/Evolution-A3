private ["_spawnLocations","_spawnLocation","_spawnPos","_grp","_ret","_heli","_heliGrp","_wp","_tskDisplayName","_score"];
if (currentSideMission != "none") exitWith {systemChat "Sidemission has already been chosen!"};

[{
	titleCut ["","BLACK IN", 0];
	currentSideMission = "baseDef";
	publicVariable "currentSideMission";
	currentSidemissionUnits = 100;
	currentSideMissionStatus = "ip";
	publicVariable "currentSideMissionStatus";
	if (isServer) then {
		currentSidemissionUnits = 0;
	//server
		_spawnLocations = [(targetLocations select 0), (targetLocations select 1)];


		for "_i" from 1 to (["Infantry", "Side"] call EVO_fnc_calculateOPFOR) do {
			_spawnPos = [(position ([_spawnLocations] call BIS_fnc_selectRandom)), 10, 300, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			//_grp = [_spawnPos, EAST, (configFile >> "CfgGroups" >> "EAST" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam")] call EVO_fnc_spawnGroup;
			handle = [_grp, getPos spawnBuilding] call BIS_fnc_taskAttack;
			{
				currentSidemissionUnits pushBack _x;
				publicVariable "currentSidemissionUnits";
				_x AddMPEventHandler ["mpkilled", {
					currentSidemissionUnits = currentSidemissionUnits - [_this select 1];
					publicVariable "currentSidemissionUnits";
				}];
			} forEach units _grp;
		};

		for "_i" from 1 to (["Armor", "Side"] call EVO_fnc_calculateOPFOR) do {
			_spawnPos = [(position ([_spawnLocations] call BIS_fnc_selectRandom)), 10, 300, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			_ret = [_spawnPos, (floor (random 360)), (["O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F", "O_UGV_01_rcws_F","O_APC_Tracked_02_cannon_F", "O_MBT_02_cannon_F", "O_APC_Wheeled_02_rcws_F"] call BIS_fnc_selectRandom), EAST] call EVO_fnc_spawnvehicle;
		    _grp = _ret select 2;
		    handle = [_grp, getPos spawnBuilding] call BIS_fnc_taskAttack;
			{
				currentSidemissionUnits pushBack _x;
				publicVariable "currentSidemissionUnits";
				_x AddMPEventHandler ["mpkilled", {
					currentSidemissionUnits = currentSidemissionUnits - [_this select 1];
					publicVariable "currentSidemissionUnits";
				}];
			} forEach units _grp;
		};

		handle = [] spawn {
			_count = 0;
			while {_loop} do {
				_count = 0;
				sleep 10;
				{
					if (alive _x && ([_x, getMarkerPos currentSidemissionUnits] call BIS_fnc_distance2D < 1000)) then {
					_count = _count + 1;
					};
				} forEach currentSidemissionUnits;
				if (_count < 6) then {
					_loop = false;
				};
			};
			if (_count > 0) then {
				{
					if ([true, false] call bis_fnc_selectRandom) then {
						[_x] spawn EVO_fnc_surrender;
					} else {
						[_x] spawn {
							_unit = _this select 0;
							_loop = true;
							while {_loop} do {
								_players = [_unit, 1000] call EVO_fnc_playersNearby;
								if (!_players || !alive _unit) then {
									_loop = false;
								};
							};
							deleteVehicle _unit;
						};
					};
				} forEach currentSidemissionUnits;
			};
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
				_score = player getVariable ["EVO_score", 0];
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