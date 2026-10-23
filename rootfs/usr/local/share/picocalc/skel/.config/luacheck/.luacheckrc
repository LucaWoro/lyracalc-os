-- luacheck for PICO-8 and TIC-80 carts (standard Lua syntax only)
std = "max"
max_line_length = false
allow_defined = true
ignore = {"131"}
unused_args = false
globals = {
  "_init", "_update", "_update60", "_draw",                -- PICO-8
  "TIC", "SCN", "BDR", "OVR", "BOOT", "MENU",              -- TIC-80
}
read_globals = {
  -- PICO-8
  "print", "cls", "spr", "sspr", "map", "mget", "mset", "btn", "btnp", "sfx", "music",
  "pal", "palt", "fillp", "circ", "circfill", "oval", "ovalfill", "rect", "rectfill",
  "line", "pset", "pget", "sget", "sset", "fget", "fset", "camera", "clip", "color",
  "cursor", "flip", "rnd", "srand", "flr", "ceil", "abs", "min", "max", "mid", "sgn",
  "sin", "cos", "atan2", "sqrt", "band", "bor", "bxor", "bnot", "shl", "shr", "lshr",
  "rotl", "rotr", "tostr", "tonum", "chr", "ord", "sub", "split", "add", "del", "deli",
  "count", "all", "foreach", "stat", "time", "t", "peek", "poke", "peek2", "poke2",
  "peek4", "poke4", "memcpy", "memset", "reload", "cstore", "cartdata", "dget", "dset",
  "menuitem", "extcmd", "printh", "run", "stop", "trace", "yield", "cocreate",
  "coresume", "costatus", "tline", "serial", "reset", "holdframe",
  -- TIC-80
  "circb", "elli", "ellib", "exit", "font", "key", "keyp", "mouse", "peek1", "poke1",
  "pix", "pmem", "rectb", "sync", "tstamp", "tri", "trib", "textri", "ttri", "vbank",
}
