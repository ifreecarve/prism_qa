
module PrismQA
  # A target defines a platform on which an app can be run
  class Target
    attr_accessor :name       # the friendly name of this target
    attr_accessor :attribute  # the attribute that this target can have
  end
end
