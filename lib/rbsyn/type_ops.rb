
module TypeOperations

  require_relative 'type_helper'

  def compute_targs(trec, tmeth, is_moi=false, peeknext: nil)
    # This is were you should allow it to use more than the first definition, ONLY
    # when it is an MOI. 
    # TODO: we use only the first definition, ignoring overloaded method definitions
    #puts ("from type_ops.rb compute_targs: trec #{trec}\n\n")
    #type = tmeth[0]
    if !is_moi
      targs = [tmeth[0].args]
      exp_tret = [tmeth[0].ret]
      param_matches = [index_of_var_in_ret(tmeth[0])]
    else
      targs = tmeth.map {|t| t.args }
      exp_tret = tmeth.map {|t| t.ret}
      param_matches = tmeth.map {|t| index_of_var_in_ret(t)}
    end
    # if targs.size > 1
    #   binding.pry
    # end
    return targs.map {|t| t.map { |targ| RDL::Type::DynamicType.new }} if ENV.key? 'DISABLE_TYPES'

    # handling multiple possible argument types for polymoprhism in the expected return. 

    accum = []
    targs.zip(exp_tret, param_matches).map {|argsig, retsig, parammatch|
      # t is the specific method signature we are on, among many
      # r is the expected return type
      accum << [[]]

      # add in a blank list for each enou method signature, (one list per method)
      argsig.zip(parammatch).map {|targ, param_index|
        
        # targ is the specific positional argument of the specific signature we are on
        case targ
          
        when RDL::Type::VarType
          # when the argument to be filled is a variable type
          # we use the signatures return argument to find a match_aheading typevar in the return signature 
          # and use that position to look and see if the expected return has a filled type in that position
          match_ahead = nil
          match_behind = nil

          if !(trec.is_a?(RDL::Type::GenericType) && trec.base == retsig.base) || param_index.nil?
            # we don't perfom Union Operation if Return base is not the same as Receiver Base
            match_behind = nil
          else
            match_behind = trec.params[param_index]
          end
          if peeknext.nil? || param_index.nil?
            # don't bother lookahead if the varaible in the formal doesn't match anything in the expected return, or if there is no concrete expected to match
            match_ahead = nil
          else
            match_ahead = peeknext.params[param_index]
          end
        

          if match_ahead.is_a?(RDL::Type::VarType) || match_ahead.nil?
            # case where the expected return is not concrete yet
            # or the match_ahead spuriously has nothing to do with generic (not likely)
            # we enumerate all possibilities (this could be made more elegant for better constraints)
            all_types = ParentsHelper.getParents
            temp_accum = []

            all_types.each do |conc|
              # for the k new concrete values which we can use to fill this formal_argument, clone the existing j arg lists k times and add each of the k args, gives j*k
              # new arg_lists
              conc = str_to_type(conc)
              accum[-1].each do |arglist|
                #binding.pry # THIS IS WHERE I AM TRYING TO CREATE THE UNION OPERATION

                if !match_behind.nil? && !(match_behind <= conc)
                  conc = RDL::Type::UnionType.new([conc, match_behind]) # this seems too simple there is probably a need for nesting consideration
                end

                dupe = arglist.clone << conc
                temp_accum << dupe
              end
            
            end
            accum[-1] = temp_accum

          else
            # case where there is a specific argument, so we can feel free to just add it to each possible copy of our current list need to add Unioning operation here too. 
            
            accum[-1].each do |i|
              # adding Union Operation
              if !match_behind.nil? && !(match_behind <= match_ahead)
                i << RDL::Type::UnionType.new([match_behind, match_ahead])
              else
                i << match_ahead
              end
            end
          end
        when RDL::Type::ComputedType
          bind = Class.new.class_eval { binding }
          bind.local_variable_set(:trec, trec)
          accum[-1].each do |i|
            i << targ.compute(bind)
          end

        else 
          accum[-1].each do |i|
            i << targ
          end
        end
      }
      
    }
    accum
  end

  def splitter(string)
    
    lst = []
    while string != ""
      flag = true
      index = -1
      while flag
        index = string.index(";", index + 1)
        if string[0 .. index].count("(") == string[0 .. index].count(")")
          lst << string[0 ... index]
          string = string[index + 1 ..]
          flag = false
        end
      end
    end
  end

  def type_to_string(tipe)
    if tipe.is_a?(String)
      return tipe
    end
    case tipe
    when RDL::Type::UnionType
      return "union(#{tipe.types.map {|i| type_to_string(i)}.join(";")})"
    when RDL::Type::NominalType
      return "#{tipe.name}"
    when RDL::Type::GenericType
      return "generic(#{type_to_string(tipe.base)};#{tipe.params.map {|i| type_to_string(i)}.join(";")})"
    when RDL::Type::VarType
      return "variable(#{tipe.name.to_s})"
    when RDL::Type::SingletonType
      raise StandardError "We shouldn't be converting singleton types to strings, that is not a reversible operation"
    else
      raise StandardError "No Type Found"
    end
  end

  def str_to_type(string)
    if !string.is_a?(String)
      return string
    end
    
    control = string[/\S+/]
    case control 
    when "union" 
      lst = splitter(string[5, -1])
      return RDL::Type::UnionType.new(lst.map {|i| str_to_type(i)})
    when "generic"
      lst = splitter(string[7, -1])
      RDL::Type::GenericType.new(str_to_type(lst[0]),lst[1 ..].map {|i| str_to_type(i)})
    when "variable"
      lst = splitter(string[8, -1])
      RDL::Type::VarType.new(lst[0].to_sym)
    when "DynamicType"
      return RDL::Type::DynamicType.new()
    else
      return RDL::Type::NominalType.new(string.strip())
    end
  end

  def index_of_var_in_ret(method)

    args = method.args
    ret = method.ret
    if !ret.is_a?(RDL::Type::GenericType)
      return [nil]*args.size
    end 
    params = ret.params
    args.map {|i| params.index(i)}
    
  end

  def compute_tout(trec, tmethod, targs)

    # TODO: we use only the first definition, ignoring overloaded method definitions
    # BR: Note: this might be where our problem of duplicates is happening. 
    # BR Here is where you need to give the overloaded method definitions. 
    
    tmethod.each do |t|

      begin
        if targs.zip(t.args).any? {|actual, prescribed| (!(str_to_type(actual) <= prescribed) && !prescribed.is_a?(RDL::Type::VarType)) }
          next
        end
      rescue Exception => e
        binding.pry
      end 

      #type = tmeth[0]
      return RDL::Type::DynamicType.new if ENV.key? 'DISABLE_TYPES'

      tret = t.ret
      
      case tret
      when RDL::Type::ComputedType
        bind = Class.new.class_eval { binding }
        bind.local_variable_set(:trec, trec)
        bind.local_variable_set(:targs, targs)
        return tret.compute(bind)
      
      when RDL::Type::DynamicType
        
        return RDL::Type::DynamicType.new()

      when RDL::Type::VarType
        if tret.name == :self
          return trec
        else

          params = RDL::Wrap.get_type_params(trec.base.to_s)[0]
          idx = params.index(tret.name)
          raise RbSynError, "unexpected" if idx.nil?
          return trec.params[idx]
        end
      when RDL::Type::GenericType
        # fill in to get generics fully up and running. 
        
      else
        return tret
      end
    end
  end

  def parents_of(trecv)
    #binding.pry

    case trecv
    when RDL::Type::SingletonType
      cls = trecv.val
      if cls.is_a? Class
        cls.ancestors.map { |klass| RDL::Util.add_singleton_marker(klass.to_s) }
      else
        raise RbSynError, "expected only true/false" unless (cls == true || cls == false || cls.nil? || cls.is_a?(Symbol))
        cls.class.ancestors.map { |klass| klass.to_s }
      end
    when RDL::Type::PreciseStringType
      String.ancestors.map { |klass| klass.to_s }
    when RDL::Type::UnionType
      trecv.types.map { |type| parents_of type }.flatten
    when RDL::Type::GenericType
      if trecv.base.name == 'ActiveRecord_Relation'
        parents_of(trecv.base) + parents_of(trecv.params[0])
      else
        parents_of trecv.base
      end
    when RDL::Type::OptionalType
      parents_of trecv.type
    when RDL::Type::NominalType
      
      RDL::Util.to_class(trecv.name).ancestors.map { |klass| klass.to_s }
    when RDL::Type::FiniteHashType
      Hash.ancestors.map { |klass| klass.to_s }
    when RDL::Type::BotType
      []
    when RDL::Type::DynamicType 

      ParentsHelper.getParents()
    else
      raise RbSynError, "unhandled type #{trecv.inspect}"

    end
  end

  def constructable?(targs, tenv, strict=false)
    bool = Proc.new { |targ| targ <= RDL::Globals.types[:bool] }
    targs.all? { |targ|
      case targ
      when RDL::Type::BotType, RDL::Type::TopType
        false
      when RDL::Type::FiniteHashType
        if strict
          targ.elts.values.all? { |v| constructable? [v], tenv, strict }
        else
          targ.elts.values.any? { |v| constructable? [v], tenv, strict }
        end
      when RDL::Type::OptionalType
        constructable? [targ.type], tenv, strict
      when RDL::Type::NominalType
        tenv.any? { |t| t <= targ }
      when RDL::Type::UnionType
        targ.types.any? { |t| constructable? [t], tenv, strict }
      when RDL::Type::SingletonType
        if [Symbol, TrueClass, FalseClass].include? targ.val.class
          true
        else
          raise RbSynError, "unhandled type #{targ.inspect}"
        end
      when bool
        true
      else
        raise RbSynError, "unhandled type #{targ.inspect}"
      end
    
  
    }
  end

  def types_from_tenv(tenv)
    tenv.values.to_set
  end


  def merge_methods(left, right)

    merged = Marshal.load(Marshal.dump(left))
    right[:type].zip(right[:effect]).map {|type, effect| 
      if !(merged[:type].any? {|t| t.args == type.args})
        merged[:type].append(type)
        merged[:effect].append(effect)
      end
    }
    merged
  end

  def methods_of(trecv)



    parents = parents_of(trecv)

      if ENV["ADD_DYN"] == "TRUE"
        parents.append("DynamicType") unless parents.include?("DynamicType")
      end
    # x = Hash[*parents.map { |klass|
        
    #     RDL::Globals.info.info[klass]
    #   }.reject(&:nil?).collect { |h| h.to_a }.flatten]
    #   
    
  
    x = parents.reduce({}) {|acc, klass| 
      methods = Marshal.load(Marshal.dump(RDL::Globals.info.info[klass]))
      if methods == nil
        acc
      else
        j = methods.reduce(acc) {|ac, (key, val)|
          if ac.has_key?(key)
            merged = merge_methods(ac[key], val)
            ac[key] =  merged
          else
            ac[key] = val
          end
          ac
        }
        acc = j
        acc
        
      end
    }
    

    
  end
end