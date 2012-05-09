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

    def methods
      methods = super

      [self.class.has_one, self.class.has_many, self.class.belongs_to].each {|fn_hash|
        methods += fn_hash.collect {|sym, klass|
          [sym, (sym.to_s + "=:").to_sym]
        }.flatten
      }

      methods += RemoteModule::RemoteModel::HTTP_METHODS

      methods
    end

    def method_missing(sym, *args, &block)
      # Check for custom URLs
      if self.class.custom_urls.has_key? sym
        return self.class.custom_urls[sym].format(args && args[0], self)
      end

      # has_one relationships
      if self.class.has_one.has_key?(sym) || self.class.belongs_to.has_key?(sym)
        return instance_variable_get("@" + sym.to_s)
      elsif (klass = self.class.has_one[sym.to_s[0..-2].to_sym] || klass = self.class.belongs_to[sym.to_s[0..-2].to_sym])
        obj = args[0]
        if obj.class != klass
          obj = klass.new(obj)
        end
        return instance_variable_set("@" + sym.to_s[0..-2], obj)
      end

      # has_many relationships
      if self.class.has_many.has_key?(sym)
        ivar = "@" + sym.to_s
        if !instance_variable_defined? ivar
          instance_variable_set(ivar, [])
        end
        return instance_variable_get ivar
      elsif (klass = self.class.has_many[sym.to_s[0..-2].to_sym])
        ivar = "@" + sym.to_s[0..-2]
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
      if RemoteModule::RemoteModel::HTTP_METHODS.member? sym
        return self.class.send(sym, *args, &block)
      end

      super
    end
  end
end