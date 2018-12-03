ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function get_job_step(skill)
    if not Config.Jobs[skill.job] or not Config.Jobs[skill.job].steps[skill.name] then
        return nil
    end

    return Config.Jobs[skill.job].steps[skill.name]
end

function commit_skills(xPlayer)
    local player_skills = get_skills(xPlayer)

    for job_name, jobs in pairs(player_skills) do
        for skill_name, skill in pairs(jobs) do
            MySQL.Async.execute('UPDATE `user_skills` SET `tries` = @tries WHERE `identifier` = @Identifier AND `job` = @Job AND `name` = @Name',
            {
                ['@Identifier'] = xPlayer.identifier,
                ['@Job']        = skill.job,
                ['@Name']       = skill.name,
                ['@tries']      = skill.tries,
            })
        end
    end
end

function get_skills(xPlayer)
    local player_skills = xPlayer.get('skills')
    local formated_skill = nil

    if not player_skills then -- Skills have not been initiated
        math.randomseed(os.time()) -- Should be removed from here and added to a global server function and be run once

        player_skills = {}

        local result = MySQL.Sync.fetchAll('SELECT `job`, `name`, `tries` FROM `user_skills` WHERE `identifier` = @Identifier ORDER BY `job`', {
            ['@Identifier'] = xPlayer.identifier
        })

        for i=1, #result, 1 do
            skill = format_skill(result[i].job, result[i].name, result[i].tries)

            if skill then
                if not player_skills[skill.job] then
                    player_skills[skill.job] = {}
                end

                player_skills[skill.job][skill.name] = skill
            end
        end

        xPlayer.set('skills', player_skills)
    end

    return player_skills
end

function get_skills_stats(xPlayer)
    local player_skills = get_skills(xPlayer)
    local skills_sum = 0
    local skills_count = 0

    for job_name, jobs in pairs(player_skills) do
        for skill_name, skill in pairs(jobs) do
            skills_sum = skills_sum + tonumber(skill.level)
            skills_count = skills_count + 1
        end
    end

    return {sum = skills_sum, count = skills_count}
end

function get_skill(xPlayer, job, name)
    local player_skills = get_skills(xPlayer)
    local skill = player_skills[job][name]

    if not skill then -- This skill does not exists
        local skill = format_skill(job, name, 0)

        if not formated_skill then
            return nil
        end

        player_skills[job][name] = skill
        xPlayer.set('skills', player_skills)

        MySQL.Async.execute('INSERT INTO `user_skills` (`identifier`, `job`, `name`, `tries`) VALUES (@Identifire, @Job, @Name, @Tries)',
        {
            ['@Identifire'] = xPlayer.identifier,
            ['@Job']        = job,
            ['@Name']       = name,
            ['@Tries']      = 0
        })

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_new", _U(name)))
    end

    return skill
end

function format_skill(job, name, tries)
    if get_job_step({job = job, name = name}) then
        local formatted_skill = get_level_from_tries({
            job = job,
            name = name,
            tries = tries,
            level = 0
        })

        return formatted_skill
    end

    return nil
end

function get_level_from_tries(skill)
    local skill_rate = get_job_step(skill).skill_rate

    skill.level = math.sqrt((skill_rate*skill_rate) - ((skill_rate - skill.tries) * (skill_rate - skill.tries)))
    skill.level = ESX.Round(((skill.level/skill_rate)*100),1)

    return skill
end

function remove_skill(xPlayer, skill)
    local player_skills = get_skills(xPlayer)

    player_skills[skill.job][skill.name] = nil
    xPlayer.set('skills', player_skills)

    MySQL.Async.execute('DELETE FROM `user_skills` WHERE `identifier` = @Identifire AND `name` = @Name',
    {
        ['@Identifire'] = xPlayer.identifier,
        ['@Name']       = skill.name
    })
end

function increase_skill(xPlayer, skill)
    local roll = math.random(1000) / 10

    if skill.level < roll then
        set_skill_tries(xPlayer, skill, skill.tries + 1)

        local skills_stats = get_skills_stats(xPlayer)
        if skills_stats.sum > Config.GlobalSkillLimit then
            decrease_random_skill(xPlayer, skill)
        end

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('skill_up', _U(skill.name), skill.level + 0.1))
    end
end

function set_skill_tries(xPlayer, skill, tries, show_message)
    if tries <= 0 then
        remove_skill(xPlayer, skill)

        if show_message == true then
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_removed", _U(skill.name)))
        end
    else
        local player_skills = get_skills(xPlayer)

        skill.tries = tries
        skill = get_level_from_tries(skill)

        player_skills[skill.job][skill.name] = skill

        xPlayer.set('skills', player_skills)

        commit_skills(xPlayer)

        if show_message == true then
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_modified", _U(skill.name), level))
        end
    end
end

function decrease_random_skill(xPlayer, not_skill)
    local player_skills = get_skills(xPlayer)
    local skills_stats = get_skills_stats(xPlayer)

    if skills_stats.count > 1 then
        local skill = not_skill
        local index = -1
        local counter = -1

        while(skill.name == not_skill.name)
        do
            index = math.random(1, skills_stats.count)
            counter = 1

            for name, loop_skill in pairs(player_skills) do
                if index == counter then
                    skill = loop_skill
                    break
                end
                counter = counter + 1
            end
        end

        set_skill_tries(xPlayer, skill, skill.tries - 1)

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('skill_down', _U(skill.name), skill.tries - 1))
    end
end

function execute_skill(xPlayer, skill)
    local step = get_job_step(skill)
    local mood = "bad"
    local diff = 12.5
    local variace = 0.8
    local add = 0
    local roll_skill = math.random(1000) / 10

    if skill.level > roll_skill then
        mood = "good"

        local roll_qty = rand_normal(skill.level - diff, skill.level + diff, variace, 0.1, 100)
        local multiplyer = 1 --local multiplyer = get_job_step(skill).add

        add = (math.floor(roll_qty/25)+1)*multiplyer
    end

    xPlayer.addInventoryItem(skill.name, add)

    if Config.PlayAnimation then
        TriggerClientEvent("esx_jobs_skill:anim", xPlayer.source, mood)
    end
end

--******************************************************************
-- Working vehicle management
--******************************************************************
local isVehicleInArea = {}
RegisterServerEvent('esx_jobs_skills:areaVehiclesResponse')
AddEventHandler('esx_jobs_skills:areaVehiclesResponse', function(response)
    isVehicleInArea[ESX.GetPlayerFromId(source).identifier] = response
end)

function isVehicleCloseEnough(xPlayer, step)
    TriggerClientEvent('esx_jobs_skill:getVehicleInArea', xPlayer.source, step.vehicle, 'esx_jobs_skills:areaVehiclesResponse')

    while isVehicleInArea[xPlayer.identifier] == nil do
        Citizen.Wait(1)
    end
    local reponse = isVehicleInArea[xPlayer.identifier]
    isVehicleInArea[xPlayer.identifier] = nil

    return reponse
end

--******************************************************************
-- Vendor actions
--******************************************************************
-- Vendor sell action
ESX.RegisterServerCallback('esx_jobs_skill:vendorSell', function(source, cb, step, qty)
    local xPlayer = ESX.GetPlayerFromId(source)
    local step = get_job_step({job = xPlayer.job.name, name = step})
    --TODO: KU-22

    if not isVehicleCloseEnough(xPlayer, step) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("working_vehicle_too_far"))
        return false
    end

    local transaction_status = 'success'
    local transaction_status_message = ''
    local transaction_quantity = qty
    local transaction_total = 0

    local inventoryItem = xPlayer.getInventoryItem(step.db_name)
    local inventory_count = inventoryItem and xPlayer.getInventoryItem(step.db_name).count or 0

    if inventory_count >= step.max then
        transaction_status = 'fail'
        transaction_quantity = 0
        transaction_status_message = 'vendor_too_many_items_in_inventory'
    elseif inventory_count + qty > step.max then
        transaction_quantity = step.max - inventory_count
    end

    if transaction_quantity > 0 then
        if xPlayer.getMoney() >= step.vendor.price_sell then -- Can at least buy 1
            if xPlayer.getMoney() < transaction_total then -- Can't buy all
                transaction_quantity = math.floor(xPlayer.getMoney()/step.vendor.price_sell)
            end
            transaction_total = step.vendor.price_sell * transaction_quantity

            xPlayer.removeMoney(transaction_total)
            xPlayer.addInventoryItem(step.db_name, transaction_quantity)
        else
            transaction_status = 'fail'
            transaction_quantity = 0
            transaction_status_message = 'vendor_no_money'
        end
    end

    cb({
        transaction = {
            status = transaction_status,
            message = transaction_status_message,
            quantity = transaction_quantity,
            total = transaction_total
        }
    })
end)

-- Vendor buy action
ESX.RegisterServerCallback('esx_jobs_skill:vendorBuy', function(source, cb, step, qty)
    local xPlayer = ESX.GetPlayerFromId(source)
    local step = get_job_step({job = xPlayer.job.name, name = step})
    --TODO: KU-22

    if not isVehicleCloseEnough(xPlayer, step) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("working_vehicle_too_far"))
        return false
    end

    local transaction_status = 'success'
    local transaction_status_message = ''
    local transaction_quantity = qty

    local inventory_count = xPlayer.getInventoryItem(step.db_name).count

    if inventory_count == 0 then
        transaction_status = 'fail'
        transaction_quantity = 0
        transaction_status_message = 'vendor_no_item_in_inventory'
    elseif inventory_count < transaction_quantity then
        transaction_quantity = inventory_count
    end

    if transaction_quantity > 0 then
        transaction_total = step.vendor.price_buy * transaction_quantity
        xPlayer.removeInventoryItem(step.db_name, transaction_quantity)
        xPlayer.addMoney(transaction_total)
    end

    cb({
        transaction = {
            status = transaction_status,
            message = transaction_status_message,
            quantity = transaction_quantity,
            total = transaction_total
        }
    })
end)

--******************************************************************
-- Skill management server callbacks
--******************************************************************
ESX.RegisterServerCallback('esx_jobs_skill:getSkills', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local skills = get_skills(xPlayer)
    cb(skills)
end)

ESX.RegisterServerCallback('esx_jobs_skill:removeSkill', function(source, cb, skill)
    local xPlayer = ESX.GetPlayerFromId(source)
    remove_skill(xPlayer, skill)
    cb()
end)

ESX.RegisterServerCallback('esx_jobs_skill:getInventoryItem', function(source, cb, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getInventoryItem(name))
end)

--******************************************************************
-- Execute working actions
--******************************************************************
function start_working(xPlayer, skill)
    local step = get_job_step(skill)

    if not isVehicleCloseEnough(xPlayer, step) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("working_vehicle_too_far"))
        return false
    end

    execute_skill(xPlayer, skill)
    increase_skill(xPlayer, skill)
end

TriggerEvent('esx_jobs:registerHook', "overrides", "add_item", "ku_jobs_skills_execute_skill", function (params)
    local xPlayer = params.xPlayer
    local skill = get_skill(xPlayer, xPlayer.job.name, params.item.db_name)

    function start_working(xPlayer, skill)
end)

--******************************************************************
-- Register external jobs
--******************************************************************
TriggerEvent('esx_jobs:registerExternalJobs', transform_job_2_esx_jobs(Config.Jobs))
