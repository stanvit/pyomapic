Heavily based on Python OMAPI (DHCP) Interface by Perry Lorier, Matt Brown 
perry@coders.net,matt@mattb.net.nz, downloaded from http://source.meta.net.nz/svn/dhcparpd/trunk/pyomapi/

Fixed for our local WestCall needs by Stas Vitkovsky <stas.vitkovsky@gmail.com>

On amd64 (x86_64) platforms you should have libomapi, libds and libdst compiled
with the -fPIC option, but at least in the Debian Lenny they're not. So you need to recompile 
the dhcp3-dev package adding the -fPIC option to the CFLAGS in its debian/rules.


Many thanks to Ignace Mouzannar (-ghantoos-) for his article on creating a deb from python distutils.
http://ghantoos.org/2008/10/19/creating-a-deb-package-from-a-python-setuppy/
I thought it was easier :)

