# PilotInfo

![PtaszWare Logo](https://github.com/MPtasz/PilotInfo/blob/main/assets/logos/PtasWareLogo190x197.png)

**PtaszWare**

-  by: Mark Ptaszynski
-  Copyright: March, 2026
-  Version: 1.1.0

---

The FAA requires all recreational operators of unmanned aircraft weighing 250 grams (0.55 lbs)
or more to register their unmanned aircraft and pass the TRUST test and provide proof of passage
if asked by law enforcement.

This tool allows the user to enter and store name, address, phone, AMA #
FAA # and TRUST # on the radio so the info can be produced at the field
when needed.

## INSTALLATION

Copy the PilotInfo.lua file to /SCRIPTS/TOOLS/PilotInfo.lua  (on the radio's SD card).
The data file PilotInfo.txt will be in the /SCRIPTS/TOOLS directory.
An empty data file will be created if it does not exist.

## USAGE

Radio Menu → Tools → Pilot Info

![Tools/PilotInfo](https://github.com/MPtasz/PilotInfo/blob/main/assets/screenshots/ToolsPilotInfo.png)

  - the script now opens with a view screen
  
![Tools/PilotInfo](https://github.com/MPtasz/PilotInfo/blob/main/assets/screenshots/PilotInfoDisplay.png)  
  
  - if PilotInfo.txt does not exist the file will be created
    and all fields start empty
  - press EDIT to fill them in and press SAVE to create/save the file
  - all fields are editable at any time on the EDIT acressn
  - tap (or navigate to) any text field and press ENTER to open the EdgeTX virtual keyboard
  
![Tools/PilotInfo](https://github.com/MPtasz/PilotInfo/blob/main/assets/screenshots/PilotInfoEdit.png)     
  
  - press SAVE to write changes to the SD card
  - press the EdgeTX logo (top-left) or CLOSE to exit
  - if there are unsaved changes a prompt will ask to confirm
  
![Tools/PilotInfo](https://github.com/MPtasz/PilotInfo/blob/main/assets/screenshots/PilotInfoSafed.png)   

## PilotInfo.txt FORMAT (one value per line, no header in the file)

**PilotInfo.Txt example**

  - Line 1 - Name
  - Line 2 - Street Address
  - Line 3 - City/State/Zip
  - Line 4 - Phone #
  - Line 5 - AMA #
  - Line 6 - FAA #
  - Line 7 - TRUST #
  
**PilootInfo.Txt Information**  

| Line # | Label          | Length         | Hint           |
| ------ | -------------- | -------------- | -------------- |
| Line 1 | Pilot Name     | (max 30 chars) |                |
| Line 2 | Street Address | (max 50 chars) |                |
| Line 3 | City/State/ZIP | (max 50 chars) |                |
| Line 4 | Phone #        | (max 15 chars) | (xxx) xxx-xxxx |
| Line 5 | AMA #          | (max 10 chars) |                |
| Line 6 | FAA #          | (max 15 chars) |                |
| Line 7 | TRUST #        | (max 20 chars) |                |

### FIELD DEFINITIONS

  each entry describes one pilot data field

  - label  – text shown above the edit box on screen
  - length – the REAL maximum character length for this field (enforced on save)
  - hint   – short format example (stored for documentation - not used at this time
             (purhaps for future use?)

  EdgeTX's lvgl.textEdit requires its 'length' to be between 32 and 128 - 
  several fields have a true max less then 32 (Phone=15, AMA=10, FAA=15, TRUST=20)
  pass max(32, maxlen) to the widget to satisfy the API, then truncate to the real
  maxlen when saving file.

## NOTES

  - LVGL is used (LVGL API + lvgl.textEdit)
  - written with EdgeTX v2.11 or later for LVGL support

  FILE_PATH is the full SD card path for the pilot data file
  keeping it in /SCRIPTS/TOOLS/ (next to the .lua file) is clean and ensures
  the script can always locate its data on any supported radio model
  
  EdgeTX's lvgl.textEdit requires its 'length' to be between 32 and 128
  several fields have a true max less then 32 (Phone=15, AMA=10, FAA=15, TRUST=20)
  pass max(32, maxlen) to the widget to satisfy the API then truncate to the real
  maxlen when saving file
  
## License

 GPLv3: http://www.gnu.org/licenses/gpl-3.0.html

 This program is free software: you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation, either version 3 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 A PARTICULAR PURPOSE. See the GNU General Public License for more details.
