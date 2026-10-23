#!/usr/bin/env python3
# Status bar for the PicoCalc screen, toggled with Alt+O or SIGUSR1.
# FPS | CPU + per-core load | RAM | SD MB/s | WiFi | sound | temperature | battery
# Alerts: while /run/lyracalc/alert exists its text blinks across the bar, also when
# the bar is hidden. "WARN:" prefix = orange, "CRIT:" or none = red.
# SIGUSR2 re-reads the alert file.
import os, mmap, struct, signal, threading, time, glob

W, H = 320, 11
KEY_PROG1 = 148
FB = "/dev/fb0"
SPI = "/sys/bus/spi/devices/spi0.0/statistics/bytes_tx"
BAT = "/sys/firmware/picocalc/battery_percent"
SD = "/sys/block/mmcblk0/stat"
XSOCK = "/tmp/.X11-unix/X0"
ALERT = "/run/lyracalc/alert"
OVL_DEV = "/dev/fb_overlay"   # display driver draws the bar itself (no flicker)
FRAME = 320 * 320 * 2
CORES = 3
INTERVAL = 1.0
GUARD_INTERVAL = 0.01

def rgb(r, g, b):
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)

BG, FG, LBL, DIM = rgb(20, 20, 28), rgb(255, 255, 255), rgb(90, 200, 255), rgb(170, 170, 170)
GREEN, YELLOW, RED, GREY, TRACK = (rgb(60, 220, 90), rgb(250, 210, 40), rgb(240, 60, 60),
                                   rgb(140, 140, 140), rgb(55, 55, 70))

FONT = {
    "0": (0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E), "1": (0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E),
    "2": (0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F), "3": (0x1F, 0x02, 0x04, 0x02, 0x01, 0x11, 0x0E),
    "4": (0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02), "5": (0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E),
    "6": (0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E), "7": (0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08),
    "8": (0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E), "9": (0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C),
    "F": (0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10), "P": (0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10),
    "S": (0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E), "C": (0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E),
    "U": (0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E), "R": (0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11),
    "A": (0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11), "M": (0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11),
    "D": (0x1C, 0x12, 0x11, 0x11, 0x11, 0x12, 0x1C), "/": (0x01, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10),
    "I": (0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E), "O": (0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E),
    "K": (0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11), "B": (0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E), "%": (0x18, 0x19, 0x02, 0x04, 0x08, 0x13, 0x03), "-": (0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00),
    "+": (0x00, 0x04, 0x04, 0x1F, 0x04, 0x04, 0x00), " ": (0,) * 7,
    "E": (0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F), "T": (0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04),
    "Y": (0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04), "L": (0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F),
    "W": (0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A), "H": (0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11),
    "G": (0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F), "N": (0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11),
    "V": (0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04), "X": (0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11),
    "Z": (0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F), "J": (0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C),
    "Q": (0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D), "!": (0x04, 0x04, 0x04, 0x04, 0x04, 0x00, 0x04),
    ":": (0x00, 0x0C, 0x0C, 0x00, 0x0C, 0x0C, 0x00),
}
NARROW = {".": (0, 0, 0, 0, 0, 0, 1)}   # 1 pixel wide dot

class Bar:
    def __init__(self):
        self.px = [BG] * (W * H)
    def clear(self):
        self.px = [BG] * (W * H)
    def rect(self, x, y, w, h, c):
        for yy in range(max(0, y), min(H, y + h)):
            row = yy * W
            for xx in range(max(0, x), min(W, x + w)):
                self.px[row + xx] = c
    def frame(self, x, y, w, h, c):
        self.rect(x, y, w, 1, c); self.rect(x, y + h - 1, w, 1, c)
        self.rect(x, y, 1, h, c); self.rect(x + w - 1, y, 1, h, c)
    def text(self, x, y, s, c):
        for ch in s:
            if ch in NARROW:
                g, cw, adv = NARROW[ch], 1, 2
            else:
                g, cw, adv = FONT.get(ch, FONT[" "]), 5, 6
            for r, bits in enumerate(g):
                for col in range(cw):
                    if bits & (1 << (cw - 1 - col)) and 0 <= x + col < W:
                        self.px[(y + r) * W + x + col] = c
            x += adv
        return x
    def data(self):
        return struct.pack("<%dH" % (W * H), *self.px)

def read_int(path):
    try:
        return int(open(path).read())
    except (OSError, ValueError):
        return None

def cpu_times():
    res = {}
    for line in open("/proc/stat"):
        if not line.startswith("cpu"):
            break
        f = line.split()
        v = list(map(int, f[1:8]))
        res[f[0]] = (v[3] + v[4], sum(v))
    return res

def find_temp():
    zones = sorted(glob.glob("/sys/class/thermal/thermal_zone*"))
    for z in zones:
        try:
            if any(k in open(z + "/type").read().lower() for k in ("cpu", "soc")):
                return z + "/temp"
        except OSError:
            pass
    return zones[0] + "/temp" if zones else None
TEMP = find_temp()

def wifi_state():
    """None = no (supported) WiFi stick, else (switched on, connected, signal 0..1)."""
    devs = sorted(glob.glob("/sys/class/net/wl*"))
    if not devs:
        return None
    d = devs[0]
    try:
        admin_up = bool(int(open(d + "/flags").read(), 16) & 1)
        connected = open(d + "/operstate").read().strip() == "up"
    except (OSError, ValueError):
        return None
    q = None
    try:
        name = os.path.basename(d) + ":"
        for line in open("/proc/net/wireless"):
            f = line.split()
            if f and f[0] == name:
                q = min(1.0, float(f[2].rstrip(".")) / 70.0)
    except (OSError, ValueError, IndexError):
        pass
    return admin_up, connected, q

AUDIO_CONF = "/etc/picocalc.conf"
AUDIO_MOD = "/sys/module/picocalc_snd_pwm"

def audio_state():
    """None = sound disabled permanently (config) or driver not loaded,
    else True = muted, False = on. Volume is set with the wheel."""
    try:
        for line in open(AUDIO_CONF):
            k, _, v = line.strip().partition("=")
            if k.strip().upper() == "AUDIO" and v.strip().strip('"').lower() in ("off", "0", "no", "disabled"):
                return None
    except OSError:
        pass
    if not os.path.isdir(AUDIO_MOD):
        return None
    return bool(read_int(AUDIO_MOD + "/parameters/mute") or 0)

def sd_sectors():
    try:
        f = open(SD).read().split()
        return int(f[2]) + int(f[6])   # sectors read + written (512 bytes each)
    except (OSError, ValueError, IndexError):
        return None

def pct(old, new):
    di, dt = new[0] - old[0], new[1] - old[1]
    return max(0.0, min(100.0, 100.0 * (1 - di / dt))) if dt > 0 else 0.0

class Stats:
    def __init__(self):
        self.t = time.monotonic()
        self.spi, self.cpu, self.sd = read_int(SPI) or 0, cpu_times(), sd_sectors()
        self.bat, self.chg, self.bat_t = None, False, 0
    def sample(self):
        now = time.monotonic(); dt = max(now - self.t, 0.01)
        spi = read_int(SPI) or 0
        fps = max(spi - self.spi, 0) / FRAME / dt
        cpu = cpu_times()
        total = pct(self.cpu.get("cpu", (0, 0)), cpu.get("cpu", (0, 0)))
        cores = [pct(self.cpu.get("cpu%d" % i, (0, 0)), cpu.get("cpu%d" % i, (0, 0)))
                 if "cpu%d" % i in cpu else None for i in range(CORES)]
        mi = {}
        for line in open("/proc/meminfo"):
            k, v = line.split(":", 1); mi[k] = int(v.split()[0])
        tot = mi["MemTotal"]; used = tot - mi.get("MemAvailable", mi["MemFree"])
        sd = sd_sectors()
        sdmb = (sd - self.sd) * 512 / 1048576 / dt if sd is not None and self.sd is not None else None
        temp = read_int(TEMP) if TEMP else None
        if now - self.bat_t >= 1:
            v = read_int(BAT)
            self.bat, self.chg = (None, False) if v is None else (v & 127, bool(v & 128))
            self.bat_t = now
        self.t, self.spi, self.cpu, self.sd = now, spi, cpu, sd
        return dict(wifi=wifi_state(), audio=audio_state(), fps=fps, cpu=total, cores=cores, ram=100.0 * used / tot,
                    used=round(used / 1024), tot=round(tot / 1024), sd=sdmb, temp=None if temp is None else temp / 1000.0, bat=self.bat, chg=self.chg)

def load_col(p):
    return GREEN if p < 50 else YELLOW if p < 85 else RED

def rtext(bar, right, y, s, c):
    """Right-aligned text ending at 'right'."""
    w = sum(2 if ch in NARROW else 6 for ch in s)
    bar.text(right - w, y, s, c)
    return right - w

def tw(s):
    """Width of a text in pixels (including 1 pixel of space after the last character)."""
    return sum(2 if ch in NARROW else 6 for ch in s)

# WiFi icon 9x7: three arcs + dot (more arcs light up with better signal)
WIFI_ARCS = [
    {0: ".#######.", 1: "#.......#"},   # outer
    {2: "..#####..", 3: ".#.....#."},   # middle
    {4: "...###..."},                   # inner
    {6: "....#...."},                   # dot
]

def put(bar, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        bar.px[y * W + x] = c

def cross(bar, x, y, size, c):
    for i in range(size):
        put(bar, x + i, y + i, c); put(bar, x + size - 1 - i, y + i, c)

def wifi_icon(bar, x, y, lit, col):
    """lit = how many parts light up (from the inside out: dot, inner, middle, outer)."""
    for i, arc in enumerate(WIFI_ARCS):
        c = col if (3 - i) < lit else TRACK
        for row, pat in arc.items():
            for col_i, ch in enumerate(pat):
                if ch == "#":
                    put(bar, x + col_i, y + row, c)

def draw_wifi(bar, x, y, w):
    if w is None:                       # no stick detected
        wifi_icon(bar, x, y, 0, TRACK); cross(bar, x + 5, y + 3, 4, RED)
        return
    admin_up, connected, q = w
    if not admin_up:                    # stick present, WiFi off
        wifi_icon(bar, x, y, 4, GREY)
    elif not connected:                 # on, but not connected
        wifi_icon(bar, x, y, 4, YELLOW)
    else:                               # connected, arcs = signal
        lit = 4 if q is None or q >= 0.66 else 3 if q >= 0.33 else 2
        wifi_icon(bar, x, y, lit, GREEN)

WIFI_W = 9
AUDIO_W = 10

def speaker(bar, x, y, c):
    bar.rect(x, y + 2, 2, 3, c)                     # body
    bar.rect(x + 2, y + 1, 1, 5, c)                 # cone
    bar.rect(x + 3, y, 1, 7, c)

def draw_audio(bar, x, y, a):
    if a is None:                       # disabled permanently
        speaker(bar, x, y, TRACK)
        for i in range(8):
            put(bar, x + 1 + i, y + 6 - (i * 6) // 7, RED)
        return
    speaker(bar, x, y, FG)
    if a:                               # muted
        cross(bar, x + 5, y + 1, 5, RED)
        return
    waves = 3                           # on (volume is set with the wheel)
    shapes = [  # per wave: vertical part + corners
        [(5, 2), (5, 3), (5, 4)],
        [(6, 1), (7, 2), (7, 3), (7, 4), (6, 5)],
        [(8, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (8, 6)],
    ]
    for i, pts in enumerate(shapes):
        c = GREEN if i < waves else TRACK
        for dx, dy in pts:
            put(bar, x + dx, y + dy, c)

def read_alert():
    """Returns (level, text): level "WARN" (orange) or "CRIT" (red); text "" = no alert."""
    try:
        with open(ALERT) as f:
            s = f.read().strip().upper()
    except OSError:
        return "CRIT", ""
    level = "CRIT"
    if s[:5] in ("WARN:", "CRIT:"):
        level, s = s[:4], s[5:].strip()
    return level, s[:50]

ORANGE = rgb(255, 140, 0)
ALERT_COLOURS = {"WARN": ORANGE, "CRIT": RED}

def render_alert(bar, level, msg, blink):
    """Blinks between a coloured bar (white text) and a black bar (coloured text)."""
    col = ALERT_COLOURS.get(level, RED)
    bar.rect(0, 0, W, H, col if blink else rgb(0, 0, 0))
    bar.text(max(1, (W - tw(msg)) // 2), 2, msg, FG if blink else col)
    return bar.data()

def render(bar, s):
    bar.clear()
    fps = "%d" % round(s["fps"])
    cpu = "%d%%" % round(s["cpu"])
    mb = "%d/%dMB" % (s["used"], s["tot"])
    v = s["sd"]
    sd = "--.-MB" if v is None else "%04.1fMB" % min(v, 99.9)
    t = s["temp"]
    temp = "--C" if t is None else "%dC" % round(t)
    bat = s["bat"]
    battxt = "--%" if bat is None else "%d%%" % bat

    # visible width of each section (without the space after the last character)
    widths = [
        tw("FPS") + 1 + tw(fps) - 1,
        tw("CPU") + 1 + tw(cpu) + 1 + 14,
        tw("RAM") + 1 + tw(mb) - 1,
        tw("SD") + 1 + tw(sd) - 1,
        WIFI_W,
        AUDIO_W,
        tw(temp) - 1,
        16 + 3 + tw(battxt) - 1,
    ]
    # spread the remaining space evenly over the gaps (margin: 1 pixel left and right)
    n = len(widths) - 1
    free = (W - 2) - sum(widths)
    gaps = [free // n + (1 if i < free % n else 0) for i in range(n)]
    xs = [1]
    for w, g in zip(widths, gaps):
        xs.append(xs[-1] + w + g)

    # FPS
    x = bar.text(xs[0], 2, "FPS", LBL); bar.text(x + 1, 2, fps, FG)
    # CPU total, followed by the 3 cores as bars
    x = bar.text(xs[1], 2, "CPU", LBL); x = bar.text(x + 1, 2, cpu, FG)
    for i, c in enumerate(s["cores"]):
        bx = x + 1 + i * 5
        bar.rect(bx, 1, 4, 9, TRACK)
        if c:
            h = max(1, round(9 * c / 100))
            bar.rect(bx, 10 - h, 4, h, load_col(c))
    # RAM in MB
    x = bar.text(xs[2], 2, "RAM", LBL); bar.text(x + 1, 2, mb, FG)
    # SD: system SD card read + write in MB/s, always in the format XX.X
    x = bar.text(xs[3], 2, "SD", LBL); bar.text(x + 1, 2, sd, FG)
    # WiFi and sound icons
    draw_wifi(bar, xs[4], 2, s["wifi"])
    draw_audio(bar, xs[5], 2, s["audio"])
    # temperature
    tcol = GREY if t is None else GREEN if t < 60 else YELLOW if t < 75 else RED
    bar.text(xs[6], 2, temp, tcol)
    # battery (yellow frame = charging)
    bx = xs[7]
    col = GREY if bat is None else GREEN if bat >= 50 else YELLOW if bat >= 20 else RED
    frm = YELLOW if s["chg"] else FG
    bar.frame(bx, 2, 14, 7, frm); bar.rect(bx + 14, 4, 2, 3, frm)
    if bat:
        bar.rect(bx + 2, 4, max(1, 10 * min(bat, 100) // 100), 3, col)
    bar.text(bx + 19, 2, battxt, FG)
    return bar.data()

class DevOut:
    """Bar is drawn by the display driver on top of everything.
    Closing the device (or this program ending) removes it automatically."""
    def __init__(self):
        self.fd = os.open(OVL_DEV, os.O_WRONLY)
    def show(self, data):
        os.write(self.fd, data)
    def close(self):
        os.close(self.fd)

class FbOut:
    def __init__(self):
        self.fd = os.open(FB, os.O_RDWR)
        self.m = mmap.mmap(self.fd, W * H * 2)
        self.saved = None
        self.data = None
    def show(self, data):
        if self.saved is None:
            self.saved = self.m[:len(data)]
        self.data = data
        self.m[:len(data)] = data
    def guard(self):
        """Repaint the bar right away if the console has drawn over it."""
        if self.data and self.m[:len(self.data)] != self.data:
            self.m[:len(self.data)] = self.data
    def close(self):
        if self.saved:
            self.m[:len(self.saved)] = self.saved
        self.m.close(); os.close(self.fd)
        try:   # make the console redraw everything
            with open("/dev/tty0", "w") as t:
                t.write("\033[?5h\033[?5l")
        except OSError:
            pass

class XOut:
    def __init__(self):
        from Xlib import display, X
        self.X = X
        self.d = display.Display(":0")
        s = self.d.screen()
        self.depth = s.root_depth
        if self.depth != 16:
            raise RuntimeError("unsupported X depth %d" % self.depth)
        self.w = s.root.create_window(0, 0, W, H, 0, self.depth, X.InputOutput, X.CopyFromParent,
                                      override_redirect=True, background_pixel=s.black_pixel)
        self.gc = self.w.create_gc()
        self.w.map()
    def show(self, data):
        self.w.configure(stack_mode=self.X.Above)
        self.w.put_image(self.gc, 0, 0, W, H, self.X.ZPixmap, self.depth, 0, data)
        self.d.flush()
    def close(self):
        try:
            self.w.unmap(); self.d.flush(); self.d.close()
        except Exception:
            pass

enabled = False
wake = threading.Event()
def toggle(*_):
    global enabled
    enabled = not enabled
    wake.set()

def find_kbd():
    for n in glob.glob("/sys/class/input/event*/device/name"):
        try:
            if open(n).read().strip() == "picocalc_kbd":
                return "/dev/input/" + n.split("/")[4]
        except OSError:
            pass
    return None

def kbd_thread():
    size = struct.calcsize("IIHHi")
    while True:
        dev = find_kbd()
        if dev:
            try:
                with open(dev, "rb", buffering=0) as f:
                    while True:
                        ev = f.read(size)
                        if len(ev) < size:
                            break
                        _, _, typ, code, val = struct.unpack("IIHHi", ev)
                        if typ == 1 and code == KEY_PROG1 and val == 1:
                            toggle()
            except OSError:
                pass
        time.sleep(2)

def main():
    signal.signal(signal.SIGUSR1, toggle)
    signal.signal(signal.SIGUSR2, lambda *_: wake.set())
    threading.Thread(target=kbd_thread, daemon=True).start()
    bar, stats, fb, xo = Bar(), None, None, None
    next_render = 0.0
    blink = False
    while True:
        level, alert = read_alert()
        if not enabled and not alert:
            # hidden: measure nothing, just wait for Alt+O
            if fb:
                fb.close(); fb = None
            if xo:
                xo.close(); xo = None
            stats = None
            wake.wait(); wake.clear()
            continue
        if stats is None:
            stats = Stats()
            next_render = time.monotonic() + 0.5

        now = time.monotonic()
        if now >= next_render:
            if alert:
                next_render = now + 0.5
                blink = not blink
                data = render_alert(bar, level, alert, blink)
            else:
                next_render = now + INTERVAL
                data = render(bar, stats.sample())
            if os.path.exists(OVL_DEV):
                if xo:
                    xo.close(); xo = None
                if fb and not isinstance(fb, DevOut):
                    fb.close(); fb = None
                try:
                    fb = fb or DevOut()
                    fb.show(data)
                except OSError:
                    fb = None
            elif os.path.exists(XSOCK):
                if fb:
                    fb.close(); fb = None
                try:
                    xo = xo or XOut(); xo.show(data)
                except Exception:
                    if xo:
                        xo.close()
                    xo = None
            else:
                if xo:
                    xo.close(); xo = None
                try:
                    fb = fb or FbOut(); fb.show(data)
                except OSError:
                    fb = None
        if fb and not isinstance(fb, DevOut):
            # plain framebuffer: repaint the bar if the console drew over it
            fb.guard()
            wake.wait(GUARD_INTERVAL)
        else:
            wake.wait(max(0.0, next_render - time.monotonic()))
        wake.clear()

if __name__ == "__main__":
    main()
