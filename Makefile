CFLAGS=-g -Wall -W -fPIC -I/usr/include/python2.4
LDLIBS=-ldhcpctl -lomapi -ldst

all: omapi_wrap.o base64.o
	gcc -shared omapi_wrap.o base64.o $(LDLIBS) -o _omapi.so
	
omapi_wrap.c: omapi.i
	swig -python omapi.i

clean:
	rm -f *.so *.pyc *.o omapi_wrap.c omapi.py
	rm -rf build
	

