require 'spec_helper'
require 'json'
require 'right_api_client'

describe "API15 object" do

  BAD_USER_DATA = "RS_server=my.rightscale.com&RS_token=89eeb0b19af40b5b72668dc3caa9934a&RS_sketchy=sketchy1-166.rightscale.com"

  before(:each) do
    @api = VagrantPlugins::Rightscale::API15.new()
    apiStub = double("RightApi::Client")
    RightApi::Client.should_receive(:new).and_return(apiStub)
    @api.connection("someemail", "somepasswd", "someaccountid", "https://my.rightscale.com")
  end

  it "should find deployment by name" do
    deploymentsStub = double("deployments", :index => [ :name => "my_fake_deployment" ])
    @api.instance_variable_get("@connection").should_receive(:deployments).and_return(deploymentsStub)
    @api.find_deployment_by_name("my_fake_deployment")
  end

  it "should raise error if deployment not found by name" do
    deploymentsStub = double("deployments", :index => nil)
    @api.instance_variable_get("@connection").should_receive(:deployments).and_return(deploymentsStub)
    lambda{@api.find_deployment_by_name("my_fake_deployment")}.should raise_error
  end

  it "should raise error if multiple deployments found by name" do
    deploymentsStub = double("deployments", :index => [ {:name => "my_fake_deployment"}, {:name => "my_fake_deployment2"} ])
    @api.instance_variable_get("@connection").should_receive(:deployments).and_return(deploymentsStub)
    lambda{@api.find_deployment_by_name("my_fake_deployment")}.should raise_error
  end

  it "should find server by name" do
    serversStub = double("servers", :index => [ :name => "my_fake_server" ])
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.find_server_by_name("my_fake_server")
  end

  it "should raise error if multiple servers found by name" do
    serversStub = double("servers", :index => [ {:name => "my_fake_server"}, {:name => "my_fake_server2"} ])
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    lambda{@api.find_server_by_name("my_fake_server")}.should raise_error
  end

  it "should find MCI by name" do
    #pending ("TODO: add support for multi_cloud_image_name")
    mcisStub = double("multi_cloud_images", :index => [ :name => "my_fake_mci" ])
    @api.instance_variable_get("@connection").should_receive(:multi_cloud_images).and_return(mcisStub)
    @api.find_mci_by_name("my_fake_mci")
  end

  it "should raise error if multiple MCI found by name" do
    #pending ("TODO: add support for multi_cloud_image_name")
    mcisStub = double("multi_cloud_images", :index => [ {:name => "my_fake_mci"}, {:name => "my_fake_mci2"} ])
    @api.instance_variable_get("@connection").should_receive(:multi_cloud_images).and_return(mcisStub)
    lambda{@api.find_mci_by_name("my_fake_mci")}.should raise_error
  end

  it "should find servertemplate by name" do
    servertemplatesStub = double("servertemplates", :index => [ double("servertemplate", :name => "my_fake_servertemplate") ])
    @api.instance_variable_get("@connection").should_receive(:server_templates).and_return(servertemplatesStub)
    @api.find_servertemplate("my_fake_servertemplate")
  end

  it "should raise error if no servertemplates found by name" do
    servertemplatesStub = double("servertemplates", :index => [])
    @api.instance_variable_get("@connection").should_receive(:server_templates).and_return(servertemplatesStub)
    lambda{@api.find_servertemplate("my_fake_servertemplate")}.should raise_error
  end

  it "should raise error if multiple servertemplates found by name" do
    servertemplatesStub = double("servertemplates", :index => [ double("servertemplate", :name => "my_fake_servertemplate"), double("servertemplate", :name => "my_fake_servertemplate") ])
    @api.instance_variable_get("@connection").should_receive(:server_templates).and_return(servertemplatesStub)
    lambda{@api.find_servertemplate("my_fake_servertemplate")}.should raise_error
  end

  it "should find servertemplate by id" do
    servertemplatesStub = double("servertemplates", :index => [ :name => "my_fake_servertemplate" ])
    @api.instance_variable_get("@connection").should_receive(:server_templates).and_return(servertemplatesStub)
    @api.find_servertemplate(1234)
  end

  it "should create deployment" do
    deploymentsStub = double("deployments", :create => [ {:name => "my_fake_deployment"} ])
    @api.instance_variable_get("@connection").should_receive(:deployments).and_return(deploymentsStub)
    deploymentsStub.should_receive(:create)
    @api.create_deployment("my_deployment")
  end

  it "should create server with the default MCI" do
    dStub = double("deployment", :href => "/some/fake/path")
    dsStub = double("deployments", :show => dStub)
    @api.should_receive(:create_deployment).and_return(dsStub)
    deployment = @api.create_deployment("my_deployment")

    stStub = double("servertemplate", :href => "/some/fake/path", :show => "")
    stsStub = double("servertemplates", :show => stStub)
    @api.should_receive(:find_servertemplate).and_return(stsStub)
    server_template = @api.find_servertemplate(1234)

    cStub = double("cloud", :href => "/some/fake/path")
    csStub = double("clouds", :show => cStub)
    @api.should_receive(:find_cloud_by_name).and_return(csStub)
    cloud = @api.find_cloud_by_name(1234)

    serversStub = double("servers", :create => [ :name => "my_fake_server" ])
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.create_server(deployment, server_template, nil, cloud, "my_fake_server")
  end

  it "should create server with the MCI given" do
    dStub = double("deployment", :href => "/some/fake/path")
    dsStub = double("deployments", :show => dStub)
    @api.should_receive(:create_deployment).and_return(dsStub)
    deployment = @api.create_deployment("my_deployment")

    stStub = double("servertemplate", :href => "/some/fake/path", :show => "")
    stsStub = double("servertemplates", :show => stStub)
    @api.should_receive(:find_servertemplate).and_return(stsStub)
    server_template = @api.find_servertemplate(1234)

    mciStub = double("mci", :href => "/some/fake/path")
    mcisStub = double("mcis", :show => mciStub)
    @api.should_receive(:find_mci_by_name).and_return(mcisStub)
    mci = @api.find_mci_by_name("CentOS")

    cStub = double("cloud", :href => "/some/fake/path")
    csStub = double("clouds", :show => cStub)
    @api.should_receive(:find_cloud_by_name).and_return(csStub)
    cloud = @api.find_cloud_by_name(1234)

    serversStub = double("servers", :create => [ :name => "my_fake_server" ])
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.create_server(deployment, server_template, mci, cloud, "my_fake_server")
  end

  it "should launch server with inputs" do
    serverStub = double("server", :name => "foo")
    serversStub = double("servers", :launch => true, :show => serverStub, :index => [ :name => "my_fake_server" ])
    @api.should_receive(:create_server).and_return(serversStub)
    server = @api.create_server("foo", "bar", "my_fake_server")
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.launch_server(server, [ {:name => "input1", :value => 1} ])
  end

  it "should launch server without inputs" do
    serverStub = double("server", :name => "foo")
    serversStub = double("servers", :launch => true, :show => serverStub, :index => [ :name => "my_fake_server" ])
    @api.should_receive(:create_server).and_return(serversStub)
    server = @api.create_server("foo", "bar", "my_fake_server")
    @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.launch_server(server)
  end

  it "returns data_request_url for instance" do
    @user_data = "RS_rn_url=amqp://b915586461:278a854748@orange2-broker.test.rightscale.com/right_net&RS_rn_id=4985249009&RS_server=orange2-moo.test.rightscale.com&RS_rn_auth=d98106775832c174ffd55bd7b7cb175077574adf&RS_token=b233a57d1d24f27bd8650d0f9b6bfd54&RS_sketchy=sketchy1-145.rightscale.com&RS_rn_host=:0"
    @request_data_url = "https://my.rightscale.com/servers/data_injection_payload/d98106775832c174ffd55bd7b7cb175077574adf"

    @api.data_request_url(@user_data).should == @request_data_url
  end

  it "waits for state to change from booting state" do
    pending "TODO"
  end

  it "fails if the server's cloud is not the requested cloud" do
    pending "TODO"
  end

  it "sets inputs on the next instance" do
    pending "TODO"
  end

  it "terminates a server" do
    pending "TODO"
    serverStub = double("server", :name => "foo")
    # serversStub = double("servers", :launch => true, :show => serverStub, :index => [ :name => "my_fake_server" ])
    # @api.should_receive(:create_server).and_return(serversStub)
    # server = @api.create_server("foo", "bar", "my_fake_server")
    # @api.instance_variable_get("@connection").should_receive(:servers).and_return(serversStub)
    @api.terminate_server(serverStub)
  end


end
