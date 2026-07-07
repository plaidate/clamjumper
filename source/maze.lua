-- The reef: a tile grid of open sand and coral walls. Generated per reef
-- and guaranteed fully connected — coral is scattered at random, then any
-- open tile not reachable from the player's corner is sealed off, so the
-- remaining open set is always one connected region.

local gfx <const> = playdate.graphics

Maze = {}

local CORAL_A = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 } -- 50%

Maze.grid = nil       -- grid[r][c] = true when open (walkable)
Maze.openTiles = nil  -- list of {c, r}
Maze.startP = { 0, C.ROWS - 1 }
Maze.startR = { C.COLS - 1, 0 }

function Maze.isOpen(c, r)
    return Util.inBounds(c, r) and Maze.grid[r][c]
end

local function floodFrom(grid, sc, sr)
    local seen = {}
    local list = {}
    local function key(c, r) return r * C.COLS + c end
    local q = { { sc, sr } }
    seen[key(sc, sr)] = true
    local head = 1
    while head <= #q do
        local cur = q[head]; head = head + 1
        list[#list + 1] = cur
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nc, nr = cur[1] + d[1], cur[2] + d[2]
            if Util.inBounds(nc, nr) and grid[nr][nc] and not seen[key(nc, nr)] then
                seen[key(nc, nr)] = true
                q[#q + 1] = { nc, nr }
            end
        end
    end
    return list, seen
end

function Maze.generate(reef)
    local density = C.CORAL_DENSITY + math.min(reef * 0.01, 0.1)
    local need = 14
    local grid, open
    for attempt = 1, 12 do
        grid = {}
        for r = 0, C.ROWS - 1 do
            grid[r] = {}
            for c = 0, C.COLS - 1 do
                grid[r][c] = math.random() >= density
            end
        end
        -- keep the two corners (and their neighbours) clear for spawns
        for _, s in ipairs({ Maze.startP, Maze.startR }) do
            grid[s[2]][s[1]] = true
            for _, d in ipairs({ { 1, 0 }, { 0, -1 }, { -1, 0 }, { 0, 1 } }) do
                local nc, nr = s[1] + d[1], s[2] + d[2]
                if Util.inBounds(nc, nr) then grid[nr][nc] = true end
            end
        end
        local list, seen = floodFrom(grid, Maze.startP[1], Maze.startP[2])
        -- seal unreachable pockets
        for r = 0, C.ROWS - 1 do
            for c = 0, C.COLS - 1 do
                if grid[r][c] and not seen[r * C.COLS + c] then grid[r][c] = false end
            end
        end
        open = list
        if #open >= need then break end
        density = density * 0.7
    end
    Maze.grid = grid
    Maze.openTiles = open
end

-- open tiles excluding a set of {c,r} anchors and their immediate area
function Maze.spotsAwayFrom(anchors, minDist)
    local out = {}
    for _, t in ipairs(Maze.openTiles) do
        local ok = true
        for _, a in ipairs(anchors) do
            if math.abs(t[1] - a[1]) + math.abs(t[2] - a[2]) < minDist then
                ok = false; break
            end
        end
        if ok then out[#out + 1] = t end
    end
    return out
end

function Maze.draw()
    for r = 0, C.ROWS - 1 do
        for c = 0, C.COLS - 1 do
            if not Maze.grid[r][c] then
                local x = C.OX + c * C.TILE
                local y = C.OY + r * C.TILE
                gfx.setPattern(CORAL_A)
                gfx.fillRoundRect(x + 1, y + 1, C.TILE - 2, C.TILE - 2, 4)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRoundRect(x + 1, y + 1, C.TILE - 2, C.TILE - 2, 4)
                -- a couple of coral branches so walls read as reef, not brick
                gfx.drawLine(x + 6, y + C.TILE - 3, x + 4, y + C.TILE - 9)
                gfx.drawLine(x + C.TILE - 6, y + C.TILE - 3, x + C.TILE - 5, y + C.TILE - 10)
                gfx.drawLine(x + C.TILE // 2, y + C.TILE - 3, x + C.TILE // 2 + 2, y + C.TILE - 8)
            end
        end
    end
end
