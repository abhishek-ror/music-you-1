module BxBlockFreecredits
  class FreecreditBalancesController < ApplicationController
    before_action :validate_json_web_token
    before_action :set_credit_balance, only: [:freecredit_balance, :transation]

    def freecredit_balance
      render status: :ok, json: { freecredit_balance: BxBlockFreecredits::FreecreditBalanceSerializer.new(@cb).serializable_hash }
    end

    def transation
      credit_balance = @cb.amount
      total_amt = params[:amount].to_f

      spend_credits = params[:spend_credits].to_f
      if spend_credits > credit_balance
        render status: :bad_request, json: { errors: { message: "Cannot spend more credits than Credit Balance." } }
      elsif spend_credits > ( total_amt * @cb.spend_rate / 100 )
        render status: :bad_request, json: { errors: { message: "spend_credits should not be more than #{@cb.spend_rate}% of total amount." } }
      else
        spend_credits = @cb.max_spend_limit if spend_credits > @cb.max_spend_limit
        transfer_amt = total_amt - spend_credits

        # begin transaction
        txn_id = BxBlockFreecredits::FakeTransactionService.send_money(@cb.account_id, transfer_amt)
        if txn_id.present? # on success
          freecredits = transfer_amt * @cb.gain_rate / 100
          freecredits = @cb.max_gain_limit if freecredits > @cb.max_gain_limit

          # update Credit Balance
          new_credit_balance = credit_balance - spend_credits + freecredits
          @cb.update(amount: new_credit_balance)
          # create credit history
          @fch = BxBlockFreecredits::FreecreditHistory.new(
                  account_id: @token.id,
                  transaction_id: txn_id,
                  total_amount: total_amt,
                  gained: freecredits,
                  spent: spend_credits,
                  effective_amount: transfer_amt,
                  updated_balance: new_credit_balance,
                  description: params[:description]
                )
          if @fch.save
            # send email with confirmation
            # BxBlockFreecredits::FreecreditsMailer.send_freecredits_mail(@fch).deliver_now
            render status: :ok, json: { credit_transaction_details: BxBlockFreecredits::FreecreditHistorySerializer.new(@fch).serializable_hash }
          else
            render status: :bad_request, json: { errors: @fch.errors }
          end
        else # on failed txn
          # send txn failed email ** optional
          render status: :payment_required, json: { message: "Transaction failed." }
        end
      end

    end

    private
    def set_credit_balance
      @cb = BxBlockFreecredits::FreecreditBalance.find_by(account_id: @token.id)
      if @cb.nil?
        @cb = BxBlockFreecredits::FreecreditBalance.create(credit_balance_params)
      end
    end

    def credit_balance_params
      { account_id: @token.id, amount: 0 }
    end
  end
end
