Last I left off I created something to delete duplicates in the creation step and in the expansion step, it doesn't eliminate them 
from the worklist, which will reduce sort time, but it at least shouldn't expand upon those, discarding them instead. 

I learned that the types that I have been using for the fully typed system may be overspecified and that I might need to change
the specifications to get a more accurate type spec.  

I also learned that Arrays and List Like objects are not really capturing the type info about the lists Array\<Thing\>,  WELL I didn't really learn that so much as I am learning how limiting this is. 

### Current
I might be able to get the fully typed version working again if I make the Arrays have the type Array\<K\> method args\<J\> -> Array\<Union[K, J]\>. 

Steps

- I am currently updating RbSyn to handle dependent types with a type variable included, *** this might be an issue for the type system as my variation uses NominalTypes for most everything. ***  


I have set it up so that the system can use generics, but there are 2 parts of that missing. 
1. The generics are not yet set up to handle union types in the parameters. At the very least, with arrays this is possible, we can mkae claim that an Array not yet declared generic, the type will become whatever is put in it. Then we might assume that any method which invokes the type param in the argument might be able to alter the 
type param in the result. 
From this we might be able to look up the type of the param in the reciever (we can easily circumvent the limitations of the sytem since we are constructing not checking) and union it with the param in the output, if not already part of the union. This is tricky though::!! because we are synthesizing not checking, we need to go for variant, NOT contravariant leq operation (IE Type1 <= Union[Type1, Type2]) because we want to search for the more specific program. 

BIG CAVIOT, THIS ONLY WORKS WHEN THE INPUT AND OUTPUT TYPE ARE GENERICS WITH THE SAME BASE. AND IT MIGHT END UP BITING YOU BACK SO MAKE SURE IT CAN BE DISABLED

2. I currently have the reachability function in paths to type replacing the final element in the chain with the target type, but none of the intermediate elements. ex
A<t> -> A<t> -> A<concrete>. Since at each point in the system it can replace <t> with all possible types, we can make several chains and use the Union operation described above to eliminate overly gerneral types. EX << will definitely cause a union, so, we can see that any A<t> -> A<t,j> might be overly general.


3. I have gottent the string to type function created. This is implemented in the 
get_args funciton in type_ops ***DONE***

4. My system currently doesn't correctly calculate the output type. I am working on that now.

5. I really need to update the reachability function so that the paths correctly update. 

### End Current

Next I might have a way to check types for type errors but I don't think I have created a means of updating type signatures in the presence of new information. 

- Do that next


Finally I realized something that might be worth checking into 

With Hamster::Cons_1
we have a list and then we have method 
```ruby
Cons_1.take/drop arg -> LazyList_1
```

so with args like False Array IE 
```ruby
x = Hamster::Cons_1[items].take(Array[2,3,4])
```

it won't throw an error but 

when we do 

```ruby
x[2]
```

it will throw an ArgumentError because the argument to take needs to be compatable with the <= operator. 

Right now our example problem isn't using any [] operator definition. 

Even if it did we would see a situation where both

```ruby
LazyList_1::thing.take[NonInt][2] 
LazyList_1::thing.take[Int][2] 
```
give us an argument error and non-argument error resp. 
BUT! consider that this means that we have a situation where our current system will say that LazyList_1 [Int] is both well typed and 
unwell typed. 

I believe that we can resolve this by carrying more information in our types, close to dependent types. It would have to see that LazyList.take[NonInt][Int] is an error but LazyList.take[Int][Int] isnt an error. 

So we really need a way to extend the type system to include information about prior method calls in certain cases. 

But this also indicates something interesting, that including useless function might be able to yeild info about what does and doesn't work. I think of this as being something like a keystone behavior, methods that must always work, this would be information that the user KNOWS and supplies and if anything we generate doesn't work with this method we know that it MUST be an error type that should be discarded. 


