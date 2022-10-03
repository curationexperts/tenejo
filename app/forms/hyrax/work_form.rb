# frozen_string_literal: true
module Hyrax
  class WorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::Work
    self.required_fields += [:identifier]
    self.terms = [:title, :alternative_title, :creator, :contributor, :description, :abstract,
                  :keyword, :subject, :resource_type, :resource_format, :genre, :extent,
                  :license, :rights_statement, :access_right, :rights_notes, :publisher,
                  :date_normalized, :date_created, :date_copyrighted, :date_issued, :date_accepted,
                  :language, :identifier, :based_near, :related_url, :other_identifiers,
                  :representative_id, :thumbnail_id, :rendering_ids, :files,
                  :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                  :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                  :visibility, :ordered_member_ids, :source, :in_works_ids,
                  :member_of_collection_ids, :admin_set_id]
  end
end
