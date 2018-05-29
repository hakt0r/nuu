
update-demo:
	ssh root@rop.hktr.de '\
		cd /var/www/nuu;    \
		killall node;       \
		git pull;           \
		coffee tools/build.coffee run >/dev/null 2>&1 </dev/null &! \
		exit 0'

push:
	git push
	make update-demo

all:
	coffee tools/build.coffee run

sysgen:
	coffee tools/build.coffee sysgen

debug-brk:
	coffee tools/build.coffee assets
	nodejs --inspect-brk build/server.js

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
