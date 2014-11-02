# AutoRip
With AutoRip you can save and convert audio and video discs automatically.
All you need is a Linux box (without X) and a disc drive.
In fact, AutoRip acts as a web frontend for MakeMKV, ABCDE and Handbrake.

## Requirements and Dependencies
To automate this process, you need some third party tools installed.
* **Automation**
  * Halevt (Recognizes your disc and starts AutoRip)
* **Audio**
  * abcde (Audio ripping software)
  * flac, id3v2, id3 (Dependencies for abcde)
* **Video**
  * MakeMKV: (Saves your video disc. Setup as described [here](http://www.makemkv.com/forum2/viewtopic.php?f=3&t=224))
  * HandBrakeCLI (Converts the video to a proper format.)
  * libdvdcss2, libdvdread4, libqt4-dev (Dependencies for MakeMKV)
* **Webserver**
  * Nginx

## Installation
The following information describes the installation on a Debian server.


## HandBrake, abcde and dependencies
I use the deb-multimedia repository for HandBrake.
```bash
echo 'deb http://www.deb-multimedia.org wheezy main non-free' > /etc/apt/sources.list.d/debmultimedia.list
apt-get update && apt-get install deb-multimedia-keyring
apt-get update
apt-get install abcde handbrake-cli libdvdcss2 libdvdread4 libqt4-dev flac id3 id3v2 regionset
```

Setup the right region for your DVD drive.
```bash
regionset /dev/sr1
```

### AutoRip
```bash
apt-get install git
git clone hhttps://github.com/blue-ananas/autorip.git /opt/autorip
useradd -M -s /usr/sbin/nologin -d /opt/autorip autorip
chown -R autorip.autorip /opt/autorip
```

Configure the settings as needed.
At least set up a directory and the disc drive (e.g. CDROM, OUTPUTDIR WAVOUTPUTDIR for audio.conf,  DVD_SRC, DVD_OUT for dvd.conf and BLURAY_SRC, BLURAY_OUT for bluray.conf).
```bash
su -s /bin/bash autorip
editor ~/conf/audio.conf
editor ~/conf/dvd.conf
editor ~/conf/bluray.conf
rm -rf ~/.dvdcss
```

### Halevt
```bash
apt-get install halevt
adduser halevt autorip
adduser halevt cdrom
cp /opt/autorip/doc/halevt/halevt.xml /etc/halevt/halevt.xml
sed -i s/"HALEVT_GROUP=plugdev"/"HALEVT_GROUP=autorip"/g /etc/default/halevt
sed -i s/"HALEVT_USER=plugdev"/"HALEVT_USER=autorip"/g /etc/default/halevt
service halevt restart
```


### Nginx
In order to have a very small memory footprint I use Nginx.
Of course you can also use Apache2 for this.

 ```bash
apt-get install nginx
cp /opt/autorip/doc/nginx/autorip.conf /etc/nginx/sites-available/autorip.conf
ln -s /etc/nginx/sites-enabled/autorip.conf  /etc/nginx/sites-available/autorip.conf
adduser wwww-data autorip
service nginx restart
```

## License
General Public License, Version 3.0
>This program is free software: you can redistribute it and/or modify
>it under the terms of the GNU General Public License as published by
>the Free Software Foundation, either version 3 of the License, or
>(at your option) any later version.

>This program is distributed in the hope that it will be useful,
>but WITHOUT ANY WARRANTY; without even the implied warranty of
>MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
>GNU General Public License for more details.

>You should have received a copy of the GNU General Public License
>along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Credits
AutoRip makes use of the following projects:
* [jQuery](http://www.jquery.org/)
* [jQuery DotDotDot](http://dotdotdot.frebsite.nl/)
* [Bootstrap](http://getbootstrap.com/)
* [Clamp.js](https://github.com/josephschmitt/Clamp.js/)

## History
* 1.0 - Final release of the program and its code.
* master - Alpha version in development state.