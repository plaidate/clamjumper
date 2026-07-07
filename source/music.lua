-- A sparse ocean groove: a clock-driven step sequencer (accumulate dt,
-- fire on step boundaries — no drift) that plays under the reef and the
-- bonus round. A soft triangle bass walks root/fifth; a quiet sine pluck
-- sketches minor-pentatonic notes. The root rises with the reef.

local snd <const> = playdate.sound

Music = {}

local bass = snd.synth.new(snd.kWaveTriangle)
local pluck = snd.synth.new(snd.kWaveSine)

local STEP = 0.24            -- seconds per step, 8 steps to a bar
local ROOTS = { 110.00, 98.00, 123.47, 130.81 } -- A2 G2 B2 C3, per reef
local PENTA = { 1.0, 1.1892, 1.3348, 1.4983, 1.7818 } -- minor pentatonic
-- bass degrees per step (0 = rest); bar B alternates in a low fifth
local BASS_A = { 1, 0, 0, 0, 4, 0, 0, 0 }
local BASS_B = { 1, 0, 0, 4, 0, 0, 2, 0 }
-- pluck degrees per step across a 2-bar phrase (0 = rest)
local PLUCK = { 0, 0, 3, 0, 0, 5, 0, 0, 0, 2, 0, 4, 0, 0, 3, 0 }

local acc, step = 0, 0

function Music.reset()
    acc, step = 0, 0
end

function Music.update(dt, active)
    if not active then return end
    acc = acc + dt
    while acc >= STEP do
        acc = acc - STEP
        step = step + 1
        local root = ROOTS[(G.reef - 1) % #ROOTS + 1]
        local s8 = (step - 1) % 8 + 1
        local s16 = (step - 1) % 16 + 1
        local bar = (step - 1) // 8
        local bp = (bar % 2 == 0) and BASS_A or BASS_B
        if bp[s8] > 0 then
            -- fifths sit below the root so the bass stays out of the way
            local f = root * PENTA[bp[s8]]
            if bp[s8] > 1 then f = f / 2 end
            bass:playNote(f, 0.09, STEP * 1.8)
        end
        if PLUCK[s16] > 0 then
            pluck:playNote(root * 2 * PENTA[PLUCK[s16]], 0.05, STEP * 0.9)
        end
    end
end
