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

local util = {}

function util.isMouseOverText(x, y, item, font, offset)
	local offset = offset or 10
	x = x - item.x
	if x >= -offset and x <= font:getWidth(item.title) + offset then
		y = y - item.y
		if y >= -offset and y <= font:getHeight() + offset then
			return true
		end
	end

	return false
end

return util
