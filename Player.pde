
class Player
{
  float rot = 0f;
  PVector pos;
  PVector dim;
  PShape sprite;
  String spritename;
  
  NonGriddle ng;
  
  Player(PVector pos, PVector dim) { this.pos = pos.copy(); this.dim = dim.copy(); rot = 0f; ng = null; sprite = null; spritename = ""; }
  
  Player() { this(new PVector(), new PVector()); }
  
  void draw()
  {
    pushMatrix();
          
    translate(pos);
    
    rotate(rot);
    
    translate(dim.copy().mult(-0.5f));
    
    shape(sprite,0,0,dim.x, dim.y);
    
    popMatrix();
  }
  
  void update(Grid grid)
  {
    if (globals.keyReleased)
    {
      
      if (key == CODED && (keyCode == RIGHT || keyCode == DOWN || keyCode == LEFT || keyCode == UP))
      {
        IntVec offset = new IntVec(0,0);
        
        switch (keyCode)
        {
          case RIGHT: rot = 0f;            ++offset.x; break;
          case DOWN:  rot = HALF_PI;       ++offset.y; break;
          case LEFT:  rot = PI;            --offset.x; break;
          case UP:    rot = PI + HALF_PI;  --offset.y; break;
          default: break;
        }
        
        //IntVec p = globals.active_grid.get_grid_pos_from_object(this);
        //IntVec np = p.copy().add(offset);
        
        Griddle fg = get_faced_griddle(grid);
        
        if (fg.traversable)// || PVector.dist(pos, fg.center_center()) > dim.x)
        {
          //TODO: make this not gridlocked. 
          pos.add(PVector.fromAngle(rot).mult(dim.x));
        }
      }
      else if (key == 'x')
      {
        //IntVec offset = offset_from_direction(face);
        //IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        get_faced_griddle(grid).player_interact_end(this);
      }
      else if (key == ' ')
      {
        //IntVec offset = offset_from_direction(face);
        //IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        
        //Griddle g = globals.active_grid.get(gpos.copy().add(offset));
        Griddle fg = get_faced_griddle(grid);
        
        //try to pick up
        if (ng == null && fg.can_give_ng())
        {
          NonGriddle gng = fg.ng();
          
          if (gng != null)
          {
            if (gng instanceof LevelEditorNonGriddle)
              ((LevelEditorNonGriddle)gng).visible = true;
            
            fg.remove_ng(gng);
            ng = gng;
          }
        }
        
        //try to put down
        else
        {
          if (ng instanceof LevelEditorNonGriddle)
            ((LevelEditorNonGriddle)ng).visible = false;
          
          if (fg.receive_ng(ng))
            ng = null;
        }
      }
    }
    else if (keyPressed && key == 'x')
    {
      get_faced_griddle(grid).player_interact(this);
    }
    //DEBUG
    /*
    else if (keyPressed && key == 'p')
    {
      IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
      
      println("Player object at grid pos { x: " + gpos.x + ", y: " + gpos.y + " }, pos { x: " + pos.x + ", y: " + pos.y + " }, ng: " + (ng() != null ? ng().name : "null") + ", json: " + this.serialize().toString());
    }
    else if (keyPressed && key == 'd')
    {
      
    }
    */
    
    if (ng != null)
    {
      ng.pos = PVector.fromAngle(rot).mult(dim.x * 0.4f).add(pos);
     // PVector offset = offset_from_direction(face).toPVec().mult(dim.x * 0.4);
      
      //ng().pos = center_center().add(offset);
    }
  }
  
  IntVec get_face_square(Grid grid)
  {
    //first we need to make a point that is one edge_width in the direction the player is facing
    PVector p = PVector.fromAngle(rot).mult(dim.x).add(pos);
    
    //now get the grid coordinates from the grid
    return grid.grid_pos_from_absolute_pos(p); //<>//
  }
  
  Griddle get_faced_griddle(Grid grid)
  {
    return grid.get(PVector.fromAngle(rot).mult(dim.x).add(pos));
  }
  
  //JSONObject serialize() { JSONObject o = new JSONObject(); IntVec gp = globals.session.grid.grid_pos_from_absolute_pos(pos); o.setInt("x", gp.x); o.setInt("y", gp.y); o.setString("type", "Player"); return o;  }
  //void deserialize(JSONObject o) { pos = globals.session.grid.absolute_pos_from_grid_pos(new IntVec(o.getInt("x"), o.getInt("y"))); }
}
