import { assertEquals } from "@std/assert";

export function add(a: number, b: number): number {
  return a + b;
}

assertEquals(add(1, 2), 3);
console.log(`1 + 2 = ${add(1, 2)}`);
