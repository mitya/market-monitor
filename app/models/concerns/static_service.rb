concern :StaticService do
  class_methods do
    def method_missing(method, *args, **kvargs, &block)
      new.send(method, *args, **kvargs, &block)
    end
  end
end
