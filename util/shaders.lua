local M = {}

local test_code = [[
vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 screen_coords) {
    return Texel(tex, texcoord);
}
]]

local test_shader = love.graphics.newShader(test_code)

local glow_code = [[
extern float time;

const float blur_radius = 5.0;

vec4 effect(vec4 input_color, Image tex, vec2 texcoord, vec2 screen_coords) {
    vec3 base = input_color.rgb;
    float alpha = input_color.a;

    // Distance-based blur emulation via surrounding alpha (approximate bloom)
    float glow = 0.0;
    for (float x = -blur_radius; x <= blur_radius; x++) {
        for (float y = -blur_radius; y <= blur_radius; y++) {
            glow += Texel(tex, texcoord + vec2(x, y) / 256.0).a;
        }
    }

    glow /= 25.0; // normalize

    // Add pulse
    float pulse = 0.75 + 0.25 * sin(time * 3.0);
    vec3 color = base * glow * pulse;

    return vec4(color, glow * pulse);
}
]]

local scanline_glow_code = [[
extern vec2 mousePosition;
extern vec2 buttonCenter;
extern vec2 buttonSize;
extern number hoverAmount;

extern float time;

const float blur_radius = 4.0;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    // --- Pixelation setup ---
    float screenDiagonal = length(love_ScreenSize.xy);
    float pixelSize = screenDiagonal * 0.06;
    vec2 screenUV = uv * love_ScreenSize.xy;
    vec2 pixelBlock = floor(screenUV / pixelSize);
    vec2 blockCenter = (pixelBlock + 0.5) * pixelSize;
    vec2 quantUV = blockCenter / love_ScreenSize.xy;

    vec4 base = Texel(tex, quantUV);

    // --- Shine band position based on mouse ---
    vec2 diag = normalize(vec2(1.0, 1.0)); // direction of band
    float maxOffset = dot(buttonSize, diag); // max travel distance

    float mouseDist = dot(mousePosition - buttonCenter, diag);
    float normOffset = clamp(mouseDist / maxOffset, -1.0, 1.0);

    // Nonlinear exponential-ish scale
    float scaledOffset = sign(normOffset) * pow(abs(normOffset), 0.5); // try 0.4–0.7 for tuning
    float bandCenter = dot(buttonCenter, diag) + scaledOffset * maxOffset;

    // --- Determine if pixel is inside the band ---
    float pixelDiag = dot(blockCenter, diag);
    float bandWidth = screenDiagonal * 0.2;
    float insideBand = step(abs(pixelDiag - bandCenter), bandWidth * 0.5);

    // --- Combine base and shine ---
    vec3 shineColor = vec3(1.0);
    vec3 finalColor = mix(base.rgb, shineColor, insideBand * hoverAmount * 0.1);

    base =  vec4(finalColor, base.a);

    float alpha = base.a;

    // Distance-based blur emulation via surrounding alpha (approximate bloom)
    float glow = 0.0;
    for (float x = -blur_radius; x <= blur_radius; x++) {
        for (float y = -blur_radius; y <= blur_radius; y++) {
            glow += Texel(tex, uv + vec2(x, y) / 256.0).a;
        }
    }

    glow /= 25.0; // normalize

    // Add pulse
    float pulse = 0.75 + 0.25 * sin(time * 3.0);
    finalColor = (base * glow * pulse).rgb;

    return vec4(finalColor, glow * pulse);
}
]]

local scanline_glow_shader = love.graphics.newShader(scanline_glow_code)

---@param amount number
---@param x integer
---@param y integer
---@param w integer
---@param h integer
function M.scanline_glow(amount, x, y, w, h)
	love.graphics.setShader(scanline_glow_shader)
	-- scanline_glow_shader:send("time", time)
	scanline_glow_shader:send("time", love.timer.getTime())
	scanline_glow_shader:send("mousePosition", { love.mouse.getPosition() })
	scanline_glow_shader:send("buttonCenter", { x + w / 2, y + h / 2 })
	scanline_glow_shader:send("buttonSize", { w, h })
	scanline_glow_shader:send("hoverAmount", amount)
end


local glow_shader = love.graphics.newShader(glow_code)

---@param time number
function M.glow(time)
	glow_shader:send("time", time)
	love.graphics.setShader(glow_shader)
end

local scanline_code = [[
extern vec2 mousePosition;
extern vec2 buttonCenter;
extern vec2 buttonSize;
extern number hoverAmount;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    // --- Pixelation setup ---
    float screenDiagonal = length(love_ScreenSize.xy);
    float pixelSize = screenDiagonal * 0.06;
    vec2 screenUV = uv * love_ScreenSize.xy;
    vec2 pixelBlock = floor(screenUV / pixelSize);
    vec2 blockCenter = (pixelBlock + 0.5) * pixelSize;
    vec2 quantUV = blockCenter / love_ScreenSize.xy;

    vec4 base = Texel(tex, quantUV);

    // --- Shine band position based on mouse ---
    vec2 diag = normalize(vec2(1.0, 1.0)); // direction of band
    float maxOffset = dot(buttonSize, diag); // max travel distance

    float mouseDist = dot(mousePosition - buttonCenter, diag);
    float normOffset = clamp(mouseDist / maxOffset, -1.0, 1.0);

    // Nonlinear exponential-ish scale
    float scaledOffset = sign(normOffset) * pow(abs(normOffset), 0.5); // try 0.4–0.7 for tuning
    float bandCenter = dot(buttonCenter, diag) + scaledOffset * maxOffset;

    // --- Determine if pixel is inside the band ---
    float pixelDiag = dot(blockCenter, diag);
    float bandWidth = screenDiagonal * 0.2;
    float insideBand = step(abs(pixelDiag - bandCenter), bandWidth * 0.5);

    // --- Combine base and shine ---
    vec3 shineColor = vec3(1.0);
    vec3 finalColor = mix(base.rgb, shineColor, insideBand * hoverAmount * 0.1);

    return vec4(finalColor, base.a);
}
]]

local scanline_shader = love.graphics.newShader(scanline_code)

---@param amount number
---@param x integer
---@param y integer
---@param w integer
---@param h integer
function M.scanline(amount, x, y, w, h)
	love.graphics.setShader(scanline_shader)
	-- scanline_shader:send("time", time)
	scanline_shader:send("mousePosition", { love.mouse.getPosition() })
	scanline_shader:send("buttonCenter", { x + w / 2, y + h / 2 })
	scanline_shader:send("buttonSize", { w, h })
	scanline_shader:send("hoverAmount", amount)
end

local border_code = [[
extern number time;
extern number border_thickness;
extern number corner_radius;
extern vec4 border_color;
extern vec2 rect_pos;
extern vec2 rect_size;

float roundedBoxSDF(vec2 p, vec2 size, float radius) {
    vec2 q = abs(p - size * 0.5) - (size * 0.5 - vec2(radius));
    return length(max(q, 0.0)) - radius;
}

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 fragCoord) {
    vec2 localPos = fragCoord - rect_pos;

    float dist = roundedBoxSDF(localPos, rect_size, corner_radius);
    float mask = smoothstep(border_thickness, 0.0, dist);

    float shimmer = 0.9 + 0.1 * sin(time * 2.0); // slow breathing glow
    vec4 glow = vec4(border_color.rgb, border_color.a * shimmer * mask);

    return glow * color;
}
]]

local border_shader = love.graphics.newShader(border_code)

---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param time number
---@param thickness number
---@param color number[]
function M.border(x, y, w, h, time, thickness, color)
	border_shader:send("time", time)
	border_shader:send("border_thickness", thickness)
	border_shader:send("border_color", color)
	border_shader:send("rect_pos", { x, y })
	border_shader:send("rect_size", { w, h })
	border_shader:send("corner_radius", 8) -- or whatever looks good
	love.graphics.setShader(border_shader)
end

local pulse_code = [[
extern float time;

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixel_coord) {
    // Gentle pulsing (between 0.9 and 1.0)
    float pulse = 0.95 + 0.05 * sin(time * 2.0);

    return vec4(color.rgb, color.a * pulse);
}
]]

local pulse_shader = love.graphics.newShader(pulse_code)

---@param time number
function M.pulse(time)
	pulse_shader:send("time", time)
	love.graphics.setShader(pulse_shader)
end

local aaPointSampleShaderCode = [[
// The default size, in pixels, of the antialiasing filter. The default is 1.0 for a mathematically perfect
// antialias. But if you want, you can increase this to 1.5, 2.0, 3.0 and such to force a bigger antialias zone
// than normal, using more screen pixels.
const float SMOOTH_SIZE = 1.0;

const float _HALF_SMOOTH = SMOOTH_SIZE / 2.0;

// The raw width and height of the image in pixels.
uniform vec2 imageSize;

// The horizontal and vertical scales used when drawing the image, making an image texel take several screen pixels.
uniform vec2 texelScale;

// The angle of rotation that the image was drawn with.
// Only used with the boundary antialiasing. This uniform can be removed if you don't need it.
uniform float angle;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // Map the UVs in this vertex from range [0, +1] to range [-1, +1].
    vec2 corner_direction = (VertexTexCoord.xy - 0.5) / 0.5;

    // Move the vertex by its UV direction to "expand" the quad mesh.
    float angleCos = cos(angle);
    float angleSin = sin(angle);
    mat2 sprite_rotation = mat2(angleCos, angleSin, -angleSin, angleCos); // Column-major.
    vertex_position.xy += sprite_rotation * (corner_direction * _HALF_SMOOTH);

    // The amount in UV units that the vertices were shifted.
    vec2 pixel_uv_size = _HALF_SMOOTH / imageSize;

    // Offset the texture coordinates so the contents of the quad remain the same.
    VaryingTexCoord.xy += pixel_uv_size * corner_direction / texelScale;

    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // The antialiasing is done with the UV coordinates of the pixel, sampling the
    // center of texels when the screen pixel is entirely contained in a texel, and
    // sampling an interpolation between the center of two neighboring texels when
    // the screen pixel is between the edge of those texels.

    // When modifying this, be aware of the three types of units being used:
    // A) Normalized UV space: [0, 0] -> [1, 1]
    // B) Image space: [0,0] -> [image_width, image_height]
    // C) "Screen pixel" space: [0, 0] -> [image_width*texelScale, image_height*texelScale]

    vec2 texel = texture_coords * imageSize;
    vec2 nearest_edge = floor(texel + 0.5);
    vec2 dist = (texel - nearest_edge) * texelScale;

    vec2 factor = clamp(dist/vec2(_HALF_SMOOTH), -1.0, 1.0);
    vec2 antialiased_uv = (nearest_edge + 0.5 * factor) / imageSize;
    if (Texel(tex, antialiased_uv).a == 0) {
      return vec4(0);
    }

    // Optional boundary antialiasing, making pixels transparent at the edges of the image.
    // This works in screen pixels, getting the distance from the center of the image to the
    // pixel being processed, and then calculating a value when that distance becomes larger than
    // half the image size minus _HALF_SMOOTH. The alpha is the unit complement (1 - x) of this value.

    /* Original code:
     * vec2 center_offset = abs(texture_coords - vec2(0.5));
     * vec2 halfSize = imageSize/2.0 * texelScale;
     * vec2 refSize = halfSize - _HALF_SMOOTH;
     * dist = (temp*imageSize*texelScale - refSize) / SMOOTH_SIZE;
     */
    vec2 center_offset = abs(texture_coords - vec2(0.5));
    dist = ((center_offset - 0.5) * imageSize * texelScale + _HALF_SMOOTH) / SMOOTH_SIZE;
    dist = clamp(dist, 0.0, 1.0);
    float alpha = 1.0 - max(dist.x, dist.y);
    vec4 texturecolor = vec4(Texel(tex, antialiased_uv).rgb, alpha);

    // Without boundary-antialiasing you can just use this line. Make sure to also remove the vertex shader
    // function at the top.
    //vec4 texturecolor = Texel(tex, antialiased_uv);

    return texturecolor * color;
}
#endif
]]

local pixel_shader = love.graphics.newShader(aaPointSampleShaderCode)

---@param w integer
---@param h integer
---@param sx number
---@param sy number
---@param r number
function M.pixel(w, h, sx, sy, r)
	pixel_shader:send("imageSize", { w, h })
	pixel_shader:send("texelScale", { sx, sy })
	pixel_shader:send("angle", r)
	love.graphics.setShader(pixel_shader)
end

local pixel_scanline_code = [[

extern vec2 mousePosition;
extern vec2 buttonCenter;
extern vec2 buttonSize;
extern number hoverAmount;

extern vec2 imageSize;
extern vec2 texelScale;
extern float angle;

const float SMOOTH_SIZE = 2.0;
const float _HALF_SMOOTH = SMOOTH_SIZE / 2.0;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // Map the UVs in this vertex from range [0, +1] to range [-1, +1].
    vec2 corner_direction = (VertexTexCoord.xy - 0.5) / 0.5;

    // Move the vertex by its UV direction to "expand" the quad mesh.
    float angleCos = cos(angle);
    float angleSin = sin(angle);
    mat2 sprite_rotation = mat2(angleCos, angleSin, -angleSin, angleCos); // Column-major.
    vertex_position.xy += sprite_rotation * (corner_direction * _HALF_SMOOTH);

    // The amount in UV units that the vertices were shifted.
    vec2 pixel_uv_size = _HALF_SMOOTH / imageSize;

    // Offset the texture coordinates so the contents of the quad remain the same.
    VaryingTexCoord.xy += pixel_uv_size * corner_direction / texelScale;

    return transform_projection * vertex_position;
}
#endif

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
    // The antialiasing is done with the UV coordinates of the pixel, sampling the
    // center of texels when the screen pixel is entirely contained in a texel, and
    // sampling an interpolation between the center of two neighboring texels when
    // the screen pixel is between the edge of those texels.

    // When modifying this, be aware of the three types of units being used:
    // A) Normalized UV space: [0, 0] -> [1, 1]
    // B) Image space: [0,0] -> [image_width, image_height]
    // C) "Screen pixel" space: [0, 0] -> [image_width*texelScale, image_height*texelScale]

    vec2 texel = uv * imageSize;
    vec2 nearest_edge = floor(texel + 0.5);
    vec2 dist = (texel - nearest_edge) * texelScale;

    vec2 factor = clamp(dist/vec2(_HALF_SMOOTH), -1.0, 1.0);
    vec2 antialiased_uv = (nearest_edge + 0.5 * factor) / imageSize;
    if (Texel(tex, antialiased_uv).a == 0) {
      return vec4(0);
    }

    // Optional boundary antialiasing, making pixels transparent at the edges of the image.
    // This works in screen pixels, getting the distance from the center of the image to the
    // pixel being processed, and then calculating a value when that distance becomes larger than
    // half the image size minus _HALF_SMOOTH. The alpha is the unit complement (1 - x) of this value.

    /* Original code:
     * vec2 center_offset = abs(uv - vec2(0.5));
     * vec2 halfSize = imageSize/2.0 * texelScale;
     * vec2 refSize = halfSize - _HALF_SMOOTH;
     * dist = (temp*imageSize*texelScale - refSize) / SMOOTH_SIZE;
     */
    vec2 center_offset = abs(uv - vec2(0.5));
    dist = ((center_offset - 0.5) * imageSize * texelScale + _HALF_SMOOTH) / SMOOTH_SIZE;
    dist = clamp(dist, 0.0, 1.0);
    float alpha = 1.0 - max(dist.x, dist.y);
    vec4 texturecolor = vec4(Texel(tex, antialiased_uv).rgb, alpha);

    // Without boundary-antialiasing you can just use this line. Make sure to also remove the vertex shader
    // function at the top.
    //vec4 texturecolor = Texel(tex, antialiased_uv);

    vec4 base = texturecolor * color;
    // Continue with scanline shader below

    // --- Pixelation setup ---
    float screenDiagonal = length(love_ScreenSize.xy);
    float pixelSize = screenDiagonal * 0.025;
    vec2 screenUV = uv * love_ScreenSize.xy;
    vec2 pixelBlock = floor(screenUV / pixelSize);
    vec2 blockCenter = (pixelBlock + 0.5) * pixelSize;
    vec2 quantUV = blockCenter / love_ScreenSize.xy;

    // --- Shine band position based on mouse ---
    vec2 diag = normalize(vec2(1.0, 1.0)); // direction of band
    float maxOffset = dot(buttonSize, diag); // max travel distance

    // Only move band if mouse is inside the button bounds
    vec2 halfSize = 0.5 * buttonSize;
    vec2 minBounds = buttonCenter - halfSize;
    vec2 maxBounds = buttonCenter + halfSize;
    bool mouseInside =
        mousePosition.x >= minBounds.x && mousePosition.x <= maxBounds.x &&
        mousePosition.y >= minBounds.y && mousePosition.y <= maxBounds.y;

    float scaledOffset = 0.0;
    if (mouseInside) {
        float mouseDist = dot(mousePosition - buttonCenter, diag);
        float normOffset = clamp(mouseDist / maxOffset, -1.0, 1.0);
        scaledOffset = sign(normOffset) * pow(abs(normOffset), 0.5); // nonlinear
    }

    float bandCenter = dot(buttonCenter, diag) + scaledOffset * maxOffset;

    // --- Determine if pixel is inside the band ---
    float pixelDiag = dot(blockCenter, diag);
    float bandWidth = screenDiagonal * 0.15;
    float insideBand = step(abs(pixelDiag - bandCenter), bandWidth * 0.5);

    // --- Combine base and shine ---
    vec3 shineColor = vec3(1.0);
    vec3 finalColor = mix(base.rgb, shineColor, insideBand * hoverAmount * 0.1);

    return vec4(finalColor, base.a);
}
  ]]

local pixel_scanline_shader = love.graphics.newShader(pixel_scanline_code)

---@param w integer
---@param h integer
---@param sx number
---@param sy number
---@param r number
function M.pixel_scanline(x, y, w, h, sx, sy, r)
	pixel_scanline_shader:send("mousePosition", { love.mouse.getPosition() })
	pixel_scanline_shader:send("buttonCenter", { x + w / 2, y + h / 2 })
	pixel_scanline_shader:send("buttonSize", { w, h })
	pixel_scanline_shader:send("hoverAmount", 1.)
	pixel_scanline_shader:send("imageSize", { w, h })
	pixel_scanline_shader:send("texelScale", { sx, sy })
	-- pixel_scanline_shader:send("angle", r)
	love.graphics.setShader(pixel_scanline_shader)
end

function M.reset()
	love.graphics.setShader()
end

return M
