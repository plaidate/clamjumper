-- Shared helpers: clamp/lerp, tile<->pixel conversion, and a breadth-first
-- search over the open reef tiles that returns the first step toward the
-- nearest goal (used by the rival AI and the smoke autopilot).

Util = {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

function Util.lerp(a, b, t)
    return a + (b - a) * t
end

function Util.sign(v)
    if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

-- pixel center of tile (c, r)
function Util.tilePx(c, r)
    return C.OX + c * C.TILE + C.TILE / 2, C.OY + r * C.TILE + C.TILE / 2
end

function Util.inBounds(c, r)
    return c >= 0 and c < C.COLS and r >= 0 and r < C.ROWS
end

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- first step (dc, dr) from (sc, sr) toward the nearest tile where
-- goalfn(c, r) is true, walking only open tiles; nil if none reachable
function Util.pathNext(sc, sr, goalfn)
    local COLS = C.COLS
    local function key(c, r) return r * COLS + c end
    local parent = { [key(sc, sr)] = -1 }
    local q = { { sc, sr } }
    local head = 1
    local goal = nil
    while head <= #q do
        local cur = q[head]; head = head + 1
        local cc, cr = cur[1], cur[2]
        if not (cc == sc and cr == sr) and goalfn(cc, cr) then
            goal = cur; break
        end
        for _, d in ipairs(DIRS) do
            local nc, nr = cc + d[1], cr + d[2]
            if Util.inBounds(nc, nr) and Maze.isOpen(nc, nr) and not parent[key(nc, nr)] then
                parent[key(nc, nr)] = key(cc, cr)
                q[#q + 1] = { nc, nr }
            end
        end
    end
    if not goal then return nil end
    -- walk parents back until the step off the start tile
    local cc, cr = goal[1], goal[2]
    while true do
        local p = parent[key(cc, cr)]
        if p == key(sc, sr) or p == -1 then
            return cc - sc, cr - sr, goal[1], goal[2]
        end
        cc, cr = p % COLS, p // COLS
    end
end

-- Fisher-Yates in place
function Util.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
