Config.Jobs.gas = {}
Config.Jobs.gas.steps = {
    oil = {
        name = _U("oil_name"),
        db_name = "oil",
        unit = "oil_unit",
        time = 5000,
        max = 50,
        add = 1,
        remove = 1,
        requires = "nothing",
        requires_name = "Nothing",
        skill_rate = 5000,
        work_type = "gather",
        position = {
            Pos = {x = 609.58, y = 2856.74, z = 38.90},
            Size = {x = 20.0, y = 20.0, z = 1.0},
            Color = {r = 204, g = 204, b = 0},
            Marker = 1,
            Blip = true,
            Name = _U("oil_action_name"),
            Type = "work",
            Hint = _U("oil_hint"), -- Changer
            GPS = {x = 2736.94, y = 1417.99, z = 23.48}
        },
        vendor = {
            Pos = {x = 604.62, y = 2919.60, z = 38.75},
            Color = {r = 0, g = 204, b = 0},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Marker = 1,
            Blip = true,
            Name = _U("oil_deliver"),
            Type = "vendor",
            Spawner = 1,
            price_buy = 5,
            price_sell = 50,
            Hint = _U("f_deliver_gas_button") -- Changer
        }
    },
    refined_oil = {
        name = _U("f_fuel_refine"),
        db_name = "refined_oil",
        unit = "refined_oil_unit",
        time = 5000,
        max = 100,
        add = 4,
        remove = 1,
        requires = "oil",
        requires_name = _U("oil"),
        skill_rate = 5000,
        work_type = "transform",
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
        },
        vendor = {
            Pos = {x = 2689.35, y = 1506.57, z = 23.50},
            Color = {r = 0, g = 204, b = 0},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Marker = 1,
            Blip = true,
            Name = _U("refined_oil_deliver"),
            Type = "vendor",
            Spawner = 1,
            price_buy = 5,
            price_sell = 50,
            Hint = _U("f_deliver_gas_button") -- Changer
        }
    },
    gas = {
        name = _U("f_gas"),
        db_name = "gas",
        unit = "gas_unit",
        time = 5000,
        max = 200,
        add = 2,
        remove = 1,
        requires = "refined_oil",
        requires_name = _U("refined_oil"),
        skill_rate = 5000,
        work_type = "transform",
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
            Color = {r = 0, g = 204, b = 0},
            Size = {x = 10.0, y = 10.0, z = 1.0},
            Marker = 1,
            Blip = true,
            Name = _U("f_deliver_gas"),
            Type = "vendor",
            Spawner = 1,
            price_buy = 5,
            price_sell = 50,
            Hint = _U("f_deliver_gas_button") -- Changer
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
