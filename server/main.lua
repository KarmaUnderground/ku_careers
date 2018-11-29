ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function commit_skills(xPlayer)
    local player_skills = get_skills(xPlayer)

    for name, skill in pairs(player_skills) do
        MySQL.Async.execute('UPDATE `user_skills` SET `tries` = @tries WHERE `identifier` = @Identifier AND `name` = @Name',
        {
            ['@tries']      = skill.tries,
            ['@Identifier'] = xPlayer.identifier,
            ['@Name']       = skill.name
        })
    end
end

function get_skills(xPlayer)
    local player_skills = xPlayer.get('skills')
    local formated_skill = nil

    if not player_skills then -- Skills have not been initiated
        math.randomseed(os.time()) -- Should be removed from here and added to a global server function and be run once

        player_skills = {}

        local result = MySQL.Sync.fetchAll('SELECT `name`, `tries`, `craft_cycle` FROM `user_skills` WHERE `identifier` = @Identifier ORDER BY `craft_cycle`', {
            ['@Identifier'] = xPlayer.identifier
        })

        for i=1, #result, 1 do
            formated_skill = format_skill(result[i])
            if formated_skill then
                player_skills[formated_skill.name] = formated_skill
            end
        end

        xPlayer.set('skills', player_skills)
    end

    table.sort(player_skills)
    return player_skills
end

function get_skills_stats(xPlayer)
    local player_skills = get_skills(xPlayer)
    local skills_sum = 0
    local skills_count = 0

    for name, skill in pairs(player_skills) do
        skills_sum = skills_sum + tonumber(skill.level)
        skills_count = skills_count + 1
    end

    return {
        sum = skills_sum,
        count = skills_count,
    }
end

function get_skill(xPlayer, name)
    local player_skills = get_skills(xPlayer)
    local player_skill = player_skills[name]

    if not player_skill then -- This skill does not exists
        local formated_skill = format_skill(name, 0, true)

        if not formated_skill then
            return nil
        end

        player_skills[name] = formated_skill
        xPlayer.set('skills', player_skills)

        MySQL.Async.execute('INSERT INTO `user_skills` (`identifier`, `name`, `level`) VALUES (@Identifire, @Name, @Level)',
        {
            ['@Identifire'] = xPlayer.identifier,
            ['@Name']       = name,
            ['@Level']      = 0
        })

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_new", _U(player_skills[name].name)))
    end

    return player_skills[name]
end

function format_skill(skill)
    if not Config.Jobs[skill.craft_cycle] then
        return nil
    end

    local formatted_skill = {
        craft_cycle = skill.craft_cycle,
        name = skill.name,
        tries = skill.tries,
        level = get_level_from_tries(skill)
    }

    return formatted_skill
end

function get_level_from_tries(skill)
    local job = Config.Jobs[skill.craft_cycle]
    local craft_cycle = job.craft_cycles[skill.name]
    local skill_rate = craft_cycle.skill_rate

    local level = 0
    level = math.sqrt((skill_rate*skill_rate) - ((skill_rate - skill.tries) * (skill_rate - skill.tries)))
    level = ESX.Round(((level/skill_rate)*100),1)

    return level
end

function remove_skill(xPlayer, skill)
    local player_skills = get_skills(xPlayer)

    player_skills[skill.name] = nil
    xPlayer.set('skills', player_skills)

    MySQL.Async.execute('DELETE FROM `user_skills` WHERE `identifier` = @Identifire AND `name` = @Name',
    {
        ['@Identifire'] = xPlayer.identifier,
        ['@Name']       = skill.name
    })
end

function set_skill_tries(xPlayer, skill, tries, show_message)
    if tries <= 0 then 
        remove_skill(xPlayer, skill)

        if show_message == true then 
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_removed", _U(skill.name)))
        end
    else
        local player_skills = get_skills(xPlayer)

        player_skills[skill.name].tries = tries
        player_skills[skill.name].level = get_level_from_tries(player_skills[skill.name])

        xPlayer.set('skills', player_skills)

        commit_skills(xPlayer)

        if show_message == true then 
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_modified", _U(skill.name), level))
        end
    end
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
    local mood = "bad"
    local diff = 12.5
    local variace = 0.8

    local roll_skill = math.random(1000) / 10

    if skill.level > roll_skill then
        local roll_qty = rand_normal(skill.level - diff, skill.level + diff, variace, 0.1, 100)

        mood = "good"
        xPlayer.addInventoryItem(skill.name, math.floor(roll_qty/25)+1)
    end

    if Config.PlayAnimation then 
        TriggerClientEvent("esx_jobs_skill:anim", xPlayer.source, mood)
    end
end

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

TriggerEvent('esx_jobs:registerHook', "overrides", "add_item", function (params)
    local xPlayer = params.xPlayer
    local item = params.item

    execute_skill(xPlayer, get_skill(xPlayer, item.db_name))
    increase_skill(xPlayer, get_skill(xPlayer, item.db_name))
end)

TriggerEvent('esx_jobs:registerExternalJobs', transform_job_2_esx_jobs(Config.Jobs))