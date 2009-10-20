PYTHON=`which python`
DESTDIR=/
BUILDIR=$(CURDIR)/debian/python-omapic
PROJECT=python-opmapic
VERSION=1.99

PYTHON_CFLAGS=$(shell python-config --cflags)
LIBS=-ldhcpctl -lomapi -ldst
CFLAGS=-fPIC $(PYTHON_CFLAGS) $(LIBS)

all:
	@echo "make src - Create source package"
	@echo "make install - Install on local system"
	@echo "make rpm - Generate a rpm package"
	@echo "make deb - Generate a deb package"
	@echo "make here - compile all the libraries here"
	@echo "make clean - Get rid of scratch and byte files"

src:
	$(PYTHON) setup.py sdist $(COMPILE)

install:
	$(PYTHON) setup.py install --root $(DESTDIR) $(COMPILE)

rpm:
	$(PYTHON) setup.py bdist_rpm --post-install=rpm/postinstall --pre-uninstall=rpm/preuninstall

deb:
	# build the source package in the parent directory
	# then rename it to project_version.orig.tar.gz
	$(PYTHON) setup.py sdist $(COMPILE) --dist-dir=../ --prune
	rename -f 's/$(PROJECT)-(.*)\.tar\.gz/$(PROJECT)_$$1\.orig\.tar\.gz/' ../*
	# build the package
	dpkg-buildpackage -i -I -rfakeroot

clean:
	$(PYTHON) setup.py clean
	$(MAKE) -f $(CURDIR)/debian/rules clean
	rm -rf build/ MANIFEST
	rm -f *.so *.o omapi_wrap.c omapi.py
	find . -name '*.pyc' -delete


here: omapi_wrap.o base64.o
	gcc -shared omapi_wrap.o base64.o $(LIBS) -o _omapi.so

omapi_wrap.c: omapi.i
	swig -python omapi.i

	
