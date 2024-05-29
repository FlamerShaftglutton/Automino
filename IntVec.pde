class IntVec
{
  int x;
  int y;
  
  IntVec(int x, int y) { this.x = x; this.y = y; }
  
  IntVec clone() { return new IntVec(x,y); }
  IntVec copy() { return clone(); }
  
  IntVec add(int x, int y) { this.x += x; this.y += y; return this; }
  IntVec add(IntVec rhs) { return add(rhs.x, rhs.y); }
  IntVec add(int b) { return add(b,b); }
  
  IntVec sub(int x, int y) { this.x -= x; this.y -= y; return this; }
  IntVec sub(IntVec rhs) { return sub(rhs.x, rhs.y); }
  IntVec sub(int b) { return sub(b,b); }
  
  IntVec mult(int x, int y) { this.x *= x; this.y *= y; return this; }
  IntVec mult(IntVec rhs) { return mult(rhs.x, rhs.y); }  
  IntVec mult(int b) { return mult(b,b); }
  
  IntVec div(int x, int y) { this.x /= x; this.y /= y; return this; }
  IntVec div(IntVec rhs) { return div(rhs.x, rhs.y); }
  IntVec div(int b) { return div(b,b); }
  
  PVector toPVec() { return new PVector(x,y); }
  
  String print() { return "{ x: " + x + ", y: " + y + " }"; }
}
