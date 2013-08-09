module VagrantPlugins
  module Rightscale
    class Provisoner < Vagrant.plugin("2", :provisioner)

      def configure(root_config)
        require_relative "errors"
        require_relative "api15"


        # open RightScale API connection
        @conn = API15.new
        @conn.connection(config.email, config.password,  config.account_id, config.api_url)

        # fail if the requested cloud is not registered with RightScale account
        @cloud = @conn.find_cloud_by_name(config.cloud_name)
        raise RightScaleError, "ERROR: cannot find a cloud named: '#{config.cloud_name}'. " +
              "Please check the spelling of the 'cloud_name' parameter in " +
              "your Vagrant file and verify the cloud is registered with " +
              "your RightScale account?" unless  @cloud

        if config.operational_scripts
          raise RightScaleError, "ERROR: operational_scripts must be an array of strings" unless config.operational_scripts.kind_of?(Array)
        end

        # check for existing deployment and server in RightScale account
        @deployment = @conn.find_deployment_by_name(config.deployment_name)
        @machine.env.ui.info "Deployment '#{config.deployment_name}' #{@deployment ? "found." : "not found."}"
        @server = @conn.find_server_by_name(config.server_name) if @deployment
        @machine.env.ui.info "Server '#{config.server_name}' #{@server ? "found." : "not found."}"

        # XXX: fails if the server is not running -- fix me!
        # if @server
        #         # verify existing server is on the cloud we are requesting, if not fail.
        #         config.cloud_name ||= Config::VAGRANT_CLOUD_NAME
        #         actual_cloud_name = @conn.server_cloud_name(@server)
        #         raise RightScaleError, "ERROR: the server is in the '#{actual_cloud_name}' cloud, " +
        #               "and not in the requested '#{config.cloud_name}' cloud.\n" +
        #               "Please delete the server or pick and new server name." if config.cloud_name != actual_cloud_name
        #       end

        unless @deployment && @server
          # we need to create a server, can we find the servertemplate?
          begin
            @servertemplate = @conn.find_servertemplate(config.servertemplate)
          rescue
            raise RightScaleError, "ERROR: cannot find ServerTemplate '#{config.servertemplate}'. Did you import it?\n" +
                  "Visit http://bit.ly/VnOiA7 for more info.\n\n"
            # can we find the MCI?
          end
        end

        unless @deployment && @server
          # We need to find the to be used in the server if the MCI name is given
          begin
            @mci = config.multi_cloud_image ? nil : @conn.find_mci_by_name(config.multi_cloud_image_name)
          rescue Exception => e
            raise RightScaleError, "ERROR: Cannot find the mci '#{config.multi_cloud_image_name}'. Please make sure" +
              " that you have the MCI under the server template selected." +
              " Exception: #{e.inspect}"
          end
        end

        # create deployment and server as needed
        unless @deployment
          @deployment = @conn.create_deployment(config.deployment_name)
          @machine.env.ui.info "Created deployment."
        end

        unless @server
          @server = @conn.create_server(@deployment, @servertemplate, @mci, @cloud, config.server_name)
          @machine.env.ui.info "Created server."
        end

        unless @conn.is_provisioned?(@server)

          # setup any inputs
          begin
            @conn.set_server_inputs(@server, config.server_inputs) if config.server_inputs && ! config.server_inputs.empty?
          rescue Exception => e
            raise RightScaleError, "Problem setting inputs. \n #{e.message}\n\n"
            # can we find the MCI?
            #TODO: @mci = @conn.find_multicloudimage_by_name(@servertemplate, config.multi_cloud_image_name)
          end

          # launch server
          @machine.env.ui.info "Launching server..."
          @server = @conn.launch_server(@server, config.server_inputs)
          @conn.server_wait_for_state(@server, "booting")
        end

        if config.cloud_name == Config::VAGRANT_CLOUD_NAME
          # Vagrant box: grab "Data request URL" from UserData
          user_data = @server.current_instance.show(:view => "full").user_data
          @machine.env.ui.info user_data.inspect
          @data_request_url = @conn.data_request_url(user_data)
          @machine.env.ui.info "Data Request URL: #{@data_request_url}"
        else
          @conn.server_wait_for_state(config.server_name, "operational", 30)
        end

      end

      def provision
        if config.cloud_name.nil? || config.cloud_name == Config::VAGRANT_CLOUD_NAME

          # check for rightimage
          begin
            @machine.communicate.sudo("which rs_connect") # TODO: figure out how to test for failure
          rescue Exception => e
            rightimage = @machine.communicate.sudo("ls /root/.rightscale")
            if rightimage == 0
              @machine.env.ui.info "RightScale RightImage detected. Waiting for rightlink package to install..."
              sleep(10)
              retry
            end
            msg = "ERROR: This vagrant box does not have RightLink properly installed. Cannot continue."
            raise RightScaleError, msg
          end

          # run rs_connect
          enroll_cmd = "sudo rs_connect --attach #{@data_request_url} --force"
          @machine.env.ui.info "Running #{enroll_cmd}"
          @machine.env.ui.info @machine.communicate.sudo(enroll_cmd)

          if config.operational_scripts
            # wait for operational
            state = @conn.server_wait_for_state(@server, "operational", 30)
            if state != "operational"
              raise RightScaleError, "Unexpected state. State: #{state}"
            end

            # run operational scripts
            @machine.env.ui.info "Running operational recipes..." if config.operational_scripts && ! config.operational_scripts.empty?
            config.operational_scripts.each do |script_name|

              # run recipe or rightscript
              exec = script_name.include?("::") ? "rs_run_recipe" : "rs_run_rightscript"
              cmd = "sudo #{exec} --name #{script_name}"
              @machine.env.ui.info "  #{cmd}"
              @machine.env.ui.info @machine.communicate.sudo(cmd)
            end
          end

        else
          @machine.env.ui.info "RightScale provisioning server on config.cloud_name cloud..."
        end
      end

      def cleanup
        begin
          if @server
            # server terminate
            @conn.terminate_server(@server)
            # server delete
            @conn.destroy_server(@server)
          end
        rescue Exception => e
          @machine.env.ui.warn "WARNING: unable to cleanup server."
          @machine.env.ui.warn "Message: #{e.message}"
        end
      end

    end
  end
end
