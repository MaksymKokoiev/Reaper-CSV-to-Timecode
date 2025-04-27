# REAPER Script: CSV to Timecode
Lua Reaper Script for aligning items based on the timecode in a CSV


This is a Lua script for \[REAPER\](https://www.reaper.fm/) that allows users to import timecodes from a CSV file to perform two main actions:

1\.  \*\*Align Selected Items:\*\* Sequentially align selected media items on tracks to timecodes specified in a CSV file. The script matches items to timecodes based on the track name.  
2\.  \*\*Generate Tracks:\*\* Create new tracks in the REAPER project based on the unique track names found in a specified column of the CSV file.

\#\# Author

\* \*\*Name:\*\* Maksym Kokoiev  
\* \*\*Website:\*\* \<https://maxkokomusic.com/\>

\#\# Requirements

\* \*\*REAPER:\*\* Version 6.32 or later.  
\* \*\*ReaImGui Extension:\*\* This script uses the ReaImGui library to create the user interface. You need to install it first.  
    \* \*\*Recommended Installation:\*\* Use \[ReaPack\](https://reapack.com/) to install ReaImGui.  
        1\.  Install ReaPack if you haven't already.  
        2\.  In REAPER, go to \`Extensions\` \> \`ReaPack\` \> \`Browse packages...\`.  
        3\.  Search for \`ReaImGui\` and install it.  
        4\.  Restart REAPER.

\#\# Installation

1\.  Install the required \*\*ReaImGui\*\* extension (see above).  
2\.  Download the \`CSV to timecode.lua\` script file from this repository.  
3\.  Open REAPER.  
4\.  Go to \`Actions\` \> \`Show action list...\`.  
5\.  Click \`New Action...\` \> \`Load ReaScript...\`.  
6\.  Browse to and select the downloaded \`CSV to timecode.lua\` file.  
7\.  The script is now available in your Action List. You can assign a keyboard shortcut or add it to a toolbar for easy access.

\#\# Usage

1\.  \*\*Prepare your CSV file:\*\*  
    \* The CSV file should contain columns for track names and timecodes.  
    \* By default, the script expects the \*\*Track Name\*\* in \*\*Column 2\*\* and the \*\*Timecode\*\* in \*\*Column 3\*\* (1-based indexing). You can change these defaults in the script's UI.  
    \* Timecodes should be in \`HH:MM:SS.sss\` or \`HH:MM:SS,sss\` format. The script can handle different decimal separators and number of decimal places (configurable in the UI).  
    \* The first row is assumed to be a header and will be skipped.  
    \* Example CSV:  
        \`\`\`csv  
        ID,Track Name,Timecode,Description  
        1,Dialogue,"00:01:15.250",Start of scene 1  
        2,Music,"00:01:18.500",Music cue in  
        3,Dialogue,"00:01:25.000",End of scene 1  
        4,SFX,"00:01:26.100",Door slam  
        \`\`\`

2\.  \*\*Run the script:\*\* Launch the "CSV to timecode" script from the REAPER Action List.

3\.  \*\*Configure Settings in the UI:\*\*  
    \* \*\*Browse CSV:\*\* Select your prepared CSV file.  
    \* \*\*Timecode Col / Track Name Col:\*\* Adjust if your CSV uses different columns (1-based index).  
    \* \*\*Seconds Decimals:\*\* Set the number of decimal places (0-3) expected in your timecode's seconds field.  
    \* \*\*Decimal Separator:\*\* Choose \`.\` or \`,\` to match your CSV.  
    \* \*\*Hour Offset:\*\* Apply an hour offset if your CSV timecodes need adjustment relative to the REAPER timeline (e.g., for different timecode standards).

4\.  \*\*Perform Actions:\*\*  
    \* \*\*Process CSV & Align Selected Items:\*\*  
        \* Select the media items in your REAPER project that you want to align. Items must be on tracks whose names \*exactly match\* the names in your CSV's Track Name column.  
        \* Click this button. The script will load the CSV, find the corresponding timecodes for each track, sort the selected items on each track by their current position, and align them sequentially to the sorted timecodes from the CSV.  
    \* \*\*Generate Tracks from CSV:\*\*  
        \* Click this button to create new tracks in REAPER for each unique track name found in the CSV's Track Name column. The tracks will be created in the order they first appear in the CSV.

5\.  \*\*Log Window:\*\* Check the log window at the bottom of the script UI for status messages, errors, or warnings during processing.

\#\# License

This project is licensed under the Apache License, Version 2.0. See the \[LICENSE\](LICENSE) file for details.

Copyright 2025 Maksym Kokoiev

Licensed under the Apache License, Version 2.0 (the "License");  
you may not use this file except in compliance with the License.  
You may obtain a copy of the License at  
\[http://www.apache.org/licenses/LICENSE-2.0\](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software  
distributed under
