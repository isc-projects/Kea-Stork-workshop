#!/bin/bash

exec >/var/log/stackscript.log 2>&1

set -eux

apt update
apt upgrade -y

apt install -y socat jq locales-all

token="$(curl -s -X PUT -H 'Metadata-Token-Expiry-Seconds: 3600' 'http://169.254.169.254/v1/token')"
label="$(curl -s -H "Metadata-Token: $token" -H 'Accept: application/json' 'http://169.254.169.254/v1/instance' | jq -r '.label')"
ipv4="$(curl -s -H "Metadata-Token: $token" -H 'Accept: application/json' 'http://169.254.169.254/v1/network' | jq -r '.ipv4.public.[0]')"

role="${label#*-}"
ipv4="${ipv4%/*}"
subnet="${ipv4%.*}"

case "${role}" in
	kea1)
		private4='192.168.1.2'
		private6='2001:db8::2'
		;;
	kea2)
		private4='192.168.1.3'
		private6='2001:db8::3'
		;;
	stork)
		private4='192.168.1.4'
		private6='2001:db8::4'
		stork='true'
		;;
	client)
		private4='192.168.1.5'
		private6='2001:db8::5'
		;;
esac

echo 'Port 7223' > /etc/ssh/sshd_config.d/port.conf

echo 'source /etc/network/interfaces.d/*' > /etc/network/interfaces
cat > /etc/network/interfaces.d/lo <<-"EOF"
	auto lo
	iface lo inet loopback
EOF
cat > /etc/network/interfaces.d/eth0 <<-EOF
	auto eth0
	iface eth0 inet static
	    address ${ipv4}/24
	    gateway ${subnet}.1

	iface eth0 inet6 auto
EOF
cat > /etc/network/interfaces.d/eth1 <<-EOF
	auto eth1
	iface eth1 inet static
	    address ${private4}/24

	iface eth1 inet6 static
	    address ${private6}/64
EOF

# otherwise dhcpcd will wipe it...
chattr +i /etc/resolv.conf

hostnamectl set-hostname "${role}"

cat >> /etc/hosts <<-EOF
	192.168.1.2	kea1
	192.168.1.3	kea2
	192.168.1.4	stork
	192.168.1.5	client
EOF
if [ -n "${stork:-}" ]; then
	apt install -y postgresql
fi

systemctl reboot --when='+30 seconds'
