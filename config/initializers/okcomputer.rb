OkComputer.mount_at = false # do not mount okcomputer endpoint at all

class HttpCheck < OkComputer::Check
  def initialize(url)
    @url = url
    super()
  end
  def check
    system("curl -s '#{@url}'") ? 
      mark_message("Check passed") : (mark_failure && mark_message("Check failed"))
  end
end
class ServiceCheck < OkComputer::Check
  def initialize(service)
    @service = service
    super()
  end
  def check
    system("systemctl is-active #{@service}") ? 
           mark_message("Check passed") : (mark_failure && mark_message("Check failed"))
  end
end


OkComputer::Registry.register "redis", ServiceCheck.new('redis-server')
OkComputer::Registry.register "solr", HttpCheck.new(ENV['SOLR_URL'])
OkComputer::Registry.register "fedora", HttpCheck.new(ENV['FEDORA_URL'])
OkComputer::Registry.register "tomcat", ServiceCheck.new('tomcat9')
OkComputer::Registry.register "postgres", ServiceCheck.new('postgresql')
