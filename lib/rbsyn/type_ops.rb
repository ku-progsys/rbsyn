
module TypeOperations

  require_relative 'type_helper'

  def compute_targs(trec, tmeth, is_moi=false)
    # This is were you should allow it to use more than the first definition, ONLY
    # when it is an MOI. 
    # TODO: we use only the first definition, ignoring overloaded method definitions
    #puts ("from type_ops.rb compute_targs: trec #{trec}\n\n")
    #type = tmeth[0]
    if !is_moi
      targs = [tmeth[0].args]
    else
      targs = tmeth.map {|t| t.args }
    end
    # if targs.size > 1
    #   binding.pry
    # end
    return targs.map {|t| t.map { |targ| RDL::Type::DynamicType.new }} if ENV.key? 'DISABLE_TYPES'

    targs.map {|t| 
      t.map { |targ|
        case targ
        when RDL::Type::ComputedType
          bind = Class.new.class_eval { binding }
          bind.local_variable_set(:trec, trec)
          targ.compute(bind)
        else
          targ
        end
      }
    }

  end

  def compute_tout(trec, tmethod, targs)

    # TODO: we use only the first definition, ignoring overloaded method definitions
    # BR Here is where you need to give the overloaded method definitions. 
    
    tmethod.each do |t|

      if targs.zip(t.args).any? {|actual, prescribed| !(actual <= prescribed)}
        next
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