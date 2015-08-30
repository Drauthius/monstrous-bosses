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

local State = class("State")

function State:setManager(mgr)
	self.stateManager = mgr
end

function State:getStateManager()
	return self.stateManager
end

function State:onEnter(...) end

function State:onLeave() end

function State:update(dt) end

function State:draw() end

return State
