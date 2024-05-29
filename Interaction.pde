class InteractionFactory
{
  HashMap<InteractionKey, Interaction> interactions;
  
  void load(String json_file)
  {
    interactions = new HashMap<InteractionKey, Interaction>();
    
    JSONArray root = loadJSONArray(json_file);
    
    for (int i = 0; i < root.size(); ++i)
    {
      JSONObject oo = root.getJSONObject(i);
      
      if (!oo.hasKey("operation"))
      {
        println("Interaction defined without operation'. Skipping interaction.");
        continue;
      }
      
      if (!oo.hasKey("input"))
      {
        println("Interaction defined without inputs. Skipping interaction.");
        continue;
      }
      
      if (!oo.hasKey("output"))
      {
        println("Interaction defined without outputs. Full line is '" + oo.toString() + "'. Skipping interaction.");
        continue;
      }
      
      if (!oo.hasKey("time"))
      {
        println("Interaction defined without time. Skipping interaction.");
        continue;
      }
      
      String operation = oo.getString("operation");
      float time = oo.getFloat("time");
      
      Object input_o = oo.get("input");
      StringList inputs = new StringList();
      
      if (input_o instanceof JSONArray)
      {
        JSONArray input_a = (JSONArray)input_o;
        for (int ii = 0; ii < input_a.size(); ++ii)
          inputs.append(input_a.getString(ii));
      }
      else
        inputs.append((String)input_o);
        
      
      Object output_o = oo.get("output");
      StringList outputs = new StringList();
      
      if (output_o instanceof JSONArray)
      {
        JSONArray output_a = (JSONArray)output_o;
        for (int ii = 0; ii < output_a.size(); ++ii)
          outputs.append(output_a.getString(ii));
      }
      else
        outputs.append((String)output_o);
        
      
      Interaction interaction = new Interaction();
      interaction.operation = operation;
      interaction.input_ngs = inputs;
      interaction.output_ngs = outputs;
      interaction.time = time;
      
      interactions.put(new InteractionKey(operation, inputs), interaction);
    }
  }
  
  
  Interaction get_interaction(String operation, String ng_name) { StringList s = new StringList(); s.append(ng_name); return get_interaction(operation, s); }
  boolean interaction_exists(String operation, String ng_name) { StringList s = new StringList(); s.append(ng_name); return interaction_exists(operation,s); }
  
  Interaction get_interaction(String operation, StringList ng_names) { return interactions.get(new InteractionKey(operation,ng_names)).copy(); }
  boolean interaction_exists(String operation, StringList ng_names) { return interactions.containsKey(new InteractionKey(operation,ng_names)); }
}

class Interaction
{
  String operation;
  StringList input_ngs;
  StringList output_ngs;
  float  time;
  
  Interaction() { operation = ""; input_ngs = new StringList(); output_ngs = new StringList(); time = 0f; }
  Interaction(String operation, StringList input_ngs, StringList output_ngs, float time) { this.operation = operation; this.input_ngs = input_ngs.copy(); this.output_ngs = output_ngs.copy(); this.time = time; }
  Interaction clone() { Interaction i = new Interaction(); i.operation = operation; i.input_ngs = input_ngs.copy(); i.output_ngs = output_ngs.copy(); i.time = time; return i; }
  Interaction copy() { return clone(); }
}

class InteractionKey
{
  String operation;
  StringList input_ngs;
  
  InteractionKey(String operation, StringList input_ngs) { this.operation = operation; this.input_ngs = input_ngs.copy(); }
  InteractionKey clone() { return new InteractionKey(operation, input_ngs.copy()); }
  InteractionKey copy() { return clone(); }
  
  @Override
  public int hashCode()
  {
      return operation.hashCode() + input_ngs.toString().hashCode();
  }
  
  @Override
  public boolean equals(Object o)
  {
      return (o instanceof InteractionKey) && operation.equals(((InteractionKey)o).operation) && input_ngs.toString().equals(((InteractionKey)o).input_ngs.toString());
  }
}
