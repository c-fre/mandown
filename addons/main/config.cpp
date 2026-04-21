class CfgPatches {
    class mandown_main {
        name = "Man Down Mod";
        units[] = {};
        weapons[] = {};
        requiredVersion = 0.1;
        requiredAddons[] = {
            "cba_main",
            "ace_medical"
        };
    };
};

class CfgSounds {
    sounds[] = {"mandown_fah", "mandown_ginge", "mandown_mimimi", "mandown_reverb", "mandown_sos"};
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
};
