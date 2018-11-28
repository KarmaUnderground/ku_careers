ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function commit_skills(xPlayer)
    local player_skills = get_skills(xPlayer)

    for name, skill in pairs(player_skills) do
        MySQL.Async.execute('UPDATE `user_skills` SET `level` = @Level WHERE `identifier` = @Identifier AND `name` = @Name',
        {
            ['@Level']      = skill.level,
            ['@Identifier'] = xPlayer.identifier,
            ['@Name']       = skill.name
        })
    end
end

function get_skills(xPlayer)
    local player_skills = xPlayer.get('skills')

    if player_skills == nil then -- Skills have not been initiated
        math.randomseed(os.time()) -- Should be removed from here and added to a global server function and be run once
        player_skills = {}

        local result = MySQL.Sync.fetchAll('SELECT `name`, `tries` FROM `user_skills` WHERE `identifier` = @Identifier', {
            ['@Identifier'] = xPlayer.identifier
        })

        for i=1, #result, 1 do
            player_skills[result[i].name] = format_skill(xPlayer, result[i].name, result[i].tries)
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
        player_skills[name] = format_skill(xPlayer, name, 0, true)
        xPlayer.set('skills', player_skills)

        MySQL.Async.execute('INSERT INTO `user_skills` (`identifier`, `name`, `level`) VALUES (@Identifire, @Name, @Level)',
        {
            ['@Identifire'] = xPlayer.identifier,
            ['@Name']       = name,
            ['@Level']      = 0
        })

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_new", player_skills[name].label))
    end

    return player_skills[name]
end

function format_skill(xPlayer, name, level)

    return {
        name = name,
        level = level,
        label = _U(name)
    }
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

function set_skill_level(xPlayer, skill, level, show_message)
    if level <= 0 then 
        remove_skill(xPlayer, skill)

        if show_message == true then 
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_removed", skill.label))
        end
    else
        local player_skills = get_skills(xPlayer)

        player_skills[skill.name].level = level
        xPlayer.set('skills', player_skills)

        commit_skills(xPlayer)

        if show_message == true then 
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U("skill_modified", skill.label, level))
        end
    end
end

function base_100_skill(xPlayer, skill)
    
end

function increase_skill(xPlayer, skill)
    local roll = math.random(1000) / 10

    if skill.level < roll then
    set_skill_level(xPlayer, skill, skill.level + 0.1)

        local skills_stats = get_skills_stats(xPlayer)
        if skills_stats.sum > Config.GlobalSkillLimit then 
            decrease_random_skill(xPlayer, skill)
        end

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('skill_up', skill.label, skill.level + 0.1))
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

        set_skill_level(xPlayer, skill, skill.level - 0.1)

        TriggerClientEvent('esx:showNotification', xPlayer.source, _U('skill_down', skill.label, skill.level - 0.1))
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

ESX.RegisterServerCallback('esx_jobs_skill:getAllSkills', function(source, cb)
    cb(get_skills(ESX.GetPlayerFromId(source)))
end)

ESX.RegisterServerCallback('esx_jobs_skill:removeSkillLevel', function(source, cb, name, level)
    local xPlayer = ESX.GetPlayerFromId(source)
    local skill = get_skill(xPlayer, name)

    set_skill_level(xPlayer, skill, skill.level - level, true)

    cb()
end)

TriggerEvent('esx_jobs:registerHook', "overrides", "add_item", function (params)
    local xPlayer = params.xPlayer
    local item = params.item

    execute_skill(xPlayer, get_skill(xPlayer, item.db_name))
    increase_skill(xPlayer, get_skill(xPlayer, item.db_name))
end)

TriggerEvent('esx_jobs:registerExternalJobs', transform_job_2_esx_jobs(Config.Jobs))
