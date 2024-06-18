
class Griddle
{
  PVector pos;
  PVector dim;
  int     quarter_turns;
  boolean traversable = false;
  
  ArrayList<NonGriddle> ngs;
  
  String spritename;
  PShape sprite;
  
  String template = "";
  String type = "Griddle";
  
  GridGameFlowBase game;
  
  Griddle(GridGameFlowBase game) { this.game = game; pos = new PVector(); dim = new PVector(); quarter_turns = 0; traversable = false; ngs = new ArrayList<NonGriddle>(); spritename = ""; sprite = null; template = ""; type = "Griddle"; }

  void draw()
  {
    draw(sprite);
  }
  
  void draw(PShape s)
  {
    if (s != null)
    {
      pushMatrix();
      
      translate(center_center());
      
      rotate(-quarter_turns * HALF_PI);
      
      translate(dim.copy().mult(-0.5f));
      
      shape(s,0,0,dim.x, dim.y);
      
      popMatrix();
    }
  }
  
  void update()
  {
    center_ngs();
  }
  
  JSONObject serialize()
  {
    JSONObject o = new JSONObject();
    o.setString("type", type);
    o.setString("sprite", spritename);
    o.setBoolean("traversable", traversable);
    o.setInt("quarter_turns", quarter_turns);
    o.setString("_template", template);
    
    return o;
  }
  
  void deserialize(JSONObject o) { spritename = o.getString("sprite","null"); if (spritename.length() > 0)  sprite = globals.sprites.get_sprite(spritename); quarter_turns = o.getInt("quarter_turns", 0); template = o.getString("_template",o.getString("type",type)); }
  
  NonGriddle ng() { if (ngs.isEmpty()) return null; return ngs.get(ngs.size()-1); }
  boolean can_accept_ng(NonGriddle n) { return ngs.size() <= 1; }
  boolean can_give_ng() { return true; }
  boolean receive_ng(NonGriddle ng) { if (!can_accept_ng(ng)) return false; ngs.add(ng); return true; }
  void    remove_ng(NonGriddle ng) { ngs.remove(ng); }
  void    remove_ng() { if (!ngs.isEmpty()) ngs.remove(ngs.size() - 1); }
  void    center_ngs() 
  {
    if (ngs.size() == 1)
      ngs.get(0).pos = center_center();
    
    if (ngs.size() <= 1)
      return;
    
    float xtw = dim.x * 0.4f;
    float xstep = xtw  / ngs.size();
    float xstart = xtw * -0.5f;
    
    for (int i = 0 ; i < ngs.size(); ++i)
      ngs.get(i).pos = center_center().add(xstart + xstep * i,0f); 
  }
  
  
  void    player_interact(Player player) { }
  void    player_interact_end(Player player) { }
  
  IntVec get_grid_pos() { return game.grid.get_grid_pos_from_object(this); }
  
  
  PVector top_left() { return pos.copy(); }
  PVector top_center() { return pos.copy().add(dim.x * 0.5f, 0f); }
  PVector top_right() { return pos.copy().add(dim.x, 0f); }
  PVector center_left() { return pos.copy().add(0f, dim.y * 0.5f); }
  PVector center_center() { return pos.copy().add(dim.copy().mult(0.5f)); }
  PVector center_right() { return pos.copy().add(dim.x, dim.y * 0.5f); }
  PVector bottom_left() { return pos.copy().add(0f, dim.y); }
  PVector bottom_center() { return pos.copy().add(dim.x * 0.5f, dim.y); }
  PVector bottom_right() { return pos.copy().add(dim); }
}

class NullGriddle extends Griddle
{
  NullGriddle(GridGameFlowBase game) { super(game); type = "NullGriddle"; }
  NullGriddle() { this(null); }
  
  boolean can_accept_ng(NonGriddle n) { return false; }
  
  void draw() {  }
  void update() {  }
}

class EmptyGriddle extends Griddle
{
  EmptyGriddle(GridGameFlowBase game) { super(game); traversable = true; type = "EmptyGriddle"; }
  
  boolean can_accept_ng(NonGriddle n) { return ngs.isEmpty(); }
  
  void draw() 
  {     
    noFill();
    stroke(#000000);
    strokeWeight(1f);
    
    rect(pos.x, pos.y, dim.x, dim.y); 
  }
  
  void update() { if (ng() != null) ng().pos = center_center(); }
}

class WallGriddle extends Griddle
{
  WallGriddle() { this(null); }
  WallGriddle(GridGameFlowBase game) { super(game); traversable = false; type = "WallGriddle"; }
  
  boolean can_accept_ng(NonGriddle n) { return false; }
}

class PlayerGriddle extends Griddle
{
  PlayerGriddle(GridGameFlowBase game) { super(game); type = "PlayerGriddle"; }
}
