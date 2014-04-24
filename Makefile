# GNUMakefile
RSYNC=/usr/bin/rsync \
	--exclude NOBACKUP/ \
	--exclude LOCAL/ \
	--exclude local/ \
	--exclude tmp/ \
	--exclude obj/ \
	--exclude Makefile \
	--exclude '.??*' \
	--exclude '*~'

PROJECT=vgaplayer
WWWBASE=../../euske.github.io/$(PROJECT)/

all:

clean:

upload: bin
	-$(RSYNC) -rutv bin/ $(WWWBASE)/
