#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;      // размер в логических px
    float aberr;   // хроматическая аберрация, логические px
    float dpr;     // масштаб экрана (физические px на логический)
} ubuf;
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0 * 2.0 - 1.0;
    uv *= 1.0 - dot(uv, uv) * 0.010;
    vec2 p = clamp(uv * 0.5 + 0.5, vec2(0.0), vec2(1.0));

    // хроматическая аберрация (R и B смещены по горизонтали)
    vec2 px = vec2(ubuf.aberr) / ubuf.res;
    vec4 c = texture(source, p);
    float r = texture(source, clamp(p + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).r;
    float b = texture(source, clamp(p - vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).b;
    vec3 rgb = vec3(r, c.g, b);

    float cellPx = max(2.0, floor(3.0 * ubuf.dpr + 0.5));
    vec2 cell = fract(p * ubuf.res * ubuf.dpr / cellPx);
    float line = max(step(0.88, cell.x), step(0.88, cell.y));
    rgb *= 1.0 - 0.055 * line;

    rgb *= 1.0 - 0.16 * dot(uv * 0.75, uv * 0.75);

    rgb = min(rgb, vec3(c.a)); // premultiplied alpha
    fragColor = vec4(rgb, c.a) * ubuf.qt_Opacity;
}
