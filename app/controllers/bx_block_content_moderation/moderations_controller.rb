module BxBlockContentModeration
  class ModerationsController < ApplicationController
    include ActiveStorage::SetCurrent
    before_action :check_filetype

    def index
      all_previous_inputs = BxBlockContentModeration::Content.where(created_by: @current_user)
      render json: ContentSerializer.new(all_previous_inputs)
    end

    def create
      return unless params[:text_content].present? or params[:image].present?

      @content = BxBlockContentModeration::Content.new(params_for_moderation)
      @content.save
      @original_text = @content[:text_content] #Declaring here again since the Gem edits all instances of the string.

      text_approval(TextModerator.new(params[:text_content],@original_text).text_filter) if params[:text_content].present?
      image_approval(ImageModerator.new.check(params[:image])) if params[:image].present?

      render json: ContentSerializer.new(@content), status: :created
    end

    private

    def text_approval(status)
      @content.update(is_text_approved: true) if status == 1
    end

    def image_approval(status)
       @content.update(is_image_approved: true)  if status == 1
    end

    def params_for_moderation
      params.permit(:text_content,:image).merge(created_by: @current_user.id, updated_by: @current_user.id, is_active: true, is_text_approved: false, is_image_approved: false)
    end

    def check_filetype
      allowed_files = ['.jpg', '.jpeg', '.png']
      return unless params[:image].present? && !(allowed_files.include? File.extname(params[:image]))
      render json: { error: 'Invalid file. Only images (jpg,jpeg,png) are allowed' }, status: :unprocessable_entity
    end
  end
end
