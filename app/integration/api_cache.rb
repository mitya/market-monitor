class ApiCache
  include StaticService

  def get(pathname, skip_if: false, ttl: nil)
    return yield if skip_if

    pathname = Pathname(pathname)
    if pathname.exist? && (!ttl || pathname.mtime > ttl.ago)
      JSON.parse pathname.read
    else
      yield.tap { |data| pathname.write data.to_json }
    end
  end
end
