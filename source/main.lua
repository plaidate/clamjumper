-- Clam Jumper — a standalone Playdate game.
-- An ocean-bed take on the 1982 arcade game Claim Jumper: instead of a
-- cowboy racing a rival to collect gold bars in a maze, you pick a clam
-- specialist — sea star, octopus, or ray — and race a rival one to pry
-- pearls from clams scattered across a reef. Crank to pry, fire your
-- species' ability with A, dodge the moray eel. Whoever nets more pearls
-- wins the reef.

import "CoreLibs/graphics"

import "config"
import "util"
import "harness"
import "species"
import "save"
import "sfx"
import "music"
import "maze"
import "critter"
import "clams"
import "player"
import "rival"
import "eel"
import "fx"
import "bonus"
import "input"
import "draw"

local gfx <const> = playdate.graphics

Game = {}

Save.load()
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
Harness.shotPath = "build/clamjumper-shot.png"
Fx.reset()

function G.addScore(n)
    G.score = G.score + n
    if G.score >= G.nextLifeAt then
        G.nextLifeAt = G.nextLifeAt + C.EXTRA_LIFE_EVERY
        if G.lives < C.MAX_LIVES then
            G.lives = G.lives + 1
            Fx.text("EXTRA LIFE", C.W / 2, 130)
            Sfx.fanfare({ 659, 988, 1319 }, 0.08)
        end
    end
end

local function buildReef()
    Maze.generate(G.reef)
    Clams.reset(G.reef)
    Player.reset()
    Rival.reset(G.reef)
    Eel.reset(G.reef)
    Critter.resetInks()
    Fx.reset()
end

local function startGame()
    G.speciesKey = Species.order[G.speciesIdx]
    Save.store() -- remember the pick as next game's default
    G.score = 0
    G.lives = C.START_LIVES
    G.nextLifeAt = C.EXTRA_LIFE_EVERY
    G.reef = 1
    buildReef()
    Music.reset()
    G.state = "intro"
    G.t = 0
    Harness.count("games")
    Sfx.fanfare()
end

function Game.over()
    if G.score > G.high then
        G.high = G.score
        Save.store()
    end
    G.state = "gameover"
    G.t = 0
    Harness.count("gameovers")
    Sfx.lose()
end

local function finishReef()
    G.wonReef = G.pearlsPlayer >= G.pearlsRival
    G.addScore(C.PTS_REEF_CLEAR)
    if G.wonReef then
        G.addScore(C.PTS_REEF_WIN)
        Sfx.fanfare({ 523, 659, 784, 1047 }, 0.09)
    else
        Sfx.blip(400)
    end
    Harness.count("reefsCleared")
    G.state = "clear"
    G.t = 0
end

-- ---- play update ------------------------------------------------------------

local function updatePlay(dt)
    local inp = Input.gather()

    -- movement / ability
    if inp.ability then
        local sp = Species.get(G.player.species)
        if Critter.ability(G.player) then
            if sp.ability == "clamp" then Sfx.clamp()
            elseif sp.ability == "glide" then Sfx.glide()
            else Sfx.jump() end
            Harness.count("abilityUses")
        end
    elseif inp.mvx ~= 0 or inp.mvy ~= 0 then
        Critter.step(G.player, inp.mvx, inp.mvy)
    end
    G.player.glideHeld = inp.abilityHeld
    Critter.update(G.player, dt)

    local p = G.player

    -- a ray landing its glide square on a clam slams it part-open
    if p.glideLanded then
        p.glideLanded = nil
        local cl = Clams.at(p.c, p.r)
        if cl then Clams.wingSlam(cl) end
    end

    -- prying the clam underfoot with the crank
    local here = Critter.idle(p) and Clams.at(p.c, p.r) or nil
    if here then
        G.pryClam = here
        local deg = math.abs(inp.crank or 0)
        if deg > 0.5 then Clams.playerPry(here, deg) end
    else
        G.pryClam = nil
    end
    Clams.decayExcept(here, dt)

    Critter.updateInks(dt)
    Rival.update(dt)
    Eel.update(dt)

    if Eel.hitsPlayer() then
        Player.caught()
        if G.state ~= "play" then return end
    end

    if Clams.remaining() == 0 then
        finishReef()
    end
end

-- ---- top-level loop ---------------------------------------------------------

local function advanceAfterCard()
    if G.reef % C.BONUS_EVERY == 0 then
        Bonus.start()
        G.state = "bonus"
        G.t = 0
    else
        G.reef = G.reef + 1
        buildReef()
        G.state = "intro"
        G.t = 0
    end
end

local function tick()
    local dt = C.DT
    G.t = G.t + dt
    Util.runPending(dt)
    Fx.update(dt)
    Music.update(dt, G.state == "play" or G.state == "bonus")

    gfx.clear(gfx.kColorBlack)
    gfx.setColor(gfx.kColorWhite)

    if G.state == "title" then
        if Input.confirm() then
            G.state = "pick"
            G.t = 0
        end
        Draw.title()
    elseif G.state == "pick" then
        if Harness.enabled then
            -- rotate species across smoke games (or force via SMOKE_SPECIES)
            local n = #Species.order
            if SMOKE_SPECIES and SMOKE_SPECIES ~= false then
                G.speciesIdx = ((SMOKE_SPECIES - 1) % n) + 1
            else
                G.speciesIdx = ((Harness.counters.games or 0) % n) + 1
            end
        else
            local d = Input.menuLR()
            if d ~= 0 then
                G.speciesIdx = (G.speciesIdx - 1 + d) % #Species.order + 1
                Sfx.blip(700)
            end
        end
        if Input.confirm() then startGame() end
        Draw.pick()
    elseif G.state == "intro" then
        Draw.intro()
        if G.t > 1.6 then
            G.state = "play"
            G.t = 0
        end
    elseif G.state == "play" then
        updatePlay(dt)
        if G.state == "play" then Draw.reef() end
    elseif G.state == "clear" then
        Draw.clearCard()
        if G.t > 2 then advanceAfterCard() end
    elseif G.state == "bonus" then
        local inp = Input.gather()
        if Bonus.update(dt, inp) then
            G.reef = G.reef + 1
            buildReef()
            G.state = "intro"
            G.t = 0
        else
            Draw.bonus()
        end
    elseif G.state == "gameover" then
        Draw.gameover()
        if G.t > 1 and Input.confirm() then
            G.state = "title"
            G.t = 0
        end
    end
end

Harness.extra = function(t)
    t.state = G.state
    t.reef = G.reef
    t.score = G.score
    t.lives = G.lives
    t.clamsLeft = (G.clams and Clams.remaining()) or 0
    t.you = G.pearlsPlayer or 0
    t.rival = G.pearlsRival or 0
    t.species = G.speciesKey
    t.rivalSpecies = G.rival and G.rival.species or "none"
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, tick)
end
