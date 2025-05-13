module BxBlockContentManagement
  class ContentManagementsController < ApplicationController
    # skip_before_action :validate_json_web_token
    def index
      @contents = BxBlockContentManagement::ContentManagement.all

      return render json: {
        message: 'No Content is present'
      } unless @contents.present?

      render json: BxBlockContentManagement::ContentSerializer.new(
        @contents, meta: {message: 'List of all contents'}
      ).serializable_hash
    end

    def get_approved
      @contents = BxBlockContentManagement::ContentManagement.where(status:true)
      if @contents.present?
        render json: BxBlockContentManagement::ContentSerializer.new(@contents, meta: {message: 'List of approved contents'}).serializable_hash
      else
        render json: { error: "Content Management not found" }
      end
    end

    def get_user_type
      @contents = BxBlockContentManagement::ContentManagement.where(user_type: params[:user_type])
      @contents = @contents.or(BxBlockContentManagement::ContentManagement.where.not(user_type: params[:user_type]).where(status: true))
      if @contents.present?
        render json: BxBlockContentManagement::ContentSerializer.new(@contents,  meta: {message: 'List of all contents'}), status: :ok
      else
        render json: { error: "Content not found" }
      end
    end

    def create
      @content = BxBlockContentManagement::ContentManagement.new(content_params)
      if @content.save
        render json: BxBlockContentManagement::ContentSerializer.new(@content, meta: {
          message: 'Content Created Successfully',
        }).serializable_hash, status: :created
      else
        render json: { errors: format_activerecord_errors(@content.errors) },
               status: :unprocessable_entity
      end
    end

    def show
      @content = BxBlockContentManagement::ContentManagement.find_by(id: params[:id])
      if @content
        render json: BxBlockContentManagement::ContentSerializer.new(@content, meta: {
          message: "Content details are updated."}).serializable_hash, status: :ok
      else
        render json: { error: "Content not found" }
      end
    end

    def update
      @content = BxBlockContentManagement::ContentManagement.find(params[:id])
      if @content.update(content_params)
        render json: BxBlockContentManagement::ContentSerializer.new(@content, meta: {
          message: "Content details are updated."}).serializable_hash, status: :ok
      else
        render json: {errors: format_activerecord_errors(@content.errors)},
               status: :unprocessable_entity
      end
    end

    def destroy
      @content = BxBlockContentManagement::ContentManagement.find(params[:id])
      if @content.destroy
        render json: {message: "Content info Deleted."}, status: :ok
      else
        render json: {errors: format_activerecord_errors(@content.errors)},
               status: :unprocessable_entity
      end
    end

    private

    def content_params
      params.permit(
        :title, :id, :description, :status,  :price, :user_type, :quantity, images: []
      )
    end

  end
end
