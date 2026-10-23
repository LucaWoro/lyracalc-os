-- Linters for the micro linter plugin
function preinit()
    for _, n in ipairs({"gcc", "g++", "pyflakes", "luacheck", "shellcheck"}) do
        linter.removeLinter(n)
    end
    linter.makeLinter("shellcheck", "shell", "shellcheck", {"-f", "gcc", "%f"}, "%f:%l:%c: %m")
    linter.makeLinter("luacheck", "lua", "luacheck", {"--no-color", "--formatter=plain", "%f"}, "%f:%l:%c: %m")
    linter.makeLinter("pyflakes3", "python", "pyflakes3", {"%f"}, "%f:%l:%c: %m")
    linter.makeLinter("cppcheck-c", "c", "cppcheck",
        {"--enable=warning,style,performance,portability", "--template=gcc", "--quiet", "--language=c", "%f"}, "%f:%l:%c: %m")
    linter.makeLinter("cppcheck-cpp", "c++", "cppcheck",
        {"--enable=warning,style,performance,portability", "--template=gcc", "--quiet", "--language=c++", "%f"}, "%f:%l:%c: %m")
end
