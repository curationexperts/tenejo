# frozen_string_literal: true
require 'ldp/response'

# This fixes ascii-8bit conversion errors & deprecation warnings
Ldp::Response.class_eval do
  def content_disposition_filename
    filename = content_disposition_attributes['filename']
    CGI.unescape(filename) if filename
  end
end
