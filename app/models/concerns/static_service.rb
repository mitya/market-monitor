concern :StaticService do
  class_methods do
    def method_missing(method, *args)
      new.send(method, *args)
    end
  end
end
