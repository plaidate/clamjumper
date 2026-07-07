-- The cast: three clam-hunting specialists. Each entry is a full stat sheet
-- read by the critter chassis (speed, pry profile) plus the numbers for its
-- signature A-button ability. pips are the pick-screen bars: speed/pry/agility.

Species = {}

Species.order = { "starfish", "octopus", "ray" }

Species.defs = {
    starfish = {
        name = "SEA STAR",
        blurb1 = "EASY PRY - BUMPS ONLY HALVE IT",
        blurb2 = "A CLAMPS DOWN - BUT NO HOP AT ALL",
        speed = 70, pryGoal = 420, pryDecay = 90, bumpKeep = 0.5,
        ability = "clamp",
        clampTime = 1.2, clampCool = 4.0,
        pips = { 1, 3, 1 },
    },
    octopus = {
        name = "OCTOPUS",
        blurb1 = "QUICK - BUT PRY PROGRESS FADES FAST",
        blurb2 = "A JETS 3 TILES AND INKS THE RIVAL",
        speed = 92, pryGoal = 540, pryDecay = 320, bumpKeep = 0,
        ability = "dash",
        dashTiles = 3, dashTime = 0.32, dashCool = 0.7,
        pips = { 3, 2, 3 },
    },
    ray = {
        name = "RAY",
        blurb1 = "HOLD A TO GLIDE OVER EVERYTHING",
        blurb2 = "LAND ON A CLAM TO SLAM IT PART-OPEN",
        speed = 86, pryGoal = 480, pryDecay = 200, bumpKeep = 0,
        ability = "glide",
        glideTiles = 4, glideSpeed = 150, glideCoolPerTile = 0.3,
        slamCredit = 120,
        pips = { 2, 2, 3 },
    },
}

function Species.get(key)
    return Species.defs[key]
end
