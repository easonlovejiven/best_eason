class Upload::BaseStock < Upload::Base
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :crop_t

  mount_uploader :image, BaseStockAvatar
    
  validates :image, file_size: {maximum: 5.megabytes.to_i}
 
  # 裁剪图片
  after_update :crop_avatar
  def crop_avatar
    image.recreate_versions! if cropping?
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end
end
