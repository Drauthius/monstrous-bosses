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

local GameObject = class("GameObject")

function GameObject:initialize(x, y)
	self.pos = { x = x, y = y }
	self.size = { w = 50, h = 100 }
	self.active = false
end

function GameObject:isWithin(x, y)
	x = x - self.pos.x
	y = y - self.pos.y
	return x >= 0 and x <= self.size.w and y >= 0 and y <= self.size.h
end

function GameObject:isIntersecting(other)
	return not (
		self.pos.x + self.size.w < other.pos.x or
		other.pos.x + other.size.w < self.pos.x or
		self.pos.y + self.size.h < other.pos.y or
		other.pos.y + other.size.h < self.pos.y)
end

function GameObject:setActive(isActive)
	self.active = isActive
end

function GameObject:isActive()
	return self.active
end

function GameObject:update(dt)
end

function GameObject:draw()
	if debug then
		if self.active then
			love.graphics.setColor(80, 255, 80, 255)
		else
			love.graphics.setColor(80, 80, 255, 255)
		end
		love.graphics.rectangle("line", self.pos.x, self.pos.y, self.size.w, self.size.h)
	end
end

return GameObject
