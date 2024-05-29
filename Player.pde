
class Player extends Griddle
{
  Direction face;
  
  Player() { super(new PVector(), new PVector()); face = Direction.EAST; }
  
  void update()
  {
    if (globals.keyReleased)
    {
      if (key == CODED && (keyCode == RIGHT || keyCode == DOWN || keyCode == LEFT || keyCode == UP))
      {
        IntVec offset = new IntVec(0,0);
        
        switch (keyCode)
        {
          case RIGHT: face = Direction.EAST;  ++offset.x; break;
          case DOWN:  face = Direction.SOUTH; ++offset.y; break;
          case LEFT:  face = Direction.WEST;  --offset.x; break;
          case UP:    face = Direction.NORTH; --offset.y; break;
          default: break;
        }
        
        IntVec p = globals.active_grid.get_grid_pos_from_object(this);
        IntVec np = p.copy().add(offset);
        
        Griddle g = globals.active_grid.get(np);
        
        if (g.traversable)
        {
          globals.active_grid.set(p, g);
          globals.active_grid.set(np, this);
        }
      }
      else if (key == 'x')
      {
        IntVec offset = offset_from_direction(face);
        IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        
        Griddle g = globals.active_grid.get(gpos.copy().add(offset));
        
        g.player_interact_end(this);
      }
      else if (key == ' ')
      {
        IntVec offset = offset_from_direction(face);
        IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        
        Griddle g = globals.active_grid.get(gpos.copy().add(offset));
        
        //try to pick up
        if (ngs.isEmpty() && g.can_give_ng())
        {
          NonGriddle gng = g.ng();
          
          if (gng != null && receive_ng(gng))
            g.remove_ng(gng);
          
          if (gng instanceof LevelEditorNonGriddle)
            ((LevelEditorNonGriddle)gng).visible = true;
        }
        
        //try to put down
        else
        {
          if (ng() instanceof LevelEditorNonGriddle)
            ((LevelEditorNonGriddle)ng()).visible = false;
          
          if (g.receive_ng(ng()))
            remove_ng();
        }
      }
    }
    else if (keyPressed && key == 'x')
    {
      IntVec offset = offset_from_direction(face);
      IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
      
      Griddle g = globals.active_grid.get(gpos.copy().add(offset));
      
      g.player_interact(this);
    }
    //DEBUG
    else if (keyPressed && key == 'p')
    {
      IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
      
      println("Player object at grid pos { x: " + gpos.x + ", y: " + gpos.y + " }, pos { x: " + pos.x + ", y: " + pos.y + " }, ng: " + (ng() != null ? ng().name : "null") + ", json: " + this.serialize().toString());
    }
    else if (keyPressed && key == 'd')
    {
      
    }
    
    if (ng() != null)
    {
      PVector offset = offset_from_direction(face).toPVec().mult(dim.x * 0.4);
      
      ng().pos = center_center().add(offset);
    }
    
    quarter_turns = quarter_turns_from_direction(face);
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("type", "Player"); return o;  }
  void deserialize(JSONObject o) { super.deserialize(o); face = direction_from_quarter_turns(quarter_turns); }
}
