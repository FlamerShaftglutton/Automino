

class ResourcePool extends Griddle
{
  String ng_type;
  
  boolean can_accept_ng(NonGriddle n) { return ng_type.equals(n.name); }
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; game.destroy_ng(ng); return true; }
  
  ResourcePool(GridGameFlowBase game) { super(game); type = "ResourcePool"; }
  
  void update()
  {
    if (ngs.isEmpty())
      produce_resource(game);
       //ngs.add(game.create_and_register_ng(ng_type));
    
    super.update();
  }
  
  void produce_resource(GridGameFlowBase game) { ngs.add(game.create_and_register_ng(ng_type)); }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("ng_type", ng_type); return o;  }
  void deserialize(JSONObject o) { super.deserialize(o); ng_type = o.getString("ng_type", ""); }
}

class RandomResourcePool extends ResourcePool
{
  StringList resources = new StringList();
  StringList remaining_resources = new StringList();
  
  RandomResourcePool(GridGameFlowBase game) { super(game); type = "RandomResourcePool"; }
  
  void update()
  {
    if (remaining_resources.size() == 0)
    {
      remaining_resources = resources.copy();
      remaining_resources.shuffle();
    }
    
    if (ngs.isEmpty())
      ng_type = remaining_resources.pop();
    
    super.update();
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); JSONArray a = new JSONArray(); for (String s : resources) a.append(s); o.setJSONArray("resources",a); return o;  }
  void deserialize(JSONObject o)
  {
    super.deserialize(o);
    
    Object resource_o = o.get("resources");
    
    if (resource_o instanceof JSONArray)
    {
      JSONArray a = o.getJSONArray("resources");
      
      for (int i = 0; i < a.size(); ++i)
        resources.append(a.getString(i));
    }
    else if (resource_o instanceof JSONObject)
    {
      JSONObject oo = (JSONObject)resource_o;
      
      for (Object ko : oo.keys())
      {
        String k = (String)ko;
        int times = oo.getInt(k);
        
        for (int i = 0; i < times; ++i)
          resources.append(k);
      }
    }
  }
}

class CountingOutputResourcePool extends ResourcePool
{
  int count = 0;
  int required = -1;
  PShape ng_sprite;
  
  CountingOutputResourcePool(GridGameFlowBase game) { super(game); type = "CountingOutputResourcePool"; }
  
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; game.destroy_ng(ng); ++count; return true; }
  
  void produce_resource(GridGameFlowBase game) { if (count > 0) { super.produce_resource(game); --count; } }
  
  int get_count() { return count + ngs.size(); }
  
  //void update() { this.game = game;  }
  void draw()
  {
    super.draw();
    
    pushMatrix();
    
    translate(pos);
    
    PVector text_spot   = new PVector(dim.x * 0.5f, dim.y * 0.2f);
    PVector sprite_dim  = dim.copy().mult(0.4f);
    PVector sprite_spot = new PVector(dim.x * 0.5f, dim.y * 0.6f).sub(sprite_dim.copy().mult(0.5f));
    
    textAlign(CENTER,CENTER);
    String s = "" + get_count();
    
    if (required > 0)
      s += " / " + required;
    
    textSize(24);
    fill(#000000);
    text(s, text_spot.x, text_spot.y);
    
    if (ng_sprite != null && get_count() == 0)
      shape(ng_sprite, sprite_spot.x, sprite_spot.y, sprite_dim.x, sprite_dim.y);
    
    popMatrix();
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("ng_type", ng_type); o.setInt("required", required); o.setInt("count", get_count()); return o;  }
  
  void deserialize(JSONObject o)
  {
    super.deserialize(o); 
    count = o.getInt("count", 0); 
    required = o.getInt("required", -1);   
    
    if (!ng_type.equals("")) 
      ng_sprite = globals.ngFactory.create_ng(ng_type).shape; 
  }
}

class MetaActionCounter extends Griddle
{
  String display_string = "";
  String action = "";
  StringList parameters = new StringList();
  
  MetaActionCounter(GridGameFlowBase game) { super(game); type = "MetaActionCounter"; }
  
  boolean can_accept_ng() { return false; }
  
  void draw()
  {
    super.draw();
    
    if (!display_string.equals(""))
    {
      fill(#000000);
      stroke(#000000);
      textSize(14f);
      textAlign(CENTER,CENTER);
      text(display_string, pos.x + dim.x * 0.5f, pos.y + dim.y * 0.5f);
    }
  }
  
  void player_interact_end(Player player)
  {
    String message = parameters.size() == 0 ? "" : parameters.get(0);
    globals.messages.post_message(action, message);
  }
  
  void deserialize(JSONObject o) 
  { 
    super.deserialize(o); 
    display_string = o.getString("display","");
    action = o.getString("action", "null");

    JSONArray a = o.getJSONArray("parameters");
    
    if (a != null)
    {
      for (int i = 0; i < a.size(); ++i)
        parameters.append(a.getString(i));
    }
  }
  
  JSONObject serialize() 
  {
    JSONObject o = super.serialize();
    o.setString("display", display_string);
    o.setString("action", action);
    
    JSONArray a = new JSONArray();
    for (String p : parameters)
      a.append(p);
    
    o.setJSONArray("parameters", a);
    
    return o;
  }
}

class LevelEditorGriddle extends EmptyGriddle
{
  boolean locked = false;
  
  
  LevelEditorGriddle(GridGameFlowBase game) { super(game); type = "LevelEditorGriddle"; }
  
  void update() { traversable = ngs.isEmpty(); }
  
  void player_interact_end(Player player)
  {
    if (!locked)
      ++quarter_turns;
  }
  
  boolean receive_ng(NonGriddle ng)
  {
    if (ng.name.equals("Gold Ingot") && !ngs.isEmpty())
    {
      globals.messages.post_message(new Message("upgrade", ng().name, this));
      return false;
    }
    
    if (!super.receive_ng(ng) || !(ng instanceof LevelEditorNonGriddle))
      return false;
      
    
    LevelEditorNonGriddle leng = (LevelEditorNonGriddle)ng;
    
    sprite = leng.shape;
    spritename = leng.as_json.getString("sprite");
    
    if (sprite == null && !spritename.isEmpty())
      sprite = globals.sprites.get_sprite(spritename);
    
    return true;
  }
  
  boolean can_accept_ng(NonGriddle n) { return n.name.equals("Gold Ingot") || (!locked && n instanceof LevelEditorNonGriddle && super.can_accept_ng(n)); }
  boolean can_give_ng() { return !locked; }
  
  void draw() 
  {
    noFill();
    stroke(0,0,0);
    strokeWeight(1);
    rect(pos.x, pos.y, dim.x, dim.y);
    
    if (ngs.isEmpty())
    {
      sprite = null;
      spritename = "";
    }
    
    super.draw(sprite);
  }
  
  JSONObject serialize()
  { 
    if (ngs.isEmpty())
      return (new EmptyGriddle(game)).serialize();
    
    JSONObject o = ((LevelEditorNonGriddle)ngs.get(0)).as_json;
    o.setInt("quarter_turns", quarter_turns);
    
    return  o;
  }
}

class RewardGriddle extends Griddle
{
  String reward_griddle_name = "";
  float time_used = 0f;
  float time_needed = 10f;
  boolean finished = false;
  boolean running = false;
  
  RewardGriddle(GridGameFlowBase game) { super(game); type = "RewardGriddle"; }
  
  void update()
  {
    if (sprite == null && !reward_griddle_name.isEmpty()) 
    {
      Griddle g = globals.gFactory.create_griddle(reward_griddle_name, game);
      
      if (g != null)
        sprite = g.sprite;
    }
    
    if (running)
    {
      time_used += 1f / 60f;
      
      if (time_used >= time_needed)
      {
        running = false;
        finished = true;
      }
    }
  }
  
  void draw()
  {
    super.draw();
    
    fill(color(0,0,0,80));
    noStroke();
    rect(pos.x, pos.y, dim.x, dim.y);
    
    if (finished)
    {
      fill(color(0, 0, 0, 200));
      noStroke();
      rect(pos.x, pos.y, dim.x, dim.y);
    }
    else if (running)
    {
      fill(color(0,0,0,80));
      noStroke();
      rect(pos.x, pos.y, dim.x, dim.y * time_used / time_needed );
    }
  }
}
