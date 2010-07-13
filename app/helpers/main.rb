require 'memcached'

class Main
  helpers do
  
  # memcached
    def getcache(key)
      if (! $cache)
        $cache = Memcached.new()
        return nil
      end
      begin
        return $cache.get(key) 
      rescue
        nil
      end
    end

    def setcache(key, val)
      begin
        $cache.set(key, val) 
      rescue
      end
    end
    
    # Generate HAML and escape HTML by default.
    def haml(template, options = {}, locals = {})
      options[:escape_html] = true unless options.include?(:escape_html)
      super(template, options, locals)
    end

    # Render a partial and pass local variables.
    #
    # Example:
    #   != partial :games, :players => @players
    def partial(template, locals = {})
      haml(template, {:layout => false}, locals)
    end

  end
end
