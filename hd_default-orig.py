#!/usr/bin/env python
import sys
import os
import subprocess

# root filesystem
offset = "${offset 6}"
statb = subprocess.Popen("stat -f -c %b /", shell=True, stdout=subprocess.PIPE,)
statb_value = statb.communicate()[0]	
statf = subprocess.Popen("stat -f -c %f /", shell=True, stdout=subprocess.PIPE,)
statf_value = statf.communicate()[0]		
total = int(statb_value)
used = total - int(statf_value)
dec = (((used * 100) / total) + 5) / 10
if dec > 9:
	icon = "0"
elif dec < 1:
	icon = "A"
else:
	icon = str(dec)
print "Root:${color}${fs_used_perc /} %${color}${alignr}${fs_bar 5,45 /}"

# /home folder (if its a separate mount point)
if os.path.ismount("/home"):
	# start calculation for the pie chart symbol (icon)		
	statb = subprocess.Popen("stat -f -c %b /home", shell=True, stdout=subprocess.PIPE,)
	statb_value = statb.communicate()[0]	
	statf = subprocess.Popen("stat -f -c %f /home", shell=True, stdout=subprocess.PIPE,)
	statf_value = statf.communicate()[0]		
	total = int(statb_value)
	used = total - int(statf_value)
	dec = (((used * 100) / total) + 5) / 10
	if dec > 9:
		icon = "0"
	elif dec < 1:
		icon = "A"
	else:
		icon = str(dec)
	# end calculation icon
	print "Home:${color}${fs_used_perc /home} %${color}"

# folder in /media
for device in os.listdir("/media/"):
	if (not device.startswith("cdrom")) and (os.path.ismount('/media/'+device)):
		# start calculation dec value (for the pie chart symbol)		
		statb = subprocess.Popen('stat -f -c %b "/media/'+device+'"', shell=True, stdout=subprocess.PIPE,)
		statb_value = statb.communicate()[0]	
		statf = subprocess.Popen('stat -f -c %f "/media/'+device+'"', shell=True, stdout=subprocess.PIPE,)
		statf_value = statf.communicate()[0]		
		total = int(statb_value)
		used = total - int(statf_value)
		dec = (((used * 100) / total) + 5) / 10
		if dec > 9:
			icon = "0"
		elif dec < 1:
			icon = "A"
		else:
			icon = str(dec)
		# end calculation dec
		print device + ":${color}${fs_used_perc /media/"+device+"} %${color}"
