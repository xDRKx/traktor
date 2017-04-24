#!/bin/bash
clear
echo -e "Traktor vX.XX.X\nTor will be automatically installed and configured…\n\n"
#checking root !
if (whoami != root)
  then echo "Please run as root/nHow to : "$"su -c './traktor-debian.sh'"

  else (
		# Install Packages
		##
		apt-get update > /dev/null
		apt install -y aptitude
		aptitude install -y \
			tor \
			obfs4proxy \
			polipo \
			dnscrypt-proxy \
			torbrowser-launcher \
			apt install obsf4proxy
			apt-transport-tor
		#checking apparmor
		test "$(apparmor_parser)" != '' && (echo 1 > /tmp/DES)
		##
		# Write Bridge
		wget https://ubuntu-ir.github.io/traktor/torrc -O /etc/tor/torrc > /dev/null

		# Fix Apparmor problem
		##
		if [ "$(cat /tmp/DES)" == '1' ]; then
		sed -i '27s/PUx/ix/' /etc/apparmor.d/abstractions/tor
		apparmor_parser -r -v /etc/apparmor.d/system_tor
		fi
		##
		# Write Polipo config
		echo 'logSyslog = true
		logFile = /var/log/polipo/polipo.log
		proxyAddress = "::0"        # both IPv4 and IPv6
		allowedClients = 127.0.0.1
		socksParentProxy = "localhost:9050"
		socksProxyType = socks5' | tee /etc/polipo/config > /dev/null
		service polipo restart

		# Set IP and Port on HTTP
		gsettings set org.gnome.system.proxy mode 'manual'
		gsettings set org.gnome.system.proxy.http host 127.0.0.1
		gsettings set org.gnome.system.proxy.http port 8123
		gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '192.168.0.0/16', '10.0.0.0/8', '172.16.0.0/12']"

		# Install Finish
		echo "Install Finished successfully…"

		# Wait for tor to establish connection
		echo "Tor is trying to establish a connection. This may take long for some minutes. Please wait" | sudo tee /var/log/tor/log
		bootstraped='n'
		service tor restart
		while [ $bootstraped == 'n' ]; do
			if cat /var/log/tor/log | grep "Bootstrapped 100%: Done"; then
				bootstraped='y'
			else
				sleep 1
			fi
		done

		# Add tor repos
		echo "deb tor+http://deb.torproject.org/torproject.org stable main" | tee /etc/apt/sources.list.d/tor.list > /dev/null

		# Fetching Tor signing key and adding it to the keyring
		gpg --keyserver keys.gnupg.net --recv 886DDD89
		gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

		# update tor from main repo
		apt-get update > /dev/null
		aptitude install -y \
			tor \
			obfs4proxy

		# Fix Apparmor problem
		##
		if [ "$(cat /tmp/DES)" == '1' ]; then
		sed -i '27s/PUx/ix/' /etc/apparmor.d/abstractions/tor
		apparmor_parser -r -v /etc/apparmor.d/system_tor
		fi
		##
		# Traktor GUI Panel
		mkdir $HOME/.traktor_gui_panel
		mv traktor_gui_panel.py $HOME/.traktor_gui_panel
		mv traktor_gui_panel/icons $HOME/.traktor_gui_panel/
		chmod +x ~/.traktor_gui_panel/traktor_gui_panel.py

		touch /usr/share/applications/traktor-gui-panel.desktop
		echo "[Desktop Entry]
		Version=1.0
		Name=Traktor GUI Panel
		Name[fa]=تراکتور پنل گرافیکی
		GenericName=Traktor Panel
		GenericName[fa]=تراکتور پنل
		Comment=Traktor GUI Panel
		Comment[fa]=تراکتور پنل گرافیکی
		Exec=$HOME/.traktor_gui_panel/traktor_gui_panel.py
		Terminal=false
		Type=Application
		Categories=Network;Application;
		Icon=$HOME/.traktor_gui_panel/icons/traktor.png
		Keywords=Tor;Browser;Proxy;VPN;Internet;Web" | tee /usr/share/applications/traktor-gui-panel.desktop > /dev/null

		# update finished
		echo "Congratulations!!! Your computer is using Tor. may run torbrowser-launcher now."

		)
fi

exit
