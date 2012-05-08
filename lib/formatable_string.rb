module RemoteModule
  class FormatableString < String
    # Takes in a hash and spits out the formatted string
    # Checks the delegate first
    def format(params = {}, delegate = nil)
      params ||= {}
      split = self.split '/'
      split.collect { |path|
        ret = path
        if path[0] == ':'
          path_sym = path[1..-1].to_sym

          curr = nil
          if delegate && delegate.respond_to?(path_sym)
            curr = delegate.send(path_sym)
          end

          ret = (curr || params[path_sym] || path).to_s
        end

        ret
      }.join '/'
    end
  end
end