-- One-time import of the shared blacklist (entries as synced by the
-- standalone ForeverBlackListed addon, reporter "Xenshi Lucas"). Runs
-- once on login, merges into FBLDB through the normal import path and
-- marks itself done - deleting this file does not remove the data.
local _, ns = ...
local S = SentiUI

local ENTRIES = {
        ["guild|limit break"] = {
            ["added"] = 1794961890,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "guild",
            ["list"] = "black",
            ["mod"] = 1794961890,
            ["name"] = "Limit Break",
            ["note"] = "Gambling Gilde Klauen mobs kein fair play",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Gambling Gilde Klauen mobs kein fair play",
                    ["t"] = 1794961890,
                },
            },
        },
        ["player|abdi warsame"] = {
            ["added"] = 1795052639,
            ["by"] = "Dio Mio",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795052639,
            ["name"] = "Abdi Warsame",
            ["notes"] = {
                ["dio mio"] = {
                    ["a"] = "Dio Mio",
                    ["n"] = "Intentional loot steal",
                    ["t"] = 1795052639,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 4 PvP",
        },
        ["player|aerial calibarn"] = {
            ["added"] = 1794937761,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794937761,
            ["name"] = "Aerial Calibarn",
            ["note"] = "Kindergarten im Chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten im Chat",
                    ["t"] = 1794937761,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|alan corpsecamper"] = {
            ["added"] = 1794954647,
            ["group"] = "other",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795044545,
            ["name"] = "Alan Corpsecamper",
            ["notes"] = {
                ["false incarnate"] = {
                    ["a"] = "False Incarnate",
                    ["n"] = "ninja'd tanking items, shittalking, ninjaing healing items",
                    ["t"] = 1794954647,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 4 PvP",
        },
        ["player|alextrazos dragonborn"] = {
            ["added"] = 1794606590,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794606590,
            ["name"] = "Alextrazos Dragonborn",
            ["note"] = "Bullshit im chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Bullshit im chat",
                    ["t"] = 1794606590,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|baba yag??"] = {
            ["added"] = 1794772370,
            ["group"] = "players",
            ["guild"] = "La Cima",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1794772370,
            ["name"] = "Baba Yag??",
            ["notes"] = {
                ["thefalcon cres"] = {
                    ["a"] = "Thefalcon Cres",
                    ["n"] = "prueba",
                    ["t"] = 1794772370,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|baba yaga"] = {
            ["added"] = 1795218624,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795218624,
            ["name"] = "Baba Yaga",
            ["notes"] = {
                ["zenn syg"] = {
                    ["a"] = "Zenn Syg",
                    ["n"] = "Kill on low hp",
                    ["t"] = 1795218624,
                },
            },
        },
        ["player|banano evs"] = {
            ["added"] = 1794748205,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794748205,
            ["name"] = "Banano Evs",
            ["note"] = "Schreibt nur Bl??dsinn im Allgemeinen Channel nicht wirklich vertrauensvoll",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Schreibt nur Bl??dsinn im Allgemeinen Channel nicht wirklich vertrauensvoll",
                    ["t"] = 1794748205,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|billy balloon"] = {
            ["added"] = 1794683209,
            ["group"] = "players",
            ["guild"] = "Lucky",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794743188,
            ["name"] = "Billy Balloon",
            ["notes"] = {
                ["billy balloon"] = {
                    ["a"] = "Billy Balloon",
                    ["n"] = "Test",
                    ["t"] = 1794683209,
                },
                ["xenshi lucas"] = {
                    ["del"] = true,
                    ["t"] = 1794743188,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
        ["player|buffalo shoe"] = {
            ["added"] = 1794953122,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794953122,
            ["name"] = "buffalo shoe",
            ["notes"] = {
                ["can nab"] = {
                    ["a"] = "Can Nab",
                    ["n"] = "Inv abgekehnt und escort mob geklaut",
                    ["t"] = 1794953122,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 5 PvE",
        },
        ["player|chago luka"] = {
            ["added"] = 1795096568,
            ["group"] = "players",
            ["guild"] = "The Pale Bastion",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795096568,
            ["name"] = "Chago Luka",
            ["notes"] = {
                ["dacky forever"] = {
                    ["a"] = "Dacky Forever",
                    ["n"] = "Ninja looter",
                    ["t"] = 1795096568,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 9 RP PvP",
        },
        ["player|cierra bares"] = {
            ["added"] = 1795120240,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795120240,
            ["name"] = "Cierra Bares",
            ["notes"] = {
                ["zocalo fduty"] = {
                    ["a"] = "Zocalo Fduty",
                    ["n"] = "Ali que me campeo en Vega de Tuercespina. Matar",
                    ["t"] = 1795120240,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 2 PvP",
        },
        ["player|cruel barb"] = {
            ["added"] = 1795218645,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795218645,
            ["name"] = "Cruel Barb",
            ["notes"] = {
                ["zenn syg"] = {
                    ["a"] = "Zenn Syg",
                    ["n"] = "Killed when aoe farm low hp",
                    ["t"] = 1795218645,
                },
            },
        },
        ["player|daraz klinge"] = {
            ["added"] = 1794946726,
            ["by"] = "Holla Aeon",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794946726,
            ["name"] = "Daraz Klinge",
            ["notes"] = {
                ["holla aeon"] = {
                    ["a"] = "Holla Aeon",
                    ["n"] = "Flugpunkt Camper",
                    ["t"] = 1794946726,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 8 PvP",
        },
        ["player|destino oscuro"] = {
            ["added"] = 1795211917,
            ["group"] = "players",
            ["guild"] = "DTEK",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795211917,
            ["name"] = "Destino Oscuro",
            ["notes"] = {
                ["snehy pakarna"] = {
                    ["a"] = "Snehy Pakarna",
                    ["n"] = "ninja bow ZF as warlock",
                    ["t"] = 1795211917,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 2 PvP",
        },
        ["player|dimitris mvrm"] = {
            ["added"] = 1795017388,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795017388,
            ["name"] = "Dimitris Mvrm",
            ["notes"] = {
                ["grumpy wife"] = {
                    ["a"] = "Grumpy Wife",
                    ["n"] = "Dog atitude",
                    ["t"] = 1795017388,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 4 PvP",
        },
        ["player|divo nivo"] = {
            ["added"] = 1794937835,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794937835,
            ["name"] = "Divo Nivo",
            ["note"] = "Kindergarten im Chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten im Chat",
                    ["t"] = 1794937835,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|du rockero"] = {
            ["added"] = 1794758359,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794821291,
            ["name"] = "Du Rockero",
            ["notes"] = {
                ["elvenda sho"] = {
                    ["a"] = "Elvenda Sho",
                    ["n"] = "Ninja en off.-hand i ST",
                    ["t"] = 1794758366,
                },
                ["nocy boi"] = {
                    ["del"] = true,
                    ["t"] = 1794821291,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|enkla grejer"] = {
            ["added"] = 1795052601,
            ["by"] = "Dio Mio",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795052601,
            ["name"] = "Enkla Grejer",
            ["notes"] = {
                ["dio mio"] = {
                    ["a"] = "Dio Mio",
                    ["n"] = "Intentional loot steal",
                    ["t"] = 1795052601,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 4 PvP",
        },
        ["player|fattjocke"] = {
            ["added"] = 1795021020,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795021020,
            ["name"] = "Fattjocke",
            ["notes"] = {
                ["demon sparda"] = {
                    ["a"] = "Demon Sparda",
                    ["n"] = "sss",
                    ["t"] = 1795021020,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|finuil corvinus"] = {
            ["added"] = 1795003228,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795003228,
            ["name"] = "Finuil Corvinus",
            ["note"] = "meddl trottel",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "meddl trottel",
                    ["t"] = 1795003228,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|fussel pfote"] = {
            ["added"] = 1794961944,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["guild"] = "Limit Break",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794961944,
            ["name"] = "Fussel Pfote",
            ["note"] = "gambler 2",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "gambler 2",
                    ["t"] = 1794961944,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|garbage hunter"] = {
            ["added"] = 1795108201,
            ["by"] = "Vihainen Outolempi",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795108201,
            ["name"] = "Garbage Hunter",
            ["notes"] = {
                ["vihainen outolempi"] = {
                    ["a"] = "Vihainen Outolempi",
                    ["n"] = "ninja",
                    ["t"] = 1795108201,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 3 PvE",
        },
        ["player|giovani giorgo"] = {
            ["added"] = 1795272019,
            ["by"] = "Felis Cothurnata",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795272019,
            ["name"] = "Giovani Giorgo",
            ["notes"] = {
                ["felis cothurnata"] = {
                    ["a"] = "Felis Cothurnata",
                    ["n"] = "ganking 10 levels under his",
                    ["t"] = 1795272019,
                },
            },
        },
        ["player|h?k? h?lystar"] = {
            ["added"] = 1794930873,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794930873,
            ["name"] = "H?k? H?lystar",
            ["note"] = "Sucht mitglieder f?r ini aber will nie rennen",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Sucht mitglieder f?r ini aber will nie rennen",
                    ["t"] = 1794930873,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|harke b?umling"] = {
            ["added"] = 1795088703,
            ["by"] = "Ellesmera Schattenkind",
            ["group"] = "players",
            ["guild"] = "Der Verlorene Kreuzzug",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795088703,
            ["name"] = "Harke B?umling",
            ["notes"] = {
                ["ellesmera schattenkind"] = {
                    ["a"] = "Ellesmera Schattenkind",
                    ["n"] = "Narzist Gnomeregan",
                    ["t"] = 1795088703,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|harpocrate lum?clat"] = {
            ["added"] = 1794932504,
            ["by"] = "Wax Divinemis",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794932504,
            ["name"] = "Harpocrate Lum?clat",
            ["notes"] = {
                ["wax divinemis"] = {
                    ["a"] = "Wax Divinemis",
                    ["n"] = "leaver",
                    ["t"] = 1794932504,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|j?n gitaxias"] = {
            ["added"] = 1794933922,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794933922,
            ["name"] = "J?n Gitaxias",
            ["note"] = "Ninjalooting",
            ["notes"] = {
                ["shiriana vastaya"] = {
                    ["a"] = "Shiriana Vastaya",
                    ["n"] = "Ninjalooting",
                    ["t"] = 1794933922,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 1 PvE",
        },
        ["player|j?y kiddow"] = {
            ["added"] = 1794937905,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794937905,
            ["name"] = "J?y Kiddow",
            ["note"] = "Kindergarten im Chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten im Chat",
                    ["t"] = 1794937905,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|jack bleed"] = {
            ["added"] = 1794746835,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794821281,
            ["name"] = "Jack bleed",
            ["notes"] = {
                ["relka kakansson"] = {
                    ["a"] = "Relka Kakansson",
                    ["n"] = "D??lig tank, ninja pullar, tar loot han inte beh??er i dalaran city",
                    ["t"] = 1794746835,
                },
                ["voltenc occit"] = {
                    ["del"] = true,
                    ["t"] = 1794821281,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|janzhek lrovzan"] = {
            ["added"] = 1795114565,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795114565,
            ["name"] = "Janzhek Lrovzan",
            ["notes"] = {
                ["eles viharszem"] = {
                    ["a"] = "Eles Viharszem",
                    ["n"] = "noob",
                    ["t"] = 1795114565,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 8 PvP",
        },
        ["player|jozan valdragon"] = {
            ["added"] = 1795120304,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795120304,
            ["name"] = "Jozan Valdragon",
            ["notes"] = {
                ["zocalo fduty"] = {
                    ["a"] = "Zocalo Fduty",
                    ["n"] = "Ali que me mato con su \"hermano\" en Clarofluvial. Matar",
                    ["t"] = 1795120304,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 2 PvP",
        },
        ["player|kalor adenayer"] = {
            ["added"] = 1794580851,
            ["group"] = "boosters",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794652138,
            ["name"] = "Kalor Adenayer",
            ["note"] = "Booster",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Booster",
                    ["t"] = 1794580851,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|klein kalib?r"] = {
            ["added"] = 1795007889,
            ["by"] = "Clara Geist",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1795007889,
            ["name"] = "Klein Kalib?r",
            ["notes"] = {
                ["clara geist"] = {
                    ["a"] = "Clara Geist",
                    ["n"] = "Hilfsbereit",
                    ["t"] = 1795007889,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 8 PvP",
        },
        ["player|leaf leaf"] = {
            ["added"] = 1795052473,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795052473,
            ["name"] = "leaf leaf",
            ["notes"] = {
                ["digi pigi"] = {
                    ["a"] = "Digi Pigi",
                    ["n"] = "Ninja",
                    ["t"] = 1795052473,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 8 PvP",
        },
        ["player|lion stormfang"] = {
            ["added"] = 1794954428,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794954428,
            ["name"] = "Lion Stormfang",
            ["notes"] = {
                ["lucis thunderballs"] = {
                    ["a"] = "Lucis Thunderballs",
                    ["n"] = "retard",
                    ["t"] = 1794954428,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|lumi lightwarden"] = {
            ["added"] = 1794756973,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794756973,
            ["name"] = "Lumi Lightwarden",
            ["notes"] = {
                ["soy minero"] = {
                    ["a"] = "Soy Minero",
                    ["n"] = "Mining ninja",
                    ["t"] = 1794756973,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 5 PvE",
        },
        ["player|martyrex dezl"] = {
            ["added"] = 1794740470,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794740470,
            ["name"] = "Martyrex Dezl",
            ["notes"] = {
                ["billy balloon"] = {
                    ["a"] = "Billy Balloon",
                    ["n"] = "Ninjalooting, Needing on BoEs",
                    ["t"] = 1794740470,
                },
                ["gneldre kjerring"] = {
                    ["a"] = "Gneldre Kjerring",
                    ["n"] = "Ninjalooting, Needing on BoEs",
                    ["t"] = 1794740470,
                },
                ["justanother humanpaladin"] = {
                    ["a"] = "Justanother Humanpaladin",
                    ["n"] = "Ninjalooting, Needing on BoEs",
                    ["t"] = 1794740470,
                },
                ["voltenc occit"] = {
                    ["a"] = "Voltenc Occit",
                    ["n"] = "Ninjalooting, Needing on BoEs",
                    ["t"] = 1794740470,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 4 PvP",
        },
        ["player|mini vampire"] = {
            ["added"] = 1794843849,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794843849,
            ["name"] = "Mini Vampire",
            ["notes"] = {
                ["vaelith guerresainte"] = {
                    ["a"] = "Vaelith Guerresainte",
                    ["n"] = "Connard",
                    ["t"] = 1794843849,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
        ["player|mizuk? pal"] = {
            ["added"] = 1794945551,
            ["group"] = "players",
            ["guild"] = "HORDE DURE",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794945551,
            ["name"] = "Mizuk? Pal",
            ["notes"] = {
                ["tarraghad xghalazobbi"] = {
                    ["a"] = "Tarraghad Xghalazobbi",
                    ["n"] = "Ninja, ninjas everything \"for offspec\", as if he had 3 specs, including BoE epics",
                    ["t"] = 1794945551,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 3 PvE",
        },
        ["player|morkka gigahamma"] = {
            ["added"] = 1795105783,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1795105816,
            ["name"] = "Morkka Gigahamma",
            ["notes"] = {
                ["staycalmo snegg"] = {
                    ["a"] = "Staycalmo Snegg",
                    ["n"] = "Kill",
                    ["t"] = 1795105816,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 4 PvP",
            ["votes"] = {
                ["staycalmo snegg"] = {
                    ["del"] = true,
                    ["t"] = 1795105803,
                    ["v"] = 0,
                },
            },
        },
        ["player|nerissi rogue"] = {
            ["added"] = 1795096815,
            ["group"] = "players",
            ["guild"] = "Zeldas Brauerei",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795096815,
            ["name"] = "Nerissi Rogue",
            ["note"] = "Thief",
            ["notes"] = {
                ["kiriko vastaya"] = {
                    ["a"] = "Kiriko Vastaya",
                    ["n"] = "Thief",
                    ["t"] = 1795096815,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 1 PvE",
        },
        ["player|ny? threat"] = {
            ["added"] = 1794961926,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["guild"] = "Limit Break",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795025851,
            ["name"] = "Ny? Threat",
            ["note"] = "Gambler 1",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Gambler 1",
                    ["t"] = 1794961926,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|nyalia beastwhisper"] = {
            ["added"] = 1794767174,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794847637,
            ["name"] = "Nyalia Beastwhisper",
            ["notes"] = {
                ["maeve moonshield"] = {
                    ["a"] = "Maeve Moonshield",
                    ["n"] = "steals mobs, not helped level 10",
                    ["t"] = 1794767174,
                },
                ["soy minero"] = {
                    ["del"] = true,
                    ["t"] = 1794847637,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 10 RP",
        },
        ["player|onyx shott"] = {
            ["added"] = 1794705153,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794821273,
            ["name"] = "Onyx Shott",
            ["notes"] = {
                ["maint moonborn"] = {
                    ["a"] = "Maint Moonborn",
                    ["n"] = "Overpulled and left Gnomeregan coz he didnt wanna do quests",
                    ["t"] = 1794705153,
                },
                ["xenshi lucas"] = {
                    ["del"] = true,
                    ["t"] = 1794821273,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 5 PvE",
        },
        ["player|orange peel"] = {
            ["added"] = 1795021166,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1795021166,
            ["name"] = "orange peel",
            ["notes"] = {
                ["bigg bonz"] = {
                    ["a"] = "Bigg Bonz",
                    ["n"] = "topper",
                    ["t"] = 1795021166,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 5 PvE",
        },
        ["player|os ca"] = {
            ["added"] = 1794783848,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794821262,
            ["name"] = "Os ca",
            ["notes"] = {
                ["maint moonborn"] = {
                    ["a"] = "Maint Moonborn",
                    ["n"] = "Retard, rq de dungeon sin razon alguna",
                    ["t"] = 1794783848,
                },
                ["topkek mage"] = {
                    ["del"] = true,
                    ["t"] = 1794821262,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 4 PvP",
            ["votes"] = {
                ["topkek mage"] = {
                    ["t"] = 1794783933,
                    ["v"] = -1,
                },
            },
        },
        ["player|pan norewegian name"] = {
            ["added"] = 1795218675,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795218675,
            ["name"] = "Pan norewegian name",
            ["notes"] = {
                ["zenn syg"] = {
                    ["a"] = "Zenn Syg",
                    ["n"] = "Killed while fighting elite",
                    ["t"] = 1795218675,
                },
            },
        },
        ["player|patty bangbang"] = {
            ["added"] = 1795026246,
            ["group"] = "players",
            ["guild"] = "Danish Legion",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795026246,
            ["name"] = "Patty Bangbang",
            ["notes"] = {
                ["orange peel"] = {
                    ["a"] = "Orange Peel",
                    ["n"] = "Greed tagger",
                    ["t"] = 1795026246,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|pawette mcfurface"] = {
            ["added"] = 1794948866,
            ["by"] = "Sjha Uul",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794948866,
            ["name"] = "Pawette Mcfurface",
            ["notes"] = {
                ["sjha uul"] = {
                    ["a"] = "Sjha Uul",
                    ["n"] = "BAR",
                    ["t"] = 1794948866,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 4 PvP",
        },
        ["player|piratenk?nig trafalgarlaw"] = {
            ["added"] = 1794937820,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794937820,
            ["name"] = "Piratenk?nig Trafalgarlaw",
            ["note"] = "Kindergarten im Chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten im Chat",
                    ["t"] = 1794937820,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|rabidia deepthorn"] = {
            ["added"] = 1794847448,
            ["group"] = "players",
            ["guild"] = "Morning Pump",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1794847448,
            ["name"] = "Rabidia Deepthorn",
            ["notes"] = {
                ["chipmyster vonhelga"] = {
                    ["a"] = "Chipmyster Vonhelga",
                    ["n"] = "Best tank",
                    ["t"] = 1794847448,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
        ["player|rainer winkl?hr"] = {
            ["added"] = 1794937749,
            ["by"] = "Xenshi Lucas",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794937749,
            ["name"] = "Rainer Winkl?hr",
            ["note"] = "Kindergarten im Chat",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten im Chat",
                    ["t"] = 1794937749,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|rash gun"] = {
            ["added"] = 1794850518,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794850518,
            ["name"] = "Rash Gun",
            ["notes"] = {
                ["auranetius noxar"] = {
                    ["a"] = "Auranetius Noxar",
                    ["n"] = "Leave Groupe When you Share Quests",
                    ["t"] = 1794850518,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
        ["player|razor kruger"] = {
            ["added"] = 1795255982,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795255982,
            ["name"] = "Razor Kruger",
            ["notes"] = {
                ["zenn syg"] = {
                    ["a"] = "Zenn Syg",
                    ["n"] = "Low lvl ganker",
                    ["t"] = 1795255982,
                },
            },
        },
        ["player|reidiga gratler"] = {
            ["added"] = 1794595129,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794595129,
            ["name"] = "Reidiga Gratler",
            ["note"] = "Runs Brain AFK and dont look on the Healer",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Runs Brain AFK and dont look on the Healer",
                    ["t"] = 1794595129,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|ripv?n winkle"] = {
            ["added"] = 1794842453,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794842453,
            ["name"] = "Ripv?n Winkle",
            ["notes"] = {
                ["emi nockels"] = {
                    ["a"] = "Emi Nockels",
                    ["n"] = "Ninja Looter",
                    ["t"] = 1794842453,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 2 PvP",
        },
        ["player|shengla fang"] = {
            ["added"] = 1794708230,
            ["group"] = "players",
            ["guild"] = "Steiw GMBH",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794708230,
            ["name"] = "Shengla Fang",
            ["note"] = "stealing Mobs",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "stealing Mobs",
                    ["t"] = 1794708230,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|shizzy"] = {
            ["added"] = 1794927183,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794927183,
            ["name"] = "Shizzy",
            ["notes"] = {
                ["bankwaermer thefirst"] = {
                    ["a"] = "Bankwaermer Thefirst",
                    ["n"] = "Druid, Leveling ganker",
                    ["t"] = 1794927183,
                },
                ["honeybadger onlibs"] = {
                    ["a"] = "Honeybadger Onlibs",
                    ["n"] = "Druid, Leveling ganker",
                    ["t"] = 1794927183,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 6 PvP",
        },
        ["player|sir henryus"] = {
            ["added"] = 1794847350,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794847350,
            ["name"] = "Sir Henryus",
            ["notes"] = {
                ["chipmyster vonhelga"] = {
                    ["a"] = "Chipmyster Vonhelga",
                    ["n"] = "Useless",
                    ["t"] = 1794847350,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
        ["player|sneaky peakys"] = {
            ["added"] = 1794683237,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "good",
            ["mod"] = 1794743966,
            ["name"] = "Sneaky Peakys",
            ["notes"] = {
                ["billy balloon"] = {
                    ["a"] = "Billy Balloon",
                    ["n"] = "Makker",
                    ["t"] = 1794683237,
                },
                ["xenshi lucas"] = {
                    ["del"] = true,
                    ["t"] = 1794743202,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
            ["votes"] = {
                ["xenshi lucas"] = {
                    ["del"] = true,
                    ["t"] = 1794738801,
                    ["v"] = 0,
                },
            },
        },
        ["player|snodig proclien"] = {
            ["added"] = 1794834900,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794834900,
            ["name"] = "Snodig Proclien",
            ["notes"] = {
                ["fieel thesecond"] = {
                    ["a"] = "Fieel Thesecond",
                    ["n"] = "loots all quest items then leaves",
                    ["t"] = 1794834900,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 2 PvP",
        },
        ["player|sparky stormwhisper"] = {
            ["added"] = 1794768826,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794768826,
            ["name"] = "Sparky Stormwhisper",
            ["notes"] = {
                ["keladan murmeronce"] = {
                    ["a"] = "Keladan Murmeronce",
                    ["n"] = "Griefing, stealing loot in dungeons",
                    ["t"] = 1794768826,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 9 RP PvP",
        },
        ["player|theomir halsey"] = {
            ["added"] = 1795198424,
            ["by"] = "Olorunn Whitebeard",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795198424,
            ["name"] = "Theomir Halsey",
            ["notes"] = {
                ["olorunn whitebeard"] = {
                    ["a"] = "Olorunn Whitebeard",
                    ["n"] = "Ninja: RFK needade allt av v?rde, oavsett",
                    ["t"] = 1795198424,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 10 RP",
        },
        ["player|vi destructive"] = {
            ["added"] = 1795005435,
            ["by"] = "Clara Geist",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795005435,
            ["name"] = "Vi Destructive",
            ["notes"] = {
                ["clara geist"] = {
                    ["a"] = "Clara Geist",
                    ["n"] = "keine Gruppe, farmt Questmobs f?r XP ab",
                    ["t"] = 1795005435,
                },
                ["klee blatt"] = {
                    ["a"] = "Klee Blatt",
                    ["n"] = "keine Gruppe, farmt Questmobs f?r XP ab",
                    ["t"] = 1795005435,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 8 PvP",
        },
        ["player|vralaak nightborn"] = {
            ["added"] = 1795085734,
            ["by"] = "Windfury Seri?s",
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795085734,
            ["name"] = "Vralaak Nightborn",
            ["notes"] = {
                ["windfury seri?s"] = {
                    ["a"] = "Windfury Seri?s",
                    ["n"] = "Legit retarded",
                    ["t"] = 1795085734,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 6 PvP",
        },
        ["player|vultor lotus"] = {
            ["added"] = 1794752495,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794752495,
            ["name"] = "Vultor Lotus",
            ["note"] = "Verl??sst gruppen ohne was zu sagen ...",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Verl??sst gruppen ohne was zu sagen ...",
                    ["t"] = 1794752495,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|xarenthil blutfluch"] = {
            ["added"] = 1795090641,
            ["group"] = "players",
            ["guild"] = "The Lunatics",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795090683,
            ["name"] = "Xarenthil Blutfluch",
            ["notes"] = {
                ["rainer winnkler"] = {
                    ["a"] = "Rainer Winnkler",
                    ["n"] = "Meldemuschi",
                    ["t"] = 1795090683,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 8 PvP",
            ["votes"] = {
                ["rainer winnkler"] = {
                    ["t"] = 1795090756,
                    ["v"] = -1,
                },
            },
        },
        ["player|xinef pr?tor"] = {
            ["added"] = 1795203251,
            ["group"] = "players",
            ["guild"] = "Day Walker",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795203251,
            ["name"] = "Xinef Pr?tor",
            ["note"] = "Solo player, no team player",
            ["notes"] = {
                ["shiriana vastaya"] = {
                    ["a"] = "Shiriana Vastaya",
                    ["n"] = "Solo player, no team player",
                    ["t"] = 1795203251,
                },
            },
            ["realm"] = "CAMWOW EU5 Realm 1 PvE",
        },
        ["player|xyl amon"] = {
            ["added"] = 1794651164,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1794651164,
            ["name"] = "Xyl Amon",
            ["note"] = "Kindergarten Spam",
            ["notes"] = {
                ["xenshi lucas"] = {
                    ["a"] = "Xenshi Lucas",
                    ["n"] = "Kindergarten Spam",
                    ["t"] = 1794651164,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 3 PvE",
        },
        ["player|zerion dawnblade"] = {
            ["added"] = 1795041073,
            ["group"] = "players",
            ["kind"] = "player",
            ["list"] = "black",
            ["mod"] = 1795041073,
            ["name"] = "zerion dawnblade",
            ["notes"] = {
                ["kush west"] = {
                    ["a"] = "Kush West",
                    ["n"] = "ninja loot und arschkind",
                    ["t"] = 1795041073,
                },
            },
            ["realm"] = "CAMWOW EU4 Realm 7 PvE",
        },
    }

local TOMBSTONES = {
        ["player|???????? ????????????"] = 1794936766,
        ["player|aegis l?ghtbringer"] = 1794918720,
        ["player|alice schwarzer"] = 1794578862,
        ["player|feldolin d??sterlicht"] = 1794578864,
        ["player|feldolin d?sterlicht"] = 1794578864,
        ["player|feldolin düsterlicht"] = 1794578864,
        ["player|nafameritas xll"] = 1794565146,
        ["player|note testguy"] = 1794607684,
        ["player|poise h??gri"] = 1794652546,
    }

local GROUPS = {
        ["boosters"] = {
            ["builtin"] = true,
            ["name"] = "Boosters",
            ["order"] = 4,
        },
        ["boostgold"] = {
            ["builtin"] = true,
            ["name"] = "Booster & gold seller",
            ["order"] = 6,
        },
        ["bots"] = {
            ["builtin"] = true,
            ["name"] = "Bots",
            ["order"] = 2,
        },
        ["g7"] = {
            ["name"] = "shitters",
            ["order"] = 7,
        },
        ["goldsellers"] = {
            ["builtin"] = true,
            ["name"] = "Gold sellers",
            ["order"] = 5,
        },
        ["other"] = {
            ["builtin"] = true,
            ["name"] = "Other",
            ["order"] = 3,
        },
        ["players"] = {
            ["builtin"] = true,
            ["name"] = "Players",
            ["order"] = 1,
        },
    }

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
	C_Timer.After(8, function()
		local F = ns.FBL
		if not (F and F.ImportJSON and F.JsonEncode) then return end
		-- live global, not F.db: several addons declare FBLDB and the last
		-- saved-variables file to load replaces it - a cached .db can point
		-- at an orphaned table whose flag write never reaches disk
		local db = _G.FBLDB
		if type(db) ~= "table" then return end
		db.imports = db.imports or {}
		if db.imports.xenshiLucas then return end

		-- entries may already sit in the store (sync, a shared saved
		-- file): importing again would only re-report them, so probe the
		-- list first and stay silent either way - this is bootstrap
		-- housekeeping, not news
		local missing = 0
		for _, e in pairs(ENTRIES) do
			local k = F.Key and F.Key(e.kind == "guild" and "guild" or "player", e.name)
			if not (k and db.entries and db.entries[k]) then
				missing = missing + 1
			end
		end
		if missing == 0 then
			db.imports.xenshiLucas = true
			return
		end

		-- keyed saved-variable maps -> the array shape the importer reads
		local entries = {}
		for _, e in pairs(ENTRIES) do entries[#entries + 1] = e end
		local tombs = {}
		for k, ts in pairs(TOMBSTONES) do
			local kind, name = k:match("^(%a+)|(.+)$")
			if kind then tombs[#tombs + 1] = { kind = kind, name = name, removed = ts } end
		end
		local groups = {}
		for id, g in pairs(GROUPS) do
			groups[#groups + 1] = { id = id, name = g.name, builtin = g.builtin }
		end

		local json = F.JsonEncode({
			app = "ForeverBlackListed", version = 1,
			entries = entries, tombstones = tombs, groups = groups,
		})
		F.ImportJSON(json, nil, true)
		db.imports.xenshiLucas = true
	end)
end)
