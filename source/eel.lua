-- The moray eel: the reef's lethal hazard. It slides tile to tile along
-- open corridors, mostly holding its heading, and kills the player on
-- contact (unless the player is mid-hop above it). More eels per reef.

Eel = {}

local function spawnOne(reef)
    -- start far from the player's corner
    local spots = Maze.spotsAwayFrom({ Maze.startP }, 5)
    if #spots == 0 then spots = Maze.openTiles end
    local s = spots[math.random(#spots)]
    local px, py = Util.tilePx(s[1], s[2])
    return {
        c = s[1], r = s[2], px = px, py = py,
        tc = s[1], tr = s[2], moving = false,
        dc = 1, dr = 0, stepT = 0,
        -- body trail of recent centers for the wiggly render
        trail = { { px, py }, { px, py }, { px, py }, { px, py } },
        step = math.max(C.EEL_STEP - (reef - 1) * 0.02, C.EEL_STEP_MIN),
    }
end

function Eel.reset(reef)
    local n = 1 + (reef - 1) // 2
    G.eels = {}
    for _ = 1, n do
        G.eels[#G.eels + 1] = spawnOne(reef)
    end
end

local function chooseDir(e)
    -- prefer to keep going; otherwise turn to any open neighbour, avoiding
    -- an immediate reversal unless boxed in
    local opts = {}
    for _, d in ipairs({ { e.dc, e.dr }, { e.dr, e.dc }, { -e.dr, -e.dc } }) do
        if Maze.isOpen(e.c + d[1], e.r + d[2]) then opts[#opts + 1] = d end
    end
    if #opts == 0 then
        if Maze.isOpen(e.c - e.dc, e.r - e.dr) then return -e.dc, -e.dr end
        return 0, 0
    end
    -- weight forward motion
    if opts[1][1] == e.dc and opts[1][2] == e.dr and math.random() < 0.7 then
        return e.dc, e.dr
    end
    local d = opts[math.random(#opts)]
    return d[1], d[2]
end

function Eel.update(dt)
    for _, e in ipairs(G.eels) do
        if e.moving then
            local gx, gy = Util.tilePx(e.tc, e.tr)
            local sp = C.TILE / e.step
            local ddx, ddy = gx - e.px, gy - e.py
            local d = math.sqrt(ddx * ddx + ddy * ddy)
            if d <= sp * dt then
                e.px, e.py = gx, gy
                e.c, e.r = e.tc, e.tr
                e.moving = false
                table.insert(e.trail, 1, { e.px, e.py })
                while #e.trail > 5 do table.remove(e.trail) end
            else
                e.px = e.px + ddx / d * sp * dt
                e.py = e.py + ddy / d * sp * dt
            end
        else
            local dc, dr = chooseDir(e)
            if dc == 0 and dr == 0 then
                -- trapped: sit still
            else
                e.dc, e.dr = dc, dr
                e.tc, e.tr = e.c + dc, e.r + dr
                e.moving = true
            end
        end
    end
end

-- does any eel share the player's tile (and the player is grounded)?
-- airborne critters and a clamped sea star are safe
function Eel.hitsPlayer()
    local p = G.player
    if Critter.jumping(p) or p.invuln > 0 or Critter.clamped(p) then return false end
    for _, e in ipairs(G.eels) do
        local ec = e.moving and e.tc or e.c
        local er = e.moving and e.tr or e.r
        if (e.c == p.c and e.r == p.r) or (ec == p.c and er == p.r) then
            return true
        end
    end
    return false
end
