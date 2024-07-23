

class ResourcePool extends Griddle
{
  String ng_type;
  
  boolean can_accept_ng(NonGriddle n) { return ng_type.equals(n.name); }
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; game.destroy_ng(ng); return true; }
  
  ResourcePool(GridGameFlowBase game) { super(game); type = "ResourcePool"; }
  
  void update()
  {
    if (ngs.isEmpty())
      produce_resource();
    
    super.update();
  }
  
  NonGriddle produce_resource() { NonGriddle retval = game.create_and_register_ng(ng_type); ngs.add(retval); return retval; }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("ng_type", ng_type); return o;  }
  void deserialize(JSONObject o) { super.deserialize(o); ng_type = o.getString("ng_type", ""); }
}

class RandomResourcePool extends ResourcePool
{
  StringList resources = new StringList();
  StringList remaining_resources = new StringList();
  StringList extra_resources = new StringList();
  
  RandomResourcePool(GridGameFlowBase game) { super(game); type = "RandomResourcePool"; }
  
  void update()
  {
    if (remaining_resources.size() == 0)
    {
      remaining_resources = resources.copy();
      remaining_resources.append(extra_resources);
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
    
    if (game instanceof GameSession) 
    {
      GameSession gs = (GameSession)game;
      extra_resources = gs.rules.get_strings("Resource:Random");
    }
  }
}

class CountingResourcePool extends ResourcePool
{
  int count = 0;
  PShape ng_sprite;
  
  CountingResourcePool(GridGameFlowBase game) { super(game); type = "CountingResourcePool"; ng_type = ""; }
  
  boolean can_accept_ng(NonGriddle ng) { return get_count() == 0 || ng_type.length() == 0 || super.can_accept_ng(ng); }
  
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; if (!ng_type.equals(ng.name)) { ng_type = ng.name; ng_sprite = ng.shape; } game.destroy_ng(ng); ++count; return true; }
  
  NonGriddle produce_resource() { NonGriddle retval = null; if (count > 0) { retval = super.produce_resource(); --count; } return retval; }
  
  int get_count() { return count + ngs.size(); }
  
  boolean set_count(int new_amount) { if (new_amount < 0) return false; count = new_amount; ngs.clear(); return true; }
  
  String get_display_string() { return "" + get_count(); }
  
  void draw()
  {
    super.draw();
    
    pushMatrix();
    
    translate(pos);
    
    PVector text_spot   = new PVector(dim.x * 0.5f, dim.y * 0.2f);
    PVector sprite_dim  = dim.copy().mult(0.25f);
    PVector sprite_spot = new PVector(dim.x * 0.2f, dim.y * 0.7f).sub(sprite_dim.copy().mult(0.5f));
    
    textAlign(CENTER,CENTER);
    
    textSize(18);
    fill(#000000);
    text(get_display_string(), text_spot.x, text_spot.y);
    
    if (ng_sprite != null && (get_count() == 0 || ngs.isEmpty()))
      shape(ng_sprite, sprite_spot.x, sprite_spot.y, sprite_dim.x, sprite_dim.y);
    
    popMatrix();
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("ng_type", ng_type); o.setInt("count", get_count()); return o;  }
  
  void deserialize(JSONObject o)
  {
    super.deserialize(o); 
    count = o.getInt("count", 0); 
    
    if (!ng_type.equals("")) 
      ng_sprite = globals.ngFactory.create_ng(ng_type).shape; 
  }
}

class ConveyorCountingResourcePool extends CountingResourcePool
{
  ConveyorComponent comp;
  
  ConveyorCountingResourcePool(GridGameFlowBase game) { super(game); type = "ConveyorCountingResourcePool"; comp = new ConveyorComponent(game, this); }
  
  void deserialize(JSONObject o) { super.deserialize(o); comp.deserialize(o.getJSONObject("component"));  }
  JSONObject serialize() { JSONObject retval = super.serialize(); retval.setJSONObject("component", comp.serialize()); return retval; }
  
  void update()
  {
    super.update();
    
    if (get_count() > 0 && comp.ng == null)
    {
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns+3);
      IntVec xy = get_grid_pos().add(iv_offset);
      Griddle gg = game.grid.get(xy.x, xy.y);
      
      PVector start = center_center();
      PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
      
      NonGriddle ng = ng();
      
      if (count > 0)
        ng = produce_resource();
      
      comp.start_conveying(gg, start, end, ng);
    }
    
    comp.update();
  }
  
  void remove_ng(NonGriddle ng) 
  {
    super.remove_ng(ng); 
  
    if (ng == comp.ng)
      comp.ng = null;
  }
  
}

class CountingOutputResourcePool extends CountingResourcePool
{
  int required = 1;
  
  CountingOutputResourcePool(GridGameFlowBase game) { super(game); type = "CountingOutputResourcePool"; }
  
  String get_display_string() { if (required < 0) return super.get_display_string(); return "" + get_count() + " / " + required; }
  
  boolean can_accept_ng(NonGriddle n) { return ng_type.equals(n.name); }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setInt("required", required); return o;  }
  void deserialize(JSONObject o){ super.deserialize(o); required = o.getInt("required", -1); }
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
      textAlign(CENTER,TOP);
      text(display_string, pos.x, pos.y + dim.y * 0.5f, dim.x, dim.y);
    }
  }
  
  void player_interact_end(Player player)
  {
    String message = parameters.size() == 0 ? "" : parameters.join(";");
    globals.messages.post_message(action, message, this);
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
  color background_color = color(255,255,255,0);
  Griddle subgriddle = null;
  
  LevelEditorGriddle(GridGameFlowBase game) { super(game); type = "LevelEditorGriddle"; }
  
  void update()
  {
    if (subgriddle == null) 
    { 
      if (!ngs.isEmpty())
      {
        LevelEditorNonGriddle leng = (LevelEditorNonGriddle)ng();
        subgriddle = globals.gFactory.create_griddle(leng.as_json,game);
        subgriddle.pos = pos.copy();
        subgriddle.dim = dim.copy();
        subgriddle.quarter_turns = quarter_turns;
      }
    }
    else
    {
      if (ngs.isEmpty())
        subgriddle = null;
      else
      {
        subgriddle.pos = pos.copy();
        subgriddle.dim = dim.copy();
        subgriddle.quarter_turns = quarter_turns;
      }
    }
  }
  
  void player_interact_end(Player player)
  {
    if (!locked)
      ++quarter_turns;
  }
  
  boolean receive_ng(NonGriddle ng)
  {
    if (ng.name.equals("Gold Ingot"))
    {
      if (!ngs.isEmpty())
        globals.messages.post_message(new Message("upgrade", ng().name, this));
      
      return false;
    }
    
    if (!super.receive_ng(ng) || !(ng instanceof LevelEditorNonGriddle))
      return false;
      
    LevelEditorNonGriddle leng = (LevelEditorNonGriddle)ng;
    
    subgriddle = globals.gFactory.create_griddle(leng.as_json,game);
    subgriddle.pos = pos.copy();
    subgriddle.dim = dim.copy();
    subgriddle.quarter_turns = quarter_turns;
    
    return true;
  }
  
  void    remove_ng(NonGriddle ng) { super.remove_ng(ng); subgriddle = null; }
  void    remove_ng() { super.remove_ng(); subgriddle = null; }
  
  boolean can_accept_ng(NonGriddle n) { return n.name.equals("Gold Ingot") || (!locked && n instanceof LevelEditorNonGriddle && ngs.isEmpty() && super.can_accept_ng(n)); }
  boolean can_give_ng() { return !locked; }
  
  void draw() 
  {
    fill(background_color);
    stroke(0,0,0);
    strokeWeight(1);
    rect(pos.x, pos.y, dim.x, dim.y);
    
    if (subgriddle == null)
      super.draw();
    else
      subgriddle.draw();
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
  
  void deserialize(JSONObject o) 
  { 
    super.deserialize(o); 
    reward_griddle_name = o.getString("reward_griddle_name","");
    finished = o.getBoolean("finished", false);
  }
  
  JSONObject serialize() 
  {
    JSONObject o = super.serialize();
    o.setString("reward_griddle_name", reward_griddle_name);
    o.setBoolean("finished", finished);
 
    return o;
  }
}
