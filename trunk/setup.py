#!/usr/bin/env python

from distutils.core import setup,Extension

_omapi = Extension('_omapi',
	sources = ['omapi.i', 'base64.c'],
	libraries = ['dhcpctl', 'omapi', 'dst'],
)

setup(name="PyOMAPIc",
	version="2.0",
	description="Python OMAPI (DHCP) Interface",
	author="Stas (Stanislav) Vitkovsky",
	author_email="stas.vitkovsky@gmail.com",
	url="http://code.google.com/p/pyomapic/",
	ext_modules=[_omapi],
	py_modules=['omapi','PyOMAPIc'],
)


