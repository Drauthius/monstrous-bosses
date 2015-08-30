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

-- Globals
debug = false
music = nil

-- Classes
local StateManager = require("lib.state.manager")
local Title = require("src.title")
local Game = require("src.game")
local EndScreen = require("src.endscreen")

-- Objects
local stateMgr

function love.load()
	--music = love.audio.newSource("sfx/526428_8-bit-A-Labor-of-Lo.mp3", "stream")
	music = love.audio.newSource("sfx/373579_An_Evil_Industry.mp3", "stream")
	music:setVolume(0.2)
	music:setLooping(true)
	music:play()

	stateMgr = StateManager:new(
		Title:new(),
		EndScreen:new(),
		Game:new())
	stateMgr:enterState("Title")
	stateMgr:reverseDraworder(true)
	--stateMgr:enterState("EndScreen", { workSeconds = 123, numFired = 12 })
end

function love.update(dt)
	stateMgr:update(dt)
end

function love.draw()
	stateMgr:draw()

	if debug == true then
		love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 10, 1)
	end
end

function love.keypressed(key)
	if key == "rctrl" then
		debug = not debug
	elseif stateMgr:isStateActive("EndScreen") then
		stateMgr:getState("EndScreen"):keypressed(key)
	end
end

function love.textinput(text)
	if stateMgr:isStateActive("EndScreen") then
		stateMgr:getState("EndScreen"):textinput(text)
	end
end

function love.mousepressed(x, y, button)
	if button ~= "l" then return end
	stateMgr:getForegroundState():handleMouse(true, x, y)
end

function love.mousereleased(x, y, button)
	if button ~= "l" then return end
	stateMgr:getForegroundState():handleMouse(false, x, y)
end

function love.handlers.endtutorial()
	stateMgr:getState("Game"):endTutorial()
end

function love.handlers.gameover()
	stateMgr:getState("Game"):gameOver()
end
