import java.util.*; 

class Modifier
{
  String field;
  ModifierOperation op;
  float  float_value;
  int    int_value;
  String string_value;
  
  Modifier(String field, ModifierOperation op, String value) { this.field = field; this.op = op; float_value = parse_float(value, 0f); int_value = (int)float_value; string_value = value; }
  Modifier() { this("", ModifierOperation.NONE, ""); }
  Modifier(String to_parse)
  {
    this();
    String[] chunks = split_respecting_quoted_whitespace(to_parse);
    
    if (chunks.length >= 4 && (chunks[2].toLowerCase().equals("to") || chunks[2].toLowerCase().equals("from")))
    {
      switch (chunks[0].toLowerCase())
      {
        case "add": case "sum": case "+": op = ModifierOperation.ADD; break;
        case "subtract":  case "sub": case "-": op = ModifierOperation.SUBTRACT; break;
        case "set": op = ModifierOperation.SET; break;
        case "multiply": case "mult": case "*": op = ModifierOperation.MULTIPLY; break;
        case "divide": case "div": case "/": op = ModifierOperation.DIVIDE; break;
        default: op = ModifierOperation.NONE; println("Unknown rule modifier operator '" + chunks[0] + "'."); break;
      }
      
      string_value = chunks[1];
      float_value = parse_float(chunks[1],0f);
      int_value = (int)float_value;
      
      field = chunks[3];
    }
  }
  
  float get_float(float current_value)
  {
    switch (op)
    {
      case ADD:      return current_value + float_value;
      case SUBTRACT: return current_value - float_value;
      case SET:      return                 float_value;
      case MULTIPLY: return current_value * float_value;
      case DIVIDE:   return current_value / float_value;
      default:       return current_value;
    }
  }
  
  int get_int(int current_value)
  {
    switch (op)
    {
      case ADD:      return current_value + int_value;
      case SUBTRACT: return current_value - int_value;
      case SET:      return                 int_value;
      case MULTIPLY: return current_value * int_value;
      case DIVIDE:   return current_value / int_value;
      default:       return current_value;
    }
  }
  
  String get_string(String current_value)
  {
    if (current_value.length() == 0 || op == ModifierOperation.SET)
      return string_value;
    
    if (string_value.length() == 0)
      return current_value;
    
    return current_value + ", " + string_value;
  }
  
  float  get_float()  { return float_value;  }
  int    get_int()    { return int_value;    }
  String get_string() { return string_value; }
}

class Rule
{
  String name;
  String description;
  
  RuleType type;
  StringList dependencies;
  StringList tags;
  ArrayList<Modifier> mods;
  
  Rule(String name, String description, RuleType type, StringList dependencies, StringList tags)
  {
    this.description = description; 
    this.name = name; 
    this.type = type; 
    this.dependencies = new StringList(dependencies);
    this.tags = new StringList(tags);
    mods = new ArrayList<Modifier>();
  }

  Rule() { this("", "", RuleType.CURSE, new StringList(), new StringList()); }
  
  boolean is_locked(StringList rulenames) { for (String dep : dependencies) { if (!rulenames.hasValue(dep)) return true; } return false; }
  
  void deserialize(JSONObject o)
  {
    name = o.getString("name", "no name specified");
    description = o.getString("description", "no description specified");
    type = o.getString("type","curse").equals("boon") ? RuleType.BOON : RuleType.CURSE;
    tags = getStringList("tags", o);
    dependencies = getStringList("dependencies", o);
    
    mods = new ArrayList<Modifier>();
    StringList mods_as_strings = getStringList("mods", o);
    for (String m : mods_as_strings)
      mods.add(new Modifier(m));
  }
}


//maintains the active rules for a game session. Also has a separate mapping of all the rules' modifiers keyed by field they modify.
class RuleManager
{
  RuleList rules = new RuleList();
  HashMap<String, ArrayList<Modifier>> mods = new HashMap<String, ArrayList<Modifier>>();
  
  void put(Rule r)
  {
    rules.add(r);
    
    for (Modifier m : r.mods)
    {
      if (!mods.containsKey(m.field))
        mods.put(m.field, new ArrayList<Modifier>());
      
      mods.get(m.field).add(m);
    }
  }
  
  void put(RuleList rl)
  {
    for (int i = 0; i < rl.size(); ++i)
      put(rl.get(i));
  }
  
  float get_float(String field, float current_value)
  {
    float retval = current_value;
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval = ms.get(i).get_float(retval);
    }
    
    return retval;
  }
  
  int get_int(String field, int current_value)
  {
    int retval = current_value;
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval = ms.get(i).get_int(retval);
    }
    
    return retval;
  }
  
  StringList get_strings(String field)
  {
    StringList retval = new StringList();
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval.appendUnique(ms.get(i).get_string());
    }
    
    return retval;
  }
  
  float  get_float (String field) { return get_float (field,0f); }
  int    get_int   (String field) { return get_int   (field,0 ); }
  String get_string(String field) { return get_strings(field).join(", "); }
  
  StringList get_rule_names() { return rules.names(); }
  RuleList   get_rules()      { return rules.clone(); }
  
  RuleList get_available_curses()
  {
    RuleList retval = globals.ruleFactory.get_all_curses();
    
    retval.remove_all(rules);
    
    for (int i = 0; i < retval.size(); ++i)
    {
      if (retval.get(i).is_locked(rules.names()))
      {
        retval.remove(i);
        --i;
      }
    }
    
    return retval;
  }
  
  RuleList get_available_boons()
  {
    RuleList retval = globals.ruleFactory.get_all_boons();
    
    retval.remove_all(rules);
    
    for (int i = 0; i < retval.size(); ++i)
    {
      if (retval.get(i).is_locked(rules.names()))
      {
        retval.remove(i);
        --i;
      }
    }
    
    return retval;
  }
}

class RuleList
{
  private ArrayList<Rule> rules;
  
  RuleList() { rules = new ArrayList<Rule>(); }
  
  RuleList(ArrayList<Rule> rules) { this.rules = rules; }
  
  RuleList(RuleList rhs) { this(); add_all(rhs); }
  
  StringList names() { StringList retval = new StringList(); for (int i = 0; i < rules.size(); ++i) retval.append(rules.get(i).name); return retval; }
  
  RuleList copy() { return new RuleList(this); }
  RuleList clone() { return copy(); }
  
  Rule get(int i) { if (i < 0 || i >= rules.size()) return null; return rules.get(i); }
  
  Rule get_random() { int r = (int)random(0, rules.size()); return rules.get(r); }
  
  RuleList shuffle() { Collections.shuffle(rules); return this; }
  
  RuleList top(int num) { if (num < rules.size()) rules.subList(num, rules.size()).clear(); return this; }
  
  int size() { return rules.size(); }
  
  RuleList add(Rule rule) { rules.add(rule); return this; }
  RuleList remove(Rule rule) { rules.remove(rule); return this; }
  RuleList remove(int i) { if (i >= 0 && i < rules.size()) rules.remove(i); return this; }
  
  RuleList filter_by_all_tags(StringList tags)
  {
    for (int i = 0; i < rules.size(); ++i)
    {
      StringList this_rules_tags = rules.get(i).tags;
      
      for (String tag : tags)
      {
        if (!this_rules_tags.hasValue(tag))
        {
          rules.remove(i);
          --i;
          break;
        }
      }
    }
    
    return this;
  }
  
  RuleList filter_by_all_tags(String... tags) { return filter_by_all_tags(new StringList(tags)); }
  
  RuleList filter_by_any_tag(StringList tags)
  {
    for (int i = 0; i < rules.size(); ++i)
    {
      StringList this_rules_tags = rules.get(i).tags;
      
      boolean found_one = false;
      for (String tag : tags)
      {
        if (this_rules_tags.hasValue(tag))
        {
          found_one = true;
          break;
        }
      }
      
      if (!found_one)
      {
        rules.remove(i);
        --i;
      }
    }
    
    return this;
  }
  
  RuleList filter_by_any_tag(String... tags) { return filter_by_any_tag(new StringList(tags)); }
  
  RuleList filter_by_tag(String tag) { return filter_by_all_tags(tag); }
  
  RuleList filter_out_tags(StringList tags)
  {
    for (int i = 0; i < rules.size(); ++i)
    {
      StringList this_rules_tags = rules.get(i).tags;
      
      for (String tag : tags)
      {
        if (this_rules_tags.hasValue(tag))
        {
          rules.remove(i);
          --i;
          break;
        }
      }
    }
    
    return this;
  }
  
  RuleList clear() { rules.clear(); return this; }
  
  RuleList filter_out_tags(String... tags)
  {
    return filter_out_tags(new StringList(tags));
  }
  
  RuleList filter_out_tag(String tag) { return filter_out_tags(tag); }
  
  RuleList filter_just_curses() { RuleList retval = copy(); for (int i = rules.size(); i >= 0; --i) { if (rules.get(i).type == RuleType.BOON ) retval.remove(i); } return retval; }
  RuleList filter_just_boons()  { RuleList retval = copy(); for (int i = rules.size(); i >= 0; --i) { if (rules.get(i).type == RuleType.CURSE) retval.remove(i); } return retval; }
  
  RuleList remove_all(RuleList rhs) { rules.removeAll(rhs.rules); return this; }
  RuleList add_all(RuleList rhs) { rules.addAll(rhs.rules); return this; }
  
  RuleList remove_all(StringList rhs_names) {  for (int i = 0; i < rules.size(); ++i) { if (rhs_names.hasValue(rules.get(i).name)) { rules.remove(i); --i; } } return this; }
  RuleList add_all(StringList rhs_names) { for (String s : rhs_names) rules.add(globals.ruleFactory.get_rule(s)); return this; }
}

class RuleFactory
{
  private HashMap<String, Rule> rules = new HashMap<String, Rule>();
  private RuleList all_curses;
  private RuleList all_boons;
  
  void load(String filepath)
  {
    rules = new HashMap<String, Rule>();
    all_curses = new RuleList();
    all_boons = new RuleList();
    
    JSONArray list = loadJSONArray(filepath);
    
    for (int i = 0; i < list.size(); ++i)
    {
      JSONObject lojo = list.getJSONObject(i);
      
      if (lojo.getBoolean("disabled",false))
        continue;
      
      Rule rr = new Rule();
      
      rr.deserialize(lojo);
      rules.put(rr.name, rr);
      
      if (rr.type == RuleType.CURSE)
        all_curses.add(rr);
      else
        all_boons.add(rr);
    }
  }
  
  Rule get_rule(String name) { return rules.get(name); }
  
  RuleList get_all_curses() { return all_curses.copy(); }
  RuleList get_all_boons()  { return all_boons.copy();  }
  
  StringList get_tags(String name) { return new StringList(get_rule(name).tags); }
}


enum ModifierOperation
{
  ADD,
  SUBTRACT,
  SET,
  MULTIPLY,
  DIVIDE,
  NONE
}

enum RuleType
{
  CURSE,
  BOON
}
