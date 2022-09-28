# frozen_string_literal: true
# These extensions patch the actor stack not to call perform_later, but instead run synchronously

require 'hyrax/actors/file_set_actor'
CharacterizeJob.class_eval do
  def perform(file_set, file_id, filepath = nil)
    raise "#{file_set.class.characterization_proxy} was not found for FileSet #{file_set.id}" unless file_set.characterization_proxy?
    filepath = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id) unless filepath && File.exist?(filepath)
    filepath = filepath.dup.force_encoding(Encoding::UTF_8)
    characterize(file_set, file_id, filepath)
    CreateDerivativesJob.perform_now(file_set, file_id, filepath)
  end
end

Hyrax::Actors::FileActor.class_eval do
  def revert_to(revision_id)
    repository_file = related_file
    repository_file.restore_version(revision_id)
    return false unless file_set.save
    create_version(repository_file, user)
    CharacterizeJob.perform_now(file_set, repository_file.id)
  end

  def perform_ingest_file_through_active_fedora(io)
    # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        io,
                                        relation,
                                        versioning: false)
    return false unless file_set.save
    repository_file = related_file
    create_version(repository_file, user)
    CharacterizeJob.perform_now(file_set, repository_file.id, pathhint(io))
  end
end

Hyrax::Actors::FileSetActor.class_eval do
  def create_content(file, relation = :original_file, from_url: false)
    # If the file set doesn't have a title or label assigned, set a default.
    file_set.label ||= label_for(file)
    file_set.title = [file_set.label] if file_set.title.blank?
    @file_set = perform_save(file_set)
    return false unless file_set
    if from_url
      # If ingesting from URL, don't spawn an IngestJob; instead
      # reach into the FileActor and run the ingest with the file instance in
      # hand. Do this because we don't have the underlying UploadedFile instance
      file_actor = build_file_actor(relation)
      file_actor.ingest_file(wrapper!(file: file, relation: relation))
      parent = parent_for(file_set: file_set)
      VisibilityCopyJob.perform_now(parent)
      InheritPermissionsJob.perform_now(parent)
    else
      IngestJob.perform_now(wrapper!(file: file, relation: relation))
    end
    file_set.reload.update_index
  end

  def update_content(file, relation = :original_file)
    IngestJob.perform_now(wrapper!(file: file, relation: relation), notification: true)
  end
end
