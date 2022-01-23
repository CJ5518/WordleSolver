

local function filterWordlist(inFilename, outFilename)
	local inFile = io.open(inFilename, "r");
	local outFile = io.open(outFilename, "w");
	local doneLines = {};
	for line in inFile:lines() do
		line = line:lower();
		if line:len() == 5 and not line:find("[^%a]") and not doneLines[line] then
			doneLines[line] = true;
			outFile:write(line);
			outFile:write("\n");
		end
	end
	inFile:close();
	outFile:close();
end



local function printf(s, ...)
	print(string.format(s, ...));
end

local function loadWordList(inFilename)
	local inFile = io.open(inFilename, "r");
	local doneLines = {};
	for line in inFile:lines() do
		doneLines[#doneLines+1] = line;
	end
	inFile:close();
	return doneLines;
end

--filterWordlist("words.txt", "out.txt");

local words, knownLetters, semiKnownLetters, blackListLetters;

local function restart()
	print("Welcome to wordle solver");
	words = loadWordList("out.txt");
	knownLetters = {};
	semiKnownLetters = {};
	blackListLetters = "1";
	print("When prompted to display remaining words, you may also guess or restart (r) the system");
end

--Use this maybe for somthn idk
--https://rosettacode.org/wiki/Statistics/Normal_distribution#Lua
local function showHistogram (t) 
    local lo = math.ceil(math.min(unpack(t)))
    local hi = math.floor(math.max(unpack(t)))
    local hist, barScale = {}, 200
    for i = lo, hi do
        hist[i] = 0
        for k, v in pairs(t) do
            if math.ceil(v - 0.5) == i then
                hist[i] = hist[i] + 1
            end
        end
        io.write(i .. "\t" .. string.rep('=', hist[i] / #t * barScale))
        print(" " .. hist[i])
    end
end

local function step()
	printf("Working with %d words, display? (y/r/guess)", #words);
	local res = io.read();
	if res == "y" then
		for q = 1, #words do
			print(words[q]);
		end
	elseif res == "r" then
		return restart();
	elseif res:len() ~= 5 then
		print("Guess does not have 5 letters")
	else
		print("");
		print("Please indicate the results of your guess")
		print("N: Not in word");
		print("Y: In the word, in that position");
		print("?: In the word, but not that position");
		--Collect their results
		local results;
		while true do
			results = io.read();
			if results:len() ~= 5 or results:find("[^%?YN]") then
				print("Your guess has something wrong with it, please try again");
			else
				break;
			end
		end
		--Parse their results
		for q = 1, results:len() do
			local char = results:sub(q,q);
			if char == "?" then
				if semiKnownLetters[res:sub(q,q)] then
					semiKnownLetters[res:sub(q,q)][#semiKnownLetters[res:sub(q,q)]+1] = q;
				else
					semiKnownLetters[res:sub(q,q)] = {q};
				end
			elseif char == "Y" then
				if knownLetters[res:sub(q,q)] then
					knownLetters[res:sub(q,q)][#knownLetters[res:sub(q,q)]+1] = q;
				else
					knownLetters[res:sub(q,q)] = {q};
				end
			else
				blackListLetters = blackListLetters .. res:sub(q,q);
			end
		end
		--Trim the wordlist accordingly
		local newWords = {};
		for q = 1, #words do
			if not words[q]:find(string.format("[%s]", blackListLetters)) then
				local fitsWithKnown = true;
				for char, knownTab in pairs(knownLetters) do
					for i = 1, #knownTab do
						if words[q]:sub(knownTab[i], knownTab[i]) ~= char then
							fitsWithKnown = false; break;
						end
					end
					if not fitsWithKnown then break end
				end
				--Check for word containing letter but not at specific positions
				if fitsWithKnown then
					local fitsWithSemiKnown = true;
					for char, semiTab in pairs(semiKnownLetters) do
						for i = 1, #semiTab do
							if not words[q]:find(char) or words[q]:sub(semiTab[i], semiTab[i]) == char then
								fitsWithSemiKnown = false; break;
							end
						end
						if not fitsWithSemiKnown then break end
					end
					if fitsWithSemiKnown then
						newWords[#newWords+1] = words[q];
					end
				end
			end
		end
		words = newWords;
	end
end

restart();

while true do
	step();
end