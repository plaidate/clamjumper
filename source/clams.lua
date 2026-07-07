-- The clams: closed shells scattered on the reef floor, each holding a
-- pearl. Standing on one and cranking pries it open (player), or the rival
-- pries on a timer. Whoever finishes gets the pearl. The player's pry goal
-- and decay come from their species; a ray landing a glide square on a clam
-- slams it part-open.

Clams = {}

function Clams.reset(reef)
    local count = math.min(C.CLAMS_BASE + (reef - 1) * C.CLAMS_STEP, C.CLAMS_CAP)
    local spots = Maze.spotsAwayFrom({ Maze.startP, Maze.startR }, 2)
    Util.shuffle(spots)
    G.clams = {}
    for i = 1, math.min(count, #spots) do
        local s = spots[i]
        G.clams[#G.clams + 1] = {
            c = s[1], r = s[2],
            taken = false, pry = 0, open = 0,
            rivalPry = 0,
        }
    end
    G.pearlsPlayer = 0
    G.pearlsRival = 0
    G.total = #G.clams
end

function Clams.at(c, r)
    for _, cl in ipairs(G.clams) do
        if not cl.taken and cl.c == c and cl.r == r then return cl end
    end
    return nil
end

function Clams.remaining()
    local n = 0
    for _, cl in ipairs(G.clams) do
        if not cl.taken then n = n + 1 end
    end
    return n
end

-- the player crank-pries the clam under them; deg is crank change this frame
function Clams.playerPry(cl, deg)
    local goal = Species.get(G.player.species).pryGoal
    cl.pry = Util.clamp(cl.pry + deg, 0, goal)
    cl.open = cl.pry / goal
    if deg > 4 then Sfx.pry(cl.open) end
    if cl.pry >= goal then
        cl.taken = true
        cl.by = "player"
        G.pearlsPlayer = G.pearlsPlayer + 1
        G.addScore(C.PTS_PEARL)
        Fx.pearl(cl.c, cl.r)
        Sfx.pearl()
        Harness.count("pearls")
        return true
    end
    return false
end

-- a ray wing-slam: landing a glide on the clam blasts it part-open
function Clams.wingSlam(cl)
    local x, y = Util.tilePx(cl.c, cl.r)
    Fx.text("SLAM!", x, y - 18)
    Fx.bubbleBurst(x, y, 8)
    Sfx.slam()
    Harness.count("wingSlams")
    Clams.playerPry(cl, Species.get("ray").slamCredit)
end

-- progress bleeds back when the player steps off without finishing
function Clams.decayExcept(activeCl, dt)
    local sp = Species.get(G.player.species)
    for _, cl in ipairs(G.clams) do
        if cl ~= activeCl and not cl.taken and cl.pry > 0 then
            cl.pry = math.max(0, cl.pry - sp.pryDecay * dt)
            cl.open = cl.pry / sp.pryGoal
        end
    end
end

function Clams.rivalTake(cl)
    cl.taken = true
    cl.by = "rival"
    cl.open = 1
    G.pearlsRival = G.pearlsRival + 1
    Fx.pearl(cl.c, cl.r)
    Sfx.blip(300)
    Harness.count("rivalPearls")
end
