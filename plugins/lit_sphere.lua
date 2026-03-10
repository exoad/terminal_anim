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

plugin = {
    meta = {
        name = "lit_sphere",
        version = "1.0.0",
        author = "exoad",
        description = "fake lit ball",
    },
   -- a lot of the math here was "inspired" (literally copied) from a wikipedia article 
    paint = function(ctx)
        local pixels = {}
        local cx = ctx.width * 0.5
        local cy = ctx.height * 0.5
        local r = math.max(4, math.min(ctx.width * 0.26, ctx.height * 0.45))
        local lx = math.cos(ctx.time * 0.5)
        local ly = math.sin(ctx.time * 0.3) * 0.35
        local lz = 0.9
        local llen = math.sqrt(lx * lx + ly * ly + lz * lz)
        lx, ly, lz = lx / llen, ly / llen, lz / llen
        for y = 1, ctx.height do
            for x = 1, ctx.width do
                local nx = (x - cx) / r
                local ny = (y - cy) / r
                local d2 = nx * nx + ny * ny
                if d2 <= 1 then
                    local nz = math.sqrt(1 - d2)
                    local ndotl = nx * lx + ny * ly + nz * lz
                    local rim = clamp(1 - nz, 0, 1)
                    local spec = clamp((ndotl - 0.75) * 4, 0, 1)
                    local shade = clamp(ndotl * 0.85 + (1 - rim) * 0.15 + spec * 0.55, 0, 1)
                    local i = clamp(math.floor(shade * (#ramp - 1) + 1.5), 1, #ramp)
                    local color = "37"
                    if shade > 0.82 then
                        color = "97"
                    elseif shade > 0.58 then
                        color = "96"
                    elseif shade > 0.35 then
                        color = "36"
                    else
                        color = "34"
                    end
                    pixels[#pixels + 1] = { x = x, y = y, ch = ramp[i], color = color }
                elseif d2 <= 1.08 then
                    pixels[#pixels + 1] = { x = x, y = y, ch = ".", color = "2;120;120;120" }
                end
            end
        end
        return pixels
    end,
}
