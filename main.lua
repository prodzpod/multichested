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
        n = n + 1
        newinst:set("m_id", n - 3390)
        newx = newx + interval
    end
end

local multiplyChestPacket = net.Packet.new("multiplyChest", function(player, obj, x, y, num, players)
    multiplyChest(obj, x, y, num, players)
end)
local removeOriginalChestPacket = net.Packet.new("removeOriginalChest", function(player, netinst)
    local inst = netinst:resolve()
    if inst:isValid() then
        inst:destroy()
    end
end)
local oChestMultiplier = Object.new("oChestMultiplier")
callback("onStageEntry", function()
    if net.host then
        oChestMultiplier:create(0, 0)
    end
end)
oChestMultiplier:addCallback("create", function(self)
    self:getData().time = 1
end)
oChestMultiplier:addCallback("step", function(self)
    if (self:getData().time == 0) then
        self:destroy()
    end
    self:getData().time = self:getData().time - 1
end)
oChestMultiplier:addCallback("destroy", function(self)
    number = #(Object.find("P"):findAll())
    if number ~= 1 then -- no need to trigger this when 1 player is active
        for _, type in ipairs(chests) do
            for _, inst in ipairs(type:findAll()) do
                if net.host then
                    multiplyChest(type, inst.x, inst.y, current, number)
                    multiplyChestPacket:sendAsHost(net.ALL, nil, type, inst.x, inst.y, current, number)
                    current = current + 1
                    removeOriginalChestPacket:sendAsHost(net.ALL, nil, inst:getNetIdentity())
                    inst:destroy()
                end
            end
        end
    end
end)

local openMultipliedChest = net.Packet.new("openMultipliedChest", function(player, id)
    for _, type in ipairs(chests) do
        for _, inst in ipairs(type:findAll()) do
            if (inst:get("m_id") == id) then
                inst:setAlarm(0, 30)
                return
            end
        end
    end
end)
callback("onMapObjectActivate", function(instance, player)
    if net.host then
        openMultipliedChest:sendAsHost(net.ALL, nil, instance:get("m_id"))
    else
        openMultipliedChest:sendAsClient(instance:get("m_id"))
    end
end)

callback("onActorInit", function(actor)
	if (actor:get("team") == "enemy") then
		number = #(Object.find("P"):findAll())
		local def = actor:get("maxhp")
		actor:set("hp", def * number)
		actor:set("maxhp", def * number)
		local xp = actor:get("exp_worth")
		actor:set("exp_worth", xp * number)
		local point = actor:get("point_value")
		actor:set("point_value", point * number)
	end
end)