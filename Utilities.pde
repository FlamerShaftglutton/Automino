import java.util.regex.Pattern;
import java.util.Collections;

void translate(PVector p) { translate(p.x,p.y); }

String right(String in, int characters) { if (in.length() < characters) return in; return in.substring(in.length() - characters); } 

int parse_int(String s, int default_value)
{
    try {
        return Integer.parseInt(s);
    } catch (NumberFormatException e) {
        return default_value;
    }
}

float parse_float(String s, float default_value)
{
    try {
        return Float.parseFloat(s);
    } catch (NumberFormatException e) {
        return default_value;
    }
}

StringList getStringList(String field, JSONObject o)
{
  StringList retval = new StringList();
  
  Object of = o.get(field);
  
  if (of instanceof String)
    retval.append((String)of);
  else if (of instanceof JSONArray)
    retval = ((JSONArray)of).toStringList();
  
  /*
  {
    JSONArray a = (JSONArray)of;
    
    for (int i = 0; i < a.size(); ++i)
      retval.append(a.getString(i));
  }
  */
  
  return retval;
}

String[] split_respecting_quoted_whitespace(String s)
{
  StringList retval = new StringList();
  
  boolean insinglequotes = false;
  boolean indoublequotes = false;
  
  String current_string = "";
  
  for (int i = 0; i < s.length(); ++i)
  {
    char c = s.charAt(i);
    
    if (c == '\'' && insinglequotes)
      insinglequotes = false;
    else if (c == '"'  && indoublequotes)
      indoublequotes = false;
    else if (insinglequotes || indoublequotes)
      current_string += c;
    else if (c == '\'')
      insinglequotes = true;
    else if (c == '"')
      indoublequotes = true;
    else if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
    {
      if (current_string.length() > 0)
        retval.append(current_string);
      
      current_string = "";
    }
    else 
      current_string += c;
  }
  
  if (current_string.length() > 0)
    retval.append(current_string);
  
  return retval.values();
}
//{ return Pattern.compile("\\s+(?=(?:[^\"']*[\"'][^\"']*[\"'])*[^\"']*$)").split(s); }

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
  
  boolean equals(IntVec rhs) { return rhs.x == x && rhs.y == y; }
  
  String print() { return "{ x: " + x + ", y: " + y + " }"; }
}

IntVec[] orthogonal_offsets() { IntVec[] retval = { new IntVec(1,0), new IntVec(0,-1), new IntVec(-1,0), new IntVec(0,1) }; return retval; }
IntVec[] adjacent_offsets() { IntVec[] retval = { new IntVec(-1,-1), new IntVec(0,-1), new IntVec(1,-1), new IntVec(-1,0), new IntVec(1,0),new IntVec(-1,1), new IntVec(0,1), new IntVec(1,1) }; return retval; }

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

IntVec offset_from_angle(float angle)
{
  return offset_from_quarter_turns(int(0.01f + (TWO_PI - angle) / HALF_PI));
}

//returns a color with full brightness, about 3/5 saturation, and a random hue. This should turn out slightly muted/pastel instead of the harshness of a truly random color.
color random_color()
{
  colorMode(HSB);
  
  int random_hue = (int)random(255);
  
  color retval = color(random_hue, 150, 255);
  
  colorMode(RGB);
  
  return retval;
}

//returns a random color within a hue range of the supplied color. So if you supply purple and 0.05 as the range you'll still get purple, but slightly different. 0.5 would be a full swing of any hue. Uses the same saturation and brightness as the supplied color.
color random_color(color midpoint, float max_range)
{
  colorMode(HSB);
  
  int random_hue = (255 + (int)hue(midpoint) + (int)random(-max_range * 255f, max_range * 255f)) & 255;
  
  color retval = color(random_hue, saturation(midpoint), brightness(midpoint));
  
  colorMode(RGB);
  
  return retval;
}

float text_size_to_fit(String t, float w)
{
  textSize(100);
  
  float tw = textWidth(t);
  
  return 100 / (tw / w);
}

//using the current textSize, word-wrap a string so it doesn't overflow the width given. Note that it does not handle width-exceeding single words gracefully (it actually loses the bulk of the letters). So don't do that.
StringList wrap_string(String s, float w)
{
  StringList retval = new StringList();
  
  int start_index = 0;
  int end_index = 1;
  int previous_index;
  
  while (end_index > 0 && end_index < s.length() - 1)
  {
    previous_index = end_index;
    end_index = s.indexOf(' ', previous_index+1);
    
    if (end_index < 0)
      end_index = s.length() - 1;
    
    if (textWidth(s.substring(start_index, end_index)) > w)
    {
      retval.append(s.substring(start_index, previous_index));
      start_index = previous_index + 1;
      end_index = start_index;
    }
  }
  
  retval.append(s.substring(start_index));
  
  return retval;
}


//utility class that lets you store and manipulate 2d maps of bit/booleans
class BitGrid
{
  int[] values;
  int w;
  int h;
  
  BitGrid(int w, int h)
  {
    values = new int[1 + (w*h)/32];//integer division rounds down, so you gotta add one. You should do a check to see if it's exact, but I really don't care about one extra int
    this.w = w;
    this.h = h;
  }
  
  void set_bit  (int x, int y) { int superindex = x + y * w; int index = superindex / 32; int subindex = superindex - index * 32; int mask =   1 << subindex;  values[index] |= mask; }
  void unset_bit(int x, int y) { int superindex = x + y * w; int index = superindex / 32; int subindex = superindex - index * 32; int mask = ~(1 << subindex); values[index] &= mask; }
  void flip_bit (int x, int y) { int superindex = x + y * w; int index = superindex / 32; int subindex = superindex - index * 32; int mask =   1 << subindex;  values[index] ^= mask; }
  
  void put_bit(int x, int y, boolean value) { if (value) set_bit(x,y); else unset_bit(x,y); }
  
  boolean get_bit(int x, int y) { int superindex = x + y * w; int index = superindex / 32; int subindex = superindex - index * 32; return ((values[index] >>> subindex) & 1) == 1; }
}




//Barebones A* utility function for finding the shortest path on a grid between two points. Depends on IntVec and BitGrid.
ArrayList<IntVec> shortest_path(IntVec start, IntVec end, BitGrid obstacles)
{
  ArrayList<IntVec> stack = new ArrayList<IntVec>();
  
  int w = obstacles.w;
  int h = obstacles.h;
  
  IntVec[][] parent = new IntVec[w][h];
  int[][] distance_to_start = new int[w][h];
  int[][] distance_to_end = new int[w][h];
  
  for (int x = 0; x < w; ++x)
  {
    for (int y = 0; y < h; ++y)
    {
      parent[x][y] = null;
      distance_to_start[x][y] = Integer.MAX_VALUE;
      distance_to_end[x][y] = abs(x - end.x) + abs(y - end.y);//minkowski distance
    }
  }
  
  distance_to_start[start.x][start.y] = 0;
  stack.add(start);
  
  while (!stack.isEmpty())
  {
    //first up find the best candidate
    int best_index = -1;
    int best_dis = Integer.MAX_VALUE;
    
    for (int i = 0; i < stack.size(); ++i)
    {
      IntVec iv = stack.get(i);
      int total_estimated_distance = distance_to_start[iv.x][iv.y] + distance_to_end[iv.x][iv.y];
      if (total_estimated_distance < best_dis)
      {
        best_index = i;
        best_dis = total_estimated_distance;
      }
    }
    
    IntVec best_index_vec = stack.get(best_index);
    stack.remove(best_index);
    
    //check all four surrounding cells
    for (IntVec offset : new IntVec[]{ new IntVec(-1,0), new IntVec(0,-1), new IntVec(1,0), new IntVec(0,1) })
    {
      IntVec cpos = best_index_vec.copy().add(offset);
      
      if (cpos.x < 0 || cpos.y < 0 || cpos.x >= obstacles.w || cpos.y >= obstacles.h || obstacles.get_bit(cpos.x, cpos.y))
        continue;
      
      if (cpos.equals(end))
      {
        ArrayList<IntVec> retval = new ArrayList<IntVec>();
        
        retval.add(end);
        for (IntVec rpos = best_index_vec.copy(); rpos != null && !rpos.equals(start); rpos = parent[rpos.x][rpos.y])
          retval.add(rpos);
        retval.add(start);
        Collections.reverse(retval);

        return retval;
      }
      
      int dts = distance_to_start[best_index_vec.x][best_index_vec.y] + 1;
      
      boolean was_null = parent[cpos.x][cpos.y] == null && !cpos.equals(start);
      
      if (was_null || distance_to_start[cpos.x][cpos.y] > dts)
      {
        parent[cpos.x][cpos.y] = best_index_vec.copy();
        distance_to_start[cpos.x][cpos.y] = dts;
        
        if (!was_null)
        {
          for (int i = stack.size() - 1; i >= 0; --i)
          {
            if (stack.get(i).equals(cpos))
              stack.remove(i);
          }
        }
        
        stack.add(cpos);
      }
    }
  }
  
  return new ArrayList<IntVec>();
}
