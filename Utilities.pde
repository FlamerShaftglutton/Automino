IntVec offset_from_quarter_turns(int quarter_turns)
{
  quarter_turns &= 3;
  IntVec retval = new IntVec(0,0);
  
  switch (quarter_turns)
  {
    case 1: retval.y = -1; break;
    case 0:  retval.x =  1; break;
    case 3: retval.y =  1; break;
    case 2:  retval.x = -1; break;
  }
  
  return retval;
}

void translate(PVector p) { translate(p.x,p.y); }

String right(String in, int characters) { if (in.length() < characters) return in; return in.substring(in.length() - characters); } 

class IntVec
{
  int x;
  int y;
  
  IntVec(int x, int y) { this.x = x; this.y = y; }
  IntVec(PVector rhs) { x = (int)rhs.x; y = (int)rhs.y; }
  
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

IntVec[] orthogonal_offsets() { IntVec[] retval = { new IntVec(1,0), new IntVec(0,-1), new IntVec(-1,0), new IntVec(0,1) }; return retval; }
IntVec[] adjacent_offsets() { IntVec[] retval = { new IntVec(-1,-1), new IntVec(0,-1), new IntVec(1,-1), new IntVec(-1,0), new IntVec(1,0),new IntVec(-1,1), new IntVec(0,1), new IntVec(1,1) }; return retval; }
