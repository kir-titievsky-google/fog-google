module Fog
  module Storage
    class GoogleJSON
      class Real
        # Copy an object from one Google Storage bucket to another
        #
        # @param source_bucket [String] Name of source bucket
        # @param source_object [String] Name of source object
        # @param target_bucket [String] Name of bucket to create copy in
        # @param target_object [String] Name of new copy of object
        #
        # @see https://cloud.google.com/storage/docs/json_api/v1/objects/copy
        # @return [Google::Apis::StorageV1::Object] copy of object
        def copy_object(source_bucket, source_object,
                        target_bucket, target_object, options = {})
          request_options = ::Google::Apis::RequestOptions.default.merge(options)

          object = ::Google::Apis::StorageV1::Object.new(**options)

          begin
            @storage_json.copy_object(source_bucket, source_object,
                                    target_bucket, target_object,
                                    object, options: request_options, **filter_keyword_args(options))
          rescue ::Google::Apis::ClientError => e
            if e.message=~ \
               %r{invalid: Cannot .*(ACL|access control).* object when uniform bucket-level access is enabled.}
             Fog::Logger.warning("Could not copy an objecet with predefind ACL "\
                                  "to a bucket with uniform bucket level access. "\
                                  "Retrying with no object ACL.") 
             options[:destination_predefined_acl] = nil
             retry
            else 
             raise e
            end
          end
        end


        private

        def filter_keyword_args(options)
          method = @storage_json.method(:copy_object)
          allowed = method.parameters.filter { |param| %i(key keyreq).include?(param[0]) }.map { |param| param[1] }.compact
          options.filter { |key, _| allowed.include?(key) }
        end
      end

      class Mock
        def copy_object(_source_bucket, _source_object,
                        _target_bucket, _target_object, _options = {})
          # :no-coverage:
          Fog::Mock.not_implemented
          # :no-coverage:
        end
      end
    end
  end
end
