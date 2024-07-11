
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
    boolean pressed_left  = globals.keyboard.is_coded_key_pressed(LEFT);
    boolean pressed_right = globals.keyboard.is_coded_key_pressed(RIGHT);
    boolean pressed_down  = globals.keyboard.is_coded_key_pressed(DOWN);
    boolean pressed_up    = globals.keyboard.is_coded_key_pressed(UP);
    boolean held_ctrl     = globals.keyboard.is_coded_key_held(CONTROL);
    boolean held_x        = globals.keyboard.is_key_held('x');
    boolean released_x    = globals.keyboard.is_key_released('x');
    boolean pressed_space = globals.keyboard.is_key_pressed(' ');
    boolean pressed_qm    = globals.keyboard.is_key_pressed('/') || globals.keyboard.is_key_pressed('?');
    
    if (pressed_left || pressed_right || pressed_down || pressed_up)
    {
      IntVec offset = new IntVec(0,0);
      
      if (pressed_right)
      {
        rot = 0f;
        ++offset.x;
      }
      else if (pressed_up)
      {
        rot = PI + HALF_PI;
        --offset.y;
      }
      else if (pressed_left)
      {
        rot = PI;
        --offset.x;
      }
      else if (pressed_down)
      {
        rot = HALF_PI;
        ++offset.y;
      }
      
      if (!held_ctrl)
      {
        Griddle fg = get_faced_griddle(parent.grid);
            
        if (fg.traversable)// || PVector.dist(pos, fg.center_center()) > dim.x)
        {
          //TODO: make this not gridlocked. 
          pos.add(PVector.fromAngle(rot).mult(dim.x));
        }
      }
    }
    else if (released_x)
    {
      get_faced_griddle(parent.grid).player_interact_end(this);
    }
    else if (pressed_space)
    {
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
    else if (pressed_qm)
    {
      Griddle fg = get_faced_griddle(parent.grid);
        
      if (fg instanceof LevelEditorGriddle)
      {
        LevelEditorGriddle leg = (LevelEditorGriddle)fg;
        
        if (!leg.ngs.isEmpty())
        {
          JSONObject lengo = ((LevelEditorNonGriddle)leg.ng()).as_json;
          globals.messages.post_message("info", globals.gFactory.get_description(lengo.getString("_template",lengo.getString("type",""))));
        }
      }
      else if (fg instanceof MetaActionCounter)
        globals.messages.post_message("info", globals.gFactory.get_description(((MetaActionCounter)fg).parameters.get(0)));
      else
        globals.messages.post_message("info", globals.gFactory.get_description(fg.template));
    }
    else if (held_x)
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
