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
local cron = require("lib.cron")

local GameObject = require("src.gameobject")

local Employee = GameObject:subclass("Employee")

Employee.static.energyBar = love.graphics.newImage("gfx/energybar.png")
Employee.static.greenBar = love.graphics.newImage("gfx/greenbar.png")
Employee.static.energyBarBlinkSheet = love.graphics.newImage("gfx/energybar_blink.png")
Employee.static.energyBarBlinkGrid = anim8.newGrid(60, 18, Employee.energyBarBlinkSheet:getDimensions())
Employee.static.greenArrow = love.graphics.newImage("gfx/greenarrow.png")
Employee.static.redArrow = love.graphics.newImage("gfx/redarrow.png")

Employee.static.spriteSheet = love.graphics.newImage("gfx/employees.png")
Employee.static.spriteGrid = anim8.newGrid(64, 148, Employee.spriteSheet:getWidth(), Employee.spriteSheet:getHeight(), 0, 0, 1)

-- Resistances are in percent (100% = no effort) per station type (computer=1,
-- printer=2, paperwork=3)
Employee.static.types = {
	{ -- Red
		id = 1,
		energyRestoration = 2,
		resistances = { 70, 70, 50 },
		minWorkTime = 5,
		slackingChance = 20,
	},
	{ -- Purple
		id = 2,
		energyRestoration = 4,
		resistances = { 30, 70, 30 },
		minWorkTime = 3,
		slackingChance = 40,
	},
	{ -- Blue
		id = 3,
		energyRestoration = 5,
		resistances = { 50, 50, 20 },
		minWorkTime = 4,
		slackingChance = 50,
	},
	{ -- Green
		id = 4,
		energyRestoration = 4,
		resistances = { 70, 30, 30 },
		minWorkTime = 3,
		slackingChance = 40,
	},
	{ -- White
		id = 5,
		energyRestoration = 6,
		resistances = { 20, 20, 20 },
		minWorkTime = 2,
		slackingChance = 60,
	},
}

Employee.static.changePerArrow = 3

function Employee:initialize(x, y, toX, toY, employeeType)
	GameObject.initialize(self, x, y)

	self.walkTo = { x = toX or x, y = toY or y }
	self.walkingSpeed = love.math.random(100, 200)

	self:setEnergy(love.math.random(45, 65))
	self.energyChange = 0

	self.type = Employee.types[employeeType or love.math.random(1, #Employee.types)]
	self.size.w = Employee.spriteGrid.frameWidth
	self.size.h = Employee.spriteGrid.frameHeight

	self.slackingCheckInterval = love.math.random(5,10)/10 -- How often (in seconds) to evaluate slacking

	local c = self.type.id
	self.walkingAnimation = anim8.newAnimation(Employee.spriteGrid(c,1, c,2, c,1, c,3, c,4, c,3), self.walkingSpeed/700)
	self.workingAnimation = anim8.newAnimation(Employee.spriteGrid(c,8, c,9, c,8, c,10), 0.2)

	-- Hella-ugly, but hey.
	self.eyeAnimation = anim8.newAnimation(Employee.spriteGrid(c,5, c,6, c,7, c,7, c,6, c,5, c,1), 0.04, "pauseAtEnd")
	self.blinkTimer = cron.after(0, function() end)

	self.energyBarBlink = anim8.newAnimation(Employee.energyBarBlinkGrid('1-3',1, '3-1',1), 0.1)
end

function Employee:setEnergy(energy)
	self.energy = energy
end

function Employee:getEnergy()
	return self.energy
end

function Employee:isExhausted()
	return self.energy <= 0 and self.exhaustedTimer ~= nil
end

function Employee:isWorking()
	return self.working
end

function Employee:setWorking(isWorking, station)
	if self:isExhausted() then
		self.working = false
	else
		self.working = isWorking
		self.lastWorkChange = love.timer.getTime()
		if isWorking then
			self.idleTimer = nil
		end
	end
	if self.station ~= nil then
		self.station:unassign(self)
	end
	self.station = station
	if self.station ~= nil then
		self.station:assign(self)
		self.workingAnimation.flippedH = self.station:isFlipped()
		self.walkingAnimation.flippedH = self.workingAnimation.flippedH
	end
end

function Employee:startDragging()
	self:setWorking(false, nil)
	self.dragging = true
	-- Stop walking
	self.walkTo = nil
end

function Employee:stopDragging()
	self.dragging = false
end

function Employee:startSlacking()
	self:setWorking(false, self.station)
	self.idleTimer = cron.after(love.math.random(3,6), function() end)
end

function Employee:update(dt)
	GameObject.update(self, dt)

	local startingEnergy = self:getEnergy()

	if self.dragging then
		self.pos.x = love.mouse.getX() - 15
		self.pos.y = love.mouse.getY() - 15
	end

	if self.exhaustedTimer and self.exhaustedTimer <= love.timer.getTime() then
		self.exhaustedTimer = nil
	end

	if self:isWorking() then
		local afterResistance = self.station:getEnergyConsumption() * ((100 - self.type.resistances[self.station.type.id])/100)
		self:setEnergy(self:getEnergy() - afterResistance * dt)
		if self:getEnergy() <= 0 then
			self:setEnergy(0)
			self.energyBarBlink:gotoFrame(1)
			self.exhaustedTimer = love.timer.getTime() + 5
			self:setWorking(false, self.station)
		else
			-- Random chance that some slacking will occur.
			local workedFor = love.timer.getTime() - self.lastWorkChange
			if workedFor > self.type.minWorkTime then
				if love.math.random(1, 100) <= self.type.slackingChance then
					self:startSlacking()
				else
					self.lastWorkChange = self.lastWorkChange + self.slackingCheckInterval
				end
			end
		end
	elseif not self:isExhausted() then
		self:setEnergy(self:getEnergy() + self.type.energyRestoration*dt)
		if self:getEnergy() >= 100 then
			love.event.push("gameover")
		end

		if self.walkTo ~= nil and (self.walkTo.x ~= self.pos.x or self.walkTo.y ~= self.pos.y) then
			self.walkingAnimation:resume()

			local movement = self.walkingSpeed * dt

			for _,v in ipairs({ "x", "y" }) do
				if self.walkTo[v] > self.pos[v] then
					if v == "x" then self.walkingAnimation.flippedH = true end
					self.pos[v] = self.pos[v] + movement
				elseif self.walkTo[v] < self.pos[v] then
					if v == "x" then self.walkingAnimation.flippedH = false end
					self.pos[v] = self.pos[v] - movement
				end
				if math.abs(self.walkTo[v] - self.pos[v]) <= 2 then
					self.pos[v] = self.walkTo[v]
				end
			end
		else
			self.walkingAnimation:pauseAtStart()
		end
	end

	if self.idleTimer ~= nil and self.idleTimer:update(dt) then
		self.idleTimer = nil
		if not self.dragging and not self:isExhausted() and not self:isWorking() then
			self:setWorking(false, nil) -- Release station.
			self.walkTo = {
				x = love.math.random(Employee.idleArea.x1, Employee.idleArea.x2),
				y = love.math.random(Employee.idleArea.y1, Employee.idleArea.y2)
			}
		end
	end

	self.walkingAnimation:update(dt)
	self.workingAnimation:update(dt)
	self.eyeAnimation:update(dt)
	self.eyeAnimation.flippedH = self.walkingAnimation.flippedH
	self.energyBarBlink:update(dt)
	if self.blinkTimer:update(dt) then
		self.eyeAnimation:gotoFrame(1)
		self.eyeAnimation:resume()
		self.blinkTimer = cron.after(love.math.random(2, 5), function() end)
	end

	self.energyChange = (self:getEnergy() - startingEnergy) / dt
end

function Employee:draw()
	do -- Body
		local animation = self.walkingAnimation
		if self:isWorking() then
			animation = self.workingAnimation
		end

		love.graphics.setColor(255, 255, 255, 255)
		animation:draw(Employee.spriteSheet, self.pos.x, self.pos.y)
		if self:isActive() then
			love.graphics.setColor(0, 255, 0, 100)
			animation:draw(Employee.spriteSheet, self.pos.x, self.pos.y)
		end
	end

	do -- Eye
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setStencil(function()
			-- Only draw the head
			love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size.w, self.size.h/4)
		end)
		self.eyeAnimation:draw(Employee.spriteSheet, self.pos.x, self.pos.y)
		if self:isActive() then
			love.graphics.setColor(0, 255, 0, 100)
			self.eyeAnimation:draw(Employee.spriteSheet, self.pos.x, self.pos.y)
		end
		love.graphics.setStencil()
	end

	GameObject.draw(self)

	do -- Draw energy bar
		local barOffset = 3 -- Number of pixels until the bar starts/ends

		local x = self.pos.x + (self.size.w - Employee.energyBar:getWidth())/2
		local y, w, h = self.pos.y - 5, Employee.energyBar:getWidth(), 10
		local fill = math.max(0, (w - 2*barOffset) / 100 * self:getEnergy())

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(Employee.energyBar, x, y)

		love.graphics.setStencil(function()
			love.graphics.rectangle("fill", x + barOffset, y, fill, h)
		end)
		love.graphics.draw(Employee.greenBar, x, y)
		love.graphics.setStencil()

		if not self:isExhausted() then
			local arrowOffset = 3
			if self:isWorking() then
				local arrowWidth = Employee.redArrow:getWidth()
				for i=1,3 do
					love.graphics.setColor(255, 255, 255,
						math.max(0, math.min(255,
							(-self.energyChange - Employee.changePerArrow*(i-1)) / Employee.changePerArrow * 255)))
					love.graphics.draw(Employee.redArrow, x - i*arrowWidth - arrowOffset, y)
				end
			else
				local arrowWidth = Employee.greenArrow:getWidth()
				for i=1,3 do
					love.graphics.setColor(255, 255, 255,
						math.max(0, math.min(255,
							(self.energyChange - Employee.changePerArrow*(i-1)) / Employee.changePerArrow * 255)))
					love.graphics.draw(Employee.greenArrow, x + w + arrowOffset + (i-1)*arrowWidth, y)
				end

				if self:getEnergy() >= 90 then
					love.graphics.setColor(50, 255, 50, 255)
					self.energyBarBlink:draw(Employee.energyBarBlinkSheet, x - 5, y - 5)
				end
			end
		else
			self.energyBarBlink:draw(Employee.energyBarBlinkSheet, x - 5, y - 5)
		end
	end
end

return Employee
