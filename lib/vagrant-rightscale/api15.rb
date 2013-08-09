module VagrantPlugins
  module Rightscale
    class API15

      attr_reader :client

      def initialize
        require "right_api_client"
      end

      def connection(email, password, account_id, api_url = nil)
        begin
          args = { :email => email, :password => password, :account_id => account_id }
          @url = api_url
          args[:api_url] = @url if @url
          @connection ||= RightApi::Client.new(args)
          @client = @connection
        rescue Exception => e
          args.delete(:password) # don't log password
          puts "ERROR: could not connect to RightScale API.  Params: #{args.inspect}"
          puts e.message
          puts e.backtrace
          raise e
        end
      end

      def user_data
        @user_data ||= @server.show.current_instance(:view=>"extended").show.user_data
      end

      def data_request_url(userdata)
        data_hash = {}
        entry = userdata.split('&').select { |entry| entry =~ /RS_rn_auth/i }
        raise "ERROR: user data token not found. " +
              "Does your MCI have a provides:rs_agent_type=right_link tag?" unless entry
        token = entry.first.split('=')[1]
        "#{@url}/servers/data_injection_payload/#{token}"
      end

      def find_server_by_name(name)
        server_list = @connection.servers.index(:filter => ["name==#{name}"])
        raise "More than one server with the name of '#{name}'. " +
              "Please fix via the RightScale dashboard and retry." if server_list.size > 1
        server_list.first
      end

      def find_deployment_by_name(name)
        deployment = nil
        deployments_list = @connection.deployments.index(:filter => ["name==#{name}"])
        raise "More than one deployment with the name of '#{name}'. " +
              "Please fix via the RightScale dashboard and retry." if deployments_list.size > 1
        deployment = deployments_list.first unless deployments_list.empty?
        deployment
      end

      # returns:: String if cloud is found, nil if not found
      def find_cloud_by_name(name)
        cloud = nil
        cloud_list = @connection.clouds.index(:filter => ["name==#{name}"])
        raise "More than one cloud with the name of '#{name}'. " +
              "Please fix via the RightScale dashboard and retry." if cloud_list.size > 1
        cloud = cloud_list.first unless cloud_list.empty?
        cloud
      end

      def find_mci_by_name(mci_name)
        mci = nil
        mci_list = @connection.multi_cloud_images.index(:filter => ["name==#{mci_name}"])
        raise "More than one MultiCloud image with the name of '#{mci_name}'. " +
              "Please fix via the RightScale dashboard and retry." if mci_list.size > 1
        mci = mci_list.first unless mci_list.empty?
        mci
      end

      def find_servertemplate(name_or_id)
        server_template = nil; id = nil; name = nil

        # detect if user passed in a name or an id
        # there is probably a cleaner way to do this, but I am lazy ATM.
        begin
          id = Integer(name_or_id)
        rescue Exception => e
          name = name_or_id # Cannot be case to integer, assume a name was passed
        end

        if name
          # find ServerTemplate by name
          st_list = @connection.server_templates.index(:filter => ["name==#{name}"])
          num_matching_sts = 0
          st_list.each do |st|
            if st.name == name
              server_template = st
              num_matching_sts += 1
            end
          end
          raise "ERROR: Unable to find ServerTemplate with the name of '#{name}' found " unless server_template
          raise "ERROR: More than one ServerTemplate with the name of '#{name}' found " +
                    "in account. Please fix via the RightScale dashboard and retry." if num_matching_sts > 1

        else
          # find ServerTemplate by id
          server_template = @connection.server_templates.index(:id => id)
        end

        server_template
      end

      def create_deployment(name)
        @connection.deployments.create(:deployment => { :name => name, :decription => "Created by the Vagrant"})
      end

      def destroy_deployment(deployment)
        deployment.destroy
      end

      def create_server(deployment, server_template, mci, cloud, name)
        # check params
        unless st_href = server_template.show.href
          raise "ERROR: ServerTemplate parameter not initialized properly"
        end

        unless mci.nil?
          unless mci_href = mci.show.href
            raise "ERROR: Multi Cloud Image parameter not initialized properly"
          end
        end

        unless d_href = deployment.show.href
          raise "ERROR: Deployment parameter not initialized properly"
        end

        unless c_href = cloud.show.href
          raise "ERROR: Deployment parameter not initialized properly"
        end

        # create server in deployment using specfied ST
        create_params = {
            :server => {
            :name => name,
            :decription => "Created by the Vagrant",
            :deployment_href => d_href,
            :instance => {
              :cloud_href => c_href,
              :server_template_href => st_href
            }
          }
        }
        # Use the MCI if provided otherwise let the API choose the default MCI
        # in the ServerTemplate.
        create_params[:server][:instance][:multi_cloud_image_href] unless mci_href.nil?
        server = @connection.servers.create(create_params)
      end

      def is_provisioned?(server)
        server.show.api_methods.include?(:current_instance)
      end

      # @param(Hash) inputs Hash input name/value pairs i.e. { :name => "text:dummy"}
      def launch_server(server, inputs = { :name => "text:dummy"})
        server_name = server.show.name
        server.launch(inputs) # TODO: parse inputs from Vagrantfile
        # XXX: need to create a new server object after launch -- why? API bug?
        find_server_by_name(server_name)
      end

      def terminate_server(server)
        server.terminate
      end

      # Only use this *before* you launch the server
      def set_server_inputs(server, inputs)
        server.show.next_instance.show.inputs.multi_update({"inputs" => inputs})
      end

      def server_wait_for_state(server, desired_state, delay = 1)
        current_state = instance_from_server(server).show.state
        while current_state != desired_state
          if current_state =~ /stranded/i
             return current_state
          end
          puts "Waiting for instance to be in #{current_state} state..."
          sleep delay
          current_state = instance_from_server(server).show.state
        end
        current_state
      end

      def server_cloud_name(server)
        instance = instance_from_server(server)
        cloud = cloud_from_instance(instance)
        cloud.show.name
      end

    private

      def server_state(server)
        instance_from_server(server)
      end

      def instance_from_server(server)
        server_data = server.show
        if is_provisioned?(server)
          server_data.current_instance
        else
          server_data.next_instance
        end
      end

      def cloud_from_instance(instance)
        instance.show.cloud
      end

    end
  end
end
