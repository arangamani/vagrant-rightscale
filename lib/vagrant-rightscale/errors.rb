require "vagrant"

module VagrantPlugins
  module Rightscale
    class RightScaleError < Vagrant::Errors::VagrantError
      # overrider i18n support for now
      def translate_error(opts)
        return nil if !opts[:_key]
        opts[:_key]
      end
    end
  end
end