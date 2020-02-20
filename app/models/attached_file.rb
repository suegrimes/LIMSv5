# == Schema Information
#
# Table name: attached_files
#
#  id                    :integer          not null, primary key
#  sampleproc_id         :integer          not null
#  sampleproc_type       :string(50)       not null
#  document              :string(255)
#  document_content_type :string(40)
#  document_file_size    :string(25)
#  notes                 :string(255)
#  updated_by            :integer
#  created_at            :datetime
#

class AttachedFile < ApplicationRecord
  FILES_ROOT = (SITE_URL.include?('stanford.edu') ? File.join(Rails.root, "..", "..", "shared", "attached_files") :
                                                   File.join(Rails.root, "..", "LIMSFiles", "AttachedFile"))
  
  belongs_to :sampleproc, optional: true, polymorphic: true
  mount_uploader :document, AttachmentUploader

  validates_lengths_from_database except: :document

  #skip_callback :save, :after, :remove_previously_stored_document
  # behavior changed in Rails 5, need raise: false to make work
  skip_callback :save, :after, :remove_previously_stored_document, raise: false

  validates_presence_of :document

  before_save :update_document_attributes

  def update_document_attributes
    if document.present? && document_changed?
      self.document_content_type = document.file.content_type
      self.document_file_size = document.file.size
    end
  end

  def previewable?
    (%w(jpg jpeg gif png txt csv pdf).include?(document.file.extension.downcase) ? true : false)
  end

  def stored_name_has_id
    fn_part1 = document.file.identifier.split('_')[0]
    return (fn_part1 == sampleproc_id.to_s ? true : false)
  end

  def doc_filename
    if stored_name_has_id
      return document.file.identifier[(sampleproc_id.to_s.size+1)..-1]
    else
      return document.file.identifier
    end
  end

  def doc_stored_name
    if stored_name_has_id
      return document.file.identifier
    else
      return [sampleproc_id.to_s, '_', doc_filename].join
    end
  end

  #def basename_with_ext
    # Return file basename, with extension (and with id prefix)
    #return document.path.split('/').last
    #return document.file.identifier
    #return [sampleproc_id.to_s, '_', document.basename, '.', document.extension].join
  #end
  
  def doc_fullpath
    #return document.current_path
    return File.join(FILES_ROOT, sampleproc_type, doc_stored_name)
  end
end
