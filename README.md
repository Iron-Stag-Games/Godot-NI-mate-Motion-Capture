#### I intend to make this plugin 100% stable and feature-complete for its users! Please [report bugs or ask questions about usability](https://github.com/hoontee/godot-ni-mate-motion-capture/issues) and a response will be made within a day of posting.

# NI mate Motion Capture

Add an NImate node to the scene to begin - its variables should be self-explanatory.

Requires Delicode NI mate. Use default settings with skeleton tracking enabled.

https://ni-mate.com/download/

## Rig Compatibility

All animated bones must face forwards relative to the armature.

In Blender, you can ensure this is the case by displaying bone axes and checking if the Z axes are facing forward:

![](https://github.com/hoontee/godot-ni-mate-motion-capture/blob/master/axes.png?raw=true)

If any of them aren't facing forward, select all bones in Edit mode and do **Armature > Bone Roll > Recalculate Roll > Global +/- X/Y/Z Axis**. You will most likely be using **Global -Y Axis** if the armature faces forward relative to the world.

![](https://github.com/hoontee/godot-ni-mate-motion-capture/blob/master/recalculate_roll.png?raw=true)
