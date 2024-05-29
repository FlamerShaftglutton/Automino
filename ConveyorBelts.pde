class SmartGrabberBelt extends GrabberBelt
{
  String keyed_ng_type = "";
  PShape keyed_ng_sprite;
  
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
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("keyed_ng_type",keyed_ng_type); o.setString("type", "SmartGrabberBelt"); return o;  }  
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
  void update()
  {
    super.update();
    
    if (ng() == null)
    {
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns+2);
      IntVec xy = globals.active_grid.get_grid_pos_from_object(this).add(iv_offset);
      
      Griddle gg = globals.active_grid.get(xy.x, xy.y);
      //NonGriddle gg_ng = gg.ng();
      
      if (!(gg instanceof Player))
      {
        for (NonGriddle gg_ng : gg.ngs)
        {
          if (can_grab(gg_ng) && receive_ng(gg_ng))
          {
            gg.remove_ng(gg_ng);
            break;
          }
        }
      }
    }
  }
  
  boolean can_grab(NonGriddle ng_to_grab) { return true; }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("type", "GrabberBelt"); return o;  }
}

class SwitchGrabberBelt extends GrabberBelt
{
  boolean enabled = false;
  String disabled_spritename;
  PShape disabled_sprite;
  
  void update() { if (enabled) super.update(); }
  void draw()
  {
    if (enabled)
      super.draw();
    else
      super.draw(disabled_sprite);
  }
  
  void player_interact_end(Player player) { enabled = !enabled; }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("type", "SwitchGrabberBelt"); o.setBoolean("enabled",enabled); o.setString("disabled_sprite", disabled_spritename); return o;  }
  void deserialize(JSONObject o) 
  { 
    super.deserialize(o); 
    enabled = o.getBoolean("enabled"); 
    disabled_spritename = o.getString("disabled_sprite","null");
    disabled_sprite = globals.sprites.get_sprite(disabled_spritename); 
  }
}

class ConveyorBelt extends Griddle
{
  float movement_progress = 0f;
  
  void update()
  {
    NonGriddle ng = ng();
    
    if (ng != null)
    {
      movement_progress += 0.04;//0.015f;
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns);
      IntVec xy = globals.active_grid.get_grid_pos_from_object(this).add(iv_offset);
      
      if (movement_progress < 1f)
      {
        if (movement_progress > 0.5f)
        {
          //stop half-way if the next thing can't take this yet (unless it's another conveyor belt)
          Griddle gg = globals.active_grid.get(xy.x, xy.y);
          
          if (!gg.can_accept_ng(ng))//(!(gg instanceof ConveyorBelt) && !gg.can_accept_ng(ng))
            movement_progress = 0.5f;
        }
        
        PVector start;
        PVector end;
        
        switch (quarter_turns & 3)
        {
          case 0: start = center_left(); end = center_right(); break;
          case 1: start = bottom_center(); end = top_center(); break;
          case 2: start = center_right(); end = center_left(); break;
          case 3: start = top_center(); end = bottom_center(); break;
          default: start = end = center_center(); break;
        }
        
        //PVector offset = iv_offset.toPVec();
        //offset.x *= dim.x;
        //offset.y *= dim.y;
        //end.add(offset);
        
        ng.pos = PVector.lerp(start,end,movement_progress);
      }
      else
      {
        //find the neighboring griddle and try to pass this off
        if (globals.active_grid.get(xy.x,xy.y).receive_ng(ng))
          remove_ng(ng);
        else
          movement_progress = 1f;
      }
    }
  }
  
  boolean can_accept_ng(NonGriddle n) { return ngs.isEmpty(); }
  
  boolean receive_ng(NonGriddle ng)
  {
    if (!super.receive_ng(ng))
      return false;
    
    movement_progress = 0f;
    
    return true;
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("type", "ConveyorBelt"); return o;  }
}
