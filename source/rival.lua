-- The rival — the "clam jumper". Each reef it spawns as a random species
-- other than yours, paths to the nearest untaken clam and pries it on a
-- timer. If you are part-way into a clam it will come and bump you off it
-- (unless you are a clamped sea star — then it gives up and farms). Its
-- species shows in how it hunts: an octopus rival jet-dashes at contested
-- clams and inks you, a sea star rival is slow but pries fast and never
-- chases, a ray rival covers corridors in gliding hops.

Rival = {}

function Rival.reset(reef)
    local opts = {}
    for _, k in ipairs(Species.order) do
        if k ~= G.speciesKey then opts[#opts + 1] = k end
    end
    local key = opts[math.random(#opts)]
    local sp = Species.get(key)
    local factor = math.min(C.RIVAL_FACTOR + (reef - 1) * C.RIVAL_FACTOR_STEP, C.RIVAL_FACTOR_CAP)
    -- a sea star rival would crawl; give it back some speed, it pries fast
    if key == "starfish" then factor = math.min(factor + 0.15, 0.95) end
    G.rival = Critter.spawn(Maze.startR[1], Maze.startR[2], "rival", key, sp.speed * factor)
    G.rival.pryT = 0
    G.rival.pryClam = nil
    local pryScale = (key == "starfish") and 0.65 or 1
    G.rivalPryTime = math.max(C.RIVAL_PRY_TIME - (reef - 1) * 0.15, C.RIVAL_PRY_MIN) * pryScale
end

-- is the player prying a clam right now, close enough to be worth stealing?
local function playerContest()
    if not G.pryClam then return nil end
    if Critter.clamped(G.player) then return nil end -- clamped: unbumpable
    if G.pryClam.pry < Species.get(G.player.species).pryGoal * 0.25 then return nil end
    return G.pryClam
end

-- an octopus rival jet-dashes when the player's clam is a straight shot away
local function tryDash(rv)
    local p = G.player
    local sp = Species.get("octopus")
    local dc, dr, dist = 0, 0, 0
    if rv.r == p.r and rv.c ~= p.c and math.abs(rv.c - p.c) <= sp.dashTiles then
        dc, dist = Util.sign(p.c - rv.c), math.abs(rv.c - p.c)
    elseif rv.c == p.c and rv.r ~= p.r and math.abs(rv.r - p.r) <= sp.dashTiles then
        dr, dist = Util.sign(p.r - rv.r), math.abs(rv.r - p.r)
    else
        return false
    end
    rv.dc, rv.dr = dc, dr
    local oc, orr = rv.c, rv.r
    if not Critter.hop(rv, dist, sp.dashTime, C.JUMP_HEIGHT) then return false end
    rv.cool = sp.dashCool * 2
    rv.coolMax = rv.cool
    Critter.dropInk(oc, orr, "rival")
    Sfx.jump()
    return true
end

function Rival.update(dt)
    local rv = G.rival
    Critter.update(rv, dt)

    -- prying its own clam
    if rv.pryClam then
        if rv.pryClam.taken then
            rv.pryClam = nil
        else
            rv.pryClam.open = math.min(rv.pryClam.rivalPry / G.rivalPryTime, 1)
            rv.pryT = rv.pryT + dt
            rv.pryClam.rivalPry = rv.pryT
            if rv.pryT >= G.rivalPryTime then
                Clams.rivalTake(rv.pryClam)
                rv.pryClam = nil
            end
            return
        end
    end

    if not Critter.idle(rv) then return end

    local p = G.player
    local contest = playerContest()

    -- arrived on the player mid-pry: shove them off their clam
    if contest and rv.c == p.c and rv.r == p.r then
        Player.bumped()
        Harness.count("bumps")
        return -- next frame the clam is underfoot and it starts prying
    end

    -- if I'm standing on an untaken clam, start prying it
    local here = Clams.at(rv.c, rv.r)
    if here then
        rv.pryClam = here
        rv.pryT = here.rivalPry or 0
        return
    end

    -- octopus flourish: a straight-shot dash at the contested clam
    if rv.species == "octopus" and contest and rv.cool <= 0 and math.random() < 0.5 then
        if tryDash(rv) then return end
    end

    -- choose a goal: contest the player's clam, else nearest untaken clam
    local goalfn
    if contest and rv.species ~= "starfish" and math.random() < 0.6 then
        goalfn = function(c, r) return c == p.c and r == p.r end
    else
        goalfn = function(c, r) return Clams.at(c, r) ~= nil end
    end
    local dc, dr = Util.pathNext(rv.c, rv.r, goalfn)
    if dc then
        -- ray flourish: cover long corridors in gliding hops
        if rv.species == "ray" and rv.cool <= 0 and math.random() < 0.25 then
            rv.dc, rv.dr = dc, dr
            if Critter.hop(rv, 2, C.JUMP_TIME, C.JUMP_HEIGHT * 0.7) then
                rv.cool = 0.9
                return
            end
        end
        Critter.step(rv, dc, dr)
    else
        -- nothing reachable: wander
        local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
        Util.shuffle(dirs)
        for _, d in ipairs(dirs) do
            if Critter.step(rv, d[1], d[2]) then break end
        end
    end
end
