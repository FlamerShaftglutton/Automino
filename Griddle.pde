
class Griddle
{
  PVector pos;
  PVector dim;
  int     quarter_turns;
  boolean traversable = false;
  
  ArrayList<NonGriddle> ngs;
  
  String spritename;
  PShape sprite;
  
  String type = "Griddle";
  
  Griddle(PVector pos, PVector dim) { this.pos = pos.copy(); this.dim = dim.copy(); quarter_turns = 0; ngs = new ArrayList<NonGriddle>(); }
  Griddle() { this(new PVector(), new PVector()); }
  
  void draw()
  {
    draw(sprite);
  }
  
  void draw(PShape s)
  {
    if (s != null)
    {
      pushMatrix();
      
      translate(center_center());
      
      rotate(-quarter_turns * HALF_PI);
      
      translate(dim.copy().mult(-0.5f));
      
      shape(s,0,0,dim.x, dim.y);
      
      popMatrix();
    }
  }
  
  void update(GridGameFlowBase game)
  {
    center_ngs();
  }
  
  JSONObject serialize()
  {
    JSONObject o = new JSONObject();
    o.setString("type", type);
    o.setString("sprite", spritename);
    o.setBoolean("traversable", traversable);
    o.setInt("quarter_turns", quarter_turns);
    
    return o;
  }
  
  void deserialize(JSONObject o) { spritename = o.getString("sprite","null"); sprite = globals.sprites.get_sprite(spritename); quarter_turns = o.getInt("quarter_turns", 0); }
  
  NonGriddle ng() { if (ngs.isEmpty()) return null; return ngs.get(ngs.size()-1); }
  boolean can_accept_ng(NonGriddle n) { return ngs.size() <= 1; }
  boolean can_give_ng() { return true; }
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; ngs.add(ng); return true; }
  void    remove_ng(NonGriddle ng) { ngs.remove(ng); }
  void    remove_ng() { if (!ngs.isEmpty()) ngs.remove(ngs.size() - 1); }
  void    center_ngs() 
  {
    if (ngs.size() == 1)
      ngs.get(0).pos = center_center();
    
    if (ngs.size() <= 1)
      return;
    
    float xtw = dim.x * 0.4f;
    float xstep = xtw  / ngs.size();
    float xstart = xtw * -0.5f;
    
    for (int i = 0 ; i < ngs.size(); ++i)
      ngs.get(i).pos = center_center().add(xstart + xstep * i,0f); 
  }
  
  
  void    player_interact(Player player) { }
  void    player_interact_end(Player player) { }
  
  
  PVector top_left() { return pos.copy(); }
  PVector top_center() { return pos.copy().add(dim.x * 0.5f, 0f); }
  PVector top_right() { return pos.copy().add(dim.x, 0f); }
  PVector center_left() { return pos.copy().add(0f, dim.y * 0.5f); }
  PVector center_center() { return pos.copy().add(dim.copy().mult(0.5f)); }
  PVector center_right() { return pos.copy().add(dim.x, dim.y * 0.5f); }
  PVector bottom_left() { return pos.copy().add(0f, dim.y); }
  PVector bottom_center() { return pos.copy().add(dim.x * 0.5f, dim.y); }
  PVector bottom_right() { return pos.copy().add(dim); }
}

class NullGriddle extends Griddle
{
  NullGriddle() { type = "NullGriddle"; }
  
  boolean can_accept_ng(NonGriddle n) { return false; }
  
  void draw() {  }
  void update(GridGameFlowBase game) {  }
}

class EmptyGriddle extends Griddle
{
  EmptyGriddle() { super(new PVector(), new PVector()); traversable = true; type = "EmptyGriddle"; }
  
  boolean can_accept_ng(NonGriddle n) { return ngs.isEmpty(); }
  
  void draw() 
  {     
    noFill();
    stroke(#000000);
    strokeWeight(1f);
    
    rect(pos.x, pos.y, dim.x, dim.y); 
  }
  
  void update(GridGameFlowBase game) { if (ng() != null) ng().pos = center_center(); }
}

class PlayerGriddle extends Griddle
{
  PlayerGriddle() { type = "PlayerGriddle"; }
}



class GriddleFactory
{
  HashMap<String, JSONObject> templates;
  
  void load(String json_file)
  {
    templates = new HashMap<String, JSONObject>();
    
    JSONArray root = loadJSONArray(json_file);
    
    for (int i = 0; i < root.size(); ++i)
    {
      JSONObject o = root.getJSONObject(i);
      
      String template_name = "";
      
      if (o.hasKey("_template"))
        template_name = o.getString("_template");
      else if (o.hasKey("type"))
        template_name = o.getString("type");
      
      if (template_name.equals(""))
      {
        println("Griddle template found with no _template or type specified. Loading of this griddle has been skipped.");
        continue;
      }
      
      templates.put(template_name, o);
    }
  }
  Griddle create_griddle(String name) { return create_griddle(name, new JSONObject()); }
  Griddle create_griddle(String name, JSONObject overwrite) 
  { 
    if (templates.containsKey(name)) 
      return create_griddle(templates.get(name),overwrite); 
    
    return create_griddle(overwrite);
  }
  
  Griddle create_griddle(JSONObject base, JSONObject over)
  {
    return create_griddle(merge_JSONObjects(base, over));
  }
  
  Griddle create_griddle(JSONObject template)
  { 
    Griddle g;
    String type = template.getString("type","NullGriddle");
    switch (type)
    {
      case "Player": case "PlayerGriddle": g = new PlayerGriddle();              break;
      case "ConveyorBelt":                 g = new ConveyorBelt();               break;
      case "ResourcePool":                 g = new ResourcePool();               break;
      case "NullGriddle":                  g = new NullGriddle();                break;
      case "EmptyGriddle":                 g = new EmptyGriddle();               break;
      case "Griddle":                      g = new Griddle();                    break;
      case "Transformer":                  g = new Transformer();                break;
      case "GrabberBelt":                  g = new GrabberBelt();                break;
      case "SmartGrabberBelt":             g = new SmartGrabberBelt();           break;
      case "SwitchGrabberBelt":            g = new SwitchGrabberBelt();          break;
      case "MetaActionCounter":            g = new MetaActionCounter();          break;
      case "LevelEditorGriddle":           g = new LevelEditorGriddle();         break;
      case "CountingOutputResourcePool":   g = new CountingOutputResourcePool(); break;
      case "RandomResourcePool":           g = new RandomResourcePool();         break;
      case "TrashCompactor":               g = new TrashCompactor();             break;
      default:                             g = new NullGriddle();                break;
    }
    
    g.deserialize(template);
    
    return g;
  }
}

JSONObject merge_JSONObjects(JSONObject base, JSONObject over)
{
  //clone our base
  JSONObject template = JSONObject.parse(base.toString());
  
  //for each field in the overwriter replace the field in the template
  for (Object field : over.keys())
    template.put(field.toString(), over.get(field.toString()));
    
  //replace the type to make sure it's the fully derived type, not the template name
  template.setString("type", base.getString("type"));
  
  return template;
}
