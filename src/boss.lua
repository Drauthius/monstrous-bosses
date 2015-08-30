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

local Boss = GameObject:subclass("Boss")

Boss.static.spriteSheet = love.graphics.newImage("gfx/boss.png")

function Boss:initialize(x, y)
	GameObject.initialize(self, x, y)

	self.font = love.graphics.newFont("ttf/monstapix.ttf", 24)

	self.assignQuotes = {
		"RS",
		"QS",
		"PO",
		"Wx"
	}
	self.fireQuotes = {
		"UQ",
		"UV",
		"UW",
		"QTP",
		"RTP",
		"oW"
	}
	self.idleQuotes = {
		"L",
		"OQR",
		"mS",
		"PPP",
		"w",
		"c",
		"r"
	}

	self.currentQuote = {
		text = nil,
		lastUntil = love.timer.getTime()
	}

	self.missing = false
	self.fireTimer = nil
	self.firingTimer = nil

	local bodyGrid = anim8.newGrid(150, 150, Boss.spriteSheet:getDimensions())
	self.bodyAnimation = anim8.newAnimation(bodyGrid('1-4',1, '3-2',1), 0.09, function()
		if self.currentQuote.lastUntil <= love.timer.getTime() then
			self.bodyAnimation:pauseAtStart()
		end
	end)
	self.bodyAnimation:pauseAtStart()
	self.size.w, self.size.h = 150, 150

	self.deathAnimation = anim8.newAnimation(bodyGrid('10-17',1),
		{ 0.8, 0.2, 0.2, 0.2, 0.1, 0.1, 0.1, 0.5 },
		function()
			self.missing = true
			self.deathAnimation:pauseAtEnd()
		end)

	-- Ugly, but hey.
	local eyeGrid = anim8.newGrid(150, 30, Boss.spriteSheet:getDimensions())
	self.eyeAnimation = anim8.newAnimation(eyeGrid('5-9',1, '9-5',1, 1,1), 0.04, "pauseAtEnd")
	self.blinkTimer = cron.after(0, function() end)
end

function Boss:isMissing()
	return self.missing
end

function Boss:isFiring()
	return self.fireTimer ~= nil or self.firingTimer ~= nil or self.gettingFired == true
end

function Boss:assignEmployee()
	self.currentQuote.text = self.assignQuotes[love.math.random(1, #self.assignQuotes)]
	self.currentQuote.lastUntil = love.timer.getTime() + 1.2
	self.bodyAnimation:resume()
end

function Boss:fireEmployee()
	self.currentQuote.text = self.fireQuotes[love.math.random(1, #self.fireQuotes)]
	self.currentQuote.lastUntil = love.timer.getTime() + 1
	self.fireTimer = cron.after(1, function() self.missing = true end)
	self.bodyAnimation:resume()
end

function Boss:getFired()
	self.missing = false
	self.fireTimer = nil
	self.firingTimer = nil
	self.gettingFired = true
	self.currentQuote.lastUntil = love.timer.getTime()
end

function Boss:update(dt)
	if love.timer.getTime() - self.currentQuote.lastUntil > 8 then
		self.currentQuote.text = self.idleQuotes[love.math.random(1, #self.idleQuotes)]
		self.currentQuote.lastUntil = love.timer.getTime() + 1.2
		self.bodyAnimation:resume()
	end

	if self.fireTimer and self.fireTimer:update(dt) then
		self.fireTimer = nil
		self.firingTimer = cron.after(1.5, function() self.missing = false end)
	end
	if self.firingTimer and self.firingTimer:update(dt) then
		self.firingTimer = nil
	end

	if not self.gettingFired then
		self.bodyAnimation:update(dt)
		self.eyeAnimation:update(dt)
		if self.blinkTimer:update(dt) then
			self.eyeAnimation:gotoFrame(1)
			self.eyeAnimation:resume()
			self.blinkTimer = cron.after(love.math.random(2, 5), function() end)
		end
	else
		self.deathAnimation:update(dt)
	end
end

function Boss:draw()
	if self:isMissing() then return end

	love.graphics.setColor(255, 255, 255, 255)
	if not self.gettingFired then
		self.bodyAnimation:draw(Boss.spriteSheet, self.pos.x, self.pos.y)
		self.eyeAnimation:draw(Boss.spriteSheet, self.pos.x, self.pos.y)
	else
		self.deathAnimation:draw(Boss.spriteSheet, self.pos.x, self.pos.y)
	end

	GameObject.draw(self)

	if self.currentQuote.lastUntil > love.timer.getTime() then
		local x = self.pos.x + self.size.w + 5
		local w = self.font:getWidth(self.currentQuote.text)
		local h = self.font:getHeight()
		local y = self.pos.y + 20 - h

		-- Speech bubble
		local bubbleOriginPoly = {
			self.pos.x + self.size.w, self.pos.y + 30,
			self.pos.x + self.size.w + w/2, y + h/2,
			self.pos.x + self.size.w + w, y + h/2
		}
		love.graphics.setLineWidth(2)

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.polygon("fill", bubbleOriginPoly)
		love.graphics.setColor(155, 0, 0, 255)
		love.graphics.polygon("line", bubbleOriginPoly)

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle("fill", x, y, w + 5, h + 5)
		love.graphics.setColor(155, 0, 0, 255)
		love.graphics.rectangle("line", x, y, w + 5, h + 5)

		-- Speech
		love.graphics.setColor(155, 0, 0, 255)
		love.graphics.setFont(self.font)
		love.graphics.print(self.currentQuote.text, x + 5, y + 5)
	end
end

return Boss
