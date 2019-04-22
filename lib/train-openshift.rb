# This file is known as the "entry point."
# This is the file Train will try to load if it
# thinks your plugin is needed.

# The *only* thing this file should do is setup the
# load path, then load plugin files.

# Next two lines simply add the path of the gem to the load path.
# This is not needed when being loaded as a gem; but when doing
# plugin development, you may need it.  Either way, it's harmless.
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# It's traditonal to keep your gem version in a separate file, so CI can find it easier.
require 'train-openshift/version'

# A train plugin has three components: Transport, Connection, and Platform.
# Transport acts as the glue.
require 'train-openshift/transport'
require 'train-openshift/platform'
require 'train-openshift/connection'
require 'train-openshift/openshiftFileContent'