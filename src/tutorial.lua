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
local util = require("src.util")

local Boss = require("src.boss")
local Door = require("src.door")
local Employee = require("src.employee")
local Station = require("src.station")
local Infinite = require("src.infinite")

local Tutorial = class("Tutorial")

function Tutorial:initialize()
	self.employee = Employee:new(400, 400)
	self.station = Station:new(500, 500)
	self.door = Door:new(unpack(Infinite.doorLocation))
	self.boss = Boss:new(200, 60)
	self.dragging = false

	self.employee:setEnergy(20)

	self.skipFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 24)
	self.skipText = {
		title = "Skip tutorial",
		x = (love.window.getWidth()-self.skipFont:getWidth("Skip tutorial")) / 2,
		y = 1
	}

	--self.dialogueFont = love.graphics.newFont(14)
	--self.clickFont = love.graphics.newFont(11)
	self.dialogueFont = love.graphics.newFont("ttf/Minecraftia-Regular.ttf", 14)
	self.clickFont = love.graphics.newFont("ttf/Minecraftia-Regular.ttf", 10)
	self.dialogues = {
		{ text = "Welcome to the office! This fellow here is you. You're the boss.",
		  click = true,
		  x = self.boss.pos.x + self.boss.size.w, y = self.boss.pos.y, w = 250,
		  satisfied = function() return true end
		},
		{ text = "This is Tim. He is your minion.",
		  click = true,
		  x = self.employee.pos.x + self.employee.size.w + 10, y = self.employee.pos.y, w = 250,
		  satisfied = function() return true end
		},
		{ text = "Your goal is to expend all of Tim's energy, " ..
		  "and when there is nothing left, you can fire him!",
		  click = true,
		  x = self.employee.pos.x + self.employee.size.w + 10, y = self.employee.pos.y, w = 250,
		  satisfied = function() return true end
		},
		{ text = "Put Tim to work by dragging him to a work station.",
		  x = 350, y = 50, w = 1000,
		  satisfied = function()
			if self.station:isActive() then
				self.employee:setWorking(true, self.station)
				self.employee:update(0)
				return true
			else
				return false
			end
		  end
		},
		{ text = "Tim will now labour away for the good of the company!",
		  click = true,
		  x = self.employee.pos.x + self.employee.size.w + 10, y = self.employee.pos.y, w = 250,
		  satisfied = function()
			self.employee:setEnergy(10)
			return true
		  end
		},
		{ text = "Once he is fully exhausted and used up, you should get rid of him.",
		  click = true,
		  x = self.employee.pos.x + self.employee.size.w + 10, y = self.employee.pos.y, w = 250,
		  satisfied = function()
			  self.employee:setEnergy(0)
			  self.employee:update(0)
			  return true
		  end
		},
		{ text = "Terminate Tim by dragging him to your office.",
		  x = 350, y = 50, w = 500,
		  satisfied = function()
			if self.door:isActive() then
				self.hideTim = true
				self.door:setActive(false)
				return true
			else
				return false
			end
		  end
		},
		{ text = "The arrows next to an employee's energy bar indicate how quickly " ..
		  "the energy is depleted or refreshed.",
		  click = true,
		  x = 350, y = 50, w = 500,
		  satisfied = function() return true end
		},
		{ text = "Employees sharing the same colour have the same preferences and resistances.",
		  click = true,
		  x = 350, y = 50, w = 500,
		  satisfied = function() return true end
		},
		{ text = "The rest you'll have to figure out on your own. Just remember that having " ..
		  "energetic employees reflects badly upon you.",
		  x = 350, y = 50, w = 500,
		  click = true,
		  satisfied = function()
			  love.event.push("endtutorial")
			  return false
		  end
		},
	}
	-- Calculate height and a better width.
	for _,dia in ipairs(self.dialogues) do
		local width, lines = self.dialogueFont:getWrap(dia.text, dia.w)
		dia.w = width
		dia.h = lines * self.dialogueFont:getHeight()
	end
	self.dialogue = 1
end

function Tutorial:destroy(runAfter)
	runAfter()
end

function Tutorial:update(dt)
	local x, y = love.mouse.getPosition()

	if self.dragging then
		self.employee.pos.x = x
		self.employee.pos.y = y

		if self.employee:isExhausted() then
			self.door:setActive(self.door:isIntersecting(self.employee))
		else
			self.station:setActive(self.station:isIntersecting(self.employee))
		end
	elseif not self.dialogues[self.dialogue].click then
		self.employee:setActive(self.employee:isWithin(x, y))
	end
end

function Tutorial:draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(Infinite.background)

	local x, y = love.mouse.getPosition()

	self.door:draw()
	self.boss:draw()
	self.station:draw()
	if not self.hideTim then
		self.employee:draw()
	end

	do -- Dialogues
		local dia = self.dialogues[self.dialogue]
		-- Background
		local bgExtraHeight = 13
		if dia.click then
			bgExtraHeight = bgExtraHeight + 2 + self.clickFont:getHeight()
		end
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle("fill", dia.x-5, dia.y-10, dia.w+10, dia.h+bgExtraHeight)

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setFont(self.dialogueFont)
		love.graphics.printf(dia.text, dia.x, dia.y, dia.w, "left")
		if dia.click then
			love.graphics.setColor(150, 150, 150, 255)
			love.graphics.setFont(self.clickFont)
			love.graphics.printf("click to continue", dia.x, dia.y + dia.h + 5, dia.w, "center")
		end
	end

	if util.isMouseOverText(x, y, self.skipText, self.skipFont) then
		love.graphics.setColor(80, 255, 80, 255)
	else
		love.graphics.setColor(255, 255, 255, 255)
	end
	love.graphics.setFont(self.skipFont)
	love.graphics.print(self.skipText.title, self.skipText.x, self.skipText.y)
end

function Tutorial:handleMouse(pressed, x, y)
	if not pressed then
		if util.isMouseOverText(x, y, self.skipText, self.skipFont) then
			love.event.push("endtutorial")
		end

		if self.dragging then
			self.dragging = false
		end

		if self.dialogues[self.dialogue].satisfied() then
			self.dialogue = self.dialogue + 1
		end

		self.station:setActive(false)
	elseif not self.dialogues[self.dialogue].click and pressed and self.employee:isWithin(x, y) then
		self.dragging = true
	end
end

return Tutorial
