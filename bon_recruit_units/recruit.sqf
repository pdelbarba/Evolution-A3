// by Bon_Inf*

if(not local player) exitWith{};
_count = 0;
{
	if (!isPlayer _x) then {
		_count = _count + 1;
	};
} forEach units group player;
_count = _count + count bon_recruit_queue;
//_precount = count units group player + count bon_recruit_queue;
//if (_precount >= bon_max_units_allowed) exitWith {hint "You've reached the max allowed group size."};
if (_count >= bon_max_units_allowed) exitWith {hint "You've reached the maximum allowed group size for your rank."};


#include "dialog\definitions.sqf"
disableSerialization;


_update_queue = {
	_display = findDisplay BON_RECRUITING_DIALOG;
	_queuelist = _display displayCtrl BON_RECRUITING_QUEUE;
	_queuelist ctrlSetText format["Units queued: %1",count bon_recruit_queue];
};


_display = findDisplay BON_RECRUITING_DIALOG;
_listbox = _display displayCtrl BON_RECRUITING_UNITLIST;
_sel = lbCurSel _listbox; if(_sel < 0) exitWith{};

_unittype = bon_recruit_recruitableunits select _sel;
_typename = lbtext [BON_RECRUITING_UNITLIST,_sel];

_queuepos = 0;
_queuecount = count bon_recruit_queue;
if(_queuecount > 0) then {
	_queuepos = (bon_recruit_queue select (_queuecount - 1)) + 1;
	hint parseText format["<t size='1.0' font='PuristaMedium' color='#ef2525'>%1</t> added to queue.",_typename];
};
bon_recruit_queue = bon_recruit_queue + [_queuepos];

[] call _update_queue;


WaitUntil{_queuepos == bon_recruit_queue select 0};
sleep (1.5 * (_queuepos min 1));
hint parseText format["Processing your <t size='1.0' font='PuristaMedium' color='#ffd800'>%1</t>.",_typename];

sleep 8.5;




/********************* UNIT CREATION ********************/
_unit = objNull;

if (player distance SpawnBuilding < 1000) then {
	//_spawnPos = [getPos player, 10, 10, 10, 0, 2, 0] call BIS_fnc_findSafePos;
	_spawnPos = getPos player;
	_unit = group player createUnit [_unittype, _spawnPos, [], 0, "FORM"];
} else {
    _spawnPos = [((getPos player) select 0), ((getPos player) select 1), (((getPos player) select 2) + 200)];
	_unit = group player createUnit [_unittype, [_spawnPos select 0, _spawnPos select 1, 200], [], 0, "FORM"];
    _unit allowdamage false;
    waitUntil {(position _unit select 2) <= 75};
    _chute = createVehicle ["Steerable_Parachute_F", position _unit, [], (random 10), 'FLY'];
    _chute setPos (getPos _unit);
    _unit assignAsDriver _chute;
    _unit moveIndriver _chute;
    _unit DoMove (getPos leader group _unit);
    _unit allowdamage true;
	[_unit] spawn {
	    _unit = _this select 0;
	    (vehicle _unit) allowDamage false;// Set parachute invincible to prevent exploding if it hits buildings
	    waitUntil {isTouchingGround _unit || (position _unit select 2) < 1 };
	    _unit allowDamage false;
	    _unit action ["EJECT", vehicle _unit];
	    _unit setvelocity [0,0,0];
	    sleep 1;// Para Units sometimes get damaged on landing. Wait to prevent this.
	    _unit allowDamage true;
	};
};
_unit setRank "PRIVATE";
[[[_unit], {
	_unit = _this select 0;
	_unit addEventHandler ["HandleScore", {
		_ai = _this select 0;
		_source = _this select 1;
		_scoreToAdd = _this select 2;
		_player = leader group _ai;
		_score = _player getVariable ["EVO_score", 0];
		_score = _score + _scoreToAdd;
		_player setVariable ["EVO_score", _score, true];
		[_player, _scoreToAdd] call bis_fnc_addScore;
		if (EVO_Debug) then {
			systemChat format ["%1 got points from %2. Sending points to %3.", _ai, _source, _player];
		};
	}];
}], "BIS_fnc_spawn", false] call BIS_fnc_MP;
[_unit] execVM (BON_RECRUIT_PATH+"init_newunit.sqf");
/*******************************************************/




//hint parseText format["Your <t size='1.0' font='PuristaMedium' color='#008aff'>%1</t> %2 has arrived.",_typename,name _unit];
_msg = format["Your <t size='1.0' font='PuristaMedium' color='#008aff'>%1</t> %2 has arrived.",_typename,name _unit];
["deployed",["REINFORCEMENTS", _msg]] call BIS_fnc_showNotification;
bon_recruit_queue = bon_recruit_queue - [_queuepos];

[] call _update_queue;
