# Problems and my workings

## Resources

- the method RDL.note_type e will display the type of e during type checking.



## Next steps

You don't yet have a means of resolving conflicts between types that have both passed and not, this should be done by preventing a type failure from being entered onto the err list that is already on the correct list. 

You also have the option to look up how many arguments each function takes from Ruby itself, this would allow for greatly generalized behavior, at least for when we are constructing from a known receiver. This would be implemented in the construction process itself.  

You also don't have the type merging system general enough you need to merge types that have the same parent class and don't have conflicting bad-types. This might
also involve a poset so fun!

You also shoud consider using RDL itself to encode the type signatures, this would be much faster than what you have. 

You should also consider using the error messages directly from AST, this would have the benefit of being easier, and you could just use :name, :args, and :reciever, to 
capture the information you want. This would be much faster than what you have, it might not be as granular as you would like though???


## Current Limitations

Currently anything that requires a hash won't work, and that is because it doesn't know the keys to use

perahps we can use something like this: 

      receiver.attribute_names.each do |i|
        puts i
      end
      puts "\n\n\n\n"


we might also try scanning through instance_variables, and recursively looking for strings and constants. 


Notes: 
to me it seems that we might be able to send a first class object in place of a key through funcitons that aren't c-calls .
This would require the object to be hashable.

then we could use module redefinitions to make sure that any time the object was called across some known data structure we record what that structure is 
and what it's keys are. 


## LLM Solution:

It might be possible to give an slm as much information as we can regarding the function being called and ask it to generate key name candidates, here 
is a potential script we might use, along with some tests I did with chatGPT. 

### RESET CONTEXT
You are a keyword‐argument name suggester. 
Your job is to read the JSON input below, then output as many candidate keys as you can, up to [max_suggestions], for the 
call, described in the json as "method_name" which is being called by "class_name". Order results from top (most likely) to bottom 
(least likely), shorter strings will be more likely, more relevant string will be more likely, short and relevant strings will be most likely. Respond _only_ with a JSON array of strings.

### EXAMPLE INPUT 1

Input:
{
  "class_name": "UserService",
  "method_name": "find_user",
  "parent_classes": ["BaseService"],
  "sibling_methods": ["create_user", "delete_user"],
  "child_classes": [],
  "max_suggestions": 5
}

### EXAMPLE OUTPUT 1

Output:
[
  "user",
  "id",
  "user_id",
  "email",
  "limit",  
]

### EXAMPLE INPUT 2

Input:
{
  "class_name": "EmailBuilder",
  "method_name": "send",
  "parent_classes": ["Notifier"],
  "sibling_methods": ["schedule", "render_template"],
  "child_classes": ["TransactionalEmail", "MarketingEmail"],
  "max_suggestions": 6
}

### EXAMPLE OUTPUT 2

Output:
[
  "from",
  "to",
  "subject",
  "body",
  "cc",
  "attachments"
]


### YOUR TASK
Read the following `INPUT JSON` section.  
Produce a JSON array of strings with length ≥ `min_suggestions` and ≤ `max_suggestions`.  
Order entries most→least likely.  
Do not output any extra text.

### INPUT JSON
{{}}




### TESTING RESULTS: 


INPUTS 

{{ "class_name": "State", "method_name": "addParent", "parent_classes": [], "sibling_methods": ["addChildren", "addNode", "__gt__", "__lt__"], "child_classes": [], "max_suggestions": 6}}

OUTPUTS

[ "parent", "parent_state", "state", "parent_id", "state_id", "id" ]


INPUTS


OUTPUTS
