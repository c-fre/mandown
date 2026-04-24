// === Logging / Shared Helpers ===
mandown_fnc_log = {
    params ["_message"];

    diag_log text format ["[Mandown] %1", _message];
};

mandown_downSoundValues = [
    "none",
    "mandown_fah",
    "mandown_ginge",
    "mandown_mimimi",
    "mandown_reverb",
    "mandown_sos",
    "mandown_boom",
    "mandown_cat",
    "mandown_gold",
    "mandown_laugh",
    "mandown_oof"
];

mandown_downSoundLabels = [
    "None",
    "Fah",
    "Ginge",
    "Mimimi",
    "Reverb",
    "SOS",
    "Boom",
    "Cat",
    "Gold",
    "Laugh",
    "Oof"
];

[
    format [
        "Registered down sounds: %1",
        ((mandown_downSoundValues select [1, count mandown_downSoundValues]) joinString ", ")
    ]
] call mandown_fnc_log;

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

mandown_fnc_getUnitVehicle = {
    params ["_unit"];

    private _vehicle = objectParent _unit;
    if (isNull _vehicle) then {
        _vehicle = vehicle _unit;
    };

    _vehicle
};

mandown_fnc_getUnitTeamSide = {
    params ["_unit"];

    private _side = side group _unit;
    if (_side == sideUnknown) then {
        _side = side _unit;
    };

    _side
};

mandown_fnc_getVehicleMarkerType = {
    params ["_vehicle", "_referenceUnit"];

    private _sideStr = [[_referenceUnit] call mandown_fnc_getUnitTeamSide] call mandown_fnc_getSideMarkerPrefix;
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
        case ((_vehicle isKindOf "Car") || {_vehicle isKindOf "LandVehicle"}): {
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

    if !(isClass (configFile >> "CfgMarkers" >> _markerType)) then {
        _markerType = "mil_dot";
    };

    if !(isClass (configFile >> "CfgMarkerColors" >> _markerColor)) then {
        _markerColor = "Default";
    };

    private _marker = createMarkerLocal [_markerName, [_position select 0, _position select 1]];
    _marker setMarkerShapeLocal "ICON";
    _marker setMarkerTypeLocal _markerType;
    _marker setMarkerColorLocal _markerColor;
    _marker setMarkerSizeLocal [1, 1];
    _marker setMarkerTextLocal _markerText;
    _marker setMarkerAlphaLocal (if (_shouldBlink && {!mandown_bft_blinkVisible}) then {0.2} else {1});

    mandown_bft_markers pushBack _marker;
    mandown_bft_markerMeta pushBack [_marker, _shouldBlink];
};

mandown_fnc_bftUpdate = {
    call mandown_fnc_clearBftMarkers;

    if !(missionNamespace getVariable ["mandown_bft_enabled", false]) exitWith {};
    if (isNull ACE_player || {!alive ACE_player}) exitWith {};

    private _playerSide = [player] call mandown_fnc_getUnitTeamSide;
    private _displayMode = missionNamespace getVariable ["mandown_bft_displayMode", "allPlayers"];
    private _showDownedPlayers = missionNamespace getVariable ["mandown_bft_showDownedPlayers", true];
    private _markerIndex = 0;

    if (_displayMode isEqualTo "allPlayers") then {
        private _vehicles = [];
        private _vehicleOccupants = [];

        {
            private _vehicle = [_x] call mandown_fnc_getUnitVehicle;
            private _vehicleIndex = _vehicles find _vehicle;

            if (_vehicleIndex == -1) then {
                _vehicles pushBack _vehicle;
                _vehicleOccupants pushBack [_x];
            } else {
                (_vehicleOccupants select _vehicleIndex) pushBack _x;
            };
        } forEach (allPlayers select {([_x] call mandown_fnc_getUnitTeamSide) == _playerSide && {alive _x}});

        {
            private _vehicle = _vehicles select _forEachIndex;
            private _occupants = _x;
            private _referenceUnit = _occupants select 0;
            private _anyUnconscious = _showDownedPlayers && {(_occupants findIf {_x getVariable ["ACE_isUnconscious", false]}) != -1};
            private _isSingleton = (count _occupants) == 1;
            private _isVehicleStack = _vehicle != _referenceUnit;
            private _markerType = if (_isSingleton && {_anyUnconscious} && {!_isVehicleStack}) then {
                [[_referenceUnit] call mandown_fnc_getUnitTeamSide] call mandown_fnc_getMedicalMarkerType
            } else {
                [_vehicle, _referenceUnit] call mandown_fnc_getVehicleMarkerType
            };
            private _markerColor = if (_anyUnconscious) then {
                "ColorRed"
            } else {
                format ["Color%1", [_referenceUnit] call mandown_fnc_getUnitTeamSide]
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
                private _leaderVehicle = [_leader] call mandown_fnc_getUnitVehicle;
                private _leaderInVehicle = _leaderVehicle != _leader;
                private _leaderIsUnconscious = _showDownedPlayers && {alive _leader && {_leader getVariable ["ACE_isUnconscious", false]}};
                private _markerType = if (_leaderIsUnconscious) then {
                    if (_leaderInVehicle) then {
                        [_leaderVehicle, _leader] call mandown_fnc_getVehicleMarkerType
                    } else {
                        [side _group] call mandown_fnc_getMedicalMarkerType
                    }
                } else {
                    if (_leaderInVehicle) then {
                        [_leaderVehicle, _leader] call mandown_fnc_getVehicleMarkerType
                    } else {
                        if (!isNil "ace_common_fnc_getMarkerType") then {
                            [_group] call ace_common_fnc_getMarkerType
                        } else {
                            [_leaderVehicle, _leader] call mandown_fnc_getVehicleMarkerType
                        }
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
                    getPos _leaderVehicle,
                    _markerType,
                    _markerColor,
                    _markerText,
                    false
                ] call mandown_fnc_registerBftMarker;

                _markerIndex = _markerIndex + 1;

                if (_showAllDownedInLeaderOnly && {_showDownedPlayers}) then {
                    {
                        private _unitVehicle = [_x] call mandown_fnc_getUnitVehicle;
                        private _markerType = if (_unitVehicle == _x) then {
                            [[_x] call mandown_fnc_getUnitTeamSide] call mandown_fnc_getMedicalMarkerType
                        } else {
                            [_unitVehicle, _x] call mandown_fnc_getVehicleMarkerType
                        };
                        private _shouldBlink = _unitVehicle == _x;

                        [
                            format ["mandown_bft_%1", _markerIndex],
                            getPos _unitVehicle,
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

    if (!isPlayer _unit) exitWith {};
    if (!hasInterface || {isNull player} || {player == _unit}) exitWith {};
    if !(missionNamespace getVariable ["mandown_receiveDownAlerts", true]) exitWith {};

    private _alertAudience = missionNamespace getVariable ["mandown_downAlertAudience", "sameSide"];
    if (_alertAudience isEqualTo "sameGroup") then {
        if ((group _unit) != (group player)) exitWith {};
    } else {
        if (([_unit] call mandown_fnc_getUnitTeamSide) != ([player] call mandown_fnc_getUnitTeamSide)) exitWith {};
    };

    private _rangeKm = missionNamespace getVariable ["mandown_downAlertRangeKm", 1];
    private _rangeMeters = _rangeKm * 1000;
    private _volume = missionNamespace getVariable ["mandown_receiveDownAlertVolume", 1];

    if (_rangeMeters <= 0) exitWith {};
    if ((player distance _unit) > _rangeMeters) exitWith {};
    if (_volume <= 0) exitWith {};

    playSoundUI [_sound, _volume];
};

mandown_fnc_getEffectiveDownSoundChoice = {
    private _sound = missionNamespace getVariable ["mandown_soundChoice", "mandown_sos"];

    if (missionNamespace getVariable ["mandown_forceDownSoundChoice", false]) then {
        _sound = missionNamespace getVariable ["mandown_forcedDownSoundChoice", "mandown_sos"];
    };

    _sound
};

mandown_fnc_syncLocalPlayerDownSoundChoice = {
    if (!hasInterface || {isNull player}) exitWith {};

    player setVariable ["mandown_soundChoice", call mandown_fnc_getEffectiveDownSoundChoice, true];
};

// === Downed Input / Hover Camera Helpers ===
mandown_fnc_isLocalPlayerUnconscious = {
    hasInterface && {!isNull player} && {alive player} && {player getVariable ["ACE_isUnconscious", false]}
};

mandown_fnc_getAceDisableMouseDisplay = {
    uiNamespace getVariable ["ace_common_dlgDisableMouse", displayNull]
};

mandown_fnc_isDownedInputPassthroughKey = {
    params ["_key"];

    // Keep Escape available for the pause/respawn flow while downed.
    _key isEqualTo 1
};

mandown_fnc_initDownedInputState = {
    if (isNil "mandown_downedInputMain") then {
        mandown_downedInputMain = createHashMap;
    };

    if (isNil "mandown_downedInputCombo") then {
        mandown_downedInputCombo = createHashMap;
    };
};

mandown_fnc_onDownedKeyDown = {
    params ["_key"];

    call mandown_fnc_initDownedInputState;

    private _keyPressedInfo = mandown_downedInputMain getOrDefault [_key, [false, 0], true];
    _keyPressedInfo params ["_keyPressed", "_keyPressedCount"];

    if (!_keyPressed) then {
        _keyPressedInfo set [0, true];
        _keyPressedInfo set [1, _keyPressedCount + 1];
    };

    if !(mandown_downedInputCombo getOrDefault [_key, false]) then {
        mandown_downedInputCombo set [_key, true];
    };
};

mandown_fnc_onDownedKeyUp = {
    params ["_key"];

    call mandown_fnc_initDownedInputState;

    if (mandown_downedInputCombo getOrDefault [_key, false]) then {
        mandown_downedInputCombo deleteAt _key;
    };

    private _keyPressedInfo = mandown_downedInputMain getOrDefault [_key, [false, 0]];

    if (_keyPressedInfo select 0) then {
        _keyPressedInfo set [0, false];
    };

    [{
        params ["_key"];

        if (isNil "mandown_downedInputMain") exitWith {};

        private _keyPressedInfo = mandown_downedInputMain getOrDefault [_key, [false, 0]];
        _keyPressedInfo set [1, ((_keyPressedInfo select 1) - 1) max 0];

        if (_keyPressedInfo isEqualTo [false, 0]) then {
            mandown_downedInputMain deleteAt _key;
        };
    }, _key, 0.5] call CBA_fnc_waitAndExecute;
};

mandown_fnc_isActionPressed = {
    params ["_action"];

    call mandown_fnc_initDownedInputState;

    private _return = false;

    {
        _x params ["_mainKeyArray", "_comboKeyArray", "_isDoubleTap"];
        _mainKeyArray params ["_mainDik", "_mainDevice"];

        private _comboDikPressed = if (_comboKeyArray isEqualTo []) then {
            true
        } else {
            _comboKeyArray params ["_comboDik", "_comboDevice"];
            _comboDevice == "KEYBOARD" && {mandown_downedInputCombo getOrDefault [_comboDik, false]}
        };

        _return = _comboDikPressed &&
            {_mainDevice == "KEYBOARD"} &&
            {((mandown_downedInputMain getOrDefault [_mainDik, [false, 0]]) select 1) > (parseNumber _isDoubleTap)};

        if (_return) exitWith {};
    } forEach (actionKeysEx _action);

    _return
};

mandown_fnc_isAnyActionPressed = {
    params ["_actions"];

    private _return = false;
    {
        if ([_x] call mandown_fnc_isActionPressed) exitWith {
            _return = true;
        };
    } forEach _actions;

    _return
};

mandown_fnc_restoreDownedInputLock = {
    if (call mandown_fnc_isLocalPlayerUnconscious) then {
        ["unconscious", true] call ace_common_fnc_setDisableUserInputStatus;
    };
};

mandown_fnc_markDownedInputHandled = {
    missionNamespace setVariable ["mandown_downedInputLastHandled", diag_tickTime];
};

mandown_fnc_wasDownedInputRecentlyHandled = {
    (diag_tickTime - (missionNamespace getVariable ["mandown_downedInputLastHandled", -1])) < 0.15
};

mandown_fnc_attachDownedHoverCameraInput = {
    if (!hasInterface) exitWith {};
    if (isNil "mandown_downedHoverCamera") exitWith {};

    private _display = findDisplay 46;
    if (isNull _display) exitWith {};
    if (_display getVariable ["mandown_hoverCameraInputAttached", false]) exitWith {};

    _display setVariable ["mandown_hoverCameraInputAttached", true];
    mandown_downedHoverCameraMouseEh = _display displayAddEventHandler ["MouseMoving", {
        _this call mandown_fnc_onDownedHoverCameraMouse
    }];
    mandown_downedHoverCameraKeyDownEh = _display displayAddEventHandler ["KeyDown", {
        _this call mandown_fnc_onDownedHoverCameraKeyDown
    }];
    mandown_downedHoverCameraKeyUpEh = _display displayAddEventHandler ["KeyUp", {
        params ["", "_key"];

        if ([_key] call mandown_fnc_isDownedInputPassthroughKey) exitWith {false};

        [_key] call mandown_fnc_onDownedKeyUp;
        true
    }];
};

mandown_fnc_detachDownedHoverCameraInput = {
    if (!hasInterface) exitWith {};

    private _display = findDisplay 46;
    if (!isNull _display) then {
        _display setVariable ["mandown_hoverCameraInputAttached", false];
    };

    if (!isNil "mandown_downedHoverCameraMouseEh") then {
        if (!isNull _display) then {
            _display displayRemoveEventHandler ["MouseMoving", mandown_downedHoverCameraMouseEh];
        };
        mandown_downedHoverCameraMouseEh = nil;
    };

    if (!isNil "mandown_downedHoverCameraKeyDownEh") then {
        if (!isNull _display) then {
            _display displayRemoveEventHandler ["KeyDown", mandown_downedHoverCameraKeyDownEh];
        };
        mandown_downedHoverCameraKeyDownEh = nil;
    };

    if (!isNil "mandown_downedHoverCameraKeyUpEh") then {
        if (!isNull _display) then {
            _display displayRemoveEventHandler ["KeyUp", mandown_downedHoverCameraKeyUpEh];
        };
        mandown_downedHoverCameraKeyUpEh = nil;
    };
};

mandown_fnc_suspendDownedHoverCamera = {
    if (!hasInterface) exitWith {};
    if (isNil "mandown_downedHoverCamera") exitWith {};
    if (missionNamespace getVariable ["mandown_downedHoverCameraSuspended", false]) exitWith {};

    missionNamespace setVariable ["mandown_downedHoverCameraSuspended", true];
    call mandown_fnc_detachDownedHoverCameraInput;
    mandown_downedHoverCamera cameraEffect ["Terminate", "BACK"];
    player switchCamera "INTERNAL";
};

mandown_fnc_resumeDownedHoverCamera = {
    if (!hasInterface) exitWith {};
    if (isNil "mandown_downedHoverCamera") exitWith {};
    if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {};

    missionNamespace setVariable ["mandown_downedHoverCameraSuspended", false];
    ["unconscious", false] call ace_common_fnc_setDisableUserInputStatus;

    mandown_downedHoverCamera cameraEffect ["Internal", "BACK"];
    mandown_downedHoverCamera camSetFov (missionNamespace getVariable ["mandown_downedHoverCameraFov", 1.35]);
    mandown_downedHoverCamera camCommit 0;
    showCinemaBorder false;

    call mandown_fnc_updateDownedHoverCamera;
    call mandown_fnc_attachDownedHoverCameraInput;
};

mandown_fnc_closeDownedHoverCamera = {
    params [["_restoreInputLock", true, [true]]];

    if (!hasInterface) exitWith {};
    if (isNil "mandown_downedHoverCamera") exitWith {};

    if (!isNil "mandown_downedHoverCameraPfh") then {
        [mandown_downedHoverCameraPfh] call CBA_fnc_removePerFrameHandler;
        mandown_downedHoverCameraPfh = nil;
    };

    call mandown_fnc_detachDownedHoverCameraInput;
    missionNamespace setVariable ["mandown_downedHoverCameraSuspended", false];

    mandown_downedHoverCamera cameraEffect ["Terminate", "BACK"];
    camDestroy mandown_downedHoverCamera;
    mandown_downedHoverCamera = nil;

    player switchCamera "INTERNAL";
    if (_restoreInputLock) then {
        call mandown_fnc_restoreDownedInputLock;
    };
};

mandown_fnc_updateDownedHoverCamera = {
    if (isNil "mandown_downedHoverCamera") exitWith {};
    if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {
        [] call mandown_fnc_closeDownedHoverCamera;
    };

    if (missionNamespace getVariable ["mandown_downedHoverCameraSuspended", false]) exitWith {};

    if (visibleMap) exitWith {
        call mandown_fnc_suspendDownedHoverCamera;
    };

    private _cameraPos = (getPosASLVisual player) vectorAdd [0, 0, 3.5];
    private _yaw = missionNamespace getVariable ["mandown_downedHoverCameraYaw", 0];
    private _pitch = missionNamespace getVariable ["mandown_downedHoverCameraPitch", -15];
    private _dir = [
        (sin _yaw) * (cos _pitch),
        (cos _yaw) * (cos _pitch),
        sin _pitch
    ];
    private _right = [cos _yaw, -(sin _yaw), 0];
    private _up = _right vectorCrossProduct _dir;

    mandown_downedHoverCamera setPosASL _cameraPos;
    mandown_downedHoverCamera setVectorDirAndUp [_dir, _up];
};

mandown_fnc_adjustDownedHoverCameraFov = {
    params ["_delta"];

    if (isNil "mandown_downedHoverCamera") exitWith {};

    private _fov = ((missionNamespace getVariable ["mandown_downedHoverCameraFov", 1.35]) + _delta) max 0.45 min 1.7;
    missionNamespace setVariable ["mandown_downedHoverCameraFov", _fov];
    mandown_downedHoverCamera camSetFov _fov;
    mandown_downedHoverCamera camCommit 0;
};

mandown_fnc_updateDownedHoverCameraZoom = {
    if (isNil "mandown_downedHoverCamera") exitWith {};

    private _zoomIn = ((inputAction "zoomIn") max (inputAction "zoomInToggle")) max (inputAction "zoomContIn");
    private _zoomOut = ((inputAction "zoomOut") max (inputAction "zoomOutToggle")) max (inputAction "zoomContOut");
    private _delta = (_zoomOut - _zoomIn) * diag_deltaTime * 0.9;

    if (abs _delta > 0.001) then {
        [_delta] call mandown_fnc_adjustDownedHoverCameraFov;
    };
};

mandown_fnc_onDownedHoverCameraMouse = {
    params ["", "_deltaX", "_deltaY"];

    if (isNil "mandown_downedHoverCamera") exitWith {false};

    private _yaw = (missionNamespace getVariable ["mandown_downedHoverCameraYaw", 0]) + (_deltaX * 0.5);
    private _pitch = ((missionNamespace getVariable ["mandown_downedHoverCameraPitch", -15]) - (_deltaY * 0.5)) max -89 min 89;

    missionNamespace setVariable ["mandown_downedHoverCameraYaw", _yaw % 360];
    missionNamespace setVariable ["mandown_downedHoverCameraPitch", _pitch];

    true
};

mandown_fnc_onDownedHoverCameraKeyDown = {
    params ["", "_key"];

    if ([_key] call mandown_fnc_isDownedInputPassthroughKey) exitWith {false};

    [_key] call mandown_fnc_onDownedKeyDown;

    if (["personView"] call mandown_fnc_isActionPressed) exitWith {
        call mandown_fnc_toggleDownedHoverCamera;
        true
    };

    if (["ShowMap"] call mandown_fnc_isActionPressed) exitWith {
        call mandown_fnc_openDownedMap;
        true
    };

    if ([["zoomIn", "zoomInToggle"]] call mandown_fnc_isAnyActionPressed) exitWith {
        [-0.08] call mandown_fnc_adjustDownedHoverCameraFov;
        true
    };

    if ([["zoomOut", "zoomOutToggle"]] call mandown_fnc_isAnyActionPressed) exitWith {
        [0.08] call mandown_fnc_adjustDownedHoverCameraFov;
        true
    };

    true
};

mandown_fnc_openDownedHoverCamera = {
    if (!hasInterface) exitWith {};
    if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {};
    if !(missionNamespace getVariable ["mandown_downedHoverCameraEnabled", true]) exitWith {};
    if (!isNil "mandown_downedHoverCamera") exitWith {};

    private _camera = "camera" camCreate ASLToAGL ((getPosASLVisual player) vectorAdd [0, 0, 3.5]);
    if (isNull _camera) exitWith {};

    mandown_downedHoverCamera = _camera;
    missionNamespace setVariable ["mandown_downedHoverCameraYaw", getDirVisual player];
    missionNamespace setVariable ["mandown_downedHoverCameraPitch", -15];
    missionNamespace setVariable ["mandown_downedHoverCameraFov", 1.35];
    missionNamespace setVariable ["mandown_downedHoverCameraSuspended", false];

    call mandown_fnc_resumeDownedHoverCamera;

    mandown_downedHoverCameraPfh = [{
        if (missionNamespace getVariable ["mandown_downedHoverCameraSuspended", false]) exitWith {};

        call mandown_fnc_attachDownedHoverCameraInput;
        call mandown_fnc_updateDownedHoverCamera;
        call mandown_fnc_updateDownedHoverCameraZoom;
    }, 0, []] call CBA_fnc_addPerFrameHandler;
};

mandown_fnc_toggleDownedHoverCamera = {
    call mandown_fnc_markDownedInputHandled;

    if (isNil "mandown_downedHoverCamera") then {
        call mandown_fnc_openDownedHoverCamera;
    } else {
        [] call mandown_fnc_closeDownedHoverCamera;
    };
};

mandown_fnc_openDownedMap = {
    if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {false};
    if !(missionNamespace getVariable ["mandown_mapAccess", true]) exitWith {false};

    call mandown_fnc_markDownedInputHandled;
    missionNamespace setVariable ["mandown_downedMapActive", true];

    if (!isNil "mandown_downedHoverCamera") then {
        call mandown_fnc_suspendDownedHoverCamera;
    };

    call mandown_fnc_restoreDownedInputLock;

    private _display = call mandown_fnc_getAceDisableMouseDisplay;
    if (!isNull _display) then {
        _display closeDisplay 0;
    };

    openMap true;
    true
};

mandown_fnc_handleDownedInputActions = {
    if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {false};

    if (["ShowMap"] call mandown_fnc_isActionPressed) exitWith {
        call mandown_fnc_openDownedMap
    };

    if (["personView"] call mandown_fnc_isActionPressed) exitWith {
        if (missionNamespace getVariable ["mandown_downedHoverCameraEnabled", true]) then {
            call mandown_fnc_toggleDownedHoverCamera;
            true
        } else {
            false
        };
    };

    false
};

mandown_fnc_attachDownedInputBridge = {
    if (!hasInterface) exitWith {};

    private _display = call mandown_fnc_getAceDisableMouseDisplay;
    if (isNull _display) exitWith {};
    if (_display getVariable ["mandown_inputBridgeAttached", false]) exitWith {};

    call mandown_fnc_initDownedInputState;
    _display setVariable ["mandown_inputBridgeAttached", true];

    _display displayAddEventHandler ["KeyDown", {
        params ["", "_key"];

        if ([_key] call mandown_fnc_isDownedInputPassthroughKey) exitWith {false};

        [_key] call mandown_fnc_onDownedKeyDown;
        call mandown_fnc_handleDownedInputActions
    }];

    _display displayAddEventHandler ["KeyUp", {
        params ["", "_key"];

        if ([_key] call mandown_fnc_isDownedInputPassthroughKey) exitWith {false};

        [_key] call mandown_fnc_onDownedKeyUp;
        false
    }];
};

mandown_fnc_refreshDownedInputPfh = {
    if (!hasInterface) exitWith {};

    if (!isNil "mandown_downedInputPfh") then {
        [mandown_downedInputPfh] call CBA_fnc_removePerFrameHandler;
        mandown_downedInputPfh = nil;
    };

    mandown_downedInputPfh = [{
        call mandown_fnc_attachDownedInputBridge;

        if ((missionNamespace getVariable ["mandown_downedMapActive", false]) && {!visibleMap}) then {
            missionNamespace setVariable ["mandown_downedMapActive", false];

            if (!isNil "mandown_downedHoverCamera" && {missionNamespace getVariable ["mandown_downedHoverCameraSuspended", false]}) then {
                call mandown_fnc_resumeDownedHoverCamera;
            } else {
                call mandown_fnc_restoreDownedInputLock;
            };
        };

        if !(call mandown_fnc_isLocalPlayerUnconscious) exitWith {
            missionNamespace setVariable ["mandown_downedMapActive", false];
            missionNamespace setVariable ["mandown_downedHoverCameraSuspended", false];
        };
    }, 0, []] call CBA_fnc_addPerFrameHandler;
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
        2,
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
        "mandown_downedHoverCameraEnabled",
        "CHECKBOX",
        "Allow downed hover camera",
        ["Mandown", "Utilities"],
        true,
        1,
        {
            if (hasInterface && {!_this}) then {
                [] call mandown_fnc_closeDownedHoverCamera;
            };
        }
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

    [
        "mandown_forceDownSoundChoice",
        "CHECKBOX",
        "Force down sound for all players",
        ["Mandown", "Utilities"],
        false,
        2,
        {
            call mandown_fnc_syncLocalPlayerDownSoundChoice;
        }
    ] call CBA_fnc_addSetting;

    [
        "mandown_forcedDownSoundChoice",
        "LIST",
        "Forced down sound",
        ["Mandown", "Utilities"],
        [
            mandown_downSoundValues,
            mandown_downSoundLabels,
            (mandown_downSoundValues find "mandown_sos")
        ],
        2,
        {
            call mandown_fnc_syncLocalPlayerDownSoundChoice;
        }
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
            mandown_downSoundValues,
            mandown_downSoundLabels,
            (mandown_downSoundValues find "mandown_sos")
        ],
        false,
        {
            call mandown_fnc_syncLocalPlayerDownSoundChoice;
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
        "mandown_downAlertAudience",
        "LIST",
        "Down alert audience",
        ["Mandown", "Utilities"],
        [
            ["sameGroup", "sameSide"],
            ["Group/squad only", "All same side"],
            1
        ],
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

call mandown_fnc_syncLocalPlayerDownSoundChoice;
call mandown_fnc_refreshBftPfh;
call mandown_fnc_refreshDownedInputPfh;

["mandown_downedHoverCamera", {
    (!isNil "mandown_downedHoverCamera") ||
    {(missionNamespace getVariable ["mandown_downedMapActive", false]) && {visibleMap}}
}] call CBA_fnc_registerFeatureCamera;


// === Unconscious events ===
["ace_unconscious", {
    params ["_unit", "_isUnconscious"];

    if (_unit == player) then {
        if (!_isUnconscious) then {
            missionNamespace setVariable ["mandown_downedMapActive", false];
            [] call mandown_fnc_closeDownedHoverCamera;
            openMap [false, false];
        };
    };

    // Re-enable speaking for downed players by removing ACE's blockSpeaking reason
    if (_isUnconscious && {missionNamespace getVariable ["mandown_allowDownedVoice", true]}) then {
        [_unit, "blockSpeaking", "ace_unconscious", false] call ace_common_fnc_statusEffect_set;
    };

    // Play the downed player's selected alert locally for same-side clients
    // that are in range and have not opted out of alerts.
    if (_isUnconscious) then {
        private _sound = _unit getVariable ["mandown_soundChoice", "mandown_sos"];
        [_unit, _sound] call mandown_fnc_playDownSound;
    };

    if (missionNamespace getVariable ["mandown_bft_enabled", false]) then {
        call mandown_fnc_bftUpdate;
    };
}] call CBA_fnc_addEventHandler;
