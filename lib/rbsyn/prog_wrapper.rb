class ProgWrapper
  include AST
  require_relative "ast/check_error_pass"
  # require_relative "ast/refine_type_pass_v2"  # AI altered: DynamicRefineTypes merged into RefineTypesV2
  require_relative "ast/refine_types_v2" # AI generated
  require_relative "ast/ttype_print"
  require_relative "./complex_error"

  attr_reader :seed, :env, :exprs, :looking_for, :target, :inferred_errors, :exprs
  attr_accessor :passed_asserts, :inferred_errors, :ctx, :env, :ttype, :dynamic_components, :typehash, :typestring

  def remove_duplicates(list)
    counts = {}
    list.each do |item| 
      counts[item.typehash] = item
      # AI note: tried structure_hash here (2026-10-09) and reverted. Siblings from one expansion often share code but
      # differ in node types (one per signature, hash-key variants last); keeping only the last one steered later
      # expansions down the hash-variant path (28 setter signatures learned, getters never reached). The structure
      # key is used only for the work-list check in SynHelper#dedupe_key.
    end
    counts.values
  end

  def get_variance
    temp = @seed
    if temp.type == :envref
      temp = @env.info[@seed.children[0]][:expr]
    end

    if temp.type == :hole
      var = temp.children[1].fetch(:variance, COVARIANT)
    else
      var = COVARIANT
    end

    return var

  end

  def initialize(ctx, seed, env, exprs=RDL.type_cast([], 'Array<TypedNode>', force: true))
    @ctx = ctx
    @seed = seed
    @env = env
    @exprs = exprs
    @passed_asserts = 0
    @looking_for = :type
    @ttype = nil
    @inferred_errors = 0
    @dynamic_components = 0
    @typehash = nil
    @typestring = nil
    @variance_at_creation = get_variance
    # add the ranking for types here

  end

  def look_for(kind, target)
    case kind
    when :type
      raise RbSynError, "expected target to be a type" unless target.is_a? RDL::Type::Type
      @looking_for = :type
      @target = target
    when :effect
      @looking_for = :effect
      @target = target
    when :teffect
      @looking_for = :teffect
      @target = target
    else
      raise RbSynError, "can look for types/effects only"
    end
  end

  def to_typestring
    if @typestring.nil?
      t = TTypePrint.new()
      string = t.process(to_ast).to_a.join(" ")
      @typehash = string.hash
      @typestring = string
    end
    @typestring
  end

  def typehash
    if @typehash.nil?
      to_typestring
    end
    @typehash
  end

  # AI generated: deduplication key. Concrete code is compared as code (no node types); holes are compared with
  # their depth, parameters and type, so two candidates differing only in hole types stay separate. typehash /
  # to_typestring above are kept unchanged for verbose checks (DEDUPE_TYPEHASH=1 switches deduplication back).
  def structure_string # AI generated
    @structure_string ||= structure_of(to_ast)
  end

  def structure_hash # AI generated
    @structure_hash ||= structure_string.hash
  end

  # AI generated: write learned types into a hole-free candidate (see LearnedTypeWriteBack); no-op otherwise
  def write_back_learned_types!(type_info) # AI generated
    @hole_free = !has_hole? if @hole_free.nil?
    return false unless @hole_free
    pass = LearnedTypeWriteBack.new(type_info)
    new_seed = pass.process(@seed)
    new_exprs = @exprs.map { |e| pass.process(e) }
    new_info = @env.info.transform_values { |entry| entry.merge(expr: pass.process(entry[:expr])) }
    return false unless pass.changed
    @seed = new_seed
    @exprs = new_exprs
    @env.info = new_info
    @typehash = @typestring = @structure_string = @structure_hash = nil
    true
  end

  def to_ast
    pass = FlattenProgramPass.new(@ctx, @env)
    
    ast = pass.process(@seed)
    return ast if @exprs.empty?

    effect_exprs = @exprs.map { |e| pass.process(e) }
    assigns = pass.var_expr.map { |id, e|
      s(RDL::Globals.types[:top], :lvasgn, "#{VAR_PREFIX}#{id}".to_sym, e)
    }
    @ttype = ast.ttype
    s(ast.ttype, :begin, *[
      *assigns,
      *effect_exprs,
      ast # this is a hack, we can populate the return expression in a type driven way
    ])
  end
  
  

  def ==(other)
    to_ast == other.to_ast
  end

  def eql?(other)
    self == other
  end

  def hash
    to_ast.hash
  end

  def add_side_effect_expr(expr)
    @prog_size_cache = nil # AI generated: program changed, invalidate cached size
    @structure_string = @structure_hash = @hole_free = nil # AI generated: program changed, invalidate cached keys
    @exprs << expr
  end

  def build_candidates()
    
    # update_types_pass = RefineTypesPass.new  # AI altered: replaced by RefineTypesV2 (same behaviour without dynamic:)
    update_types_pass = RefineTypesV2.new # AI generated
    case @looking_for
    when :type
      
      #puts ENV["GLOBAL_COUNT"]
      pass1 = ExpandHolePass.new(@ctx, @env)
      __q0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) if ENV["DBG_DYN"] # INSTRUMENTATION Q (AI generated, remove)
      # binding.pry
      expanded = pass1.process(@seed)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      if ENV["DBG_DYN"] # INSTRUMENTATION Q (AI generated, remove)
        __q1 = Process.clock_gettime(Process::CLOCK_MONOTONIC) # INSTRUMENTATION Q
        __qn = expand_map.map(&:size).reduce(1, :*) # INSTRUMENTATION Q
        warn "[Q] expand=#{(__q1 - __q0).round(2)}s selections=#{__qn} map=#{pass1.expand_map.inspect[0, 80]} methods_of calls=#{$__mo_calls} secs=#{($__mo_secs || 0).round(1)}" if (__q1 - __q0) > 0.5 || __qn > 300 # INSTRUMENTATION Q
      end # INSTRUMENTATION Q
      # binding.pry
      # count = 0 
      x = expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
        # binding.pry
        # puts "selection: #{selection.to_s}"
        # count += 1

        __q3 = ($__q3 ||= Hash.new(0.0)) if ENV["DBG_DYN"] # INSTRUMENTATION Q3 (AI generated, remove): per-stage time in this loop
        __q3t = Process.clock_gettime(Process::CLOCK_MONOTONIC) if ENV["DBG_DYN"] # INSTRUMENTATION Q3
        __xc_selection = selection.dup if ENV["XC_CHECK"] # INSTRUMENTATION XC (AI generated, remove): ExtractASTPass consumes its selection
        pass2 = ExtractASTPass.new(selection, @env)
        temp = pass2.process(expanded)
        # >>> INSTRUMENTATION XC (AI generated, remove): compare the new shallow environment copy with the old deep copy
        if ENV["XC_CHECK"]
          old_pass = ExtractASTPass.new(__xc_selection, @env, deep_copy: true)
          old_temp = old_pass.process(expanded)
          ser = lambda { |n| n.is_a?(TypedNode) ? "(#{n.type}:#{n.ttype} #{n.children.map { |c| ser.(c) }.join(' ')})" : n.inspect }
          env_ser = lambda { |e| e.info.keys.sort.map { |k| "#{k}=>#{e.info[k][:count]}:#{ser.(e.info[k][:expr])}" }.join(';') }
          $__xc = ($__xc || Hash.new(0))
          if ser.(old_temp) == ser.(temp) && env_ser.(old_pass.env) == env_ser.(pass2.env)
            $__xc[:same] += 1
          else
            $__xc[:different] += 1
            warn "[XC] MISMATCH prog_same=#{ser.(old_temp) == ser.(temp)} env_keys old=#{old_pass.env.info.keys.sort.inspect} new=#{pass2.env.info.keys.sort.inspect}" if $__xc[:different] <= 5
          end
          warn "[XC] checked #{$__xc[:same] + $__xc[:different]}: same=#{$__xc[:same]} different=#{$__xc[:different]}" if (($__xc[:same] + $__xc[:different]) % 200).zero?
        end
        # <<< INSTRUMENTATION XC <<<
        if ENV["DBG_DYN"] then __n = Process.clock_gettime(Process::CLOCK_MONOTONIC); __q3[:extract] += __n - __q3t; __q3t = __n; __q3[:selections] += 1 end # INSTRUMENTATION Q3
        # program = update_types_pass.process(temp)  # AI altered: merged into the single refiner.process below
        new_env = pass2.env

        # refiner = DynamicRefineTypes.new(@ctx, new_env)  # AI altered: RefineTypesPass + DynamicRefineTypes in one pass
        refiner = RefineTypesV2.new(ctx: @ctx, env: new_env, dynamic: true) # AI generated
        #BR, this is where you should really be counting the number of dynamic types. ???
        #even the number of errors??
        
        begin
          # if count > 10 
           
          #   puts "program: \n#{new_env.info[program.to_ast.children[0]][:expr].to_ast}"
          #   binding.pry
          # end
          # program = refiner.process(program)  # AI altered: input is now the unrefined candidate (temp),
          #                                     # since RefineTypesPass no longer runs before this
          program = refiner.process(temp) # AI generated
          if ENV["DBG_DYN"] then __n = Process.clock_gettime(Process::CLOCK_MONOTONIC); __q3[:refine] += __n - __q3t; __q3t = __n end # INSTRUMENTATION Q3
     
          # if program.ttype != @target && (((program.ttype <= @target) && @variance_at_creation == CONTRAVARIANT) || ((@target <= program.ttype) && @variance_at_creation == COVARIANT))  
          # AI altered: %dyn ("not known yet") is <= every type in RDL, so the line above rejected every
          # candidate built from %dyn-typed methods; exempt %dyn so unknown-type programs can be observed
          if !program.ttype.is_a?(RDL::Type::DynamicType) && program.ttype != @target && (((program.ttype <= @target) && @variance_at_creation == CONTRAVARIANT) || ((@target <= program.ttype) && @variance_at_creation == COVARIANT)) # AI generated
            #binding.pry
            ($__rej ||= Hash.new(0))["variance-skip ttype=#{program.ttype} target=#{@target} var=#{@variance_at_creation}"] += 1 if ENV["DBG_DYN"] # INSTRUMENTATION Q2 (AI generated, remove)
            next
          end
        rescue NoMethodError, NameError, ComplexError  => e
          ($__rej ||= Hash.new(0))["#{e.class}: #{e.message.to_s[0, 90]}"] += 1 if ENV["DBG_DYN"] # INSTRUMENTATION Q2 (AI generated, remove)
          # we created an ill typed program that went undiscovered when it is still using dynamic types
          # what I am assuming is that we discovered a type, then we attempted to use it after we have corrected its 
          # type errors. 
          # so skip
          next
        rescue Exception => e
          ($__rej ||= Hash.new(0))["#{e.class}: #{e.message.to_s[0, 90]}"] += 1 if ENV["DBG_DYN"] # INSTRUMENTATION Q2 (AI generated, remove)
         
          #refiner = DynamicRefineTypes.new(@ctx, new_env)
          # binding.pry
          # p = refiner.process(program)
          next
        end 

        if ENV["DBG_DYN"] then __n = Process.clock_gettime(Process::CLOCK_MONOTONIC); __q3[:variance] += __n - __q3t; __q3t = __n end # INSTRUMENTATION Q3
        prog_wrap = ProgWrapper.new(@ctx, program, new_env)
        prog_wrap.look_for(:type, @target)
        prog_wrap.passed_asserts = @passed_asserts
        prog_wrap
      }
      # binding.pry
      x = x.reject(&:nil?)
      if ENV["DBG_DYN"] && $__q3 && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - __q1) > 2.0 # INSTRUMENTATION Q3 (AI generated, remove)
        warn "[Q3] env_bytes=#{(Marshal.dump(@env).bytesize rescue -1)} slow selection loop: #{$__q3.map { |k, v| "#{k}=#{v.is_a?(Float) ? v.round(2) : v}" }.join(' ')} kept=#{x.size} rejected=#{($__rej || {}).sort_by { |_, v| -v }.first(3).map { |k, v| "#{v}x #{k[0, 70]}" }.join(' | ')}" # INSTRUMENTATION Q3
      end # INSTRUMENTATION Q3
      $__q3 = nil if ENV["DBG_DYN"] # INSTRUMENTATION Q3
      if ENV["DBG_DYN"] && $__rej && !$__rej.empty? && (($__rej_n = ($__rej_n || 0) + 1) <= 12) # INSTRUMENTATION Q2 (AI generated, remove)
        warn "[Q2] seed=#{@seed.to_s.gsub(/\s+/, ' ')[0, 80]} kept=#{x.size} rejected: #{$__rej.sort_by { |_, v| -v }.first(6).map { |k, v| "#{v}x #{k}" }.join(' | ')}" # INSTRUMENTATION Q2
      end # INSTRUMENTATION Q2
      $__rej = Hash.new(0) if ENV["DBG_DYN"] # INSTRUMENTATION Q2
      warn "[Q] selection loop=#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - __q1).round(2)}s kept=#{x.size} methods_of calls=#{$__mo_calls} secs=#{($__mo_secs || 0).round(1)}" if ENV["DBG_DYN"] && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - __q1) > 0.5 # INSTRUMENTATION Q (AI generated, remove)
     
      x = remove_duplicates(x)
      # binding.pry
      x
    when :effect

      # TODO: ordering can be done better to build candidates programs with
      # method calls that can satisfy multiple effects at once
      x = RDL.type_cast(@target, 'Array<String>', force: true).map { |eff|
        methds = methods_with_write_effect(eff)
        eff_hole = s(RDL::Globals.types[:top], :hole, 1, {effect: true})
        pass1 = ExpandHolePass.new(@ctx, @env)
        pass1.effect_methds = methds
   
        expanded = pass1.process(eff_hole)

        expand_map = pass1.expand_map.map { |i| i.times.to_a }
        expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
          raise RbSynError, "expected only one item" unless selection.size == 1
          read_eff = pass1.read_effs[selection.first]
          pass2 = ExtractASTPass.new(selection, @env)

          program = update_types_pass.process(pass2.process(expanded))
          new_env = pass2.env
          prog_wrap = ProgWrapper.new(@ctx, @seed, new_env, @exprs.dup)
          prog_wrap.add_side_effect_expr(program)
          prog_wrap.look_for(:teffect, read_eff)
          prog_wrap.passed_asserts = @passed_asserts
          prog_wrap
        }
      }.flatten
      x
    when :teffect
      pass1 = ExpandHolePass.new(@ctx, @env)
      expanded = pass1.process(@exprs.last)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
        pass2 = ExtractASTPass.new(selection, @env)
        program = pass2.process(expanded)
        new_env = pass2.env
        new_exprs = @exprs.dup
        new_exprs[-1] = program
        prog_wrap = ProgWrapper.new(@ctx, @seed, new_env, new_exprs)
        prog_wrap.look_for(:teffect, @target)
        prog_wrap.passed_asserts = @passed_asserts
        prog_wrap
      }
    else
      raise RbSynError, "can look for types/effects only"
    end
  end

  def methods_with_write_effect(eff)
    if eff == '*'
      effect_causing = []
      klasses = RDL::Globals.info.info.keys.map { |kls| RDL::Util.to_class(kls) }
      klasses.each { |klass|
        RDL::Globals.info.info.each { |cls, v1|
          v1.each { |meth, v2|
            v2.fetch(:write, ['']).each { |weff|
              next if weff.empty?
              cls_qual = RDL::Util.to_class(cls)
              cls_qual = RDL::Util.singleton_class_to_class(cls_qual) if cls_qual.singleton_class?
              if klass.ancestors.include? cls_qual
                kl = RDL::Util.to_class_str(klass)
                if RDL::Util.to_class(cls).singleton_class?
                  kls = RDL::Util.add_singleton_marker(kl)
                else
                  kls = klass
                end
                effect_causing << [kls, meth, v2.fetch(:read, [''])]
              else
                effect_causing << [cls, meth, v2.fetch(:read, [''])]
              end
            }
          }
        }
      }
      return effect_causing
    elsif eff.split('.').size <= 2
      effect_causing = []
      klass = RDL::Util.to_class(eff.split('.')[0])
      # klass = RDL::Util.singleton_class_to_class(klass) if klass.singleton_class?
      #BRYAN CURRENT THIS FOLLOWING GLOBALS.INFO.INFO DOES NOT CONTAIN ACTIVERECORD::BASE FIGURE OUT WHERE IT IS LOADED AT
      RDL::Globals.info.info.each { |cls, v1|
        # if cls.include?("DynamicType")
        #   binding.pry
        #   cls = "BasicObject"
        #   #BR Experimental: Since a dynamic type can work as any type we shouldn't base the effect off of dynamic itself but based upon 
        #   # every possible permutation of types. This should already be enumerated in prior type inference passes, though. 
        #   next
        # end
        # puts cls
        # binding.pry
        v1.each { |meth, v2|
          # if meth == :save
          #   binding.pry
          # end
          flag = false
          v2.fetch(:write, ['']).each { |weff|
            if cls.include?("DynamicType")
              save_cls = cls
              cls = "BasicObject"
              flag = true
              # binding.pry
            end
            begin
            cls_qual = RDL::Util.to_class(cls)
            rescue Exception => e 
              binding.pry 
              RDL::Util.to_class
            end

            cls_qual = RDL::Util.singleton_class_to_class(cls_qual) if cls_qual.singleton_class?
            if weff.include? 'self'
              if (klass.ancestors.include?(cls_qual) || (cls_qual == ActiveRecord_Relation && klass.ancestors.include?(ActiveRecord::Base)))
                weff = weff.gsub('self', klass.name)
              end
            end
            if EffectAnalysis.effect_leq(eff, weff)

              if klass.ancestors.include? cls_qual
                if RDL::Util.to_class(cls).singleton_class?
                  kls = RDL::Util.add_singleton_marker(eff.split('.')[0])
                else
                  kls = eff.split('.')[0]
                end
                effect_causing << [kls, meth, v2.fetch(:read, [''])]
              else
                if flag 
                  effect_causing << [save_cls,  meth, v2.fetch(:read, [''])]
              else
                effect_causing << [cls, meth, v2.fetch(:read, [''])]
                end 
              end
            end
          }
        }
      }
      # binding.pry
      return effect_causing
    else
      raise RbSynError, "don't know how to handle #{eff.inspect}"
    end
  end

  def has_hole?
    [@seed, *@exprs].any? { |prog| NoHolePass.has_hole? prog, @env }
  end

  # def prog_size
  #   [@seed, *@exprs].map { |prog| ProgSizePass.prog_size prog, @env }.sum
  # end
  # AI altered: prog_size is called on every comparison while sorting the work list; the
  # program only changes through add_side_effect_expr, so cache it there
  def prog_size # AI generated
    @prog_size_cache ||= [@seed, *@exprs].map { |prog| ProgSizePass.prog_size prog, @env }.sum
  end

  def ttype
    @seed.ttype
  end

  # AI generated: printer for structure_string
  def structure_of(node) # AI generated
    case node
    when TypedNode
      if node.type == :hole
        "(hole #{node.children[0]} #{node.children[1].inspect} : #{node.ttype})"
      else
        "(#{node.type} #{node.children.map { |c| structure_of(c) }.join(' ')})"
      end
    when Parser::AST::Node
      "(#{node.type} #{node.children.map { |c| structure_of(c) }.join(' ')})"
    else
      node.inspect
    end
  end

end