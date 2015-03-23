
lookup = {
	["0"] = colours.white;
	["1"] = colours.orange;
	["2"] = colours.magenta;
	["3"] = colours.lightBlue;
	["4"] = colours.yellow;
	["5"] = colours.lime;
	["6"] = colours.pink;
	["7"] = colours.grey;
	["8"] = colours.lightGrey;
	["9"] = colours.cyan;
	["A"] = colours.purple;
	["B"] = colours.blue;
	["C"] = colours.brown;
	["D"] = colours.green;
	["E"] = colours.red;
	["F"] = colours.black;
	[" "] = 0;
}

save = {}
for k, v in pairs( lookup ) do
	save[v] = k
end
