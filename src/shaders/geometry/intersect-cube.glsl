/**
 * Ray intersection test for a cube
 */
float intersectCube(
  vec3 rayStart,
  vec3 rayDirection,
  in vec3 cubeMinExtent,
  in vec3 cubeMaxExtent,
  in mat3 cubeRotationInverse,
  in vec3 cubePosition
) {
  vec3 start;
  vec3 direction;
  float tNear;
  float tFar;
  vec3 tMin;
  vec3 tMax;
  float tEnter;
  float tExit;

  start = rayStart - cubePosition;
  start = cubeRotationInverse * start;
  direction = cubeRotationInverse * rayDirection;

  tNear = -1000000000.;
  tFar = 1000000000.;
  tMin = (cubeMinExtent - start) / direction;
  tMax = (cubeMaxExtent - start) / direction;

  tEnter = min(tMin.x, tMax.x);
  tExit = max(tMin.x, tMax.x);
  if (tEnter > tNear) tNear = tEnter;
  if (tExit < tFar) tFar = tExit;

  tEnter = min(tMin.y, tMax.y);
  tExit = max(tMin.y, tMax.y);
  if (tEnter > tNear) tNear = tEnter;
  if (tExit < tFar) tFar = tExit;

  tEnter = min(tMin.z, tMax.z);
  tExit = max(tMin.z, tMax.z);
  if (tEnter > tNear) tNear = tEnter;
  if (tExit < tFar) tFar = tExit;

  if (tNear < tFar) return tNear;
  return -1.;
}

#pragma glslify: export(intersectCube);
