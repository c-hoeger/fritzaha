# Simple class to access Fritzbox functions

The provided `FritzAHA` ruby class implements access to the [AVM Home Automation HTTP Interface](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf) as well as to a small set of standard Fritzbox
functionality.

I started this library as a fun project to integrate my [Fritz!DECT200](https://avm.de/produkte/fritzdect/fritzdect-200/?pk_campaign=SEM-komplett&pk_kwd=FRITZ%21DECT) into [Munin](http://munin-monitoring.org).

![Temperature graphs of my Fritz!DECT200](dect200_munin.png)

The contained script can be used to utilize the implemented functionality, e.g. to toggle the powerswitch

```Text
$ fritzbox -l mylogin -c setswitchtoggle -a ainofswitch
```
