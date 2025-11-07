class ProgCache
  include AST

  def initialize(ctx)
    @cache = Set.new
    @ctx = ctx
  end

  def add(prog)
    @cache.add(prog)
  end

  def find_prog(preconds, postconds)
    @cache.each do |prog|
      all_pass = preconds.zip(postconds).all? do |precond, postcond|
        begin
          res, klass = eval_ast(@ctx, prog.to_ast, precond)
        rescue RbSynError => err
          raise err
        rescue StandardError => err
          false # If an error occurs, this specific pre/post pair fails
        end
        klass.instance_eval {
          @params = postcond.parameters.map &:last
        }
        klass.instance_exec res, &postcond
      rescue RbSynError, StandardError # Catch errors from instance_exec
        false
      end
      return prog if all_pass
    end
    nil
  end
end
