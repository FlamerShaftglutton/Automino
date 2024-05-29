class Grid
{
  int w;
  int h;
  float edge_width;
  
  PVector pos;
  PVector original_pos;
  PVector dim;
  
  ArrayList<Griddle> griddles;
  ArrayList<GridAlteration> alterations;
  
  Grid(PVector pos, PVector dim) { this(pos, dim, 0, 0); }
  
  Grid(PVector pos, PVector dim, int w, int h)
  {
    this.pos = pos.copy();
    original_pos = pos.copy();
    this.dim = dim.copy();
    
    init(w, h);
  }
  
  void init(int w, int h)
  {
    this.w = w;
    this.h = h;
    
    edge_width = Math.min(dim.x / w, dim.y / h);
    pos = original_pos.copy().add(dim.copy().sub((new PVector(w,h)).mult(edge_width)).mult(0.5f));
    
    griddles = new ArrayList<Griddle>(); 
    alterations = new ArrayList<GridAlteration>();
    
    for (int i = 0; i < w * h; ++i)
    {
      EmptyGriddle eg = new EmptyGriddle();
      eg.pos = (new PVector(i % w, i / w)).mult(edge_width).add(pos); 
      eg.dim = new PVector(edge_width, edge_width); 
      griddles.add(eg);
    }
  }
  
  void deserialize(JSONObject loaded_json)
  {
    w = loaded_json.getInt("width");
    h = loaded_json.getInt("height");
    
    init(w,h);
    
    JSONArray root = loaded_json.getJSONArray("grid");
    
    for (int i = 0; i < root.size(); ++i)
    {
      JSONObject o = root.getJSONObject(i);
      int x = o.getInt("x",-1);
      int y = o.getInt("y",-1);
      String type = o.getString("type","NullGriddle");
      
      Griddle g = globals.gFactory.create_griddle(type, o);
      
      set(x,y,g);
    }
    
    update();
  }
  
  JSONObject serialize()
  {
      JSONObject root = new JSONObject();
      root.setInt("width", w);
      root.setInt("height", h);
      
      JSONArray retval = new JSONArray(); 
      for (Griddle g : griddles)
      {
        JSONObject o = g.serialize();
        IntVec p = get_grid_pos_from_object(g);
        o.setInt("x", p.x);
        o.setInt("y", p.y);
        retval.append(o); 
      }
      root.setJSONArray("grid", retval);
      
      return root;
  }
  
  Griddle get(int x, int y) { if (x < 0 || x >= w || y < 0 || y >= h) return new NullGriddle(); return griddles.get(x + y * w); }
  
  Griddle get(PVector point)
  {
    int x, y;
    
    PVector cut = point.copy().sub(pos).div(edge_width);
    
    x = (int)cut.x;
    y = (int)cut.y;
    
    if (x >= w || x < 0 || y >= h || y < 0)
      return new NullGriddle();
    
    return get(x,y);
  }
  
  Griddle get(IntVec xy) { return get(xy.x, xy.y); }
  
  void set(int x, int y, Griddle newval) { set(new IntVec(x,y), newval); }
  
  void set(IntVec xy, Griddle newval) { alterations.add(new GridAlteration(xy, newval)); }
  
  void draw()
  {
    
    noFill();
    stroke(#000000);
    strokeWeight(1);
    
    rect(pos.x, pos.y, w * edge_width, h * edge_width);

    for (Griddle g : griddles)
      g.draw();
  }
  
  void update()
  {
    for (int i = 0; i < griddles.size(); ++i)
      griddles.get(i).update();
    
    apply_alterations();
  }
  
  void apply_alterations()
  {
    for (GridAlteration ga : alterations)
    {
      if (ga.xy.x < 0 || ga.xy.y < 0 || ga.xy.x >= w || ga.xy.y >= h)
        println("Unable to set object in spot " + ga.xy.print());
      else
      {
        ga.newval.pos = (new PVector(ga.xy.x,ga.xy.y)).mult(edge_width).add(pos); 
        ga.newval.dim = new PVector(edge_width, edge_width); 
        griddles.set(ga.xy.x + ga.xy.y * w, ga.newval);
      }
    }
    alterations.clear();
  }
  
  
  IntVec get_grid_pos_from_object(Griddle g) { int i = griddles.indexOf(g); if (i < 0) { println("That object doesn't exist!"); return null; } return new IntVec(i % w, i / w); }
}

class GridAlteration
{
  IntVec xy;
  Griddle newval;
  
  GridAlteration() { xy = new IntVec(0,0); newval = new NullGriddle(); }
  GridAlteration(IntVec xy, Griddle newval) { this.xy = xy.copy(); this.newval = newval; }
}
