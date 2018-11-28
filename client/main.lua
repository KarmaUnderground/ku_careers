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
        end
        if IsControlJustReleased(0, Keys['E']) and IsControlPressed(0, Keys["LEFTCTRL"]) and Config.AllowSkillModificaton then
            ShowSkills()
        end
    end
end)

function ShowSkills()
    ESX.TriggerServerCallback("esx_jobs_skill:getAllSkills", function(skills)

        local skills_rows = {}
        local skills_sum = 0

        for name, skill in pairs(skills) do
            table.insert(skills_rows, {
                data = name,
                cols = {
                    skill.label, 
                    skill.level,
                    '{{' .. _U('forget_all') .. '|all}} {{' .. _U('forget_part') .. '|some}}'
                }
            })
            skills_sum = skills_sum + tonumber(skill.level)
        end

        table.insert(skills_rows, {
            data = 'sum',
            cols = {
                'Total', 
                skills_sum,
                ''
            }
        })

        local skills_menu = {
            title = _U('skill_list_title'),
            head = {_U('skill_list_table_title_name'), _U('skill_list_table_title_level'), _U('skill_list_table_title_action')},
            rows = skills_rows
        }

        ESX.UI.Menu.CloseAll()

        ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'skill_list', skills_menu,
            function(response, menu)
                menu.close()
                if response.value == 'all' then
                    ForgetSkill(response.data, 100)
                elseif response.value == 'some' then
                    ShowForgetSkill(response.data)
                end
            end,
            function(response, menu)
                menu.close()
            end
        )
    end)
end

function ShowForgetSkill(skill)
    ESX.UI.Menu.Open(
        'dialog', GetCurrentResourceName(), 'skill_forget_confirmation',
        {
            title = _U('skill_forget_dialog_title')
        },
        function(response, menu)
            local qty = tostring(response.value)                              
            menu.close()
            ForgetSkill(skill, qty)
        end,
        function(response, menu)
            menu.close()
        end
    ) 
end

function ForgetSkill(skill, qty)
    ESX.TriggerServerCallback("esx_jobs_skill:removeSkillLevel", function()end, skill, qty)
end

RegisterNetEvent('esx_jobs_skill:anim')
AddEventHandler('esx_jobs_skill:anim', function(mood)
    if mood == "good" then 
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_yes_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    else
        TaskPlayAnim(GetPlayerPed(-1), "gestures@m@standing@casual" , "gesture_nod_no_hard", 8.0, -8.0, 1000, 0, 0, false, false, false)
    end
end)
