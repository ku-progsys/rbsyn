class CheckErrorPass < ::AST::Processor
  include TypeOperations
  require "set"
  attr_reader :errors

  def initialize(errs, successes)

    @type_errs = errs
    @type_successes = successes
    @errors = 0
    temp = Set[]

    @type_successes.each {|i|
 
      #for each method
      i[1].each {|j|
        #for each success in each method
        temp.add(j[:result])
      }
    }
    if temp.size > 1

      @dyn_returns = RDL::Type::UnionType.new(temp.to_a)
    elsif temp.size == 1
      @dyn_returns = temp.to_a[0]
    end

  end

  def update_reset(type_errs, type_successes)

    @type_errs = type_errs
    @type_successes = type_successes
    @errors = 0
    temp = Set[]

    @type_successes.each {|i|
 
      #for each method
      i[1].each {|j|
        #for each success in each method
        temp.add(j[:result])
      }
    }
    if temp.size > 1
     
      @dyn_returns = RDL::Type::UnionType.new(temp.to_a)
    elsif temp.size == 1
      @dyn_returns = temp.to_a[0]
    end
  end


  def on_send(node)
    mth = node.children[1]
    trecv = process(node.children[0]) 
    return "error" if trecv.to_s == "error" #expecting a string for errors, for now

    targs = node.children[2 ..].map {|k|
      k.is_a?(TypedNode) ? process(k) : nil # this way of traversing will collect every error. 
      
    }
    return "error" if targs.map {|i| i.to_s}.include?("error")
    # return error if any of the children are in error (without incrementing the number of errors found)
    signature = {:receiver => trecv, 
      :args => targs,
      :method => mth}

    
    if @type_successes.keys.include?(mth) # pass for when method is a method of interest (successes is initalized with all moi)
      @type_successes[mth].each {|i|
        if match_success(i, signature)
          #node.update_ttype(i[:result])  # uncomment if you would like the type to be updated with the emperical  types
          return i[:result]
        end

      }
      
      @type_errs[mth].each {|i|
        # check if this matches any known errors since we have already tested sucesses we will agressively check for errors. 
        if matches_err(i, signature)  
          @errors += 1
          return "error"
        end

      }

      # try to infer the type to pass up the tree using previously seen sucesses
      # if neither error nor sucesses have been seen with this type return dynamic (this may hide bugs so inspect this carefuly)
      return RDL::Type::DynamicType.new() 
      
    else  # this is not a moi
      mthds = methods_of(trecv)
      info = mthds[mth]
      if info.nil?
        return "error" 
      end

      tmeth = info[:type]

      begin
        tret = compute_tout(trecv, tmeth, targs)
        #node.update_ttype(tret)  # uncomment if you would like the type to be updated with the emperical  types
        return tret
      rescue Exception => e
        return "error"
      end
    end
  end


  def handler_missing(node)

    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    return node.ttype
  end


  def match_success(template, signature)

    
    if template[:args].size != signature[:args].size
      return false
    elsif !(signature[:receiver] <= template[:receiver])  # comment if you want it to be non-conservative in what it rejects
      # TODO clean comment and put in readme or experiemental log
      # we aren't using liskov, we are not trying to find out if an unknown function
      # is a subtype, we are trying to find out if a known function is being used 
      # as an instance of a known type. So if it is not a subtype it doesn't match
      return false
    end  

    template[:args].zip(signature[:args]).each {|t,s|
      if !(s <= t) # again remove if you want it to reject potentail candidates.
        return false
      end
    }

    return true

  end

  def matches_err(template, signature)

    # match with any signatures which are a supertype of the template error
    #dyn = RDL::Type::DynamicType.new()

    # this might be a mistake as there might be variable size arguments. 
    if template[:args] == :ALL #this is where there is a method missing error
      if template[:receiver] == signature[:receiver]
        #puts "testing function on template: #{template}\n\n\nsignature: #{signature}\n\n"
        return true
      end
    end
    if template[:args].size != signature[:args].size
      # for now I can't think of how to handle a vararg
      return false
    end
    ([template[:receiver]] + template[:args]).zip(
      ([signature[:receiver]] + signature[:args])).each {|t,s|

      if !iterativesuper(t, s)  # same as above, uncomment second predicate if you want it to be overzealous
        return false
      end
      } 

    return true

  end

  def iterativesuper(lower, upper)
    # since our error type might have been a specific instance of a union type
    # we must check if our type is a supertype of any of the parts of a union.
    # this will recursively check as a union can technically have a sub-union (bad practice though.)
    if upper.is_a?(RDL::Type::UnionType)
      upper.types.each do |i|
        
        if iterativesuper(i, lower)
          return true
        end

      end
      return false
    end

    if lower.is_a?(RDL::Type::UnionType)
      lower.types.each do |i|
        
        if iterativesuper(upper, i)
          return true
        end
      end
      return false
    end

    return lower <= upper

  end

end




#BR NOTE 1: # we may need to do successes first as we might want to prioritize exploration rather than pruning when we are dealing with 
        # cases where the restrictions conflict with the successes