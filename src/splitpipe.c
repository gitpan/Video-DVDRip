/* $Id: splitpipe.c,v 1.5 2001/11/23 20:21:52 joern Exp $
 *
 * Copyright (C) 2001 Jörn Reder <joern@zyn.de> All Rights Reserved
 * 
 * This program is part of Video::DVDRip, which is free software; you can
 * redistribute it and/or modify it under the same terms as Perl itself.
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define BUFSIZE 1024*1024

/* function prototypes */
void usage (void);
void split_pipe ( int chunk_size, char* base_filename, char* extension );
int  open_split_file( int old_fd, int chunk_cnt, char* base_filename, char* extension );
void write_split_file ( int split_fd, char* buffer, size_t cnt );

/* print usage */
void usage (void) {
	printf ("usage: splitpipe size-in-mb base-filename extension\n\n");
	exit(1);
}

/* main function */
int main(int argc, char *argv[]) {
	int    chunk_size;
	char*  base_filename;
	char*  extension;
	int    ok;

	if ( argc != 4 ) usage();
	
	ok = sscanf (argv[1], "%d", &chunk_size);
	
	if ( ok != 1 )   usage();
	
	base_filename = argv[2];
	extension     = argv[3];
	
	split_pipe ( chunk_size, base_filename, extension);
	
	fprintf (stderr, "--splitpipe-finished--\n");

	return 0;
}

/* split and pipe */
void split_pipe ( int chunk_size, char* base_filename, char* extension ) {
	char	buffer[BUFSIZE];
	int	file_cnt = 1;
	int	split_fd;
	size_t	bytes_read;
	size_t	bytes_written = 0;
	size_t	bytes_this_chunk;
	size_t	bytes_next_chunk;
	
	chunk_size *= 1024*1024;

	split_fd = open_split_file (
		-1, file_cnt, base_filename, extension
	);

	while ( bytes_read = read (0, buffer, BUFSIZE) ) {
		/* echo chunk to stdout */
		write (1, buffer, bytes_read);
		
		/* echo progress information to stderr */
		fprintf (stderr, "%d-%d\n", file_cnt, bytes_written);

		/* check if we need to open a new file */
		if ( bytes_written + bytes_read > chunk_size ) {
			bytes_this_chunk = chunk_size-bytes_written;
			bytes_next_chunk = bytes_read-bytes_this_chunk;

			write_split_file (split_fd, buffer, bytes_this_chunk);

			++file_cnt;
			split_fd = open_split_file (
				split_fd, file_cnt, base_filename, extension
			);

			write_split_file (split_fd, buffer+bytes_this_chunk, bytes_next_chunk);
			bytes_written = bytes_next_chunk;

		} else {
			write_split_file (split_fd, buffer, bytes_read);
			bytes_written += bytes_read;
		}
	}
	
	close (split_fd);
}

/* write data to split file */
void write_split_file ( int split_fd, char* buffer, size_t cnt ) {
	if ( -1 == write (split_fd, buffer, cnt) ) {
		fprintf (stderr, "Can't write to split file.\n");
		exit (1);
	}
}

/* open a new split file */
int open_split_file( int old_fd, int chunk_cnt,
		     char* base_filename, char* extension ) {
	char	filename[255];
	int	new_fd;

	if ( old_fd != -1 ) {
		/* ok, first close last split file */
		close (old_fd);
	}
	
	/* now open a new split file */
	sprintf (filename, "%s-%03d.%s", base_filename, chunk_cnt, extension);
	
	new_fd = creat (filename, 0644);
	
	if ( -1 == new_fd ) {
		fprintf (stderr, "Can't create file %s\n", filename);
		exit (1);
	}
	
	return new_fd;
}
