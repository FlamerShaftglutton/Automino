class FloatAttribute
{
  float base;
  StringList monitored_variables;
  Griddle parent;

  FloatAttribute(float base, StringList monitored_variables, Griddle parent) { this.base = base; this.monitored_variables = monitored_variables; this.parent = parent; }
  FloatAttribute(float base, String monitored_variable, Griddle parent) { this(base, new StringList(monitored_variable), parent); }
  
  float get()
  {
    float modified = base;
    
    if (parent.game instanceof GameSession) 
    {
      GameSession gs = (GameSession)parent.game;
      
      for (String mv : monitored_variables)
        modified = gs.rules.get_float(mv, modified);
    }
    
    IntVec pos = parent.get_grid_pos();
    for (IntVec offset : adjacent_offsets())
    {
      IntVec opos = pos.copy().add(offset);
      
      Griddle neighbor_griddle = parent.game.grid.get(opos); 
      if (neighbor_griddle instanceof StatusBroadcaster)
      {
        StatusBroadcaster sb = (StatusBroadcaster)neighbor_griddle;
        
        for (String mv : monitored_variables)
        {
          if (sb.statuses.hasValue(mv))
          {
            //modified += sb.current_addend;
            modified *= sb.current_multiplier;
            break;
          }
        }
      }
    }
    
    return modified;
  }  
}

class NullFloatAttribute extends FloatAttribute
{
  NullFloatAttribute() { super(0f, "", null); }
  
  float get() { return -1f; }
}

class IntAttribute
{
  int base;
  StringList monitored_variables;
  Griddle parent;

  IntAttribute(int base, StringList monitored_variables, Griddle parent) { this.base = base; this.monitored_variables = monitored_variables; this.parent = parent; }
  IntAttribute(int base, String monitored_variable, Griddle parent) { this(base, new StringList(monitored_variable), parent); }
  
  int get()
  {
    int modified = base;
    
    if (parent.game instanceof GameSession) 
    {
      GameSession gs = (GameSession)parent.game;
      
      for (String mv : monitored_variables)
        modified = gs.rules.get_int(mv, modified);
    }
    
    IntVec pos = parent.get_grid_pos();
    for (IntVec offset : adjacent_offsets())
    {
      IntVec opos = pos.copy().add(offset);
      
      Griddle neighbor_griddle = parent.game.grid.get(opos); 
      if (neighbor_griddle instanceof StatusBroadcaster)
      {
        StatusBroadcaster sb = (StatusBroadcaster)neighbor_griddle;
        
        for (String mv : monitored_variables)
        {
          if (sb.statuses.hasValue(mv))
          {
            modified += sb.current_addend;
            modified *= sb.current_multiplier;
            break;
          }
        }
      }
    }
    
    return modified;
  }  
}

/*
class SpeedComponent
{
  float base_speed;
  String variable_name;
  Griddle parent;
  
  SpeedComponent(float base_speed, String variable_name, Griddle parent) { this.base_speed = base_speed; this.variable_name = variable_name; this.parent = parent; }
  
  float get()
  {
    float modified_speed = base_speed;
    
    if (parent.game instanceof GameSession) 
    {
      GameSession gs = (GameSession)parent.game;
      modified_speed = gs.rules.get_float(variable_name, modified_speed);
    }
    
    IntVec pos = parent.get_grid_pos();
    for (IntVec offset : adjacent_offsets())
    {
      IntVec opos = pos.copy().add(offset);
      
      Griddle neighbor_griddle = parent.game.grid.get(opos); 
      if (neighbor_griddle instanceof StatusBroadcaster)
      {
        StatusBroadcaster sb = (StatusBroadcaster)neighbor_griddle;
        
        if (sb.statuses.hasValue("speed"))
          modified_speed *= sb.current_multiplier;
      }
    }
    
    return modified_speed;
  }
}
*/

class ConveyorComponent
{
  //float base_speed = 0.03f;
  //float modified_speed;
  float movement_progress;
  GridGameFlowBase game;
  Griddle parent_griddle;
  NonGriddle ng = null;
  PVector start;
  PVector end;
  Griddle destination_griddle;
  
  FloatAttribute speed;
  
  ConveyorComponent(GridGameFlowBase game, Griddle parent_griddle) { this.game = game; this.parent_griddle = parent_griddle; speed = new NullFloatAttribute(); }
  
  void deserialize(JSONObject o) { float base_speed; if (o == null) base_speed = 0.03f; else base_speed = o.getFloat("base_speed",0.03f);  speed = new FloatAttribute(base_speed, new StringList("Speed:ConveyorBelt","speed"), parent_griddle); }
  JSONObject serialize() { JSONObject retval = new JSONObject(); retval.setFloat("base_speed", speed.base); return retval; }
  
  void start_conveying(Griddle destination, PVector start, PVector end, NonGriddle target)
  {
    destination_griddle = destination;
    this.start = start.copy();
    this.end   = end.copy();
    ng = target;
    
    movement_progress = (start.dist(end) - end.dist(target.pos)) / start.dist(end);
  }
  
  float get_speed() { return speed.get(); }
  
  void update()
  {
    if (ng != null)
    {
      movement_progress += get_speed();
      
      if (movement_progress < 1f)
        ng.pos = PVector.lerp(start,end,movement_progress);
      
      if (movement_progress > 0f && movement_progress < 1f)
      {
        if (!destination_griddle.can_accept_ng(ng))//(!(gg instanceof ConveyorBelt) && !gg.can_accept_ng(ng))
          movement_progress = 0.0f;
      }
      else if (movement_progress >= 1f)
      {
        if (destination_griddle.receive_ng(ng))
          parent_griddle.remove_ng(ng);
        else
          movement_progress = 1f;
      }
    }
  }
  
  boolean is_empty() { return ng == null; }
}
