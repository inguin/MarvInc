require "classes.interpreter.memory"
require "classes.img_button"
require "classes.primitive"
local Color = require "classes.color.color"
require "classes.tabs.tab"
local Parser = require "classes.interpreter.parser"
require "classes.text_box"
-- CODE TAB CLASS--

CodeTab = Class{
    __includes = {Tab},

    button_color = 150,

    init = function(self, eps, dy)
        Tab.init(self, eps, dy)

        -- chars accepted in terminal
        local acc = {}
        for i = 32, 126 do
            acc[string.char(i)] = string.char(i)
        end

        self.term = TextBox(self.pos.x, self.pos.y, self.w, 30, 20, 30, true, FONTS.fira(18), acc)

        -- Buttons
        local bsz = 50
        local by = self.pos.y + self.h - bsz
        local bx = self.pos.x + self.w / 5
        local hf = function(self) return StepManager.state == self.highlight_state and (not self.how_fast or self.how_fast == StepManager.how_fast)  end
        self.stop_b = ImgButton(bx, by, bsz, BUTS_IMG.stop, function() StepManager.stop() end)
        self.stop_b.highlight, self.stop_b.highlight_state = hf, 'stopped'

        bx = bx + bsz + 20
        self.pause_b = ImgButton(bx, by, bsz, BUTS_IMG.pause,
            function()
                if StepManager.state == 'playing' then
                    StepManager.pause()
                else StepManager.step() end
            end)
        self.pause_b.draw = function(self)
            self.img = StepManager.state == 'playing' and BUTS_IMG.pause or BUTS_IMG.step
            ImgButton.draw(self)
        end



        bx = bx + bsz + 20
        self.play_b = ImgButton(bx, by, bsz, BUTS_IMG.play, function() StepManager.play() end)
        self.play_b.highlight, self.play_b.highlight_state, self.play_b.how_fast = hf, 'playing', 1

        bx = bx + bsz + 20
        self.fast_b = ImgButton(bx, by, bsz, BUTS_IMG.fast, function() StepManager.fast() end)
        self.fast_b.highlight, self.fast_b.highlight_state, self.fast_b.how_fast = hf, 'playing', 2

        bx = bx + bsz + 20
        self.superfast_b = ImgButton(bx, by, bsz, BUTS_IMG.superfast, function() StepManager.superfast() end)
        self.superfast_b.highlight, self.superfast_b.highlight_state, self.superfast_b.how_fast = hf, 'playing', 3

        self.buttons = {self.stop_b, self.pause_b, self.play_b, self.fast_b, self.superfast_b}

        -- Inventory slot
        self.inv_slot = nil
        self.inv_x = bx + bsz + 40
        self.inv_y = by
        self.inv_w = 50
        self.inv_h = 50
        self.inv_fnt = FONTS.fira(14)
        self.inv_clr = Color.white()
        self.inv_txt = "INVENTORY"
        self.inv_txt_w = self.inv_fnt:getWidth(self.inv_txt)
        self.inv_txt_h = self.inv_fnt:getHeight()

        self:setId "code_tab"
        -- Memory
        self.memory = Memory(self.pos.x, self.pos.y + self.term.h + 10, self.w, by - 10 - (self.pos.y + self.term.h + 10), 12)

        self.tp = "code_tab"
    end
}

function CodeTab:activate()
    self.term:activate()
end

function CodeTab:deactivate()
    self.term:deactivate()
end

function CodeTab:update(dt)
    self.term:update(dt)
    self.memory:update(dt)
end

function CodeTab:draw()
    if self.err_msg and self.err_line ~= self.term.cursor.i then
        love.graphics.setColor(100, 0, 0)
        love.graphics.setFont(FONTS.fira(13))
        love.graphics.print("Line " .. self.err_line .. ": " .. self.err_msg, self.term.pos.x, self.term.pos.y - FONTS.fira(13):getHeight())
    end
    self.term:draw(self.bad_lines)

    -- Draw buttons
    for _, b in ipairs(self.buttons) do b:draw() end

    -- Inventory
    love.graphics.rectangle("line", self.inv_x, self.inv_y, self.inv_w, self.inv_h)
    love.graphics.setFont(self.inv_fnt)
    love.graphics.print(self.inv_txt, self.inv_x + self.inv_w/2 - self.inv_txt_w/2,
        self.inv_y + self.inv_h)
    if ROOM.bot and ROOM.bot.inv then
        ROOM.bot.inv:draw(self.inv_x, self.inv_y, self.inv_w, self.inv_h)
    end

    -- Draw memory
    self.memory:draw()
end

local function typingRegister(self)
    return self.memory.collide_slot ~= -1 and ROOM.version > "1.0"
end

function CodeTab:keyPressed(key)
    if love.keyboard.isDown("lctrl", "rctrl") then
        if key == 'right' then
            StepManager.increase()
            return
        elseif key == 'left' then
            StepManager.decrease()
            return
        end
    end
    if self.lock then
        if key == 'space' then
            if StepManager.running then
                StepManager.pause()
            else StepManager.play() end
        elseif key == 'escape' then
            StepManager.stop()
        end
        return
    end
    if love.keyboard.isDown("lctrl", "rctrl") then
        if key == 'return' then
            if StepManager.running then
                StepManager.pause()
            else
                StepManager.play()
            end
            return
        end
    end
    local t = typingRegister(self) and self.memory.tbox or self.term
    t:keyPressed(key)
    if typingRegister(self) then self.memory:update_renames() end

    self:checkErrors()
end

function CodeTab:textInput(txt)
    if self.lock then return end
    local t = typingRegister(self) and self.memory.tbox or self.term
    t:textInput(txt)
    if typingRegister(self) then self.memory:update_renames() end
    self:checkErrors()
end

function CodeTab:mousePressed(x, y, but)
    for _, b in ipairs(self.buttons) do b:mousePressed(x, y, but) end

    if self.lock then return end
    local t = typingRegister(self) and self.memory.tbox or self.term
    t:mousePressed(x, y, but)
    self:checkErrors()
end

function CodeTab:mouseScroll(x, y)
    local t = typingRegister(self) and self.memory.tbox or self.term
    t:mouseScroll(x, y)
end

function CodeTab:mouseReleased(x, y, but)
    local t = typingRegister(self) and self.memory.tbox or self.term
    t:mouseReleased(x, y, but)
end

function CodeTab:mouseMoved(x, y)
    self.memory:mouseMoved(x, y)
end

-- Check invalid lines
function CodeTab:checkErrors()
    local c, err_l, err_m = Parser.parseAll(self.term.lines, self.renames)
    if err_l or not c then
        self.bad_lines = c
        self.err_line = err_l
        self.err_msg = err_m
    else
        self.bad_lines = nil
        self.err_line = nil
        self.err_msg = nil
    end
end

-- Resets screen for a new puzzle
function CodeTab:reset(puzzle)
    self.term:reset_lines(puzzle.lines_on_terminal)
    self.term:typeString(puzzle.code)
    self.renames = puzzle.renames
    self.inv_renames = {}
    for a, b in pairs(self.renames) do
        self.inv_renames[b] = a
    end
    self.memory:setSlots(puzzle.memory_slots)
end

function CodeTab:getLines()
    local l = {}
    for i = 1, self.term.line_cur do
        l[i] = self.term.lines[i]
    end
    return l
end

function CodeTab:showLine(i)
    self.term.exec_line = i
end

function CodeTab:saveCurrentCode()
    if not ROOM:connected() then return end
    SaveManager.save_code(ROOM.puzzle_id, table.concat(self:getLines(), "\n"), self.renames)
end
