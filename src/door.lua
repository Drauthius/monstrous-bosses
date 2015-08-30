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

local Door = GameObject:subclass("Door")

Door.static.spriteSheet = love.graphics.newImage("gfx/door.png")
Door.static.spriteGrid = anim8.newGrid(244, 126, Door.spriteSheet:getWidth(), Door.spriteSheet:getHeight(), 1, 1, 1)

Door.static.sound = love.audio.newSource("sfx/door_heavy_shut_flats_corridor_reverb.mp3")

function Door:initialize(x, y)
	GameObject.initialize(self, x, y)

	self.size.w = Door.spriteGrid.frameWidth
	self.size.h = Door.spriteGrid.frameHeight

	self.sound = Door.sound -- or clone
	self.sound:setVolume(2)
	self.sound:setLooping(false)

	self.open = false
end

function Door:isOpen()
	return self.open
end

function Door:setOpen(open)
	if self.open ~= open then
		self.sound:play()
		self.open = open
	end
end

function Door:draw()
	local frames = Door.spriteGrid:getFrames(1,1, 1,2)
	local draw = 1
	if self:isOpen() then
		draw = 2
	end

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(Door.spriteSheet, frames[draw], self.pos.x, self.pos.y)
	if self:isActive() then
		love.graphics.setColor(0, 255, 0, 100)
		love.graphics.draw(Door.spriteSheet, frames[draw], self.pos.x, self.pos.y)
	end

	GameObject.draw(self)
end

return Door
