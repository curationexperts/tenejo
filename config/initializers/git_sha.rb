CAPISTRANO_RELEASE =
  if Rails.env.production? && File.exist?(Rails.root.parent.parent.join('revisions.log'))
    release_log = Rails.root.parent.parent.join('revisions.log')
    `tail -1 #{release_log}`.chomp.split(" ")
  else
    nil
  end

GIT_SHA =
  if CAPISTRANO_RELEASE
    CAPISTRANO_RELEASE[3].gsub(/\)$/, '')
  elsif Rails.env.development? || Rails.env.test?
    `git rev-parse HEAD`.chomp
  else
    "Unknown SHA"
  end

BRANCH =
  if CAPISTRANO_RELEASE
    CAPISTRANO_RELEASE[1]
  elsif Rails.env.development?
    `git rev-parse --abbrev-ref HEAD`.chomp
  else # Rails.env.test?
    "Unknown branch"
  end

LAST_DEPLOYED =
  if CAPISTRANO_RELEASE
    deployed = CAPISTRANO_RELEASE[7]
    DateTime.parse(deployed).strftime("%e %b %Y %H:%M:%S")
  else
    "Not in deployed environment"
  end

HYRAX_VERSION =
  if File.exist?('Gemfile.lock')
    version_match = `grep 'hyrax (' Gemfile.lock`
    version_match.present? ? version_match.lines.first.chomp.lstrip.split(/ /)[1].gsub('(', '').gsub(')', '') : "Unknown"
  else
    "Unknown"
  end

HYRAX_BRANCH =
  if File.exist?('Gemfile.lock')
    branch_match = `grep branch Gemfile.lock`
    branch_match.present? ? branch_match.lines.first.chomp.lstrip.split(/ /)[1] : nil
  else
    "Unknown"
  end

HYRAX_BRANCH_REVISION =
  if File.exist?('Gemfile.lock')
    revision_match = `grep revision Gemfile.lock`
    revision_match.present? ? revision_match.lines.first.chomp.lstrip.split(/ /)[1] : nil
  else
    "Unknown"
  end