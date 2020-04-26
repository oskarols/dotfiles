#!/usr/bin/env python3
import subprocess
# just a helper function
get = lambda cmd: subprocess.check_output(cmd).decode("utf-8")
# get the current mouse position
current = [int(n) for n in [it.split(":")[1] for it in get(["xdotool", "getmouselocation"]).split()[:2]]]
# get the x/y size of the left screen
screendata = [(s.split("x")[0], s.split("x")[1].split("+")[0]) for s in get(["xrandr"]).split() if "+0+0" in s ][0]
xy = [int(n) for n in screendata]
# see if the mouse is on the left- or right screen
if current[0] < xy[0]:
    # if the mouse currently is on the left screen, move it to the right (from the middle of the left screen)
    command = ["xdotool", "mousemove", "--sync", str(current[0]+xy[0]), str(xy[1]/2)]
else:
    # if the mouse currently is on the left screen, move it to the right (from the middle of the left screen)
    command = ["xdotool", "mousemove", "--sync", str(current[0]-xy[0]), str(xy[1]/2)]

subprocess.Popen(command)
# optional: click after the mouse move: comment out if not needed / wanted
subprocess.Popen(["xdotool", "click", "1"])