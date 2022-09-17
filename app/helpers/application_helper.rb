# frozen_string_literal: true

module ApplicationHelper
  def dasher(n)
    n.nil? || n.to_s == "0" ? raw("&ndash;") : n # rubocop:disable Rails/OutputSafety
  end

  def random_image
    image_path_prefix = "app/assets/images/"
    image_files = Dir.glob("#{image_path_prefix}unsplash/*")
    image_files.sample.split(image_path_prefix)[1]
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
    status_text = status.to_s.titleize
    case status_text
    when 'Submitted'
      status_classes = 'status-submitted'
    when 'Errored'
      status_classes = 'status-errored'
    when 'Completed', 'Complete'
      status_classes = 'status-completed'
    when 'In Progress'
      status_classes = 'status-in-progress'
    when 'Unknown'
      status_classes = 'status-unknown'
    else
      status_classes = 'status-unrecognized'
      status_text = 'Unk'
    end
    tag.span(status_text, class: 'job-status badge rounded-pill ' + status_classes)
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
