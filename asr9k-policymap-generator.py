#!/usr/bin/env python
'''
This script can be used to generate configurations for QOS profiles on IOS XR
'''
__author__ = 'arielweher'

import os
import argparse
import uuid

dlulratio=0.25

parser = argparse.ArgumentParser(description='QOS Profile Generator')
parser.add_argument('--name',help='Name of the QOS Map', required=False, default=str(uuid.uuid4().get_hex().upper()[0:12]))
parser.add_argument('--download', help='Download Bandwidth', required=True)
parser.add_argument('--upload',help='Upload Bandwidth', required=False, default=0)
parser.add_argument('--unit',help='Bandwidth unit', required=False, choices=['k', 'm', 'g','K','M','G'], default='k')
parser.add_argument('--nodsl',help='The profile is not meant to be used in a DSL network', required=False, choices=['y','n','Y','N'], default='n')
# Parse all arguments
args = parser.parse_args()

name=str(args.name)
dlbw=int(args.download)
ulbw=int(args.upload)
unit=str.lower(args.unit)
nodsl=str.lower(args.nodsl)

# We convert the bandwidth to kbps
if unit == 'm':
    dlbw=dlbw*1000
    ulbw=ulbw*1000
if unit == 'g':
    dlbw=dlbw*1000000
    ulbw=ulbw*1000000

if ulbw < 1:
    ulbw = dlbw * dlulratio

# DSL Headers Correction Factor (+15%)
if nodsl == 'n':
 dlbw=int(dlbw*1.15)
 ulbw=int(ulbw*1.15)

print "Input Parameters:"
print ("Name: %s" % name)
print ("Download Bandwidth: %s" % str(dlbw))
print ("Upload Bandwidth: %s" % str(ulbw))
print ("Unit: %sbps" % str(unit))
print ("Not meant to be xDSL: %s" % str.upper(nodsl))

def CreateProfile(name,down,up):
    print("")
    print("!!!!! START OF POLICY MAPS !!!!!")
    print("")
    print("policy-map child-%s-upload" % name)
    print(" class DC-4-QOS")
    print("  police rate %s kbps" % (ulbw*2))
    print("   conform-action transmit")
    print("   exceed-action drop")
    print("  !")
    print(" !")
    print(" class class-default")
    print("  police rate %s kbps" % ulbw)
    print("   conform-action transmit")
    print("   exceed-action drop")
    print("  !")
    print(" !")
    print(" end-policy-map")
    print("!")
    print("policy-map child-%s-download" % name)
    print(" class DC-4-QOS")
    print("  police rate %s kbps" % (dlbw*2))
    print("   conform-action transmit")
    print("   exceed-action drop")
    print("  !")
    print(" !")
    print(" class class-default")
    print("  police rate %s kbps" % dlbw)
    print("   conform-action transmit")
    print("   exceed-action drop")
    print("  !")
    print(" !")
    print(" end-policy-map")
    print("!")
    print("policy-map profile-%s-upload" % name)
    print(" class class-default")
    print("  service-policy child-%s-upload" %name)
    print(" !")
    print(" end-policy-map")
    print("!")
    print("policy-map profile-%s-download" % name)
    print(" class class-default")
    print("  service-policy child-%s-download" %name)
    print(" !")
    print(" end-policy-map")
    print("!")
    
CreateProfile(name,dlbw,ulbw)
