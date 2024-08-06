class Transformer extends Griddle
{
  StringList operations = new StringList();
  boolean running = false;
  float time_used = 0f;
  Interaction current_interaction;
  boolean automatic = false;
  float base_speed = 0.01f;
  float modified_speed;
  StringList extra_inputs = new StringList();
  StringList extra_outputs = new StringList();
  
  Transformer(GridGameFlowBase game) { super(game); type = "Transformer"; }
  
  void update()
  {
    if (running && ngs.isEmpty())
    {
      running = false;
      time_used = 0f;
      current_interaction = null;
    }
    
    if (running)
    {
      if (automatic)
        time_used += get_speed();
      
      if (time_used >= current_interaction.time)
        finish_transformation();
    }
    
    super.update();
  }
  
  float get_speed() { return modified_speed; }
  
  void remove_ng(NonGriddle ng)
  { 
    super.remove_ng(ng);
    
    start_transformation();
  }
  void remove_ng()
  {
    super.remove_ng();
    
    start_transformation();
  }
  
  void start_transformation()
  {
    time_used = 0f;
    current_interaction = null;
    
    StringList to_find_extra_inputs = extra_inputs.copy();
    
    for (NonGriddle ng : ngs)
    {
      if (to_find_extra_inputs.hasValue(ng.name))
        to_find_extra_inputs.removeValue(ng.name);
    }
    
    if (to_find_extra_inputs.size() == 0)
      current_interaction = first_matching_interaction(ngs);
    
    running = current_interaction != null;
  }
  
  void finish_transformation()
  {
    running = false;
    
    //destroy all inputs
    for (NonGriddle ng : ngs)
      game.destroy_ng(ng);
    
    ngs.clear();
    
    //create the outputs
    StringList modified_outputs = current_interaction.output_ngs.copy();
    modified_outputs.append(extra_outputs);
    for (String output_ng_name : modified_outputs)
    {
      NonGriddle ng2 = game.create_and_register_ng(output_ng_name);
      
      if (!permissive_receive_ng(ng2))
        println("Something went wrong in Transformer. New ng created but could not be stored. Old ng is already dead.");
    }
  }
  
  void player_interact(Player player)
  {  
    if (!automatic)
    {
      if (running)
        time_used += get_speed();
      else
        start_transformation();
    }
  }
  
  void draw()
  {
    super.draw();
    
    pushMatrix();
    
    translate(pos);
    
    if (running && current_interaction != null)
    {
      fill(200);
      strokeWeight(1f);
      stroke(50);
      
      rect(dim.x * 0.1, dim.y * 0.1, dim.x * 0.8, dim.y * 0.1);
      
      fill(#66FF66);
      
      rect(dim.x * 0.1, dim.y * 0.1, dim.x * 0.8 * time_used / current_interaction.time , dim.y * 0.1);
    }
    
    popMatrix();
    
  }
  
  Interaction first_matching_interaction(StringList ng_names)
  {
    for (String operation : operations)
    {
      if (globals.interactions.interaction_exists(operation, ng_names))
        return globals.interactions.get_interaction(operation, ng_names); 
    }
    
    return null;
  }
  
  Interaction first_matching_interaction(ArrayList<NonGriddle> ng_list)
  {
    StringList sl = new StringList();
    for (int i = 0; i < ng_list.size(); ++i)
      sl.push(ng_list.get(i).name);
    
    return first_matching_interaction(sl);
  }
  
  
  boolean can_accept_ng(NonGriddle n)
  {
    //the first thing is always accepted
    if (ngs.isEmpty())
      return true;
    
    //the second thing will only be accepted if there is a matching interaction using the first thing
    StringList sl = get_ng_names();
    sl.push(n.name);
    
    return first_matching_interaction(sl) != null;
  }
  
  
  boolean receive_ng(NonGriddle ng) 
  { 
    return can_accept_ng(ng) && permissive_receive_ng(ng);
  }
  
  boolean permissive_receive_ng(NonGriddle ng)
  {
    ngs.add(ng);
    
    start_transformation();
    
    running = running && automatic;
    
    return true;
  }
  
  StringList get_ng_names() { StringList retval = new StringList(); for (int i = 0; i < ngs.size(); ++i) retval.append(ngs.get(i).name); return retval; }
  
  void deserialize(JSONObject o)
  {
    super.deserialize(o); 
    base_speed = o.getFloat("speed", 0.01f);
    modified_speed = base_speed;
    automatic = o.getBoolean("automatic", false); 
    operations = getStringList("operations", o);
    extra_inputs  = new StringList();
    extra_outputs = new StringList();
    
    if (game instanceof GameSession) 
    {
      GameSession gs = (GameSession)game;
      modified_speed = base_speed;
      for (String operation : operations)
      {
        modified_speed = gs.rules.get_float("Speed:"+operation, modified_speed);
        extra_inputs.append (gs.rules.get_strings("Inputs:"+operation));
        extra_outputs.append(gs.rules.get_strings("Outputs:"+operation));
      }
    }
  }
  
  JSONObject serialize() 
  {
    JSONObject o = super.serialize(); 
    o.setFloat("speed", base_speed);
    o.setBoolean("automatic", automatic);
    
    JSONArray a = new JSONArray();
    for (String op : operations)
      a.append(op);
    
    o.setJSONArray("operations", a);
    
    return o;
  }
}

class TrashCompactor extends Transformer
{  
  TrashCompactor(GridGameFlowBase game) { super(game); type = "TrashCompactor"; }
  Interaction first_matching_interaction(StringList ng_names)
  {
    if (ng_names.size() == 2)
      return new Interaction("", ng_names, new StringList(), 3f);//TODO: replace the time (3f) with a data point instead of hard coding
      
    return null;
  }
}

class ConveyorTransformer extends Transformer
{
  ConveyorComponent comp;
  ArrayList<NonGriddle> previous_outputs = new ArrayList<NonGriddle>();
  
  ConveyorTransformer(GridGameFlowBase game) { super(game); type = "ConveyorTransformer"; comp = new ConveyorComponent(game, this); }
  
  void update()
  {
    if (comp.ng == null && !start_conveying() && previous_outputs.isEmpty())
      super.update();
    
    comp.update();
  }
  
  
  boolean start_conveying()
  {
    //we have a lot of reasons not to do this. Like if we have no ngs, or if we have no previous interaction to look against to see if our ngs are outputs
    if (running || comp.ng != null || previous_outputs.isEmpty())
      return false;
    
    StringList neighbor_smartgrabber_ng_keys = new StringList();
    IntVec gridpos = game.grid.get_grid_pos_from_object(this);
    for (IntVec iv : orthogonal_offsets())
    {
      IntVec offset_pos = iv.copy().add(gridpos);
      Griddle neighbor = game.grid.get(offset_pos);
      
      if (neighbor instanceof SmartGrabberBelt)
      {
        SmartGrabberBelt sgb = (SmartGrabberBelt)neighbor;
        int qts = sgb.quarter_turns & 3;
        
        if (sgb.keyed_ng_type != null && sgb.keyed_ng_type.length() > 0 && ((qts == 0 && iv.x == 1) || (qts == 1 && iv.y == -1) || (qts == 2 && iv.x == -1) || (qts == 3 && iv.y == 1)))
          neighbor_smartgrabber_ng_keys.append(sgb.keyed_ng_type); //appendunique is more 'correct' but will only improve performance in an edge case that will basically never happen (two or more smart grabbers keyed to the same output pulling from the same ConveyorTransformer), while slightly worsening performance normally
      }
    }
    
    //check each nongriddle in reverse order
    for (int i = previous_outputs.size()-1; i >= 0; --i)
    {
      NonGriddle ng = previous_outputs.get(i);
      
      if (!neighbor_smartgrabber_ng_keys.hasValue(ng.name))
      {
        IntVec iv_offset = offset_from_quarter_turns(quarter_turns+3);
        IntVec xy = get_grid_pos().add(iv_offset);
        Griddle gg = game.grid.get(xy.x, xy.y);
        
        PVector start = center_center();
        PVector end = start.copy().add(iv_offset.toPVec().mult(dim.x));
		ng.pos = center_center();
        
        comp.start_conveying(gg, start, end, ng);
        
        return true;
      }
    }
    
    return false;
  }
  
  void remove_ng(NonGriddle ng) { super.remove_ng(ng); previous_outputs.remove(ng); if (ng == comp.ng) comp.ng = null; }
  
  void finish_transformation() { super.finish_transformation(); previous_outputs = new ArrayList<NonGriddle>(ngs); start_conveying(); }
  
  boolean can_accept_ng(NonGriddle n) { return comp.ng == null && previous_outputs.isEmpty() && super.can_accept_ng(n); }
  
  void deserialize(JSONObject o) { super.deserialize(o); comp.deserialize(o.getJSONObject("component"));  }
  JSONObject serialize() { JSONObject retval = super.serialize(); retval.setJSONObject("component", comp.serialize()); return retval; }
}
