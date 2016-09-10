/*

WebGL TypeScript Raytracer
--------------------------
Author: Dylan Cutler
--------------------

Main program

*/

import Raytracer from "./Raytracer";

function main(): void {
  let canvas: HTMLCanvasElement;
  let raytracer: Raytracer;

  canvas = document.createElement("canvas");
  canvas.width = 500;
  canvas.height = 500;
  document.getElementById('container').appendChild(canvas);

  raytracer = new Raytracer(canvas);
  raytracer.setLookAt(0, 0, 1, 0, 0, 0);
  setTimeout(() => { raytracer.render(); }, 500);
}
window.onload = (event: Event): void => main();
