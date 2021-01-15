local chests = {Object.find("Chest1"), Object.find("Chest2"), Object.find("Chest5"), Object.find("Barrel1"), Object.find("Barrel2"), Object.find("Shrine1"), Object.find("Shrine2"), Object.find("Shrine5")}

local number
local interval
local current = 0

local multiplyChest = function(obj, x, y, num, players)
    interval = 48 - (8 * players)
    local newx = x - (interval * players * 0.5)
    local n = num * players
    for i = 1, players do
        local newinst = obj:create(newx, y)
        while newinst:collidesMap(newx, newinst.y + 3) do
            newinst.y = newinst.y - 3
        end
        n = n + 1
        inst:set("m_id", n + 339000)
        newx = newx + interval
    end
end

multiplyChestPacket = net.Packet.new("multiplyChest", function(player, obj, x, y, num, players)
    log("packet recieved: multiplyChest with id " .. num)
    multiplyChest(obj, x, y, num, players)
end)

local oChestMultiplier = Object.new("oChestMultiplier")
callback("onStageEntry", function()
    if net.host then
        oChestMultiplier:create(0, 0)
    end
end)
oChestMultiplier:addCallback("step", function(self)
    self:destroy()
end)
oChestMultiplier:addCallback("destroy", function(self)
    number = #(Object.find("P"):findAll())
    if (number ~= 1 and net.host) then -- no need to trigger this when 1 player is active
        for _, type in ipairs(chests) do
            for _, inst in ipairs(type:findAll()) do
                log("spawning chests number " .. current)
                multiplyChest(type, inst.x, inst.y, current, number)
                multiplyChestPacket:sendAsHost(net.ALL, nil, type, inst.x, inst.y, current, number)
                current = current + 1
                inst:destroy()
            end
        end
    end
end)