
require "pry"
require 'pry-byebug'
require 'parser/current'
require "set"
require_relative 'ast/infer_types'
require_relative 'debugger'
require_relative 'complex_error'
#require_relative "proliferate_pass"




def duplicates(list)
  t = TTypePrint.new()
  counts = Hash.new(0)
  
  list.each do |item| 
    counts[t.process(item).to_a.join(" ")] += 1
    t.reset()
  end
  counts.select { |_, n| n > 1 }
end


def test_ordering(worklist)
  is_sorted = worklist.each_cons(2).all? { |a, b| a.inferred_errors <= b.inferred_errors }
  if !is_sorted
    raise "Not sorted"
  end
end


def discard_impossible_types(generated, type)
  
  generated.select { |prog_wrap|
    prog_wrap.ttype <= type
  }
end

def read_asts(astlist)
  puts "LIST SIZE: #{astlist.size}"
  astlist.each do |i|
    puts "----------------\n"
    puts i.to_ast
    puts "TYPE: #{i.ttype}"
    puts "----------------\n"
  end
end

# AI generated: raised by a typed search that hit its switch_after budget (see SynHelper#generate)
class SwitchToInference < StandardError; end # AI generated

module SynHelper
  include TypeOperations
  
  # def generate(seed_hole, preconds, postconds, return_all=false, add_dyn: false, type_search_depth: 120 )
  # AI altered: added switch_after: a typed search (add_dyn false) that reaches this many iterations without a
  # solution raises SwitchToInference, so the caller can switch to an inference pass (see
  # generate_typed_then_inference). nil (the default) keeps the original behaviour.
  def generate(seed_hole, preconds, postconds, return_all=false, add_dyn: false, type_search_depth: 120, switch_after: nil) # AI generated

    if add_dyn 
      ENV['ADD_DYN'] = "TRUE"
    else
      ENV['ADD_DYN'] = 'FALSE'
    end

    correct_progs = []
    sweep_mode = ENV.key?("SWEEP_DYN") # AI generated: opt-in single-pass inference (see the inference limit below)
    exhaustion = DynArgExhaustion.new(@ctx.type_info) # AI generated: exhaustion of %dyn argument holes (lib/rbsyn/dyn_arg_exhaustion.rb)
    last_watermark = nil # AI generated: smallest program size in the work list at the last exhaustion check
    work_list = [seed_hole,]
    basehashlist = []
    evaluated_srcs = Set.new # AI generated: sources of hole-free programs already run against the specs
    counter = 0

    until work_list.empty?
      # ENV["COUNT"] = (ENV["COUNT"].to_i + 1).to_s
      # if ENV["COUNT"]=="351"
      #   binding.pry
      # end
      # if counter >= type_search_depth && add_dyn
      #   raise NameError, "done checking for types at count: #{counter}"
      # end
      # AI altered: with SWEEP_DYN set, reaching the inference limit no longer ends the search (the caller
      # used to restart a fresh typed search from a new seed). Instead, candidates still carrying %dyn
      # components are swept off the work list (kept in @swept_dyn for later reintroduction), inference
      # mode is switched off, and the same search continues with the typed candidates it already has.
      if counter >= type_search_depth && add_dyn # AI generated
        raise NameError, "done checking for types at count: #{counter}" unless sweep_mode # AI generated: old path
        swept = work_list.select { |prog_wrap| prog_wrap.dynamic_components > 0 } # AI generated
        if swept.size == work_list.size # AI generated: nothing typed to continue with, fall back to the restart path
          raise NameError, "done checking for types at count: #{counter} (sweep left no typed candidates)" # AI generated
        end
        # >>> INSTRUMENTATION SW (AI generated, remove) >>>
        if ENV["DBG_DYN"]
          warn "[SW] swept #{swept.size}; with passed_asserts>0: #{swept.count { |pw| pw.passed_asserts > 0 }}"
          swept.select { |pw| pw.passed_asserts > 0 }.first(6).each do |pw|
            dyn_nodes = []
            walk = lambda { |n| next unless n.is_a?(TypedNode); dyn_nodes << "#{n.type}#{n.type == :send ? ':' + n.children[1].to_s : ''}(#{n.ttype})" if n.ttype.is_a?(RDL::Type::DynamicType); n.children.each { |c| walk.(c) } }
            walk.(pw.to_ast)
            fresh = @ctx.type_info.check_errors(pw)
            warn "[SW]   pa=#{pw.passed_asserts} look=#{pw.looking_for} stored_dyn=#{pw.dynamic_components} recomputed(err,dyn)=#{fresh.inspect} %dyn-typed nodes=#{dyn_nodes.inspect[0, 160]} ast=#{pw.to_ast.to_s.gsub(/\s+/, ' ')[0, 150]}"
          end
        end
        # <<< INSTRUMENTATION SW <<<
        work_list -= swept # AI generated
        (@swept_dyn ||= []).concat(swept) # AI generated
        add_dyn = false # AI generated
        ENV['ADD_DYN'] = 'FALSE' # AI generated
        work_list = work_list.sort_by { |prog_wrap| comparator_key(prog_wrap) } # AI generated: re-rank with the inference-off order
        @ctx.logger.debug("Inference limit reached at #{counter}: swept #{swept.size} %dyn candidates, continuing with #{work_list.size} typed candidates") # AI generated
      end
      raise SwitchToInference, "typed search reached #{counter} iterations" if switch_after && !add_dyn && counter >= switch_after # AI generated
      counter += 1
      # puts "counter: #{counter}"
      #puts counter
      # binding.pry
      # binding.pry
      $__prof_t = Process.clock_gettime(Process::CLOCK_MONOTONIC) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      if ENV["DBG_DYN"] # INSTRUMENTATION PX (AI generated, remove): per-iteration snapshot for slow-iteration breakdown
        __px_snap = $__prof.dup # INSTRUMENTATION PX
        __px_t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) # INSTRUMENTATION PX
      end # INSTRUMENTATION PX
      # work_list = work_list.sort { |a, b| comparator(a, b) }  # AI altered: redundant, the list is already
      #                                                        # sorted at the end of the previous iteration
      $__prof_t = __prof_mark(:sort1, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
   
      base = work_list.shift


      # if basehashlist.include? base.typehash  # AI altered: identical hole-free programs carrying different
      #                                         # inferred signatures had distinct typehashes and were all expanded
      base_key = dedupe_key(base) # AI generated
      # >>> INSTRUMENTATION ER (AI generated, remove) >>>
      if ENV["DBG_DYN"]
        __s = base.to_ast.to_s
        $__er_total = ($__er_total || 0) + 1
        if __s.include?("(envref")
          $__er_hits = ($__er_hits || 0) + 1
          warn "[ER] envref survives to_ast (#{$__er_hits}/#{$__er_total}) typestring=#{base.to_typestring[0, 160]} ast=#{__s.gsub(/\s+/, ' ')[0, 200]}" if $__er_hits <= 6
        end
        warn "[ER] summary: #{$__er_hits || 0} of #{$__er_total} popped candidates still contain envref after to_ast" if $__er_total % 500 == 0
      end
      # <<< INSTRUMENTATION ER <<<
      if basehashlist.include? base_key # AI generated
        # >>> INSTRUMENTATION S (AI generated, remove) >>>
        if ENV["DBG_DYN"] && !add_dyn && base.looking_for != :type
          warn "[S] SKIPPED dup typehash counter=#{counter} look=#{base.looking_for} tgt=#{base.target.inspect[0, 60]} pa=#{base.passed_asserts} ast=#{base.to_ast.to_s.gsub(/\s+/, ' ')[0, 200]}"
        end
        # <<< INSTRUMENTATION S <<<
        next
      end
      # basehashlist << base.typehash  # AI altered
      basehashlist << base_key # AI generated
      # >>> INSTRUMENTATION T (AI generated, remove) >>>
      if ENV["DBG_DYN"] && !add_dyn && (counter <= 80 || counter % 250 == 0)
        warn "[T] counter=#{counter} wl=#{work_list.size} look=#{base.looking_for} tgt=#{base.target.inspect[0, 60]} err=#{base.inferred_errors} dyn=#{base.dynamic_components} size=#{base.prog_size} pa=#{base.passed_asserts} ast=#{base.to_ast.to_s.gsub(/\s+/, ' ')[0, 220]}"
      end
      if ENV["DBG_DYN"] && add_dyn
        warn "[I] counter=#{counter} t=#{Time.now.strftime('%H:%M:%S.%L')} wl=#{work_list.size} err=#{base.inferred_errors} dyn=#{base.dynamic_components} size=#{base.prog_size} ast=#{base.to_ast.to_s.gsub(/\s+/, ' ')[0, 200]}"
      end
      # <<< INSTRUMENTATION T <<<
      effect_needed = []

      # puts "BASE: \n#{base.to_ast}"
      # puts "SIZE OF WORKLIST: #{work_list.size}" 
      # work_list.each_with_index do |i, index| puts "Size: #{i.prog_size} #Passed Asserts: #{i.passed_asserts} #Dynamic Components: #{i.dynamic_components} Has Hole: #{i.has_hole?}, Contains hole1 #{i.to_ast.to_s.include?("hole 1")}" end
      # binding.pry
      $__prof_t = __prof_mark(:pop_dedupe, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      __bt0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) if ENV["DBG_DYN"] # INSTRUMENTATION B (AI generated, remove)
      generated = base.build_candidates()
      if ENV["DBG_DYN"] # INSTRUMENTATION B (AI generated, remove)
        __bdt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - __bt0 # INSTRUMENTATION B
        warn "[B] counter=#{counter} add_dyn=#{add_dyn} build=#{__bdt.round(2)}s generated=#{generated.size} look=#{base.looking_for} ast=#{base.to_ast.to_s.gsub(/\s+/, ' ')[0, 200]}" if __bdt > 0.5 # INSTRUMENTATION B
      end # INSTRUMENTATION B
      $__prof_t = __prof_mark(:build, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      # >>> INSTRUMENTATION X (AI generated, remove) >>>
      if ENV["DBG_DYN"] && !add_dyn
        bs = base.to_ast.to_s.gsub(/\s+/, ' ')
        if base.looking_for == :teffect && bs.match?(/\(begin \(begin \(send \(lvar :arg0\) :email= \(hole 1 [^)]*\)\)\) \(true\)\)$/)
          warn "[X] counter=#{counter} expanding #{bs} hole_ttype=#{base.exprs.last.to_s[0, 0]}"
          warn "[X]   generated #{generated.size}:"
          generated.first(40).each { |g| warn "[X]     #{g.to_ast.to_s.gsub(/\s+/, ' ')[0, 200]}" }
        end
      end
      # <<< INSTRUMENTATION X <<<

      # puts "\n----------------\n"
      evaluable = generated.reject &:has_hole?

      # >>> INSTRUMENTATION E2 (remove) >>>
      if ENV["DBG_DYN"]
        evaluable.each do |pw|
          s = pw.to_ast.to_s.gsub(/\s+/, ' ')
          next unless s.include?(":exists?") && s.match?(/\(hash\b/)
          warn "[E2] counter=#{counter} RECV=#{s[/\(send \((.{0,40})/, 1].inspect} ARGS=#{s[/:exists\? (.*)/, 1].inspect}"
        end
      end
      # <<< INSTRUMENTATION E2 <<<
      tempbool = false

      if ENV["INSPECT"]=="T" && (ENV["COND"].nil? || base.to_ast.to_s == ENV["COND"])
        ENV["COUNT"] = (ENV["COUNT"].to_i + 1).to_s
        File.open("test_output.txt", "a") do |f|
          f.write "\n----------------\n"
          f.write "TTYPES\n"
          generated.each do |i| f.write "#{i.to_ast.ttype}\n" end
          f.write "\nPROGS\n\n"
          f.write "LOCAL_COUNT: #{counter}\n"
          f.write "GLOBAL_COUNT: #{ENV["COUNT"]}\n\n"
          f.write "BASE_AFTER:\n#{base.to_ast}\n"
          f.write "BASETYPE: #{base.to_ast.ttype}\n"
          f.write "SIZE WORK_LIST: #{work_list.size}\n"
          f.write "SIZE generated: #{generated.size}\n"
          f.write "EVALUABLE#: #{evaluable.size}\n"
          f.write "\n-------------------------\n"
          
        end
      end
      
      # AI generated: drop programs whose source was already evaluated (same code from a different
      # signature of the same method) - running them again yields identical results
      evaluable = evaluable.reject { |prog_wrap| # AI generated
        src = plain_source(prog_wrap) # AI generated
        seen = evaluated_srcs.include?(src) # AI generated
        evaluated_srcs << src # AI generated
        seen # AI generated
      } # AI generated
      evaluable.each { |prog_wrap|
        res = 1
        klass = 1
        passes = 1
        # puts "TESTING: \n#{prog_wrap.to_ast} \nof TTYPE: #{prog_wrap.to_ast.ttype}"
        #puts Unparser.unparse(prog_wrap.to_ast)
        tempbool = false

        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin

            # res, klass = eval_ast_second(@ctx, prog_wrap.to_ast, precond)
            # 
            #
            res, klass = if add_dyn
               eval_ast_second(@ctx, prog_wrap.to_ast, precond)
             else
               eval_ast(@ctx, prog_wrap.to_ast, precond)
             end

            
          rescue RbSynError => err
            raise err
          rescue TypeError => err
            tempbool = true
            break
          rescue StandardError => err
            # >>> INSTRUMENTATION R (remove) >>>
            if ENV["DBG_DYN"]
              ast_s = prog_wrap.to_ast.to_s.gsub(/\s+/, ' ')
              if ast_s.match?(/\(send \(lvar DiasporaUser\(.*?\) :exists\? \(hash \(pair \(sym :email\)/)
                warn "[R] #{err.class}: #{err.message[0, 80]}"
                warn "[R] at: #{err.backtrace.first(8).join("\n      ")}"
                warn "[R] prog: #{ast_s[0, 200]}"
                # binding.pry  # AI altered: blocks unattended runs (DBG_DYN=1 hits it once the search reaches exists?(email: ...))
              end
            end
            # <<< INSTRUMENTATION R <<<
            tempbool = true
            next
          rescue ComplexError => err
            tempbool = true
            next
          rescue SyntaxError => err
            # really this shouldn't happen, our generator shouldn't be attempting to create ill formed formulae, but right now I don't have a workaround for some ad hoc constructs.  
            tempbool = true
            next
          end

          begin
            klass.instance_eval {
              @params = postcond.parameters.map &:last
            }
            # begin
            passes = klass.instance_exec res, &postcond
            # rescue Exception => e 
            #   if ENV["FLAGFLAG"] == "T" 
            #     puts "prog_wrap: #{prog_wrap.to_ast}"
            #     binding.pry
            #   end
            #   raise e 
            # end 
            passes

          rescue AssertionError => e
            orig_prog = prog_wrap.dup
            prog_wrap.passed_asserts = e.passed_count
            warn "[A] pa=#{e.passed_count} read=#{e.read_set.inspect} prog=#{prog_wrap.to_ast.to_s.gsub(/\s+/, ' ')[0, 220]}" if ENV["DBG_DYN"] && !add_dyn && e.passed_count >= 2 # INSTRUMENTATION A (AI generated, remove)
            prog_wrap.look_for(:effect, e.read_set)
            effect_needed << prog_wrap

            if orig_prog.looking_for == :teffect && !(orig_prog.target.size == 1 || orig_prog.target[0] == '')
              orig_prog.passed_asserts = e.passed_count
              orig_prog.look_for(:teffect, orig_prog.target)
              effect_needed << orig_prog
            end

          rescue RbSynError => e
            raise e

          rescue StandardError => e
            if ENV["DBG_DYN"] && (($__pe_n = ($__pe_n || 0) + 1) <= 5) # INSTRUMENTATION PE (AI generated, remove)
              warn "[PE] postcondition raised #{e.class}: #{e.message[0, 120]} at #{e.backtrace.first(3).join(' <- ')} prog=#{prog_wrap.to_ast.to_s.gsub(/\s+/, ' ')[0, 120]}" # INSTRUMENTATION PE
            end # INSTRUMENTATION PE
            next
          rescue ComplexError => e 
            next
          end
          
        }
        #BLOCK END

        
        if tempbool
          # type error encountered in a complete program, we should not add back to the worklist
          next
        end
        # passes all tests
        #debug(Unparser.unparse(prog_wrap.to_ast), "arg1.take(arg2)")
        # if test_outputs.all? true && !add_dyn
        # AI altered: the line above parses as test_outputs.all?(true && !add_dyn), i.e. all?(false) during inference,
        # which accepted programs whose outputs were all false. Intended: all outputs true, and not during inference
        # (except in SWEEP_DYN mode, where a correct program found while inferring is kept like any other)
        if test_outputs.all?(true) && (!add_dyn || sweep_mode) # AI generated
            #puts "correct program \n#{format_ast(prog_wrap.to_ast)}"
            correct_progs << prog_wrap
          return prog_wrap unless return_all
          
        elsif ENV.key? 'DISABLE_EFFECTS'
          prog_wrap.passed_asserts = 0
          prog_wrap.inferred_errors = 10000 #BR This is my addition this 
          prog_wrap.look_for(:effect, ['*'])

          effect_needed << prog_wrap
        end
        
      }
      # done evaluating complete programs

      $__prof_t = __prof_mark(:eval, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      remainder_holes = generated.select { |prog_wrap|
        prog_wrap.has_hole? &&
        prog_wrap.prog_size <= @ctx.max_prog_size 
        
      }
      
      newsuccess = @ctx.type_info.newsuccess
      newerror = @ctx.type_info.newerror
      newtypes = @ctx.type_info.get_reset_newtypes

      # if newsuccess
      #   work_list.map {|prog_wrap|
      #     proliferate = Proliferate.new(newtypes, @ctx.moi)
      #     x = proliferate(prog_wrap, newtypes, godelhash)} 
      #     work_list.concat(Array(x)) unless x.nil?
      # end

      # >>> INSTRUMENTATION N (AI generated, remove) >>>
      if ENV["DBG_DYN"] && !add_dyn && (counter <= 5 || counter % 50 == 0)
        warn "[N] counter=#{counter} newsuccess=#{newsuccess.inspect} newerror=#{newerror.inspect} wl=#{work_list.size} t=#{Time.now.strftime('%H:%M:%S')}"
      end
      if ENV["DBG_DYN"] && !add_dyn
        evaluable.each do |pw|
          s = pw.to_ast.to_s.gsub(/\s+/, ' ')
          warn "[U] counter=#{counter} built: #{s[0, 250]}" if s.match?(/:email= (\(begin )?\(send \(lvar :arg0\) :unconfirmed_email\)/)
        end
      end
      # <<< INSTRUMENTATION N <<<
      # >>> INSTRUMENTATION W (AI generated, remove) >>>
      if ENV["DBG_DYN"] && !add_dyn && [100, 200, 400, 600].include?(counter)
        sorted = work_list.sort { |a, b| comparator(a, b) }
        hist = Hash.new(0)
        sorted.each { |pw| hist[[pw.looking_for, pw.inferred_errors, pw.prog_size, pw.passed_asserts, pw.dynamic_components]] += 1 }
        warn "[W] counter=#{counter} wl=#{sorted.size} histogram (look,err,size,pa,dyn)=>count:"
        hist.sort_by { |k, _| sorted.index { |pw| [pw.looking_for, pw.inferred_errors, pw.prog_size, pw.passed_asserts, pw.dynamic_components] == k } }
            .first(25).each { |k, v| warn "[W]   #{k.inspect} => #{v}" }
        sorted.each_with_index do |pw, i|
          s = pw.to_ast.to_s.gsub(/\s+/, ' ')
          next unless pw.looking_for == :teffect && s.include?(":email=") && s.include?("(hole 1")
          warn "[W]   target-like rank=#{i} err=#{pw.inferred_errors} size=#{pw.prog_size} pa=#{pw.passed_asserts} dyn=#{pw.dynamic_components} ast=#{s[0, 200]}"
        end
      end
      # <<< INSTRUMENTATION W <<<
      # if newsuccess  # AI altered: new errors also change inferred_errors, so rescore on either
      if newsuccess || newerror # AI generated
        work_list.map {|prog_wrap|
          prog_wrap.write_back_learned_types!(@ctx.type_info) # AI generated: hole-free candidates take their learned types
          prog_wrap.inferred_errors, prog_wrap.dynamic_components = @ctx.type_info.check_errors(prog_wrap)
        }
      end

      remainder_holes.map {|prog_wrap|
          prog_wrap.inferred_errors, prog_wrap.dynamic_components = @ctx.type_info.check_errors(prog_wrap)
      }
 
      $__prof_t = __prof_mark(:rescore, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      remainder_holes.push(*effect_needed)


      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      # if !correct_progs.empty? && return_all && !add_dyn
      if !correct_progs.empty? && return_all && (!add_dyn || sweep_mode) # AI altered: SWEEP_DYN keeps correct programs found while inferring
        return correct_progs
      end
      
      # work_list = [*work_list, *remainder_holes].sort { |a, b| comparator(a, b) }  # AI altered: comparator block
      #                                                                         # dominated runtime on 10k+ lists
      # AI generated: while inferring, record %dyn argument holes of new candidates and concretize any whose
      # (receiver type, method, position, depth) is already exhausted (see DynArgExhaustion)
      if add_dyn # AI generated
        watermark = work_list.empty? ? nil : work_list.map(&:prog_size).min # AI generated
        remainder_holes = remainder_holes.flat_map { |prog_wrap| # AI generated
          exhaustion.note(prog_wrap) # AI generated
          replaced = watermark.nil? ? nil : exhaustion.concretize(prog_wrap, watermark) # AI generated
          replaced.nil? ? [prog_wrap] : replaced.each { |pw| pw.inferred_errors, pw.dynamic_components = @ctx.type_info.check_errors(pw) } # AI generated
        } # AI generated
      end # AI generated
      work_list = [*work_list, *remainder_holes].sort_by { |prog_wrap| comparator_key(prog_wrap) } # AI generated
      # AI generated: when the watermark rises, concretize exhausted %dyn arguments across the whole work list
      if add_dyn && !work_list.empty? # AI generated
        watermark = work_list.map(&:prog_size).min # AI generated
        if last_watermark.nil? || watermark > last_watermark # AI generated
          before = [exhaustion.concretized, exhaustion.dropped] # AI generated
          work_list = work_list.flat_map { |prog_wrap| # AI generated
            replaced = exhaustion.concretize(prog_wrap, watermark) # AI generated
            next [prog_wrap] if replaced.nil? # AI generated
            replaced.each { |pw| pw.inferred_errors, pw.dynamic_components = @ctx.type_info.check_errors(pw); exhaustion.note(pw) } # AI generated
          }.sort_by { |prog_wrap| comparator_key(prog_wrap) } # AI generated
          @ctx.logger.debug("Exhaustion watermark #{last_watermark.inspect} -> #{watermark}: concretized #{exhaustion.concretized - before[0]}, dropped #{exhaustion.dropped - before[1]}, work list #{work_list.size}") # AI generated
          last_watermark = watermark # AI generated
        end # AI generated
      end # AI generated
      $__prof_t = __prof_mark(:sort2, $__prof_t) if ENV["DBG_DYN"] # INSTRUMENTATION P (AI generated, remove)
      if ENV["DBG_DYN"] && __px_t0 # INSTRUMENTATION PX (AI generated, remove)
        __px_total = Process.clock_gettime(Process::CLOCK_MONOTONIC) - __px_t0 # INSTRUMENTATION PX
        if __px_total > 2.0 # INSTRUMENTATION PX
          __px_parts = $__prof.map { |k, v| [k, (v - (__px_snap[k] || 0.0)).round(2)] }.select { |_, v| v > 0.05 } # INSTRUMENTATION PX
          warn "[PX] slow iteration counter=#{counter} add_dyn=#{add_dyn} total=#{__px_total.round(2)}s parts=#{__px_parts.inspect} generated=#{generated.size} evaluated=#{evaluable.size} preconds=#{preconds.size} wl=#{work_list.size} base=#{base.to_ast.to_s.gsub(/\s+/, ' ')[0, 160]}" # INSTRUMENTATION PX
        end # INSTRUMENTATION PX
      end # INSTRUMENTATION PX
      if ENV["DBG_DYN"] && counter % 100 == 0 # INSTRUMENTATION P (AI generated, remove)
        warn "[P] counter=#{counter} add_dyn=#{add_dyn} wl=#{work_list.size} cumulative secs: #{$__prof.map { |k, v| "#{k}=#{v.round(1)}" }.join(' ')} methods_of calls=#{$__mo_calls} secs=#{($__mo_secs || 0).round(1)}" # INSTRUMENTATION P
      end # INSTRUMENTATION P
#      test_ordering(work_list)
      work_list
    end
    log = "Type Sucesses"
    @ctx.type_info.type_successes.each {|i, j| 
      j.each { |k|  
        log = log + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    }
    log2 = "Type Failures"
    @ctx.type_info.type_errs.each do |i, j|
      j.each { |k|
        log2 = log2 + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    end

    raise RbSynError, "No candidates found" + "\n\n" + log + "\n\n" + log2 + "\n\n"

  end

  # AI generated: source text of a program, ignoring the type annotations on its nodes
  def plain_source(prog_wrap) # AI generated
    Unparser.unparse(prog_wrap.to_ast)
  rescue StandardError
    prog_wrap.to_ast.to_s
  end

  # AI generated: programs with holes keep the typed hash (hole types matter for expansion);
  # hole-free programs are keyed by source plus what they are searching for
  def dedupe_key(prog_wrap) # AI generated
    # return prog_wrap.typehash if prog_wrap.has_hole?  # AI altered: see ProgWrapper#structure_hash; the key now also
    #                                                   # includes what the candidate is searching for (type vs effect step)
    if prog_wrap.has_hole? # AI generated
      return prog_wrap.typehash if ENV.key?("DEDUPE_TYPEHASH") # AI generated: original key, for comparison
      return [prog_wrap.structure_hash, prog_wrap.looking_for, prog_wrap.target.to_s].hash # AI generated
    end # AI generated
    [plain_source(prog_wrap), prog_wrap.looking_for, prog_wrap.target.to_s].hash
  end

  # >>> INSTRUMENTATION P (AI generated, remove) >>>
  $__prof = Hash.new(0.0)
  def __prof_mark(name, t0)
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    $__prof[name] += (t1 - (t0 || t1))
    t1
  end
  # <<< INSTRUMENTATION P <<<

  # AI altered: original comparator below ranked prog_size before passed_asserts (the reference ranks
  # passed_asserts first, which is what lets it follow an effect chain), and its a.passed_asserts >
  # b.passed_asserts branch returned 1, the same as the < branch.
  # def comparator(a, b)
  #
  #   if a.inferred_errors > b.inferred_errors
  #     1
  #   elsif a.inferred_errors == b.inferred_errors
  #
  #     if a.prog_size < b.prog_size
  #       -1
  #     elsif a.prog_size == b.prog_size
  #
  #       if a.passed_asserts < b.passed_asserts
  #         1
  #       elsif a.passed_asserts == b.passed_asserts
  #
  #
  #
  #         if a.dynamic_components < b.dynamic_components
  #           1
  #         elsif a.dynamic_components > b.dynamic_components
  #           -1
  #         elsif a.dynamic_components == b.dynamic_components
  #           if a.ttype == @ctx.functype.ret
  #             -1
  #           elsif b.ttype == @ctx.functype.ret
  #             1
  #           else
  #             0
  #           end
  #         end
  #       else
  #         # 1  # AI altered: this branch is a.passed_asserts > b.passed_asserts, which must sort a first;
  #         #    # returning 1 here gave the same answer as the < branch, so passed_asserts never ranked anything
  #         -1 # AI generated
  #       end
  #
  #
  #     else
  #       1
  #     end
  #
  #
  #   else
  #     -1
  #   end
  # end

  # AI generated: same criteria as the comparator above, reordered so passed_asserts outranks
  # prog_size (inferred_errors still first); ascending sort key, so negate "more is better" fields
  # def comparator_key(prog_wrap) # AI generated
  #   [prog_wrap.inferred_errors,
  #    -prog_wrap.passed_asserts,
  #    prog_wrap.prog_size,
  #    -prog_wrap.dynamic_components,
  #    prog_wrap.ttype == @ctx.functype.ret ? 0 : 1]
  # end
  # AI altered: two search strategies. With type inference on (ENV["ADD_DYN"] == "TRUE", set by generate and
  # switched off by the SWEEP_DYN sweep) the goal is exploration, so the original order is used: inferred
  # errors, size, passed assertions (size-ordered exploration is also what makes "all programs of size <= n
  # have been seen" meaningful). With inference off the goal is solving: inferred errors, passed assertions,
  # size (as vanilla), which follows effect chains greedily. passed_asserts sign fix kept in both.
  def comparator_key(prog_wrap) # AI generated
    tail = [-prog_wrap.dynamic_components, prog_wrap.ttype == @ctx.functype.ret ? 0 : 1]
    if ENV["ADD_DYN"] == "TRUE"
      [prog_wrap.inferred_errors, prog_wrap.prog_size, -prog_wrap.passed_asserts, *tail]
    else
      [prog_wrap.inferred_errors, -prog_wrap.passed_asserts, prog_wrap.prog_size, *tail]
    end
  end

  # AI generated: typed search first; switch to an inference pass (then typed with no cap, as the original two-phase
  # path) if the typed search runs out of candidates or reaches the inference budget without a solution.
  # seed_builder returns a fresh seed each call (generate rewrites a candidate's environment while expanding it).
  def generate_typed_then_inference(seed_builder, preconds, postconds, return_all, label) # AI generated
    budget = (ENV["ITERS"].nil? ? 19 : ENV["ITERS"].to_i) * @ctx.moi.size
    return generate(seed_builder.call, preconds, postconds, return_all) if @ctx.moi.empty?
    begin
      return generate(seed_builder.call, preconds, postconds, return_all, switch_after: budget)
    rescue SwitchToInference => e
      @ctx.logger.debug("#{label}: #{e.message} without a solution, switching to an inference pass")
    rescue RbSynError => e
      raise e unless e.message.start_with?("No candidates")
      @ctx.logger.debug("#{label}: typed search ran out of candidates, switching to an inference pass")
    end
    begin
      generate(seed_builder.call, preconds, postconds, return_all, add_dyn: true, type_search_depth: budget)
    rescue NameError
      @ctx.logger.debug("#{label}: inference complete, resuming typed search")
      generate(seed_builder.call, preconds, postconds, return_all)
    end
  end

  def comparator(a, b) # AI generated: kept for callers that sort with a block
    comparator_key(a) <=> comparator_key(b)
  end

end
