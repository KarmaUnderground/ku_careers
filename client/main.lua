ESX = nil

local Keys = { ["E"] = 38, ["LEFTSHIFT"] = 21, ["LEFTCTRL"] = 3 }
local xPlayer = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

  	while ESX.GetPlayerData().job == nil do
  		Citizen.Wait(10)
  	end

    xPlayer = ESX.GetPlayerData()
end)

local inCraftCycle = nil
local isMenuOpen = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if IsControlJustReleased(0, Keys['E']) and IsControlPressed(0, Keys["LEFTSHIFT"]) and Config.AllowSkillModificaton then
            ShowSkills()
        elseif IsControlJustReleased(0, Keys['E']) and IsControlPressed(0, Keys["LEFTCTRL"]) and Config.AllowSkillModificaton then
            --EShowSkills()
        elseif IsControlJustReleased(0, Keys['E']) then
            if inCraftCycle then
                showVendorMenu(inCraftCycle)
            else
                ESX.UI.Menu.CloseAll()
            end
        end
    end
end)

function ShowSkills()
    ESX.TriggerServerCallback("esx_jobs_skill:getSkills", function(skills)
        local skills_rows = {}
        local skills_sum = 0

        for name, skill in pairs(skills) do
            table.insert(skills_rows, {
                data = name,
                cols = {
                    _U(skill.craft_cycle),
                    _U(skill.name),
                    skill.level,
                    '{{' .. _U('forget_all') .. '|all}}'
                }
            })
            skills_sum = skills_sum + tonumber(skill.level)
        end

        table.insert(skills_rows, {
            data = 'sum',
            cols = {
                '','','',
                'Total:' .. skills_sum
            }
        })

        local skills_menu = {
            title = _U('skill_list_title'),
            head = {_U('skill_list_table_title_category'), _U('skill_list_table_title_name'), _U('skill_list_table_title_level'), _U('skill_list_table_title_action')},
            rows = skills_rows
        }

        ESX.UI.Menu.CloseAll()

        ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'ku_jobs_skills_skill_list', skills_menu,
            function(response, menu)
                menu.close()
                if response.value == 'all' then
                    ForgetSkill(skills[response.data])
                end
            end,
            function(response, menu)
                menu.close()
            end
        )
    end)
end

function ForgetSkill(skill)
    ESX.TriggerServerCallback("esx_jobs_skill:removeSkill", function()end, skill)
end

function showVendorMenu(craft_cycle)
    -- Utiliser un menu graphique cool
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ku_jobs_skills_vendor_menu',
    {
        title    = _U("vendor_menu_title", _U(craft_cycle.db_name)),
        align    = 'center',
        elements = {
            { label = _U("vendor_menu_action_sell", _U(craft_cycle.db_name), _U('$_before'), craft_cycle.vendor.price_buy, _U('$_after'), _U(craft_cycle.unit)), value = "sell" },
            { label = _U("vendor_menu_action_buy", _U(craft_cycle.db_name), _U('$_before'), craft_cycle.vendor.price_sell, _U('$_after'), _U(craft_cycle.unit)), value = "buy" },
            { label = _U("cancel"), value = "cancel" }
        }
    },
    function(data, menu)
        menu.close()
        if not (data.current.value == "cancel") then
            showVendorMenuQuantity(craft_cycle, data.current.value)
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

function showVendorMenuQuantity(craft_cycle, type)
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'ku_jobs_skills_vendor_menu_qty',
    {
        title = _U('vendor_menu_qty_question', _U(craft_cycle.unit),  _U(craft_cycle.db_name), string.lower(_U(type)))
    },
    function(data, menu)
        menu.close()
        if type == "buy" then
            vendorSell(craft_cycle, data.value)
        elseif type == "sell" then
            vendorBuy(craft_cycle, data.value)
        end
    end,
    function(data, menu)
        menu.close()
    end)
end

function vendorBuy(craft_cycle, qty)
    ESX.TriggerServerCallback("esx_jobs_skill:vendorBuy", function(response)
        if response.transaction.status == "success" then
            ESX.ShowNotification(_U('vendor_transaction_sell_success', response.transaction.quantity, string.lower(_U(craft_cycle.unit)), string.lower(_U(craft_cycle.db_name))))
        else
            ESX.ShowNotification(_U(response.transaction.message, string.lower(_U(craft_cycle.db_name))))
        end
    end, craft_cycle, qty)
end

function canSeeMarker(marker)
    return GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), marker.Pos.x, marker.Pos.y, marker.Pos.z, true) < 100
end

function isInMarker(marker)
    return GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), marker.Pos.x, marker.Pos.y, marker.Pos.z, true) < marker.Size.x / 2
end

function vendorSell(craft_cycle, qty)
    ESX.TriggerServerCallback("esx_jobs_skill:vendorSell", function(response)
        if response.transaction.status == "success" then
            ESX.ShowNotification(_U('vendor_transaction_buy_success', response.transaction.quantity, string.lower(_U(craft_cycle.unit)), string.lower(_U(craft_cycle.db_name))))
        else
            ESX.ShowNotification(_U(response.transaction.message, craft_cycle.max, string.lower(_U(craft_cycle.unit)), string.lower(_U(craft_cycle.db_name))))
        end
    end, craft_cycle, qty)
end

RegisterNetEvent('esx_jobs_skill:anim')
AddEventHandler('esx_jobs_skill:anim', function(mood)
    if mood == "good" then
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_yes_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    else
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_no_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    end
end)

local in_the_zone = false
local get_in_the_zone = false
Citizen.CreateThread(function() -- Display vendor circles
    while true do
        Citizen.Wait(1)

        if xPlayer then
            for name, craft_cycle in pairs(Config.Jobs[xPlayer.job.name].craft_cycles) do
                if craft_cycle.vendor then
                    if(craft_cycle.vendor.Marker ~= -1 and canSeeMarker(craft_cycle.vendor)) then
                        DrawMarker(craft_cycle.vendor.Marker, craft_cycle.vendor.Pos.x, craft_cycle.vendor.Pos.y, craft_cycle.vendor.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, craft_cycle.vendor.Size.x, craft_cycle.vendor.Size.y, craft_cycle.vendor.Size.z, craft_cycle.vendor.Color.r, craft_cycle.vendor.Color.g, craft_cycle.vendor.Color.b, 100, false, true, 2, false, false, false, false)
                        in_the_zone = isInMarker(craft_cycle.vendor)
                        if(in_the_zone and not get_in_the_zone) then
                            get_in_the_zone = true

                            inCraftCycle = craft_cycle
                            hintMessage = _U(craft_cycle.db_name .. "_hint")
                        elseif(not in_the_zone and get_in_the_zone) then
                            get_in_the_zone = false

                            inCraftCycle = nil
                            ESX.UI.Menu.CloseAll()
                        end
                    end
                end
      		end
        end
	end
end)

hintMessage = ""
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		if not (hintMessage == "") then
			ESX.ShowHelpNotification(hintMessage)
            hintMessage = ""
		end
	end
end)
