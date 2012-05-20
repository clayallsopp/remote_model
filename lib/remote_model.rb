module RemoteModule
  class RemoteModel
    HTTP_METHODS = [:get, :post, :put, :delete]

    class << self
      # These three methods (has_one/many/ + belongs_to)
      # map a symbol to a class for method_missing lookup 
      # for each :symbol in params.
      # Can also be used to view the current mappings:
      # EX
      # Question.has_one
      # => {:user => User}

      # EX 
      # self.has_one :question, :answer, :camel_case
      # => {:question => Question, :answer => Answer, :camel_case => CamelCase}
      def has_one(params = [])
        make_fn_lookup "has_one", params, singular_klass_str_lambda
      end

      # EX 
      # self.has_many :questions, :answers, :camel_cases
      # => {:questions => Question, :answers => Answer, :camel_cases => CamelCase}
      def has_many(params = [])
        make_fn_lookup "has_many", params, lambda { |sym| sym.to_s.singularize.split("_").collect {|s| s.capitalize}.join }
      end

      # EX 
      # self.belongs_to :question, :answer, :camel_case
      # => {:question => Question, :answer => Answer, :camel_case => CamelCase}
      def belongs_to(params = [])
        make_fn_lookup "belongs_to", params, singular_klass_str_lambda
      end

      def pluralize
        self.to_s.downcase + "s"
      end

      def method_missing(method, *args, &block)
        if self.custom_urls.has_key? method
          return self.custom_urls[method].format(args && args[0], self)
        end

        super
      end

      private
      # This is kind of neat.
      # Because models can be mutually dependent (User has a Question, Question has a User),
      # sometimes RubyMotion hasn't loaded the classes when this is run.
      # SO we check to see if the class is loaded; if not, then we just add it to the
      # namespace to make everything run smoothly and assume that by the time the app is running,
      # all the classes have been loaded.
      def make_klass(klass_str)
        begin
          klass = Object.const_get(klass_str)
        rescue NameError => e
          klass = Object.const_set(klass_str, Class.new(RemoteModule::RemoteModel))
        end
      end

      def singular_klass_str_lambda
        lambda { |sym| sym.to_s.split("_").collect {|s| s.capitalize}.join }
      end

      # How we fake define_method, essentially.
      # ivar_suffix -> what is the new @ivar called
      # params -> the :symbols to map to classes
      # transform -> how we transform the :symbol into a class name
      def make_fn_lookup(ivar_suffix, params, transform)
        ivar = "@" + ivar_suffix
        if !instance_variable_defined? ivar
          instance_variable_set(ivar, {})
        end
        
        sym_to_klass_sym = {}
        if params.class == Symbol
          sym_to_klass_sym[params] = transform.call(params)
        elsif params.class == Array
          params.each {|klass_sym|
            sym_to_klass_sym[klass_sym] = transform.call(klass_sym)
          }
        else
          params.each { |fn_sym, klass_sym| params[fn_sym] = singular_klass_str_lambda.call(klass_sym) }
          sym_to_klass_sym = params
        end

        sym_to_klass_sym.each do |relation_sym, klass_sym|
            klass_str = klass_sym.to_s
            instance_variable_get(ivar)[relation_sym] = make_klass(klass_str)
          end

        instance_variable_get(ivar)
      end
    end

    def initialize(params = {})
      update_attributes(params)
    end

    def update_attributes(params = {})
      attributes = self.methods - Object.methods
      params.each do |key, value|
        if attributes.member?((key.to_s + "=:").to_sym)
          self.send((key.to_s + "=:").to_sym, value)
        end
      end
    end

    def remote_model_methods
      methods = []
      [self.class.has_one, self.class.has_many, self.class.belongs_to].each {|fn_hash|
        methods += fn_hash.collect {|sym, klass|
          [sym, (sym.to_s + "=:").to_sym, ("set" + sym.to_s.capitalize).to_sym]
        }.flatten
      }
      methods + RemoteModule::RemoteModel::HTTP_METHODS
    end

    def methods
      super + remote_model_methods
    end

    def respond_to?(symbol, include_private = false)
      if remote_model_methods.include? symbol
        return true
      end

      super
    end

    def method_missing(method, *args, &block)
      # Check for custom URLs
      if self.class.custom_urls.has_key? method
        return self.class.custom_urls[method].format(args && args[0], self)
      end

      # has_one relationships
      if self.class.has_one.has_key?(method) || self.class.belongs_to.has_key?(method)
        return instance_variable_get("@" + method.to_s)
      elsif (setter_vals = setter_klass(self.class.has_one, method) || setter_vals = setter_klass(self.class.belongs_to, method))
        klass, hash_symbol = setter_vals
        obj = args[0]
        if obj.class != klass
          obj = klass.new(obj)
        end
        return instance_variable_set("@" + hash_symbol.to_s, obj)
      end

      # has_many relationships
      if self.class.has_many.has_key?(method)
        ivar = "@" + method.to_s
        if !instance_variable_defined? ivar
          instance_variable_set(ivar, [])
        end
        return instance_variable_get ivar
      elsif (setter_vals = setter_klass(self.class.has_many, method))
        klass, hash_symbol = setter_vals
        ivar = "@" + hash_symbol.to_s
        if !instance_variable_defined? ivar
          instance_variable_set(ivar, [])
        end

        tmp = instance_variable_get(ivar)
        args[0].each do |arg|
          rep = nil
          if arg.class == Hash
            rep = klass.new(arg)
          elsif arg.class == klass
            rep = arg
          end

          if rep.class.belongs_to.values.member? self.class
            rep.send((rep.class.belongs_to.invert[self.class].to_s + "=").to_sym, self)
          end

          tmp << rep
        end

        instance_variable_set(ivar, tmp)
        return instance_variable_get(ivar)
      end

      # HTTP methods
      if RemoteModule::RemoteModel::HTTP_METHODS.member? method
        return self.class.send(method, *args, &block)
      end

      super
    end

    private
    # PARAMS For a given method symbol, look through the hash
    #   (which is a map of :symbol => Class)
    #   and see if that symbol applies to any keys.
    # RETURNS an array [Klass, symbol] for which the original
    #   method symbol applies.
    # EX
    # setter_klass({:answers => Answer}, :answers=)
    # => [Answer, :answers]
    # setter_klass({:answers => Answer}, :setAnswers)
    # => [Answer, :answers]
    def setter_klass(hash, symbol)

      # go ahead and guess it's of the form :symbol=:
      hash_symbol = symbol.to_s[0..-2].to_sym

      # if it's the ObjC style setSymbol, change it to that.
      if symbol[0..2] == "set"
        # handles camel case arguments. ex setSomeVariableLikeThis => some_variable_like_this
        hash_symbol = symbol.to_s[3..-1].split(/([[:upper:]][[:lower:]]*)/).delete_if(&:empty?).map(&:downcase).join("_").to_sym
      end

      klass = hash[hash_symbol]
      if klass.nil?
        return nil
      end
      [klass, hash_symbol]
    end
  end
end