--[[
#####################################
Marvellous Inc.
Copyright (C) 2017  MarvellousSoft & USPGameDev
See full license in file LICENSE.txt
(https://github.com/MarvellousSoft/MarvInc/blob/dev/LICENSE.txt)
#####################################
]]--

require "classes.primitive"
local LoreManager = require "classes.lore_manager"

-- Puzzle stores the values for a new room.

Puzzle = Class{
    -- Declaring what the fields are (for readability/default values).

    -- Puzzle name
    name = nil,
    -- Puzzle id (filename)
    id = nil,
    -- Puzzle number
    n = nil,
    -- Extra info
    extra_info = "",

    -- Puzzle object grid
    grid_obj = nil,
    -- Puzzle floor grid
    grid_floor = nil,

    -- Bot initial position
    init_pos = nil,
    -- Bot initial orientation
    orient = nil,

    -- Objective info
    objective_text = nil,
    objective_checker = nil,
    completed = nil,

    -- Lines allowed in terminal
    lines_on_terminal = 20,
    memory_slots = nil,

    -- Called when the puzzle is started
    on_start = nil,

    -- Called when the puzzle is disconnected
    on_end = nil,

    -- previous code for the puzzle (if saved)
    code = "",

    -- puzzle renaming of registers
    renames = nil,

    -- When completed -- used by LoreManager
    -- called when solving the puzzle for the first time
    first_completed = LoreManager.default_completed,
    -- called subsequent times
    already_completed = LoreManager.already_completed,

    -- End turn Signal function handler. Remove on disconnection.
    turn_handler = nil
}

function Puzzle:manage_objectives(auto_win)
    if self.completed then return end
    if auto_win or self.objective_checker(ROOM) --[[or love.keyboard.isDown("f10")  REMOVE IN RELEASE]] then
        LoreManager.mark_completed(self)
        self.completed = true
        SFX.win_puzzle:stop()
        SFX.win_puzzle:play()
    end
end
