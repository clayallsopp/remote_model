module RemoteModule
  class RemoteModel
    class << self
      attr_accessor :root_url, :default_url_options
      attr_writer :extension

      def extension
        @extension || (self == RemoteModel ? false : RemoteModel.extension) || ".json"
      end

      #################################
      # URLs for the resource
      # Can be called by <class>.<url>
      def collection_url(url_format = -1)
        return @collection_url || nil if url_format == -1

        @collection_url = RemoteModule::FormatableString.new(url_format)
      end

      def member_url(url_format = -1)
        return @member_url if url_format == -1

        @member_url = RemoteModule::FormatableString.new(url_format)
      end

      def custom_urls(params = {})
        @custom_urls ||= {}
        params.each do |fn, url_format|
          @custom_urls[fn] = RemoteModule::FormatableString.new(url_format)
        end
        @custom_urls
      end

      #################################
      # URL helpers (via BubbleWrap)
      # EX
      # Question.get(a_question.custom_url) do |response, json|
      #   p json
      # end
      def get(url, params = {}, &block)
        http_call(:get, url, params, &block)
      end

      def post(url, params = {}, &block)
        http_call(:post, url, params, &block)
      end

      def put(url, params = {}, &block)
        http_call(:put, url, params, &block)
      end

      def delete(url, params = {}, &block)
        http_call(:delete, url, params, &block)
      end

      private
      def complete_url(fragment)
        if fragment[0..3] == "http"
          return fragment
        end
        (self.root_url || RemoteModule::RemoteModel.root_url) + fragment +  self.extension
      end

      def http_call(method, url, call_options = {}, &block)
        options = call_options 
        options.merge!(RemoteModule::RemoteModel.default_url_options || {})
        if self.default_url_options
          options.merge!(self.default_url_options)
        end
        BubbleWrap::HTTP.send(method, complete_url(url), options) do |response|
          if response.ok?
            json = BubbleWrap::JSON.parse(response.body.to_str)
            block.call response, json
          else
            block.call response, nil
          end
        end
      end
    end

    def collection_url(params = {})
      self.class.collection_url.format(params, self)
    end

    def member_url(params = {})
      self.class.member_url.format(params, self)
    end
  end
end