# $Id: Makefile,v 1.9 2002/09/01 15:57:09 joern Exp $

all:	dr_splitpipe dr_progress

dr_splitpipe:	dr_splitpipe.c
	cc -o dr_splitpipe dr_splitpipe.c && mv dr_splitpipe ..

dr_progress:	dr_progress.c
	cc -o dr_progress dr_progress.c && mv dr_progress ..

clean:
	rm -f dr_splitpipe ../dr_splitpipe dr_progress ../dr_progress
