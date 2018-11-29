Config.Jobs.gas = {}
Config.Jobs.gas.craft_cycles = {
    oil = {
        name = _U("f_fuel"),
        db_name = "oil",
        time = 5000,
        max = 24,
        add = 1,
        remove = 1,
        requires = "nothing",
        requires_name = "Nothing",
        skill_rate = 5000,
        craft_cycle_step = 1,
        craft_type = "gathering",
        position = {
            Pos = {x = 609.58, y = 2856.74, z = 38.90},
            Size = {x = 20.0, y = 20.0, z = 1.0},
            Color = {r = 204, g = 204, b = 0},
            Marker = 1,
            Blip = true,
            Name = _U("f_drill_oil"),
            Type = "work",
            Hint = _U("f_drillbutton"),
            GPS = {x = 2736.94, y = 1417.99, z = 23.48}
        }
    },
    refined_oil = {
        name = _U("f_fuel_refine"),
        db_name = "refined_oil",
        time = 5000,
        max = 24,
        add = 1,
        remove = 2,
        requires = "petrol",
        requires_name = _U("f_fuel"),
        skill_rate = 5000,
        craft_cycle_step = 2,
        craft_type = "transform",
        position = {
            Pos = {x = 2736.94, y = 1417.99, z = 23.48},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Color = {r = 204, g = 204, b = 0},
            Marker = 1,
            Blip = true,
            Name = _U("f_fuel_refine"),
            Type = "work",
            Hint = _U("f_refine_fuel_button"),
            GPS = {x = 265.75, y = -3013.39, z = 4.73}
        }
    },
    gas = {
        name = _U("f_gas"),
        db_name = "gas",
        time = 5000,
        max = 24,
        add = 2,
        remove = 1,
        requires = "petrol_raffin",
        requires_name = _U("f_fuel_refine"),
        skill_rate = 5000,
        craft_cycle_step = 3,
        craft_type = "transform",
        position = {
            Pos = {x = 265.75, y = -3013.39, z = 4.73},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Color = {r = 204, g = 204, b = 0},
            Marker = 1,
            Blip = true,
            Name = _U("f_fuel_mixture"),
            Type = "work",
            Hint = _U("f_fuel_mixture_button"),
            GPS = {x = 491.40, y = -2163.37, z = 4.91}
        },
        vendor = {
            Pos = {x = 491.40, y = -2163.37, z = 4.91},
            Color = {r = 204, g = 204, b = 0},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Marker = 1,
            Blip = true,
            Name = _U("f_deliver_gas"),
            Type = "delivery",
            Spawner = 1,
            Item = {
                {
                    name = _U("delivery"),
                    time = 500,
                    remove = 1,
                    max = 100, -- if not present, probably an error at itemQtty >= item.max in esx_jobs_sv.lua
                    price = 61,
                    drop = 100
                }
            },

            Hint = _U("f_deliver_gas_button"),
            GPS = {x = 609.58, y = 2856.74, z = 39.49}
        },
        seller = {

        }
    }
}

Config.Jobs.gas.BlipInfos = {
    Sprite = 436,
    Color = 5
}

Config.Jobs.gas.Vehicles = {
    {
        Spawner = 1,
        Hash = "phantom",
        Trailer = "tanker",
        HasCaution = true,
        spawner = {
            Pos = {x = 554.59, y = -2314.43, z = 4.86},
            Size = {x = 3.0, y = 3.0, z = 2.0},
            Color = {r = 204, g = 204, b = 0},
            Marker = 1,
            Blip = false,
            Name = _U("spawn_veh"),
            Type = "vehspawner",
            Spawner = 1,
            Hint = _U("spawn_truck_button"),
            Caution = 2000,
            GPS = {x = 602.25, y = 2926.62, z = 39.68}
        },
        spawn = {
            Pos = {x = 570.54, y = -2309.70, z = 4.90},
            Size = {x = 3.0, y = 3.0, z = 1.0},
            Marker = -1,
            Blip = false,
            Name = _U("service_vh"),
            Type = "vehspawnpt",
            Spawner = 1,
            GPS = 0,
            Heading = 0
        },
        dispawn = {
            Pos = {x = 520.68, y = -2124.21, z = 4.98},
            Size = {x = 5.0, y = 5.0, z = 1.0},
            Color = {r = 255, g = 0, b = 0},
            Marker = 1,
            Blip = false,
            Name = _U("return_vh"),
            Type = "vehdelete",
            Hint = _U("return_vh_button"),
            Spawner = 1,
            Caution = 2000,
            GPS = 0,
            Teleport = 0
        },
    }
}

Config.Jobs.gas.CloakRoom = {
    Pos = {x = 557.93, y = -2327.90, z = 4.82},
    Size = {x = 3.0, y = 3.0, z = 2.0},
    Color = {r = 204, g = 204, b = 0},
    Marker = 1,
    Blip = true,
    Name = _U("f_oil_refiner"),
    Type = "cloakroom",
    Hint = _U("cloak_change"),
    GPS = {x = 554.59, y = -2314.43, z = 4.86}
}
