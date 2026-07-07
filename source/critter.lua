-- The critter chassis: shared tile movement for the player and the rival,
-- whichever species either one is. A critter glides to a neighbour tile when
-- told; its A-ability dispatches on species — a 3-tile jet dash that drops
-- ink (octopus), a hold-to-glide flight (ray), or a suction clamp (sea
-- star). Anything airborne has i-frames; anything clamped cannot move, be
-- bumped, or be hurt by an eel. Ink puffs live here too: a puff stuns the
-- *other* side when they wade into it (eels ignore ink).

Critter = {}
Critter.inks = {}

function Critter.spawn(c, r, kind, speciesKey, speed)
    local px, py = Util.tilePx(c, r)
    return {
        c = c, r = r, px = px, py = py,
        kind = kind, species = speciesKey,
        speed = speed or Species.get(speciesKey).speed,
        moving = false, tc = c, tr = r,
        dc = (kind == "rival") and -1 or 1, dr = 0,
        jumpT = 0, jumpDur = 1, jumpH = C.JUMP_HEIGHT, hop = 0, cool = 0,
        stun = 0, invuln = 0, clampT = 0,
        glide = nil, glideHeld = false,
    }
end

function Critter.jumping(cr) -- airborne (i-frames): mid-hop, -dash, or -glide
    return cr.jumpT > 0 or cr.glide ~= nil
end

function Critter.clamped(cr)
    return (cr.clampT or 0) > 0
end

function Critter.idle(cr)
    return not cr.moving and not Critter.jumping(cr) and cr.stun <= 0
end

-- begin a glide to an open neighbour; returns true if it started
function Critter.step(cr, dc, dr)
    if cr.moving or Critter.jumping(cr) or cr.stun > 0 or Critter.clamped(cr) then return false end
    if dc == 0 and dr == 0 then return false end
    cr.dc, cr.dr = dc, dr
    if Maze.isOpen(cr.c + dc, cr.r + dr) then
        cr.moving = true
        cr.tc, cr.tr = cr.c + dc, cr.r + dr
        return true
    end
    return false
end

local function canAct(cr)
    return not cr.moving and not Critter.jumping(cr) and cr.cool <= 0
        and cr.stun <= 0 and not Critter.clamped(cr)
end

-- arc up to `tiles` tiles in the facing direction, fewer if the far ones
-- are blocked; the caller sets the cooldown
function Critter.hop(cr, tiles, time, height)
    if not canAct(cr) then return false end
    local land
    for dist = tiles, 1, -1 do
        local nc, nr = cr.c + cr.dc * dist, cr.r + cr.dr * dist
        if Maze.isOpen(nc, nr) then land = { nc, nr }; break end
    end
    if not land then return false end
    cr.jumpT = time
    cr.jumpDur = time
    cr.jumpH = height or C.JUMP_HEIGHT
    cr.sx, cr.sy = cr.px, cr.py
    cr.ex, cr.ey = Util.tilePx(land[1], land[2])
    cr.landC, cr.landR = land[1], land[2]
    return true
end

-- the A button, per species; returns true if the ability fired
function Critter.ability(cr)
    local sp = Species.get(cr.species)
    if sp.ability == "clamp" then
        if not canAct(cr) then return false end
        cr.clampT = sp.clampTime
        cr.cool = sp.clampCool
        cr.coolMax = sp.clampCool
        return true
    elseif sp.ability == "dash" then
        local oc, orr = cr.c, cr.r
        if not Critter.hop(cr, sp.dashTiles, sp.dashTime, C.JUMP_HEIGHT) then return false end
        cr.cool = sp.dashCool
        cr.coolMax = sp.dashCool
        Critter.dropInk(oc, orr, cr.kind)
        return true
    else -- glide: airborne while the button is held, up to glideTiles
        if not canAct(cr) then return false end
        local cands = {}
        for d = 1, sp.glideTiles do
            local nc, nr = cr.c + cr.dc * d, cr.r + cr.dr * d
            if not Util.inBounds(nc, nr) then break end
            if Maze.isOpen(nc, nr) then cands[#cands + 1] = d end
        end
        if #cands == 0 then return false end
        cr.glide = { dist = 0, cands = cands, maxPx = cands[#cands] * C.TILE,
            sx = cr.px, sy = cr.py }
        cr.glideHeld = true
        return true
    end
end

local function eelAt(c, r)
    for _, e in ipairs(G.eels or {}) do
        if (e.c == c and e.r == r) or (e.moving and e.tc == c and e.tr == r) then
            return true
        end
    end
    return false
end

-- the button was released (or range ran out): land on the next open
-- candidate at/ahead of the current distance, preferring one without an
-- eel on it; fall back to the last candidate passed
local function glideLand(cr)
    local g = cr.glide
    local sp = Species.get(cr.species)
    local pick
    for pass = 1, 2 do
        for _, d in ipairs(g.cands) do
            if d * C.TILE >= g.dist - 0.01
                and (pass == 2 or not eelAt(cr.c + cr.dc * d, cr.r + cr.dr * d)) then
                pick = d
                break
            end
        end
        if pick then break end
    end
    pick = pick or g.cands[#g.cands]
    cr.glide = nil
    cr.jumpT = C.GLIDE_LAND_TIME
    cr.jumpDur = C.GLIDE_LAND_TIME
    cr.hopStart = cr.hop
    cr.fromGlide = true
    cr.sx, cr.sy = cr.px, cr.py
    cr.landC, cr.landR = cr.c + cr.dc * pick, cr.r + cr.dr * pick
    cr.ex, cr.ey = Util.tilePx(cr.landC, cr.landR)
    cr.cool = sp.glideCoolPerTile * pick
    cr.coolMax = cr.cool
end

-- advance one frame; returns true on the frame it arrives at a new tile
function Critter.update(cr, dt)
    if cr.cool > 0 then cr.cool = cr.cool - dt end
    if cr.stun > 0 then cr.stun = cr.stun - dt end
    if cr.invuln > 0 then cr.invuln = cr.invuln - dt end
    if cr.clampT > 0 then cr.clampT = cr.clampT - dt end

    -- a thin bubble wake while airborne
    if Critter.jumping(cr) and math.random() < 0.25 then
        Fx.wake(cr.px, cr.py - (cr.hop or 0) * 0.5)
    end

    if cr.glide then
        local g = cr.glide
        local sp = Species.get(cr.species)
        g.dist = math.min(g.dist + sp.glideSpeed * dt, g.maxPx)
        cr.px = g.sx + cr.dc * g.dist
        cr.py = g.sy + cr.dr * g.dist
        cr.hop = C.JUMP_HEIGHT * 0.85 * math.min(1, g.dist / 14)
        if not cr.glideHeld or g.dist >= g.maxPx then
            glideLand(cr)
        end
        return false
    end

    if cr.jumpT > 0 then
        cr.jumpT = cr.jumpT - dt
        local k = 1 - math.max(cr.jumpT, 0) / cr.jumpDur
        cr.px = Util.lerp(cr.sx, cr.ex, k)
        cr.py = Util.lerp(cr.sy, cr.ey, k)
        if cr.fromGlide then
            cr.hop = cr.hopStart * (1 - k) -- ease down from glide height
        else
            cr.hop = math.sin(math.pi * k) * cr.jumpH
        end
        if cr.jumpT <= 0 then
            cr.hop = 0
            cr.c, cr.r = cr.landC, cr.landR
            cr.px, cr.py = cr.ex, cr.ey
            if cr.fromGlide then
                cr.fromGlide = nil
                cr.glideLanded = true
            end
            return true
        end
        return false
    end

    if cr.moving then
        local gx, gy = Util.tilePx(cr.tc, cr.tr)
        local step = cr.speed * dt
        local ddx, ddy = gx - cr.px, gy - cr.py
        local d = math.sqrt(ddx * ddx + ddy * ddy)
        if d <= step then
            cr.px, cr.py = gx, gy
            cr.c, cr.r = cr.tc, cr.tr
            cr.moving = false
            return true
        end
        cr.px = cr.px + ddx / d * step
        cr.py = cr.py + ddy / d * step
    end
    return false
end

-- ---- ink puffs ---------------------------------------------------------------

function Critter.resetInks()
    Critter.inks = {}
end

function Critter.dropInk(c, r, owner)
    local px, py = Util.tilePx(c, r)
    Critter.inks[#Critter.inks + 1] = {
        c = c, r = r, px = px, py = py, t = C.INK_TIME, owner = owner,
    }
end

function Critter.updateInks(dt)
    for i = #Critter.inks, 1, -1 do
        local ink = Critter.inks[i]
        ink.t = ink.t - dt
        local victim = (ink.owner == "player") and G.rival or G.player
        if ink.t <= 0 then
            table.remove(Critter.inks, i)
        elseif victim and victim.c == ink.c and victim.r == ink.r
            and victim.stun <= 0 and not Critter.jumping(victim) then
            victim.stun = C.INK_STUN
            table.remove(Critter.inks, i)
            Fx.bubbleBurst(ink.px, ink.py, 10)
            Fx.text("INKED!", ink.px, ink.py - 16)
            Sfx.bump()
            Harness.count("inkStuns")
        end
    end
end
