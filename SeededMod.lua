ModUtil.RegisterMod("SeededMod")

--[[
  Mod for the Modded Seeded category, to improve quality of life
  in routed Hades and reduce randomness without impacting the core gameplay.
]]
local config = {
  ModName = "Seeded Mod",
  DeterministicPriceOfMidas = true,
  DeterministicSpawnPositions = true,
  DeterministicMoneyDrops = true, -- this might still depend on enemy kill order
  DisableGhostRngIncrements = true
}

if ModConfigMenu then
  ModConfigMenu.Register(config)
end

-- Ensure that the rng calls for Price of Midas will always happen in the same order.
ModUtil.LoadOnce( function()
    if config.DeterministicPriceOfMidas then
      table.sort(ConsumableData.DamageSelfDrop, cmp_multitype)
    end
end)

--[[ Ensure that spawn initial spawn positions are always the same on the same seed,
     by sorting the spawn point tables when they come back from the engine.
]]
ModUtil.WrapBaseFunction("GetIds", function( baseFunc, args )
  local ids = baseFunc(args)
  if config.DeterministicSpawnPositions and args.Name and args.Name == "SpawnPoints" then
    table.sort(ids, cmp_multitype)
  end
  return ids
end)

local spawnPointIdTypes = {}

ModUtil.WrapBaseFunction("GetIdsByType", function( baseFunc, args)
  local ids = baseFunc(args)
  if config.DeterministicSpawnPositions and args.Name and spawnPointIdTypes[args.Name] then
    table.sort(ids, cmp_multitype)
  end
  return ids
end)

ModUtil.WrapBaseFunction("SelectSpawnPoint", function(baseFunc, currentRoom, enemy, encounter)
  if enemy.RequiredSpawnPoint then
    spawnPointIdTypes[enemy.RequiredSpawnPoint] = true
  end
  if enemy.PreferredSpawnPoint then
    spawnPointIdTypes[enemy.PreferredSpawnPoint] = true
  end
  return baseFunc(currentRoom, enemy, encounter)
end)

--[[
  Facilities for having several RNGs, all initialized to the same seed but with independant offsets.
]]
local AdditionalRngs = {
  Ghost = 2,
  Money = 3
}
ModUtil.WrapBaseFunction("RandomInit", function(baseFunc, rngId)
  if rngId == nil or rngId == 1  then
    local result = baseFunc(rngId)
    for _, id in pairs(AdditionalRngs) do
      NextSeeds[id] = NextSeeds[1]
      RandomInit(id)
    end
    return result
  else
    return baseFunc(rngId)
  end
end)

function OneArgRngFunction(rngId, condition)
  return function(baseFunc, a1)
    if config[condition] then
      return baseFunc(a1, GetRngById(rngId))
    else
      return baseFunc(a1)
    end
  end
end

function TwoArgRngFunction(rngId, condition)
  return function(baseFunc, a1, a2)
    if config[condition] then
      return baseFunc(a1, a2, GetRngById(rngId))
    else
      return baseFunc(a1, a2)
    end
  end
end

local RngFunctions = {
  GetRandomValue = OneArgRngFunction,
  RandomChance = OneArgRngFunction,
  RandomFloat = TwoArgRngFunction,
  RemoveRandomValue = OneArgRngFunction,
  RandomInt = TwoArgRngFunction
}

function OverrideFunctionRng(funcName, rngId, condition)
  for rngFunctionName, rngFunction in pairs(RngFunctions) do
    ModUtil.WrapBaseWithinFunction( funcName, rngFunctionName, rngFunction(rngId, condition) )
  end
end

-- Put rolls from money drops on a separate RNG so it doesn't affect routing.
-- This also prevents the main increments from killing pots.
OverrideFunctionRng("CheckMoneyDrop", AdditionalRngs.Money, "DeterministicMoneyDrops")

-- Put ghost pathing on a separate RNG so it doesn't affect routing.
OverrideFunctionRng("PatrolPath", AdditionalRngs.Ghost, "DisableGhostRngIncrements")
OverrideFunctionRng("FollowPath", AdditionalRngs.Ghost, "DisableGhostRngIncrements")
