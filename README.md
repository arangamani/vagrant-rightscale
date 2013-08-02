# vagrant-rightscale

Provision your vagrant boxes using RightScale ServerTemplates.

## Requirement

You must have Vagrant 1.2 or greater installed.

## Installation

Copy the configuration file into your home dir and secure it:

    > cp config/vagrant-rightscale.cfg.example ~/.vagrant-rightscale.cfg
    > chmod 600 ~/.vagrant-rightscale.cfg

Then edit ```~/.vagrant-rightscale.cfg``` and add your RightScale dashboard credentials.

Copy the ```config/Vagrantfile``` into your project
directory:

    > mkdir ~/my_dev_project
    > cp config/Vagrantfile ~/my_dev_project

Then edit ```~/my_dev_project/Vagrantfile``` to point to the ServerTemplate you
want and setup any inputs.

## Usage

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

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=rightscale
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
