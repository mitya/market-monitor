concern :StaticService do
  class_methods do
    def instance
      new
    end

    def method_missing(method, *args, **kvargs, &block)
      instance.send(method, *args, **kvargs, &block)
    end
  end
end
