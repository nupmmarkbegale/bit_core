module BitCore
  # A collection of ordered Slides.
  class Slideshow < ActiveRecord::Base
    has_many :slides,
             -> { order "position" },
             class_name: "BitCore::Slide",
             foreign_key: :bit_core_slideshow_id,
             dependent: :destroy,
             inverse_of: :slideshow
    has_one :content_provider,
            as: :source_content,
            dependent: :nullify

    validates :title, presence: true

    accepts_nested_attributes_for :slides

    def add(slide_params)
      slide = slides.build(slide_params)
      slide.position = slides.count + 1

      slide
    end

    def remove(slide)
      return false unless slide.destroy

      (slide.position + 1..slides.last.position).each do |pos|
        slides.find_by_position(pos).update(position: pos - 1)
      end

      true
    end

    def sort(ordered_ids)
      self.class.transaction do
        self.class.connection.execute "SET CONSTRAINTS " \
                                      "bit_core_slide_position DEFERRED"
        ordered_ids.each_with_index do |id, idx|
          slides.find(id).update_attribute(:position, idx + 1)
        end
      end
    end
  end
end
