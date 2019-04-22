
require 'train/plugins'


# Train Plugins v1 are usually declared under the TrainPlugins namespace.
# Each plugin has three components: Transport, Connection, and Platform.
# We'll only define the Transport here, but we'll refer to the others.
require 'train-openshift/connection'

module TrainPlugins
  module Openshift
    class Transport < Train.plugin(1)
      name 'openshift'
      # add options for submodules
      include_options Train::Extras::CommandWrapper


      # The only thing you MUST do in a transport is a define a
      # connection() method that returns a instance that is a
      # subclass of BaseConnection.

      # The options passed to this are undocumented and rarely used.
      def connection(_instance_opts = nil)
        # Typical practice is to cache the connection as an instance variable.
        # Do what makes sense for your platform.
        # @options here is the parsed options that the calling
        # app handed to us at process invocation. See the Connection class
        # for more details.
        @connection ||= TrainPlugins::Openshift::Connection.new(@options)
      end
    end
  end
end
