#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    float dpr;
    vec4 c0;   // суша (тёмный фон)
    vec4 c1;   // здания, вода, парки, подписи
    vec4 c2;   // дороги
} ubuf;
layout(binding = 1) uniform sampler2D source;

void main() {
    float px = max(2.0, floor(3.0 * ubuf.dpr + 0.5)) / ubuf.dpr;
    vec2 cell = floor(qt_TexCoord0 * ubuf.res / px);
    vec2 uv = (cell + 0.5) * px / ubuf.res;
    vec4 t = texture(source, uv);
    vec3 col = t.rgb / max(t.a, 0.001);

    vec3 land = vec3(0.949, 0.937, 0.914);            // цвет суши в стандартных тайлах OSM
    float mn = min(col.r, min(col.g, col.b));

    vec4 o;
    if (t.a < 0.5)                       o = ubuf.c0; // тайл не загружен
    else if (mn > 0.96)                  o = ubuf.c2; // белые дороги
    else if (distance(col, land) < 0.04) o = ubuf.c0; // суша
    else                                 o = ubuf.c1; // всё остальное

    fragColor = vec4(o.rgb, 1.0) * ubuf.qt_Opacity;
}
