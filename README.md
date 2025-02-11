# What is Twopence

* Twopence is a test executor
* it can run tests in a KVM virtual machine without using the network
* it can also run more traditional SSH tests in a remote machine
* it can send the tests through a serial cable too

# How does Twopence work

* Twopence is basically a set of libraries
* shell, ruby, and python wrappers are provided for convenience
* each library is seen as a plugin,
* currenly available plugins are virtio (KVM), ssh, serial, and tcp

# How would I use it

Have a look at the examples:

* [from shell](examples/example.sh)
* [from Ruby](examples/example.rb)
* [from Python](examples/example.py)

# A note on security

* the test server runs on the system under test as root, performs no authentication,
  and will execute whatever command it is asked to
* the SSH tests assume that you have published a public key
  with a private key without passphrase
* in short, Twopence is very unsafe and should be reserved to
  pure test environments (test labs, no production servers)

# How do I compile it


* run the following commands as root (openSUSE/SLE):

```console
# zypper install libssh-devel ruby-devel rubygem-rake-compiler python-devel
```

* on Ubuntu:

```console
# apt-get install libssh-dev ruby-dev rake-compiler python-dev
```

* on Fedora
```console
# dnf install libssh-devel ruby-devel rubygem-rake-compiler python-devel redhat-rpm-config
```


* then run the following command, as a normal user:

```console
$ make
```

* and again as root user:

```console
$ make install
$ ldconfig
```

# How do I run the examples with SSH

* on the system under test, make sure the sshd damon is started:

```console
$ service sshd start
```

and that it is not being blocked by the firewall

* on the testing system, create a pair of SSH keys:

```console
$ ssh-keygen -t rsa
```

without setting a passphrase

* copy the public key t* the system under test:

```console
$ scp ~/.ssh/id_rsa.pub joe@sut.example.com:.
```
* then, on the system under test, append the public key t* the
  authorized keys file:

```console
cat id_rsa.pub >> ~/.ssh/authorized keys
```

* repeat for each account that will be used to run the tests
* in the directory `/usr/lib/twopence/`
  adapt the first lines of test.rb and test.sh to the IP address or hostname of your system under test
* run the following commands:

```console
$ cd examples
$ /usr/lib/twopence/test.sh
$ ruby /usr/lib/twopence/test.rb
```

# How do I run the examples with virtio

* setup a KVM virtual machine
* declare a UNIX domain socket
* to do that, you can use virt-manager:
  Hardware => Channel =>
  Path = the directory and name of your socket file
  Target type = virtio
  Target name = org.opensuse.twopence.0
* or you can use the provided script:

```console
$ /usr/lib/twopence/add_virtio_channel.sh mydomain
```

* (optional) create an isolated network so you can reach your VM:
  You can use the provided isolated.xml, or write your own:

  <network>
   <name>isolated</name>
     <ip address='192.168.254.1'
  netmask='255.255.255.0'>
     <dhcp>
       <range start='192.168.254.2'
  end='192.168.254.254' />
     </dhcp>
   </ip>
  </network>

  (if the 192.168.254.0/24 network is already in use
  elsewhere on your network, you can choose a
  different network).

* (optional) create the network, set it to autostart, and
start it:

```console
$ sudo virsh net-define isolated.xml
$ sudo virsh net-autostart isolated
$ sudo virsh net-start isolated
```
* (optional) Edit (using "virsh edit $guestname") the
configuration of each guest that uses direct
(macvtap) for its network connection and add a new
<interface> in the <devices> section similar to
the following:

```xml
   <interface type='network'>
     <source network='isolated'/>
     <model type='virtio'/>
   </interface>
```

Note: model is optional

* start the VM

* (optional) set up the isolated network:

```console
$ set the ip e.g. ip addr add 192.168.254.2/24 dev
ens10
$ ip link set ens10 up
```

* copy twopence into the VM (it is assumed you are running from the git project):

```console
$ rsync -avzp -e ssh . root@192.168.254.2:.
```

* inside the VM, install twopence, and be sure to have libssh-devel installed:

```console
$ sudo zypper install libssh-devel
$ sudo make install
```

*  inside of the VM, run the server as root:

```console
$ twopence_test_server
```

* in the directory `/usr/lib/twopence/`
  adapt the first lines of test.rb and test.sh
  to the name of the socket file you just created; for example:

```console
export TARGET=virtio:/var/run/twopence/test.sock
```

* run the following commands:

```console
$ cd examples
$ export LD_LIBRARY_PATH=../library
$ ruby /usr/lib/twopence/test.rb
```

* if you get error opening the communication,
  check the permissions of the socket file:

```console
$ ls -l /var/run/twopence/test.sock
```

# How do I run the examples with a serial cable

* connect a null-modem cable to the system under test
* connect the other end to the testing machine
* determine the port name on both ends
  (you can use "minicom" to do that)
* copy the test server into the system under test:

```console
$ scp /usr/lib/twopence/twopence_test_server root@sut.example.com:.
```

instead of scp, you may use shared folders or whichever method you prefer

* inside of the sut, run the server as root:

```console
$ ./twopence_test_server
```

* in the directory `/usr/lib/twopence/`
  adapt the first lines of test.rb and test.sh
  to the name of the character device; for example:

```console
export TARGET=serial:/dev/ttyS0
```

* run the following commands:

```console
$ cd examples
$ /usr/lib/twopence/test.sh
$ ruby /usr/lib/twopence/test.rb
```

* if you get error opening the communication,
  check the permissions of the character device file:

```console
$ ls -l /dev/ttyS0
```
