-- High-score (and last-picked species) persistence in the "clamjumper"
-- datastore.

Save = {}

function Save.load()
    local d = playdate.datastore.read("clamjumper")
    G.high = (d and d.high) or 0
    local idx = (d and d.species) or 1
    if idx < 1 or idx > #Species.order then idx = 1 end
    G.speciesIdx = idx
end

function Save.store()
    playdate.datastore.write({ high = G.high, species = G.speciesIdx }, "clamjumper")
end
