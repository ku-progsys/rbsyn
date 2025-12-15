class CheckErrorPass < ::AST::Processor
  include TypeOperations
  require "set"
  attr_reader :errors, :dynamic_components

  def initialize(errs, successes)

    @type_errs = errs
    @type_successes = successes
    @errors = 0
    @dynamic_components = 0
    # temp = Set[]

    # @type_successes.each {|i|
      
      
    #   #for each method
    #   i[1].each {|j|
    #     #for each success in each method
    #     temp.add(j[:result])
    #   }
    # }
    # if temp.size > 1

    #   @dyn_returns = RDL::Type::UnionType.new(temp.to_a)
    # elsif temp.size == 1
    #   @dyn_returns = temp.to_a[0]
    # end

  end

  def update_reset(type_errs, type_successes)

    @type_errs = type_errs
    @type_successes = type_successes
    @errors = 0
    @dynamic_components = 0
    # temp = Set[]
    
    # @type_successes.each {|i|
    #   puts "type success: #{i}"
    #   #for each method
    #   i[1].each {|j|
    #     #for each success in each method
    #     temp.add(j[:result])
    #   }
    # }
    # puts "---------------\n\n"
    # if temp.size > 1

    #   @dyn_returns = RDL::Type::UnionType.new(temp.to_a)
    # elsif temp.size == 1
    #   @dyn_returns = temp.to_a[0]
    # end

  end


  def on_send(node)
    mth = node.children[1]
    trecv = process(node.children[0]) 
    if trecv.is_a?(RDL::Type::DynamicType)
      @dynamic_components += 1
    end
    return "error" if trecv.to_s == "error" #expecting a string for errors, for now

    targs = node.children[2 ..].map {|k|
      k.is_a?(TypedNode) ? process(k) : nil # this way of traversing will collect every error. 
      
    }
    return "error" if targs.map {|i| i.to_s}.include?("error")
    # return error if any of the children are in error (without incrementing the number of errors found)
    signature = {:recvr => trecv, 
      :args => targs,
      :method => mth}

    
    if @type_successes.keys.include?(mth) # pass for when method is a method of interest (successes is initalized with all moi)
      result = []
      @type_successes[mth].each {|i|
        if match_success(i, signature)
          #BR THIS IS WHERE YOU CAN GENERATE NEW PROGRAMS!!!
          #node.update_ttype(i[:result])  # uncomment if you would like the type to be updated with the emperical  types

          if i[:result].is_a?(RDL::Type::DynamicType)
            @dynamic_components += 1
          end
          return  i[:result]

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
        if tret.is_a?(RDL::Type::DynamicType)
          @dynamic_components += 1
        end
        #node.update_ttype(tret)  # uncomment if you would like the type to be updated with the emperical  types
        return tret
      rescue Exception => e
        return "error"
      end
    end
  end


  def handler_missing(node)

    if node.is_a?(TypedNode) && node.ttype.is_a?(RDL::Type::DynamicType)
      @dynamic_components += 1
    end


    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
    
    return node.ttype
  end


  def match_success(template, signature)

    
    if template[:args].size != signature[:args].size
      return false
    elsif !(signature[:recvr] <= template[:recvr])  # comment if you want it to be non-conservative in what it rejects
      # TODO clean comment and put in readme or experiemental log
      # we aren't using liskov, we are not trying to find out if an unknown function
      # is a subtype, we are trying to find out if a known function is being used 
      # as an instance of a known type. So if it is not a subtype it doesn't match
      return false
    end  

    # template[:args].zip(signature[:args]).each {|t,s|
    #   if !(s <= t) # again remove if you want it to reject potential candidates.
    #     return false
    #   end
    # }
    # return true
#     => 1610
#     [2] pry(#<Synthesizer>)> work_list.sum { |w| w.inferred_errors }
#     => 1183
    begin
      return !(template[:args].zip(signature[:args]).any? {|t,s| !left_intersection_subtype(t, s)})
    rescue Exception => e 
      binding.pry
    end
#     => 933
#     [2] pry(#<Synthesizer>)> work_list.size
#     => 1447
#     WEIRD! THESE SHOULDN'T BE LIKE THIS
    

  end

  def matches_err(template, signature)

    # match with any signatures which are a supertype of the template error
    #dyn = RDL::Type::DynamicType.new()

    # this might be a mistake as there might be variable size arguments. 
    if template[:args] == :ALL #this is where there is a method missing error
      if template[:recvr] == signature[:recvr]
        #puts "testing function on template: #{template}\n\n\nsignature: #{signature}\n\n"
        return true
      end
    end
    if template[:args].size != signature[:args].size
      # for now I can't think of how to handle a vararg
      return false
    end
    begin
      return !(([template[:recvr]] + template[:args]).zip(
        ([signature[:recvr]] + signature[:args])).any? {|t,s|

        # t <= s || left_intersection_subtype(t, s)  # same as above, uncomment second predicate if you want it to be overzealous
        !left_intersection_supertype(t, s)
        #   return false
        # end
        } )
      rescue Exception => e 
        binding.pry
      end

    #return true

  end

  def left_intersection_subtype(lower, upper)
    # if any of the types within a Union or \
    #otherwise on the left are a subtype of any of the types on the right Union or otherwise. 
    if upper.is_a?(RDL::Type::UnionType)

      u = upper.types
    else
      u = [upper]
    end

    if lower.is_a?(RDL::Type::UnionType)

      l = lower.types
    else 
      l = [lower]
    end

    return l.any? { |t_left| u.any? { |t_right| t_left <= t_right }}

  end

  def left_intersection_supertype(lower, upper)
    # if any of the types within a Union or \
    #otherwise on the left are a subtype of any of the types on the right Union or otherwise. 
    if upper.is_a?(RDL::Type::UnionType)

      u = upper.types
    else
      u = [upper]
    end

    if lower.is_a?(RDL::Type::UnionType)

      l = lower.types
    else 
      l = [lower]
    end

    return l.any? { |t_left| u.any? { |t_right| t_right <= t_left  }}

  end

  


end








#BR NOTE 1: # we may need to do successes first as we might want to prioritize exploration rather than pruning when we are dealing with 
        # cases where the restrictions conflict with the successes