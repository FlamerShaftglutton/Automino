
class Player
{
  float rot = 0f;
  PVector pos;
  PVector dim;
  PShape sprite;
  String spritename;
  GridGameFlowBase parent;
  
  NonGriddle ng;
  
  Player(PVector pos, PVector dim, GridGameFlowBase parent) { this.pos = pos.copy(); this.dim = dim.copy(); rot = 0f; ng = null; sprite = null; spritename = ""; this.parent = parent; }
  
  Player(GridGameFlowBase parent) { this(new PVector(), new PVector(), parent); }
  
  void draw()
  {
    pushMatrix();
          
    translate(pos);
    
    rotate(rot);
    
    translate(dim.copy().mult(-0.5f));
    
    shape(sprite,0,0,dim.x, dim.y);
    
    popMatrix();
  }
  
  void update()
  {
    if (globals.keyReleased)
    {
      
      if (key == CODED && (keyCode == RIGHT || keyCode == DOWN || keyCode == LEFT || keyCode == UP))
      {
        IntVec offset = new IntVec(0,0);
        
        //float old_rot = rot;
        
        switch (keyCode)
        {
          case RIGHT: rot = 0f;            ++offset.x; break;
          case DOWN:  rot = HALF_PI;       ++offset.y; break;
          case LEFT:  rot = PI;            --offset.x; break;
          case UP:    rot = PI + HALF_PI;  --offset.y; break;
          default: break;
        }
        
        //if (abs(rot - old_rot) < 0.1f)
        //{
          Griddle fg = get_faced_griddle(parent.grid);
          
          if (fg.traversable)// || PVector.dist(pos, fg.center_center()) > dim.x)
          {
            //TODO: make this not gridlocked. 
            pos.add(PVector.fromAngle(rot).mult(dim.x));
          }
        //}
      }
      else if (key == 'x')
      {
        //IntVec offset = offset_from_direction(face);
        //IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        get_faced_griddle(parent.grid).player_interact_end(this);
      }
      else if (key == ' ')
      {
        //IntVec offset = offset_from_direction(face);
        //IntVec gpos = globals.active_grid.get_grid_pos_from_object(this);
        
        //Griddle g = globals.active_grid.get(gpos.copy().add(offset));
        Griddle fg = get_faced_griddle(parent.grid);
        
        //try put down
        if (ng != null)
        {
          if (fg.receive_ng(ng))
          {
            if (ng instanceof LevelEditorNonGriddle)
              ((LevelEditorNonGriddle)ng).visible = false;
              
            ng = null;
          }
        }
        //try to pick up
        else if (fg.can_give_ng() && !fg.ngs.isEmpty())
        {
          NonGriddle gng = fg.ngs.get(0);
          
          if (gng instanceof LevelEditorNonGriddle)
            ((LevelEditorNonGriddle)gng).visible = true;
          
          fg.remove_ng(gng);
          ng = gng;
        }
      }
    }
    else if (keyPressed && key == 'x')
      get_faced_griddle(parent.grid).player_interact(this);
    
    if (ng != null)
      ng.pos = PVector.fromAngle(rot).mult(dim.x * 0.4f).add(pos);
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
}
