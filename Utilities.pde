import java.util.regex.Pattern;

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
  {
    JSONArray a = (JSONArray)of;
    
    for (int i = 0; i < a.size(); ++i)
      retval.append(a.getString(i));
  }
  
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
