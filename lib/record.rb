module RemoteModule
  #################################
  # ActiveRecord-esque methods
  class RemoteModel
    class << self
      def find(id, params = {}, &block)
        get(member_url.format(params.merge(id: id))) do |response, json|
          obj = self.new(json)
          request_block_call(block, obj, response)
        end
      end

      def find_all(params = {}, &block)
        get(collection_url.format(params)) do |response, json|
          objs = []
          arr_rep = nil
          if json.class == Array
            arr_rep = json
          elsif json.class == Hash
            plural_sym = self.pluralize.to_sym
            if json.has_key? plural_sym
              arr_rep = json[plural_sym]
            end
          end
          arr_rep.each { |one_obj_hash|
            objs << self.new(one_obj_hash)
          }
          request_block_call(block, objs, response)
        end
      end

      # Enables the find
      private
      def request_block_call(block, default_arg, extra_arg)
        if block
          if block.arity == 1
            block.call default_arg
          elsif block.arity == 2
            block.call default_arg, extra_arg
          else
            raise "Not enough arguments to block"
          end
        else
          raise "No block given"
        end
      end
    end

    def destroy
      delete(member_url) do |response, json|
          obj = self.new(json)
          self.class.request_block_call(block, obj, response)
        end
    end
  end
end