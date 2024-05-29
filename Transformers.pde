class Transformer extends Griddle
{
  StringList operations = new StringList();
  boolean running = false;
  float time_used = 0f;
  Interaction current_interaction;
  boolean automatic = false;
  float speed = 0.01f;
  
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
  
  void finish_transformation()
  {
    running = false;
    
    //destroy all inputs
    for (NonGriddle ng : ngs)
      globals.destroy_ng(ng);
    
    ngs.clear();
    
    //create the outputs
    for (String output_ng_name : current_interaction.output_ngs)
    {
      NonGriddle ng2 = globals.create_and_register_ng(output_ng_name);
      
      if (!receive_ng(ng2))
        println("Something went wrong in Transformer. New ng created but could not be stored. Old ng is already dead.");
    }
    
    time_used = 0f;
    
    current_interaction = first_matching_interaction(ngs);
    
    running = current_interaction != null;
  }
  
  void player_interact(Player player)
  {  
    if (!automatic)
    {
      if (running)
        time_used += speed;
      else
      {
        current_interaction = first_matching_interaction(ngs);
        
        running = current_interaction != null;
      }
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
  
  Interaction first_matching_interaction(ArrayList<NonGriddle> ngs)
  {
    StringList sl = new StringList();
    for (int i = 0; i < ngs.size(); ++i)
      sl.push(ngs.get(i).name);
    
    return first_matching_interaction(sl);
  }
  
  
  boolean can_accept_ng(NonGriddle n)
  {
    return super.can_accept_ng(n) && !running;
    
    /*
    //the first thing is always accepted
    if (ngs.isEmpty())
      return true;
    
    //the second thing will only be accepted if there is a matching interaction using the first thing
    StringList sl = new StringList();
    for (int i = 0; i < ngs.size(); ++i)
      sl.push(ngs.get(i).name);

    sl.push(n.name);
    
    return first_matching_interaction(sl) != null;
    */
  }
  
  
  boolean receive_ng(NonGriddle ng) 
  { 
    if (!can_accept_ng(ng) || !super.receive_ng(ng))
      return false; 
    
    current_interaction = first_matching_interaction(ngs);
    
    if (current_interaction != null && automatic)
    {
      running = true;
      time_used = 0f;
    }
  
    return true; 
  }
  
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
    o.setString("type", "Transformer");
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
  Interaction first_matching_interaction(StringList ng_names)
  {
    if (ng_names.size() >= 2)
      return new Interaction("", ng_names, new StringList(), 3f);//TODO: replace the time (3f) with a data point instead of hard coding
      
    return null;
  }
  
  JSONObject serialize() { JSONObject o = super.serialize(); o.setString("type", "TrashCompactor"); return o; }
}
