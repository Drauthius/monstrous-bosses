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

local State = require("lib.state.state")

local EndScreen = State:subclass("EndScreen")

function EndScreen:initialize()
	self.highScoreFile = love.filesystem.newFile("highScore")
	if love.filesystem.exists("highScore") then
		self.highScore = {}

		self.highScoreFile:open("r")
		for line in self.highScoreFile:lines() do
			local score, name = line:match("(%d+) (.*)")
			table.insert(self.highScore, { tonumber(score), name })
		end
		self.highScoreFile:close()
	else
		-- Some nice defaults
		self.highScore = {
			{ 1000, "Diablo" },
			{ 800, "Slave driver" },
			{ 400, "Brute" },
			{ 100, "Lesser Imp"}
		}
	end

	self.credits = {
		{ "Programmer", "Albert Diserholt" },
		{ "Graphics", "Sunisa Thongdaengdee\n& Albert Diserholt" },
		{ "", "" },
		{ "Created for Ludum Dare 33:" },
		{ '"You are the Monster"' },
		{ "" },
		{ "Music by scrappy777 @ newgrounds.org" },
		{ "" },
		{ "Sound effects from http://www.freesfx.co.uk" },
		{ "" }
	}

	self.titleFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 32)
	self.subtitleFont = love.graphics.newFont("ttf/Retro Computer_DEMO.ttf", 24)
	self.textFont = love.graphics.newFont("ttf/Minecraftia-Regular.ttf", 16)

	self.tips = {
		"Workers with the same colour share the same personality and resistances.",
		"Different workers react differently to different work stations. "
		.."Try and find the optimal assignment.",
		"Firing someone takes time, so make sure that no worker is close to fully rested "
		.."before performing the action."
	}
	self.currentTip = 0

	self.time = 0
end

function EndScreen:onEnter(score)
	self.score = score
	self.score.total = math.floor(self.score.workSeconds) + self.score.numFired * 20

	self.entering = ""
	self.pos = -1
	for i=1,#self.highScore do
		if self.highScore[i][1] < self.score.total then
			table.insert(self.highScore, i, { self.score.total, "" })
			self.pos = i
			break
		end
	end
	if self.pos == -1 then
		table.insert(self.highScore, { self.score.total, "" })
		self.pos = #self.highScore
	end

	for i=11,#self.highScore do
		self.highScore[i] = nil
	end
	if self.pos > 10 or self.score.total <= 0 then
		self.pos = -1
		self.entering = nil
	end

	self.currentTip = (self.currentTip % #self.tips) + 1
end

function EndScreen:update(dt)
	self.time = self.time + dt
end

function EndScreen:draw()
	-- Draw a rectangle over the screen.
	love.graphics.setColor(0, 0, 0, 200)
	love.graphics.rectangle("fill", 0, 0, love.window.getDimensions())

	local leftCol = 115
	local rightCol = love.window.getWidth()/2 + leftCol + 15
	local lineSpacing = self.textFont:getHeight()*1.5

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(self.titleFont)
	love.graphics.printf("Game Over", 0, 50, love.window.getWidth(), "center")

	do -- Left column
		local scoreStart = 150
		love.graphics.setFont(self.subtitleFont)
		love.graphics.print("Your score:", leftCol-15, scoreStart)

		scoreStart = scoreStart + self.subtitleFont:getHeight() * 1.5
		love.graphics.setFont(self.textFont)
		love.graphics.print("Forced working time: "..math.floor(self.score.workSeconds), leftCol, scoreStart)
		love.graphics.print("Employees crushed: "..self.score.numFired, leftCol, scoreStart + lineSpacing)
		love.graphics.print("Total score: "..self.score.total, leftCol, scoreStart + lineSpacing*2)

		local highScoreStart = scoreStart + lineSpacing*2 + 50
		love.graphics.setFont(self.subtitleFont)
		love.graphics.print("High score:", leftCol-15, highScoreStart)

		highScoreStart = highScoreStart + self.subtitleFont:getHeight() * 1.5 - lineSpacing
		love.graphics.setFont(self.textFont)
		for i=1,10 do
			local v = self.highScore[i]
			highScoreStart = highScoreStart + lineSpacing
			love.graphics.print(i, leftCol, highScoreStart)
			if v ~= nil then
				love.graphics.printf(v[1], leftCol+15, highScoreStart, 100, "right")
				if self.pos == i then
					love.graphics.print(self.entering, leftCol+130, highScoreStart)
					if math.floor(self.time * 4) % 2 == 0 then
						local width = self.textFont:getWidth(self.entering)
						local oneWidth = self.textFont:getWidth("w")
						if #self.entering == 10 then
							width = width - oneWidth
						end
						love.graphics.rectangle("fill",
							leftCol+130 + width,
							highScoreStart + self.textFont:getHeight()-1,
							oneWidth+1, 4)
					end
				else
					love.graphics.print(v[2], leftCol+130, highScoreStart)
				end
			else
				love.graphics.printf(0, leftCol+15, highScoreStart, 100, "right")
				love.graphics.print("-", leftCol+130, highScoreStart)
			end
		end
	end

	do -- Right column
		local creditsStart = 150
		love.graphics.setFont(self.subtitleFont)
		love.graphics.print("Credits", rightCol-15, creditsStart)
		creditsStart = creditsStart + self.subtitleFont:getHeight() * 1.5 - lineSpacing

		love.graphics.setFont(self.textFont)
		for i,v in ipairs(self.credits) do
			creditsStart = creditsStart + lineSpacing

			if v[2] ~= nil then
				love.graphics.printf(v[1], rightCol, creditsStart, 100, "right")
				love.graphics.print(v[2], rightCol+115, creditsStart)
			else
				love.graphics.printf(v[1], rightCol, creditsStart, love.window.getWidth() - rightCol - 15, "center")
			end
		end

		local tipsStart = creditsStart + 50
		love.graphics.setFont(self.subtitleFont)
		love.graphics.print("Tips", rightCol-15, tipsStart)

		tipsStart = tipsStart + self.subtitleFont:getHeight() * 1.5
		love.graphics.setFont(self.textFont)
		love.graphics.printf(self.tips[self.currentTip], rightCol, tipsStart, love.window.getWidth() - rightCol - 15)
	end

	if self.entering == nil then
		love.graphics.setFont(self.textFont)
		love.graphics.printf("click to restart", 0, love.window.getHeight() - 20, love.window.getWidth(), "center")
	end
end

function EndScreen:handleMouse(pressed)
	if not pressed and self.entering == nil then
		self:getStateManager():leaveState("Game")
		self:getStateManager():switchState("Game")
		love.event.push("endtutorial")
	end
end

function EndScreen:textinput(t)
	if self.entering ~= nil then
		self.entering = self.entering:sub(1, 9) .. t
	end
end

function EndScreen:keypressed(key)
	if self.entering ~= nil then
		if key == "backspace" then
			self.entering = self.entering:sub(1, #self.entering-1)
		elseif key == "return" or key == "enter" then
			self:save()
			self.entering = nil
		end
	end
end

function EndScreen:save()
	if self.entering ~= "" then
		self.highScore[self.pos][2] = self.entering
		self.highScoreFile:open("w")
		for _,entry in ipairs(self.highScore) do
			self.highScoreFile:write(("%d %s\n"):format(entry[1], entry[2]))
		end
		self.highScoreFile:close()
	end

	self.pos = -1
end

return EndScreen
