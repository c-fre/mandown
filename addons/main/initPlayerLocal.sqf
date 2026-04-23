// === Logging / Shared Helpers ===
mandown_fnc_log = {
    params ["_message"];

    diag_log text format ["[Mandown] %1", _message];
};

// === BFT Helpers ===
mandown_bft_markers = [];
mandown_bft_markerMeta = [];
mandown_bft_blinkVisible = true;

mandown_fnc_clearBftMarkers = {
    { deleteMarkerLocal _x } forEach mandown_bft_markers;
    mandown_bft_markers = [];
    mandown_bft_markerMeta = [];
};

mandown_fnc_getSideMarkerPrefix = {
    params ["_side"];

    switch (_side) do {
        case west: {"b"};
        case east: {"o"};
        case resistance: {"n"};
        default {"n"};
    };
};

mandown_fnc_isValidMarkerType = {
    params ["_markerType"];

    isClass (configFile >> "CfgMarkers" >> _markerType)
};

mandown_fnc_selectMarkerType = {
    params ["_markerTypes", "_fallbackType"];

    {
        if ([_x] call mandown_fnc_isValidMarkerType) exitWith {
            _fallbackType = _x;
        };
    } forEach _markerTypes;

    _fallbackType
};

mandown_fnc_getMedicalMarkerType = {
    params ["_side"];

    private _sideStr = [_side] call mandown_fnc_getSideMarkerPrefix;
    private _fallbackType = format ["%1_inf", _sideStr];

    [
        [format ["%1_med", _sideStr], _fallbackType],
        _fallbackType
    ] call mandown_fnc_selectMarkerType;
};

mandown_fnc_getVehicleMarkerType = {
    params ["_vehicle", "_referenceUnit"];

    private _sideStr = [side _referenceUnit] call mandown_fnc_getSideMarkerPrefix;
    private _fallbackType = format ["%1_inf", _sideStr];
    private _markerTypes = switch (true) do {
        case (_vehicle == _referenceUnit): {
            [_fallbackType]
        };
        case (_vehicle isKindOf "Air"): {
            [format ["%1_air", _sideStr], format ["%1_plane", _sideStr], _fallbackType]
        };
        case (_vehicle isKindOf "Tank"): {
            [format ["%1_armor", _sideStr], _fallbackType]
        };
        case (_vehicle isKindOf "Ship"): {
            [format ["%1_naval", _sideStr], _fallbackType]
        };
        case (_vehicle isKindOf "Car"): {
            [format ["%1_motor_inf", _sideStr], format ["%1_mech_inf", _sideStr], _fallbackType]
        };
        default {
            [_fallbackType]
        };
    };

    [_markerTypes, _fallbackType] call mandown_fnc_selectMarkerType;
};

mandown_fnc_formatOccupantLabel = {
    params ["_occupants"];

    private _separator = if ((missionNamespace getVariable ["mandown_bft_vehicleNameFormat", "multiline"]) isEqualTo "commaDelimited") then {
        ", "
    } else {
        toString [10]
    };

    (_occupants apply { name _x }) joinString _separator;
};

mandown_fnc_registerBftMarker = {
    params ["_markerName", "_position", "_markerType", "_markerColor", "_markerText", ["_shouldBlink", false]];

    private _marker = createMarkerLocal [_markerName, [_position select 0, _position select 1]];
    _marker setMarkerTypeLocal _markerType;
    _marker setMarkerColorLocal _markerColor;
    _marker setMarkerTextLocal _markerText;
    _marker setMarkerAlphaLocal (if (_shouldBlink && {!mandown_bft_blinkVisible}) then {0.2} else {1});

    mandown_bft_markers pushBack _marker;
    mandown_bft_markerMeta pushBack [_marker, _shouldBlink];
};

mandown_fnc_bftUpdate = {
    call mandown_fnc_clearBftMarkers;

    if !(missionNamespace getVariable ["mandown_bft_enabled", false]) exitWith {};
    if (isNull ACE_player || {!alive ACE_player}) exitWith {};

    private _playerSide = playerSide;
    private _displayMode = missionNamespace getVariable ["mandown_bft_displayMode", "allPlayers"];
    private _showDownedPlayers = missionNamespace getVariable ["mandown_bft_showDownedPlayers", true];
    private _markerIndex = 0;

    if (_displayMode isEqualTo "allPlayers") then {
        private _vehicles = [];
        private _vehicleOccupants = [];

        {
            private _vehicle = vehicle _x;
            private _vehicleIndex = _vehicles find _vehicle;

            if (_vehicleIndex == -1) then {
                _vehicles pushBack _vehicle;
                _vehicleOccupants pushBack [_x];
            } else {
                (_vehicleOccupants select _vehicleIndex) pushBack _x;
            };
        } forEach (allPlayers select {side _x == _playerSide && {alive _x}});

        {
            private _vehicle = _vehicles select _forEachIndex;
            private _occupants = _x;
            private _referenceUnit = _occupants select 0;
            private _anyUnconscious = _showDownedPlayers && {(_occupants findIf {_x getVariable ["ACE_isUnconscious", false]}) != -1};
            private _isSingleton = (count _occupants) == 1;
            private _isVehicleStack = _vehicle != _referenceUnit;
            private _markerType = if (_isSingleton && {_anyUnconscious} && {!_isVehicleStack}) then {
                [side _referenceUnit] call mandown_fnc_getMedicalMarkerType
            } else {
                [_vehicle, _referenceUnit] call mandown_fnc_getVehicleMarkerType
            };
            private _markerColor = if (_anyUnconscious) then {
                "ColorRed"
            } else {
                format ["Color%1", side _referenceUnit]
            };
            private _markerText = [_occupants] call mandown_fnc_formatOccupantLabel;
            private _shouldBlink = _isSingleton && {_anyUnconscious} && {!_isVehicleStack};

            [
                format ["mandown_bft_%1", _markerIndex],
                getPos _vehicle,
                _markerType,
                _markerColor,
                _markerText,
                _shouldBlink
            ] call mandown_fnc_registerBftMarker;

            _markerIndex = _markerIndex + 1;
        } forEach _vehicleOccupants;
    } else {
        private _showAllDownedInLeaderOnly = missionNamespace getVariable ["mandown_bft_showAllDownedInLeaderOnly", false];
        private _groupsToDraw = allGroups select {
            side _x == _playerSide && {((units _x) findIf {isPlayer _x}) != -1}
        };

        {
            private _group = _x;
            private _leader = leader _group;

            if !(isNull _leader) then {
                private _leaderIsUnconscious = _showDownedPlayers && {alive _leader && {_leader getVariable ["ACE_isUnconscious", false]}};
                private _markerType = if (_leaderIsUnconscious) then {
                    [side _group] call mandown_fnc_getMedicalMarkerType
                } else {
                    if (!isNil "ace_common_fnc_getMarkerType") then {
                        [_group] call ace_common_fnc_getMarkerType
                    } else {
                        [vehicle _leader, _leader] call mandown_fnc_getVehicleMarkerType
                    }
                };
                private _markerColor = if (_leaderIsUnconscious) then {
                    "ColorRed"
                } else {
                    format ["Color%1", side _group]
                };
                private _markerText = if (_leaderIsUnconscious) then {
                    name _leader
                } else {
                    groupId _group
                };

                [
                    format ["mandown_bft_%1", _markerIndex],
                    getPos _leader,
                    _markerType,
                    _markerColor,
                    _markerText,
                    false
                ] call mandown_fnc_registerBftMarker;

                _markerIndex = _markerIndex + 1;

                if (_showAllDownedInLeaderOnly && {_showDownedPlayers}) then {
                    {
                        private _markerType = if (vehicle _x == _x) then {
                            [side _x] call mandown_fnc_getMedicalMarkerType
                        } else {
                            [vehicle _x, _x] call mandown_fnc_getVehicleMarkerType
                        };
                        private _shouldBlink = vehicle _x == _x;

                        [
                            format ["mandown_bft_%1", _markerIndex],
                            getPos (vehicle _x),
                            _markerType,
                            "ColorRed",
                            name _x,
                            _shouldBlink
                        ] call mandown_fnc_registerBftMarker;

                        _markerIndex = _markerIndex + 1;
                    } forEach ((units _group) select {
                        isPlayer _x &&
                        {_x != _leader} &&
                        {alive _x} &&
                        {_x getVariable ["ACE_isUnconscious", false]}
                    });
                };
            };
        } forEach _groupsToDraw;
    };
};

mandown_fnc_bftBlinkUpdate = {
    if !(missionNamespace getVariable ["mandown_bft_enabled", false]) exitWith {};
    if (isNull ACE_player || {!alive ACE_player}) exitWith {};

    mandown_bft_blinkVisible = !mandown_bft_blinkVisible;

    {
        _x params ["_marker", "_shouldBlink"];

        if (_shouldBlink) then {
            _marker setMarkerAlphaLocal (if (mandown_bft_blinkVisible) then {1} else {0.2});
        } else {
            _marker setMarkerAlphaLocal 1;
        };
    } forEach mandown_bft_markerMeta;
};

mandown_fnc_refreshBftPfh = {
    if (!hasInterface) exitWith {};

    if (!isNil "mandown_bft_pfh") then {
        [mandown_bft_pfh] call CBA_fnc_removePerFrameHandler;
        mandown_bft_pfh = nil;
    };

    if (!isNil "mandown_bft_blinkPfh") then {
        [mandown_bft_blinkPfh] call CBA_fnc_removePerFrameHandler;
        mandown_bft_blinkPfh = nil;
    };

    call mandown_fnc_clearBftMarkers;

    if (missionNamespace getVariable ["mandown_bft_enabled", false]) then {
        mandown_bft_blinkVisible = true;
        mandown_bft_pfh = [mandown_fnc_bftUpdate, missionNamespace getVariable ["mandown_bft_interval", 5], []] call CBA_fnc_addPerFrameHandler;
        mandown_bft_blinkPfh = [mandown_fnc_bftBlinkUpdate, 0.75, []] call CBA_fnc_addPerFrameHandler;
        call mandown_fnc_bftUpdate;
    };
};

mandown_fnc_refreshBftSettings = {
    if (hasInterface) then {
        call mandown_fnc_refreshBftPfh;
    };
};

mandown_fnc_playDownSound = {
    params ["_unit", "_sound"];

    if (_sound == "none") exitWith {};

    if (!hasInterface || {isNull player} || {player == _unit}) exitWith {};
    if !(missionNamespace getVariable ["mandown_receiveDownAlerts", true]) exitWith {};

    private _rangeKm = missionNamespace getVariable ["mandown_downAlertRangeKm", 1];
    private _rangeMeters = _rangeKm * 1000;
    private _volume = missionNamespace getVariable ["mandown_receiveDownAlertVolume", 1];

    if (_rangeMeters <= 0) exitWith {};
    if ((player distance _unit) > _rangeMeters) exitWith {};
    if (_volume <= 0) exitWith {};

    playSoundUI [_sound, _volume];
};


// === Register CBA Settings ===
mandown_fnc_registerSharedSettings = {
    // --- BFT Ext. ---
    [
        "mandown_bft_interval",
        "SLIDER",
        "BFT update interval (seconds)",
        ["Mandown", "BFT Ext."],
        [1, 30, 5, 1],
        1,
        {
            call mandown_fnc_refreshBftSettings;
        },
        true
    ] call CBA_fnc_addSetting;

    [
        "mandown_bft_displayMode",
        "LIST",
        "BFT display mode",
        ["Mandown", "BFT Ext."],
        [
            ["allPlayers", "leadersOnly"],
            ["All players", "Leaders only"],
            0
        ],
        1,
        {
            call mandown_fnc_refreshBftSettings;
        }
    ] call CBA_fnc_addSetting;

    [
        "mandown_bft_vehicleNameFormat",
        "LIST",
        "Vehicle name format",
        ["Mandown", "BFT Ext."],
        [
            ["multiline", "commaDelimited"],
            ["New line per player", "Comma delimited"],
            0
        ],
        1,
        {
            call mandown_fnc_refreshBftSettings;
        }
    ] call CBA_fnc_addSetting;

    [
        "mandown_bft_showDownedPlayers",
        "CHECKBOX",
        "Show downed players on BFT",
        ["Mandown", "BFT Ext."],
        true,
        false,
        {
            call mandown_fnc_refreshBftSettings;
        }
    ] call CBA_fnc_addSetting;

    [
        "mandown_bft_showAllDownedInLeaderOnly",
        "CHECKBOX",
        "Show all downed players in leader-only mode",
        ["Mandown", "BFT Ext."],
        false,
        1,
        {
            call mandown_fnc_refreshBftSettings;
        }
    ] call CBA_fnc_addSetting;

    [
        "mandown_bft_enabled",
        "CHECKBOX",
        "Enable BFT",
        ["Mandown", "BFT Ext."],
        false,
        1,
        {
            call mandown_fnc_refreshBftSettings;
        }
    ] call CBA_fnc_addSetting;

    // --- Utilities ---
    [
        "mandown_allowDownedVoice",
        "CHECKBOX",
        "Allow downed players to speak",
        ["Mandown", "Utilities"],
        true,
        1,
        {}
    ] call CBA_fnc_addSetting;

    [
        "mandown_mapAccess",
        "CHECKBOX",
        "Allow map access while unconscious",
        ["Mandown", "Utilities"],
        true,
        1,
        {}
    ] call CBA_fnc_addSetting;

    [
        "mandown_downAlertRangeKm",
        "SLIDER",
        "Down alert range (km)",
        ["Mandown", "Utilities"],
        [0, 10, 1, 1],
        1,
        {}
    ] call CBA_fnc_addSetting;
};

mandown_fnc_registerClientSettings = {
    if (!hasInterface) exitWith {};

    [
        "mandown_soundChoice",
        "LIST",
        "Down sound",
        ["Mandown", "Utilities"],
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

    [
        "mandown_receiveDownAlerts",
        "CHECKBOX",
        "Receive down alerts",
        ["Mandown", "Utilities"],
        true,
        false,
        {}
    ] call CBA_fnc_addSetting;

    [
        "mandown_receiveDownAlertVolume",
        "SLIDER",
        "Down alert volume",
        ["Mandown", "Utilities"],
        [0, 3, 1, 2],
        false,
        {}
    ] call CBA_fnc_addSetting;
};

call mandown_fnc_registerSharedSettings;
call mandown_fnc_registerClientSettings;

if (!hasInterface) exitWith {};

call mandown_fnc_refreshBftPfh;


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

    // Sound on going down — only send from the downed player's machine so TFAR
    // Play the downed player's selected alert locally for clients that are in
    // range and have not opted out of alerts.
    if (_isUnconscious) then {
        private _sound = _unit getVariable ["mandown_soundChoice", "mandown_sos"];
        [_unit, _sound] call mandown_fnc_playDownSound;
    };

    if (missionNamespace getVariable ["mandown_bft_enabled", false]) then {
        call mandown_fnc_bftUpdate;
    };
}] call CBA_fnc_addEventHandler;
