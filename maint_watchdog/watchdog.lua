-- SPDX-License-Identifier: Apache-2.0

-- This script requires that each channel broadcasts using wireless opencomputers
-- compatible signals.  YOu'd need a redstone card (tier 2).
-- In GTNH, the wireless Needs MAintenence cover does not broadcast on a channel
-- that is compatible with opencomputers, so you would have to do something like this:

-- Suppose you have a line of machines performing 1 function, like, for example, a 
-- PBI line of LCRs.
-- LCR #1 :  "represents the entire line."
-- LCR #2 :  A worker in the line
-- LCR #3 :  ANother worker in the line

-- setup would be:
-- LCR #1, #2, #3: All have a "Wireless Needs MAintenence cover" on their controller
-- all set to the same channel (for example 1001)
-- LCR #1: 
-- Has an Advanced Wirelress Redstone RECEIVER COVER (external) anywhere on it (I prefer
-- putting it on the maintennece hatch)
-- THat wireless Reciever cover is set to the same channel (1001 in this example) and its
-- gate mode is set to "OR" so it will signal if any of the machines in the group signal
-- IN front of that wireless reciever cover is a WR-CBE Redstone Wireless Transmitter
-- that WR-CBE is set to the same channel (1001).
-- Channel 1001 is then given a name and a number in the below list, and you're done.

-- I would recommend starting at channel 1000 onwards since the WR-CBE wireless handheld
-- sniffer then also functions as an instantaneous view of any maint issues!


local keyboard = require "keyboard"
local component = require "component"
local main_loop = require "main_loop"
local term = require "term"
local tty = require "tty"

-- its actually quite expensive to switch wireless channels so you have to do it 2
-- per tick (per second) at most.
local channels_per_tick = 2

local rs_card = component.redstone

local wireless_channels = {
    [42] = { name = " W0   | NitroBenzene Chem Reactor" }, 
    [43] = { name = " W0   | Benzene Turbine"}, 
    [44] = { name = " W0   | Biomass setup"}, 
    [45] = { name = " W0   | Benzene setup"},
    [46] = { name = " Pwr  | LSC"},
    [47] = { name = " Pwr  | Nuke Large Heat Exchangers"},
    [48] = { name = " Pwr  | Nuke Turbines"},
    [49] = { name = " Pwr  | Coal Tar Refining System"},
    [50] = { name = " Pwr  | Diesel Gens"},
    [51] = { name = " W0   | Nitrobenzene Gens"},
    [52] = { name = " P1F1 | Sulfuric Acid LCR"},
    [12] = { name = " P1F1 | Teflon TFT Complex"},
    [13] = { name = " P1F1 | Ethylene Complex + polyvinyl"},
    [14] = { name = " P1F1 | Oil refinery and desulfur"},
    [15] = { name = " P1F2 | Nitric Acid LCR"},
    [16] = { name = " P1F2 | CBD Line"},
    [17] = { name = " P1F2 | Naptha Crack and Distil" },
    [18] = { name = " ACF1 | Clean Room"},
    [19] = { name = " ACF2 | EBFs and Freezer"},
    [20] = { name = " ACF2 | LCRs"},
    [21] = { name = " ACF2 | Alloy Blast Smelter"},
    [22] = { name = " ACF2 | Multi Smelter"},
    [23] = { name = " ACF2 | Implosion Compressor"},
    [24] = { name = " ACF2 | Row Of Multis"},
    [25] = { name = " P1F2 | Heavy Fuel Distillation"},
    [26] = { name = " P1F2 | Silicon Rubber Line"},
    [27] = { name = " P1F2 | Butadiene Crack / Refine"},
    [28] = { name = " P1F2 | Epoxid line"},
    [29] = { name = " P1F3 | Heavy Fuel Cracking"},
    [30] = { name = " P1F3 | Advanced Glue Process"},
    [31] = { name = " P1F3 | Radon Loop"},
    [32] = { name = " P1F3 | Polyphenelyne.S line"},
    [33] = { name = " P1F3 | iTNT LCR"},
    [34] = { name = " M1F1 | Industrial Presses"},
    [35] = { name = " M1F1 | Industrial Extruder"},
    [36] = { name = " M1F1 | Industrial Wire Factory"},
    [37] = { name = " M1F2 | Distilled Water"},
    [38] = { name = " P2F2 | Noble Gasses Process"},
    [39] = { name = " M1F2 | Platline - Platinum Only"},
    [40] = { name = " M1F2 | Tungsten / Scheelite Line"},
    [41] = { name = " M1F3 | Platline - O, Rhom, Ir"},
    [53] = { name = " P2F1 | Ammonia Quad LCR"},
    [54] = { name = " P2F1 | Drilling Fluid Multi"},
    [55] = { name = " P2F1 | PBI Line"},
    [56] = { name = " P2F1 | Phthalic Acid (Coal Tar)"},
    [57] = { name = " P2F2 | HCL LCR"},
    [58] = { name = " P2F2 | Sodium Nitrate LCR"},
    [59] = { name = " P2F2 | Formic Acid Line"},
    [60] = { name = " P2F2 | Carbon Monoxide LCR"},
    [61] = { name = " M2F1 | Rhodium Finalization"},
    [62] = { name = " M2F1 | Palladium Finalization"},
    [63] = { name = " OrF1 | Macerator + Thermal Cent"},
    [64] = { name = " OrF1 | Oreproc - Chem Baths"},
    [65] = { name = " OrF1 | Sift,Centrifuge,Electrolyze"},
    [66] = { name = " OrF1 | EBFs and Freezer"},
    [67] = { name = " OrF2 | Rutile Chain + Mg Recapture"},
    [68] = { name = " OrF2 | Indium Process"},
    [69] = { name = " OrF2 | Bauxite Refining Process"},
    [70] = { name = " M2F1 | Thorium 232 Process'"}
 }

 -- this adds a property to the above table for each entry "needs_maint" and initialize to false.
for k in pairs(wireless_channels) do wireless_channels[k].needs_maint = false end

-- so now each entry in the above table actually looks like
-- { 
--   name = "blahblah",
--   needs_maint = false
-- }

-- go to the first channel in the table (which is not necessarily channel 1)
local current_channel = next(wireless_channels, nil)

function check_one_channel()
    rs_card.setWirelessFrequency(current_channel)
    wireless_channels[current_channel].needs_maint = rs_card.getWirelessInput()

    -- go to the next channel in the table or go back to the first one if its at the end.
    current_channel = next(wireless_channels, current_channel) or next(wireless_channels, nil)
end

function update()
    if not main_loop.default_tick_callback() then return false end
    local starting_channel = current_channel
    for i = 1, channels_per_tick do
        check_one_channel()
        if starting_channel == current_channel then break end -- loop only once per go at most
    end
    printstatus()
    return true
end

function printstatus()
    local columnoffset = 1
    local window_width, window_height = tty.getViewport()
    term.clear()
    term.setCursor(columnoffset,1)
    term.write("Maint Monitor (Q TO Quit) ... scanning channel " .. tostring(current_channel) .. " (" ..  wireless_channels[current_channel].name .. ")")
    term.setCursor(columnoffset,2)
    term.write(" STATUS |  LOC  | NAME") 
    term.setCursor(columnoffset,3)
    term.write("--------|-------|--------------------") 
    local current_pos = 4
    for k in pairs(wireless_channels) do
        term.setCursor(columnoffset,current_pos)
        if k == current_channel then term.write("\xF0\x9F\x91\x80") else term.write(" ") end
        term.setCursor(columnoffset+3,current_pos)
        if wireless_channels[k].needs_maint then
            term.write("ALARM| ".. wireless_channels[k].name)
        else
            term.write(" OK  | ".. wireless_channels[k].name)
        end
        current_pos = current_pos + 1
        if current_pos >= window_height - 1 then
            columnoffset = columnoffset +  window_width / 3
            current_pos = 4
            term.setCursor(columnoffset,2)
            term.write(" STATUS |  LOC  | NAME") 
            term.setCursor(columnoffset,3)
            term.write("--------|-------|--------------------") 

        end
    end
end

main_loop.tick_callback = update
main_loop.key_up_callback = function(code)
  if not main_loop.default_key_up_callback(code) then return false end
  return true -- return false to quit.  The default callback quits if you press 'q'
end

main_loop.run()
