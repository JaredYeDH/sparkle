#version 430 core

uniform mat4 uMVP;
uniform mat4 uView;
uniform float uSpriteSizeRatio;

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

in VDataBlock {
  vec3 position;
  vec3 velocity;
  vec3 color;
  float decay;
  float pointSize;
} IN[];

out GDataBlock {
  vec3 color;
  vec2 texcoord;
  float decay;
} OUT;

void main() {
  mat3 view = mat3(uView);

  // Calculate screen-space velocity.
  vec3 u = view * IN[0].velocity;

  const float dp_u = dot(u, u);

  // closer to 1, the particle velocity face the camera
  float nz = abs((u*inversesqrt(dp_u)).z);
  nz *= nz;

  // stretched billboard dimensions.
  const float w = 0.20f; // TODO : change interactively
  const float speed = smoothstep(0.0f, 750.0f, dp_u);

  // when face to the camera, the particle is not stretched.
  float h = mix(0.1f, uSpriteSizeRatio, speed);
  h = mix(h, 1.0f, nz) * w;

  // compute screen-space velocity
  u.z = 0.0;
  u = normalize(u);

  // orthogonal screen-space vector.
  vec3 v = vec3(-u.y, u.x, 0.0f);

  // compute the change of basis matrix.
  vec3 a = v * view;
  vec3 b = u * view;
  vec3 c = cross(a, b);
  mat3 basis = mat3(a, b, c);

  // vertices offset.
  vec3 N = basis * vec3(0,  h, 0);
  vec3 E = basis * vec3(w,  0, 0);
  vec3 S = basis * vec3(0, -h, 0);
  vec3 W = basis * vec3(-w, 0, 0);

  // Emit the quad primitive.
  OUT.color = IN[0].color;
  OUT.decay = IN[0].decay;

  vec3 p = IN[0].position;
  OUT.texcoord = vec2(0.0f, 0.0f); gl_Position = uMVP * vec4(p+W+S, 1.0f); EmitVertex();
  OUT.texcoord = vec2(1.0f, 0.0f); gl_Position = uMVP * vec4(p+E+S, 1.0f); EmitVertex();
  OUT.texcoord = vec2(0.0f, 1.0f); gl_Position = uMVP * vec4(p+W+N, 1.0f); EmitVertex();
  OUT.texcoord = vec2(1.0f, 1.0f); gl_Position = uMVP * vec4(p+E+N, 1.0f); EmitVertex();
  EndPrimitive();
}
