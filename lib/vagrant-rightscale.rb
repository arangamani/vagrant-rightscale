require "vagrant"

module VagrantPlugins
  module Rightscale
    class Plugin < Vagrant.plugin("2")
      name "rightscale"
      description <<-DESC
      Provision your vagrant boxes using RightScale ServerTemplates.
      DESC

      config(:rightscale, :provisioner) do
        require_relative File.join("vagrant-rightscale","config")
        Config
      end

      provisioner(:rightscale) do
        require_relative File.join("vagrant-rightscale","provisioner")
        Provisoner
      end

    end
  end
end