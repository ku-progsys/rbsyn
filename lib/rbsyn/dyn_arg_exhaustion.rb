# AI generated: exhaustion of %dyn argument holes during type inference.
#
# Calls built from a %dyn placeholder signature (e.g. DynamicType#email= : (%dyn) -> %dyn) get %dyn argument
# holes, and those node types were never revised once real signatures were learned. Narrowing them eagerly
# would lose fills that only become typeable later at a greater depth, so instead:
#
#   key = (receiver type, method, argument position, hole depth)
#   - record the smallest program size at which a candidate with a %dyn argument hole for that key was queued
#   - watermark = smallest program size still in the work list; programs never shrink when expanded, so once
#     watermark > that size, every program of that size has been generated and run: the key is exhausted
#   - a call whose %dyn argument holes are all exhausted is concretized: the candidate is replaced by one copy
#     per learned signature of receiver.method (as fn_call does), with the argument holes and the call (and
#     its wrapping begin) retyped from that signature. No learned signature for it -> the candidate is dropped.
#
# Only used while type inference is on (see SynHelper#generate).
class DynArgExhaustion # AI generated
  attr_reader :concretized, :dropped

  def initialize(type_info)
    @type_info = type_info
    @first_size = {}
    @concretized = 0
    @dropped = 0
  end

  # record the keys of every %dyn argument hole in a queued candidate
  def note(prog_wrap)
    size = prog_wrap.prog_size
    sites(prog_wrap).each { |site|
      site[:keys].each { |key| @first_size[key] = size if @first_size[key].nil? || size < @first_size[key] }
    }
  end

  # nil when nothing in the candidate is exhausted, otherwise the replacement candidates (possibly empty)
  # def concretize(prog_wrap, watermark)
  #   site = sites(prog_wrap).find { |s| s[:keys].all? { |key| exhausted?(key, watermark) } }
  #   return nil if site.nil?
  #
  #   replacements = learned_signatures(site).map { |sig| retype(prog_wrap, site, sig) }.compact
  #   replacements.empty? ? (@dropped += 1) : (@concretized += 1)
  #   # a replacement may hold further exhausted calls
  #   replacements.flat_map { |pw| concretize(pw, watermark) || [pw] }
  # end
  # AI altered: a learned signature whose argument type is itself %dyn left the hole %dyn, so the same site was found
  # again and the recursion never ended (SystemStackError in 8 benchmarks). learned_signatures now skips such
  # signatures, and the recursion is bounded as a safety net.
  MAX_CONCRETIZE_DEPTH = 8 # AI generated

  def concretize(prog_wrap, watermark, depth = 0) # AI generated
    return nil if depth >= MAX_CONCRETIZE_DEPTH
    site = sites(prog_wrap).find { |s| s[:keys].all? { |key| exhausted?(key, watermark) } }
    return nil if site.nil?

    replacements = learned_signatures(site).map { |sig| retype(prog_wrap, site, sig) }.compact
    replacements.empty? ? (@dropped += 1) : (@concretized += 1)
    # a replacement may hold further exhausted calls
    replacements.flat_map { |pw| concretize(pw, watermark, depth + 1) || [pw] }
  end

  private

  def exhausted?(key, watermark)
    first = @first_size[key]
    !first.nil? && watermark > first
  end

  # send nodes with %dyn method-argument holes, found in the seed, the effect statements and the environment
  def sites(prog_wrap)
    found = []
    roots = [prog_wrap.seed, *prog_wrap.exprs] + prog_wrap.env.info.values.map { |entry| entry[:expr] }
    roots.each { |root| collect(root, found) }
    found
  end

  def collect(node, found)
    return unless node.is_a?(TypedNode)
    if node.type == :send
      recv, meth, *args = node.children
      dyn_holes = args.each_with_index.select { |arg, _|
        arg.is_a?(TypedNode) && arg.type == :hole && arg.ttype.is_a?(RDL::Type::DynamicType) &&
          arg.children[1].is_a?(Hash) && arg.children[1][:method_arg]
      }
      unless dyn_holes.empty?
        recv_type = recv.is_a?(TypedNode) ? recv.ttype : nil
        keys = dyn_holes.map { |arg, idx| [recv_type.to_s, meth, idx, arg.children[0]] }
        found << { node: node, recv_type: recv_type, meth: meth, keys: keys }
      end
    end
    node.children.each { |c| collect(c, found) }
  end

  def learned_signatures(site)
    successes = @type_info.type_successes[site[:meth]] || []
    args = site[:node].children[2..]
    successes.select { |sig|
      next false unless sig[:args].is_a?(Array) && sig[:args].size == args.size
      next false unless receiver_matches?(site[:recv_type], sig[:recvr])
      # arguments that are already filled must fit the signature
      args.each_with_index.all? { |arg, i|
        # next true if arg.is_a?(TypedNode) && arg.type == :hole  # AI altered: see below
        if arg.is_a?(TypedNode) && arg.type == :hole # AI generated
          # a %dyn hole must become concrete; a signature that is %dyn there would leave it unchanged # AI generated
          next !(arg.ttype.is_a?(RDL::Type::DynamicType) && sig[:args][i].is_a?(RDL::Type::DynamicType)) # AI generated
        end # AI generated
        arg.is_a?(TypedNode) && subtype?(arg.ttype, sig[:args][i])
      }
    }
  end

  def receiver_matches?(recv_type, sig_recv)
    return true if recv_type.nil? || recv_type.is_a?(RDL::Type::DynamicType)
    subtype?(recv_type, sig_recv)
  end

  def subtype?(a, b)
    a <= b
  rescue StandardError
    false
  end

  def retype(prog_wrap, site, sig)
    target = site[:node]
    retyper = RetypeCall.new(target, sig)
    new_seed = retyper.process(prog_wrap.seed)
    new_exprs = prog_wrap.exprs.map { |e| retyper.process(e) }
    new_env = LocalEnvironment.new
    new_env.info = prog_wrap.env.info.transform_values { |entry| entry.merge(expr: retyper.process(entry[:expr])) }

    copy = ProgWrapper.new(prog_wrap.ctx, new_seed, new_env, new_exprs)
    copy.look_for(prog_wrap.looking_for, prog_wrap.target)
    copy.passed_asserts = prog_wrap.passed_asserts
    copy.inferred_errors = prog_wrap.inferred_errors
    copy.dynamic_components = prog_wrap.dynamic_components
    copy
  rescue StandardError
    nil
  end

  # rebuilds a tree with the target call's %dyn argument holes and result retyped from a learned signature
  class RetypeCall < ::AST::Processor
    def initialize(target, sig)
      @target = target
      @sig = sig
    end

    def handler_missing(node)
      # the begin that fn_call wraps around a moi call takes the call's new type too
      if node.type == :begin && node.children.size == 1 && node.children[0].equal?(@target)
        call = retyped_call
        return TypedNode.new(call.ttype, :begin, call)
      end
      return retyped_call if node.equal?(@target)
      node.updated(nil, node.children.map { |k| k.is_a?(TypedNode) ? process(k) : k })
    end

    private

    def retyped_call
      recv, meth, *args = @target.children
      new_args = args.each_with_index.map { |arg, i|
        if arg.is_a?(TypedNode) && arg.type == :hole && arg.ttype.is_a?(RDL::Type::DynamicType)
          TypedNode.new(@sig[:args][i], :hole, *arg.children)
        else
          arg
        end
      }
      TypedNode.new(@sig[:result], :send, recv, meth, *new_args)
    end
  end
end
