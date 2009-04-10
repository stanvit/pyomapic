/*    Base64 encode/decode
 *    Copyright (C) 2005  Perry Lorier
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Compile with -DTEST for a standalone test program
 */

#include <stdlib.h>
#include <inttypes.h>
#include <string.h>

typedef unsigned char uchar_t;
uchar_t *base64_encode(const uchar_t *buf, size_t len)
{
	const unsigned char *str="ABCDEFGHJIKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	uchar_t *ret=malloc((len*4+2)/3+1);
	const uchar_t *cp=buf;
	uchar_t *out=ret;
	while(len>2) {
		uint32_t val=(cp[0]<<16)|(cp[1]<<8)|(cp[2]);
		cp+=3;
		len-=3;

		/* AAAAAAxx xxxxxxxx xxxxxxxx */	
		*(out++)=str[(val>>18)&0x3F];

		/* xxxxxxAA AAAAxxxx xxxxxxxx */
		*(out++)=str[(val>>12)&0x3F];

		/* xxxxxxxx xxxxAAAA AAxxxxxx */
		*(out++)=str[(val>> 6)&0x3F];

		/* xxxxxxxx xxxxxxxx xxAAAAAA */
		*(out++)=str[(val    )&0x3F];
	}

	if (len == 2) {
		uint32_t val=(cp[0]<<16)|(cp[1]<<8);
		cp+=2;
		len-=2;

		/* AAAAAAxx xxxxxxxx xxxxxxxx */	
		*(out++)=str[(val>>18)&0x3F];

		/* xxxxxxAA AAAAxxxx xxxxxxxx */
		*(out++)=str[(val>>12)&0x3F];

		/* xxxxxxxx xxxxAAAA AAxxxxxx */
		*(out++)=str[(val>> 6)&0x3F];

		/* xxxxxxxx xxxxxxxx xxAAAAAA */
		*(out++)='=';
	}
	else if (len == 1) {
		uint32_t val=(cp[0]<<16);
		cp+=2;
		len-=2;

		/* AAAAAAxx xxxxxxxx xxxxxxxx */	
		*(out++)=str[(val>>18)&0x3F];

		/* xxxxxxAA AAAAxxxx xxxxxxxx */
		*(out++)=str[(val>>12)&0x3F];

		/* xxxxxxxx xxxxAAAA AAxxxxxx */
		*(out++)='=';

		/* xxxxxxxx xxxxxxxx xxAAAAAA */
		*(out++)='=';
	}

	*(out++)='\0'; /* remember to NUL terminate the string */

	return ret;
}

const uchar_t base64_decode_matrix[] = { 
/*	 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F          */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0x00 */
	99,99,99,99,99,99,99,99,99,99,99,62,63,99,99,99, /* 0x10 */
	99,99,99,99,99,99,99,99,99,99,99,62,63,99,99,99, /* 0x20 */
	52,53,54,55,56,57,58,59,60,61,99,99,99,99,99,99, /* 0x30 */
	99, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14, /* 0x40 */
	15,16,17,18,19,20,21,22,23,24,25,99,99,99,99,99, /* 0x50 */
	99,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40, /* 0x60 */
	41,42,43,44,45,46,47,48,49,50,51,99,99,99,99,99, /* 0x70 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0x80 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0x90 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0xA0 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0xB0 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0xC0 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0xD0 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99, /* 0xE0 */
	99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99  /* 0xF0 */
	};

void base64_decode(const uchar_t *in, uchar_t **out, int *outlen)
{
	int inlen = strlen(in);
	int i;
	int j=0;

	if (inlen < 2) {
		*out=malloc(0);
		*outlen=0;
		return;
	}

	if (in[inlen-2]=='=') {
		*outlen=inlen*3/4-2;
	}
	else if (in[inlen-1]=='=') {
		*outlen=inlen*3/4-1;
	}
	else {
		*outlen=inlen*3/4;
	}
	*out=malloc(*outlen);
	for(i=0;i<inlen;) {
		int val=0;
		/* Skip invalid charactors (eg whitespace) */
		while (i<inlen && base64_decode_matrix[in[i]]==99) {
			++i;
		}
		if (i>=inlen)
			break;
		val=base64_decode_matrix[in[i++]]<<18;
		/* Skip invalid charactors (eg whitespace) */
		while (i<inlen && base64_decode_matrix[in[i]]==99) {
			++i;
		}
		if (i>=inlen)
			break;

		val|=base64_decode_matrix[in[i++]]<<12;
		(*out)[j++]=val>>16;
		
		/* Skip invalid charactors (eg whitespace) */
		while (i<inlen && base64_decode_matrix[in[i]]==99) {
			++i;
		}
		if (i>=inlen)
			break;

		val|=base64_decode_matrix[in[i++]]<<6;
		(*out)[j++]=val>>8;

		/* Skip invalid charactors (eg whitespace) */
		while (i<inlen && base64_decode_matrix[in[i]]==99) {
			++i;
		}
		if (i>=inlen)
			break;

		val|=base64_decode_matrix[in[i++]];
		(*out)[j++]=val;

	}
}

#ifdef TEST
#include <stdio.h>

int main(int argc, char *argv[])
{
	uchar_t *buf;
	int len;
	if (argc<2) {
		fprintf(stderr,"Usage: base64 string\n");
		return 1;
	}
	printf("%s\n",base64_encode(argv[1],strlen(argv[1])));
	base64_decode(base64_encode(argv[1],strlen(argv[1])),&buf,&len);
	printf("%s\n",buf);

	return 0;
}
#endif
