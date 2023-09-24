-- SPDX-License-Identifier: Apache-2.0

-- This is just a reusable utility file, if you run it on its own, it wont do anything
-- All it does is establish 3 things - a tick callback, a keybaord press callback, and a run function
-- to use it, 
-- main_loop = require "main_loop"
-- main_loop.key_up_callback = function(keycode) { do whatever you want on keypress} end
-- main_loop.tick_callback = function() { do whatever you want every tick} end
-- your key_up_Callback and your tick_callback MUST return true, or else the program will quit.
-- you don't override the key_up_callback, a default one that quits if q is pressed is used
-- if  you don't override the tick callback a default do-nothing one will be used.
-- you can also call the default_key_up_callback from your overridden callback if you still
-- want 'q' to quit, just rember to also return false if it returns false.
-- function:  main_loop.run

local event = require "event"
local keyboard = require "keyboard"

local function unknownEvent()
    return true
end

local main_loop = setmetatable( {}, { __index = function() return unknownEvent end } )

-- callbacks - override these to use this class and get callsbacks (overriding is optional)
main_loop.tick_callback = nil
main_loop.key_up_callback = nil
-- constants
main_loop.seconds_per_tick = 1 -- how often the main loop will invoke 
-- state.  Set this to false to quit or return false from your tick callback

main_loop.running = true

-- default callback - override to handle more keys than just 'q'
function main_loop.default_key_up_callback(code)
    if (code == keyboard.keys.q) then 
        return false 
    end
    return true
end

function main_loop.default_tick_callback()
    return true
end

main_loop.tick_callback = main_loop.default_tick_callback
main_loop.key_up_callback = main_loop.default_key_up_callback

function main_loop.key_up(address, char, code, playerName)
    return main_loop.key_up_callback(code)
end

local function handleEvent(eventID, ...)
    if (eventID) then
        res = main_loop[eventID](...)
        return res
    end
    return true
end

function main_loop.run()
    while true do
        result = handleEvent(event.pull(main_loop.seconds_per_tick))
        if not result then
            break
        end
        if not main_loop.tick_callback() then 
            break
        end
    end
end

return main_loop
