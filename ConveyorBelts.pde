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
    
    if (ng() == null)
    {
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns);
      IntVec xy = game.grid.get_grid_pos_from_object(this);
      //IntVec to_neighbor = xy.copy().add(iv_offset);
      IntVec from_neighbor = xy.copy().sub(iv_offset);
      
      //Griddle gg_to = game.grid.get(to_neighbor);
      Griddle gg_from = game.grid.get(from_neighbor);

      if (!(gg_from instanceof ConveyorBelt) || gg_from.quarter_turns != quarter_turns)
      {
        for (NonGriddle gg_ng : gg_from.ngs)
        {
          if (can_grab(gg_ng) && receive_ng(gg_ng))
          {
            gg_from.remove_ng(gg_ng);
            
            //figure out how far back to set it
            PVector start = center_center();
            PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
            
            movement_progress = (start.dist(end) - end.dist(gg_ng.pos)) / start.dist(end); //<>//
            
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
  NonGriddle ng_vertical = null;
  NonGriddle ng_horizontal = null;
  float movement_progress_vertical = 0f;
  float movement_progress_horizontal = 0f;
  
  CrossConveyorBelt(GridGameFlowBase game) { super(game); type = "CrossConveyorBelt"; }
  
  void update()
  {
    if (ng_vertical != null)
      movement_progress_vertical = move_conveyor(ng_vertical, movement_progress_vertical, (quarter_turns & 3) < 2 ? 1 : 3);
    
    if (ng_horizontal != null)
      movement_progress_horizontal = move_conveyor(ng_horizontal, movement_progress_horizontal, (quarter_turns & 3) == 0 || (quarter_turns & 3) == 3 ? 0 : 2);
  }
  
  float move_conveyor(NonGriddle ng, float amount, int qts)
  {
    float retval = amount + 0.03f;
    
    IntVec offset = offset_from_quarter_turns(qts);
    PVector start = center_center();
    PVector end   = offset.toPVec().mult(dim.x).add(start);
    
    if (retval < 0.4f)
      ng.pos = PVector.lerp(start, end, retval);
    else
    {
      Griddle reciever = game.grid.get(game.grid.get_grid_pos_from_object(this).add(offset));
      
      if (retval < 1f)
      {
        if (!reciever.can_accept_ng(ng))
        {
          retval = min(amount,0.4f);
        }
        
        ng.pos = PVector.lerp(start, end, retval);
      }
      else
      {
        if (reciever.receive_ng(ng))
        {
          remove_ng(ng);
          retval = 0f;
        }
        else
        {
          retval = 1f;
        }
      }
    }
    
    return retval;
  }
  
  boolean can_accept_ng(NonGriddle n) { return ng_vertical == null || ng_horizontal == null; }
  
  boolean receive_ng(NonGriddle ng)
  {
    
    IntVec sender_offset = get_ng_owner_offset(ng);
    
    //this is coming from a player
    if (sender_offset == null)
    {
      if (ng_vertical == null)
      {
        ng_vertical = ng;
        //ng.pos = center_center();
        movement_progress_vertical = 0f;
        return true;
      }
      
      if (ng_horizontal == null)
      {
        ng_horizontal = ng;
        //ng_pos = center_center();
        movement_progress_horizontal = 0f;
        return true;
      }
      
      return false;
    }
    
    //this is coming from one of the sides
    else if (sender_offset.x != 0 && ng_horizontal == null)
    {
      ng_horizontal = ng;
      movement_progress_horizontal = 0f;
      return true;
    }
    
    //this is coming from the top or bottom
    else if (sender_offset.y != 0 && ng_vertical == null)
    {
      ng_vertical = ng;
      movement_progress_horizontal = 0f;
      return true;
    }
    
    return false;
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
  
  void    remove_ng(NonGriddle ng) { if (ng_horizontal == ng) ng_horizontal = null; else if (ng_vertical == ng) ng_vertical = null; else println("Not sure what to remove from CrossConveyor"); }
  void    remove_ng() 
  {
    //DEBUG
    println("Probably shouldn't do this..."); 
    
    if ((ng_horizontal == null && ng_vertical != null) || movement_progress_vertical > movement_progress_horizontal)
      ng_vertical = null; 
    else //if ((ng_horizontal != null && ng_vertical == null) || movement_progress_vertical < movement_progress_horizontal)
      ng_horizontal = null;
  }
}

class ConveyorBelt extends Griddle
{
  float movement_progress = 0f;
  
  ConveyorBelt(GridGameFlowBase game) { super(game); type = "ConveyorBelt"; }
  
  void update()
  {
    NonGriddle ng = ng();
    
    if (ng != null)
    {
      movement_progress += 0.03f;//0.015f;
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns);
      IntVec xy = game.grid.get_grid_pos_from_object(this).add(iv_offset);
      
      if (movement_progress < 1f)
      {
        //stop if the next thing can't take this yet
        Griddle gg = game.grid.get(xy.x, xy.y);
        
        if (!gg.can_accept_ng(ng))//(!(gg instanceof ConveyorBelt) && !gg.can_accept_ng(ng))
          movement_progress = min(0.0f, movement_progress);

        
        PVector start = center_center();
        PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
        
        /*
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
        */
        
        //PVector offset = iv_offset.toPVec();
        //offset.x *= dim.x;
        //offset.y *= dim.y;
        //end.add(offset);
        
        ng.pos = PVector.lerp(start,end,movement_progress);
      }
      else
      {
        //find the neighboring griddle and try to pass this off
        if (game.grid.get(xy.x,xy.y).receive_ng(ng))
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
}
