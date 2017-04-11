#!/bin/bash

#Puhastan ekraani ära
clear

#Annan kasutajale teada sõnumiga et skript hakkas tööle
dialog --title "Domeeni skript" --msgbox 'See skript on valmis kirjutatud Kevini poolt' 10 30

#Puhastan ekraani ära
clear

### Uendan igaksjuhuks serveri ka ära!!! Kui seda pole vaja siis palun kustuta/kommenteeri ära

apt-get update 
apt-get upgrade -y

#Paigaldan samba ja muud paketid
#!!!!!Siin tuleb nüüd kirjutada samuti ka REALM ning see meelde jätta!!!!
apt-get install -y samba samba-vfs-modules smbclient winbind krb5-user ldap-utils dialog 

#Kustutan samba example konfiguratsiooni
rm -fv /etc/samba/smb.conf

#Küsin kasutajalt erinevaid asju, et need muutujaks teha

#Puhstan ekraani
clear

#Edastan kasutajale küsimuse
echo "Palun sisesta enda domeeni REALM uuesti, suurtetähtedega!!"
echo "Näiteks: KEVIN.LAN"
read REALM

#Puhstan ekraani
clear

#Edastan kasutajale küsimuse
echo "Palun sisesta enda domeeni WORKGROUP uuesti, suurtetähtedega"
echo "Näiteks: KEVIN"
read WORKGROUP

#Puhstan ekraani
clear

#Edastan kasutajale küsimuse
echo "Palun sisesta enda masina NIMI"
echo "Näiteks: DC1"
read NIMI

#Puhstan ekraani
clear

#Edastan kasutajale küsimuse
echo "Palun sisesta enda masina väline IP"
echo "Näiteks: 192.168.1.2"
read Valine

#Puhstan ekraani
clear

#Seadistan samba ära

samba-tool domain provision --use-rfc2307 --server-role=dc --domain=$WORKGROUP --realm=$REALM --host-name=$NIMI

#Kustutan ära krb5.conf faili ja lingin private kaustas olevat faili

rm -fv /etc/krb5.conf
ln -s /var/lib/samba/private/krb5.conf /etc/krb5.conf

#Nüüd tuleb määrata administrator kasutajale parool

clear

echo "Sisesta administrator kasutajale palun parool"

samba-tool user setpassword administrator

#keelan parooli aegumised administrator kasutajale

samba-tool domain passwordsettings set --max-pwd-age=0
samba-tool domain passwordsettings set --min-pwd-age=0

clear

#Taaskäivitan teenused!!! Mõni hetk!!

service smbd stop
service nmbd stop
service samba-ad-dc stop
service samba-ad-dc start

clear

echo "$Valine	$NIMI.$REALM	$NIMI " >> /etc/hosts


#ISC-DHCP-SERVERI paigaldus

apt-get install -y isc-dhcp-server

clear

echo "Palun kirjuta väline võrguliides"
echo "Näiteks: eth0"
read LIIDES

clear

echo "Palun kirjuta võrgu aadress"
echo "Näiteks: 192.168.0.0"
read VORK

clear

echo "Palun sisesta võrgu subnetmask"
echo "Näiteks: 255.255.255.0"
read SUBNETMASK

clear

echo "Palun sisesta esimene aadress mida DHCP hakkab välja jagama"
echo "Näiteks: 192.168.1.10"
read ESIMENE

clear

echo "Palun sisesta viimane aadress mida DHCP hakkab välja jagama"
echo "Näiteks: 192.168.1.254"
read VIIMANE

clear

echo "Palun sisesta enda gateway aadress"
echo "Näiteks: 192.168.1.1"
read GATEWAY

clear

cd /etc/default

sed -i '21s/.*/"INTERFACES='$LIIDES'"/' isc-dhcp-server

cd /etc/dhcp

sed -i '16s/.*/option domain-name "'$REALM';/' dhcpd.conf
sed -i '17s/.*/option domain-name-servers '$Valine';/' dhcpd.conf

sed -i '38s/.*/subnet '$VORK' netmask '$SUBNETMASK' {/' dhcpd.conf
sed -i '39s/.*/range '$ESIMENE' '$VIIMANE';/' dhcpd.conf
sed -i '40s/.*/option routers '$GATEWAY';/' dhcpd.conf
sed -i '41s/.*/}/' dhcpd.conf

#echo "INTERFACES="$LIIDES"" > /etc/default/isc-dhcp-server


#echo "option domain-name "$REALM";" > /etc/dhcp/dhcpd.conf
#echo "option domain-name-servers $Valine;" >> /etc/dhcp/dhcpd.conf



#echo "subnet $VORK netmask $SUBNETMASK {" >> /etc/dhcp/dhcpd.conf
#echo "range $ESIMENE $VIIMANE;" >> /etc/dhcp/dhcpd.conf
#echo "option routers $GATEWAY;" >> /etc/dhcp/dhcpd.conf
#echo "}" >> /etc/dhcp/dhcpd.conf





perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' /etc/default/isc-dhcp-server /etc/dhcp/dhcpd.conf


service isc-dhcp-server restart

dialog --title "Domeeni skript" --msgbox 'Palun vaadata üle kõik konfiguratsiooni failid' 10 30
