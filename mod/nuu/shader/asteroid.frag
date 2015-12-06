uniform sampler2D tex0;
uniform sampler2D star_spectrum;
uniform float seed;
uniform float time;
uniform float temperature;
uniform vec3 light;

varying vec3 vNormal;
varying vec2 vTex;
varying float vElevator;
varying float vNoiser;

float shading(vec3 position){
  vec3 l = normalize(light);
  return max(0.015, dot(position, l)); }

void main() {
  vec2 p = vTex;
  vec4 c = vec4(vElevator,vElevator,vElevator,1.);
  if      ( vElevator > 0.9   ) { c += vec4(vElevator,vElevator*.3,vElevator+vNoiser,1.);}
  else if ( vElevator > 0.3   ) { c += vec4(vElevator*.2+vNoiser,vElevator+vNoiser,vElevator,1.);}
  else if ( vElevator > 0.205 ) { c += vec4(1.,vElevator,0.,1.);}
  else if ( vElevator > 0.2   ) { c += vec4(.8,vNoiser*.7,vElevator*.3,1.);}
  else                 { c += vec4(.1,vNoiser*.05,vNoiser*.5,1.);}
  gl_FragColor = vec4( c.xyz * shading(vNormal.xyz), 1.);}
