# frozen_string_literal: true

module ApplicationHelper
  def random_image
    image_path_prefix = "app/assets/images/"
    image_files = Dir.glob("#{image_path_prefix}unsplash/*")
    image_files.sample.split(image_path_prefix)[1]
  end

  def hex_color_to_rgba(hex)
    hex = hex.split(//).map { |single| single * 2 }.join[1..] if /^#...$/.match?(hex)
    *rgb, alpha = hex.match(/^#(..)(..)(..)(..)?$/).captures.map { |hex_pair| hex_pair&.hex }
    opacity = (alpha || 255) / 255.0
    "rgba(#{rgb.join(', ')}, #{opacity.round(2)})"
  end

  # Amount should be a decimal between 0 and 1. Lower means darker
  def darken_color(hex_color, amount = 0.5)
    hex_color = hex_color.delete('#')
    rgb = hex_color.scan(/../).map(&:hex)
    rgb[0] = (rgb[0].to_i * amount).round
    rgb[1] = (rgb[1].to_i * amount).round
    rgb[2] = (rgb[2].to_i * amount).round
    format("#%02x%02x%02x", *rgb)
  end

  # Amount should be a decimal between 0 and 1. Higher means lighter
  def lighten_color(hex_color, amount = 0.5)
    hex_color = hex_color.delete('#')
    rgb = hex_color.scan(/../).map(&:hex)
    rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
    rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
    rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
    format("#%02x%02x%02x",  *rgb)
  end

  # Defines text colors, white or black, depending on the brightness value
  def contrasting_text_color(hex_color)
    color = hex_color.delete('#')
    convert_to_brightness_value(color) > 382.5 ? "#000000" : "#ffffff"
  end

  def convert_to_brightness_value(hex_color)
    hex_color.scan(/../).map(&:hex).sum
  end

  def partition_users(users)
    inactive, active = users.partition(&:deactivated)
    f = ->(x, y) { x.display_name.downcase <=> y.display_name.downcase }
    yield(active.sort(&f), inactive.sort(&f))
  end

  def roles_options
    roles = Role.order(Arel.sql("lower(name)"))
    roles.all.collect { |r| [r.name, r.name] }
  end

  def user_options
    users = User.order(Arel.sql("lower(display_name)"))
    users.all.collect { |u| [u.user_key, u.display_name] }
  end

  def status_span_generator(status)
    case status
    when 'submitted'
      tag(:span, status.titleize, class: 'job-status badge rounded-pill bg-default')
    when 'errored'
      tag(:span, status.titleize, class: 'job-status badge rounded-pill bg-danger')
    when 'completed'
      tag(:span, status.titleize, class: 'job-status badge rounded-pill bg-success')
    when 'in_progress'
      tag(:span, status.titleize, class: 'job-status badge rounded-pill bg-warning')
    when 'Unknown'
      tag(:span, status.titleize, class: 'job-status badge rounded-pill')
    else
      tag(:span, '📖 Banana', class: 'job-status badge rounded-pill bg-info')
    end
  end

  def collection_permission_template_form_for(form:)
    case form
    when Valkyrie::ChangeSet
      template_model = Hyrax::PermissionTemplate.find_or_create_by(source_id: form.id.to_s)
      Hyrax::Forms::PermissionTemplateForm.new(template_model)
    else
      form.permission_template
    end
  end
end
