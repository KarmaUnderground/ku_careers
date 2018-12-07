ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function get_industry_step(skill)
    if not Config.Jobs[skill.industry] or not Config.Jobs[skill.industry].steps[skill.name] then
        return nil
    end

    return Config.Jobs[skill.industry].steps[skill.name]
end

function get_skill(industry, name)
    local skill = MySQL.Sync.fetchAll('SELECT `id`, `name`, `industry`, `skill_rate`, `work_type` FROM `skills` WHERE `name` = @Name AND industry = @Industry', {
        ['@Name'] = name,
        ['@Industry'] = industry
    })

    return skill[1]
end

function get_hyerarchy(industry)
    --[[
    local players = MySQL.Sync.fetchAll('SELECT `industry`, `name`, `tries` FROM `user_skills` WHERE `identifier` = @Identifier ORDER BY `industry`', {
        ['@Identifier'] = xPlayer.identifier
    })

    local ordered = {}

    local factor = 0
    local level = 1

    for i=1, #players, 1 do
        factor = math.pow(2, level-1)

        ordered[players[i].id].childs = {}

        if level == 1 then
            ordered[players[i].id].parent = nil
        else
            ordered[players[i].id].parent = players[(factor/2)+math.mod(i,factor/2)]
        end

        if players[factor] then
            table.insert(ordered[players[i].id].childs, players[factor].id)
        end

        if players[factor*2] then
            table.insert(ordered[players[i].id].childs, players[factor*2].id)
        end

        level = level+1
    end
    ]]
end

function commit_skills(xPlayer)
    local player_skills = get_user_skills(xPlayer)

    for industry_name, industries in pairs(player_skills) do
        for skill_name, skill in pairs(industries) do
            if skill.used then
                MySQL.Async.execute('UPDATE `user_skills` SET `tries` = @tries, `last_usage` = NOW() WHERE `identifier` = @Identifier AND `skill_id` = @Skill_id',
                {
                    ['@tries'] = skill.tries,
                    ['@Identifier'] = xPlayer.identifier,
                    ['@Skill_id']   = skill.id
                })
            end
        end
    end
end

function get_user_skills(xPlayer)
    local player_skills = xPlayer.get('skills')
    local formated_skill = nil

    if not player_skills then -- Skills have not been initiated
        math.randomseed(os.time()) -- Should be removed from here and added to a global server function and be run once

        player_skills = {}

        local result = MySQL.Sync.fetchAll('SELECT `us`.`identifier`, `us`.`skill_id`, `s`.`name` AS skill_name, `s`.`industry` AS skill_industry, `s`.`work_type` AS skill_work_type, `s`.`skill_rate`, `us`.`tries`, ROUND((SQRT(POWER(`s`.`skill_rate`,2) - POWER(`s`.`skill_rate` - `us`.`tries`,2))/`s`.`skill_rate`)*100, 1) AS level FROM `user_skills` us INNER JOIN `skills` s ON `s`.`id` = `us`.`skill_id` WHERE `us`.`identifier` = @Identifier ORDER BY `s`.`industry`;',
        {
            ['@Identifier'] = xPlayer.identifier
        })

        for i=1, #result, 1 do
            skill = {
                id = result[i]['skill_id'],
                name = result[i]['skill_name'],
                industry = result[i]['skill_industry'],
                work_type = result[i]['skill_work_type'],
                skill_rate = result[i]['skill_rate'],
                tries = result[i]['tries'],
                level = result[i]['level'],
                used = false
            }

            if skill then
                if not player_skills[skill.industry] then
                    player_skills[skill.industry] = {}
                end

                player_skills[skill.industry][skill.name] = skill
            end
        end

        xPlayer.set('skills', player_skills)
    end

    return player_skills
end

function get_user_skills_stats(xPlayer)
    local player_skills = get_user_skills(xPlayer)
    local skills_sum = 0
    local skills_count = 0

    for industry_name, industries in pairs(player_skills) do
        for skill_name, skill in pairs(industries) do
            skills_sum = skills_sum + tonumber(skill.level)
            skills_count = skills_count + 1
        end
    end

    return {sum = skills_sum, count = skills_count}
end

function get_user_skill(xPlayer, industry, name)
    local player_skills = get_user_skills(xPlayer)
    local user_skill = player_skills[industry][name]

    if not user_skill then -- This skill does not exists
        local skill = get_skill(industry, name)

        if not skill then
            return nil
        end

        MySQL.Sync.execute('INSERT INTO `user_skills` (`identifier`, `skill_id`, `tries`) VALUES (@Identifire, @Skill_id, @Tries)',
        {
            ['@Identifire'] = xPlayer.identifier,
            ['@Skill_id']   = skill.id,
            ['@Tries']      = 0
        })

        user_skill =  {
            id = skill.id,
            name = skill.name,
            industry = skill.industry,
            work_type = skill.work_type,
            skill_rate = skill.skill_rate,
            tries = 0,
            level = 0,
            used = false
        }
        
        player_skills[industry][name] = user_skill
        xPlayer.set('skills', player_skills)

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_new", _U(name)))
    end

    return user_skill
end

function format_skill(industry, name, tries)
    if get_industry_step({industry = industry, name = name}) then
        local formatted_skill = get_level_from_tries({
            industry = industry,
            name = name,
            tries = tries,
            level = 0
        })

        return formatted_skill
    end

    return nil
end

function get_level_from_tries(skill)
    local skill_rate = get_industry_step(skill).skill_rate

    skill.level = math.sqrt((skill.skill_rate*skill.skill_rate) - ((skill.skill_rate - skill.tries) * (skill.skill_rate - skill.tries)))
    skill.level = ESX.Round(((skill.level/skill.skill_rate)*100),1)

    return skill
end

function remove_skill(xPlayer, skill)
    local player_skills = get_user_skills(xPlayer)

    player_skills[skill.industry][skill.name] = nil
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

        local skills_stats = get_user_skills_stats(xPlayer)
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
        local player_skills = get_user_skills(xPlayer)

        skill.tries = tries
        skill = get_level_from_tries(skill)
        skill.used = true

        player_skills[skill.industry][skill.name] = skill

        xPlayer.set('skills', player_skills)

        commit_skills(xPlayer)

        if show_message == true then
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_modified", _U(skill.name), level))
        end
    end
end

function decrease_random_skill(xPlayer, not_skill)
    local player_skills = get_user_skills(xPlayer)
    local skills_stats = get_user_skills_stats(xPlayer)

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
    local step = get_industry_step(skill)
    local mood = "bad"
    local diff = 12.5
    local variace = 0.8
    local add = 0

    local roll_skill = math.random(1000) / 10

    if skill.level > roll_skill then
        mood = "good"

        local roll_qty = rand_normal(skill.level - diff, skill.level + diff, variace, 0.1, 100)
        local multiplyer = 1 --local multiplyer = get_industry_step(skill).add

        add = (math.floor(roll_qty/25)+1)*multiplyer
    end

    xPlayer.addInventoryItem(skill.name, add)

    if Config.PlayAnimation then
        TriggerClientEvent("ku_skills:anim", xPlayer.source, mood)
    end
end

--******************************************************************
-- Working vehicle management
--******************************************************************
local isVehicleInArea = {}
RegisterServerEvent('ku_skills:areaVehiclesResponse')
AddEventHandler('ku_skills:areaVehiclesResponse', function(response)
    isVehicleInArea[ESX.GetPlayerFromId(source).identifier] = response
end)

function isVehicleCloseEnough(xPlayer, step)
    TriggerClientEvent('ku_skills:getVehicleInArea', xPlayer.source, step.vehicle, 'ku_skills:areaVehiclesResponse')

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
ESX.RegisterServerCallback('ku_skills:vendorSell', function(source, cb, step, qty)
    local xPlayer = ESX.GetPlayerFromId(source)
    local step = get_industry_step({industry = xPlayer.job.name, name = step})
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
ESX.RegisterServerCallback('ku_skills:vendorBuy', function(source, cb, step, qty)
    local xPlayer = ESX.GetPlayerFromId(source)
    local step = get_industry_step({industry = xPlayer.job.name, name = step})
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
ESX.RegisterServerCallback('ku_skills:getSkills', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local skills = get_user_skills(xPlayer)
    cb(skills)
end)

ESX.RegisterServerCallback('ku_skills:removeSkill', function(source, cb, skill)
    local xPlayer = ESX.GetPlayerFromId(source)
    remove_skill(xPlayer, skill)
    cb()
end)

ESX.RegisterServerCallback('ku_skills:getInventoryItem', function(source, cb, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getInventoryItem(name))
end)

--******************************************************************
-- Execute working actions
--******************************************************************
function start_working(xPlayer, skill)
    local step = get_industry_step(skill)

    if not isVehicleCloseEnough(xPlayer, step) then
        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("working_vehicle_too_far"))
        return false
    end

    execute_skill(xPlayer, skill)
    increase_skill(xPlayer, skill)
end

TriggerEvent('esx_jobs:registerHook', 'overrides', 'add_item', 'ku_skills_skills_execute_skill', function (params)
    local xPlayer = params.xPlayer
    local skill = get_user_skill(xPlayer, xPlayer.job.name, params.item.db_name)

    start_working(xPlayer, skill)
end)

--******************************************************************
-- Register external jobs
--******************************************************************
TriggerEvent('esx_jobs:registerExternalJobs', transform_job_2_esx_jobs(Config.Jobs))
