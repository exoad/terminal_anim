math.randomseed(os.time())
local ramp = { " ", ".", ":", "-", "=", "+", "*", "#", "%", "@" }
local function clamp(v, a, b)
    if v < a then
        return a
    elseif v > b then
        return b
    end
    return v
end
local function rot_y(x, z, a)
    local c = math.cos(a)
    local s = math.sin(a)
    return x * c + z * s, -x * s + z * c
end
local function rot_x(y, z, a)
    local c = math.cos(a)
    local s = math.sin(a)
    return y * c - z * s, y * s + z * c
end

plugin = {
    meta = {
        name = "smiley_3d",
        version = "1.0.0",
        author = "exoad",
        description = "spinny smiley C:",
    },
    paint = function(ctx)
        local pixels = {}
        local w = ctx.width
        local h = ctx.height
        local cx = w * 0.5
        local cy = h * 0.5
        local r = math.max(6, math.min(w * 0.34, h * 0.8))
        local ar = 0.52
        local t = ctx.time
        local lx, ly, lz = 0.2, -0.3, 0.93
        local llen = math.sqrt(lx * lx + ly * ly + lz * lz)
        lx, ly, lz = lx / llen, ly / llen, lz / llen
        for y = 1, h do
            for x = 1, w do
                local nx = ((x - cx) / r) * ar
                local ny = (y - cy) / r
                local d2 = nx * nx + ny * ny
                if d2 <= 1 then
                    local nz = math.sqrt(1 - d2)
                    local ry, rz = rot_x(ny, nz, -t * 0.6)
                    local rx, rz2 = rot_y(nx, rz, -t * 1.1)
                    local lit = clamp(rx * lx + ry * ly + rz2 * lz, 0, 1)
                    local idx = clamp(math.floor(lit * (#ramp - 1) + 1.4), 1, #ramp)
                    local ch = ramp[idx]
                    local color = (lit > 0.8) and "97" or ((lit > 0.35) and "93" or "33")
                    if (rx + 0.34) ^ 2 + (ry - 0.30) ^ 2 < 0.032 and rz2 > 0 then
                        ch = "●"
                        color = "30;47"
                    elseif (rx - 0.34) ^ 2 + (ry - 0.30) ^ 2 < 0.032 and rz2 > 0 then
                        ch = "●"
                        color = "30;47"
                    elseif ry < -0.05 and ry > -0.62 and (rx * rx + (ry + 0.24) ^ 2) > 0.18 and (rx * rx + (ry + 0.24) ^ 2) < 0.31 and rz2 > 0 then
                        ch = "◡"
                        color = "30;47"
                    end
                    pixels[#pixels + 1] = { x = x, y = y, ch = ch, color = color }
                end
            end
        end

        return pixels
    end,
}
