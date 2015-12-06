
varying vec3 vNormal;
varying vec2 vTex;

void main() {
  vNormal = normal;
  vTex    = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
