--[[
Copyright (C) 2015  Albert Diserholt

This file is part of Monstrous Bosses.

Monstrous Bosses is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Monstrous Bosses is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Monstrous Bosses.  If not, see <http://www.gnu.org/licenses/>.
--]]

local anim8 = require("lib.anim8")

local GameObject = require("src.gameobject")

local Station = GameObject:subclass("Station")

Station.static.types = {
	{ -- Computer
		id = 1,
		offsetX = -23,
		energyConsumption = 10,
		spriteSheet = love.graphics.newImage("gfx/computer_station.png")
	},
	{ -- Printer
		id = 2,
		offsetX = -10,
		energyConsumption = 14,
		spriteSheet = love.graphics.newImage("gfx/printer_station.png")
	},
	{ -- Paperwork
		id = 3,
		offsetX = -23,
		energyConsumption = 18,
		spriteSheet = love.graphics.newImage("gfx/paper_station.png")
	}
}
Station.types[1].spriteGrid = anim8.newGrid(66, 139, Station.types[1].spriteSheet:getDimensions())
Station.types[2].spriteGrid = anim8.newGrid(67, 116, Station.types[2].spriteSheet:getDimensions())
Station.types[3].spriteGrid = anim8.newGrid(66, 139, Station.types[3].spriteSheet:getDimensions())

function Station:initialize(x, y, stationType, flipped)
	GameObject.initialize(self, x, y)

	self.type = Station.types[stationType or 1]
	self.size.w = self.type.spriteGrid.frameWidth
	self.size.h = self.type.spriteGrid.frameHeight

	self.idleAnimation = anim8.newAnimation(self.type.spriteGrid(1,1), 1, "pauseAtEnd")
	self.workingAnimation = anim8.newAnimation(self.type.spriteGrid('2-3',1), 0.5)

	if flipped then
		self.idleAnimation:flipH()
		self.workingAnimation:flipH()
	end

	self.workingEmployee = nil
end

function Station:canAssign(employee)
	return self.workingEmployee == nil
end

function Station:assign(employee)
	self.workingEmployee = employee
	if not self:isFlipped() then
		employee.pos.x = self.pos.x + self.size.w + self.type.offsetX
	else
		employee.pos.x = self.pos.x - (employee.size.w + self.type.offsetX)
	end
	-- Align top
	employee.pos.y = self.pos.y - (employee.size.h - self.size.h)

	self.workingAnimation:resume()
end

function Station:unassign(employee)
	self.workingEmployee = nil
end

function Station:isFlipped()
	return self.idleAnimation.flippedH
end

function Station:getEnergyConsumption()
	return self.type.energyConsumption -- Per second
end

function Station:update(dt)
	if self.workingEmployee ~= nil and not self.workingEmployee:isWorking() then
		self.workingAnimation:pauseAtStart()
	end
	self.idleAnimation:update(dt)
	self.workingAnimation:update(dt)
end

function Station:draw()
	love.graphics.setColor(255, 255, 255, 255)
	if self.workingEmployee ~= nil then
		self.workingAnimation:draw(self.type.spriteSheet, self.pos.x, self.pos.y)
	else
		self.idleAnimation:draw(self.type.spriteSheet, self.pos.x, self.pos.y)
		if self:isActive() then
			love.graphics.setColor(0, 255, 0, 100)
			self.idleAnimation:draw(self.type.spriteSheet, self.pos.x, self.pos.y)
		end
	end

	GameObject.draw(self)
end

return Station
