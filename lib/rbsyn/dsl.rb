require 'tempfile'
require 'securerandom'

class SpecProxy
  attr_reader :pre_blk, :post_blk

  def initialize(mth_name)
    @mth_name = mth_name
  end

  def setup(&blk)
    @pre_blk = blk
  end

  def post(&blk)
    @post_blk = blk
  end
end

class SynthesizerProxy
  include AST
  require "minitest/assertions"
  include Minitest::Assertions

  attr_accessor :assertions

  def initialize(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil, seed_expr)
    @ctx = Context.new
    @ctx.max_prog_size = prog_size
    @ctx.components = components
    @ctx.functype = RDL::Globals.parser.scan_str type
    @ctx.max_hash_size = max_hash_size
    @ctx.enable_constants = consts
    @ctx.enable_nil = enable_nil
    @ctx.seed_expr = seed_expr
    @ctx.sketch_mode = ENV.key? 'SKETCH'
    raise RbSynError, "expected method type" unless @ctx.functype.is_a? RDL::Type::MethodType

    @mth_name = mth_name.to_sym
    @ctx.mth_name = @mth_name
    @specs = []
    @assertions = 0
  end

  def spec(desc, &blk)
    spc = SpecProxy.new @mth_name
    spc.instance_eval(&blk)
    @specs << spc
  end

  def reset(&blk)
    @ctx.reset_func = blk
  end

  def generate_program
    if ENV.key? 'TIMEOUT'
      timeout = ENV['TIMEOUT'].strip.to_i
    else
      timeout = 300
    end
    Timeout::timeout(timeout) {
      @specs.each { |spec|
        @ctx.add_example(spec.pre_blk, spec.post_blk)
      }
      syn = Synthesizer.new(@ctx)
      max_args = @ctx.functype.args.size
      args = max_args.times.map { |t| "arg#{t}".to_sym }
      prog = syn.run
      if @ctx.seed_expr
        fn = prog.to_ast
      else
        fn = s(@ctx.functype, :def, @mth_name,
          s(RDL::Globals.types[:top], :args, *args.map { |arg|
            s(RDL::Globals.types[:top], :arg, arg)
          }), prog.to_ast)
      end
      src = Unparser.unparse(fn)
      Instrumentation.prog = src
      Instrumentation.specs = @specs.size
      src
    }
  end
end

module SpecDSL
  include AST

  def define(mth_name, type, components, prog_size: 5, max_hash_size: 1, consts: false, enable_nil: false, &blk)
    syn_proxy = SynthesizerProxy.new(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil, nil)
    syn_proxy.instance_eval(&blk)
  end

  def sketch(src, mth_name, type, components, prog_size: 5, max_hash_size: 1, consts: false, enable_nil: false, &blk)
    sk_src = File.read(src)
    ast = Parser::CurrentRuby.parse(sk_src)

    main_type = RDL::Globals.parser.scan_str(type)

    inferred = infer_sketch_source(sk_src)

    sketch_to_var = SketchToVariablePass.new(mth_name, main_type, inferred)
    new_ast = sketch_to_var.process(ast)

    gtenv_pass = GlobalTEnv.new(mth_name, main_type, inferred)
    gtenv_pass.process(new_ast)
    gtenv = gtenv_pass.tenv

    ltenv_pass = LocalTEnv.new(gtenv, mth_name, main_type, inferred)
    new_ast = ltenv_pass.process(new_ast)

    syn_proxy = SynthesizerProxy.new(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil, new_ast)
    syn_proxy.instance_eval(&blk)
  end

  private

  def infer_sketch_source(sk_src)
    ast = Parser::CurrentRuby.parse(sk_src)
    counter = 0
    hole_methods = []

    transform = lambda do |node|
      if node.is_a?(Parser::AST::Node) && node.type == :send && node.children[0].nil? && node.children[1] == :_?
        var_name = "rbsyn_hole_#{counter}".to_sym
        counter += 1
        hole_methods << var_name
        Parser::AST::Node.new(:send, [nil, var_name])
      elsif node.is_a?(Parser::AST::Node)
        node.updated(nil, node.children.map { |c|
          c.is_a?(Parser::AST::Node) ? transform.call(c) : c
        })
      else
        node
      end
    end

    transformed = transform.call(ast)

    stubs = hole_methods.map { |name|
      Parser::AST::Node.new(:def, [name, Parser::AST::Node.new(:args, []), nil])
    }
    body = Parser::AST::Node.new(:begin, [*stubs, transformed])

    temp_path = "/tmp/sketch_infer_#{SecureRandom.hex(8)}.rb"
    begin
      src = Unparser.unparse(body)
      File.write(temp_path, src)

      result = VarInfer.infer_sketch(temp_path)
      if ENV.key? 'SHOW_INFER'
        unless result.empty?
          $stderr.puts "  [infer] hole types: #{result[:hole_types].map { |k,v| "#{k}=#{v}" }.join(', ')}" if result[:hole_types]
          result[:method_types]&.each { |k,v| $stderr.puts "  [infer]   #{k}: #{v}" }
        end
      end
    rescue => e
      $stderr.puts "  [warn] Sketch inference failed: #{e.message}"
      result = {}
    ensure
      File.unlink(temp_path) if File.exist?(temp_path)
    end

    result
  end
end
