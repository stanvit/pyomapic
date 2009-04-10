#!/usr/bin/env python

from omapi import Omapi
import sre
import logging
from logging import handlers

log = logging.Logger('PyOMAPIc')
syslog = logging.handlers.SysLogHandler(address='/dev/log',facility=3)
fmt = logging.Formatter("%(name)s %(levelname)s: %(message)s")
syslog.setFormatter(fmt)
log.addHandler(syslog)

def logDecorator(fun):
	def wrapper(*args, **kwargs):
		log.debug("Called function %s(%s)"%(fun.__name__ , ', '.join(map(str,args[1:]))))
		return fun(*args, **kwargs)
	return wrapper

def regexDecorator(*regexes):
	"""Decorator, cheking function arguments against regexes.
	Use multiple arguments, which may be strings with valid regular expressions, compiled regexes or None
	if no check desired.

	example usage:

	@regexDecorator(None,"^[0-9]+$","^[a-z]")
	def foo(self,number,name):
		....
	"""
	regexes = list(regexes)
	regexes.reverse()
	def decorator(fun):
		def wrapper(*args):
			"""
			If youl like to see documentation for this function, you must 
			view source code, sorry
			"""
			for arg in args:
				try: regex = regexes.pop()
				except IndexError: continue
				if not regex: continue
				if not sre.match(regex, arg): raise ValueError("Wrong argument value %s in function %s"%(str(arg),fun.__name_))
			return fun(*args)
		return wrapper
	return decorator


class PyOMAPIc(Omapi):
	"""
	Python wrapper for C-based functions for OMAPI (DHCP)
	"""

	ipre = sre.compile('^([0-9]{1,3}\.){3}[0-9]{1,3}$')
	macre = sre.compile('^([0-9a-zA-Z]{1,2}\:){5}[0-9a-zA-Z]{1,2}$')

	def _normalizeMac(self,mac):
		if not mac: return ''
		if not sre.match(self.macre,mac): return mac
		return ":".join(map(lambda x:"%02x"%x,map(lambda x: int(x,16),mac.split(":"))))
	
	#@regexDecorator(None,ipre)
	def getLeaseMac(self,ip):
		"""
		Returns MAC-address for lease with selected IP-address
		"""
		return self._normalizeMac(self.lookup_lease_mac(ip))
	
	#@regexDecorator(None,ipre)
	def getHostMac(self,ip):
		"""
		Returns MAC-address for host with selected IP-address
		"""
		return self._normalizeMac(self.lookup_host_mac(ip))
	
	def getHostsMacs(self,ips):
		"""
		Returns list [(ip,mac),...] for IPs list
		ONLY hosts, NO leases.
		This method made for fetching of user's settings.
		"""
		result = []
		for ip in ips: result.append((ip,self.getHostMac(ip)))
		return result

	def getMac(self,ip):
		"""
		Returns MAC-address for active lease, or for host if lease not found.
		"""
		result = self.getLeaseMac(ip)
		if result: return result
		return self.getHostMac(ip)

	@regexDecorator(None,ipre,macre)
	@logDecorator
	def addHost(self,ip,mac):
		"""
		Creates new host with specified mac and ip addresses
		"""
		bip = self.lookup_host_ip(mac)
		if bip and bip != ip: raise ValueError("MAC address %s is already bound to %s"%(mac,bip))
		bmac = self.getHostMac(ip)
		if bmac and bmac != self._normalizeMac(mac): raise ValueError("IP address %s already associated with MAC %s"%(ip, bmac))
		if not bip == ip and not bmac == mac:
			self.add_host(ip, mac)
		return 'OK'
	
	#@regexDecorator(None,ipre)
	def delHost(self,ip):
		"""
		Delete host by specified IP-address.
		"""
		self.del_host(None,ip)
		return 'OK'
	

if __name__ == '__main__':
	o = PyOMAPIc('192.168.133.7',7911,'HOMENET_UPDATER', 'SXu4oFVcrD1WaNzlmlWl1Q==')
	#print o.getLeaseMac('172.22.12.30')
	#print o.getHostMac('172.22.12.5')
	#print o.getMac('172.22.12.30')
	#print o.getMac('172.22.12.5')
	#print o.addHost('172.22.12.6','11:20:03:4:5:6')
	#print o.addHost('172.22.12.10','11:20:03:4:5:7')
	#print o.delHost('172.22.12.6')
	#print o.getHostsMacs(['172.22.12.4','172.22.12.5','172.22.12.6'])

