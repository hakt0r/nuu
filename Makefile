
all:
	coffee tools/build.coffee run

clean:
	coffee tools/build.coffee clean

dist-clean:
	coffee tools/build.coffee dist_clean

init: dist-clean
	npm install
	make clean
	make

debug:
	coffee tools/build.coffee debug
