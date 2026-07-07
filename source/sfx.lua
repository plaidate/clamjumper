-- Synth sound effects: a bubbly ocean kit.

local snd <const> = playdate.sound

Sfx = {}

local tri = snd.synth.new(snd.kWaveTriangle)
local tri2 = snd.synth.new(snd.kWaveTriangle)
local sq = snd.synth.new(snd.kWaveSquare)
local saw = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)

function Sfx.blip(f)
    tri:playNote(f or 660, 0.25, 0.04)
end

function Sfx.step()
    tri2:playNote(520, 0.12, 0.02)
end

-- a rising bubble as the clam is pried
function Sfx.pry(prog)
    tri2:playNote(400 + prog * 500, 0.2, 0.03)
end

function Sfx.pearl()
    for i = 0, 3 do
        Util.after(i * 0.05, function() tri:playNote(700 + i * 220, 0.3, 0.05) end)
    end
end

function Sfx.jump()
    saw:playNote(300, 0.25, 0.12)
    Util.after(0.05, function() saw:playNote(520, 0.2, 0.06) end)
end

function Sfx.bump()
    noise:playNote(180, 0.4, 0.1)
end

-- the sea star's suction clamp: a low double thunk
function Sfx.clamp()
    sq:playNote(140, 0.3, 0.12)
    Util.after(0.06, function() sq:playNote(90, 0.25, 0.1) end)
end

-- the ray lifting off: a soft swoosh
function Sfx.glide()
    saw:playNote(240, 0.16, 0.3)
end

-- the ray's wing-slam onto a clam
function Sfx.slam()
    noise:playNote(220, 0.35, 0.08)
    Util.after(0.05, function() tri:playNote(880, 0.25, 0.06) end)
end

function Sfx.hit()
    noise:playNote(90, 0.5, 0.5)
    Util.after(0.1, function() saw:playNote(140, 0.4, 0.3) end)
end

function Sfx.fanfare(notes, step)
    notes = notes or { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * (step or 0.1), function() tri:playNote(n, 0.3, (step or 0.1) * 1.4) end)
    end
end

function Sfx.lose()
    Sfx.fanfare({ 494, 415, 349, 262 }, 0.14)
end

-- delayed-call scheduler lives here so sfx multi-notes work everywhere
local pending = {}
function Util.after(delay, fn)
    pending[#pending + 1] = { t = delay, fn = fn }
end
function Util.runPending(dt)
    for i = #pending, 1, -1 do
        local p = pending[i]
        p.t = p.t - dt
        if p.t <= 0 then
            table.remove(pending, i)
            p.fn()
        end
    end
end
