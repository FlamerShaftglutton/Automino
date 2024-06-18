class GriddleFactory
{
  HashMap<String, JSONObject> templates;
  
  void load(String json_file)
  {
    templates = new HashMap<String, JSONObject>();
    
    JSONArray root = loadJSONArray(json_file);
    
    for (int i = 0; i < root.size(); ++i)
    {
      JSONObject o = root.getJSONObject(i);
      
      String template_name = "";
      
      if (o.hasKey("_template"))
        template_name = o.getString("_template");
      else if (o.hasKey("type"))
        template_name = o.getString("type");
      
      if (template_name.equals(""))
      {
        println("Griddle template found with no _template or type specified. Loading of this griddle has been skipped.");
        continue;
      }
      
      templates.put(template_name, o);
    }
  }
  Griddle create_griddle(String name, GridGameFlowBase game) { return create_griddle(name, new JSONObject(), game); }
  Griddle create_griddle(String name, JSONObject overwrite, GridGameFlowBase game) 
  { 
    if (templates.containsKey(name)) 
      return create_griddle(templates.get(name),overwrite, game); 
    
    return create_griddle(overwrite, game);
  }
  
  Griddle create_griddle(JSONObject base, JSONObject over, GridGameFlowBase game) { return create_griddle(merge_JSONObjects(base, over), game); }
  
  Griddle create_griddle(JSONObject template, GridGameFlowBase game)
  { 
    Griddle g;
    String type = template.getString("type","NullGriddle");
    switch (type)
    {
      case "Player": case "PlayerGriddle": g = new PlayerGriddle(game);              break;
      case "ConveyorBelt":                 g = new ConveyorBelt(game);               break;
      case "ResourcePool":                 g = new ResourcePool(game);               break;
      case "NullGriddle":                  g = new NullGriddle(game);                break;
      case "EmptyGriddle":                 g = new EmptyGriddle(game);               break;
      case "Griddle":                      g = new Griddle(game);                    break;
      case "Transformer":                  g = new Transformer(game);                break;
      case "GrabberBelt":                  g = new GrabberBelt(game);                break;
      case "SmartGrabberBelt":             g = new SmartGrabberBelt(game);           break;
      case "SwitchGrabberBelt":            g = new SwitchGrabberBelt(game);          break;
      case "MetaActionCounter":            g = new MetaActionCounter(game);          break;
      case "LevelEditorGriddle":           g = new LevelEditorGriddle(game);         break;
      case "CountingOutputResourcePool":   g = new CountingOutputResourcePool(game); break;
      case "RandomResourcePool":           g = new RandomResourcePool(game);         break;
      case "TrashCompactor":               g = new TrashCompactor(game);             break;
      case "ConveyorTransformer":          g = new ConveyorTransformer(game);        break;
      case "CrossConveyorBelt":            g = new CrossConveyorBelt(game);          break;
      case "WallGriddle":                  g = new WallGriddle(game);                break;
      default:                             g = new NullGriddle(game);                break;
    }
    
    
    g.deserialize(template);
    
    return g;
  }
  
  JSONObject get_template(String name) { if (!templates.containsKey(name)) return new JSONObject(); return templates.get(name); }
  
  String get_string(String griddle_name, String field_name) { return get_template(griddle_name).getString(field_name,""); }
  
  StringList get_strings(String griddle_name, String field_name) { return getStringList(field_name, templates.get(griddle_name)); }
  
  String get_spritename(String name) { return get_template(name).getString("sprite",""); }
  
  String get_description(String name) { return get_template(name).getString("description",""); }
  
  StringList get_tags(String name) { return getStringList("tags", get_template(name)); }
  
  StringList get_names_by_tag(String tag) { StringList retval = all_template_names(); for (int i = 0; i < retval.size(); ++i) { if (!get_tags(retval.get(i)).hasValue(tag)) { retval.remove(i); --i; } } return retval; }
  
  StringList get_upgrades(String name) { return getStringList("upgrades", get_template(name)); }
  
  StringList get_operations(String name) { return getStringList("operations", get_template(name)); }
  
  StringList all_template_names() { return new StringList(templates.keySet()); }
  
  HashMap<String, StringList> all_upgrades() { HashMap<String, StringList> retval = new HashMap<String, StringList>(); for (String k : templates.keySet()) retval.put(k, get_upgrades(k)); return retval; }

  StringList all_reward_names() { StringList retval = new StringList(); for (String k : templates.keySet()) { if (get_tags(k).hasValue("reward")) retval.append(k); } return retval; }
}

JSONObject merge_JSONObjects(JSONObject base, JSONObject over)
{
  //clone our base
  JSONObject template = JSONObject.parse(base.toString());
  
  //for each field in the overwriter replace the field in the template
  for (Object field : over.keys())
    template.put(field.toString(), over.get(field.toString()));
    
  //replace the type to make sure it's the fully derived type, not the template name
  template.setString("type", base.getString("type"));
  
  return template;
}
