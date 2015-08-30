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

local State = require("lib.state.state")

local Infinite = require("src.infinite")
local Tutorial = require("src.tutorial")

local Game = State:subclass("Game")

function Game:initialize()
	--self.quitFont = love.graphics.newFont(14)
	--self.quitFont = love.graphics.newFont("ttf/jupiterc.ttf", 32)
	--self.quitFont = love.graphics.newFont("ttf/pixel-love.ttf", 24)
	self.quitFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 24)
	--self.quitFont = love.graphics.newFont("ttf/PixelDevilsdeal.tt", 24)
	self.quitText = {
		title = "Quit",
		x = love.window.getWidth()-self.quitFont:getWidth("Quit")-10,
		y = 1
	}
end

function Game:onEnter()
	self.mode = Tutorial:new()
	--self.mode = Infinite:new()
end

function Game:update(dt)
	if self:getStateManager():getForegroundState() == self then
		self.mode:update(dt)
	end
end

function Game:draw()
	self.mode:draw()

	if self:getStateManager():getForegroundState() == self then
		local x, y = love.mouse.getPosition()

		if util.isMouseOverText(x, y, self.quitText, self.quitFont) then
			love.graphics.setColor(80, 255, 80, 255)
		else
			love.graphics.setColor(255, 255, 255, 255)
		end
		love.graphics.setFont(self.quitFont)
		love.graphics.print(self.quitText.title, self.quitText.x, self.quitText.y)
	end
end

function Game:handleMouse(pressed, x, y)
	if not pressed and util.isMouseOverText(x, y, self.quitText, self.quitFont) then
		love.event.quit()
	end
	self.mode:handleMouse(pressed, x, y)
end

function Game:endTutorial()
	--[[self.mode:destroy(function()
		self.mode = Infinite:new()
	end)]]--
	self.mode = Infinite:new()
end

function Game:gameOver()
	self.mode:destroy(function(score)
		--self:getStateManager():switchState("EndScreen", score)
		self:getStateManager():enterState("EndScreen", score)
	end)
end

return Game
