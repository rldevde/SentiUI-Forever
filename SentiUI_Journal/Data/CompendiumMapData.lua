local _, DJ = ...

DJ.DUNGEON_MAPS = {

    ["Hall of Thanes"] = {
        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Hall.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.510, y = 0.944, angle = 0 },
        bosses = {
            { name = "Faldrim Anvilmar",   x = 0.509, y = 0.668 },
            { name = "Magmatus",           x = 0.748, y = 0.478 },
            { name = "Plunder",            x = 0.510, y = 0.515 },
            { name = "Durgen Dirgehammer", x = 0.509, y = 0.170 },
        },
    },
    ["Ruins of Lordaeron"] = {
        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Lordaeron.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.612, y = 0.214, angle = 180 },

        turnins = {
            { npc = "Captain Truman", x = 0.612, y = 0.272 },
        },

        bosses = {
            { name = "Witherfang",        x = 0.668, y = 0.360 },
            { name = "The Baron",         x = 0.615, y = 0.650 },
            { name = "Viktor the Vile",   x = 0.437, y = 0.788 },
            { name = "The Abandoned",     x = 0.395, y = 0.665 },
            { name = "Bjork",             x = 0.345, y = 0.220 },
            { name = "Rath'mael",         x = 0.520, y = 0.600 },
            { name = "Lordaeron Captain", x = 0.500, y = 0.300 },
        },
    },

    ["City of Dalaran"] = {

        floors = {
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_DalaranU.tga", texBottom = 1365 / 2048 },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Dalaran.tga", texBottom = 1365 / 2048 },
        },

        entrance = { floor = 1, x = 0.190, y = 0.838, angle = 0 },
        transitions = {
            { floor = 1, to = 2, x = 0.778, y = 0.564 },
        },

        bosses = {
            { name = "Atrexis the Grave Knight", floor = 1, x = 0.535, y = 0.505 },
            { name = "Lyn the Ignored",          floor = 1, x = 0.680, y = 0.177 },
            { name = "Mana Devourer",            floor = 2, x = 0.416, y = 0.730 },
            { name = "Fel Ancient",              floor = 2, x = 0.513, y = 0.549 },
            { name = "Unstable Sentinel",        floor = 2, x = 0.614, y = 0.413 },
            { name = "Arcanic Enigma",           floor = 2, x = 0.669, y = 0.503 },
            { name = "Arcane Anomaly",           floor = 2, x = 0.527, y = 0.843 },
            { name = "Shade of the Archmage",    floor = 2, x = 0.520, y = 0.240 },
        },
    },

    ["The Drowned City"] = {

        floors = {
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Drowned.tga", texBottom = 683 / 1024, label = "The Drowned City" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_DrownedA.tga", texBottom = 683 / 1024, label = "Atal'Byzal" },
        },
        entrance = { floor = 1, x = 0.846, y = 0.521, angle = 0 },
        bosses = {
            { name = "Zul'Alai",            floor = 1, x = 0.697, y = 0.572 },

            { name = "Primeval Elemental",  floor = 1, x = 0.618, y = 0.672 },
            { name = "Var'Taka",            floor = 1, x = 0.514, y = 0.689 },
            { name = "Captain Dreadrise",   floor = 1, x = 0.546, y = 0.344 },
            { name = "Deathless Marrow",    floor = 1, x = 0.349, y = 0.536 },
            { name = "Min'loth the Serpent", floor = 1, x = 0.196, y = 0.539 },
        },
    },

    ["Blackmaw Hold"] = {
        floors = {
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_BmHall.tga",          texBottom = 683 / 1024, label = "Blackmaw Grove" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Grotto.tga", texBottom = 683 / 1024, label = "Festering Grotto" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Grove.tga",    texBottom = 683 / 1024, label = "Depths of the Fallen Grove" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Elders.tga",         texBottom = 683 / 1024, label = "Depths of the Elders" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Burrow.tga",         texBottom = 683 / 1024, label = "Depths of the Burrow" },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Magic.tga", texBottom = 683 / 1024, label = "Depths of Forbidden Magic" },
        },

        entrance = { floor = 1, x = 0.183, y = 0.740, angle = 90 },
        bosses = {},
    },

    ["Krol'dok Stronghold"] = {
        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Kroldok.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.205, y = 0.807, angle = 180 },
        bosses = {
            { name = "Slavecrusher Grox",          floor = 1, x = 0.331, y = 0.703 },
            { name = "Twilight Commander Zarmok",  floor = 1, x = 0.392, y = 0.734 },
            { name = "War Handler Ashka",          floor = 1, x = 0.621, y = 0.527 },
            { name = "Nar'gurk",                   floor = 1, x = 0.411, y = 0.579 },
            { name = "Bossman Toof",               floor = 1, x = 0.617, y = 0.432 },
            { name = "Overlord Mugg",              floor = 1, x = 0.688, y = 0.242 },
        },
    },

    ["Alcaz Prison"] = {

        floors = {
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Alcaz.tga", texBottom = 683 / 1024 },
            { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Alcaz2.tga", texBottom = 683 / 1024 },
        },
        entrance = { floor = 1, x = 0.353, y = 0.160, angle = 180 },
        bosses = {},
    },
    ["Shaper's Terrace"] = {
        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Terrace.tga", texBottom = 683 / 1024 } },
        bosses = {},
    },

    ["Gnomeregan"] = {

        floors = {
            { uiMapID = 226, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Gnomeregan1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Gnomeregan1_s1.tga", x0 = 0.7595, y0 = 0.6452, x1 = 0.7934, y1 = 0.6961 } } },
            { uiMapID = 227, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Gnomeregan2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Gnomeregan2_s1.tga", x0 = 0.7435, y0 = 0.4431, x1 = 0.7774, y1 = 0.4940 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Gnomeregan2_s2.tga", x0 = 0.2275, y0 = 0.6587, x1 = 0.2615, y1 = 0.7096 } } },
            { uiMapID = 228, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Gnomeregan3.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Gnomeregan3_s1.tga", x0 = 0.4172, y0 = 0.8578, x1 = 0.4511, y1 = 0.9087 } } },
            { uiMapID = 229, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Gnomeregan4.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Gnomeregan4_s1.tga", x0 = 0.2984, y0 = 0.2740, x1 = 0.3323, y1 = 0.3249 } } },
        },
        entrance = { floor = 1, x = 0.642, y = 0.278, angle = 0 },

        transitions = {
            { floor = 1, to = 2, x = 0.545, y = 0.409, labelKey = "MAP_JUMP_LEVEL" },
            { floor = 1, to = 2, x = 0.487, y = 0.877 },
            { floor = 2, to = 3, x = 0.435, y = 0.813 },
            { floor = 3, to = 4, x = 0.370, y = 0.720 },
            { floor = 4, to = 3, x = 0.440, y = 0.726 },
        },
        bosses = {
            { name = "Grubbis",               floor = 1, x = 0.776, y = 0.671 },
            { name = "Viscous Fallout",       floor = 2, x = 0.760, y = 0.469 },
            { name = "Electrocutioner 6000",  floor = 2, x = 0.245, y = 0.684 },
            { name = "Crowd Pummeler 9-60",   floor = 3, x = 0.434, y = 0.883 },
            { name = "Mekgineer Thermaplugg", floor = 4, x = 0.315, y = 0.299 },
        },
    },
    ["Razorfen Kraul"] = {
        floors = { { uiMapID = 301, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_RazorfenKraul1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_RazorfenKraul1_s1.tga", x0 = 0.2036, y0 = 0.2874, x1 = 0.2375, y1 = 0.3383 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_RazorfenKraul1_s2.tga", x0 = 0.5589, y0 = 0.2874, x1 = 0.5928, y1 = 0.3383 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_RazorfenKraul1_s3.tga", x0 = 0.8593, y0 = 0.3937, x1 = 0.8932, y1 = 0.4446 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_RazorfenKraul1_s4.tga", x0 = 0.7914, y0 = 0.4955, x1 = 0.8253, y1 = 0.5464 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_RazorfenKraul1_s5.tga", x0 = 0.0649, y0 = 0.6602, x1 = 0.0988, y1 = 0.7111 } } } },
        entrance = { floor = 1, x = 0.714, y = 0.840, angle = 180 },

        transitions = {
            { floor = 1, x = 0.626, y = 0.562, note = true, labelKey = "MAP_RFK_VINE" },
        },
        bosses = {

            { name = "Roogug",                 x = 0.646, y = 0.430 },
            { name = "Aggem Thorncurse",       x = 0.808, y = 0.521 },
            { name = "Death Speaker Jargba",   x = 0.876, y = 0.419 },
            { name = "Earthcaller Halmgar",    x = 0.498, y = 0.473 },
            { name = "Overlord Ramtusk",       x = 0.576, y = 0.313 },
            { name = "Charlga Razorflank",     x = 0.221, y = 0.313 },
            { name = "Agathelos the Raging",  x = 0.082, y = 0.686 },
        },
    },

    ["Scarlet Monastery: Library"] = {
        floors = { { uiMapID = 303, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ScarletMonastery2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        bosses = {
            { name = "Houndmaster Loksey", x = 0.302, y = 0.846 },
            { name = "Arcanist Doan",      x = 0.835, y = 0.740 },
        },
    },

    ["Scarlet Monastery: Armory"] = {
        floors = { { uiMapID = 304, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ScarletMonastery3.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        entrance = { floor = 1, x = 0.610, y = 0.945, angle = 0 },
        bosses = {
            { name = "Herod", x = 0.785, y = 0.118 },
        },
    },
    ["Scarlet Monastery: Cathedral"] = {
        floors = { { uiMapID = 305, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ScarletMonastery4.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        entrance = { floor = 1, x = 0.618, y = 0.915, angle = 0 },
        bosses = {
            { name = "High Inquisitor Fairbanks",  x = 0.555, y = 0.250 },
            { name = "Scarlet Commander Mograine", x = 0.490, y = 0.285 },
            { name = "High Inquisitor Whitemane",  x = 0.490, y = 0.165 },
        },
    },

    ["Razorfen Downs"] = {
        floors = { { uiMapID = 300, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_RazorfenDowns1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        entrance = { floor = 1, x = 0.234, y = 0.185, angle = 90 },
        bosses = {
            { name = "Tuten'kash",               x = 0.589, y = 0.342 },
            { name = "Mordresh Fire Eye",        x = 0.860, y = 0.467 },
            { name = "Glutton",                  x = 0.345, y = 0.664 },
            { name = "Amnennar the Coldbringer", x = 0.455, y = 0.582 },
        },
    },

    ["Blackrock Depths"] = {
        floors = {
            { uiMapID = 242, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_BlackrockDepths1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 243, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_BlackrockDepths2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
        },
        entrance = { floor = 1, x = 0.329, y = 0.794, angle = 0 },
        bosses = {
            { name = "High Interrogator Gerstahn", floor = 1, x = 0.474, y = 0.922 },
            { name = "Lord Roccor",                floor = 1, x = 0.556, y = 0.670 },
            { name = "Houndmaster Grebmar",        floor = 1, x = 0.535, y = 0.573 },
            { name = "Bael'Gar",                   floor = 1, x = 0.251, y = 0.534 },
            { name = "Lord Incendius",             floor = 1, x = 0.564, y = 0.311 },
            { name = "Fineous Darkvire",           floor = 1, x = 0.635, y = 0.211 },
            { name = "Gorosh the Dervish",         floor = 2, x = 0.530, y = 0.868 },
            { name = "Grizzle",                    floor = 2, x = 0.547, y = 0.883 },
            { name = "Eviscerator",                floor = 2, x = 0.547, y = 0.913 },
            { name = "Ok'thor the Breaker",        floor = 2, x = 0.530, y = 0.928 },
            { name = "Anub'shiah",                 floor = 2, x = 0.513, y = 0.913 },
            { name = "Hedrum the Creeper",         floor = 2, x = 0.513, y = 0.883 },
            { name = "Pyromancer Loregrain",       floor = 2, x = 0.549, y = 0.948 },
            { name = "Warder Stilgiss",            floor = 2, x = 0.602, y = 0.659 },
            { name = "General Angerforge",         floor = 2, x = 0.363, y = 0.823 },
            { name = "Golem Lord Argelmach",       floor = 2, x = 0.364, y = 0.651 },
            { name = "Hurley Blackbreath",         floor = 2, x = 0.505, y = 0.704 },
            { name = "Plugger Spazzring",          floor = 2, x = 0.477, y = 0.657 },
            { name = "Phalanx",                    floor = 2, x = 0.458, y = 0.564 },
            { name = "Ambassador Flamelash",       floor = 2, x = 0.538, y = 0.485 },
            { name = "The Seven",                  floor = 2, x = 0.538, y = 0.247 },
            { name = "Magmus",                     floor = 2, x = 0.796, y = 0.118 },
            { name = "Princess Moira Bronzebeard", floor = 2, x = 0.920, y = 0.110 },
            { name = "Emperor Dagran Thaurissan",  floor = 2, x = 0.909, y = 0.118 },
        },
    },
    ["Uldaman"] = {
        floors = {
            { uiMapID = 230, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Uldaman1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 231, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Uldaman2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
        },
        entrance = { floor = 1, x = 0.679, y = 0.725, angle = 0 },
        bosses = {
            { name = "The Lost Dwarves",     floor = 1, x = 0.584, y = 0.920 },
            { name = "Revelosh",             floor = 1, x = 0.534, y = 0.725 },
            { name = "Ironaya",              floor = 1, x = 0.372, y = 0.739 },
            { name = "Ancient Stone Keeper", floor = 1, x = 0.475, y = 0.440 },
            { name = "Galgann Firehammer",   floor = 1, x = 0.267, y = 0.327 },
            { name = "Grimlok",              floor = 1, x = 0.219, y = 0.256 },
            { name = "Archaedas",            floor = 2, x = 0.553, y = 0.504 },
        },
    },
    ["Zul'Farrak"] = {

        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_ZFarrak.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.552, y = 0.880, angle = 0 },
        bosses = {
            { name = "Antu'sul",              x = 0.646, y = 0.276 },
            { name = "Witch Doctor Zum'rah",  x = 0.442, y = 0.176 },
            { name = "Shadowpriest Sezz'ziz", x = 0.296, y = 0.174 },
            { name = "Gahz'rilla",            x = 0.312, y = 0.414 },
            { name = "Zerillis",              x = 0.548, y = 0.401 },
            { name = "Sandarr Dunereaver",    x = 0.524, y = 0.428 },
            { name = "Dustwraith",            x = 0.310, y = 0.160 },
            { name = "Chief Ukorz Sandscalp", x = 0.422, y = 0.329 },
        },
    },
    ["Scarlet Monastery: Graveyard"] = {
        floors = { { uiMapID = 302, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ScarletMonastery1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ScarletMonastery1_s1.tga", x0 = 0.2285, y0 = 0.5404, x1 = 0.2625, y1 = 0.5913 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ScarletMonastery1_s2.tga", x0 = 0.7066, y0 = 0.5749, x1 = 0.7405, y1 = 0.6257 } } } },
        entrance = { floor = 1, x = 0.841, y = 0.831, angle = 180 },
        bosses = {
            { name = "Interrogator Vishas", x = 0.724, y = 0.600 },
            { name = "Bloodmage Thalnos",   x = 0.246, y = 0.566 },
        },
    },
    ["Excavation Site: Wetlands"] = {
        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Excav.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.888, y = 0.258, angle = 180, labelPos = "top" },

        turnins = {
            { npc = "Ardin Grassman", x = 0.262, y = 0.668 },
            { npc = "Daewyn Songblade", x = 0.074, y = 0.497 },
        },

        bosses = {
            { name = "Saltspine",       x = 0.550, y = 0.361 },
            { name = "Shadetooth",      x = 0.305, y = 0.484 },
            { name = "Relic Guardian",  x = 0.324, y = 0.687 },
            { name = "Highland Horror", x = 0.082, y = 0.405, npcID = 260808, quest = 95646 },
        },
    },
    ["Ragefire Chasm"] = {
        floors = { { uiMapID = 213, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Ragefire1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Ragefire1_s1.tga", x0 = 0.5259, y0 = 0.2725, x1 = 0.5599, y1 = 0.3234 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Ragefire1_s2.tga", x0 = 0.3752, y0 = 0.5584, x1 = 0.4092, y1 = 0.6093 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Ragefire1_s3.tga", x0 = 0.6806, y0 = 0.6213, x1 = 0.7146, y1 = 0.6722 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Ragefire1_s4.tga", x0 = 0.3253, y0 = 0.7904, x1 = 0.3593, y1 = 0.8413 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_Ragefire1_1.tga", x0 = 0.0150, y0 = 0.0120, x1 = 0.5948, y1 = 0.1497 } } } },
        entrance = { floor = 1, x = 0.610, y = 0.075, angle = 200 },
        bosses = {
            { name = "Oggleflint",             x = 0.561, y = 0.378 },
            { name = "Taragaman the Hungerer", x = 0.405, y = 0.570 },
            { name = "Jergosh the Invoker",    x = 0.340, y = 0.815 },
            { name = "Bazzalan",               x = 0.422, y = 0.842 },
        },
    },
    ["The Deadmines"] = {

        transitions = {
            { floor = 1, to = 2, x = 0.615, y = 0.610 },
        },
        floors = {
            { uiMapID = 291, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_TheDeadmines1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines1_s1.tga", x0 = 0.3313, y0 = 0.5898, x1 = 0.3653, y1 = 0.6407 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines1_s2.tga", x0 = 0.4721, y0 = 0.8413, x1 = 0.5060, y1 = 0.8922 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines1_1.tga", x0 = 0.3194, y0 = 0.0150, x1 = 0.6996, y1 = 0.1347 } } },
            { uiMapID = 292, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_TheDeadmines2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines2_s1.tga", x0 = 0.1088, y0 = 0.7365, x1 = 0.1427, y1 = 0.7874 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines2_s2.tga", x0 = 0.5908, y0 = 0.3428, x1 = 0.6248, y1 = 0.3937 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheDeadmines2_s3.tga", x0 = 0.5650, y0 = 0.4160, x1 = 0.6110, y1 = 0.4840, alpha = 1.0 } } },
        },
        entrance = { floor = 1, x = 0.295, y = 0.135, angle = -15 },
        bosses = {
            { name = "Rhahk'Zor",         floor = 1, x = 0.365, y = 0.610 },
            { name = "Miner Johnson",     floor = 1, x = 0.535, y = 0.520 },
            { name = "Sneed's Shredder",  floor = 1, x = 0.475, y = 0.865 },
            { name = "Sneed",             floor = 1, x = 0.535, y = 0.865 },
            { name = "Gilnid",            floor = 2, x = 0.122, y = 0.755 },
            { name = "Mr. Smite",         floor = 2, x = 0.515, y = 0.170 },
            { name = "Captain Greenskin", floor = 2, x = 0.575, y = 0.350 },
            { name = "Edwin VanCleef",    floor = 2, x = 0.605, y = 0.452 },
            { name = "Cookie",            floor = 2, x = 0.665, y = 0.430 },
        },
    },
    ["Wailing Caverns"] = {

        floors = { { uiMapID = 279, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_WailingCaverns1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024,
            texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Wailing.tga", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        entrance = { floor = 1, x = 0.465, y = 0.590, angle = 200 },

        bosses = {
            { name = "Lady Anacondra",        x = 0.310, y = 0.430 },
            { name = "Kresh",                 x = 0.385, y = 0.350 },
            { name = "Lord Cobrahn",          x = 0.155, y = 0.570 },
            { name = "Lord Pythas",           x = 0.856, y = 0.289 },
            { name = "Skum",                  x = 0.927, y = 0.792 },
            { name = "Deviate Faerie Dragon", x = 0.580, y = 0.600 },
            { name = "Lord Serpentis",        x = 0.615, y = 0.535 },
            { name = "Verdan the Everliving", x = 0.545, y = 0.460 },
            { name = "Mutanus the Devourer",  x = 0.345, y = 0.130 },
        },
    },
    ["Shadowfang Keep"] = {

        transitions = {
            { floor = 1, to = 2, x = 0.145, y = 0.864, dir = "up" },
            { floor = 2, to = 3, x = 0.515, y = 0.915, dir = "up" },
        },
        floors = {
            { uiMapID = 310, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ShadowfangKeep1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ShadowfangKeep1_s1.tga", x0 = 0.2525, y0 = 0.5554, x1 = 0.2864, y1 = 0.6063 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ShadowfangKeep1_s2.tga", x0 = 0.6497, y0 = 0.6961, x1 = 0.6836, y1 = 0.7470 } } },
            { uiMapID = 316, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ShadowfangKeep7.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ShadowfangKeep7_s1.tga", x0 = 0.5659, y0 = 0.8024, x1 = 0.5998, y1 = 0.8533 } } },
            { uiMapID = 315, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_ShadowfangKeep6.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ShadowfangKeep6_s1.tga", x0 = 0.6677, y0 = 0.3084, x1 = 0.7016, y1 = 0.3593 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_ShadowfangKeep6_s2.tga", x0 = 0.5289, y0 = 0.6018, x1 = 0.5629, y1 = 0.6527 } } },
        },
        entrance = { floor = 1, x = 0.705, y = 0.605, angle = 0 },

        turnins = {
            { npc = "Deathstalker Vincent", floor = 1, x = 0.558, y = 0.622 },
        },

        bosses = {
            { name = "Rethilgore",                 floor = 1, x = 0.670, y = 0.715 },
            { name = "Fel Steed / Shadow Charger", floor = 1, x = 0.345, y = 0.635 },
            { name = "Razorclaw the Butcher",      floor = 1, x = 0.327, y = 0.447 },
            { name = "Baron Silverlaine",          floor = 1, x = 0.162, y = 0.807 },
            { name = "Deathsworn Captain",         floor = 2, x = 0.630, y = 0.525 },
            { name = "Odo the Blindwatcher",       floor = 2, x = 0.583, y = 0.828 },
            { name = "Fenrus the Devourer",        floor = 3, x = 0.546, y = 0.627 },
            { name = "Arugal's Voidwalker",        floor = 3, x = 0.492, y = 0.710 },
            { name = "Wolf Master Nandos",         floor = 3, x = 0.590, y = 0.533 },
            { name = "Archmage Arugal",            floor = 3, x = 0.685, y = 0.334 },
        },
    },
    ["The Stockade"] = {
        floors = { { uiMapID = 225, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_TheStockade1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_TheStockade1_s1.tga", x0 = 0.7685, y0 = 0.4311, x1 = 0.8024, y1 = 0.4820 } } } },
        entrance = { floor = 1, x = 0.500, y = 0.815, angle = 0 },
        bosses = {
            { name = "Targorr the Dread",   x = 0.440, y = 0.445 },
            { name = "Kam Deepfury",        x = 0.320, y = 0.380 },
            { name = "Hamhock",             x = 0.780, y = 0.455 },
            { name = "Bazil Thredd",        x = 0.215, y = 0.255 },
            { name = "Dextren Ward",        x = 0.735, y = 0.575 },
            { name = "Bruegal Ironknuckle", x = 0.500, y = 0.190 },
        },
    },
    ["Blackfathom Deeps"] = {
        transitions = {
            { floor = 1, to = 2, x = 0.615, y = 0.700 },
            { floor = 2, to = 3, x = 0.470, y = 0.700, labelKey = "MAP_SWIM_LEVEL" },
        },
        floors = {
            { uiMapID = 221, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_BlackFathomDeeps1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_s1.tga", x0 = 0.0818, y0 = 0.3728, x1 = 0.1158, y1 = 0.4237 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_s2.tga", x0 = 0.3114, y0 = 0.5793, x1 = 0.3453, y1 = 0.6302 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_s3.tga", x0 = 0.5289, y0 = 0.5479, x1 = 0.5629, y1 = 0.5988 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_1.tga", x0 = 0.2146, y0 = 0.0075, x1 = 0.4391, y1 = 0.1093 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_2.tga", x0 = 0.4691, y0 = 0.0075, x1 = 0.8044, y1 = 0.1093 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps1_3.tga", x0 = 0.4242, y0 = 0.0075, x1 = 0.4890, y1 = 0.0719 } } },
            { uiMapID = 222, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_BlackFathomDeeps2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps2_s1.tga", x0 = 0.5090, y0 = 0.7934, x1 = 0.5429, y1 = 0.8443 }, { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps2_s2.tga", x0 = 0.8263, y0 = 0.8398, x1 = 0.8603, y1 = 0.8907 } } },
            { uiMapID = 223, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_BlackFathomDeeps3.blp", texRight = 1002 / 1024, texBottom = 668 / 1024, patches = { { tex = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\P_BlackFathomDeeps3_s1.tga", x0 = 0.5569, y0 = 0.2799, x1 = 0.5908, y1 = 0.3308 } } },
        },
        entrance = { floor = 1, x = 0.455, y = 0.085, angle = -20 },

        bosses = {
            { name = "Ghamoo-ra",            floor = 1, x = 0.325, y = 0.605 },
            { name = "Lady Sarevess",        floor = 1, x = 0.110, y = 0.385 },
            { name = "Gelihast",             floor = 1, x = 0.540, y = 0.575 },
            { name = "Lorgus Jett",          floor = 2, x = 0.325, y = 0.700 },
            { name = "Baron Aquanis",        floor = 2, x = 0.420, y = 0.720, npcID = 12876 },
            { name = "Twilight Lord Kelris", floor = 2, x = 0.525, y = 0.810 },
            { name = "Aku'mai",              floor = 2, x = 0.855, y = 0.860 },
            { name = "Old Serra'kis",        floor = 3, x = 0.585, y = 0.290 },
        },
    },

    ["Dire Maul: North"] = {
        entrance = { floor = 1, x = 0.717, y = 0.924, angle = 0 },
        floors = { { uiMapID = 235, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        bosses = {
            { name = "Guard Mol'dar",          x = 0.695, y = 0.760 },
            { name = "Stomper Kreeg",          x = 0.612, y = 0.692 },
            { name = "Guard Fengus",           x = 0.494, y = 0.780 },
            { name = "Guard Slip'kik",         x = 0.266, y = 0.571 },
            { name = "Captain Kromcrush",      x = 0.318, y = 0.506 },
            { name = "Cho'Rush the Observer",  x = 0.300, y = 0.290 },
            { name = "King Gordok",            x = 0.319, y = 0.229 },
        },
    },
    ["Dire Maul: West"] = {
        entrance = { floor = 1, x = 0.935, y = 0.507, angle = 180, labelPos = "top" },
        floors = {
            { uiMapID = 236, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 237, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul3.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 238, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul4.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
        },
        bosses = {
            { name = "Tendris Warpwood",   floor = 1, x = 0.336, y = 0.536 },
            { name = "Illyanna Ravenoak",  floor = 1, x = 0.203, y = 0.776 },
            { name = "Magister Kalendris", floor = 2, x = 0.338, y = 0.450 },
            { name = "Tsu'zee",            floor = 2, x = 0.322, y = 0.143 },
            { name = "Immol'thar",         floor = 3, x = 0.349, y = 0.575 },
            { name = "Prince Tortheldrin", floor = 3, x = 0.622, y = 0.231 },
        },
    },
    ["Dire Maul: East"] = {
        entrance = { floor = 1, x = 0.281, y = 0.554, angle = 180 },
        floors = {
            { uiMapID = 240, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul6.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 239, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_DireMaul5.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
        },
        bosses = {
            { name = "Lethtendris",           floor = 2, x = 0.438, y = 0.481 },
            { name = "Zevrim Thornhoof",      floor = 1, x = 0.575, y = 0.743 },
            { name = "Hydrospawn",            floor = 1, x = 0.536, y = 0.715 },
            { name = "Alzzin the Wildshaper", floor = 1, x = 0.566, y = 0.288 },
        },
    },
    ["Maraudon"] = {

        entrance = { floor = 1, x = 0.618, y = 0.281, angle = 0 },
        entrances = {
            { floor = 1, x = 0.618, y = 0.281, angle = 0, labelKey = "MAP_ENTRANCE_ORANGE", color = { 1.00, 0.55, 0.10 } },
            { floor = 1, x = 0.764, y = 0.659, angle = 0, labelKey = "MAP_ENTRANCE_PURPLE", color = { 0.78, 0.45, 1.00 } },
        },

        turnins = {
            { npc = "Celebras the Redeemed", floor = 2, x = 0.245, y = 0.143 },
        },
        floors = {
            { uiMapID = 280, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Maraudon1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
            { uiMapID = 281, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Maraudon2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 },
        },
        bosses = {
            { name = "Noxxion",               floor = 1, x = 0.362, y = 0.098 },
            { name = "Razorlash",             floor = 1, x = 0.166, y = 0.344 },
            { name = "Lord Vyletongue",       floor = 1, x = 0.378, y = 0.704 },
            { name = "Meshlok the Harvester", floor = 1, x = 0.246, y = 0.874 },
            { name = "Celebras the Cursed",   floor = 2, x = 0.245, y = 0.143 },
            { name = "Landslide",             floor = 2, x = 0.408, y = 0.487 },
            { name = "Tinkerer Gizlock",      floor = 2, x = 0.484, y = 0.686 },
            { name = "Rotgrip",               floor = 2, x = 0.413, y = 0.817 },
            { name = "Princess Theradras",    floor = 2, x = 0.258, y = 0.788 },
        },
    },
    ["Stratholme: Living"] = {
        entrance = { floor = 1, x = 0.675, y = 0.877, angle = 0 },
        floors = { { uiMapID = 317, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Stratholme1.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        bosses = {
            { name = "Skul",                   x = 0.574, y = 0.652 },
            { name = "Hearthsinger Forresten", x = 0.605, y = 0.327 },
            { name = "The Unforgiven",         x = 0.734, y = 0.204 },
            { name = "Timmy the Cruel",        x = 0.495, y = 0.180 },
            { name = "Postmaster Malown",      x = 0.558, y = 0.684 },
            { name = "Cannon Master Willey",   x = 0.042, y = 0.510 },
            { name = "Archivist Galford",      x = 0.272, y = 0.750 },
            { name = "Balnazzar",              x = 0.204, y = 0.818 },
        },
    },
    ["Stratholme: Undead"] = {
        entrance = { floor = 1, x = 0.658, y = 0.902, angle = 0 },
        floors = { { uiMapID = 318, texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\T_Stratholme2.blp", texRight = 1002 / 1024, texBottom = 668 / 1024 } },
        bosses = {
            { name = "Magistrate Barthilas", x = 0.566, y = 0.161 },
            { name = "Stonespine",           x = 0.649, y = 0.489 },
            { name = "Nerub'enkan",          x = 0.572, y = 0.461 },
            { name = "Baroness Anastari",    x = 0.745, y = 0.469 },
            { name = "Maleki the Pallid",    x = 0.674, y = 0.227 },
            { name = "Ramstein the Gorger",  x = 0.456, y = 0.198 },
            { name = "Baron Rivendare",      x = 0.372, y = 0.199 },
        },
    },

    ["Scholomance"] = {
        entrance = { floor = 1, x = 0.390, y = 0.652, angle = 0 },
        floors = {
            { uiMapID = 306, tiles = "Interface\\WorldMap\\ScholomanceOLD\\ScholomanceOLD1_" },
            { uiMapID = 307, tiles = "Interface\\WorldMap\\ScholomanceOLD\\ScholomanceOLD2_" },
            { uiMapID = 308, tiles = "Interface\\WorldMap\\ScholomanceOLD\\ScholomanceOLD3_" },
            { uiMapID = 309, tiles = "Interface\\WorldMap\\ScholomanceOLD\\ScholomanceOLD4_" },
        },
        bosses = {
            { name = "Kirtonos the Herald",      floor = 2, x = 0.495, y = 0.043 },
            { name = "Marduk Blackpool",         floor = 2, x = 0.444, y = 0.639 },
            { name = "Vectus",                   floor = 2, x = 0.482, y = 0.662 },
            { name = "Rattlegore",               floor = 3, x = 0.313, y = 0.646 },
            { name = "Instructor Malicia",       floor = 3, x = 0.721, y = 0.706 },
            { name = "Doctor Theolen Krastinov", floor = 3, x = 0.889, y = 0.462 },
            { name = "Lorekeeper Polkelt",       floor = 3, x = 0.720, y = 0.225 },
            { name = "Ras Frostwhisper",         floor = 4, x = 0.406, y = 0.884 },
            { name = "The Ravenian",             floor = 4, x = 0.675, y = 0.521 },
            { name = "Lord Alexei Barov",        floor = 4, x = 0.844, y = 0.308 },
            { name = "Lady Illucia Barov",       floor = 4, x = 0.670, y = 0.061 },
            { name = "Darkmaster Gandling",      floor = 4, x = 0.682, y = 0.302 },
        },
    },
    ["Sunken Temple"] = {

        floors = { { texture = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\Map_Temple.tga", texBottom = 683 / 1024 } },
        entrance = { floor = 1, x = 0.499, y = 0.130, angle = 0 },
        bosses = {
            { name = "Atal'alarion",           x = 0.499, y = 0.455 },
            { name = "Avatar of Hakkar",       x = 0.240, y = 0.453 },
            { name = "Jammal'an the Prophet",  x = 0.760, y = 0.454 },
            { name = "Ogom the Wretched",      x = 0.790, y = 0.395 },
            { name = "Dreamscythe & Weaver",   x = 0.500, y = 0.383 },
            { name = "Morphaz & Hazzas",       x = 0.498, y = 0.865 },
            { name = "Shade of Eranikus",      x = 0.666, y = 0.873 },
        },

        markers = {
            { n = 1, x = 0.4985, y = 0.5908, statue = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_S", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
            { n = 2, x = 0.4985, y = 0.3094, statue = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_N", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
            { n = 3, x = 0.4207, y = 0.5234, statue = true, flip = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_SW", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
            { n = 4, x = 0.5763, y = 0.5234, statue = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_SE", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
            { n = 5, x = 0.4207, y = 0.3887, statue = true, flip = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_NW", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
            { n = 6, x = 0.5763, y = 0.3887, statue = true, titleKey = "ST_STATUE", dirKey = "ST_DIR_NE", tipKey = "ST_STATUE_TIP", tipBoss = "Atal'alarion" },
        },
    },

    -- no packaged artwork: the floors are looked up in the client's map list by name
    ["Lower Blackrock Spire"] = { find = { "Lower Blackrock Spire", "Blackrock Spire" }, floors = {}, bosses = {} },
    ["Upper Blackrock Spire"] = { find = { "Upper Blackrock Spire", "Blackrock Spire" }, floors = {}, bosses = {} },
}
