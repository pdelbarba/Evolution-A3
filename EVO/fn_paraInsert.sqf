private ["_spendable","_score","_txt"];
_spendable = [player] call EVO_fnc_supportPoints;

if (player getVariable ["EVOrank", "PRIVATE"] == "PRIVATE" || _spendable > 2) then {
	if (player getVariable ["EVOrank", "PRIVATE"] == "PRIVATE") then {
		null = [] execVM "ATM_airdrop\atm_airdrop.sqf";
		["PointsRemoved",["HALO insertion initiated.", 0]] call BIS_fnc_showNotification;
	} else {
		_score = player getVariable ["EVO_score", 0];
		_score = _score - 2;
		player setVariable ["EVO_score", _score, true];
		[player, -2] call BIS_fnc_addScore;
		null = [] execVM "ATM_airdrop\atm_airdrop.sqf";
		["PointsRemoved",["HALO insertion initiated.", 2]] call BIS_fnc_showNotification;
	};
} else {
	_txt = "You don't have enough points to HALO drop.";
	["notQualified",[_txt]] call BIS_fnc_showNotification;
};
