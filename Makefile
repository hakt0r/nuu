
all:
	coffee tools/build.coffee run

sysgen:
	coffee tools/build.coffee sysgen

debug-brk:
	# coffee --nodejs debug tools/build.coffee run
	coffee -o build server/*.coffee
	nodejs --debug-brk build/server.js

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
