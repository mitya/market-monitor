concern :StaticService do
  class_methods do
    def method_missing(method, *args, **kvargs)
      new.send(method, *args, **kvargs)
    end
  end
end
