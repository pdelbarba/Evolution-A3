private ["_location","_aaMarker","_spawnPos","_grp","_null","_eastUnits","_allUnits","_score"];
if (currentSideMission != "none") exitWith {systemChat "Sidemission has already been chosen!"};

[{
	titleCut ["","BLACK IN", 0];
	currentSideMission = "attackMil";
	publicVariable "currentSideMission";
	currentSideMissionStatus = "ip";
	publicVariable "currentSideMissionStatus";
	if (isServer) then {
	//server
		_location = attackMilTarget;
		currentSideMissionMarker = format ["sidemission_%1", markerCounter];
		_aaMarker = createMarker [currentSideMissionMarker, position _location ];
		currentTargetMarkerName setMarkerShape "ELLIPSE";
		currentTargetMarkerName setMarkerBrush "Border";
		currentSideMissionMarker setMarkerSize [250, 250];
		currentSideMissionMarker setMarkerColor "ColorEAST";
		currentSideMissionMarker setMarkerPos (position _location);
		markerCounter = markerCounter + 1;
		publicVariable "currentSideMissionMarker";
		for "_i" from 1 to 5 do {
			_spawnPos = [position _location, 10, 300, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			_grp = [_spawnPos, EAST, (configFile >> "CfgGroups" >> "EAST" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam")] call EVO_fnc_spawnGroup;
			{
			if (HCconnected) then {
				handle = [_x] call EVO_fnc_sendToHC;
			};
			curreSidemissionUnits pushBack _x;
			publicVariable "curreSidemissionUnits";

			_x AddMPEventHandler ["mpkilled", {
					curreSidemissionUnits = curreSidemissionUnits - [_this select 1];
					publicVariable "curreSidemissionUnits";
				}];
		} forEach units _grp;
			_null = [(leader _grp), currentSideMissionMarker, "RANDOM", "NOSMOKE", "DELETE:", 80, "SHOWMARKER"] execVM "scripts\UPSMON.sqf";
		};
		if ([true, false] call bis_fnc_selectRandom) then {
			_spawnPos = [position _location, 10, 300, 10, 0, 2, 0] call BIS_fnc_findSafePos;
			_ret = [_spawnPos, (floor (random 360)), (["O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F", "O_UGV_01_rcws_F","O_APC_Tracked_02_cannon_F", "O_MBT_02_cannon_F", "O_APC_Wheeled_02_rcws_F"] call BIS_fnc_selectRandom), EAST] call EVO_fnc_spawnvehicle;
		    _tank = _ret select 0;
		    _grp = _ret select 2;
		    {
				if (HCconnected) then {
					handle = [_x] call EVO_fnc_sendToHC;
				};
				curreSidemissionUnits pushBack _x;
				publicVariable "curreSidemissionUnits";
				_x AddMPEventHandler ["mpkilled", {
					curreSidemissionUnits = curreSidemissionUnits - [_this select 1];
					publicVariable "curreSidemissionUnits";
				}];
			} forEach units _grp;
			_null = [(leader _grp), currentSideMissionMarker, "RANDOM", "NOSMOKE", "DELETE:", 80, "SHOWMARKER"] execVM "scripts\UPSMON.sqf";
		};
		handle = [] spawn {
			_loop = true;
			_count = 0;
			while {_loop} do {
				_count = 0;
				sleep 10;
				{
					if (alive _x) then {
						_count = _count + 1;
					};
				} forEach curreSidemissionUnits;
				if (_count < 9) then {
					_loop = false;
				};
			};
			sleep (random 15);
			[attackMilTask, "Succeeded", false] call bis_fnc_taskSetState;
			currentSideMissionStatus = "success";
			publicVariable "currentSideMissionStatus";
			currentSideMission = "none";
			publicVariable "currentSideMission";
			handle = [] spawn EVO_fnc_buildSideMissionArray;
			deleteMarker currentSideMissionMarker;
		};
		_tskDisplayName = format ["Attack OPFOR Installation"];
		attackMilTask = format ["attackMilTask%1", floor(random(1000))];
		[WEST, [attackMilTask], [_tskDisplayName, _tskDisplayName, ""], (position attackMilTarget), 1, 2, true] call BIS_fnc_taskCreate;
	};
	if (!isDedicated) then {
	//client
		["TaskAssigned",["","Attack OPFOR Installation"]] call BIS_fnc_showNotification;
		CROSSROADS sideChat "All units be advised, forward scouts report OPFOR activity at a military installation. Capture the military installation!";
		handle = [] spawn {
			waitUntil {currentSideMissionStatus != "ip"};
			if (player distance attackMilTarget < 1000) then {
				playsound "goodjob";
				_score = player getVariable "EVO_score";
				_score = _score + 10;
				player setVariable ["EVO_score", _score, true];
				["PointsAdded",["You completed a sidemission.", 10]] call BIS_fnc_showNotification;
			};
			sleep (random 15);
			CROSSROADS sideChat "Forward scouts report OPFOR activity at the military installation is declining. Nice job men!";
			["TaskSucceeded",["","OPFOR Installation Seized"]] call BIS_fnc_showNotification;
			currentSideMission = "none";
			publicVariable "currentSideMission";
		};
	};
},"BIS_fnc_spawn",true,true] call BIS_fnc_MP;