module BxBlockAutomaticRenewals
  class AutomaticRenewalsController < ApplicationController
    include BuilderJsonWebToken::JsonWebTokenValidation
    before_action :current_user

    def index
      @auto_renewals = current_user.automatic_renewals&.last
      if @auto_renewals.present?
        render json: AutomaticRenewalSerializer.new(@auto_renewals, meta: {
          message: "List of automatic renewals."}).serializable_hash, status: :ok
      else
        render json: {errors: [{message: 'No automatic renewals.'},]}, status: :ok
      end
    end

    def show
      @auto_renewal = current_user.automatic_renewals.find(params[:id])
      render json: AutomaticRenewalSerializer.new(@auto_renewal, meta: {
        message: "Success."}).serializable_hash, status: :ok
    end

    def create
      @auto_renewal =
        AutomaticRenewal.new(auto_renew_params.merge(account_id: current_user.id))
      if @auto_renewal.save
        render json: AutomaticRenewalSerializer.new(@auto_renewal, meta: {
          message: "Automatic Renewals turned on."}).serializable_hash, status: :created
      else
        render json: {errors: format_activerecord_errors(@auto_renewal.errors)},
          status: :unprocessable_entity
      end
    end

    def update
      @auto_renewal = current_user.automatic_renewals.find_by(id: params[:id])
      if @auto_renewal.update(auto_renew_params)
        render json: AutomaticRenewalSerializer.new(@auto_renewal, meta: {
          message: "Automatic Renewals updated."}).serializable_hash, status: :ok
      else
        render json: {errors: format_activerecord_errors(@auto_renewal.errors)},
          status: :unprocessable_entity
      end
    end

    def destroy
      @auto_renewal = current_user.automatic_renewals.find(params[:id])
      if @auto_renewal.destroy
        BxBlockAutomaticRenewals::AutomaticRenewalMailer.cancellation_renewal_notification(@auto_renewal).deliver_later
        render json: { id: @auto_renewal.id, message: "Automatic renewal cancelled" }, status: :ok
      else
        render json: { errors: [{ message: 'Failed to cancel automatic renewal.' }] }, status: :unprocessable_entity
      end
    end

    private

    def auto_renew_params
      params.require(:auto_renew).permit(:subscription_type, :is_auto_renewal)
    end
  end
end
