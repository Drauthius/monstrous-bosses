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

local util = require("src.util")

local Door = require("src.door")
local State = require("lib.state.state")
local Infinite = require("src.infinite")

local Title = State:subclass("Title")

function Title:initialize()
	self.titleFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 52)
	self.font = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 32)
	self.menu = {
		{ title = "Start game",
		  x = 100, y = 400,
		  action = function()
			  self:getStateManager():switchState("Game")
		  end
		},
		{ title = "Quit",
		  x = 100, y = 500,
		  action = love.event.quit
		}
	}

	self.door = Door:new(unpack(Infinite.doorLocation))
end

function Title:update(dt)
end

function Title:draw()
	love.graphics.setFont(self.font)

	love.graphics.setColor(255, 255, 255, 100)
	love.graphics.draw(Infinite.background)
	--self.door:draw()
	love.graphics.draw(Door.spriteSheet, Door.spriteGrid:getFrames(1,1)[1], self.door.pos.x, self.door.pos.y) --lol

	local x, y = love.mouse.getPosition()

	for _,item in ipairs(self.menu) do
		love.graphics.setColor(255, 255, 255, 255)
		if util.isMouseOverText(x, y, item, self.font) then
			love.graphics.setColor(80, 255, 80, 255)
		end
		love.graphics.print(item.title, item.x, item.y)
	end

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(self.titleFont)
	love.graphics.printf("Monstrous\nBosses", 0, 50, love.window.getWidth(), "center")
end

function Title:handleMouse(pressed, x, y)
	if pressed then return end

	for _,item in ipairs(self.menu) do
		if util.isMouseOverText(x, y, item, self.font) then
			item.action()
		end
	end
end

return Title
