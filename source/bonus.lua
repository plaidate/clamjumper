-- The pearl-rain bonus round (the original's separate mode, reskinned):
-- between reefs, pearls drift down the water column and the crab scoots
-- left/right along the seabed to catch them. No hazards, pure points.

Bonus = {}

function Bonus.start()
    G.bonus = {
        t = C.BONUS_TIME,
        x = C.W / 2,
        pearls = {},
        spawnT = 0,
        caught = 0,
    }
    Sfx.fanfare({ 659, 784, 988, 1319 }, 0.08)
    Harness.count("bonuses")
end

local CATCH_Y = C.H - 22

function Bonus.update(dt, inp)
    local b = G.bonus
    b.t = b.t - dt

    -- move the catcher
    b.x = Util.clamp(b.x + inp.mvx * 150 * dt, 16, C.W - 16)

    -- spawn pearls
    b.spawnT = b.spawnT - dt
    if b.spawnT <= 0 then
        b.spawnT = 0.45 + math.random() * 0.35
        b.pearls[#b.pearls + 1] = {
            x = math.random(20, C.W - 20), y = C.OY,
            vy = 55 + math.random() * 45, sway = math.random() * 6,
        }
    end

    for i = #b.pearls, 1, -1 do
        local p = b.pearls[i]
        p.y = p.y + p.vy * dt
        if p.y >= CATCH_Y and math.abs(p.x - b.x) < 18 then
            table.remove(b.pearls, i)
            b.caught = b.caught + 1
            G.addScore(C.PTS_BONUS_CATCH)
            Fx.bubbleBurst(p.x, CATCH_Y, 6)
            Fx.text("+" .. C.PTS_BONUS_CATCH, p.x, CATCH_Y - 16)
            Sfx.blip(900)
            Harness.count("bonusCatch")
        elseif p.y > C.H then
            table.remove(b.pearls, i)
        end
    end

    return b.t <= 0
end

function Bonus.catcherY()
    return CATCH_Y
end
