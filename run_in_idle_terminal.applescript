on run argv
	set cmd to item 1 of argv
	tell application "Terminal"
		set didRun to false
		if (count of windows) > 0 then
			repeat with w in windows
				-- some windows (e.g. Settings) have no tabs and make "tabs of w" raise an error
				set wTabs to {}
				try
					set wTabs to tabs of w
				end try
				repeat with t in wTabs
					if busy of t is false then
						do script cmd in t
						set selected tab of w to t
						set index of w to 1
						set didRun to true
						exit repeat
					end if
				end repeat
				if didRun then exit repeat
			end repeat
		end if
		if not didRun then
			do script cmd
		end if
	end tell
end run
