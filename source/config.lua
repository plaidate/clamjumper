-- Tunables (C) and live state (G). A fixed 30fps step; the reef is a tile
-- grid, critters move tile-to-tile, the crank pries clams open. Per-species
-- stats (speed, pry goal/decay, ability numbers) live in species.lua.

C = {
    DT = 1 / 30,
    W = 400,
    H = 240,

    -- reef grid: 16x9 tiles of 24px, 8px left margin under a 24px HUD
    TILE = 24,
    COLS = 16,
    ROWS = 9,
    OX = 8,
    OY = 24,

    -- the rival runs at a fraction of its species' speed, rising per reef
    RIVAL_FACTOR = 0.73,
    RIVAL_FACTOR_STEP = 0.04,
    RIVAL_FACTOR_CAP = 0.93,

    JUMP_TIME = 0.3,     -- seconds of a hop/dash arc
    JUMP_HEIGHT = 16,

    RIVAL_PRY_TIME = 2.6,
    RIVAL_PRY_MIN = 1.2,
    BUMP_STUN = 0.6,

    INK_TIME = 2.0,      -- how long an ink puff lingers
    INK_STUN = 1.5,      -- stun on whoever wades into the other side's ink
    GLIDE_LAND_TIME = 0.18,

    EEL_STEP = 0.34,     -- seconds per tile
    EEL_STEP_MIN = 0.18,

    START_LIVES = 3,
    MAX_LIVES = 5,
    EXTRA_LIFE_EVERY = 10000,
    RESPAWN_INVULN = 2.0,

    CLAMS_BASE = 5,
    CLAMS_STEP = 1,
    CLAMS_CAP = 11,
    CORAL_DENSITY = 0.20,

    BONUS_TIME = 9,
    BONUS_EVERY = 2,     -- a pearl-rain bonus after every 2nd reef

    -- points
    PTS_PEARL = 100,
    PTS_REEF_CLEAR = 250,
    PTS_REEF_WIN = 1000,
    PTS_BONUS_CATCH = 75,
}

G = {
    state = "title", -- title | pick | intro | play | clear | bonus | gameover
    t = 0,
    reef = 1,
    score = 0,
    lives = 0,
    high = 0,
    nextLifeAt = C.EXTRA_LIFE_EVERY,
    speciesIdx = 1,
    speciesKey = "starfish",
}
