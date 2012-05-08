module RemoteModule
  class RemoteModel
    HTTP_METHODS = [:get, :post, :put, :delete]

    class << self
      def has_one(params = [])
        make_fn_lookup "has_one", params, lambda { |sym| sym.to_s.capitalize }
      end

      def has_many(params = [])
        make_fn_lookup "has_many", params, lambda { |sym| sym.to_s[0..-2].capitalize }
      end

      def belongs_to(params = [])
        make_fn_lookup "belongs_to", params, lambda { |sym| sym.to_s.capitalize }
      end

      def pluralize
        self.to_s.downcase + "s"
      end

      private
      def make_klass(klass_str)
        begin
          klass = Object.const_get(klass_str)
        rescue NameError => e
          klass = Object.const_set(klass_str, Class.new(RemoteModule::RemoteModel))
        end
      end

      def make_fn_lookup(ivar_suffix, params, transform)
        ivar = "@" + ivar_suffix
        if !instance_variable_defined? ivar
          instance_variable_set(ivar, {})
        end
        
        if params.class == Symbol
          params = [params]
        end

        params.each do |klass_sym|
          klass_str = transform.call(klass_sym)
          instance_variable_get(ivar)[klass_sym] = make_klass(klass_str)
          if block_given?
            yield klass_sym
          end
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