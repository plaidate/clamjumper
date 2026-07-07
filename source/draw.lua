-- Rendering: the three species, clams, the eel, ink puffs, the HUD, and
-- every screen. All white lines and dither on black — a moonlit ocean floor.

local gfx <const> = playdate.graphics

Draw = {}

local RIVAL_A = { 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22 } -- 25%

local textCache = {}
function Draw.big(str, x, y, scale, center)
    local img = textCache[str]
    if not img then
        local w, h = gfx.getTextSize(str)
        img = gfx.image.new(math.max(w, 1), math.max(h, 1))
        gfx.pushContext(img)
        gfx.drawText(str, 0, 0)
        gfx.popContext()
        textCache[str] = img
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    img:drawScaled(center and (x - img.width * scale / 2) or x, y, scale)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.text(str, x, y, align)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local w = gfx.getTextSize(str)
    if align == "center" then x = x - w / 2 elseif align == "right" then x = x - w end
    gfx.drawText(str, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- ---- entities ---------------------------------------------------------------

function Draw.clam(cl)
    local x, y = Util.tilePx(cl.c, cl.r)
    if cl.taken then return end
    local open = cl.open or 0
    local w = 9
    local base = y + 5
    gfx.setColor(gfx.kColorWhite)
    -- bottom shell: a ribbed scallop dome sitting on the sand
    gfx.drawArc(x, base, w, 180, 360)
    gfx.drawLine(x - w, base, x + w, base)
    for i = -2, 2 do
        gfx.drawLine(x, base, x + i * (w / 3), base - 6)
    end
    -- top lid lifts open as it is pried, with a pearl showing through
    if open > 0.02 then
        local lift = 3 + open * 8
        gfx.drawArc(x, base - lift, w, 180, 360)
        gfx.drawLine(x - w, base - lift, x + w, base - lift)
        if open > 0.35 then
            gfx.fillCircleAtPoint(x, base - lift * 0.5, 1.5 + open * 2.5)
        end
        -- pry progress ring around the shell
        if open < 1 then
            gfx.drawArc(x, y, 13, -90, -90 + 360 * open)
        end
    end
end

-- ---- the three species, in vectors -------------------------------------------

local function drawStarfish(cr, filled, s)
    local x, y = cr.px, cr.py - (cr.hop or 0)
    local clamped = Critter.clamped(cr)
    local wob = clamped and 0 or math.sin(G.t * 3 + x * 0.05) * 0.12
    local ro = (clamped and 11 or 10) * s
    local ri = (clamped and 5.5 or 4.5) * s
    local rot = -math.pi / 2 + wob
    local pts = {}
    for i = 0, 4 do
        local a = rot + i * (math.pi * 2 / 5)
        pts[#pts + 1] = x + math.cos(a) * ro
        pts[#pts + 1] = y + math.sin(a) * ro
        local a2 = a + math.pi / 5
        pts[#pts + 1] = x + math.cos(a2) * ri
        pts[#pts + 1] = y + math.sin(a2) * ri
    end
    if filled then gfx.setColor(gfx.kColorWhite) else gfx.setPattern(RIVAL_A) end
    gfx.fillPolygon(table.unpack(pts))
    gfx.setColor(gfx.kColorWhite)
    gfx.drawPolygon(table.unpack(pts))
    -- madreporite dot in the middle
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x, y, 1.5 * s)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleAtPoint(x, y, 1.5 * s)
    if clamped then
        -- suction ring pressed into the sand
        gfx.drawEllipseInRect(x - 12 * s, cr.py + 2 * s, 24 * s, 5 * s)
    end
end

local function drawOctopus(cr, filled, s)
    local x, y = cr.px, cr.py - (cr.hop or 0)
    local face = cr.dc or 1
    if face == 0 then face = 1 end
    local jet = Critter.jumping(cr)
    -- tentacles: five wavy legs (streamed back while jetting)
    gfx.setColor(gfx.kColorWhite)
    for i = -2, 2 do
        local wig = math.sin(G.t * 6 + i * 1.3) * 2.5 * s
        local x0 = x + i * 3 * s
        local x1 = jet and (x0 - face * 5 * s) or (x0 + i * 1.2 * s + wig)
        local y1 = y + (jet and 5 or 7) * s
        gfx.drawLine(x0, y - 1 * s, x0 + wig * 0.4, y + 3 * s)
        gfx.drawLine(x0 + wig * 0.4, y + 3 * s, x1, y1)
    end
    -- mantle
    if filled then gfx.setColor(gfx.kColorWhite) else gfx.setPattern(RIVAL_A) end
    gfx.fillEllipseInRect(x - 8 * s, y - 12 * s, 16 * s, 13 * s)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawEllipseInRect(x - 8 * s, y - 12 * s, 16 * s, 13 * s)
    -- big eyes, looking where it goes
    local ex = x + face * 2 * s
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(ex - 3 * s, y - 5 * s, 2.2 * s)
    gfx.fillCircleAtPoint(ex + 3 * s, y - 5 * s, 2.2 * s)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(ex - 3 * s + face, y - 5 * s, s)
    gfx.fillCircleAtPoint(ex + 3 * s + face, y - 5 * s, s)
    gfx.setColor(gfx.kColorWhite)
end

local function drawRay(cr, filled, s)
    local x, y = cr.px, cr.py - (cr.hop or 0)
    local face = cr.dc or 1
    if face == 0 then face = 1 end
    local air = Critter.jumping(cr)
    local flap = 0.75 + 0.25 * math.sin(G.t * (air and 14 or 5) + x * 0.03)
    local w = 9 * s * flap
    local nose = x + face * 11 * s
    local tail = x - face * 8 * s
    if filled then gfx.setColor(gfx.kColorWhite) else gfx.setPattern(RIVAL_A) end
    gfx.fillPolygon(nose, y, x, y + w, tail, y, x, y - w)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawPolygon(nose, y, x, y + w, tail, y, x, y - w)
    -- tail whip
    local ty = y + math.sin(G.t * 7 + x * 0.05) * 2 * s
    gfx.drawLine(tail, y, tail - face * 7 * s, ty)
    -- eyes near the nose
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(x + face * 5 * s, y - 2 * s, 1.2 * s)
    gfx.fillCircleAtPoint(x + face * 5 * s, y + 2 * s, 1.2 * s)
    gfx.setColor(gfx.kColorWhite)
end

local ARTISTS = {
    starfish = drawStarfish,
    octopus = drawOctopus,
    ray = drawRay,
}

function Draw.critter(cr, filled, s)
    if cr.invuln and cr.invuln > 0 and math.floor(cr.invuln * 10) % 2 == 0 then return end
    ARTISTS[cr.species](cr, filled, s or 1)
end

function Draw.player()
    local p = G.player
    Draw.critter(p, true)
    -- long ability cooldowns (the sea star's clamp, a full-length glide)
    -- tick down as an arc over the player's head
    if p.cool > 0.3 and (p.coolMax or 0) >= 1 then
        gfx.drawArc(p.px, p.py - (p.hop or 0) - 16, 4, -90, -90 + 360 * (1 - p.cool / p.coolMax))
    end
end
function Draw.rival() Draw.critter(G.rival, false) end

function Draw.inks()
    for _, ink in ipairs(Critter.inks) do
        local r = 8 + math.sin(G.t * 5 + ink.px) * 1.5
        gfx.setPattern(RIVAL_A)
        gfx.fillCircleAtPoint(ink.px, ink.py, r)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleAtPoint(ink.px, ink.py, r)
    end
end

function Draw.eel(e)
    -- body: the trail smoothed, head at the live position
    local pts = { { e.px, e.py } }
    for _, p in ipairs(e.trail) do pts[#pts + 1] = p end
    gfx.setLineWidth(6)
    for i = 1, #pts - 1 do
        gfx.drawLine(pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2])
    end
    gfx.setLineWidth(1)
    -- head
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(e.px, e.py, 5)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(e.px, e.py, 5)
    local fx = e.moving and Util.sign(e.tc - e.c) or e.dc
    local fy = e.moving and Util.sign(e.tr - e.r) or e.dr
    gfx.fillCircleAtPoint(e.px + fx * 2 - 1, e.py + fy * 2 - 1, 1.4)
    gfx.fillCircleAtPoint(e.px + fx * 2 + 1, e.py + fy * 2 + 1, 1.4)
    gfx.setColor(gfx.kColorWhite)
end

-- ---- HUD + reef -------------------------------------------------------------

-- a tiny life icon in the player's species
local function lifeIcon(species, x, y)
    gfx.setColor(gfx.kColorWhite)
    if species == "starfish" then
        for i = 0, 4 do
            local a = -math.pi / 2 + i * math.pi * 2 / 5
            gfx.drawLine(x, y, x + math.cos(a) * 5, y + math.sin(a) * 5)
        end
    elseif species == "octopus" then
        gfx.fillCircleAtPoint(x, y - 2, 3.5)
        gfx.drawLine(x - 3, y + 1, x - 5, y + 5)
        gfx.drawLine(x, y + 1, x, y + 6)
        gfx.drawLine(x + 3, y + 1, x + 5, y + 5)
    else
        gfx.fillPolygon(x + 6, y, x - 1, y + 4, x - 5, y, x - 1, y - 4)
    end
end

function Draw.hud()
    gfx.drawLine(0, C.OY - 1, C.W, C.OY - 1)
    -- left: reef then score
    Draw.text("R" .. G.reef .. "  " .. G.score, 6, 4)
    -- center: the race — your pearls vs the rival's
    Draw.text("YOU " .. (G.pearlsPlayer or 0) .. "   RIVAL " .. (G.pearlsRival or 0), 200, 4, "center")
    -- right: lives as little species icons
    for i = 1, G.lives do
        lifeIcon(G.speciesKey, C.W - 12 - (i - 1) * 16, 10)
    end
end

function Draw.reef()
    Fx.drawAmbient()
    Maze.draw()
    for _, cl in ipairs(G.clams) do Draw.clam(cl) end
    Draw.inks()
    for _, e in ipairs(G.eels) do Draw.eel(e) end
    Draw.rival()
    Draw.player()
    Fx.draw()
    Draw.hud()
end

-- ---- screens ----------------------------------------------------------------

-- the three species swim laps across the title screen
local function titleParade()
    local lanes = {
        { species = "octopus", y = 130, v = 46, off = 0 },
        { species = "ray", y = 196, v = 62, off = 180 },
        { species = "starfish", y = 226, v = 24, off = 320 },
    }
    for _, l in ipairs(lanes) do
        local x = (G.t * l.v + l.off) % (C.W + 70) - 35
        Draw.critter({ px = x, py = l.y, dc = 1, hop = 0,
            jumpT = 0, clampT = 0, species = l.species }, true)
    end
end

function Draw.title()
    Fx.drawAmbient()
    titleParade()
    Draw.big("CLAM", 200, 30, 3, true)
    Draw.big("JUMPER", 200, 66, 3, true)
    Draw.text("PRY THE REEF'S PEARLS BEFORE THE RIVAL", 200, 116, "center")
    Draw.text("HIGH " .. G.high, 200, 150, "center")
    Draw.text("D-PAD MOVE   CRANK PRY   A ABILITY", 200, 172, "center")
    if math.floor(G.t * 2) % 2 == 0 then
        Draw.text("A - START", 200, 210, "center")
    end
end

function Draw.pick()
    Fx.drawAmbient()
    local key = Species.order[G.speciesIdx]
    local sp = Species.get(key)
    Draw.big("CHOOSE YOUR HUNTER", 200, 6, 1.5, true)
    local fake = { px = 200, py = 96, dc = 1, hop = 0, jumpT = 0, clampT = 0, species = key }
    Draw.critter(fake, true, 2.6)
    if math.floor(G.t * 2) % 2 == 0 then
        Draw.big("<", 60, 84, 2, true)
        Draw.big(">", 340, 84, 2, true)
    end
    Draw.big(sp.name, 200, 130, 2, true)
    Draw.text(sp.blurb1, 200, 162, "center")
    Draw.text(sp.blurb2, 200, 178, "center")
    -- stat pips: speed / pry / agility
    gfx.setColor(gfx.kColorWhite)
    local labels = { "SPD", "PRY", "AGI" }
    for i = 1, 3 do
        local gx = 76 + (i - 1) * 92
        Draw.text(labels[i], gx, 200)
        for j = 1, 3 do
            local rx = gx + 32 + (j - 1) * 11
            if j <= sp.pips[i] then
                gfx.fillRect(rx, 204, 8, 8)
            else
                gfx.drawRect(rx, 204, 8, 8)
            end
        end
    end
    Draw.text("A - DIVE IN", 200, 222, "center")
end

function Draw.intro()
    Fx.drawAmbient()
    Draw.big("REEF " .. G.reef, 200, 50, 3, true)
    Draw.text("FIND " .. G.total .. " CLAMS BEFORE THE RIVAL DOES", 200, 110, "center")
    Draw.text("THE RIVAL " .. Species.get(G.rival.species).name .. " WANTS THEM TOO", 200, 130, "center")
    Draw.text("CRANK TO PRY THEM OPEN", 200, 150, "center")
end

function Draw.clearCard()
    Fx.drawAmbient()
    if G.wonReef then
        Draw.big("REEF CLEARED", 200, 40, 2, true)
    else
        Draw.big("REEF LOST", 200, 40, 2, true)
    end
    Draw.text("YOU " .. G.pearlsPlayer .. "   RIVAL " .. G.pearlsRival, 200, 90, "center")
    if G.wonReef then
        Draw.text("REEF BONUS +" .. C.PTS_REEF_WIN, 200, 112, "center")
    end
    Draw.text("SCORE " .. G.score, 200, 140, "center")
end

function Draw.bonus()
    local b = G.bonus
    Fx.drawAmbient()
    -- the bonus round wears its own HUD line: score left, the countdown
    -- center, lives right (the reef's YOU/RIVAL race is on pause)
    gfx.drawLine(0, C.OY - 1, C.W, C.OY - 1)
    Draw.text("R" .. G.reef .. "  " .. G.score, 6, 4)
    Draw.text("TIME " .. math.ceil(b.t) .. "   CAUGHT " .. b.caught, 200, 4, "center")
    for i = 1, G.lives do
        lifeIcon(G.speciesKey, C.W - 12 - (i - 1) * 16, 10)
    end
    Draw.big("PEARL RAIN", 200, 32, 1.5, true)
    gfx.drawLine(0, Bonus.catcherY() + 10, C.W, Bonus.catcherY() + 10)
    for _, p in ipairs(b.pearls) do
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(p.x, p.y, 3)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(p.x, p.y, 3)
        gfx.setColor(gfx.kColorWhite)
    end
    -- the catcher, in your species
    Draw.critter({ px = b.x, py = Bonus.catcherY(), dc = 1, hop = 0,
        jumpT = 0, clampT = 0, species = G.speciesKey }, true)
    Fx.draw()
end

function Draw.gameover()
    Fx.drawAmbient()
    Draw.big("GAME OVER", 200, 40, 2, true)
    Draw.text("SCORE " .. G.score, 200, 90, "center")
    if G.score >= G.high and G.score > 0 then
        Draw.text("NEW HIGH SCORE", 200, 112, "center")
    else
        Draw.text("HIGH " .. G.high, 200, 112, "center")
    end
    Draw.text("REEFS CLEARED " .. (G.reef - 1), 200, 134, "center")
    if math.floor(G.t * 2) % 2 == 0 then
        Draw.text("A - TRY AGAIN", 200, 172, "center")
    end
end
