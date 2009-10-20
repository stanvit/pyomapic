#!/usr/bin/env python

from omapi import Omapi
import re

ipre = re.compile('^([0-9]{1,3}\.){3}[0-9]{1,3}$')
macre = re.compile('^([0-9a-fA-F]{1,2}\:){5}[0-9a-fA-F]{1,2}$')


class PyOMAPIc(Omapi):
	"""
	Python wrapper for C-based functions for OMAPI (DHCP)
	"""

	def _normalizeMac(self,mac):
		if not mac: return ''
		if not re.match(macre,mac): return mac
		try: return ":".join(map(lambda x:"%02x"%x,map(lambda x: int(x,16),mac.split(":"))))
		except: return mac
	
	def getLeaseMac(self,ip):
		"""
		Returns MAC-address for lease with selected IP-address
		"""
		return self._normalizeMac(self.lookup_lease_mac(ip))
	
	def getHostMac(self,ip):
		"""
		Returns MAC-address for host with selected IP-address
		"""
		return self._normalizeMac(self.lookup_host_mac(ip))
	
	def getMac(self,ip):
		"""
		Returns MAC-address for active lease, or for host if lease not found.
		"""
		result = self.getLeaseMac(ip)
		if result: return result
		return self.getHostMac(ip)
	
	def getHostsMacs(self,ips):
		"""
		Returns hosts list [(ip,mac),...] for IPs list
		"""
		result = []
		for ip in ips: result.append((ip,self.getHostMac(ip)))
		return result
	
	def getLeasesMacs(self,ips):
		"""
		Returns leases list [(ip,mac),...] for IPs list
		"""
		result = []
		for ip in ips: result.append((ip,self.getLeaseMac(ip)))
		return result
	
	def getMacs(self,ips):
		"""
		Returns hosts or leases list [(ip,mac),...] for IPs list
		"""
		result = []
		for ip in ips: result.append((ip,self.getMac(ip)))
		return result

	def addHost(self,ip,mac):
		"""
		Creates new host with specified MAC and IP addresses
		"""
		bip = self.lookup_host_ip(mac)
		if bip and bip != ip: raise ValueError("MAC address %s is already bound to %s"%(mac,bip))
		bmac = self.getHostMac(ip)
		if bmac and bmac != self._normalizeMac(mac): raise ValueError("IP address %s is already associated with the MAC %s"%(ip, bmac))
		if not bip == ip and not bmac == mac:
			self.add_host(ip, mac)
		return 'OK'
	
	def delHost(self,ip,mac=None):
		"""
		Deletes a host by specified IP/MAC
		"""
		self.del_host(mac,ip)
		return 'OK'
	
