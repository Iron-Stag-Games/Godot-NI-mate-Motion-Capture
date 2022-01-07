#### I intend to make this plugin 100% stable and feature-complete for its users! Please [report bugs or ask questions about usability](https://github.com/hoontee/godot-ni-mate-motion-capture/issues) and a response will be made within a day of posting.

# NI mate Motion Capture

Add an NImate node to the scene to begin - its variables should be self-explanatory.

Requires Delicode NI mate. Use default settings with skeleton tracking enabled.

## Delicode NI mate Installers

Windows - [Delicode_NI_mate_v2.14_Installer.exe](https://github.com/hoontee/godot-ni-mate-motion-capture/raw/master/ni-mate-installers/Delicode_NI_mate_v2.14_Installer.exe)

macOS - [Delicode_NI_mate_v2.14.dmg](https://github.com/hoontee/godot-ni-mate-motion-capture/raw/master/ni-mate-installers/Delicode_NI_mate_v2.14.dmg)

Ubuntu 64-bit - [Delicode-NI-mate_1.20-ubuntu_amd64.deb](https://github.com/hoontee/godot-ni-mate-motion-capture/raw/master/ni-mate-installers/Delicode-NI-mate_1.20-ubuntu_amd64.deb)

Ubuntu 32-bit - [Delicode-NI-mate_1.20-ubuntu_i386.deb](https://github.com/hoontee/godot-ni-mate-motion-capture/raw/master/ni-mate-installers/Delicode-NI-mate_1.20-ubuntu_i386.deb)

## Sensor Compatibility

Some sensors have fewer tracking points than normal. If the rig inside the NI mate viewport looks mangled, try enabling **Rig > Simple**:

![](https://github.com/hoontee/godot-ni-mate-motion-capture/blob/master/simple.png?raw=true)

## Rig Compatibility

All animated bones must face forward relative to the armature.

In Blender, you can ensure this is the case by displaying bone axes and checking if the Z axes are facing forward:

![](https://github.com/hoontee/godot-ni-mate-motion-capture/blob/master/axes.png?raw=true)

If any of them aren't facing forward, select all bones in Edit mode and do **Armature > Bone Roll > Recalculate Roll > Global +/- X/Y/Z Axis**. You'll most likely be using **Global -Y Axis** if the armature faces forward relative to the world.

![](https://github.com/hoontee/godot-ni-mate-motion-capture/blob/master/recalculate_roll.png?raw=true)