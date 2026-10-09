# AI generated: assert for inference runs (eval_ast_second). Calls to methods of interest inside an
# assertion are run through the same instrumentation as synthesized programs (TrackerRewrite +
# InferTypes#w_instrument), so types used only by the spec's assertions (e.g. the getter in
# `assert { @user.email == "x" }`) are learned, and the failed-assertion effect analysis that follows
# can find them.
#
# Guarded: an assertion is instrumented only when the parse/print round trip and w_instrument cannot
# change its meaning (see docs/instrumentation_known_issues.md). Otherwise, or when there is nothing
# to instrument, it falls back to the original Assertions#assert unchanged (just not observed).
#
# Everything after computing the assertion's value is the same as Assertions#assert.
module InstrumentedAssertions # AI generated
  include Assertions

  # node types whose meaning could change through parse/print (Ruby 2.7 parser on Ruby 3.2) or
  # through w_instrument, or under which tracelist slots could misalign (control flow)
  UNSAFE_NODE_TYPES = %i[
    block numblock block_pass lambda hash kwsplat csend defined?
    op_asgn or_asgn and_asgn masgn
    and or if case case_match while until while_post until_post for
    rescue ensure kwbegin yield super zsuper return break next redo retry
  ].freeze

  COMPARISON_METHODS = %i[== != === <= >= =~].freeze

  @cache = {}

  class << self
    # Returns {src:, tracelist:} for an instrumentable assertion, or nil to fall back.
    def prepare(blk, ctx, params)
      key = [ctx.object_id, blk.source_location, params]
      return @cache[key] if @cache.key?(key)
      @cache[key] = build(blk, ctx, params)
    end

    private

    def build(blk, ctx, params)
      header = "#{params[0]} = nil\n"
      ast = Parser::CurrentRuby.parse(header + blk.source)
      body = ast.children.last.children.last # same extraction as Assertions#assert
      return nil unless body.is_a?(Parser::AST::Node)
      return nil unless safe?(body, ctx.moi)
      return nil unless contains_moi_call?(body, ctx.moi)
      # sanity: the round trip must reproduce the same tree
      return nil unless Parser::CurrentRuby.parse(Unparser.unparse(body)) == body

      rewriter = TrackerRewrite.new(ctx.moi, ctx.tenv)
      rewritten = rewriter.process(to_typed(body))
      { src: Unparser.unparse(rewritten), tracelist: rewriter.tracelist }
    rescue StandardError, SyntaxError
      nil
    end

    def safe?(node, moi)
      return true unless node.is_a?(Parser::AST::Node)
      return false if UNSAFE_NODE_TYPES.include?(node.type)
      if node.type == :send && moi.include?(node.children[1])
        recv, meth = node.children[0], node.children[1]
        return false if recv.nil? # no explicit receiver (case 5)
        return false if setter?(meth) # setter value semantics (case 1)
      end
      node.children.all? { |c| safe?(c, moi) }
    end

    def contains_moi_call?(node, moi)
      return false unless node.is_a?(Parser::AST::Node)
      return true if node.type == :send && moi.include?(node.children[1])
      node.children.any? { |c| contains_moi_call?(c, moi) }
    end

    def setter?(meth)
      s = meth.to_s
      s.end_with?("=") && !COMPARISON_METHODS.include?(meth)
    end

    # TrackerRewrite only rewrites TypedNodes; types are not used by the rewrite
    def to_typed(node)
      return node unless node.is_a?(Parser::AST::Node)
      TypedNode.new(RDL::Globals.types[:top], node.type, *node.children.map { |c| to_typed(c) })
    end
  end

  def assert(&blk)
    recorder = instance_variable_defined?(:@dummyclass) ? @dummyclass : nil
    prepared = recorder.nil? ? nil : InstrumentedAssertions.prepare(blk, @ctx, @params)
    # >>> INSTRUMENTATION IA (AI generated, remove) >>>
    if ENV["DBG_DYN"]
      $__ia_seen ||= {}
      key = blk.source_location
      unless $__ia_seen.key?(key)
        $__ia_seen[key] = true
        warn "[IA] #{prepared ? 'instrumented' : 'fallback'}: #{blk.source.strip[0, 90]}#{prepared ? ' => ' + prepared[:src][0, 120] : ''}"
      end
    end
    # <<< INSTRUMENTATION IA <<<
    return super(&blk) if prepared.nil?

    @count += 1
    # fresh copy of the tracelist: w_instrument consumes entries (argtypes.shift)
    recorder.reset_instrumentation(prepared[:tracelist].transform_values { |v| v.is_a?(Array) ? v.dup : v })
    ans = eval(prepared[:src], blk.binding)
    if !!ans
      @passed_count += 1
      ans
    else
      # from here on identical to Assertions#assert
      return if ENV.key? 'DISABLE_EFFECTS'
      ret = @ctx.functype.ret
      raise RbSynError, "expected only one parameter" unless @params.size == 1
      type_env = {}
      # @params is a parameters of post block
      type_env[@params[0].to_sym] = ret
      @ctx.curr_binding.eval("instance_variables").each { |v|
        # TODO: Only generates nominal types for now
        type_env[v.to_sym] = RDL::Type::NominalType.new(@ctx.curr_binding.eval("#{v}.class.name"))
      }

      # Ugly hack! See https://github.com/whitequark/parser/issues/343
      header = "#{@params[0]} = nil\n"
      ast = Parser::CurrentRuby.parse(header + blk.source)

      read_set = EffectAnalysis.effect_of(ast.children.last.children.last, type_env, :read)
      write_set = EffectAnalysis.effect_of(ast.children.last.children.last, type_env, :write)
      raise AssertionError.new(@passed_count, read_set, write_set)
    end
  end
end
