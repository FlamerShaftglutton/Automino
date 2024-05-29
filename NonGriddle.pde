
class NonGriddle
{
  PVector pos;
  PVector dim;
  
  String name;
  PShape shape;
  
  NonGriddle() { pos = new PVector(); dim = new PVector(); name = ""; shape = createShape(RECT,0,0,1,1); }
  
  void copy_from(NonGriddle ng)
  {
    if (ng.pos != null)
      pos = ng.pos.copy();
    
    if (ng.dim != null)
      dim = ng.dim.copy();
    
    name = ng.name;
    
    shape = ng.shape;
  }
  
  NonGriddle clone() { NonGriddle r = new NonGriddle(); r.copy_from(this); return r; }
  
  NonGriddle copy() { return clone(); }
  
  void draw() 
  {
    pushMatrix();
    
    translate(pos.x - dim.x * 0.5f, pos.y - dim.y * 0.5f);
    
    shape(shape, 0, 0, dim.x, dim.y);
    
    popMatrix();
  }
  
  
  
  void update() 
  {
    
  }
}

class LevelEditorNonGriddle extends NonGriddle
{
  JSONObject as_json;
  boolean visible = false;
  
  LevelEditorNonGriddle clone() 
  { 
    LevelEditorNonGriddle retval = new LevelEditorNonGriddle(); 
    retval.copy_from(this);
    
    if (as_json == null)
      println("LevelEditorNonGriddle.as_json is null right before cloning. Whoopsies.");
    
    retval.as_json = JSONObject.parse(as_json.toString()); 
    
    return retval; 
  } 
  
  void draw()
  {
    if (visible)
      super.draw();
  }
}

class NonGriddleFactory
{
  HashMap<String, NonGriddle> templates;
  
  
  void load(String json_file)
  {
    templates = new HashMap<String, NonGriddle>();

    JSONArray root = loadJSONArray(json_file);
    
    for (int i = 0; i < root.size(); ++i)
    {
      JSONObject o = root.getJSONObject(i);
      
      if (!o.hasKey("name"))
        println("NonGriddle loaded without name field; defaulting to 'null'. Please check json integrity.");
      
      String name = o.getString("name", "null");
      
      if (!o.hasKey("sprite"))
        println("NonGriddle loaded without sprite field; defaulting to null sprite. Please check json integrity.");
      
      String spritename = o.getString("sprite", "line");
      
      add_ng_template(name, spritename);
    }
    
  }
  
  void add_ng_template(String name, String spritename)
  {
    NonGriddle ng = new NonGriddle();
    ng.pos = new PVector();
    PVector dim = new PVector(40f, 40f); 
    ng.dim = dim;
    ng.name = name;
  
    PShape shape;
    if (!globals.sprites.has_sprite(spritename))
    {
      shape = globals.sprites.get_sprite("null");
      println("NonGriddle '" + name + "' tried to load sprite '" + spritename + "' which doesn't exist. Defaulting to null sprite.");
    }
    else
      shape = globals.sprites.get_sprite(spritename);
    
    ng.shape = shape;
    
    templates.put(name, ng);
  }
  
  NonGriddle create_ng(String name)
  {
    NonGriddle retval = templates.get(name);
    
    if (retval == null)
    {
      println("Tried to create unknown nongriddle named '" + name + "'. Returning default value");
      retval = new NonGriddle();
    }
    
    retval = retval.clone();
    
    return retval;
  }
  
  LevelEditorNonGriddle create_le_ng(String name)
  {
    return create_le_ng(globals.gFactory.create_griddle(name).serialize());
  }
  
  LevelEditorNonGriddle create_le_ng(JSONObject o)
  { 
    LevelEditorNonGriddle retval = new LevelEditorNonGriddle(); 
    retval.dim = new PVector(40,40); 
    retval.as_json = o; 
    retval.name = o.getString("type"); 
    retval.shape = globals.sprites.get_sprite(o.getString("sprite"));
    return retval; 
  }
}
