-- Why was this archived?
-- Late 2024, Alyth Studios welcomed an investor. This investor ended up removing all developers from the Development Team, causing this repository to no longer be needed.

-- Everything below this line came prior to the archival. 

-- Variables
local DataStoreService = game:GetService("DataStoreService")
local DailyQuestStore = DataStoreService:GetDataStore("DailyQuests")
local QUEST_DURATION = 24 * 60 * 60  -- 24 hours in seconds

local quests = {
    {name = "Play for 5 Minutes", goal = 10, reward = 100},
    {name = "Collect 5 Gems", goal = 5, reward = 50},
    -- Add more quests
}

-- Assign a quest when the player joins
game.Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId

    -- Check if player has an active quest
    local success, data = pcall(function()
        return DailyQuestStore:GetAsync(userId)
    end)

    if not success or not data then
        -- If no active quest, assign a new one
        local questIndex = math.random(1, #quests)
        local quest = quests[questIndex]
        
        -- Save the new quest to DataStore
        pcall(function()
            DailyQuestStore:SetAsync(userId, {
                quest = quest,
                progress = 0,
                timestamp = os.time()
            })
        end)
    end
end)

-- Function to check and update progress
function UpdateQuestProgress(player, quest, progress)
    local userId = player.UserId
    local success, data = pcall(function()
        return DailyQuestStore:GetAsync(userId)
    end)
    
    if success and data then
        -- Check if the quest is still valid
        if os.time() - data.timestamp < QUEST_DURATION then
            data.progress = progress
            if data.progress >= quest.goal then
                -- Quest complete! Give reward
                player.leaderstats.Coins.Value = player.leaderstats.Coins.Value + quest.reward
                print("Quest Completed: ".. quest.name)

                -- Reset quest
                pcall(function()
                    DailyQuestStore:RemoveAsync(userId)
                end)
            else
                -- Update progress
                pcall(function()
                    DailyQuestStore:SetAsync(userId, data)
                end)
            end
        end
    end
end

local REWARD_TIME = 10 * 60  -- 10 minutes in seconds
local REWARD_AMOUNT = 100  -- Amount of reward (coins, points, etc.)

local DataStoreService = game:GetService("DataStoreService")
local PlaytimeStore = DataStoreService:GetDataStore("PlaytimeRewards")

-- Player joins the game
game.Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId
    
    -- Load existing playtime if available
    local success, data = pcall(function()
        return PlaytimeStore:GetAsync(userId)
    end)

    local playTime = data or 0  -- Default to 0 if no data
    local sessionStartTime = os.time()  -- Track when the player joined this session

    -- Track time played in the session
    while true do
        -- Wait for a short period and update playtime
        wait(60)  -- Update every minute
        
        local currentSessionTime = os.time() - sessionStartTime
        local totalTimePlayed = playTime + currentSessionTime

        -- Check if total time exceeds the reward time (10 minutes)
        if totalTimePlayed >= REWARD_TIME then
            -- Reward the player
            if not player:FindFirstChild("leaderstats") then
                -- Create a simple leaderboard if not already present
                local leaderstats = Instance.new("Folder")
                leaderstats.Name = "leaderstats"
                leaderstats.Parent = player
                
                local coins = Instance.new("IntValue")
                coins.Name = "Coins"
                coins.Value = 0
                coins.Parent = leaderstats
            end

            -- Give reward
            player.leaderstats.Coins.Value = player.leaderstats.Coins.Value + REWARD_AMOUNT
            print("Reward given to ".. player.Name .." for playing 10 minutes")

            -- Save that the player received the reward and reset playtime
            pcall(function()
                PlaytimeStore:SetAsync(userId, totalTimePlayed)
            end)

            -- End the loop after the reward is given
            break
        end
    end
end)


-- Example usage: call this function when the player defeats a monster or collects an item
function OnMonsterDefeated(player)
    local success, data = pcall(function()
        return DailyQuestStore:GetAsync(player.UserId)
    end)
    
    if success and data and data.quest.name == "Defeat 10 Monsters" then
        UpdateQuestProgress(player, data.quest, data.progress + 1)
    end
end

