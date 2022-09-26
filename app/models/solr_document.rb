# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  # Make any metadata changes after module inclusions to override
  # https://github.com/samvera/hyrax/blob/v3.4.1/app/models/concerns/hyrax/solr_document/metadata.rb
  attribute :identifier,       Solr::String, "identifier_ssi"
  attribute :date_normalized,  Solr::String, "date_normalized_ssi"
  attribute :date_created,     Solr::String, "date_created_ssi"
  attribute :date_copyrighted, Solr::String, "date_copyrighted_ssi"
  attribute :date_issued,      Solr::String, "date_issued_ssi"
  attribute :date_accepted,    Solr::String, "date_accepted_ssi"

  attribute :resource_format,  Solr::Array,  "resource_format_tesim"
  attribute :genre,            Solr::Array,  "genre_tesim"
  attribute :extent,           Solr::Array,  "extent_tesim"

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models.

  use_extension(Hydra::ContentNegotiation)
end
