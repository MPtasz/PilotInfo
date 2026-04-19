-- =============================================================================
--  PilotInfo.lua  –  Pilot Info Tool
-- =============================================================================
--
--  ____  _                __        __                
-- |  _ \| |_ __ _ ___ ____\ \      / /__ _ _ __ ___  
-- | |_) | __/ _` / __|_  / \ \ /\ / / _` | '__/ _ \ 
-- |  __/| || (_| \__ \/ /   \ V  V / (_| | | |  __/ 
-- |_|    \__\__,_|___/___|   \_/\_/ \__,_|_|  \___|
--
--
--  PtaszWare
--  by: Mark Ptaszynski
--  Copyright: March, 2026
--  Version: 1.1.0
--
-- =============================================================================
--
-- License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later
-- version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
-- A PARTICULAR PURPOSE. See the GNU General Public License for more details
--
-- =============================================================================
--
--  for EdgeTX v2.11+  |  Tools Menu (One-Time Run Script)
--
--  this tool allows the user to enter and store name, address, phone, AMA #
--  FAA # and TRUST # on the radio so the info can be produced at the field when
--  needed
--
--  INSTALLATION
--    copy this PilotInfo.lua file to /SCRIPTS/TOOLS/PilotInfo.lua  (on the radio's SD card)
--    the data file PilotInfo.txt will be in the /SCRIPTS/TOOLS directory
--    the data file PilotInfo.txt will be created if it does not exist
--
--  USAGE
--    Radio Menu → Tools → Pilot Info
--    - the script now opens with a view screen
--    - if PilotInfo.txt does not exist all fields start empty
--    - press EDIT to fill them in and press SAVE to create the file
--    - all fields are editable at any time on the EDIT acressn
--    - tap (or navigate to) any text field and press ENTER to open the EdgeTX virtual keyboard
--    - press SAVE to write changes to the SD card
--    - press the EdgeTX logo (top-left) or CLOSE to exit
--    - if there are unsaved changes a prompt will ask to confirm
--
--  PilotInfo.txt FORMAT (one value per line, no header)
--    Line 1  – Pilot Name      (max 30 chars)
--    Line 2  – Street Address  (max 50 chars)
--    Line 3  – City/State/ZIP  (max 50 chars)
--    Line 4  – Phone           (max 15 chars,  e.g. (xxx) xxx-xxxx)
--    Line 5  – AMA #           (max 10 chars)
--    Line 6  – FAA #           (max 15 chars)
--    Line 7  – TRUST #         (max 20 chars)
--
--  NOTES
--    - LVGL is used (LVGL API + lvgl.textEdit)
--    - written with EdgeTX v2.11 or later for LVGL support
--
--    FILE_PATH is the full SD card path for the pilot data file
--    keeping it in /SCRIPTS/TOOLS/ (next to the .lua file) is clean and ensures
--    the script can always locate its data on any supported radio model
--
--  FIELD DEFINITIONS
--    each entry describes one pilot data field
--
--    label  – text shown above the edit box on screen
--    maxlen – the REAL maximum character length for this field (enforced on save)
--    hint   – short format example (stored for documentation - not used at this time
--             (purhaps for future use?)
--
--  EdgeTX's lvgl.textEdit requires its 'length' to be between 32 and 128
--  several fields have a true max less then 32 (Phone=15, AMA=10, FAA=15, TRUST=20)
--  pass max(32, maxlen) to the widget to satisfy the API then truncate to the real
--  maxlen when saving file
-- =============================================================================

local FILE_PATH = "/SCRIPTS/TOOLS/PilotInfo.txt"

local FIELDS = {
  { label = "Pilot Name",         maxlen = 30,  hint = "First & Last Name"   },
  { label = "Street Address",     maxlen = 50,  hint = "Street / PO Box"     },
  { label = "City / State / ZIP", maxlen = 50,  hint = "City, ST  XXXXX"     },
  { label = "Phone",              maxlen = 15,  hint = "(xxx) xxx-xxxx"       },
  { label = "AMA #",              maxlen = 10,  hint = "AMA Member Number"    },
  { label = "FAA #",              maxlen = 15,  hint = "FAA Registration #"   },
  { label = "TRUST #",            maxlen = 20,  hint = "TRUST Certificate #"  },
}

--  save the field count so we don't have to call '#' inside loops

local NUM_FIELDS = #FIELDS

--  pre fill the seven fields with empty strings
--  populated by readFile() at startup
--  updated by each textEdit 'set' callback

local values = {}
for i = 1, NUM_FIELDS do
  values[i] = ""
end

--  if 'dirty = true' the user has edited at least one field since the last save (or launch)
--  used by onBack() to decide whether to show the "Exit without saving?" dialog

local dirty = false

--  if 'exitApp = true' the script should close on the next run() call
--  set by doExit() - checked in run()
--  only run() can return the exit code to EdgeTX

local exitApp = false

-- =============================================================================
--  FUNCTION readLine(f)
--
--  reads and returns one text line from an open EdgeTX file handle
--  EdgeTX's io.read() only accepts a BYTE COUNT as its second argument
--  read one byte at a time with io.read(f, 1) and concatenate
--  the characters until it finds a newline (\n) or reaches end-of-file
--
--  'f' is an open readable EdgeTX file handle (returned by io.open)
--
--  RETURN VALUE
--    string – the next line of text, with the trailing newline stripped
--             returns an empty string "" if the line itself was blank
--    nil    – 'end-of-file' was reached with no characters available
-- =============================================================================

local function readLine(f)

  local line = ""   -- accumulate characters here

  while true do

    --  io.read(f, 1) reads exactly 1 byte from the file
    --  returns nil (or an empty string depending on EdgeTX build) at end-of-file
	
    local ch = io.read(f, 1)

    --  if 'ch' is nil or an empty string then we have hit end-of-file
	
    if ch == nil or ch == "" then
	
      --  if characters are accumulated before EOF they are returned as a line
      --  (handles files that don't end with a trailing newline)
      --  if line is still empty there truly is nothing left
      --  return nil to signal EOF to the caller
	  
      if line ~= "" then
        return line
      else
        return nil
      end
    end

    --  if the current byte is a newline then the line is complete – return it
    --  do NOT include the '\n' in the returned string
	
    if ch == "\n" then
      return line
    end

    --  if the byte is a carriage return (\r) skip it
    --  PilotInfo.txt is always written with Unix-style '\n' line endings
    --  if the file is ever edited on a Windows machine it may gain '\r\n' endings
    --  ignoring '\r' here makes reading to both line-ending styles
	
    if ch ~= "\r" then
      line = line .. ch   --  append the character to the accumulating line
    end

  end   --  loop back to read the next byte

end   -- end of readLine()

-- =============================================================================
--  FUNCTION - readFile()
--
--  opens PilotInfo.txt and loads each line into values[] so the UI shows
--  any previously saved pilot data when the script starts
--
--  EdgeTX Lua scripts do not retain any state between sessions
--  every launch resets all variables
--  reading the file at startup is the only way to restore data the user entered
--  in a previous session
--
--  RETURN VALUES
--    true  – file was found and read successfully
--    false – file does not exist (first run) or could not be opened
-- =============================================================================

local function readFile()

  --  io.open(path, "r") opens the file for reading
  --  returns nil if the file does not exist this is not an error just 'not yet created'
  
  local f = io.open(FILE_PATH, "r")

  --  if 'f' is nil the file could not be opened (most likely it doesn't exist yet)
  --  leave values[] full of empty strings so the UI shows blank editable fields
  --  return false to let the caller knows no data was loaded
  
  if not f then
    return false
  end

  --  read one line per field using readLine()
  --  if readLine() returns nil (file shorter than expected) store "" (empty string)
  
  for i = 1, NUM_FIELDS do
    local line = readLine(f)
    values[i] = line or ""
  end

  --  always close the file when finished
  --  EdgeTX has a small fixed limit on simultaneous open files
  --  leaving files open can block other file operations elsewhere
  --  NOTE - must use io.close(f) – NOT f:close() – for EdgeTX userdata files
  
  io.close(f)

  return true
end


-- =============================================================================
--  FUNCTION - writeFile()
--
--  writes the current contents of values[] to PilotInfo.txt one field per line
--  creates the file if it does not exist - overwrites it completely if it does
--  (no backups are kept)
--
--  RETURN VALUES
--    true  – all fields written successfully
--    false – file could not be opened for writing
-- =============================================================================

local function writeFile()

  --  io.open(path, "w") creates the file if absent or truncates and rewrites
  --  it if present - overwriting is safe because all seven lines are written
  --  returns nil if the SD card is missing,write-protected or full
  
  local f = io.open(FILE_PATH, "w")

  --  if 'f' is nil the file could not be opened for writing
  --  return false so the caller (doSave) can display an error message rather
  --  than silently losing the user's data
  
  if not f then
    return false
  end

  --  write each field value as a single line
  
  for i = 1, NUM_FIELDS do

    --  'values[i] or ""' guards against a nil slot
	
    local v = values[i] or ""

    --  if the string exceeds the field's true maximum length, truncate it
    --	this can happen because lvgl.textEdit was given length=32 for short fields
    --  (the API minimum) allowing the user to type more than the spec
    --  allows- update values[i] so the on-screen widget reflects the
    --  truncated text after saving
	
    if #v > FIELDS[i].maxlen then
      v = string.sub(v, 1, FIELDS[i].maxlen)
      values[i] = v
    end

    --  write the value followed by a newline
    --  NOTE - must use io.write(f, str) – NOT f:write(str) – for EdgeTX files
	
    io.write(f, v .. "\n")
  end

  --  release the file handle to flush the write buffer
  --  NOTE - must use io.close(f) – NOT f:close() – for EdgeTX userdata files
  
  io.close(f)

  --  clear the dirty flag - the file on disk now matches in-memory values[]
  
  dirty = false

  return true
end

-- =============================================================================
--  FUNCTION - doExit()
--
--  sets the exitApp flag so run() returns 2 on its next call, which tells
--  EdgeTX to close the script and return to the Tools menu
--
--  only run() can legally return an exit code to EdgeTX
-- =============================================================================

local function doExit()
  exitApp = true
end

-- =============================================================================
--  FUNCTION - doSave()
--
--  called by the SAVE button - writes all field values to file and shows a
--  pop-up confirming success or reporting failure
-- =============================================================================
local function doSave()

  --  Attempt the write
  --  if writeFile() returns true the save succeeded
  
  if writeFile() then
    lvgl.message({
      title   = "Saved Successfully",
      message = "Pilot info saved to PilotInfo.txt.\n\n" ..
                "Press RETURN or ENTER then press\n" ..
                "CLOSE or the EdgeTX logo in the upper left\n" ..
                "corner to return to the Tools menu.",
    })

  -- ELSE the write failed – tell the user and give them a hint
  
  else
    lvgl.message({
      title   = "Write Error",
      message = "Could not write PilotInfo.txt.\nCheck SD card.",
    })
  end

end


-- =============================================================================
--  FUNCTION - onBack()
--
--  called by the page back-arrow, the RTN hardware key, and the CLOSE button
--  exits immediately if there are no unsaved changes - otherwise prompts first
--
--  prevents the user from accidentally losing typed data when pressing RTN or
--  CLOSE - only sessions with actual unsaved edits (dirty == true) trigger the
--  confirmation dialog - clean sessions exit instantly with no extra prompt
-- =============================================================================

local function onBack()

  --  if dirty is true, at least one field was edited since the last save
  --  show a "Yes / No" confirmation dialog before discarding those changes
  
  if dirty then
    lvgl.confirm({
      title   = "Unsaved Changes",
      message = "Exit without saving?",
      confirm = doExit,   --  doExit() is called only if the user taps "Yes"
                          --  tapping "No" or dismissing with RTN does nothing – the script stays open
    })

  --  ELSE no unsaved changes – safe to exit immediately without a dialog
  
  else
    doExit()
  end

end


-- =============================================================================
--  FUNCTION - buildUI()
--
--  creates the entire LVGL user interface
--  - the page frame
--  - a label + textEdit widget pair for each of the seven fields
--    and the SAVE / CLOSE buttons
--
--  all widget positions, sizes, and callbacks are specified here keeping UI
--  construction in one function separates it cleanly from file I/O and business logic
--
--  called once from init(), after readFile() has populated values[]
-- =============================================================================

local function buildUI()

  --  remove any existing LVGL widgets before building new ones
  --  prevents screen writes from clutering the display
  
  lvgl.clear()

  -- ============================================================================
  --  screen scaling
  --  lvgl.LCD_SCALE equals 1.0 on the 480×272 reference resolution (TX16S, etc.)
  --  and scales proportionally on other resolutions - all pixel dimensions are
  --  multiplied so the layout looks correct on every supported display size
  --  if lvgl.LCD_SCALE is nil (non-standard build) default to 1 so the layout
  --  still produces correct values for the 480×272 reference resolution
  
  local S = (lvgl ~= nil and lvgl.LCD_SCALE ~= nil) and lvgl.LCD_SCALE or 1

  -- ===========================================================================
  --  layout constants
  --  math.floor() converts scaled float values to whole pixel integers
  
  local PAD   = math.floor(6  * S)   --  margin from screen edge to widget content
  local LBL_H = math.floor(20 * S)   --  height of the field name label row
  local EDT_H = math.floor(30 * S)   --  height of the textEdit box (includes LVGL's
                                     --  2px focus ring drawn around active controls)
  local GAP   = math.floor(4  * S)   --  gap between label and its text box below it

  --  ROW_H is the total pixel height of one field row (label + gap + box + margin)
  --  mMultiplying by (index - 1) gives each row's Y position, stacking them downward
  
  local ROW_H   = LBL_H + EDT_H + GAP + math.floor(8 * S)

  --  EDIT_W is the text box width – near-full-screen on 480px wide displays leaving
  --  PAD margin on each side to match standard EdgeTX UI styling
  
  local EDIT_W  = math.floor(452 * S)

  local BTN_W   = math.floor(120 * S)   --  width of each buttons
  local BTN_GAP = math.floor(16  * S)   --  gap between the SAVE and CLOSE buttons

  -- ============================================================================
  --  page container
  --  lvgl.page() creates the standard EdgeTX full-screen container with a
  --  header bar (back-arrow, title, subtitle) and a scrollable body below it
  --  the page adds a scroll bar automatically when children overflow the body
  --  essential because seven field rows plus buttons exceed ~220px body height
  --  'back = onBack' wires BOTH the header back-arrow AND the hardware RTN key
  --  to the onBack() function ensuring the unsaved-changes check is always applied
  
  local pg = lvgl.page({
    title    = "Pilot Info Card",
    subtitle = "Tap a field to edit  \xE2\x80\x93  SAVE when done",
    back     = onBack,
  })
  
  -- \xE2\x80\x93 is the UTF-8 byte sequence for the en-dash (–) separator

  -- =============================================================================
  --  field rows
  --  ipairs() iterates the FIELDS array in order, giving index 'i' and field
  --  definition table 'fld' on each pass
  
  for i, fld in ipairs(FIELDS) do

    local idx   = i
    local row_y = (idx - 1) * ROW_H + PAD   --  Y position of this field row's top

    --  field name label (e.g. "Pilot Name")
    --  COLOR_THEME_SECONDARY1 automatically matches the user's EdgeTX color theme
	
    pg:label({
      x     = PAD,
      y     = row_y,
      color = COLOR_THEME_SECONDARY1,
      text  = fld.label,
    })

    --  editable text box – opens the EdgeTX virtual keyboard when activated
    --  'value' seeds the widget with the current stored text so existing data
    --  appears pre-filled - without it the boxes would always start blank
    --  'length' = max(32, min(128, maxlen)) satisfies the EdgeTX API constraint
    --  that length must be between 32 and 128
	--  short fields (Phone/AMA/etc.) get rounded up to 32
	--  the true maxlen is enforced at save time
    --  'set' callback is called by EdgeTX when the user confirms a keyboard edit
    --  'v' is the full new string the user typed
	
    pg:textEdit({
      x      = PAD,
      y      = row_y + LBL_H + GAP,
      w      = EDIT_W,
      value  = values[idx],
      length = math.max(32, math.min(128, fld.maxlen)),
      set    = function(v)
        values[idx] = v 
        dirty = true
      end,
    })

  end 

  -- =============================================================================
  --  buttons
  --  positioned below the last field row - still inside the scrollable page body
  
  local btn_y = NUM_FIELDS * ROW_H + math.floor(14 * S)

  --  SAVE button – writes values[] to file - shows success/failure message
  
  pg:button({
    x     = PAD,
    y     = btn_y,
    w     = BTN_W,
    text  = "SAVE",
    press = doSave,
  })

  --  CLOSE button – calls onBack() (not doExit() directly) so the unsaved-changes
  --  check applies whether the user closes via this button or RTN
  
  pg:button({
    x     = PAD + BTN_W + BTN_GAP,
    y     = btn_y,
    w     = BTN_W,
    text  = "CLOSE",
    press = onBack,
  })

end

-- =============================================================================
--  Forward declaration — allows buildViewUI and buildMenuUI to reference
--  each other since they are mutually recursive (each can navigate to the other)
-- =============================================================================

local buildMenuUI

-- =============================================================================
--  FUNCTION - buildViewUI()
--
--  read-only summary screen — all seven fields on one page, no editing
--  CLOSE exits the script; EDIT switches to the full edit page
-- =============================================================================

local function buildViewUI()

  lvgl.clear()

  local S       = (lvgl ~= nil and lvgl.LCD_SCALE ~= nil) and lvgl.LCD_SCALE or 1
  local PAD     = math.floor(6   * S)
  local ROW_V   = math.floor(24  * S)
  local NAME_W  = math.floor(220 * S)
  local COLON_X = math.floor(228 * S)
  local VALUE_X = math.floor(240 * S)

  local pg = lvgl.page({
    title    = "Pilot Info Card",
    subtitle = "Pilot Identification",
    back     = buildMenuUI,
  })

  for i, fld in ipairs(FIELDS) do
    local y = (i - 1) * ROW_V + PAD

    pg:label({
      x     = PAD,
      y     = y,
      w     = NAME_W,
      color = COLOR_THEME_SECONDARY1,
      text  = fld.label,
    })

    pg:label({
      x     = COLON_X,
      y     = y,
      color = COLOR_THEME_SECONDARY1,
      text  = ":",
    })

    pg:label({
      x     = VALUE_X,
      y     = y,
      color = BLACK,
      bold  = true,
      text  = values[i] ~= "" and values[i] or "--",
    })

  end

  local BTN_W = math.floor(120 * S)
  local BTN_G = math.floor(16  * S)
  local btn_y = NUM_FIELDS * ROW_V + math.floor(14 * S)

  pg:button({
    x     = PAD,
    y     = btn_y,
    w     = BTN_W,
    text  = "CLOSE",
    press = doExit,
  })

  pg:button({
    x     = PAD + BTN_W + BTN_G,
    y     = btn_y,
    w     = BTN_W,
    text  = "EDIT",
    press = buildUI,
  })

end
-- =============================================================================
--  FUNCTION - buildMenuUI()
--
--  opening screen shown on launch — two large buttons side by side
--  (this has been superseded - script now opens with the read only summary page)
--  EDIT  → proceeds to the full edit page
--  VIEW  → shows the read-only summary page
-- =============================================================================

buildMenuUI = function()           --  assignment form (not 'local function') so that
                                   --  the forward-declared local slot above is filled
  lvgl.clear()

  local S     = (lvgl ~= nil and lvgl.LCD_SCALE ~= nil) and lvgl.LCD_SCALE or 1
  local BTN_W = math.floor(160 * S)
  local BTN_H = math.floor(50  * S)
  local BTN_G = math.floor(20  * S)
  local cx    = math.floor(240 * S)   --  horizontal centre of the 480-px screen
  local top   = math.floor(70  * S)   --  Y position of both buttons

  local pg = lvgl.page({
    title    = "Pilot Info Card",
    subtitle = "Choose an option",
    back     = onBack,               --  RTN from menu exits (with dirty-check)
  })

  pg:button({
    x     = cx - BTN_W - math.floor(BTN_G / 2),
    y     = top,
    w     = BTN_W,
    h     = BTN_H,
    text  = "EDIT",
    press = buildUI,
  })

  pg:button({
    x     = cx + math.floor(BTN_G / 2),
    y     = top,
    w     = BTN_W,
    h     = BTN_H,
    text  = "VIEW",
    press = buildViewUI,
  })

end

-- =============================================================================
--  FUNCTION - init()
--
--  EdgeTX startup entry point – called exactly ONCE when the script loads
--  loads saved pilot data from the SD card and builds the LVGL UI
--  ============================================================================

local function init()

  --  if lvgl is nil the firmware predates EdgeTX 2.11 or LVGL support is absent
  --  Exit immediately so the lvgl.* calls in buildUI() don't crash the script
  --  the run() function handles this case with a plain lcd.* error display
  
  if lvgl == nil then return end

  readFile()

  -- buildUI()
  
  -- buildMenuUI()   
  -- menu not used - script goes right to view screen when run
  -- left the function intact so it could be activated at any time if so desired
  
  buildViewUI()

end


-- =============================================================================
--  FUNCTION - run(event, touchState)
--
--  EdgeTX per-frame entry point – called every display refresh (~20-30 fps)
--  renders a fallback error screen when LVGL is unavailable, and signals
--  EdgeTX to close the script when exitApp has been set
--
--  PARAMETERS
--    event – integer key event code (e.g. EVT_VIRTUAL_EXIT for RTN key)
--            or 0 if no key was pressed this frame
--    touchState – touch position/gesture table on touch radios - otherwise nil
--                 LVGL handles all touch events internally
--  RETURN VALUES
--    0  – keep the script running - EdgeTX calls run() again next frame
--    2  – close the script - EdgeTX returns to the Tools menu
-- =============================================================================

local function run(event, touchState)

  -- ============================================================================
  --  Fallback - LVGL not available
  --  if lvgl is nil draw a plain diagnostic screen using the legacy lcd.* API
  --  lcd.* requires the screen to be redrawn on every run() call (unlike LVGL
  --  which persists widgets automatically), this block runs every frame
  
  if lvgl == nil then
    lcd.clear()
    lcd.drawText(10, 20,  "Pilot Info Card",               MIDSIZE + INVERS)
    lcd.drawText(10,  50, "Requires EdgeTX v2.11+",        0)
    lcd.drawText(10,  68, "LVGL support not available.",   0)
    lcd.drawText(10,  86, "Please upgrade your firmware.", 0)
    lcd.drawText(10, 110, "Press EXIT to close.",          0)

    --  if the EXIT/RTN key was pressed, close the script

    if event == EVT_VIRTUAL_EXIT then return 2 end

    return 0   --  keep running so the error message stays visible
  end

  -- =============================================================================
  --  normal path - LVGL active
  --  if exitApp is set to true by doExit() (via the CLOSE button or confirmed
  --  "Exit without saving?" dialog), return 2 to close the script
  --  this then fires on the very next run() cycle after doExit() is called
  
  if exitApp then return 2 end

  --  no exit requested – return 0 to keep the script alive
  --  LVGL handles all drawing and input processing for the page automatically
  
  return 0

end 


-- =============================================================================
--  SCRIPT RETURN TABLE
--
--  EdgeTX discovers and invokes script functions through the return table
--  'init' and 'run' are required for every One-Time (Tools menu) script
--  'useLvgl = true' activates the LVGL widget API (introduced in EdgeTX 2.11)
--  without it the 'lvgl' global is nil and lvgl.textEdit / lvgl.page are
--  unavailable - on firmware older than 2.11 this key is silently ignored,
--  which is why every lvgl.* usage in this script is guarded with a nil check
-- =============================================================================

return { init = init, run = run, useLvgl = true }
