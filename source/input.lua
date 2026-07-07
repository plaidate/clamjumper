-- Controls: d-pad moves, crank pries the clam underfoot, A fires the
-- species ability (octopus dash / sea star clamp; the ray holds A to keep
-- gliding). The smoke autopilot plays all three species: it paths to the
-- nearest clam, cranks it open, answers eels with its species' move, and
-- steers left/right in the bonus round.

Input = {}

-- returns { mvx, mvy (-1/0/1), ability, abilityHeld (bool), crank (deg) }
function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end
    local mvx, mvy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then mvx = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then mvx = 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then mvy = -1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then mvy = 1 end
    -- one axis at a time on a grid; vertical wins ties
    if mvy ~= 0 then mvx = 0 end
    return {
        mvx = mvx, mvy = mvy,
        ability = playdate.buttonJustPressed(playdate.kButtonA),
        abilityHeld = playdate.buttonIsPressed(playdate.kButtonA),
        crank = playdate.getCrankChange(),
    }
end

function Input.confirm()
    if Harness.enabled then return G.t > 0.7 end
    return playdate.buttonJustPressed(playdate.kButtonA)
end

-- -1/0/1 for menu cursor moves (the species pick screen)
function Input.menuLR()
    local d = 0
    if playdate.buttonJustPressed(playdate.kButtonLeft) then d = -1 end
    if playdate.buttonJustPressed(playdate.kButtonRight) then d = d + 1 end
    return d
end

-- ---- smoke autopilot ---------------------------------------------------------

-- a tile occupied (or about to be) by an eel?
local function eelTile(c, r)
    for _, e in ipairs(G.eels or {}) do
        if (e.c == c and e.r == r) or (e.moving and e.tc == c and e.tr == r) then
            return true
        end
    end
    return false
end

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local function sidestep(inp, p)
    for _, d in ipairs(DIRS) do
        if Maze.isOpen(p.c + d[1], p.r + d[2]) and not eelTile(p.c + d[1], p.r + d[2]) then
            inp.mvx, inp.mvy = d[1], d[2]
            return
        end
    end
end

-- how long to keep A held after firing (the ray's glide wants a held button)
local apHold = 0

local function useAbility(inp, p)
    inp.ability = true
    inp.abilityHeld = true
    if p.species == "ray" then apHold = 0.4 end
end

Harness.autopilot = function()
    local inp = { mvx = 0, mvy = 0, ability = false, abilityHeld = false, crank = 0 }

    if apHold > 0 then
        apHold = apHold - C.DT
        inp.abilityHeld = true
    end

    if G.state == "bonus" then
        -- chase the lowest pearl
        local b = G.bonus
        local best
        for _, p in ipairs(b.pearls) do
            if not best or p.y > best.y then best = p end
        end
        if best then inp.mvx = Util.sign(best.x - b.x) end
        return inp
    end
    if G.state ~= "play" then return inp end

    local p = G.player
    if Critter.jumping(p) then return inp end
    local starfish = p.species == "starfish"

    -- standing on an untaken clam: crank it open (defend or bail if an eel
    -- bears down on us)
    if Critter.idle(p) and Clams.at(p.c, p.r) then
        if eelTile(p.c, p.r) and not Critter.clamped(p) then
            if starfish then
                if p.cool <= 0 then
                    useAbility(inp, p) -- clamp and ride it out
                else
                    sidestep(inp, p) -- clamp is cooling: scuttle off
                end
            else
                useAbility(inp, p) -- hop/dash/glide clear
            end
            return inp
        end
        inp.crank = 40
        return inp
    end

    if not Critter.idle(p) then return inp end

    -- an eel dead ahead: answer with the species move
    if eelTile(p.c + p.dc, p.r + p.dr) then
        if starfish then
            if p.cool <= 0 then useAbility(inp, p) else sidestep(inp, p) end
        else
            useAbility(inp, p)
        end
        return inp
    end

    -- a ray with a clam a straight glide ahead slams onto it
    if p.species == "ray" and p.cool <= 0 then
        local sp = Species.get("ray")
        for dist = 2, sp.glideTiles do
            local nc, nr = p.c + p.dc * dist, p.r + p.dr * dist
            if not Util.inBounds(nc, nr) then break end
            if Clams.at(nc, nr) and not eelTile(nc, nr) then
                useAbility(inp, p)
                -- hold just past the previous tile so the landing pick is dist
                apHold = ((dist - 0.75) * C.TILE) / sp.glideSpeed
                return inp
            end
        end
    end

    -- path to the nearest untaken clam, avoiding an eel-occupied next tile
    local dc, dr = Util.pathNext(p.c, p.r, function(c, r) return Clams.at(c, r) ~= nil end)
    if dc and not eelTile(p.c + dc, p.r + dr) then
        inp.mvx, inp.mvy = dc, dr
    elseif dc then
        -- eel blocks the ideal step: try any other safe open neighbour
        sidestep(inp, p)
    end
    return inp
end
