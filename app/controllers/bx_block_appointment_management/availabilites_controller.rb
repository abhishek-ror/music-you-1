module BxBlockAppointmentManagement
  class AvailabilitiesController < ApplicationController
    before_action :set_current_user, only: [:create, :delete_all]

    def index
      unless params[:service_provider_id].blank? || params[:availability_date].blank?
        availability = Availability.find_by(
          service_provider_id: params[:service_provider_id],
          availability_date: Date.parse(params[:availability_date]).strftime('%d/%m/%Y')
        )
        render json: {
          message: "No slots present for date " \
                   "#{Date.parse(params[:availability_date]).strftime('%d/%m/%Y')}"
        } and return unless availability.present?
        render json: ServiceProviderAvailabilitySerializer.new(
          availability, meta: {message: 'List of all slots'}
        )
      else
        render json: {errors: [
          {availability: 'Date or Service provider Account id is empty'},
        ]}, status: :unprocessable_entity
      end
    end


    def create
      availability = Availability.new(
        availability_params.merge(service_provider_id: @current_user.id)
      )
      if availability.save
        trigger_slot_worker(availability)
        render json: ServiceProviderAvailabilitySerializer.new(availability)
      else
        render json: { errors: [{slot_error: availability.errors.full_messages.first}] },
               status: :unprocessable_entity
      end
    end

    def delete_all
      BxBlockAppointmentManagement::Availability.where(
        service_provider: @current_user
      ).destroy_all
    end

    private

    def availability_params
      params.require(:availability).permit(:start_time, :end_time, :availability_date)
    end

    def trigger_slot_worker availability
      BxBlockAppointmentManagement::CreateAvailabilityWorker.perform_async(availability.id)
    end

    def set_current_user
      @current_user = AccountBlock::Account.find(@token.id)
    end
  end
end
