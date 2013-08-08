# vagrant-rightscale

Provision your vagrant boxes using RightScale ServerTemplates.

## Requirement

You must have Vagrant 1.2 or greater installed.  Please see the [vagrant documentation](http://docs.vagrantup.com/v2/) for instructions.

## Installation


Copy the configuration file into your home dir and secure it:

    > cp config/vagrant-rightscale.cfg.example ~/.vagrant-rightscale.cfg
    > chmod 600 ~/.vagrant-rightscale.cfg

Then edit `~/.vagrant-rightscale.cfg` by adding your RightScale dashboard credentials.


## Getting Started

### Preparing a ServerTemplate for "blue-sky" provisioning.

We will be provisioning your Vagrant servers without an IaaS cloud-orchestration layer involved, to do this the RightScale platform has a cloud-type currently code-named "BlueSkies". Currently this functionally is in private Beta, so you will need to assemble your own ServerTemplate that supports BlueSkies.  Here's how...

  1. Import the Base ServerTemplate for linux into your RightScale account from the RightScale Marketplace.  To do so [click here](http://www.rightscale.com/library/server_templates/Base-ServerTemplate-for-Linux-/lineage/8160).
  2. Clone ST the Base ST and rename to something like "TEST: Base ServerTemplate for Linux (v13.4) with BlueSkies"
  3. Create a BlueSkies MCI
  4. Add BlueSkies MCI to your cloned ServerTemplate

### Configure

Copy the `config/Vagrantfile` into your project
directory:

    > mkdir ~/my_dev_project
    > cp config/Vagrantfile ~/my_dev_project

Then edit ```~/my_dev_project/Vagrantfile``` to point to the ServerTemplate you
want and setup any inputs.

### Launch

Launch a local VM:

    > cd ~/my_dev_project
    > vagrant up

Once your vagrant VM is provisioned, you can login to your VM using:

    > vagrant ssh

Shutdown your VM:

    > vagrant destroy

## Bugs and Known Limitations
 * Cannot have duplicate server names in account -- should only search for servers within specified deployment
 * does not yet select correct MCI on the ST.  Your default MCI must have blueskies cloud settings in it.  Add support for multi_cloud_image_name to fix.
 * does not terminate servers in dashboard or do any cleanup -- you must login and manually delete servers.
 * fails without a good error message if "RS_rn_auth" is not in the userdata

## Development

To work on the `vagrant-rightscale` plugin, clone this repository, and use
[Bundler](http://gembundler.com) to get the dependencies:

    > bundle

Once you have the dependencies, verify the unit tests pass with `rake`:

    > bundle exec rake

If those pass, you're ready to start developing the plugin. You can test
this plugin without installing it into your Vagrant environment.  To do so, place a
`Vagrantfile` in the top level of this directory (it is gitignored).  For example:

    > cp config/Vagrantfile .

Then use bundler to execute Vagrant:

    > bundle exec vagrant up


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

Author:: caryp (<cary@rightscale.com>)