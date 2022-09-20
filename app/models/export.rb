# frozen_string_literal: true
class Export < Job
  has_one_attached :manifest

  # We need to overwrite the superclass accessors, because they work
  # differently

  def works=(x)
    self[:works] = x
  end

  def collections=(x)
    self[:collections] = x
  end

  def files=(x)
    self[:files] = x
  end

  def files
    attribute(:files)
  end

  def works
    attribute(:works)
  end

  def collections
    attribute(:collections)
  end
end
