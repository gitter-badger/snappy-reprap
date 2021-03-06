OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
CONVERT=convert

PARTFILES=$(sort $(wildcard *_parts.scad))
TARGETS=$(patsubst %.scad,STLs/%.stl,${PARTFILES})
ROTFILES=$(shell seq -f 'wiki/snappy_rot%03g.png' 0 10 359.99)

all: ${TARGETS}

STLs/%.stl: %.scad config.scad GDMUtils.scad
	@if grep -q '^\s*!' $< ; then echo "Found uncommented exclamation mark(s) in source." ; grep -Hn '^\s*!' $< ; false ; fi
	${OPENSCAD} -m make -o $@ $<
	./stl_normalize.py -c $@ -o $@

pull:
	git pull --recurse-submodules

clean:
	rm -f tmp_*.png wiki/snappy_rot*.png

cleaner: clean
	rm -f ${TARGETS}

cleanwiki:
	rm -f wiki/snappy_*.gif wiki/snappy_*.png wiki/*_parts.png

${ROTFILES}: full_assembly.scad $(wildcard *.scad)
	${OPENSCAD} -o $(subst wiki/,tmp_,$@) --imgsize=1024,1024 \
	    --projection=p --csglimit=2000000 \
	    -D '$$t=$(shell echo $(patsubst wiki/snappy_rot%.png,%/360.0,$@) | bc -l)' \
	    -D '$$do_prerender=false' --camera=0,0,255,65,0,30,2200 $<
	${CONVERT} -strip -resize 512x512 $(subst wiki/,tmp_,$@) $@
	rm -f  $(subst wiki/,tmp_,$@)

wiki/%.png: %.scad config.scad GDMUtils.scad
	${OPENSCAD} -o $(subst wiki/,tmp_,$@) --render --imgsize=3200,3200 \
	    --projection=p --csglimit=2000000 --camera=0,0,50,65,0,30,2000 $<
	${CONVERT} -trim -resize 200x200 -border 10x10 -bordercolor '#ffffe5' $(subst wiki/,tmp_,$@) $@
	rm -f $(subst wiki/,tmp_,$@)

wiki/snappy_full.png: full_assembly.scad $(wildcard *.scad)
	${OPENSCAD} -o $(subst wiki/,tmp_,$@) --imgsize=3200,3200 --projection=p \
	    --csglimit=2000000 --camera=0,0,245,65,0,30,3000 -D '$$t=0.5' $<
	${CONVERT} -trim -resize 800x800 -border 10x10 -bordercolor '#ffffe5' $(subst wiki/,tmp_,$@) $@
	rm -f $(subst wiki/,tmp_,$@)

wiki/snappy_small.png: wiki/snappy_full.png
	${CONVERT} -trim -resize 200x200 -border 10x10 -bordercolor '#ffffe5' $< $@

wiki/snappy_animated.gif: ${ROTFILES}
	${CONVERT} -delay 10 -loop 0 ${ROTFILES} $@
	rm -f ${ROTFILES}

wiki/snappy_anim_small.gif: wiki/snappy_animated.gif
	${CONVERT} -resize 200x200 $< $@

renderparts: $(patsubst %.scad,wiki/%.png,${PARTFILES})
rendering: wiki/snappy_full.png wiki/snappy_small.png
animation: wiki/snappy_animated.gif wiki/snappy_anim_small.gif
wiki: rendering renderparts animation



# Dependencies follow.
STLs/cantilever_arm_parts.stl: joiners.scad
STLs/cantilever_joint_parts.stl: joiners.scad
STLs/drive_gear_parts.stl: publicDomainGearV1.1.scad
STLs/extruder_platform_parts.stl: joiners.scad
STLs/motor_mount_plate_parts.stl: joiners.scad NEMA.scad
STLs/rail_endcap_parts.stl: joiners.scad
STLs/rail_motor_segment_parts.stl: joiners.scad
STLs/rail_segment_parts.stl: joiners.scad
STLs/sled_endcap_parts.stl: joiners.scad
STLs/sled_parts.stl: joiners.scad publicDomainGearV1.1.scad
STLs/support_leg_parts.stl: joiners.scad
STLs/xy_joiner_parts.stl: joiners.scad
STLs/yz_joiner_parts.stl: joiners.scad
