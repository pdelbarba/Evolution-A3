private ["_truck","_msg","_pos","_h","_nearVehicles","_mark","_mssg","_medmark","_crate"];

_truck = nearestObject [player, "B_Truck_01_Repair_F"];
if (isNil "_truck" || (player distance _truck > 25)) exitWith {
	_msg = format ["You can't deploy a FARP without a Repair Truck."];
	["deployed",["FARP NOT DEPLOYED", _msg]] call BIS_fnc_showNotification;
};

_pos = getPos player;

_h = nearestObject [_pos, "Land_HelipadSquare_F"];
[[_h],{
	_h = _this select 0;
	if (isServer) then
	{
		_nearVehicles = [];
		while {alive _h} do
		{
			{
				_x call EVO_fnc_rearm;
			}
			forEach ((getPos _h) nearEntities [["Car", "Tank", "Helicopter"], 2]);
			sleep 2;
		};
	};
},"BIS_fnc_spawn",true,true] call BIS_fnc_MP;



player playMoveNow "Acts_carFixingWheel";
if (!isNil "playerStructures") then {
	{
		if ((_x select 0) == PlayerCrate) then {
			EVO_vaCrates = EVO_vaCrates - [_x];
			publicVariable "EVO_vaCrates";
		};
	} forEach EVO_vaCrates;
	{
		deleteVehicle _x;
	} forEach playerStructures;
	_msg = format ["Your previous FARP has been removed."];
	["deployed",["FARP REMOVED", _msg]] call BIS_fnc_showNotification;
};


if (!isNil "playerRespawnPoint") then {
	playerRespawnPoint call BIS_fnc_removeRespawnPosition;
};


WaitUntil {animationState player != "Acts_carFixingWheel"};


if (!alive player || player distance _pos > 1) exitWith {};
_mark = format["%1FARP",(name player)];
deleteMarker _mark;
//playerStructures = [(getPos player), (getDir player), "Comps\farp.sqf", false] call (compile (preprocessFileLineNumbers "scripts\otl7_Mapper.sqf"));
playerStructures = [(getPos player), (getDir player), call (compile (preprocessFileLineNumbers ("Comps\farp.sqf")))] call BIS_fnc_ObjectsMapper;

_mssg = format["%2 %1's FARP",(name player), (rank player)];
playerRespawnPoint = [(group player), (getPos player), _mssg] call BIS_fnc_addRespawnPosition;
_medmark = createMarker [_mark, getPos player];
_medmark setMarkerShape "ICON";
_medmark setMarkerType "b_med";
_medmark setMarkerColor "ColorBlue";
_medmark setMarkerText _mssg;
_medmark setMarkerSize [1, 1];
sleep 5;
_msg = format ["Your FARP has been deployed at map grid %1.", mapGridPosition player];
["deployed",["FARP DEPLOYED", _msg]] call BIS_fnc_showNotification;
PlayerCrate = objNull;
{
	if (typeOf _x == "CargoNet_01_box_F") then {
		PlayerCrate = _x;
	};
} forEach playerStructures;
_array = [PlayerCrate, player];
EVO_vaCrates pushBack _array;
publicVariable "EVO_vaCrates";
[PlayerCrate, rank player] call EVO_fnc_buildAmmoCrate;