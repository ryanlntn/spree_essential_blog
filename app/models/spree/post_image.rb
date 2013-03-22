module Spree
  class Spree::PostImage < Spree::Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    attr_accessible :alt, :attachment, :position, :viewable_type, :viewable_id

    has_attached_file :attachment,
                      :styles => { :mini => '48x48>', :small => '150x150>', :medium => '600x600>', :large => '950x700>' },
                      :default_style => :medium,
                      :url => '/spree/posts/:id/:style/:basename.:extension',
                      :path => ':rails_root/public/spree/posts/:id/:style/:basename.:extension',
                      :convert_options => { :all => '-strip -auto-orient' }
    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    include Spree::Core::S3Support
    supports_s3 :attachment

    Spree::PostImage.attachment_definitions[:attachment][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles])
    Spree::PostImage.attachment_definitions[:attachment][:path] = Spree::Config[:attachment_path]
    Spree::PostImage.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
    Spree::PostImage.attachment_definitions[:attachment][:default_url] = Spree::Config[:attachment_default_url]
    Spree::PostImage.attachment_definitions[:attachment][:default_style] = Spree::Config[:attachment_default_style]

    #used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      unless attachment.errors.empty?
        # uncomment this to get rid of the less-than-useful interrim messages
        # errors.clear
        errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
        false
      end
    end
  end
end