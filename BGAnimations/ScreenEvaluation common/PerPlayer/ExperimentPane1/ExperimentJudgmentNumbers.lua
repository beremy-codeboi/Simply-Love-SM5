local player = ...
local pn = ToEnumShortString(player)
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local whichHighScore = 1
local highScore
local rateMode = SL.Global.ActiveModifiers.MusicRate ~= 1 and true or false
if rateMode ~= 1 then
	local RateScores = GetRateScores(player, GAMESTATE:GetCurrentSong(), GAMESTATE:GetCurrentSteps(pn))
	if RateScores then
		if RateScores[1].score == pss:GetPercentDancePoints() then whichHighScore = 2 end --TODO this doesn't account for getting a duplicate highscore
		highScore = RateScores[whichHighScore]
	end
elseif STATSMAN:GetCurStageStats():GetPlayerStageStats(pn):GetPersonalHighScoreIndex() == 0 then 
	whichHighScore = 2 
	highScore = PROFILEMAN:GetProfile(pn):GetHighScoreList(GAMESTATE:GetCurrentSong(),GAMESTATE:GetCurrentSteps(pn)):GetHighScores()[whichHighScore]
end
local TapNoteScores = {
	Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
	-- x values for P1 and P2
	x = { P1=64, P2=94 }
}

local RadarCategories = {
	Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
	-- x values for P1 and P2
	x = { P1=-180, P2=218 }
}

-----------------------------------------------------------------------------------------------------------------
--AF for the stats to compare to

local highScoreT = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.6):xy(_screen.cx - 155,_screen.cy+10) end,
}

local deltaT = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.8):xy(_screen.cx - 155,_screen.cy-24) end,
}
if highScore then
	-- do "regular" TapNotes first
	for i=1,#TapNoteScores.Types do
		local window = TapNoteScores.Types[i]
		local number = rateMode and highScore[window] or highScore:GetTapNoteScore( "TapNoteScore_"..window )

		--delta between current stats and highscore stats
		deltaT[#deltaT+1] = LoadFont("_wendy small")..{
			InitCommand=function(self)
				local toPrint
				if rateMode then toPrint = pss:GetTapNoteScores( "TapNoteScore_"..window ) - highScore[window]
				else toPrint = pss:GetTapNoteScores( "TapNoteScore_"..window ) - highScore:GetTapNoteScore( "TapNoteScore_"..window ) end
				if toPrint >= 0 then self:settext("+"..toPrint)
				else self:settext(toPrint) end
				self:zoom(.5):horizalign(left)
				self:x( TapNoteScores.x[pn] -200)
				self:y((i-1)*35 -20)
				if SL.Global.GameMode ~= "ITG" then
					self:diffuse( SL.JudgmentColors[SL.Global.GameMode][i] )
				end
				-- if some TimingWindows were turned off, the leading 0s should not
				-- be colored any differently than the (lack of) JudgmentNumber,
				-- so load a unique Metric group.
				local gmods = SL.Global.ActiveModifiers
				if i > gmods.WorstTimingWindow and i ~= #TapNoteScores.Types then
					self:diffuse(color("#444444"))
				end
				
				if toPrint > 0 then
					if window == "Miss" or window == "W5" 
						then self:diffuse(Color.Red)
					else self:diffuse(Color.Green) end
				elseif window == "Miss" or window == "W5" then self:diffuse(Color.Green)
				else self:diffuse(Color.Red) end
			end,
		}
		
		-- actual numbers for previous record
		highScoreT[#highScoreT+1] = Def.RollingNumbers{
			Font="_ScreenEvaluation numbers",
			InitCommand=function(self)
				self:zoom(0.5):horizalign(right)

				if SL.Global.GameMode ~= "ITG" then
					self:diffuse( SL.JudgmentColors[SL.Global.GameMode][i] )
				end

				-- if some TimingWindows were turned off, the leading 0s should not
				-- be colored any differently than the (lack of) JudgmentNumber,
				-- so load a unique Metric group.
				local gmods = SL.Global.ActiveModifiers
				if i > gmods.WorstTimingWindow and i ~= #TapNoteScores.Types then
					self:Load("RollingNumbersEvaluationNoDecentsWayOffs")
					self:diffuse(color("#444444"))

				-- Otherwise, We want leading 0s to be dimmed, so load the Metrics
				-- group "RollingNumberEvaluationA"	which does that for us.
				else
					self:Load("RollingNumbersEvaluationA")
				end
			end,
			BeginCommand=function(self)
				self:x( TapNoteScores.x[pn] )
				self:y((i-1)*35 -20)
				self:targetnumber(number)
			end
		}

	end

	-- then handle holds, mines, hands, rolls
	for index, RCType in ipairs(RadarCategories.Types) do
		local performance
		if rateMode then performance = highScore[RCType]
		else performance = highScore:GetRadarValues():GetValue( "RadarCategory_"..RCType ) end
		-- player performace value
		highScoreT[#highScoreT+1] = Def.RollingNumbers{
			Font="_ScreenEvaluation numbers",
			InitCommand=function(self) self:zoom(0.5):horizalign(right):Load("RollingNumbersEvaluationB") end,
			BeginCommand=function(self)
				self:y((index-1)*35 + 53)
				self:x( 218 )
				self:targetnumber(performance)
			end
		}

	end
	--Label for previous record or current record depending on if you got a new high score
	highScoreT[#highScoreT+1] = LoadFont("_wendy small")..{
		InitCommand=function(self) --TODO setting text should go in a set command so we have time to determine whichhighscore
			self:zoom(.8):xy(150,-75)
			if whichHighScore == 2 then self:settext("Previous Record")
			else self:settext("Current Record") end
		end,
	}
	--dark quad for the previous record percentage
	highScoreT[#highScoreT+1] =	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(150, 60)
			self:horizalign(right)
			self:xy(308,-10)
		end
	}
	local PercentDP = rateMode and highScore.score or highScore:GetPercentDP()
	local percent = FormatPercentScore(PercentDP)
	-- Format the Percentage string, removing the % symbol
	percent = percent:gsub("%%", "")

	highScoreT[#highScoreT+1] = LoadFont("_wendy white")..{
		Name="Percent",
		Text=percent,
		InitCommand=function(self)
			self:horizalign(right):zoom(0.585)
			self:xy(300,-10)
		end
	}
	
	highScoreT[#highScoreT+1] = LoadActor("./ExperimentJudgmentLabels.lua", player)
	
else
	highScoreT[#highScoreT+1] = LoadFont("_wendy small")..{
		Text="No previous score",
		InitCommand=function(self)
			self:zoom(.8):xy(55,-45)
			if rateMode then self:settext("No previous score\nat Rate "..SL.Global.ActiveModifiers.MusicRate) end
		end,
	}
end


local toReturn = Def.ActorFrame{Name="DeltaT"}
toReturn[#toReturn+1] = deltaT
toReturn[#toReturn+1] = highScoreT

return toReturn