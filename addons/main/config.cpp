class CfgPatches {
    class mandown_main {
        name = "Mandown";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.06;
        requiredAddons[] = {
            "cba_main",
            "ace_medical"
        };
    };
};

class CfgSounds {
    sounds[] = {
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
    };
    class mandown_fah {
        name = "mandown_fah";
        sound[] = {"mandown\main\sounds\fah.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_ginge {
        name = "mandown_ginge";
        sound[] = {"mandown\main\sounds\ginge.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_mimimi {
        name = "mandown_mimimi";
        sound[] = {"mandown\main\sounds\mimimi.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_reverb {
        name = "mandown_reverb";
        sound[] = {"mandown\main\sounds\reverb.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_sos {
        name = "mandown_sos";
        sound[] = {"mandown\main\sounds\sos.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_boom {
        name = "mandown_boom";
        sound[] = {"mandown\main\sounds\boom.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_cat {
        name = "mandown_cat";
        sound[] = {"mandown\main\sounds\cat.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_gold {
        name = "mandown_gold";
        sound[] = {"mandown\main\sounds\gold.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_laugh {
        name = "mandown_laugh";
        sound[] = {"mandown\main\sounds\laugh.ogg", 1.0, 1.0};
        titles[] = {};
    };
    class mandown_oof {
        name = "mandown_oof";
        sound[] = {"mandown\main\sounds\oof.ogg", 1.0, 1.0};
        titles[] = {};
    };
};

class Extended_PostInit_EventHandlers {
    class mandown_main {
        init = "call compile preprocessFileLineNumbers '\mandown\main\initPlayerLocal.sqf'";
    };
};
