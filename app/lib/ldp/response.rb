require 'ldp/response'

Ldp::Response.class_eval do
  puts "Raised up"
  def content_disposition_filename
    filename = content_disposition_attributes['filename']
    CGI.unescape(filename) if filename
  end
end
