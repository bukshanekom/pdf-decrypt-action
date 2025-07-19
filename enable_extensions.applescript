global debugLog
set debugLog to ""

on logDebug(message)
	global debugLog
	set currentTime to (current date) as string
	set debugLog to debugLog & currentTime & ": " & message & return
end logDebug

on exploreElement(element, depth, elementPath)
	try
		set indent to ""
		repeat with i from 1 to depth
			set indent to indent & "  "
		end repeat
		
		set elementInfo to ""
		try
			set elementInfo to elementInfo & "[" & (class of element as string) & "] "
		end try
		
		try
			set elementName to name of element
			if elementName is not missing value and elementName is not "" then
				set elementInfo to elementInfo & "name:" & elementName & " "
			end if
		end try
		
		try
			set elementDesc to description of element
			if elementDesc is not missing value and elementDesc is not "" then
				set elementInfo to elementInfo & "desc:" & elementDesc & " "
			end if
		end try
		
		my logDebug(indent & elementPath & " " & elementInfo)
		
		-- Check if this is our target
		if elementInfo contains "PDF Decrypt Action" then
			my logDebug(indent & "*** FOUND PDF DECRYPT ACTION! ***")
			if (class of element) is checkbox then
				try
					set checkValue to value of element
					if checkValue is 0 or checkValue is false then
						my logDebug(indent & "Enabling checkbox...")
						click element
						display notification "PDF Decrypt Action enabled!" with title "Success"
						return "SUCCESS"
					else
						display notification "Already enabled" with title "PDF Decrypt Action"
						return "ALREADY_ENABLED"
					end if
				end try
			end if
		end if
		
		-- Look for Extensions buttons
		if elementInfo contains "Extensions" and elementInfo contains "[button]" then
			my logDebug(indent & "*** CLICKING EXTENSIONS BUTTON ***")
			try
				click element
				delay 3
				return "CLICKED_BUTTON"
			end try
		end if
		
		-- Explore children if not too deep
		if depth < 8 then
			try
				set childElements to every UI element of element
				repeat with i from 1 to count of childElements
					try
						set result to my exploreElement(item i of childElements, depth + 1, elementPath & "/" & i)
						if result is "SUCCESS" or result is "ALREADY_ENABLED" or result is "CLICKED_BUTTON" then
							return result
						end if
					end try
				end repeat
			end try
		end if
		
		return "CONTINUE"
		
	on error
		return "ERROR"
	end try
end exploreElement

try
	my logDebug("=== UI Exploration Started ===")
	
	tell application "System Settings"
		activate
	end tell
	delay 5
	
	try
		tell application "System Settings"
			reveal pane id "com.apple.LoginItems-Settings.extension"
		end tell
		delay 5
	on error
		my logDebug("Could not reveal pane")
	end try
	
	tell application "System Events"
		tell process "System Settings"
			set windowCount to count of windows
			my logDebug("Windows found: " & windowCount)
			
			if windowCount > 0 then
				set mainWindow to window 1
				my logDebug("Window name: " & name of mainWindow)
				
				-- First exploration
				set result1 to my exploreElement(mainWindow, 0, "window")
				my logDebug("First exploration result: " & result1)
				
				if result1 is "CLICKED_BUTTON" then
					delay 5
					-- Second exploration after clicking
					set result2 to my exploreElement(mainWindow, 0, "window")
					my logDebug("Second exploration result: " & result2)
					
					if result2 is not "SUCCESS" and result2 is not "ALREADY_ENABLED" then
						display dialog "Opened Extensions but could not find PDF Decrypt Action. Please enable it manually." buttons {"OK"}
					end if
				else if result1 is not "SUCCESS" and result1 is not "ALREADY_ENABLED" then
					display dialog "Could not find PDF Decrypt Action or Extensions button. Please check manually." buttons {"OK"}
				end if
			end if
		end tell
	end tell
	
on error mainErr
	my logDebug("Main error: " & mainErr)
	display dialog "Error: " & mainErr buttons {"OK"}
end try

-- Write log
try
	set logFile to (path to home folder as string) & "Library:Logs:applescript-debug.log"
	set fileRef to open for access file logFile with write permission
	set eof of fileRef to 0
	write debugLog to fileRef
	close access fileRef
	do shell script "open -a TextEdit " & quoted form of POSIX path of logFile
end try