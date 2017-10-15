precision mediump float;

const int MAXIMUM_NUMBER_OF_SPHERES = 16;
const int MAXIMUM_NUMBER_OF_LIGHTS = 8;

varying vec3 v_CameraViewDirection;

uniform vec3 u_CameraPosition;
uniform vec3 u_AmbientLightColor;

uniform int u_NumberOfLights;
uniform vec3 u_LightPositions[MAXIMUM_NUMBER_OF_LIGHTS];
uniform vec3 u_LightColors[MAXIMUM_NUMBER_OF_LIGHTS];

uniform int u_NumberOfSpheres;
uniform vec3 u_SpherePositions[MAXIMUM_NUMBER_OF_SPHERES];
uniform float u_SphereRadii[MAXIMUM_NUMBER_OF_SPHERES];
uniform vec3 u_SphereDiffuseColors[MAXIMUM_NUMBER_OF_SPHERES];
uniform float u_SpherePhongExponents[MAXIMUM_NUMBER_OF_SPHERES];
uniform vec3 u_SphereSpecularColors[MAXIMUM_NUMBER_OF_SPHERES];

#pragma glslify: intersectSphere = require('./geometry/intersect-sphere');
#pragma glslify: getDiffuseColor = require('./color/get-diffuse-color');
#pragma glslify: getSpecularColor = require('./color/get-specular-color');

/*
 * Ray intersection test for the scene
 */
vec3 intersectScene(vec3 rayStart, vec3 rayDirection) {
  vec3 color;
  float closestDistance;
  float dist;
  vec3 position;
  vec3 surfaceNormal;
  vec3 diffuseColor;
  float phongExponent;
  vec3 specularColor;

  color = vec3(0.);
  closestDistance = -1.;

  for (int i = 0; i < MAXIMUM_NUMBER_OF_SPHERES; i += 1) {
    if (i > u_NumberOfSpheres) break;
    dist = intersectSphere(rayStart, rayDirection, u_SpherePositions[i], u_SphereRadii[i]);
    if ((dist > 0. && closestDistance == -1.) || (dist > 0. && dist < closestDistance)) {
      closestDistance = dist;
      position = rayStart + (dist * rayDirection);
      surfaceNormal = normalize(position - u_SpherePositions[i]);
      diffuseColor = u_SphereDiffuseColors[i];
      phongExponent = u_SpherePhongExponents[i];
      specularColor = u_SphereSpecularColors[i];
    }
  }

  if (closestDistance > 0.) {
    for (int i = 0; i < MAXIMUM_NUMBER_OF_LIGHTS; i += 1) {
      if (i > u_NumberOfLights) break;
      color += diffuseColor * u_AmbientLightColor;
      color += getDiffuseColor(
        u_LightPositions[i],
        u_LightColors[i],
        position,
        surfaceNormal,
        diffuseColor
      );
      color += getSpecularColor(
        u_LightPositions[i],
        u_LightColors[i],
        rayDirection,
        position,
        surfaceNormal,
        phongExponent,
        specularColor
      );
    }
  }

  return color;
}

/*
 * MAIM PROGRAM
 */
void main() {
  vec3 viewDirection;
  vec3 fragColor;
  viewDirection = normalize(v_CameraViewDirection - u_CameraPosition);
  fragColor = intersectScene(u_CameraPosition, viewDirection);
  gl_FragColor = vec4(fragColor, 1.);
}
