### Tuxcord Voice
- NOTICE: In No shape, way, OR form this project is affiliated to discord, It is just third party a modification.
  
Fix for Screenshare Audio on Offical Discord Linux Client

- Disclaimer: If you are not comfortable with changing config files for programs or using git then this project may not be ready for you yet. 



---
#### Prerequisites
- [Git](https://git-scm.com/downloads)
- [Discord](https://discord.com) (``Flatpak/RPM/DEB for any of it's clients.``)

#### Requirements
- [PipeWire](https://wiki.archlinux.org/title/PipeWire) (``Look up Installation for your specific distro.``)
- [pipewire-pulse](https://wiki.archlinux.org/title/PipeWire#:~:text=Usage-,Audio,-PipeWire%20can%20be) (``Look up Installation for your specific distro.``)
- [zenity](https://help.gnome.org/users/zenity/stable/) (``Look up Installation for your specific distro.``)

#### Getting Started
- Clone the Repository (``git clone <repo url>``)
- Locate the Config Folder (``~/.config OR ~/.local/share/flatpak OR /var/lib/flatpak/``)
- Locate App Folder For Desired Varient of Client (``Would Probably Contain Cookies/Settings/...``)
- Open Module Folder (``./x.x.x/modules/discord_voice/  # x.x.x signifies random version number``)
- Rename index.js (``index.js -> index.orig.js # Should be exact File Name``)
- Copy Files From Clones Repo to current folder (``index.js AND audio_manager.sh AND create_nightmic.sh``)
- Restart Discord

---

### Known Bugs

- Discord Becomes Unresponse and crashes sometimes after picking audio source
- Discord Becomes Unresponsive and crashes sometimes when streaming

<sub>I can not figure out fixes for this bugs so help would be appreciated </sub>

---

### TODO
- [x] Make Sure Default Input gets removed from stream
- [ ] Automated Installer
- [ ] Refractor index.js
- [ ] Refractor audio_manager.sh
---


### FAQ

#### Is this bannable by discord?
- Long Story Short, NO.
- Long Story, not particularly since it's an most of the stuff is client side, on server side it just looks like a normal stream with audio.

#### How Does this work?
- With a specific config for stream, discord adds an audio input sink from default input device
- So the script makes the stream start with that and then add our stream source for video on top
- Executes an sh script to manage audio nodes

#### Is there better way to do this?
- Yes, Vesktop But I don't like vencord, and want to use replugged with screenshare audio.

#### What funtionality Do I lose?
- Nothing, this even works with global keybinds (Xorg...). No Wayland Support (or Global keybind on Wayland) offically so use xwaylandvideobridge.

#### How Do I contribute?
- Fork.
- Make Changes.
- Make sure it works.
- Pull request.


#### How to give bug report or recommendation?
- Github issues
- Join Discord Server listed below

#### How Do I support without pull request?
- You Can Donate on my [ko-fi](https://ko-fi.com/yofukashino) or UPI at `yofukashinooo@oksbi`

[![Buy Me a Coffee at ko-fi.com](https://storage.ko-fi.com/cdn/kofi3.png?v=3)](https://ko-fi.com/yofukashino)


#### Where can I find the support?

There is support server. You can join it here:

[![Support Server](https://discordapp.com/api/guilds/919649417005506600/widget.png?style=banner3)](https://discord.gg/SgKSKyh9gY)



# Who is the author?

[![Discord Presence](https://lanyard.cnrad.dev/api/1121961711080050780?hideDiscrim=true&idleMessage=Leave%20the%20kid%20alone...)](https://discordapp.com/users/1121961711080050780)
