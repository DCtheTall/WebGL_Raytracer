precision mediump float;

const int MAXIMUM_NUMBER_OF_SPHERES = 8;
const int MAXIMUM_NUMBER_OF_CUBES = 8;
const int MAXIMUM_NUMBER_OF_LIGHTS = 8;
const int MAXIMUM_REFLECTION_DEPTH = 2;
const float FLOOR_PHONG_EXPONENT = 50.;
const float FLOOR_REFRACTIVE_INDEX = 1.3;

varying vec3 v_CameraViewPosition;
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
uniform float u_SphereRefractiveIndexes[MAXIMUM_NUMBER_OF_SPHERES];

uniform int u_NumberOfCubes;
uniform vec3 u_CubeMinExtents[MAXIMUM_NUMBER_OF_CUBES];
uniform vec3 u_CubeMaxExtents[MAXIMUM_NUMBER_OF_CUBES];
uniform mat3 u_CubeRotationInverses[MAXIMUM_NUMBER_OF_CUBES];
uniform vec3 u_CubePositions[MAXIMUM_NUMBER_OF_CUBES];
uniform vec3 u_CubeDiffuseColors[MAXIMUM_NUMBER_OF_CUBES];
uniform float u_CubePhongExponents[MAXIMUM_NUMBER_OF_CUBES];
uniform vec3 u_CubeSpecularColors[MAXIMUM_NUMBER_OF_CUBES];
uniform float u_CubeRefractiveIndexes[MAXIMUM_NUMBER_OF_CUBES];

#pragma glslify: getPlaneDiffuseColor = require('./color/get-plane-diffuse-color');
#pragma glslify: getPlaneSpecularColor = require('./color/get-plane-specular-color');
#pragma glslify: intersectPlane = require('./geometry/intersect-plane');
#pragma glslify: intersectSphere = require('./geometry/intersect-sphere');
#pragma glslify: intersectCube = require('./geometry/intersect-cube');
#pragma glslify: getCubeNormal = require('./geometry/get-cube-normal');
#pragma glslify: getDiffuseColor = require('./color/get-diffuse-color');
#pragma glslify: getSpecularColor = require('./color/get-specular-color');
#pragma glslify: testForShadow = require('./optics/test-for-shadow', MAXIMUM_NUMBER_OF_SPHERES=MAXIMUM_NUMBER_OF_SPHERES, MAXIMUM_NUMBER_OF_CUBES=MAXIMUM_NUMBER_OF_CUBES, spherePositions=spherePositions, sphereRadii=sphereRadii, cubeMinExtents=cubeMinExtents, cubeMaxExtents=cubeMaxExtents, cubeRotationInverses=cubeRotationInverses, cubePositions=cubePositions);
#pragma glslify: determineReflectance = require('./optics/determine-reflectance');

/**
 * Get natural color of the surface
 */
vec3 getNaturalColor(
  vec3 diffuseColor,
  float phongExponent,
  vec3 specularColor,
  vec3 surfaceNormal,
  vec3 rayDirection,
  vec3 position
) {
  vec3 color;

  color = vec3(0.);

  for (int i = 0; i < MAXIMUM_NUMBER_OF_LIGHTS; i += 1) {
    if (i == u_NumberOfLights) break;

    float lambertianMax;
    float specularMax;
    bool isInShadow[4];

    lambertianMax = 1.;
    specularMax = 1.;
    for (int j = 0; j < 4; j += 1) isInShadow[j] = false;
    testForShadow(
      position,
      u_LightPositions[i],
      surfaceNormal,
      length(u_LightPositions[i] - position),
      u_NumberOfSpheres,
      u_SpherePositions,
      u_SphereRadii,
      u_NumberOfCubes,
      u_CubeMinExtents,
      u_CubeMaxExtents,
      u_CubeRotationInverses,
      u_CubePositions,
      isInShadow
    );
    for (int j = 0; j < 4; j += 1) {
      if (isInShadow[j]) {
        lambertianMax -= .2;
        specularMax -= 0.2475;
      }
    }

    color += diffuseColor * u_AmbientLightColor;
    color += lambertianMax * getDiffuseColor(
      u_LightPositions[i],
      u_LightColors[i],
      position,
      surfaceNormal,
      diffuseColor
    );
    color += specularMax * getSpecularColor(
      u_LightPositions[i],
      u_LightColors[i],
      rayDirection,
      position,
      surfaceNormal,
      phongExponent,
      specularColor
    );
  }
  return color;
}

/**
 * Get the reflected color of the surface
 */
vec3 getReflectedColor(
  vec3 reflectionPosition,
  vec3 reflectionSurfaceNormal,
  vec3 rayDirection,
  float reflectance
) {
  vec3 color;
  float currentReflectance;
  vec3 reflectedRayDirection;

  color = vec3(0.);
  currentReflectance = reflectance;

  for (int i = 0; i < MAXIMUM_REFLECTION_DEPTH; i += 1) {
    float closestDistance;
    float dist;
    vec3 position;
    vec3 surfaceNormal;
    vec3 diffuseColor;
    float phongExponent;
    vec3 specularColor;
    float refractiveIndex;

    reflectedRayDirection = reflect(rayDirection, reflectionSurfaceNormal);
    closestDistance = -1.;

    for (int j = 0; j < MAXIMUM_NUMBER_OF_SPHERES; j += 1) {
      if (j == u_NumberOfSpheres) break;

      dist = intersectSphere(
        reflectionPosition,
        reflectedRayDirection,
        u_SpherePositions[j],
        u_SphereRadii[j]
      );

      if ((closestDistance < 0. && dist > 0.)
          || (dist > 0. && dist < closestDistance)) {
        closestDistance = dist;
        position = reflectionPosition + (dist * reflectedRayDirection);
        surfaceNormal = normalize(position - u_SpherePositions[j]);
        diffuseColor = u_SphereDiffuseColors[j];
        phongExponent = u_SpherePhongExponents[j];
        specularColor = u_SphereSpecularColors[j];
        refractiveIndex = u_SphereRefractiveIndexes[j];
      }
    }

    for (int j = 0; j < MAXIMUM_NUMBER_OF_CUBES; j += 1) {
      if (j == u_NumberOfCubes) break;

      dist = intersectCube(
        reflectionPosition,
        reflectedRayDirection,
        u_CubeMinExtents[j],
        u_CubeMaxExtents[j],
        u_CubeRotationInverses[j],
        u_CubePositions[j]
      );

      if ((closestDistance < 0. && dist > 0.)
          || (dist > 0. && dist < closestDistance)) {
        closestDistance = dist;
        position = reflectionPosition + (dist * reflectedRayDirection);
        surfaceNormal = normalize(position - u_CubePositions[j]);
        diffuseColor = u_CubeDiffuseColors[j];
        phongExponent = u_CubePhongExponents[j];
        specularColor = u_CubeSpecularColors[j];
        refractiveIndex = u_CubeRefractiveIndexes[j];
      }
    }

    dist = intersectPlane(reflectionPosition, reflectedRayDirection);
    if ((dist > 0. && closestDistance == -1.)
        || (dist > 0. && dist < closestDistance)) {
      closestDistance = dist;
      position = reflectionPosition + (dist * reflectedRayDirection);
      surfaceNormal = vec3(0., 1., 0.);
      diffuseColor = getPlaneDiffuseColor(position);
      phongExponent = FLOOR_PHONG_EXPONENT;
      specularColor = getPlaneSpecularColor(position);
      refractiveIndex = FLOOR_REFRACTIVE_INDEX;
    }

    if (dist > 0.) {
      vec3 c = getNaturalColor(
        diffuseColor,
        phongExponent,
        specularColor,
        surfaceNormal,
        -reflectedRayDirection,
        position
      );
      currentReflectance *= determineReflectance(
        surfaceNormal,
        reflectedRayDirection,
        refractiveIndex
      );
      color += pow(currentReflectance, float(i + 1)) * c;

      reflectionPosition = position;
      reflectionSurfaceNormal = surfaceNormal;
      rayDirection = reflectedRayDirection;
    } else {
      break;
    }
  }

  return color;
}

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
  float refractiveIndex;
  float reflectance;

  color = vec3(0.);
  closestDistance = -1.;

  // Testing if the ray intersects the spheres
  for (int i = 0; i < MAXIMUM_NUMBER_OF_SPHERES; i += 1) {
    if (i == u_NumberOfSpheres) break;
    dist = intersectSphere(
      rayStart,
      rayDirection,
      u_SpherePositions[i],
      u_SphereRadii[i]
    );
    if ((dist > 0. && closestDistance == -1.)
        || (dist > 0. && dist < closestDistance)) {
      closestDistance = dist;
      position = rayStart + (dist * rayDirection);
      surfaceNormal = normalize(position - u_SpherePositions[i]);
      diffuseColor = u_SphereDiffuseColors[i];
      phongExponent = u_SpherePhongExponents[i];
      specularColor = u_SphereSpecularColors[i];
      refractiveIndex = u_SphereRefractiveIndexes[i];
    }
  }

  // Testing if the ray intersects the cubes
  for (int i = 0; i < MAXIMUM_NUMBER_OF_CUBES; i += 1) {
    if (i == u_NumberOfCubes) break;
    dist = intersectCube(
      rayStart,
      rayDirection,
      u_CubeMinExtents[i],
      u_CubeMaxExtents[i],
      u_CubeRotationInverses[i],
      u_CubePositions[i]
    );
    if ((dist > 0. && closestDistance == -1.)
        || (dist > 0. && dist < closestDistance)) {
      closestDistance = dist;
      position = rayStart + (dist * rayDirection);
      surfaceNormal = getCubeNormal(
        rayStart,
        rayDirection,
        u_CubeMinExtents[i],
        u_CubeMaxExtents[i],
        u_CubeRotationInverses[i],
        u_CubePositions[i]
      );
      diffuseColor = u_CubeDiffuseColors[i];
      phongExponent = u_CubePhongExponents[i];
      specularColor = u_CubeSpecularColors[i];
      refractiveIndex = u_CubeRefractiveIndexes[i];
    }
  }

  // Testing if the ray interests the ground plane
  dist = intersectPlane(rayStart, rayDirection);
  if ((dist > 0. && closestDistance == -1.)
      || (dist > 0. && dist < closestDistance)) {
    closestDistance = dist;
    position = rayStart + (dist * rayDirection);
    surfaceNormal = vec3(0., 1., 0.);
    diffuseColor = getPlaneDiffuseColor(position);
    phongExponent = FLOOR_PHONG_EXPONENT;
    specularColor = getPlaneSpecularColor(position);
    refractiveIndex = FLOOR_REFRACTIVE_INDEX;
  }

  // Determine color of the fragment
  if (closestDistance > 0.) {
    color = getNaturalColor(
      diffuseColor,
      phongExponent,
      specularColor,
      surfaceNormal,
      -rayDirection,
      position
    );
    reflectance = determineReflectance(
      surfaceNormal,
      rayDirection,
      refractiveIndex
    );
    color += getReflectedColor(
      position,
      surfaceNormal,
      rayDirection,
      reflectance
    );
  }

  return color;
}

/*
 * MAIM PROGRAM
 */
void main() {
  vec3 fragColor;
  fragColor = intersectScene(u_CameraPosition + v_CameraViewPosition, normalize(v_CameraViewDirection));
  gl_FragColor = vec4(fragColor, 1.);
}
