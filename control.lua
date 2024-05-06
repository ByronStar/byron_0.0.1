--"commands" acceses the LuaCommandProcessor
--"add_command" takes in three parameters (name -> string, help -> string, function)
local inspect = require('inspect')

function screenshot(command) --Event pass a table into the function
	--game.get_player() returns a LuaPlayer object
	local player = game.get_player(command.player_index)

	--print a message to just the player who sent it
	local color = { r = 1, g = 0, b = 0, a = 1 }
	player.print("Hello there! This is a private message to: " .. player.name, color)

	local name = "screen"
	local cnt = 1
	local square = 128
	local tiled = false

	-- one step = 32 pixel
	if command.parameter ~= nil then
		local i = 0
		for w in command.parameter:gmatch("%S+") do
			if i == 0 then
				name = w
			elseif i == 1 then
				cnt = tonumber(w)
			elseif i == 2 then
				tiled = true
			else
				player.print(i, w)
			end
			i = i + 1
		end
	end
	if square * cnt > 512 then
		tiled = true
	end
	local origin = { x = 0, y = 0 }
	if game.player.character ~= nil then
		origin = game.player.character.position
	end
	if tiled then
		-- local pos = { x = math.floor(origin.x / 5) * 5 - cnt / 2 * square, y = math.floor(origin.y / 5) * 5 - cnt / 2 * square}
		local pos = {
			x = math.floor(origin.x) - cnt / 2 * square,
			y = math.floor(origin.y) - cnt / 2 * square
		}
		player.print('x=' .. pos.x .. ' y=' .. pos.y)
		for y = 0, cnt do
			for x = 0, cnt do
				player.print(name .. "_" .. y .. "x" .. x .. ".png")
				game.take_screenshot { show_entity_info = true, resolution = { x = square * 32, y = square * 32 }, position = { x = pos.x + x * square, y = pos.y + y * square }, path = name .. "_" .. y .. "x" .. x .. ".png", zoom = 1, daytime = 1.0 }
			end
		end
	else
		local pos = { x = math.floor(origin.x), y = math.floor(origin.y) }
		player.print('x=' .. pos.x .. ' y=' .. pos.y)

		game.take_screenshot { show_entity_info = true, resolution = { x = square * cnt * 32, y = square * cnt * 32 }, position = { x = pos.x, y = pos.y }, path = name .. ".png", zoom = 0.5, daytime = 1.0 }
	end

	--game.print() would print a message to all players -> LuaGameScript*
	-- game.print("This is a global message to all players")
end

function cleanupTransport(command) --Event pass a table into the function
	for _, ent in pairs(game.player.surface.find_entities_filtered { type = { "splitter", "transport-belt", "underground-belt" } }) do
		for i = 1, ent.get_max_transport_line_index() do
			ent.get_transport_line(i).clear()
		end
	end
end

function cleanupAssembly(command) --Event pass a table into the function
	local count = game.player.surface.count_entities_filtered { type = "assembling-machine" }
	if count >= 1 then
		for _, entity in pairs(game.player.surface.find_entities_filtered { type = "assembling-machine" }) do
			local inventory = entity.get_inventory(defines.inventory.assembling_machine_output)
			for content, amount in pairs(inventory.get_contents()) do
				game.player.print(entity.name .. ' c=' .. content .. ' o=' .. tostring(amount))
			end
			inventory.clear()

			inventory = entity.get_inventory(defines.inventory.assembling_machine_input)
			for content, amount in pairs(inventory.get_contents()) do
				game.player.print(entity.name .. ' c=' .. content .. ' i=' .. tostring(amount))
			end
			inventory.clear()
			-- get_fluid_contents()
		end
	end
end

function GetParms(values, t, idx) --Event pass a table into the function
	if values ~= nil then
		local i = 0
		for w in values:gmatch("%S+") do
			if type(w) == "number" then
				t[idx[i]] = tonumber(w)
			else
				t[idx[i]] = w
			end
			-- game.player.print(i .. ' w=' .. t[idx[i]])
			i = i + 1
		end
	end
end

function patch(command) --Event pass a table into the function
	local data = {
		ore = "stone",
		x = 0,
		y = 0,
		size = 5,
		density = 10
	}
	local surface = game.player.surface
	local amount
	GetParms(command.parameter, data, { [0] = "ore", [1] = "x", [2] = "y", [3] = "size", [4] = "density" })
	game.player.print('data=' .. inspect(data))
	for y = -data.size, data.size do
		for x = -data.size, data.size do
			a = (data.size + 1 - math.abs(x)) * 10
			b = (data.size + 1 - math.abs(y)) * 10
			if a < b then
				amount = math.random(a * data.density - a * (data.density - 8), a * data.density + a * (data.density - 8))
			end
			if b < a then
				amount = math.random(b * data.density - b * (data.density - 8), b * data.density + b * (data.density - 8))
			end
			if surface.get_tile(data.x + x, data.y + y).collides_with("ground-tile") then
				surface.create_entity({ name = data.ore, amount = amount, position = { data.x + x, data.y + y } })
			end
		end
	end
end

function export_filter(command) --Event pass a table into the function
	game.write_file("quickbar.txt", "local bar_filter = {\n", false)
	for i = 1, 100 do
		local filter = game.player.get_quick_bar_slot(i)
		if filter then
			game.player.print(tostring(i) .. "," .. filter.name)
			game.write_file("quickbar.txt", "{ slot = " .. tostring(i) .. ", item = \"" .. filter.name .. "\" },\n", true)
		end
	end
	game.write_file("quickbar.txt", "}\n", true)

	game.write_file("infinity.txt", "local chest_filter = {\n", false)
	for _, ent in pairs(game.player.surface.find_entities_filtered { type = { "infinity-container" } }) do
		game.player.print(">>" .. ent.name)
		for i = 1, 100 do
			local filter = ent.get_infinity_container_filter(i)
			if filter then
				game.player.print(tostring(i) .. "," .. filter.name)
				game.write_file("infinity.txt",
					"{ slot = " ..
					tostring(i) ..
					", item = { name = \"" ..
					filter.name .. "\", count = " .. filter.count .. ", mode = \"" .. filter.mode .. "\"} },\n", true)
			end
		end
	end
	game.write_file("infinity.txt", "}\n", true)
end

function init_chest(command) --Event pass a table into the function
	local chest_filter = {
		{ slot = 1,  item = { name = "loader", count = 50, mode = "at-least" } },
		{ slot = 2,  item = { name = "electric-energy-interface", count = 50, mode = "at-least" } },
		{ slot = 3,  item = { name = "infinity-chest", count = 10, mode = "at-least" } },
		{ slot = 4,  item = { name = "infinity-pipe", count = 10, mode = "at-least" } },
		{ slot = 5,  item = { name = "transport-belt", count = 100, mode = "at-least" } },
		{ slot = 6,  item = { name = "underground-belt", count = 50, mode = "at-least" } },
		{ slot = 7,  item = { name = "splitter", count = 50, mode = "at-least" } },
		{ slot = 8,  item = { name = "inserter", count = 50, mode = "at-least" } },
		{ slot = 9,  item = { name = "fast-inserter", count = 50, mode = "at-least" } },
		{ slot = 10, item = { name = "filter-inserter", count = 50, mode = "at-least" } },
		{ slot = 11, item = { name = "stack-inserter", count = 50, mode = "at-least" } },
		{ slot = 12, item = { name = "small-electric-pole", count = 50, mode = "at-least" } },
		{ slot = 13, item = { name = "medium-electric-pole", count = 50, mode = "at-least" } },
		{ slot = 14, item = { name = "big-electric-pole", count = 50, mode = "at-least" } },
		{ slot = 15, item = { name = "pipe", count = 100, mode = "at-least" } },
		{ slot = 16, item = { name = "pipe-to-ground", count = 50, mode = "at-least" } },
		{ slot = 17, item = { name = "stone-furnace", count = 50, mode = "at-least" } },
		{ slot = 18, item = { name = "assembling-machine-1", count = 50, mode = "at-least" } },
		{ slot = 19, item = { name = "assembling-machine-3", count = 50, mode = "at-least" } },
		{ slot = 20, item = { name = "assembling-machine-2", count = 50, mode = "at-least" } },
		{ slot = 21, item = { name = "oil-refinery", count = 10, mode = "at-least" } },
		{ slot = 22, item = { name = "chemical-plant", count = 10, mode = "at-least" } },
		{ slot = 23, item = { name = "centrifuge", count = 50, mode = "at-least" } },
		{ slot = 24, item = { name = "nuclear-reactor", count = 10, mode = "at-least" } },
		{ slot = 25, item = { name = "heat-pipe", count = 50, mode = "at-least" } },
		{ slot = 26, item = { name = "heat-exchanger", count = 50, mode = "at-least" } },
		{ slot = 27, item = { name = "steam-turbine", count = 10, mode = "at-least" } },
		{ slot = 28, item = { name = "boiler", count = 50, mode = "at-least" } },
		{ slot = 29, item = { name = "steam-engine", count = 10, mode = "at-least" } },
		{ slot = 30, item = { name = "solar-panel", count = 50, mode = "at-least" } },
		{ slot = 31, item = { name = "accumulator", count = 50, mode = "at-least" } },
		{ slot = 32, item = { name = "electric-mining-drill", count = 50, mode = "at-least" } },
		{ slot = 33, item = { name = "offshore-pump", count = 20, mode = "at-least" } },
		{ slot = 34, item = { name = "pumpjack", count = 20, mode = "at-least" } },
		{ slot = 35, item = { name = "steel-furnace", count = 50, mode = "at-least" } },
		{ slot = 36, item = { name = "electric-furnace", count = 50, mode = "at-least" } },
		{ slot = 37, item = { name = "beacon", count = 10, mode = "at-least" } },
	}


	for _, ent in pairs(game.player.surface.find_entities_filtered { type = { "infinity-container" } }) do
		game.player.print(">>" .. ent.name)
		for k, v in pairs(chest_filter) do
			ent.set_infinity_container_filter(v.slot, v.item)
		end
	end
end

function startup(command) --Event pass a table into the function
	local bar_filter = {
		{ slot = 1,  item = "stone-furnace" },
		{ slot = 2,  item = "assembling-machine-1" },
		{ slot = 3,  item = "assembling-machine-2" },
		{ slot = 4,  item = "assembling-machine-3" },
		{ slot = 5,  item = "oil-refinery" },
		{ slot = 6,  item = "chemical-plant" },
		{ slot = 7,  item = "centrifuge" },
		{ slot = 8,  item = "lab" },

		{ slot = 11, item = "steel-chest" },
		{ slot = 12, item = "transport-belt" },
		{ slot = 13, item = "underground-belt" },
		{ slot = 14, item = "splitter" },
		{ slot = 15, item = "inserter" },
		{ slot = 16, item = "filter-inserter" },
		{ slot = 17, item = "stack-inserter" },
		{ slot = 18, item = "small-electric-pole" },
		{ slot = 19, item = "medium-electric-pole" },

		{ slot = 20, item = "logistic-chest-storage" },
		{ slot = 21, item = "small-lamp" },
		{ slot = 22, item = "red-wire" },
		{ slot = 23, item = "green-wire" },
		{ slot = 24, item = "arithmetic-combinator" },
		{ slot = 25, item = "decider-combinator" },
		{ slot = 26, item = "constant-combinator" },
		{ slot = 27, item = "programmable-speaker" },

		{ slot = 31, item = "infinity-chest" },
		{ slot = 32, item = "loader" },
		{ slot = 33, item = "infinity-pipe" },
		{ slot = 34, item = "electric-energy-interface" },
		{ slot = 35, item = "roboport" },
	}

	game.player.insert "infinity-chest"
	game.player.insert "infinity-pipe"
	game.player.insert "electric-energy-interface"
	game.player.insert "loader"
	game.player.insert "small-electric-pole"
	game.player.insert "logistic-chest-storage"
	game.player.insert "roboport"

	for y = 0, 7 do
		game.player.insert "construction-robot"
	end

	for k, v in pairs(bar_filter) do
		game.player.set_quick_bar_slot(v.slot, v.item)
	end

	FillSpace(0, 0, 256)
end

function setOre()
	for y = 0, 0 do
		for x = 0, 0 do
			if surface.get_tile(data.x + x, data.y + y).collides_with("ground-tile") then
				surface.create_entity({ name = data.ore, amount = amount, position = { data.x + x, data.y + y } })
			end
		end
	end
end

function FillSpace(x, y, c)
	local surface = game.player.surface

	surface.destroy_decoratives({ left_top = { x - c, y - c }, right_bottom = { x + c, y + c } })
	local tiles = {}
	for dy = -c, c do
		for dx = -c, c do
			table.insert(tiles, { name = "sand-" .. math.random(3), position = { x + dx, y + dy } })
		end
	end
	surface.set_tiles(tiles)
end

function clearSpace(command) --Event pass a table into the function
	local killzone = { left_top = { x, y }, right_bottom = { x + 32, y + 32 } }

	for _, entity in ipairs(event.surface.find_entities(killzone)) do
		if entity.valid then
			if entity.name == "character" then
				-- don't destroy the player's character
			else
				entity.destroy()
			end
		end
	end

	event.surface.destroy_decoratives(killzone)

	local tiles = {}
	for dy = 0, 32 do
		for dx = 0, 32 do
			if math.fmod(x + dx, 2) == 0 then
				if math.fmod(y + dy, 2) == 0 then
					table.insert(tiles, { name = "lab-dark-1", position = { x + dx, y + dy } })
				else
					table.insert(tiles, { name = "lab-dark-2", position = { x + dx, y + dy } })
				end
			else
				if math.fmod(y + dy, 2) == 0 then
					table.insert(tiles, { name = "lab-dark-2", position = { x + dx, y + dy } })
				else
					table.insert(tiles, { name = "lab-dark-1", position = { x + dx, y + dy } })
				end
			end
		end
	end
	event.surface.set_tiles(tiles)
end

function cleanup(command) --Event pass a table into the function
	cleanupTransport(command)
	cleanupAssembly(command)
end

commands.add_command("save_screen", "Save area around player as image", screenshot)
commands.add_command("clean_transport", "Remove items from transports", cleanupTransport)
commands.add_command("clean_assembly", "Remove items from assembly machines", cleanupAssembly)
commands.add_command("cleanup", "Remove items from machines and transports", cleanup)
commands.add_command("startup", "Initialize Creative", startup)
commands.add_command("export_filter", "Save Quickbar setup", export_filter)
commands.add_command("init_chest", "Save Quickbar setup", init_chest)
commands.add_command("patch", "Remove items from machines and transports", patch)

function entity_placed(event)
	local player = game.get_player(event.player_index)
	local entity = event.created_entity

	--add random alert to confuse the player
	-- player.add_alert(entity, defines.alert_type.entity_destroyed)
	player.print('event=' .. inspect(event))
	-- player.print('container=' .. inspect(entity))
end

-- local filters = {{filter="type", type="container"}}
-- script.on_event(defines.events.on_built_entity, entity_placed, filters) --link event to function


--[[
LuaGameScript Documentation:
	https://lua-api.factorio.com/latest/LuaGameScript.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaGameScript.html

LuaCommandProcessor Documentation:
	https://lua-api.factorio.com/latest/LuaCommandProcessor.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaCommandProcessor.html

LuaPlayer Documentation:
	https://lua-api.factorio.com/latest/LuaPlayer.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaPlayer.html
]]
