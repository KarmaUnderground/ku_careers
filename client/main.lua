local Keys = {
    ["E"] = 38, ["LEFTSHIFT"] = 21, ["LEFTCTRL"] = 3
}

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if IsControlJustReleased(0, Keys['E']) and IsControlPressed(0, Keys["LEFTSHIFT"]) and Config.AllowSkillModificaton then
            ShowSkills()
        elseif IsControlJustReleased(0, Keys['E']) and IsControlPressed(0, Keys["LEFTCTRL"]) and Config.AllowSkillModificaton then
            --EShowSkills()
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

        ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'skill_list', skills_menu,
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

RegisterNetEvent('esx_jobs_skill:anim')
AddEventHandler('esx_jobs_skill:anim', function(mood)
    if mood == "good" then 
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_yes_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    else
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_no_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    end
end)
