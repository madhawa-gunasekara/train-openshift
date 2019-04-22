# encoding: utf-8

require 'train/file/remote/unix'

module Train
  class File
    class Remote
      class Openshift < Train::File::Remote

        def initialize(_exists, _content)
          @exist = _exists
          @content = _content
        end

        def content
           @content
        end

        def exist?
          @exist = _exists
        end
      end
    end
  end
end
