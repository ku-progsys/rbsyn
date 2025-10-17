# simple_web_app.rb


# created with the assistance of chatGPT will need to generate more. 
class RouteNotFoundError < StandardError; end

class SimpleWebApp
  attr_reader :routes

  def initialize
    @routes = {}
  end

  # Register a route with a block handler
  def add_route(path, &handler)
    routes[path] = handler
  end

  # Explicit setter for a route (takes a Proc or lambda)
  def set_route(path, handler_proc)
    unless handler_proc.respond_to?(:call)
      raise ArgumentError, "Handler must be callable (Proc or lambda)"
    end
    routes[path] = handler_proc
  end

  # Simulate handling a request with positional args
  def call(path, *args)
    if routes.key?(path)
      routes[path].call(*args)
    else
      raise RouteNotFoundError, "No route matches #{path}"
    end
  end
end