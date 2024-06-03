class Transformer extends Griddle
{
  StringList operations = new StringList();
  boolean running = false;
  float time_used = 0f;
  Interaction current_interaction;
  boolean automatic = false;
  float speed = 0.01f;
  
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
        time_used += speed;
      
      if (time_used >= current_interaction.time)
        finish_transformation();
    }
    
    super.update();
  }
  
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
    for (String output_ng_name : current_interaction.output_ngs)
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
        time_used += speed;
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
    
    speed = o.getFloat("speed", 0.01f);
    automatic = o.getBoolean("automatic", false);
    
    if (o.hasKey("operations"))
    {
      JSONArray a = o.getJSONArray("operations");
      
      if (a != null)
      {
        for (int i = 0; i < a.size(); ++i)
          operations.append(a.getString(i));
      }
    }
    else
      operations.append(o.getString("operation", ""));
  }
  
  JSONObject serialize() 
  {
    JSONObject o = super.serialize(); 
    o.setFloat("speed", speed);
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
  float movement_progress = 0f;
  boolean conveying = false;
  NonGriddle conveying_ng = null;
  Interaction previous_interaction = null;
  
  ConveyorTransformer(GridGameFlowBase game) { super(game); type = "ConveyorTransformer"; }
  
  void update()
  {
    if (conveying_ng == null && conveying)
    {
      conveying = false;
      movement_progress = 0f;
    }
    
    if (conveying || start_conveying())
    {
      movement_progress += 0.04;//0.015f;
      IntVec iv_offset = offset_from_quarter_turns(quarter_turns+3);
      IntVec xy = game.grid.get_grid_pos_from_object(this).add(iv_offset);
      
      if (movement_progress < 1f)
      {
        if (movement_progress > 0.5f)
        {
          //stop half-way if the next thing can't take this yet (unless it's another conveyor belt)
          Griddle gg = game.grid.get(xy.x, xy.y);
          
          if (!gg.can_accept_ng(conveying_ng))//(!(gg instanceof ConveyorBelt) && !gg.can_accept_ng(ng))
            movement_progress = 0.5f;
        }
        
        PVector start = center_center();
        PVector end = iv_offset.toPVec().mult(dim.x).add(start);
        
        conveying_ng.pos = PVector.lerp(start,end,movement_progress);
      }
      else
      {
        //find the neighboring griddle and try to pass this off
        if (game.grid.get(xy.x,xy.y).receive_ng(conveying_ng))
          remove_ng(conveying_ng);
        else
          movement_progress = 1f;
      }
    }
    else
    {
      super.update();
    }
  }
  
  boolean start_conveying()
  {
    //we have a lot of reasons not to do this. Like if we have no ngs, or if we have no previous interaction to look against to see if our ngs are outputs
    if (conveying || ngs.isEmpty())
      return false;
    
    if (previous_interaction == null && current_interaction != null)
      previous_interaction = current_interaction.copy();
    
    if (previous_interaction == null)
      return false;
    
    StringList interaction_outputs = previous_interaction.output_ngs.copy();
    StringList neighbor_smartgrabber_ng_keys = new StringList();
    for (IntVec iv : adjacent_offsets())
    {
      Griddle neighbor = game.grid.get(iv.add(game.grid.get_grid_pos_from_object(this)));
      
      if (neighbor instanceof SmartGrabberBelt)
      {
        SmartGrabberBelt sgb = (SmartGrabberBelt)neighbor;
        
        if (sgb.keyed_ng_type != null && sgb.keyed_ng_type.length() > 0)
          neighbor_smartgrabber_ng_keys.append(sgb.keyed_ng_type); //appendunique is more 'correct' but will only improve performance in an edge case that will basically never happen (two or more smart grabbers keyed to the same output pulling from the same ConveyorTransformer), while slightly worsening performance normally
      }
    }
    
    //check each nongriddle in reverse order
    for (int i = ngs.size()-1; i >= 0; --i)
    {
      NonGriddle ng = ngs.get(i);
      
      if (interaction_outputs.hasValue(ng.name) && !neighbor_smartgrabber_ng_keys.hasValue(ng.name))
      {
        conveying = true;
        movement_progress = 0f;
        conveying_ng = ng;
        return true;
      }
    }
    
    return false;
  }
  
  void remove_ng(NonGriddle ng) { if(ng == conveying_ng) { conveying = false; movement_progress = 0f; conveying_ng = null; } super.remove_ng(ng); }
  
  void finish_transformation() { previous_interaction = current_interaction.copy(); start_conveying(); super.finish_transformation(); }
  
  boolean can_accept_ng(NonGriddle n) { return !conveying && super.can_accept_ng(n); }
}
