// === BFT Update Function ===
mandown_fnc_bftUpdate = {
    { deleteMarkerLocal _x } forEach mandown_bft_markers;
    mandown_bft_markers = [];

    if !(missionNamespace getVariable ["mandown_bft_enabled", false]) exitWith {};
    if (isNull ACE_player || { !alive ACE_player }) exitWith {};

    private _playerSide = playerSide;
    private _showAll = missionNamespace getVariable ["mandown_bft_showAll", true];

    if (_showAll) then {
        // Group players by vehicle so occupants share one marker
        private _vehicles = [];
        private _vehicleOccupants = [];
        {
            private _veh = vehicle _x;
            private _vehIdx = _vehicles find _veh;
            if (_vehIdx == -1) then {
                _vehicles pushBack _veh;
                _vehicleOccupants pushBack [_x];
            } else {
                (_vehicleOccupants select _vehIdx) pushBack _x;
            };
        } forEach (allPlayers select { side _x == _playerSide });

        {
            private _veh = _vehicles select _forEachIndex;
            private _occupants = _x;
            private _anyUnconscious = (_occupants findIf { _x getVariable ["ACE_isUnconscious", false] }) != -1;
            private _repUnit = _occupants select 0;
            private _sideStr = ["n", "b", "o"] select ((["GUER", "WEST", "EAST"] find str side _repUnit) max 0);

            private _markerType = if (_anyUnconscious && { count _occupants == 1 }) then {
                format ["%1_med", _sideStr]
            } else if (_veh == _repUnit) then          { format ["%1_inf",       _sideStr] }
            else if (_veh isKindOf "Air")  then { format ["%1_air",       _sideStr] }
            else if (_veh isKindOf "Tank") then { format ["%1_armor",     _sideStr] }
            else if (_veh isKindOf "Car")  then { format ["%1_motor_inf", _sideStr] }
            else                               { format ["%1_inf",       _sideStr] };

            private _label = (_occupants apply { name _x }) joinString "\n";
            private _pos = getPos _veh;

            private _marker = createMarkerLocal [format ["mandown_bft_p_%1", _forEachIndex], [_pos select 0, _pos select 1]];
            _marker setMarkerTypeLocal _markerType;
            _marker setMarkerColorLocal (if (_anyUnconscious) then { "ColorRed" } else { format ["Color%1", side _repUnit] });
            _marker setMarkerTextLocal _label;
            mandown_bft_markers pushBack _marker;
        } forEach _vehicleOccupants;
    } else {
        {
            private _grp = _x;
            private _leader = leader _grp;
            private _isUnconscious = _leader getVariable ["ACE_isUnconscious", false];
            private _sideStr = ["n", "b", "o"] select ((["GUER", "WEST", "EAST"] find str side _grp) max 0);

            private _markerType = if (_isUnconscious) then {
                format ["%1_med", _sideStr]
            } else {
                [_grp] call ace_common_fnc_getMarkerType
            };

            private _pos = getPos _leader;
            private _marker = createMarkerLocal [format ["mandown_bft_g_%1", _forEachIndex], [_pos select 0, _pos select 1]];
            _marker setMarkerTypeLocal _markerType;
            _marker setMarkerColorLocal (format ["Color%1", side _grp]);
            _marker setMarkerTextLocal (groupId _grp);
            mandown_bft_markers pushBack _marker;
        } forEach (allGroups select { side _x == _playerSide && { (units _x) findIf { isPlayer _x } != -1 } });
    };
};

mandown_bft_markers = [];


// === Register CBA Settings ===

// --- BFT Ext. ---
[
    "mandown_bft_interval",
    "SLIDER",
    "BFT update interval (seconds)",
    ["Man Down Mod", "BFT Ext."],
    [0, 30, 5, 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    "mandown_bft_showAll",
    "CHECKBOX",
    "Show all players (unchecked = leaders only)",
    ["Man Down Mod", "BFT Ext."],
    true,
    true
] call CBA_fnc_addSetting;

[
    "mandown_bft_enabled",
    "CHECKBOX",
    "Enable BFT",
    ["Man Down Mod", "BFT Ext."],
    false,
    true,
    {
        if (_this && { isNil "mandown_bft_pfh" }) then {
            mandown_bft_pfh = [mandown_fnc_bftUpdate, missionNamespace getVariable ["mandown_bft_interval", 5], []] call CBA_fnc_addPerFrameHandler;
        };
    }
] call CBA_fnc_addSetting;

// --- Utilities ---
[
    "mandown_allowDownedVoice",
    "CHECKBOX",
    "Allow downed players to speak",
    ["Man Down Mod", "Utilities"],
    true,
    false,
    {}
] call CBA_fnc_addSetting;

[
    "mandown_mapIcon",
    "CHECKBOX",
    "Show unconscious player icons on map",
    ["Man Down Mod", "Utilities"],
    true,
    false,
    {}
] call CBA_fnc_addSetting;

[
    "mandown_mapAccess",
    "CHECKBOX",
    "Allow map access while unconscious",
    ["Man Down Mod", "Utilities"],
    true,
    false,
    {}
] call CBA_fnc_addSetting;

[
    "mandown_soundChoice",
    "LIST",
    "Down sound",
    ["Man Down Mod", "Utilities"],
    [
        ["none", "mandown_fah", "mandown_ginge", "mandown_mimimi", "mandown_reverb", "mandown_sos"],
        ["None", "Fah", "Ginge", "Mimimi", "Reverb", "SOS"],
        5
    ],
    false,
    {
        player setVariable ["mandown_soundChoice", _this, true];
    }
] call CBA_fnc_addSetting;


// === Unconscious map icon for all players ===
findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw", {
    if !(missionNamespace getVariable ["mandown_mapIcon", true]) exitWith {};
    {
        if (_x getVariable ["ACE_isUnconscious", false]) then {
            (_this select 0) drawIcon [
                '\A3\ui_f\data\igui\cfg\actions\heal_ca.paa',
                [1, 0, 0, 1],
                getPosASL _x,
                24, 24, 0,
                name _x,
                1, 0.03, "TahomaB", "right"
            ];
        };
    } forEach allPlayers;
}];

// === Unconscious events ===
["ace_unconscious", {
    params ["_unit", "_isUnconscious"];

    // Map access for local player
    // ACE_canSwitchUnits is the gate inside ace_common_fnc_disableUserInput that
    // allows the ShowMap keybind to fire while input is otherwise locked by ACE.
    if (_unit == player && missionNamespace getVariable ["mandown_mapAccess", true]) then {
        player setVariable ["ACE_canSwitchUnits", _isUnconscious];
        if (!_isUnconscious) then {
            openMap [false, false];
        };
    };

    // Re-enable speaking for downed players by removing ACE's blockSpeaking reason
    if (_isUnconscious && missionNamespace getVariable ["mandown_allowDownedVoice", true]) then {
        [_unit, "blockSpeaking", "ace_unconscious", false] call ace_common_fnc_statusEffect_set;
    };

    // Sound on going down
    if (_isUnconscious) then {
        private _sound = _unit getVariable ["mandown_soundChoice", "mandown_sos"];

        if (_sound != "none") then {
            if (isClass (configFile >> "CfgPatches" >> "task_force_radio")) then {
                private _radio = [_unit] call TFAR_fnc_activeSWRadio;
                if (isNil "_radio") then {
                    _radio = [_unit] call TFAR_fnc_activeLRRadio;
                };
                if (!isNil "_radio") then {
                    [_radio, _sound] call TFAR_fnc_sendRadioSound;
                } else {
                    _unit say3D _sound;
                };
            } else {
                _unit say3D _sound;
            };
        };
    };

}] call CBA_fnc_addEventHandler;
