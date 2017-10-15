export default class Vector {
  constructor(public x: number,
              public y: number,
              public z: number) {}

  static add(v1: Vector, v2: Vector): Vector {
    return new Vector(v1.x + v2.x,
                      v1.y + v2.y,
                      v1.z + v2.z);
  }

  static cross(v1: Vector, v2: Vector): Vector {
    return new Vector(v1.y * v2.z - v1.z * v2.y,
                      v1.z * v2.x - v1.x * v2.z,
                      v1.x * v2.y - v1.y * v2.x);
  }

  static mag(v: Vector): number {
    return ((v.x ** 2) + (v.y ** 2) + (v.z ** 2)) ** .5;
  }

  static normalize(v: Vector): Vector {
    let mag: number;

    mag = Vector.mag(v);
    if (mag === 0) {
      throw new Error('cannot normalize the zero vector');
    }
    return Vector.scale((1 / mag), v);
  }

  static scale(k: number, v: Vector): Vector {
    return new Vector(k * v.x, k * v.y, k * v.z);
  }

  static subtract(v1: Vector, v2: Vector): Vector {
    return new Vector(v1.x - v2.x,
                      v1.y - v2.y,
                      v1.z - v2.z);
  }

  public getElements(): number[] {
    return [this.x, this.y, this.z];
  }
}