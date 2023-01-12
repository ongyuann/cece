echo "[!] WARNING: we assume you're using default kali!" 
if [ "$(id -u)" -ne "0" ] ; then
    echo "[+] run this script with sudo - and i mean sudo, not root. aborting"
    exit 1
fi
cuser=$SUDO_USER
sudo echo "$cuser    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "[+] made current user $cuser password-free sudoer"
sudo echo "CustomLog /var/log/apache2/access.log combined" >> /etc/apache2/apache2.conf
sudo service apache2 restart
echo "[+] enabled apache logging - read logs with:\nsudo tail -f /var/log/apache2/access.log"
echo "[+] updating apt and dist..(**reboot only if run first time!**)"
sudo apt update && sudo apt upgrade
sudo apt-get dist-upgrade
echo "[+] reboot? [y/N]"
read answer
if [ $answer = "y" ]
then
  sudo reboot
else
  echo "[!] assuming kali upgraded! continuing"
fi

# PWPW
echo "[+] installing realtek drivers.."
echo "[+] first time? [y/N]"
read answer
if [ $answer = "y" ]
then
  current=$(pwd)
  sudo apt-get install realtek-rtl88xxau-dkms
  sudo apt-get install dkms
  cd /opt
  git clone https://github.com/aircrack-ng/rtl8812au
  cd rtl8812au
  make
  sudo make install
  cd $current
else
  echo "[!] assuming realtek drivers installed! continuing"
fi
echo "[+] check realtek drivers"
sudo dkms status
echo "[!] if you don't see realtek-rtl8814au drivers, STOP RIGHT NOW and rerun the script!"
sleep 1
echo "[+] installing crackers.."
sudo apt-get install hcxtools
sudo apt-get install hashcat-utils
sudo apt-get install cowpatty
echo "[+] installing airgeddon.."
sudo apt-get install airgeddon
sleep 1
source /usr/share/airgeddon/known_pins.db
echo "[+] installing hostapd.."
sudo apt-get install hostapd
echo "[+] installing hostapd-mana.."
sudo apt-get install hostapd-mana
echo "[+] installing freeradius.."
sudo apt-get install freeradius
echo "[+] installing asleap.."
sudo apt-get install asleap
echo "[+] installing dnsmasq.."
sudo apt-get install dnsmasq
echo "[+] installing nftables.."
sudo apt-get install nftables
echo "[+] installing bettercap.."
sudo apt-get install bettercap
echo "[+] creating bettercap oswp handshakes folder at /home/kali/oswp/shakes/ .."
mkdir -p /home/kali/oswp/shakes
echo "[+] creating dump folder at /home/kali/oswp/dumps/ .."
mkdir -p /home/kali/oswp/dumps
echo "[+] installing kismet.."
sudo apt-get install kismet
echo "[+] creating kismet log dir at /var/log/kismet/ .."
sudo mkdir /var/log/kismet
echo "[+] adjusting kismet logging config .."
sudo sed -i 's/log_prefix=.\//log_prefix=\/var\/log\/kismet\//g' /etc/kismet/kismet_logging.conf
sudo sed -i 's/log_types=kismet/log_types=kismet,pcapng/g' /etc/kismet/kismet_logging.conf
echo "[+] adjusting kismet http config .."
sudo sed -i 's/# httpd_bind_address=127.0.0.1/httpd_bind_address=127.0.0.1/g' /etc/kismet/kismet_httpd.conf
echo "[+] check:"
cat /etc/kismet/kismet_logging.conf | grep log_prefix
cat /etc/kismet/kismet_logging.conf | grep log_types
cat /etc/kismet/kismet_httpd.conf | grep bind_address
echo "[+] creating debug folder at /mnt/debug/ .."
sudo mkdir -p /mnt/debug

# PEPE
echo "[+] pepe stuff - make sure optlist.txt and ./html/ folder are present"
sudo apt install samba
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.old
cat <<EOF >>/etc/samba/smb.conf
[visualstudio]
path = /home/$cuser/data
browseable = yes
read only = no
EOF
echo "[+] smbd and nmbd setup set - enter \"$cuser\" in next prompt:"
sudo smbpasswd -a $cuser
sudo systemctl start smbd
sudo systemctl start nmbd
echo "[+] smbd and nmbd started"
echo "[+] installing sublimetext.."
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-text
sudo apt-get install krb5-user
sudo -H pip install -U oletools
sudo apt-get install mono-complete
sudo gem install evil-winrm
sudo msfdb start
echo "[+] msfdb started"

mkdir /home/$cuser/data
chmod -R 777 /home/$cuser/data
echo "[+] /home/$cuser/data created for visualstudio projects"
sudo chown -R $cuser:$cuser /var/www/html
echo "[+] normalized /var/www/html ownership"

FILE=./optlist.txt
if [ -f "$FILE" ]; then
  echo "[+] filling /opt .."
  for i in $(cat ./optlist.txt);do 
  j=`echo $i | rev | cut -d"/" -f1 | rev`
  git clone $i /opt/$j
  done
fi

sudo chown -R $cuser:$cuser /opt
echo "[+] normalized /opt ownership"

FILE=./html
if [ -d "$FILE" ]; then
  echo "[+] copying html to /var/www/html .."
  cp -r html /var/www/
  cp /var/www/html/chisel /opt/chisel/
  chmod +x /opt/chisel
  echo "[+] copied /var/www/html/chisel to /opt/chisel/chisel"
fi
