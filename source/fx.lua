-- Flair: rising bubbles, a spinning pearl pop, floating text, and drifting
-- ambient bubbles for the water column.

local gfx <const> = playdate.graphics

Fx = {}

local bubbles = {}
local pops = {}
local texts = {}
local ambient = {}

function Fx.reset()
    bubbles, pops, texts = {}, {}, {}
    if #ambient == 0 then
        for _ = 1, 18 do
            ambient[#ambient + 1] = {
                x = math.random(0, C.W), y = math.random(C.OY, C.H),
                v = 6 + math.random() * 12, r = math.random(1, 2),
            }
        end
    end
end

function Fx.bubbleBurst(x, y, n)
    for _ = 1, (n or 8) do
        bubbles[#bubbles + 1] = {
            x = x + math.random(-6, 6), y = y,
            vx = math.random(-14, 14), vy = -20 - math.random(40),
            r = math.random(1, 3), life = 0.5 + math.random() * 0.4,
        }
    end
end

-- a single tiny wake bubble (dash/glide trails)
function Fx.wake(x, y)
    bubbles[#bubbles + 1] = {
        x = x + math.random(-3, 3), y = y,
        vx = math.random(-6, 6), vy = -12 - math.random(14),
        r = 1, life = 0.3 + math.random() * 0.2,
    }
end

function Fx.pearl(c, r)
    local x, y = Util.tilePx(c, r)
    pops[#pops + 1] = { x = x, y = y, life = 0.7 }
    Fx.bubbleBurst(x, y, 10)
end

function Fx.text(str, x, y)
    texts[#texts + 1] = { str = str, x = x, y = y, life = 0.9 }
end

function Fx.update(dt)
    for i = #bubbles, 1, -1 do
        local b = bubbles[i]
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bubbles, i)
        else
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            b.vy = b.vy + 8 * dt
        end
    end
    for i = #pops, 1, -1 do
        pops[i].life = pops[i].life - dt
        pops[i].y = pops[i].y - 18 * dt
        if pops[i].life <= 0 then table.remove(pops, i) end
    end
    for i = #texts, 1, -1 do
        texts[i].life = texts[i].life - dt
        texts[i].y = texts[i].y - 22 * dt
        if texts[i].life <= 0 then table.remove(texts, i) end
    end
    for _, a in ipairs(ambient) do
        a.y = a.y - a.v * dt
        if a.y < C.OY then
            a.y = C.H + math.random(0, 10)
            a.x = math.random(0, C.W)
        end
    end
end

function Fx.drawAmbient()
    for _, a in ipairs(ambient) do
        gfx.drawCircleAtPoint(a.x, a.y, a.r)
    end
end

function Fx.draw()
    for _, b in ipairs(bubbles) do
        gfx.drawCircleAtPoint(b.x, b.y, b.r)
    end
    for _, p in ipairs(pops) do
        local rr = 3 + (0.7 - p.life) * 10
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(p.x, p.y, math.max(rr, 2))
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(p.x, p.y, math.max(rr, 2))
        gfx.setColor(gfx.kColorWhite)
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    for _, tx in ipairs(texts) do
        local w = gfx.getTextSize(tx.str)
        gfx.drawText(tx.str, tx.x - w / 2, tx.y)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
