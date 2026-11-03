#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float CORNER_CUT_SIZE = 16.0; 

uniform vec2 topLevelSize; 

void main() {
    vec2 pixel_coord = v_texcoord * topLevelSize;
    
    // Считаем расстояние до каждого из четырех краев приложения
    float dist_x = min(pixel_coord.x, topLevelSize.x - pixel_coord.x);
    float dist_y = min(pixel_coord.y, topLevelSize.y - pixel_coord.y);
    
    // Если пиксель находится в зоне диагонального отсечения — уничтожаем его
    if ((dist_x + dist_y) < CORNER_CUT_SIZE) {
        discard;
    }
    
    fragColor = texture(tex, v_texcoord);
}
