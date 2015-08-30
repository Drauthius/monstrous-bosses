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

local class = require("lib.middleclass")

local Boss = require("src.boss")
local Door = require("src.door")
local Employee = require("src.employee")
local Station = require("src.station")

local Infinite = class("Infinite")

Infinite.static.background = love.graphics.newImage("gfx/office.png")
Infinite.static.doorLocation = {
	77 + (357 - 77 - Door.spriteGrid.frameWidth) / 2,
	171 - Door.spriteGrid.frameHeight
}

Infinite.static.scoreFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 24)

Infinite.static.roarSound = love.audio.newSource("sfx/monster_or_large_creature_groan.mp3")

Employee.static.idleArea = {
	--x1 = 380, y1 = 250 - Employee.spriteGrid.frameHeight,
	x1 = 650, y1 = 250 - Employee.spriteGrid.frameHeight,
	x2 = 990 - Employee.spriteGrid.frameWidth, y2 = 535
}

function Infinite:initialize()
	self.dragging = nil
	self.employees = {}
	self.stations = {
		Station:new(100, 400, 1),
		Station:new(100, 570, 1),
		Station:new(300, 400, 1, true),
		Station:new(300, 570, 1, true),
		Station:new(400, 485, 3),
		Station:new(600, 400, 2, true),
		Station:new(600, 570, 2, true),
	}
	self.door = Door:new(unpack(Infinite.doorLocation))
	self.boss = Boss:new(200, 60)

	self.employeesAdded = 0
	self:addEmployee(1)
	self:addEmployee(1)
	self.nextEmployee = love.timer.getTime() + 18

	self.score = { workSeconds = 0, numFired = 0 }

	Infinite.roarSound:setVolume(2)
end

function Infinite:destroy(runAfter)
	music:pause()
	Infinite.roarSound:play()
	self.tearingDown = true
	self.afterTeardown = runAfter

	self.boss:getFired()
	self.door:setOpen(true)

	if self.dragging then
		self.dragging:stopDragging()
		self.dragging = false
	end
end

function Infinite:addEmployee(employeeType)
	table.insert(self.employees,
		Employee:new(love.window.getWidth(), 290 - Employee.spriteGrid.frameHeight,
			love.math.random(Employee.idleArea.x1, Employee.idleArea.x2),
			love.math.random(Employee.idleArea.y1, 300),
			employeeType))
	self.employeesAdedd = self.employeesAdded + 1
end

function Infinite:update(dt)
	-- Overlap protection. This will mark the last station or employee as
	-- active, since the last one is the one to be drawn last, and can thus
	-- be considered to be in the foreground.
	self.activeStation = nil
	self.activeEmployee = nil

	self.boss:update(dt)

	if self.tearingDown then
		-- Wait until boss is gone.
		if self.boss:isMissing() then
			music:resume()
			self.afterTeardown(self.score)
		end
		return
	end

	local x, y = love.mouse.getPosition()

	for _,station in ipairs(self.stations) do
		if self.dragging and not self.dragging:isExhausted()
		   and station:canAssign(self.dragging) and self.dragging:isIntersecting(station) then
			self.activeStation = station
		end

		station:setActive(false)
		station:update(dt)
	end
	if self.activeStation ~= nil then
		self.activeStation:setActive(true)
	end

	for _,employee in ipairs(self.employees) do
		if not self.boss:isFiring() and not self.dragging and employee:isWithin(x, y) then
			self.activeEmployee = employee
		end

		if self.boss:isMissing() then
			employee:startSlacking()
		end
		employee:setActive(false)
		employee:update(dt)
		if employee:isWorking() then
			self.score.workSeconds = self.score.workSeconds + dt
		end
	end
	if self.activeEmployee ~= nil then
		self.activeEmployee:setActive(true)
	end

	if self.dragging and self.dragging:isExhausted() and self.dragging:isIntersecting(self.door) then
		self.door:setActive(true)
	else
		self.door:setActive(false)
	end

	if not self.boss:isFiring() then
		self.door:setOpen(false)
	end

	if self.nextEmployee <= love.timer.getTime() then
		--for i=1,love.math.random(1,2) do
		for i=1,2 do
			self:addEmployee()
		end
		self.nextEmployee = love.timer.getTime() + math.max(6, 15 - self.employeesAdded)
	end
end

function Infinite:draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(Infinite.background)

	self.door:draw()
	self.boss:draw()

	for _,station in ipairs(self.stations) do
		station:draw()
	end
	for _,employee in ipairs(self.employees) do
		employee:draw()
	end

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(Infinite.scoreFont)
	local totalScore = math.floor(self.score.workSeconds) + 20 * self.score.numFired
	love.graphics.printf("Score: "..totalScore, 0, 1, love.window.getWidth(), "center")
end

function Infinite:handleMouse(pressed, x, y)
	if self.boss:isMissing() or self.boss:isFiring() then return end

	if pressed and not self.dragging then
		if self.activeEmployee ~= nil then
			self.dragging = self.activeEmployee
			self.dragging:startDragging()
		end
	elseif not pressed and self.dragging then
		if self.dragging:isExhausted() and self.door:isIntersecting(self.dragging) then
			self.boss:fireEmployee()
			self.door:setOpen(true)
			self.score.numFired = self.score.numFired + 1
			for k,employee in ipairs(self.employees) do
				if self.dragging == employee then
					table.remove(self.employees, k)
					break
				end
			end
		end

		if self.activeStation ~= nil then
			self.boss:assignEmployee()
			self.dragging:setWorking(true, self.activeStation)
		end
		self.dragging:stopDragging()
		self.dragging = nil
	end
end

return Infinite
