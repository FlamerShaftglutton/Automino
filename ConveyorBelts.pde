class SmartGrabberBelt extends GrabberBelt
{
  String keyed_ng_type = "";
  PShape keyed_ng_sprite;
  
  SmartGrabberBelt(GridGameFlowBase game) { super(game); type = "SmartGrabberBelt"; }
  
  void draw()
  {
    super.draw();
    
    if (keyed_ng_type != null && !keyed_ng_type.equals("") && keyed_ng_sprite != null)
    {
      pushMatrix();
      
      translate(pos);
      
      shape(keyed_ng_sprite, dim.x * 0.05f, dim.y * 0.05f, dim.x * 0.1f, dim.y * 0.1f);
      
      popMatrix();
    }
  }
  
  boolean can_grab(NonGriddle ng_to_grab) { return keyed_ng_type == null || keyed_ng_type.equals("") || ng_to_grab.name.equals(keyed_ng_type); }
  
  boolean receive_ng(NonGriddle ng)
  {
    if (!super.receive_ng(ng))
      return false;
    
    keyed_ng_type = ng.name;
    keyed_ng_sprite = ng.shape;
    
    return true;
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("keyed_ng_type",keyed_ng_type); return o;  }  
  void deserialize(JSONObject o) 
  { 
    super.deserialize(o); 
    keyed_ng_type = o.getString("keyed_ng_type",""); 
    if (!keyed_ng_type.equals("")) 
      keyed_ng_sprite = globals.ngFactory.create_ng(keyed_ng_type).shape; 
  }
}

class GrabberBelt extends ConveyorBelt
{
  GrabberBelt(GridGameFlowBase game) { super(game); type = "GrabberBelt"; }
  
  void update()
  {
    super.update();
    
    if (ngs.isEmpty())
    {
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns);
      IntVec xy = game.grid.get_grid_pos_from_object(this);
      IntVec from_neighbor = xy.copy().sub(iv_offset);
      
      Griddle gg_from = game.grid.get(from_neighbor);

      if (!(gg_from instanceof ConveyorBelt) || gg_from.quarter_turns != quarter_turns)
      {
        for (NonGriddle gg_ng : gg_from.ngs)
        {
          if (gg_ng != null && can_grab(gg_ng) && receive_ng(gg_ng))
          {
            gg_from.remove_ng(gg_ng);
            
            //figure out how far back to set it
            PVector start = center_center();
            PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
            
            Griddle gg_to = game.grid.get(get_grid_pos().add(iv_offset));
            
            comp.start_conveying(gg_to, start, end, gg_ng);
            comp.movement_progress = (start.dist(end) - end.dist(gg_ng.pos)) / start.dist(end);

            break;
          }
        }
      }
    }
  }
  
  boolean can_grab(NonGriddle ng_to_grab) { return true; }
}

class SwitchGrabberBelt extends GrabberBelt
{
  boolean enabled = false;
  String disabled_spritename;
  PShape disabled_sprite;
  
  SwitchGrabberBelt(GridGameFlowBase game) { super(game); type = "SwitchGrabberBelt"; }
  
  void update() { if (enabled) super.update(); }
  void draw()
  {
    if (enabled)
      super.draw();
    else
      super.draw(disabled_sprite);
  }
  
  void player_interact_end(Player player) { enabled = !enabled; }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setBoolean("enabled",enabled); o.setString("disabled_sprite", disabled_spritename); return o;  }
  void deserialize(JSONObject o) 
  { 
    super.deserialize(o); 
    enabled = o.getBoolean("enabled"); 
    disabled_spritename = o.getString("disabled_sprite","null");
    disabled_sprite = globals.sprites.get_sprite(disabled_spritename); 
  }
}


class CrossConveyorBelt extends ConveyorBelt
{
  ConveyorComponent horizontal;
  ConveyorComponent vertical;
  
  CrossConveyorBelt(GridGameFlowBase game) { super(game); type = "CrossConveyorBelt"; horizontal = new ConveyorComponent(game, this); vertical = new ConveyorComponent(game, this); ngs = new ArrayList<NonGriddle>(); ngs.add(null); ngs.add(null); }
  
  void deserialize(JSONObject o) { super.deserialize(o); horizontal.deserialize(o.getJSONObject("horizontal")); vertical.deserialize(o.getJSONObject("vertical"));  }
  JSONObject serialize() { JSONObject retval = super.serialize(); retval.setJSONObject("horizontal", horizontal.serialize()); retval.setJSONObject("vertical", vertical.serialize()); return retval; }
  
  void update()
  {
    horizontal.update();
    vertical.update();
  } 
  
  boolean can_accept_ng(NonGriddle n) { return horizontal.ng == null || vertical.ng == null; }
  
  void start_horizontal(NonGriddle ng)
  {
    PVector start = center_center();
    PVector end = start.copy();
    
    IntVec offset = new IntVec((quarter_turns & 3) == 0 || (quarter_turns & 3) == 3 ? 1 : -1, 0);
    
    end.add(offset.toPVec().mult(dim.x));
    
    horizontal.start_conveying(game.grid.get(get_grid_pos().add(offset)), start, end, ng);
  }
  
  void start_vertical(NonGriddle ng)
  {
    PVector start = center_center();
    PVector end = start.copy();
    
    IntVec offset = new IntVec(0,(quarter_turns & 3) < 2 ? -1 : 1);
    
    end.add(offset.toPVec().mult(dim.x));
    
    vertical.start_conveying(game.grid.get(get_grid_pos().add(offset)), start, end, ng);
    
  }
  
  boolean receive_ng(NonGriddle ng)
  {
    IntVec sender_offset = get_ng_owner_offset(ng);
    
    //this is coming from a player
    if (sender_offset == null)
    {
      PVector ppos = game.player.pos.copy().sub(dim.copy().div(2));
      
      if (vertical.ng == null && abs(ppos.y - pos.y) > 0.1f)
      {
        ngs.set(1,ng);
        start_vertical(ng);
        return true;
      }
      else if (horizontal.ng == null && abs(ppos.x - pos.x) > 0.1f)
      {
        ngs.set(0,ng);
        start_horizontal(ng);
        return true;
      }
      else
        return false;
    }
    else
    {
      if (sender_offset.x != 0 && horizontal.ng == null)
      {
        ngs.set(0,ng);
        start_horizontal(ng);
        return true;
      }
      else if (sender_offset.y != 0 && vertical.ng == null)
      {
        ngs.set(1,ng);
        start_vertical(ng);
        return true;
      }
      else
        return false;
    }
  }
  
  IntVec get_ng_owner_offset(NonGriddle ng)
  {
    IntVec mpos = game.grid.get_grid_pos_from_object(this);
    
    for (IntVec iv : orthogonal_offsets())
    {
      IntVec op = mpos.copy().add(iv);
      
      Griddle sender = game.grid.get(op);
      
      if (sender.ngs.contains(ng))
        return iv;
    }
    
    return null;
  }
  
  void    remove_ng(NonGriddle ng) { if (ngs.get(0) == ng) { ngs.set(0, null); horizontal.ng = null; } else if (ngs.get(1) == ng) {ngs.set(1,null); vertical.ng = null; } else println("Not sure what to remove from CrossConveyor"); }
  void    remove_ng() 
  {
    if (ngs.get(0) == null && ngs.get(1) != null)
    {
      ngs.set(1,null);
      vertical.ng = null;
    }
    else
    {
      ngs.set(0,null);
      horizontal.ng = null;
    }
  }
}

class ConveyorComponent
{
  float base_speed = 0.03f;
  float modified_speed;
  float movement_progress;
  GridGameFlowBase game;
  Griddle parent_griddle;
  NonGriddle ng = null;
  PVector start;
  PVector end;
  Griddle destination_griddle;
  
  ConveyorComponent(GridGameFlowBase game, Griddle parent_griddle) { this.game = game; this.parent_griddle = parent_griddle; }
  
  void deserialize(JSONObject o) { if (o != null) { base_speed = o.getFloat("base_speed", 0.03f); } if (game instanceof GameSession) { modified_speed = ((GameSession)game).rules.get_float("Speed:ConveyorBelt", base_speed);  } else modified_speed = base_speed; }
  JSONObject serialize() { JSONObject retval = new JSONObject(); retval.setFloat("base_speed", base_speed); return retval; }
  
  void start_conveying(Griddle destination, PVector start, PVector end, NonGriddle target)
  {
    destination_griddle = destination;
    this.start = start.copy();
    this.end   = end.copy();
    ng = target;
    
    movement_progress = 0f;
  }
  
  void update()
  {
    if (ng != null)
    {
      movement_progress += modified_speed;
      
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

class ConveyorBelt extends Griddle
{
  ConveyorComponent comp;
  
  ConveyorBelt(GridGameFlowBase game) { super(game); type = "ConveyorBelt"; comp = new ConveyorComponent(game, this); }
  
  void deserialize(JSONObject o) { super.deserialize(o); comp.deserialize(o.getJSONObject("component"));  }
  JSONObject serialize() { JSONObject retval = super.serialize(); retval.setJSONObject("component", comp.serialize()); return retval; }
  
  void update()
  {
    comp.update();
  }
  
  boolean can_accept_ng(NonGriddle n) { return ngs.isEmpty(); }
  
  boolean receive_ng(NonGriddle ng)
  {
    if (!super.receive_ng(ng))
      return false;
    
    IntVec iv_offset = offset_from_quarter_turns(quarter_turns);
    IntVec xy = get_grid_pos().add(iv_offset);
    Griddle gg = game.grid.get(xy.x, xy.y);
    
    PVector start = center_center();
    PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
    
    comp.start_conveying(gg, start, end, ng);
    
    return true;
  }
  
  void remove_ng(NonGriddle ng) { super.remove_ng(ng); comp.ng = null; }
}
