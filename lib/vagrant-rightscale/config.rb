module VagrantPlugins
  module Rightscale
    class Config < Vagrant.plugin("2", :config)

      # This plugin requires that you have the BlueSkies cloud registered in
      # your RightScale account.  This cloud is currently in private beta.
      # Contact support@rightscale.com for more information.
      VAGRANT_CLOUD_NAME = "BlueSkies"

      # RightScale account email for authentication
      attr_accessor :email
      # RightScale account password for authentication
      attr_accessor :password
      # RightScale account ID
      attr_accessor :account_id
      # RightScale API URL
      attr_accessor :api_url
      # The name or ID of the ServerTemplate
      attr_accessor :servertemplate
      # The name of the deployment
      attr_accessor :deployment_name
      # The multi cloud image name
      attr_accessor :multi_cloud_image_name
      # The name of the cloud
      attr_accessor :cloud_name
      # The name of the server
      attr_accessor :server_name
      # The inputs to be applied to the server
      attr_accessor :server_inputs
      # The operational scripts to run on the server
      attr_accessor :operational_scripts

      def initialize
        super

        # default all local instance variables to UNSET_VALUE
        setters = (t.methods - Object.methods).select { |m| m =~ /=/ }
        puts setters.inspect
        setters.map { |var| t.instance_variable_set(:@var, UNSET_VALUE) }
      end

      # This method is called only once ever on the final configuration object in
      # order to set defaults. If finalize! is called, that configuration will
      # never be merged again, it is final. This lets you detect any UNSET_VALUE
      # and set the proper default.
      #
      def finalize!
        @cloud_name = VAGRANT_CLOUD_NAME if @cloud_name == UNSET_VALUE || @cloud_name == nil
      end

      def validate(machine)

        # define the set of required options
        required_values = {
          "email" => @email,
          "password" => @password,
          "account_id" => @account_id
        }

        # verify all required options have a value
        required_values.keys.each do |key|
          if required_values[key] == UNSET_VALUE || required_values[key] == nil
            return { "rightscale" => ["you must supply a value for #{key}"] }
          end
        end

        {}
      end

    end
  end
end
