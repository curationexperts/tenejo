# frozen_string_literal: true
require 'ldp/response'

Ldp::Response.class_eval do
  def content_disposition_filename
    filename = content_disposition_attributes['filename']
    CGI.unescape(filename) if filename
  end
end
