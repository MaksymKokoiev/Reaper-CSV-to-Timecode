--[[
Copyright 2025 Maksym Kokoiev

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

-- CSV To Timecode with ReaImGui UI (User-Friendly Timecode Format)
-- Author: Maksym Kokoiev
-- Website: https://maxkokomusic.com/
-- Version: 1.4-Maksym (Based on original user-provided v1.4 logic)
-- Requires REAPER 6.32+ with ReaImGui installed and enabled.
--
-- This script loads timecodes from a CSV file, aligns selected items on matching tracks,
-- and (with the new button) generates new tracks based on the CSV Track Column.
-------------------------------------------------

-- GLOBAL OPTIONS
-------------------------------------------------
local input_tc_column = "3"               -- CSV column index for timecode (as string)
local input_tn_column = "2"               -- CSV column index for track name (as string)
local time_decimals = 3                   -- Number of decimal places for seconds (0 to 3)
local decimal_separator = "."             -- Decimal separator; can be "." or ","

local hour_offset_value = 0               -- Hour offset value in hours
local knob_min = -12
local knob_max = 12

local file_path = ""
local debug_log = ""
local mapping = nil                     -- Mapping of track names to a table of timecodes
local trackOrder = {}                   -- Order of unique track names encountered in the CSV
local last_folder = reaper.GetResourcePath() .. "/"
local frame_rate = reaper.SNM_GetIntConfigVar("replayrate", 24)

-------------------------------------------------
-- UTILITY: Build Timecode Format String
-------------------------------------------------
local function get_tc_format()
  local width = 2 + time_decimals  -- for seconds, minimum width
  local fmt = string.format("%%02d:%%02d:%%0%d.%df", width, time_decimals)
  return fmt
end

-------------------------------------------------
-- TIME CODE FUNCTIONS
-------------------------------------------------
local function format_timecode(seconds)
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  local fmt = get_tc_format()
  local tc = string.format(fmt, h, m, s)
  if decimal_separator == "," then
    tc = tc:gsub("%.", ",")
  end
  return tc
end

local function parse_timecode(timecode)
  timecode = timecode:gsub(",", ".")
  local h, m, s = timecode:match("(%d+):(%d+):([%d%.]+)")
  if h and m and s then
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
  end
  return nil
end

-------------------------------------------------
-- CSV LOADING FUNCTION (with Track Order)
-------------------------------------------------
local function load_timecodes_from_csv(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil, "Failed to open file: " .. filepath
  end

  debug_log = "Debug Log: Parsed Timecodes with Track Names\n-------------------------------------------\n"
  mapping = {}
  trackOrder = {}  -- Reset the order table
  local first_line = true

  local tc_index = tonumber(input_tc_column) or 3
  local tn_index = tonumber(input_tn_column) or 2
  local offset_seconds = hour_offset_value * 3600

  for line in file:lines() do
    if first_line then
      first_line = false -- Skip header
    else
      local fields = {}
      for value in line:gmatch("([^,]+)") do
        table.insert(fields, value)
      end

      if fields[tc_index] then
        local trackName = fields[tn_index] and fields[tn_index]:gsub('"', '') or "Unnamed Track"
        local timecode_field = fields[tc_index]:gsub('"', '')
        if (not timecode_field:find("[.,]")) and fields[tc_index+1] and fields[tc_index+1]:match("%d+") then
          timecode_field = timecode_field .. "," .. fields[tc_index+1]
        end

        local seconds = parse_timecode(timecode_field)
        if seconds then
          seconds = seconds - offset_seconds
          if not mapping[trackName] then 
            mapping[trackName] = {}
            table.insert(trackOrder, trackName)  -- Record the new track name in the order encountered
          end
          table.insert(mapping[trackName], seconds)
          debug_log = debug_log .. "Track: " .. trackName .. " | " .. format_timecode(seconds) .. "\n"
        else
          debug_log = debug_log .. "ERROR: Could not convert timecode for track " .. trackName .. " -> " .. timecode_field .. "\n"
        end
      else
        debug_log = debug_log .. "SKIPPED: Invalid row -> " .. line .. "\n"
      end
    end
  end

  file:close()
  if next(mapping) == nil then
    return nil, debug_log .. "\nNo valid timecodes found!"
  end

  return mapping, debug_log, trackOrder
end

-------------------------------------------------
-- GENERATE NEW TRACKS FUNCTION
-------------------------------------------------
local function generate_tracks(order)
  local trackCount = reaper.CountTracks(0)
  reaper.Undo_BeginBlock()
  for i, trackName in ipairs(order) do
    reaper.InsertTrackAtIndex(trackCount + i - 1, true)
    local newTrack = reaper.GetTrack(0, trackCount + i - 1)
    reaper.GetSetMediaTrackInfo_String(newTrack, "P_NAME", trackName, true)
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Generate Tracks from CSV Track Column", -1)
  debug_log = debug_log .. "\nGenerated " .. #order .. " new track(s)."
end

-------------------------------------------------
-- ALIGN SELECTED ITEMS FUNCTION
-------------------------------------------------
local function align_selected_items(mapping)
  local item_count = reaper.CountSelectedMediaItems(0)
  if item_count == 0 then
    reaper.ShowMessageBox("No items selected!", "Error", 0)
    return
  end

  local trackItems = {}
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local track = reaper.GetMediaItem_Track(item)
      local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
      if track_name and mapping[track_name] then
        if not trackItems[track_name] then trackItems[track_name] = {} end
        table.insert(trackItems[track_name], item)
      end
    end
  end

  reaper.Undo_BeginBlock()
  for track_name, items in pairs(trackItems) do
    local timecodes = mapping[track_name]
    if timecodes then
      table.sort(items, function(a, b)
        return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
      end)
      local align_count = math.min(#items, #timecodes)
      for i = 1, align_count do
        local time_in_seconds = timecodes[i]
        local frames = time_in_seconds * frame_rate
        local aligned_position = frames / frame_rate
        reaper.SetMediaItemInfo_Value(items[i], "D_POSITION", aligned_position)
      end
    end
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Align Items Sequentially on Specified Tracks to CSV Timecodes", -1)
end

-------------------------------------------------
-- ImGui UI IMPLEMENTATION
-------------------------------------------------
local ctx = reaper.ImGui_CreateContext("CSV to Timecode")
if not ctx then
  reaper.ShowMessageBox("ReaImGui context is nil. Please install and enable ReaImGui.", "Error", 0)
  return
end
if reaper.ImGui_StyleColorsDark then
  reaper.ImGui_StyleColorsDark(ctx)
end

-- Remove title bar entirely using flags NoTitleBar and NoCollapse.
local window_flags = 3

local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 500, 400, 1)
  local visible, open = reaper.ImGui_Begin(ctx, "CSV to Timecode", true, window_flags)
  if visible then
    reaper.ImGui_Text(ctx, "Project Frame Rate: " .. tostring(frame_rate))
    reaper.ImGui_Text(ctx, "CSV File: " .. (file_path == "" and "None" or file_path))
    reaper.ImGui_Separator(ctx)

    -- Input for CSV columns
    local changed1, new_tc_col = reaper.ImGui_InputText(ctx, "TC Col", input_tc_column, 10)
    if changed1 then input_tc_column = new_tc_col end

    local changed2, new_tn_col = reaper.ImGui_InputText(ctx, "Track Col", input_tn_column, 10)
    if changed2 then input_tn_column = new_tn_col end

    reaper.ImGui_Separator(ctx)

    -- Timecode format controls:
    local changed_dec, new_decimals = reaper.ImGui_SliderInt(ctx, "Seconds Decimals", time_decimals, 0, 3)
    if changed_dec then time_decimals = new_decimals end

    local combo_str = ".\0,\0"
    local current_index = (decimal_separator == ",") and 1 or 0
    local changed_sep, selected_index = reaper.ImGui_Combo(ctx, "Decimal Separator", current_index, combo_str, 2)
    if changed_sep then
      decimal_separator = (selected_index == 0) and "." or ","
    end

    reaper.ImGui_Separator(ctx)

    -- Hour offset slider
    local changed4, new_hour_offset = reaper.ImGui_SliderInt(ctx, "Hour Offset", hour_offset_value, knob_min, knob_max)
    if changed4 then hour_offset_value = new_hour_offset end

    reaper.ImGui_Separator(ctx)
    
    -- Buttons for CSV operations
    if reaper.ImGui_Button(ctx, "Browse CSV") then
      local retval, selected_file = reaper.GetUserFileNameForRead(last_folder, "Select CSV File", ".csv")
      if retval then
        file_path = selected_file
        local new_folder = file_path:match("(.+[\\/])")
        if new_folder then last_folder = new_folder end
        debug_log = "File selected: " .. file_path .. "\n"
        -- Reset mapping so that a new load is forced
        mapping = nil
        trackOrder = {}
      end
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Process CSV") then
      if file_path == "" then
        debug_log = "Please Load a CSV\n"
      else
        mapping, debug_log, trackOrder = load_timecodes_from_csv(file_path)
        if mapping then
          align_selected_items(mapping)
          debug_log = debug_log .. "\nItems aligned."
        end
      end
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Generate Tracks") then
      if file_path == "" then
        debug_log = "Please Load a CSV\n"
      else
        if not mapping then
          mapping, debug_log, trackOrder = load_timecodes_from_csv(file_path)
        end
        if mapping then
          generate_tracks(trackOrder)
        end
      end
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Debug Log:")
    reaper.ImGui_BeginChild(ctx, "Scrolling", 0, 150, 1)
      reaper.ImGui_TextWrapped(ctx, debug_log)
    reaper.ImGui_EndChild(ctx)
  end
  reaper.ImGui_End(ctx)
  
  if reaper.ImGui_Render then
    reaper.ImGui_Render(ctx)
  elseif reaper.ImGui_RenderFrame then
    reaper.ImGui_RenderFrame(ctx)
  end
  
  if open then
    reaper.defer(loop)
  end
end

loop()

