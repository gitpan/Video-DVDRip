# $Id: Makefile,v 1.11 2004/12/12 23:52:56 joern Exp $

all:	dr_splitpipe dr_progress

dr_splitpipe:	dr_splitpipe.c
	$(CC) $(CFLAGS) -o dr_splitpipe dr_splitpipe.c && mv dr_splitpipe ..

dr_progress:	dr_progress.c
	$(CC) $(CFLAGS) -o dr_progress dr_progress.c && mv dr_progress ..

clean:
	rm -f dr_splitpipe ../dr_splitpipe dr_progress ../dr_progress
