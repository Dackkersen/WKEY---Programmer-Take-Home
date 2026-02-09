local groups = {
	[0] = "Player",
	[1] = "Developer"
}

return {
	Name = "commands";
	Aliases = {"cmds", "help"};
	Description = "Displays a list of all commands, or inspects one command.";
	Group = 0;
	Args = {
		{
			Type = "command";
			Name = "Command";
			Description = "The command to view information on";
			Optional = true;
		},
	};

	ClientRun = function (context, commandName)
		local CmdrGroup = context.Group
		if commandName then
			local command = context.Cmdr.Registry:GetCommand(commandName)
			if command.Group <= CmdrGroup then
				context:Reply(("Command: %s"):format(command.Name), Color3.fromRGB(230, 126, 34))
				if command.Aliases and #command.Aliases > 0 then
					context:Reply(("Aliases: %s"):format(table.concat(command.Aliases, ", ")), Color3.fromRGB(230, 230, 230))
				end
				context:Reply(command.Description, Color3.fromRGB(230, 230, 230))
				for i, arg in ipairs(command.Args) do
					context:Reply(("#%d %s%s: %s - %s"):format(
						i,
						arg.Name,
						arg.Optional == true and "?" or "",
						arg.Type, arg.Description
					))
				end
			else
				return "You don't have permission to view this command (" .. command.Group .. ")"
			end
		else
			local commands = context.Cmdr.Registry:GetCommands()
			table.sort(commands, function(a, b)
				return a.Group < b.Group
			end)
			local lastGroup
			for _, command in ipairs(commands) do
				if command.Group <= CmdrGroup then
					if lastGroup ~= command.Group and command.Group <= CmdrGroup then
						context:Reply(("\n%s\n-------------------"):format(groups[command.Group]))
						lastGroup = command.Group	
					end
					if command.Group <= CmdrGroup then
						context:Reply(("%s - %s"):format(command.Name, command.Description))
					end
				end
			end
		end
		return ""
	end;
}
