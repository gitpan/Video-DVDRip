# $Id: Makefile,v 1.12 2005/10/09 11:26:10 joern Exp $

all:	../bin/dvdrip-splitpipe ../bin/dvdrip-progress

../bin/dvdrip-splitpipe:	dvdrip-splitpipe.c
	$(CC) $(CFLAGS) -o dvdrip-splitpipe dvdrip-splitpipe.c && mv dvdrip-splitpipe ../bin

../bin/dvdrip-progress:	dvdrip-progress.c
	$(CC) $(CFLAGS) -o dvdrip-progress dvdrip-progress.c && mv dvdrip-progress ../bin

clean:
	rm -f dvdrip-splitpipe ../bin/dvdrip-splitpipe dvdrip-progress ../bin/dvdrip-progress
