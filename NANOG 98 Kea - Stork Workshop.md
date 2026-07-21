# NANOG 98 Kea / Stork Workshop
This document is for the hands-on portion of the workshop where participants will perform several administrative functions related to Kea and Stork.  This is intended to simulate real world installation, setup, and testing of a Kea and Stork platform.

More information about Kea and Stork are available at https://www.isc.org/

## Overview
The following are the exercises that will be covered in this document.  The presenters will demonstrate a step, and then the workshop participants will perform the step.  The participants should, by now, have access to four Virtual Machines: "kea1", "kea2", "client", and "stork".  "kea1" and "kea2" will, by the end of the workshop, run `kea-dhcp4`, `kea-dhcp6` (each in an HA relationship between "kea1" and "kea2"), and `stork-agent`.  "client" will, by the end of the workshop, run `perfdhcp` by command-line invocation.  This will be used to simulate DHCP clients for various tests.  "stork" will, by the end of the workshop, run `stork-server`.  This will be used to administrate the Kea installations.

#### Exercises to be performed

1. Install the Kea software on "kea1", "kea2", and `perfdhcp` on "client".
2. Add a `kea-dhcp4` configuration to "kea1" and "kea2".  Start `kea-dhcp4` on both servers.  Test `kea-dhcp4` using `perfdhcp` from the "client" machine only to confirm it is functional. 
3. Add a `kea-dhcp6` configuration to "kea1" and "kea2".  Start `kea-dhcp4` on both servers.  Test `kea-dhcp6` using `perfdhcp` from the "client" machine only to confirm it is functional. 
4. Install `stork-server` on "stork" in this exercise.  Start `stork-server`.  Log in to the `stork-server` and set a password.
5. Install `stork-agent` on "kea1" and "kea2".  Register the `stork-agent` on each with `stork-server`.  Start `stork-agent`. Authorize the `stork-agent` from "kea1" and "kea2" on "stork".
6. Simulate client traffic using `perfdhcp` on "client" to both `kea-dhcp4` and `kea-dhcp6`.  Learn about various reporting in the Stork UI.
7. Simulate more client traffic as in exercise 6.  Experiment with HA and reporting of this in the Stork UI by stopping `kea-dhcp4` and `kea-dhcp6` on "kea1".
8. Add a new subnet to "kea1" and "kea2" using the Stork UI.

## The Exercises
The presenters will now take the participants through each exercise.  Please wait until the presenters finish and tell you to perform an exercise before proceeding however tempting it may be to work ahead.  An additional presenter is available in the room to provide personal if you should have problems.  Raise your hand to get this person's attention and they will come over to help you.  If you have not been able to log in to the Virtual Machines provided for this workshop, now would be a good time to ask for help from the presenter circulating in the room.

### Exercise 1
Install the Kea software on "kea1", "kea2", and `perfdhcp` on "client".

1. Add the repository on "kea1", "kea2" and "client":

```
curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-3-0/setup.deb.sh' | sudo -E bash
```

2. Install the `isc-kea` package on "kea1" and "kea2":

```
apt install isc-kea
```

3. Install the `perfdhcp` package on "client":

```
apt install isc-kea-perfdhcp
```

### Exercise 2
Configure, start, and test `kea-dhcp4` on "kea1" and "kea2".

1. Copy the `kea-dhcp4` configuration:

```
{
  "Dhcp4": {
    "control-socket": {
      "socket-type": "unix",
      "socket-name": "socket4"
    },
    "interfaces-config": {
      "interfaces": [
        "eth1"
      ]
    },
    "lease-database": {
      "type": "memfile",
      "name": "leases4.csv"
    },
    "hooks-libraries": [
      {
        "library": "libdhcp_lease_cmds.so"
      },
      {
        "library": "libdhcp_stat_cmds.so"
      },
      {
        "library": "libdhcp_subnet_cmds.so"
      },
      {
        "library": "libdhcp_ha.so",
        "parameters": {
          "high-availability": [
            {
              "this-server-name": "server1",
              "mode": "hot-standby",
              "peers": [
                {
                  "name": "server1",
                  "url": "http://192.168.1.2:8000/",
                  "role": "primary"
                },
                {
                  "name": "server2",
                  "url": "http://192.168.1.3:8000/",
                  "role": "standby"
                }
              ]
            }
          ]
        }
      }
    ],
    "subnet4": [
      {
        "id": 1,
        "subnet": "192.168.2.0/24",
        "relay": {
          "ip-addresses": [ "192.168.1.5" ]
        },
        "pools": [
          {
            "pool": "192.168.2.100 - 192.168.2.254"
          }
        ],
        "option-data": [
          {
            "name": "routers",
            "data": "192.168.2.1"
          }
        ]
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp4",
        "output-options": [
          {
            "output": "kea-dhcp4.log"
          }
        ],
        "severity": "INFO"
      }
    ]
  }
}
```

2. Paste the configuration into `/etc/kea/kea-dhcp4.conf` on "kea1".  This is best accomplished by truncating the file (which will already have content) before opening it and adding the configuration.

```
cp /dev/null /etc/kea/kea-dhcp4.conf && \
nano /etc/kea/kea-dhcp4.conf
```

Paste the text into what should be a blank editor window.  Press `ctrl+o` to write out the file.  Press `ctrl+x` to exit `nano`.

3. Test the configuration for syntax errors on "kea1":

```
kea-dhcp4 -T /etc/kea/kea-dhcp4.conf
```

Watch for `syntax error` or `ERROR` in the output.

4. Repeat step 2 on "kea2".  Before writing the file, locate `"this-server-name": "server1",` in the file.  This can be quickly found by pressing `ctrl+w` and typing or pasting some part of the text into the prompt.  Change the text to: `"this-server-name": "server2",` and write out the file as you did on "kea1".
5. Repeat the configuration syntax test performed in step 3 on "kea2".
6. And finally, we can start `kea-dhcp4` on both "kea1" and "kea2" with the below command:

```
systemctl enable --now isc-kea-dhcp4-server
```

Check the status to make sure that the service is running:

```
systemctl status isc-kea-dhcp4-server
```

Look for the text: `Active: active (running) since ...`

7. Use the API to test the current status of High Availability with the following command:

```
echo '{ "command": "status-get" }' | socat unix:/run/kea/socket4 - | jq
```

This can be done on either "kea1", "kea2" or both.  Look for `"state": "hot-standby"` for both the `"local"` and `"remote"` server in the output.

8. A final test of `kea-dhcp4` simulating clients using `perfdhcp` from "client" can now be performed using the command below:

```
perfdhcp -l eth1 -4 -r 1 -R 1 -p 2
```

Both the `***Statistics for: DISCOVER-OFFER***` and `***Statistics for: REQUEST-ACK***` should contain `drops: 0` and `received packets: 1` (or possibly "2").

### Exercise 3
Configure, start, and test `kea-dhcp6` on "kea1" and "kea2".  Having just completed Exercise 2, the below steps may seem familiar with only slight differences.

1. Copy the `kea-dhcp6` configuration:

```
{
  "Dhcp6": {
    "control-socket": {
      "socket-type": "unix",
      "socket-name": "socket6"
    },
    "interfaces-config": {
      "interfaces": [
        "eth1"
      ]
    },
    "lease-database": {
      "type": "memfile",
      "name": "leases6.csv"
    },
    "hooks-libraries": [
      {
        "library": "libdhcp_lease_cmds.so"
      },
      {
        "library": "libdhcp_stat_cmds.so"
      },
      {
        "library": "libdhcp_subnet_cmds.so"
      },
      {
        "library": "libdhcp_ha.so",
        "parameters": {
          "high-availability": [
            {
              "this-server-name": "server1",
              "mode": "hot-standby",
              "peers": [
                {
                  "name": "server1",
                  "url": "http://[2001:db8::2]:8000/",
                  "role": "primary"
                },
                {
                  "name": "server2",
                  "url": "http://[2001:db8::3]:8000/",
                  "role": "standby"
                }
              ]
            }
          ]
        }
      }
    ],
    "subnet6": [
      {
        "id": 1,
        "subnet": "2001:db8:0:1::/64",
        "interface": "eth1",
        "pools": [
          {
            "pool": "2001:db8:0:1::1:0 - 2001:db8:0:1::1:ffff"
          }
        ],
        "pd-pools": [
          {
            "prefix": "2001:db8:100::",
            "prefix-len": 40,
            "delegated-len": 56
          }
        ]
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp6",
        "output-options": [
          {
            "output": "kea-dhcp6.log"
          }
        ],
        "severity": "INFO"
      }
    ]
  }
}
```

2. Paste the configuration into `/etc/kea/kea-dhcp6.conf` on "kea1".  This is best accomplished by truncating the file (which will already have content) before opening it and adding the configuration.

```
cp /dev/null /etc/kea/kea-dhcp6.conf && \
nano /etc/kea/kea-dhcp6.conf
```

Paste the text into what should be a blank editor window.  Press `ctrl+o` to write out the file.  Press `ctrl+x` to exit `nano`.

3. Test the configuration for syntax errors on "kea1":

```
kea-dhcp6 -T /etc/kea/kea-dhcp6.conf
```

Watch for `syntax error` or `ERROR` in the output.

4. Repeat step 2 on "kea2".  Before writing the file, locate `"this-server-name": "server1",` in the file.  This can be quickly found by pressing `ctrl+w` and typing or pasting some part of the text into the prompt.  Change the text to: `"this-server-name": "server2",` and write out the file as you did on "kea1".
5. Repeat the configuration syntax test performed in step 3 on "kea2".
6. And finally, we can start `kea-dhcp6` on both "kea1" and "kea2" with the below command:

```
systemctl enable --now isc-kea-dhcp6-server
```

Check the status to make sure that the service is running:

```
systemctl status isc-kea-dhcp6-server
```

Look for the text: `Active: active (running) since ...`

7. Use the API to test the current status of High Availability with the following command:

```
echo '{ "command": "status-get" }' | socat unix:/run/kea/socket6 - | jq
```

This can be done on either "kea1", "kea2" or both.  Look for `"state": "hot-standby"` for both the `"local"` and `"remote"` server in the output.

8. A final test of `kea-dhcp6` simulating clients using `perfdhcp` from "client" can now be performed using the command below:

```
perfdhcp -l eth1 -6 -r 1 -R 1 -p 2 -e address-and-prefix
```

Both the `***Statistics for: SOLICIT-ADVERTISE***` and `***Statistics for: REQUEST-REPLY***` should contain `drops: 0` and `received packets: 1` (or possibly "2").


### Exercise 4
Installing, starting, logging into, and setting a password on `stork-server` on the "stork" VM.

1. Add the repository to "stork":

```
curl -1sLf 'https://dl.cloudsmith.io/public/isc/stork/setup.deb.sh' | sudo -E bash
```

2. Install the `stork-server` on "stork":

```
apt install isc-stork-server
```

3. Setup the "stork-server" user and create the database:

```
sudo -u postgres stork-tool db-create --db-name stork --db-user stork-server
```

4. Change the user used by `stork-server` to access the database to "stork-server", and set the correct port to be used on "stork":
  - Edit the file "/etc/stork/server.env":

```
nano /etc/stork/server.env
```

  - Find the line `# STORK_DATABASE_USER_NAME=`
  - Change this line to: `STORK_DATABASE_USER_NAME=stork-server`
  - Find the line: `# STORK_REST_PORT=`
  - Change this line to: `STORK_REST_PORT=4780`
  - Press `ctrl+o` to save and `ctrl+x` to exit

5. Start the server on "stork":

```
systemctl enable --now isc-stork-server
```

6. Check that it started correctly by checking the status:

```
systemctl status isc-stork-server
```

7. The Stork server should now be available here: `http://IP_address_of_your_server:4780`


### Exercise 5
Installing, registering, and starting the `stork-agent` on "kea1" and "kea2".  Note that various commands in the following exercise will contain: `IP_address_of_your_server ` which must be replaced with the IP address of your "stork" server.

1. Add the repository to both "kea1" and "kea2":

```
curl -1sLf 'https://dl.cloudsmith.io/public/isc/stork/setup.deb.sh' | sudo -E bash
```

2. Install the `stork-agent` on both "kea1" and "kea2":

```
apt install isc-stork-agent
```

3. Now register the agent from both "kea1" and "kea2" to the `stork-server` on "stork":

```
sudo -u stork-agent stork-agent register --server-url http://IP_address_of_your_server:4780
```

4. Now start the `stork-agent` on both "kea1" and "kea2":

```
systemctl enable --now isc-stork-agent
```

5. Check the status of the `stork-agent` on both "kea1" and "kea2" to make sure it is running:

```
systemctl status isc-stork-agent
```

6. Log in to the Stork UI using the folowing:
URL: `http://IP_address_of_your_server:4780`
Username: `admin`
Password: `admin`
Note that you will be forced to change your password.  Please use the same password that was supplied to you to log in to these systems as the new password.

7. Now that you are logged in, please click the "unauthorized machines" link in the banner near the top complaining about "Unregistered machines". You should see "kea1" and "kea2" listed here. Check the box for each and click "Authorize Selected".  This will authorize the `stork-agent` services on "kea1" and "kea2" that were registered in step 3, allowing them to talk to the `stork-server` on "stork".

8. Refresh the page.  This would not be strictly necessary but there would be a substantial delay before the UI was updated with new items in the menus if not done.

9. Click the hamburger menu and choose "DHCP" (DHCP may not be under the hamburger menu depending on width of your web browser window).

10. Click "Dashboard".

11. There should be a green checkmark ✅ in "Status" for "kea1" and "kea2".

### Exercise 6
Simulate client traffic using `perfdhcp` on "client" to both `kea-dhcp4` and `kea-dhcp6`.  Learn about various reporting in the Stork UI.

1. Send approximately 100 DHCPv4 packets simulating 100 clients.

```
perfdhcp -l eth1 -4 -r 10 -R 100 -p 11
```

2. On the Stork UI, click the refresh button next to the DHCP Dashboard title.  The IPv4 subnet should appear about 40% filled with a green color.  Hovering over this indicator should report 100 assigned addresses.

3. Click "Leases Search" under the "DHCP" menu on the top left (may be beneath a hamburger menu depending on the width of your screen).

4. Enter `00:0c:01:02:03:04` in the "Search leases" box and press "Enter" on the keyboard.

5. Two leases should be returned (one from each Kea server).  You can expand these records using the arrows to view more details about the leases.

6. Now we will send DHCPv6 traffic to populate similar statistics, though this traffic will request both an address and a prefix delegation:

```
perfdhcp -l eth1 -6 -r 10 -R 100 -p 11 -e address-and-prefix -b duid=000200007ed90cc084d303000912
```

7. Click "Dashboard" under the "DHCP" menu (Reminder: this may be nestled under a hamburger menu depending on your screen width) to return to the dashboard.

8. Click the same refresh button as before next to the DHCP Dashboard title.  You may have to click this button a couple of times.  Not much will change here as far as the bar filling with green as there are *a lot* of IPv6 addresses available here.  However, a hover should show around 100 "Assigned NAs" and the same for "Assigned PDs".

9. Now let us return to the "Leases Search" page found under the "DHCP" menu.

10. Type `00:02:00:00:7e:d9:0c:c0:00:0c:01:02:03:04` in the "Search leases" box and press enter on the keyboard.

11. This time you should have four results instead of two.  Two will be `IA_NA` IPv6 addresses and the other two will be `IA_PD` prefix delegations.  As before, you can expand these leases to see further details.

### Exercise 7
Simulate more client traffic like in exercise 6.  Experiment with HA and status reports of same in the Stork UI by stopping `kea-dhcp4` and `kea-dhcp6` on "kea1". 

1. For this exercise, you will need ssh sessions to "client" as you will need to run `perfdhcp` twice simultaneously.  Please connect to "client" a second time.  We will refer to these sessions as "dhcp4 client" and "dhcp6 client", so please also decide which is which for you.

2. On "dhcp4 client", please run a simulation of 100 DHCPv4 clients at a rate of 10 per second until canceled by running:

```
perfdhcp -l eth1 -4 -r 10 -R 100 -Y 1 -y 3600 -t 15
```

3. On "dhcp6 client", please run a simulation of 100 DHCPv6 clients at a rate of 10 per second requesting both an `IA_NA` and an `IA_PD` until canceled by running:

```
perfdhcp -l eth1 -6 -r 10 -R 100 -e address-and-prefix -Y 1 -y 3600 -t 15
```

4. Now we will simulate an outage on "kea1" of the `kea-dhcp4` service by stopping the service by running:

```
systemctl stop isc-kea-dhcp4-server
```

5. The `perfdhcp` running in your "dhcp4 client" window should start to report drops.

6. Now we will check the status to see if the failover has yet occurred.  the `-Y 1 -y 3600` parameters passed to `perfdhcp` tells the tool to simulate an outage by reporting that it has been an increasing number of seconds that it has been trying to get an address as a real client would.  Kea watches for this when performing failover calculations.  To check the current status, execute this command on "kea2":

```
echo '{ "command": "status-get" }' | socat unix:/run/kea/socket4 - | jq
```

In the output from the command, look for `"server-name": "server2",` with `"state": "partner-down",` and `"last-state": "unavailable",` with `"server-name": "server1",` in the `"remote": { }` section.  It may take a couple of minutes for this to occur.  There are parameters that can be set in the Kea configuration that control how quickly this happens.  After the state matches that described here, move on to step 7.

7. Look again at the "Dashboard" under the "DHCP" menu in the Stork UI.  There should be a warning triangle and "partner-down" in the "HA State" for kea2. kea1 should have a red X in status and "unavailable" in the HA State.

8. Drops should have stopped incrementing on "dhcp4 client".

9. Now we will shut down `kea-dhcp6` on "kea1" by executing the command:

```
systemctl stop isc-kea-dhcp6-server
```

10. Drops should start incrementing in `perfdhcp` running on "dhcp6 client".

11. As was done in step 6 for `kea-dhcp4`, the current status of `kea-dhcp6` will be checked on "kea2" by running:

```
echo '{ "command": "status-get" }' | socat unix:/run/kea/socket6 - | jq
```

You are looking for the `partner-down` states in the output as described in step 6.  Once the state matches that described here, move on to step 12.

12. In the Stork UI, states for `kea-dhcp6` on "kea1" and "kea2" should be similar to that described in step 7.

13. You will notice in the "Events" log on the Stork UI that times for the beginnings of the trouble are shown.

14. Drops should have stopped  incrementing in `perfdhcp` running on "dhcp6 client".

15. Now the outage can be stopped by starting `kea-dhcp4` and `kea-dhcp6` on "kea1" by running the following commands:

```
systemctl start isc-kea-dhcp4-server && \
systemctl start isc-kea-dhcp6-server
```

16. You can use the API commands described in step 6 and step 11 to check the status of HA.  You can watch the "Events" log in the Stork UI for events relating to the return to service.  Finally, clicking the refresh button next to "DHCP Dashboard" in the Stork UI should, after a couple of minutes, show that everything is working again.

17. Stop `perfdhcp` on "dhcp4 client" and "dhcp6 client" by pressing `ctrl+c` in their respective ssh windows.

### Exercise 8
Add and edit a new subnet to "kea1" and "kea2" using the Stork UI.

1. Click on "Subnets" under the "DHCP" menu.

2. Click on "+ New Subnet".

3. Enter: `2001:db8:0:2::/64` in the "Subnet" box and click "Proceed".

4. Choose both DHCPv6 servers in "Assignments > DHCP Servers".

5. Click "+ Add Pool".

6. Type `2001:db8:0:2::1:0` in "First Address" and `2001:db8:0:2::1:ffff` in "Last Address".

7. Now Pick both DHCPv6 servers in "Assignments > DHCP Servers" just below the pool info you just added.

8. Click the "Submit" button at the very bottom of the page.

9. At this point, we have realized that we forgot to add the prefix delegation.  Now we will edit the subnet that was just added to correct this omission.

10. Click "Edit".

11. Click "+ Add Pool" under "Prefix Delegation Pools".

12. Enter "2001:db8:200::/40" in "Pool Prefix"

13. Enter "56" in "Delegated Length"

14. Choose both "DHCPv6" servers in "Assignments > DHCP Servers"

15. Click the "Submit" button at the very bottom of the page.

