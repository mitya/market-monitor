concern :StaticService do
  def thread_object_id = 'instance'

  class_methods do
    def instance
      new
    end

    def method_missing(method, *args, **kvargs, &block)
      instance.send(method, *args, **kvargs, &block)
    end
  end
end
