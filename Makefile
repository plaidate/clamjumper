# Clam Jumper — an ocean-bed maze race for Playdate.
#
#   make            release build -> out/ClamJumper.pdx
#   make smoke      instrumented build -> out/ClamJumperSmoke.pdx
#
# Staging copies source/* into build/<variant>/source and writes
# smokeflag.lua (pdc wants one source root; smokeflag is generated).

OUT := out

all: release

release: build/release/source
	pdc build/release/source $(OUT)/ClamJumper.pdx

smoke: build/smoke/source
	pdc build/smoke/source $(OUT)/ClamJumperSmoke.pdx

build/release/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = false' > $@/smokeflag.lua

build/smoke/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = true' > $@/smokeflag.lua
	echo 'SMOKE_SPECIES = $(if $(SMOKE_SPECIES),$(SMOKE_SPECIES),false)' >> $@/smokeflag.lua

clean:
	rm -rf build $(OUT)

.PHONY: all release smoke clean
