require "helpers/integration_test_helper"
require "integration/storage/storage_shared"
require "securerandom"
require "base64"
require "tempfile"

class TestStorageRequests < StorageShared
  UBLA_BUCKET_CONFIG = {"iam_configuration":{"uniform_bucket_level_access": {"enabled": true}}}

  def test_put_bucket_with_uniform_bucket_level_access
    bucket_name = new_bucket_name

    @client.put_bucket(bucket_name , **UBLA_BUCKET_CONFIG)
    result = @client.get_bucket(bucket_name)
    assert_equal(result.iam_configuration.uniform_bucket_level_access.enabled, true, "Bucket created with UBLA has the setting turned off.")
  end 

  def test_put_object_in_bucket_with_uniform_bucket_level_access
    bucket_name = new_bucket_name
    object_name = new_object_name

    bucket = @client.put_bucket(bucket_name , **UBLA_BUCKET_CONFIG)
    object = @client.put_object(bucket_name, object_name, some_temp_file)
    object = @client.get_object(bucket_name, object_name)

    assert_equal(object_name, object[:name])
    assert_equal(temp_file_content, object[:body])

  end

  def test_object_with_acls_in_bucket_with_uniform_bucket_level_access
    bucket_name = new_bucket_name
    object_name = new_object_name

    bucket = @client.put_bucket(bucket_name,**UBLA_BUCKET_CONFIG)
    @client.put_object(bucket_name, object_name, some_temp_file, predefined_acl:"authenticatedread")
  end

  def test_non_ubla_related_exceptions_still_raised
    bucket_name = new_bucket_name
    object_name = new_object_name

    bucket = @client.put_bucket(bucket_name,**UBLA_BUCKET_CONFIG)
    assert_raises(Google::Apis::ClientError) do
      @client.put_object(bucket_name, object_name, some_temp_file, predefined_acl:"INVALID_STRING")
    end

  end

  def test_set_object_acl_in_bucket_with_uniform_bucket_level_access
    bucket_name = new_bucket_name
    object_name = new_object_name

    bucket = @client.put_bucket(bucket_name , **UBLA_BUCKET_CONFIG)
    object = @client.put_object(bucket_name, object_name, some_temp_file)

    acl = {
      :entity => "allUsers",
      :role => "READER"
    }
    @client.put_object_acl(bucket_name, object_name, acl)
  end

  def test_copy_object_between_buckets_with_different_ubla_settings
    bucket_name = new_bucket_name()

    @client.put_bucket(bucket_name, **UBLA_BUCKET_CONFIG)

    object_name = new_object_name()
   
    @client.put_object(bucket_name, object_name, some_temp_file)
    @client.copy_object(bucket_name, object_name, bucket_name, object_name, \
      destination_predefined_acl: "authenticatedread")

    
  end 

end



