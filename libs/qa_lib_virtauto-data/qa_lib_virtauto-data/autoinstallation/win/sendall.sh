#!/bin/bash

### Sends autoinstall files to their appropriate locations ###

os=2k
sp=sp4
arch=32
archb=i386
archc=I386
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=2k3
sp=sp2
arch=32
archb=i386
archc=I386
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=2k3
sp=sp2
arch=64
archb=x86_64
archc=AMD64
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=xp
sp=sp2
arch=32
archb=i386
archc=I386
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=xp
sp=sp2
arch=64
archb=x86_64
archc=AMD64
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=xp
sp=sp3
arch=32
archb=i386
archc=I386
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"

os=xp
sp=sp3
arch=64
archb=x86_64
archc=AMD64
virt=fv
file=def
fileb=WINNT.SIF

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${sp}/${archb}-rw/${archc}/${fileb}"


os=2k8
sp=fcs
spa=beta
arch=32
archb=i386
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=2k8
sp=fcs
spa=beta
arch=64
archb=x86_64
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=2k8
sp=fcs
spa=fcs
arch=32
archb=i386
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=2k8
sp=fcs
spa=fcs
arch=64
archb=x86_64
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=vista
sp=fcs
spa=fcs
arch=32
archb=i386
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=vista
sp=fcs
spa=fcs
arch=64
archb=x86_64
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=vista
sp=sp1
spa=sp1
arch=32
archb=i386
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

os=vista
sp=sp1
spa=sp1
arch=64
archb=x86_64
virt=fv
file=def
fileb=autounattend.xml

scp ${os}/${sp}/${arch}/${virt}/${file} root@151.155.144.100:/share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}
ssh root@151.155.144.100 "chmod 555 /share/winmakeauto/${os}-${spa}/${archb}-rw/${fileb}"

