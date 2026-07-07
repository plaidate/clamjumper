-- Player-specific logic: getting bumped off a clam by the rival, and
-- getting caught by an eel (lose a life, respawn in the corner). A clamped
-- sea star cannot be bumped; an unclamped one keeps half its pry progress.

Player = {}

function Player.reset()
    G.player = Critter.spawn(Maze.startP[1], Maze.startP[2], "player", G.speciesKey)
    G.player.invuln = C.RESPAWN_INVULN
    G.pryClam = nil
end

-- knocked off the clam being pried: lose progress and get shoved back
function Player.bumped()
    local p = G.player
    if p.invuln > 0 or Critter.clamped(p) then return end
    local sp = Species.get(p.species)
    if G.pryClam then
        G.pryClam.pry = G.pryClam.pry * (sp.bumpKeep or 0)
        G.pryClam.open = G.pryClam.pry / sp.pryGoal
        G.pryClam = nil
    end
    p.stun = C.BUMP_STUN
    -- shove one tile away from the rival, if possible
    local bc = p.c - Util.sign(G.rival.c - p.c)
    if Maze.isOpen(bc, p.r) then
        p.px, p.py = Util.tilePx(bc, p.r)
        p.c = bc
    end
    -- a sea star's tube feet keep half the progress: call it out
    Fx.text((sp.bumpKeep or 0) > 0 and "HELD ON!" or "JUMPED!", p.px, p.py - 18)
    Fx.bubbleBurst(p.px, p.py, 8)
    Sfx.bump()
end

function Player.caught()
    local p = G.player
    G.lives = G.lives - 1
    G.pryClam = nil
    Fx.bubbleBurst(p.px, p.py, 16)
    Fx.text("OUCH!", p.px, p.py - 18)
    Sfx.hit()
    Harness.count("deaths")
    if G.lives <= 0 then
        Game.over()
    else
        -- respawn in the corner
        p.c, p.r = Maze.startP[1], Maze.startP[2]
        p.px, p.py = Util.tilePx(p.c, p.r)
        p.moving = false
        p.jumpT = 0
        p.glide = nil
        p.clampT = 0
        p.stun = 0
        p.invuln = C.RESPAWN_INVULN
    end
end
